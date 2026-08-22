defmodule PhoenixHologramWeb.Hologram.Pages.PremierePage do
  use Hologram.Page

  alias Hologram.UI.Link
  alias PhoenixHologram.FaceDetection.Movie
  alias PhoenixHologram.Repo
  alias PhoenixHologramWeb.Hologram.Pages.PlayerPage

  route "/premiere"

  layout PhoenixHologramWeb.Hologram.Layouts.DefaultLayout

  def init(_params, component, _server) do
    movies = Repo.all(Movie)
    put_state(component, :movies, movies)
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
              <Link to={PlayerPage, id: movie.id} class="card bg-base-100 shadow-xl hover:shadow-2xl transition">
                <div class="card-body">
                  <h2 class="card-title">{movie.title || movie.path}</h2>
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
