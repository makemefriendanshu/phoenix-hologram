defmodule PhoenixHologramWeb.VideoController do
  use PhoenixHologramWeb, :controller

  alias PhoenixHologram.FaceDetection.Movie
  alias PhoenixHologram.Repo
  alias PhoenixHologram.VideoPreview

  @content_types %{
    ".mp4" => "video/mp4",
    ".mov" => "video/quicktime",
    ".webm" => "video/webm",
    ".mkv" => "video/x-matroska",
    ".m4v" => "video/x-m4v"
  }

  def show(conn, %{"id" => id}) do
    with %Movie{} = movie <- Repo.get(Movie, id),
         path <- resolve_path(movie),
         true <- File.regular?(path) do
      stream_video(conn, path)
    else
      _ -> send_resp(conn, 404, "Not found")
    end
  end

  defp resolve_path(movie) do
    if VideoPreview.preview_ready?(movie) do
      VideoPreview.preview_path(movie)
    else
      movie.path
    end
  end

  defp stream_video(conn, path) do
    %{size: size} = File.stat!(path)

    content_type =
      Map.get(
        @content_types,
        path |> Path.extname() |> String.downcase(),
        "application/octet-stream"
      )

    conn =
      conn
      |> put_resp_header("accept-ranges", "bytes")
      |> put_resp_content_type(content_type, nil)

    case get_req_header(conn, "range") do
      ["bytes=" <> range] -> send_range(conn, path, size, range)
      _ -> send_file(conn, 200, path)
    end
  end

  defp send_range(conn, path, size, range) do
    {range_start, range_end} = parse_range(range, size)
    length = range_end - range_start + 1

    conn
    |> put_resp_header("content-range", "bytes #{range_start}-#{range_end}/#{size}")
    |> send_file(206, path, range_start, length)
  end

  defp parse_range(range, size) do
    case String.split(range, "-") do
      [start_str, ""] ->
        {String.to_integer(start_str), size - 1}

      [start_str, end_str] ->
        {String.to_integer(start_str), min(String.to_integer(end_str), size - 1)}

      _ ->
        {0, size - 1}
    end
  end
end
