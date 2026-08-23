defmodule PhoenixHologramWeb.Hologram.Pages.PremierePage do
  use Hologram.Page

  alias Hologram.UI.Link
  alias PhoenixHologram.FaceDetection.Movie
  alias PhoenixHologram.Repo
  alias PhoenixHologram.VideoMetadata
  alias PhoenixHologramWeb.Hologram.Pages.AdminMoviePage
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
    <div class="min-h-screen">
      <div class="p-6">
        <div class="max-w-3xl mx-auto">
          <div class="flex items-center justify-center gap-3 mb-1">
            <svg viewBox="0 0 24 40" class="w-4 h-8 text-primary/70" fill="none" stroke="currentColor" stroke-width="1.2">
              <path d="M12 2c-6 6-6 20 0 36" />
              <circle cx="10" cy="10" r="2.5" fill="currentColor" stroke="none" opacity="0.55" />
            </svg>
            <h2 class="font-display text-xl sm:text-2xl text-center">
              Past Wedding Celebrations &amp; Milestones
            </h2>
            <svg viewBox="0 0 24 40" class="w-4 h-8 text-primary/70 -scale-x-100" fill="none" stroke="currentColor" stroke-width="1.2">
              <path d="M12 2c-6 6-6 20 0 36" />
              <circle cx="10" cy="10" r="2.5" fill="currentColor" stroke="none" opacity="0.55" />
            </svg>
          </div>
          <div class="gold-divider w-24 mx-auto mb-6"></div>

          {%if @movies == []}
            <div class="card card-stock shadow-xl">
              <div class="card-body">
                <p class="text-base-content/70">
                  No films yet. Once a video is ingested it will show up here.
                </p>
              </div>
            </div>
          {%else}
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {%for movie <- @movies}
                <div class="card card-stock shadow-xl hover:shadow-2xl transition overflow-hidden">
                  <Link to={PlayerPage, id: movie.id}>
                    <figure class="aspect-video bg-base-300">
                      <img src={movie.thumbnail_url} alt={movie.title} class="w-full h-full object-cover" />
                    </figure>
                  </Link>
                  <div class="card-body items-center text-center">
                    <h2 class="card-title font-display">{movie.title}</h2>
                    <p class="text-sm text-base-content/70">{movie.description}</p>
                    <div class="flex flex-wrap justify-center gap-2 mt-2">
                      <Link to={PlayerPage, id: movie.id} class="btn btn-sm btn-primary">
                        View Video ▶
                      </Link>
                      <Link to={AdminMoviePage, id: movie.id} class="btn btn-sm btn-secondary">
                        Admin View ⚙
                      </Link>
                    </div>
                  </div>
                </div>
              {/for}
            </div>
          {/if}
        </div>
      </div>
    </div>
    """
  end
end
