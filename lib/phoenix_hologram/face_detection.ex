defmodule PhoenixHologram.FaceDetection do
  @moduledoc """
  Ingests a video, detects faces per sampled frame, clusters them into
  unique identities, and persists the result: one `Movie`, one `Face`
  row per unique identity, and one `Detection` row per raw sighting
  (the raw material a later scene-timestamp-index feature will need).
  """

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
    with {:ok, movie} <- create_movie(video_path, opts) do
      case do_ingest(movie, video_path, opts) do
        {:ok, result} ->
          {:ok, result}

        {:error, reason} ->
          movie |> Movie.changeset(%{status: "failed"}) |> Repo.update()
          {:error, reason}
      end
    end
  end

  defp do_ingest(movie, video_path, opts) do
    with {:ok, frames} <- FrameExtractor.extract_frames(video_path, opts),
         {:ok, detections} <- detect_all(frames) do
      persist_clusters(movie, detections, opts)
    end
  end

  defp create_movie(video_path, opts) do
    %Movie{}
    |> Movie.changeset(%{
      path: video_path,
      title: Keyword.get(opts, :title),
      status: "processing"
    })
    |> Repo.insert()
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
          |> Face.changeset(%{movie_id: movie.id, embedding: representative_embedding(cluster)})
          |> Repo.insert()

        for detection <- cluster do
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
              confidence: detection.confidence
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

  defp representative_embedding([detection | _rest]), do: detection.embedding
end
