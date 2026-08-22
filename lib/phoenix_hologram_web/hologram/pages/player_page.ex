defmodule PhoenixHologramWeb.Hologram.Pages.PlayerPage do
  use Hologram.Page

  alias Hologram.UI.Link
  alias PhoenixHologram.FaceDetection.Movie
  alias PhoenixHologram.Repo
  alias PhoenixHologramWeb.Hologram.Pages.PremierePage

  route "/premiere/:id"
  param :id, :integer

  layout PhoenixHologramWeb.Hologram.Layouts.DefaultLayout

  def init(params, component, _server) do
    movie = Repo.get(Movie, params.id)
    put_state(component, :movie, movie)
  end

  def template do
    ~HOLO"""
    <div class="min-h-screen bg-base-200 p-6">
      <div class="max-w-3xl mx-auto">
        <Link to={PremierePage} class="link link-hover text-sm">&larr; Back to Premiere Hall</Link>

        {%if @movie == nil}
          <div class="card bg-base-100 shadow-xl mt-4">
            <div class="card-body">
              <p class="text-base-content/70">This film could not be found.</p>
            </div>
          </div>
        {%else}
          <h1 class="text-2xl font-semibold mt-4 mb-4">{@movie.title || @movie.path}</h1>
          <video controls class="w-full rounded-box shadow-xl" src={"/premiere/videos/#{@movie.id}"}>
          </video>
        {/if}
      </div>
    </div>
    """
  end
end
