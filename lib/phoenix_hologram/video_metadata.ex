defmodule PhoenixHologram.VideoMetadata do
  @moduledoc """
  Probes a movie's duration, resolution, and file size via ffmpeg (reads
  the container header only, no decoding), and caches the result on disk
  so /premiere doesn't re-spawn ffmpeg on every page view.
  """

  alias PhoenixHologram.FaceDetection.{FrameExtractor, Movie}

  @type t :: %{
          duration_ms: non_neg_integer | nil,
          width: pos_integer | nil,
          height: pos_integer | nil,
          size_bytes: non_neg_integer
        }

  @doc "Returns cached metadata for this movie, probing and caching it on first call."
  @spec fetch(Movie.t()) :: t()
  def fetch(movie) do
    case File.read(cache_path(movie)) do
      {:ok, json} -> decode(json)
      {:error, _} -> probe_and_cache(movie)
    end
  end

  @doc "One-line human summary, e.g. \"39 min · 1920x1080 · 5.7 GB\"."
  @spec describe(t()) :: String.t()
  def describe(metadata) do
    [format_duration(metadata.duration_ms), format_resolution(metadata), format_size(metadata.size_bytes)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  @spec format_duration(non_neg_integer | nil) :: String.t() | nil
  def format_duration(nil), do: nil

  def format_duration(duration_ms) do
    total_seconds = div(duration_ms, 1000)
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)

    if hours > 0 do
      "#{hours}h #{minutes}m"
    else
      "#{minutes} min"
    end
  end

  @spec format_resolution(t()) :: String.t() | nil
  def format_resolution(%{width: nil}), do: nil
  def format_resolution(%{height: nil}), do: nil
  def format_resolution(%{width: width, height: height}), do: "#{width}x#{height}"

  @spec format_size(non_neg_integer) :: String.t()
  def format_size(size_bytes) when size_bytes >= 1_000_000_000 do
    "#{Float.round(size_bytes / 1_000_000_000, 1)} GB"
  end

  def format_size(size_bytes) do
    "#{Float.round(size_bytes / 1_000_000, 1)} MB"
  end

  defp probe_and_cache(movie) do
    metadata = probe(movie.path)
    File.mkdir_p!(cache_dir())
    File.write!(cache_path(movie), encode(metadata))
    metadata
  end

  defp probe(path) do
    base = %{size_bytes: file_size(path), duration_ms: nil, width: nil, height: nil}

    case FrameExtractor.ffmpeg_path() do
      {:ok, ffmpeg} ->
        {output, _status} = System.cmd(ffmpeg, ["-i", path], stderr_to_stdout: true)
        base |> Map.merge(parse_duration(output)) |> Map.merge(parse_resolution(output))

      {:error, :ffmpeg_not_found} ->
        base
    end
  end

  defp parse_duration(output) do
    case Regex.run(~r/Duration: (\d+):(\d+):(\d+\.\d+)/, output) do
      [_, hours, minutes, seconds] ->
        ms = (String.to_integer(hours) * 3600 + String.to_integer(minutes) * 60 + String.to_float(seconds)) * 1000
        %{duration_ms: round(ms)}

      nil ->
        %{}
    end
  end

  defp parse_resolution(output) do
    case Regex.run(~r/Video:.*?(\d{2,5})x(\d{2,5})/, output) do
      [_, width, height] -> %{width: String.to_integer(width), height: String.to_integer(height)}
      nil -> %{}
    end
  end

  defp file_size(path) do
    case File.stat(path) do
      {:ok, %{size: size}} -> size
      _ -> 0
    end
  end

  defp cache_dir do
    Path.join(:code.priv_dir(:phoenix_hologram), "face_detection/movie_metadata")
  end

  defp cache_path(%Movie{id: id}) do
    Path.join(cache_dir(), "#{id}.json")
  end

  defp encode(metadata), do: Jason.encode!(metadata)

  defp decode(json) do
    json
    |> Jason.decode!()
    |> Map.new(fn {key, value} -> {String.to_existing_atom(key), value} end)
  end
end
