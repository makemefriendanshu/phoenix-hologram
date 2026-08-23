defmodule PhoenixHologram.VideoSegments do
  @moduledoc """
  Splits a movie into ~10 independently-playable segments via ffmpeg's
  segment muxer with stream copy (no re-encoding, so it's fast and
  lossless). Unlike a raw byte-range slice, each segment is a
  self-contained video file that can be downloaded and played on its
  own, without needing to be joined with the others first.

  Cuts can only land on keyframes, so the actual segment count/lengths
  vary slightly around the 10-way split — callers should read back
  whatever `list/1` returns rather than assuming exactly 10.
  """

  alias PhoenixHologram.FaceDetection.{FrameExtractor, Movie}
  alias PhoenixHologram.VideoMetadata
  alias PhoenixHologram.VideoPreview

  @target_segment_count 10

  @doc "Lists the cached segment paths for this movie, in order. Empty if not generated yet."
  @spec list(Movie.t()) :: [String.t()]
  def list(movie) do
    dir = segments_dir(movie)

    case File.ls(dir) do
      {:ok, files} -> files |> Enum.sort() |> Enum.map(&Path.join(dir, &1))
      {:error, _} -> []
    end
  end

  @doc "Returns the cached segments for this movie, generating them first if needed."
  @spec ensure_generated!(Movie.t()) :: [String.t()]
  def ensure_generated!(movie) do
    case list(movie) do
      [] -> generate!(movie)
      segments -> segments
    end
  end

  @doc "Splits `movie` into fresh segments, replacing any previously cached ones."
  @spec generate!(Movie.t()) :: [String.t()]
  def generate!(movie) do
    source = VideoPreview.resolve_path(movie)
    dir = segments_dir(movie)
    File.rm_rf!(dir)
    File.mkdir_p!(dir)

    args = [
      "-y",
      "-i",
      source,
      "-c",
      "copy",
      "-map",
      "0",
      "-f",
      "segment",
      "-segment_time",
      "#{segment_seconds(movie)}",
      "-reset_timestamps",
      "1",
      Path.join(dir, "part%03d.mp4")
    ]

    case System.cmd(ffmpeg_path!(), args, stderr_to_stdout: true) do
      {_output, 0} ->
        list(movie)

      {output, status} ->
        File.rm_rf!(dir)
        raise "ffmpeg exited with status #{status}:\n#{output}"
    end
  end

  defp segment_seconds(movie) do
    case VideoMetadata.fetch(movie) do
      %{duration_ms: duration_ms} when is_integer(duration_ms) and duration_ms > 0 ->
        max(1, div(duration_ms, 1000 * @target_segment_count))

      _ ->
        60
    end
  end

  defp segments_dir(%Movie{id: id}) do
    Path.join([:code.priv_dir(:phoenix_hologram), "face_detection/movie_segments", "#{id}"])
  end

  defp ffmpeg_path! do
    case FrameExtractor.ffmpeg_path() do
      {:ok, path} -> path
      {:error, :ffmpeg_not_found} -> raise "ffmpeg not found — run `mix face_detection.setup`"
    end
  end
end
