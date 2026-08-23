defmodule PhoenixHologram.FaceDetection do
  @moduledoc """
  Ingests a video, detects faces per sampled frame, clusters them into
  unique identities, and persists the result: one `Movie`, one `Face`
  row per unique identity, and one `Detection` row per raw sighting.
  Detections carry `:frame_time_ms` and `:face_id`, so
  `PhoenixHologram.FaceDetection.SceneIndex` can later derive each
  face's own timestamp ranges, or the movie's real scene timeline
  (segments where the same set of faces is on screen together).
  """

  import Ecto.Query

  alias PhoenixHologram.FaceDetection.{
    Clustering,
    Detection,
    Face,
    FrameExtractor,
    Movie,
    ModelServer
  }

  alias PhoenixHologram.Repo

  @doc """
  Ingests `video_path`, returning `{:ok, movie}` with its `:faces` (each
  preloaded with `:detections`) or `{:error, reason}`.

  Options:
    * `:title` - stored on the movie record
    * `:fps` - frame sampling rate, default 1
    * `:cluster_threshold` - cosine-similarity threshold, see `Clustering`
  """
  def ingest_video(video_path, opts \\ []) do
    normalized_path = Path.expand(video_path)

    with {:ok, movie} <- create_movie(normalized_path, opts) do
      case do_ingest(movie, normalized_path, opts) do
        {:ok, result} ->
          {:ok, result}

        {:error, reason} ->
          movie |> Movie.changeset(%{status: "failed"}) |> Repo.update()
          {:error, reason}
      end
    end
  end

  defp do_ingest(movie, video_path, opts) do
    with {:ok, frames} <- FrameExtractor.extract_frames(video_path, opts) do
      try do
        with {:ok, detections} <- detect_all(frames) do
          persist_clusters(movie, detections, opts)
        end
      after
        cleanup_frames(frames)
      end
    end
  end

  @doc """
  Assigns an admin-chosen identity to a face: a heading (`:label`) and
  an optional subheading (`:subtitle`). Returns `{:ok, face}` or
  `{:error, changeset}`.
  """
  def label_face(face_id, attrs) do
    Face
    |> Repo.get!(face_id)
    |> Face.label_changeset(attrs)
    |> Repo.update()
  end

  @doc "Renames a movie. Returns `{:ok, movie}` or `{:error, changeset}`."
  def rename_movie(movie_id, title) do
    Movie
    |> Repo.get!(movie_id)
    |> Movie.changeset(%{title: title})
    |> Repo.update()
  end

  defp cleanup_frames([]), do: :ok

  defp cleanup_frames([%{path: path} | _]) do
    path |> Path.dirname() |> File.rm_rf!()
  end

  # Re-ingesting a path that's already a movie (whether from a previous
  # ingest or a seeded row) reuses that row and clears its old faces
  # instead of creating a duplicate movie.
  defp create_movie(video_path, opts) do
    case Repo.get_by(Movie, path: video_path) do
      nil ->
        %Movie{}
        |> Movie.changeset(%{
          path: video_path,
          title: Keyword.get(opts, :title),
          status: "processing"
        })
        |> Repo.insert()

      movie ->
        Repo.delete_all(from f in Face, where: f.movie_id == ^movie.id)

        attrs =
          case Keyword.get(opts, :title) do
            nil -> %{status: "processing"}
            title -> %{status: "processing", title: title}
          end

        movie |> Movie.changeset(attrs) |> Repo.update()
    end
  end

  defp detect_all(frames) do
    Enum.reduce_while(frames, {:ok, []}, fn frame, {:ok, acc} ->
      case ModelServer.detect_faces(frame.path) do
        {:ok, faces} ->
          detections = Enum.map(faces, &Map.put(&1, :timestamp_ms, frame.timestamp_ms))
          {:cont, {:ok, detections ++ acc}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp persist_clusters(movie, detections, opts) do
    clusters = Clustering.cluster(detections, opts)

    Repo.transaction(fn ->
      for cluster <- clusters do
        {:ok, face} =
          %Face{}
          |> Face.changeset(%{movie_id: movie.id, embedding: cluster.centroid})
          |> Repo.insert()

        for detection <- cluster.members do
          {x, y, w, h} = detection.bbox

          {:ok, _} =
            %Detection{}
            |> Detection.changeset(%{
              face_id: face.id,
              frame_time_ms: detection.timestamp_ms,
              bbox_x: x,
              bbox_y: y,
              bbox_w: w,
              bbox_h: h,
              confidence: detection.confidence,
              embedding: detection.embedding
            })
            |> Repo.insert()
        end
      end

      movie
      |> Movie.changeset(%{status: "done"})
      |> Repo.update!()
      |> Repo.preload(faces: :detections)
    end)
  end
end
