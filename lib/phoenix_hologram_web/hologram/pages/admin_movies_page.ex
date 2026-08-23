defmodule PhoenixHologramWeb.Hologram.Pages.AdminMoviesPage do
  @moduledoc """
  Admin index: every ingested movie, with how many unique faces were
  recognised in it so far. Links into `AdminMoviePage` for the
  per-movie scene browser.
  """

  use Hologram.Page

  alias Hologram.UI.Link
  alias PhoenixHologram.FaceDetection.Movie
  alias PhoenixHologram.Repo
  alias PhoenixHologram.VideoMetadata
  alias PhoenixHologramWeb.Hologram.Pages.AdminMoviePage

  route "/admin"

  layout PhoenixHologramWeb.Hologram.Layouts.DefaultLayout

  def init(_params, component, _server) do
    movies =
      Movie
      |> Repo.all()
      |> Repo.preload(:faces)
      |> Enum.map(fn movie ->
        %{
          id: movie.id,
          title: movie.title || movie.path,
          status: movie.status,
          face_count: length(movie.faces),
          description: movie |> VideoMetadata.fetch() |> VideoMetadata.describe(),
          thumbnail_url: "/premiere/videos/#{movie.id}/thumbnail"
        }
      end)

    put_state(component, :movies, movies)
  end

  def template do
    ~HOLO"""
    <div class="min-h-screen bg-base-200 p-6">
      <div class="max-w-3xl mx-auto">
        <h1 class="text-2xl font-semibold mb-6">Admin: Recognised Faces</h1>

        {%if @movies == []}
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <p class="text-base-content/70">
                No movies yet. Ingest one with `mix face_detection.ingest`.
              </p>
            </div>
          </div>
        {%else}
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {%for movie <- @movies}
              <Link to={AdminMoviePage, id: movie.id} class="card bg-base-100 shadow-xl hover:shadow-2xl transition overflow-hidden">
                <figure class="aspect-video bg-base-300">
                  <img src={movie.thumbnail_url} alt={movie.title} class="w-full h-full object-cover" />
                </figure>
                <div class="card-body">
                  <h2 class="card-title">{movie.title}</h2>
                  <p class="text-sm text-base-content/70">{movie.description}</p>
                  <div class="flex gap-2">
                    <span class="badge badge-outline">{movie.status}</span>
                    <span class="badge badge-secondary">{movie.face_count} face(s)</span>
                  </div>
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
