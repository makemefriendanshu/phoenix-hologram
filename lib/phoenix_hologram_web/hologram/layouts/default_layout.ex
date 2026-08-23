defmodule PhoenixHologramWeb.Hologram.Layouts.DefaultLayout do
  use Hologram.Component

  alias Hologram.UI.Link
  alias Hologram.UI.Runtime
  alias PhoenixHologram.FaceDetection.Movie
  alias PhoenixHologram.Repo
  alias PhoenixHologramWeb.Hologram.Pages.AdminMoviePage
  alias PhoenixHologramWeb.Hologram.Pages.PlayerPage

  # Shared site banner (identity band + gold nav + crossfading photo hero)
  # shown above every Hologram page — lives here, not in each page, so it
  # renders once regardless of which page is wrapped in <slot />. Fixed
  # slide count so the CSS crossfade timeline (see .hero-slide /
  # @keyframes hero-crossfade in app.css) can use static percentages —
  # movies are cycled with rem/2 to fill all 4 slots even if there are
  # fewer than 4 of them.
  @hero_slide_count 4
  @hero_slide_seconds 5

  def init(_props, component, server) do
    movies = Repo.all(Movie)

    component =
      component
      |> put_state(:hero_images, build_hero_images(movies))
      |> put_state(:nav_movies, Enum.map(movies, &%{id: &1.id, title: &1.title || &1.path}))

    {component, server}
  end

  defp build_hero_images([]), do: []

  defp build_hero_images(movies) do
    Enum.map(0..(@hero_slide_count - 1), fn i ->
      movie = Enum.at(movies, rem(i, length(movies)))
      %{url: "/premiere/videos/#{movie.id}/thumbnail", delay_s: i * @hero_slide_seconds}
    end)
  end

  def template do
    ~HOLO"""
    <!DOCTYPE html>
    <html lang="en" data-theme="light">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Phoenix Hologram</title>
        <link rel="stylesheet" href="/assets/css/app.css" />
        <Runtime />
      </head>
      <body class="wedding-bg min-h-screen flex flex-col">
        <div class="card-stock border-b border-primary/30 px-6 py-4">
          <div class="max-w-5xl mx-auto flex items-start">
            <div class="flex-1"></div>
            <div class="flex-1 text-center">
              <a href="/" class="font-display text-3xl sm:text-4xl text-secondary tracking-wide">Shubh Vivaha</a>
              <p class="text-xs italic text-base-content/60 -mt-1">(A sacred union)</p>
            </div>
            <div class="flex-1 text-right pt-2">
              <span class="font-display text-[0.65rem] sm:text-xs tracking-[0.25em] uppercase text-primary">
                Celebrating Forever
              </span>
            </div>
          </div>
        </div>

        <nav class="bg-gradient-to-r from-primary/60 via-primary to-primary/60 text-primary-content">
          <div class="max-w-5xl mx-auto flex flex-wrap justify-center items-center gap-x-3 gap-y-1 py-2 px-4 text-[0.65rem] sm:text-xs font-display tracking-[0.15em] uppercase">
            <div class="dropdown">
              <div tabindex="0" role="button" class="hover:underline cursor-pointer">Premiere Hall ▾</div>
              <ul
                tabindex="0"
                class="dropdown-content menu menu-sm card-stock rounded-box z-20 mt-1 w-64 max-h-80 overflow-y-auto p-2 shadow normal-case tracking-normal text-left"
              >
                <li><a href="/premiere">All films</a></li>
                {%for movie <- @nav_movies}
                  <li><Link to={PlayerPage, id: movie.id}>{movie.title}</Link></li>
                {/for}
              </ul>
            </div>
            <span class="opacity-50">|</span>
            <div class="dropdown">
              <div tabindex="0" role="button" class="hover:underline cursor-pointer">Recognised Faces ▾</div>
              <ul
                tabindex="0"
                class="dropdown-content menu menu-sm card-stock rounded-box z-20 mt-1 w-64 max-h-80 overflow-y-auto p-2 shadow normal-case tracking-normal text-left"
              >
                <li><a href="/admin">All films</a></li>
                {%for movie <- @nav_movies}
                  <li><Link to={AdminMoviePage, id: movie.id}>{movie.title}</Link></li>
                {/for}
              </ul>
            </div>
          </div>
        </nav>

        <div class="relative h-64 sm:h-80 border-b-4 border-primary overflow-hidden">
          {%if @hero_images == []}
            <div class="absolute inset-0 wedding-bg"></div>
          {%else}
            {%for slide <- @hero_images}
              <img src={slide.url} style={"animation-delay: #{slide.delay_s}s"} class="hero-slide" />
            {/for}
          {/if}
          <div class="absolute inset-0 bg-gradient-to-t from-secondary/85 via-secondary/15 to-transparent"></div>
          <div class="absolute inset-x-0 bottom-0 px-6 pb-6 sm:pb-10 text-center">
            <div class="inline-block border border-primary/80 px-6 py-4 sm:px-14 sm:py-6">
              <p class="font-display text-primary-content text-base sm:text-2xl tracking-wide">
                Welcome to Shubh Vivaha —
              </p>
              <p class="font-display text-primary-content/90 text-sm sm:text-xl mt-1">
                Where Love Begins &amp; Tradition Flourishes
              </p>
            </div>
          </div>
        </div>

        <main class="flex-1">
          <slot />
        </main>
        <footer class="footer footer-center border-t border-primary/30 text-base-content/70 p-4 text-sm">
          <a href="/" class="link link-hover">&larr; Back to home</a>
        </footer>
      </body>
    </html>
    """
  end
end
