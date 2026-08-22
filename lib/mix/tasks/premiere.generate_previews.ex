defmodule Mix.Tasks.Premiere.GeneratePreviews do
  @moduledoc """
  Generates cached 720p/2.5Mbps preview proxies for every movie that doesn't
  have one yet, so /premiere stays watchable over bandwidth-constrained
  connections (e.g. the ngrok tunnel).

      mix premiere.generate_previews
  """

  use Mix.Task

  alias PhoenixHologram.FaceDetection.Movie
  alias PhoenixHologram.Repo
  alias PhoenixHologram.VideoPreview

  @shortdoc "Generates cached low-bitrate preview proxies for movies"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    Movie
    |> Repo.all()
    |> Enum.reject(&VideoPreview.preview_ready?/1)
    |> Enum.each(fn movie ->
      Mix.shell().info("Generating preview for ##{movie.id} (#{movie.title})...")
      VideoPreview.generate!(movie)
      Mix.shell().info("  done: #{VideoPreview.preview_path(movie)}")
    end)
  end
end
