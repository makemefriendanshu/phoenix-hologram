defmodule PhoenixHologramWeb.Hologram.Pages.PremierePage do
  use Hologram.Page

  alias Hologram.UI.Link
  alias PhoenixHologram.FaceDetection.Movie
  alias PhoenixHologram.Repo
  alias PhoenixHologram.VideoMetadata
  alias PhoenixHologramWeb.Hologram.Pages.PlayerPage

  route "/premiere"

  layout PhoenixHologramWeb.Hologram.Layouts.DefaultLayout

  def init(_params, component, _server) do
    movies =
      Movie
      |> Repo.all()
      |> Enum.map(&build_card/1)

    put_state(component, :movies, movies)
  end

  defp build_card(movie) do
    metadata = VideoMetadata.fetch(movie)

    %{
      id: movie.id,
      title: movie.title || movie.path,
      status: movie.status,
      description: VideoMetadata.describe(metadata),
      thumbnail_url: "/premiere/videos/#{movie.id}/thumbnail"
    }
  end

  def template do
    ~HOLO"""
    <div class="min-h-screen bg-base-200 p-6">
      <div class="max-w-3xl mx-auto">
        <h1 class="text-2xl font-semibold mb-6">Premiere Hall</h1>

        {%if @movies == []}
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <p class="text-base-content/70">
                No films yet. Once a video is ingested it will show up here.
              </p>
            </div>
          </div>
        {%else}
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {%for movie <- @movies}
              <Link to={PlayerPage, id: movie.id} class="card bg-base-100 shadow-xl hover:shadow-2xl transition overflow-hidden">
                <figure class="aspect-video bg-base-300">
                  <img src={movie.thumbnail_url} alt={movie.title} class="w-full h-full object-cover" />
                </figure>
                <div class="card-body">
                  <h2 class="card-title">{movie.title}</h2>
                  <p class="text-sm text-base-content/70">{movie.description}</p>
                  <span class="badge badge-outline">{movie.status}</span>
                </div>
              </Link>
            {/for}
          </div>
        {/if}
      </div>
    </div>
    """
  end
end
