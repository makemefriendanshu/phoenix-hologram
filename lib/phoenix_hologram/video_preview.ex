defmodule PhoenixHologram.VideoPreview do
  @moduledoc """
  Generates and caches a lower-bitrate 720p proxy of a movie's source video,
  so it stays watchable over bandwidth-constrained connections (e.g. the
  ngrok tunnel, which tops out well below the bitrate of raw camera footage).
  """

  alias PhoenixHologram.FaceDetection.Movie

  @preview_bitrate "2500k"

  @doc "Path the cached preview for this movie would live at, whether or not it exists yet."
  @spec preview_path(Movie.t()) :: String.t()
  def preview_path(%Movie{id: id}) do
    Path.join(previews_dir(), "#{id}.mp4")
  end

  @doc "Whether a cached preview has already been generated for this movie."
  @spec preview_ready?(Movie.t()) :: boolean
  def preview_ready?(movie) do
    movie |> preview_path() |> File.regular?()
  end

  @doc "The path playback/downloads should use: the cached preview if ready, else the raw source."
  @spec resolve_path(Movie.t()) :: String.t()
  def resolve_path(movie) do
    if preview_ready?(movie) do
      preview_path(movie)
    else
      movie.path
    end
  end

  @doc """
  Transcodes the movie's source file into a cached 720p/#{@preview_bitrate} preview.
  Overwrites any existing preview. Returns the preview path.
  """
  @spec generate!(Movie.t()) :: String.t()
  def generate!(%Movie{path: source} = movie) do
    File.mkdir_p!(previews_dir())
    dest = preview_path(movie)
    tmp = dest <> ".tmp"

    args = [
      "-y",
      "-i",
      source,
      "-vf",
      "scale=-2:720",
      "-c:v",
      "libx264",
      "-preset",
      "veryfast",
      "-b:v",
      @preview_bitrate,
      "-maxrate",
      @preview_bitrate,
      "-bufsize",
      "5000k",
      "-c:a",
      "aac",
      "-b:a",
      "128k",
      "-movflags",
      "+faststart",
      "-f",
      "mp4",
      tmp
    ]

    {output, exit_code} = System.cmd(ffmpeg_path(), args, stderr_to_stdout: true)

    if exit_code == 0 do
      File.rename!(tmp, dest)
      dest
    else
      File.rm(tmp)
      raise "ffmpeg exited with status #{exit_code}:\n#{output}"
    end
  end

  defp previews_dir do
    Path.join(:code.priv_dir(:phoenix_hologram), "face_detection/previews")
  end

  defp ffmpeg_path do
    bundled = Path.join(:code.priv_dir(:phoenix_hologram), "face_detection/bin/ffmpeg")
    if File.regular?(bundled), do: bundled, else: "ffmpeg"
  end
end
