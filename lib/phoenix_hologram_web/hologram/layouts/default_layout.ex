defmodule PhoenixHologramWeb.Hologram.Layouts.DefaultLayout do
  use Hologram.Component

  alias Hologram.UI.Link
  alias Hologram.UI.Runtime
  alias PhoenixHologram.FaceDetection
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
    movies = FaceDetection.list_movies_ordered()

    component =
      component
      |> put_state(:hero_images, build_hero_images(movies))
      |> put_state(:themes, PhoenixHologramWeb.DaisyThemes.themes())
      |> put_state(
        :nav_movies,
        Enum.map(movies, fn movie ->
          %{
            id: movie.id,
            title: movie.title || movie.path,
            thumbnail_url: "/premiere/videos/#{movie.id}/thumbnail"
          }
        end)
      )

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
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <script>
          {%raw}
          (function () {
            // Applies the chosen daisyUI theme before first paint, and
            // exposes window.phSetTheme so the "Theme" nav dropdown below can
            // change it. Shares the "phx:theme" localStorage key and the
            // data-theme/data-theme-source attributes with root.html.heex, so
            // a theme picked on a Hologram page (e.g. /premiere) also applies
            // on the plain Phoenix "/" page, and vice versa.
            var STORAGE_KEY = 'phx:theme';

            function systemTheme() {
              return matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
            }

            function applyTheme(theme) {
              if (theme === 'system') {
                localStorage.removeItem(STORAGE_KEY);
                document.documentElement.setAttribute('data-theme', systemTheme());
                document.documentElement.setAttribute('data-theme-source', 'system');
              } else {
                localStorage.setItem(STORAGE_KEY, theme);
                document.documentElement.setAttribute('data-theme', theme);
                document.documentElement.setAttribute('data-theme-source', 'user');
              }
            }

            window.phSetTheme = applyTheme;
            applyTheme(localStorage.getItem(STORAGE_KEY) || 'system');

            matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function () {
              if (document.documentElement.getAttribute('data-theme-source') === 'system') {
                applyTheme('system');
              }
            });

            // Every nav dropdown (Premiere Hall, Recognised Faces, Theme)
            // stays open via CSS :focus-within, and clicking any item inside
            // it — a movie <Link>, a plain <a>, or a theme button — focuses
            // that item rather than clearing focus, so the menu never closes
            // on its own. Blur whatever the click landed on, for any dropdown,
            // regardless of whether the click also navigates or SPA-routes.
            document.addEventListener('click', function (e) {
              if (e.target.closest('.dropdown-content')) {
                document.activeElement && document.activeElement.blur();
              }
            });
          })();
          {/raw}
        </script>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Phoenix Hologram</title>
        <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
        <link rel="alternate icon" href="/favicon.ico" sizes="any" />
        <link rel="stylesheet" href="/assets/css/app.css" />
        <Runtime />
      </head>
      <body class="wedding-bg min-h-screen flex flex-col">
        <div class="card-stock border-b border-primary/30 px-6 py-4">
          <div class="max-w-5xl mx-auto flex items-start">
            <div class="flex-1">
              <a href="/">
                <img src="/images/logo.svg" class="h-14 sm:h-16 w-auto" alt="Shubh Vivah" />
              </a>
            </div>
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
                class="dropdown-content menu menu-sm bg-gradient-to-b from-primary to-primary/90 text-primary-content rounded-box z-20 mt-1 w-64 max-h-80 overflow-y-auto p-2 shadow normal-case tracking-normal text-left"
              >
                <li>
                  <a
                    href="/premiere"
                    class="font-display border-b border-primary-content/30 mb-1 hover:bg-secondary hover:text-primary-content"
                  >
                    All films
                  </a>
                </li>
                {%for movie <- @nav_movies}
                  <li>
                    <Link
                      to={PlayerPage, id: movie.id}
                      class="flex items-center gap-2 hover:bg-secondary hover:text-primary-content"
                    >
                      <img src={movie.thumbnail_url} class="w-10 h-7 object-cover rounded shrink-0" />
                      <span class="truncate">{movie.title}</span>
                    </Link>
                  </li>
                {/for}
              </ul>
            </div>
            <span class="opacity-50">|</span>
            <div class="dropdown">
              <div tabindex="0" role="button" class="hover:underline cursor-pointer">Recognised Faces ▾</div>
              <ul
                tabindex="0"
                class="dropdown-content menu menu-sm bg-gradient-to-b from-primary to-primary/90 text-primary-content rounded-box z-20 mt-1 w-64 max-h-80 overflow-y-auto p-2 shadow normal-case tracking-normal text-left"
              >
                <li>
                  <a
                    href="/admin"
                    class="font-display border-b border-primary-content/30 mb-1 hover:bg-secondary hover:text-primary-content"
                  >
                    All films
                  </a>
                </li>
                {%for movie <- @nav_movies}
                  <li>
                    <Link
                      to={AdminMoviePage, id: movie.id}
                      class="flex items-center gap-2 hover:bg-secondary hover:text-primary-content"
                    >
                      <img src={movie.thumbnail_url} class="w-10 h-7 object-cover rounded shrink-0" />
                      <span class="truncate">{movie.title}</span>
                    </Link>
                  </li>
                {/for}
              </ul>
            </div>
            <span class="opacity-50">|</span>
            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="hover:underline cursor-pointer">Theme ▾</div>
              <ul
                tabindex="0"
                class="dropdown-content menu menu-sm bg-gradient-to-b from-primary to-primary/90 text-primary-content rounded-box z-20 mt-1 w-48 max-h-80 overflow-y-auto p-2 shadow normal-case tracking-normal text-left"
              >
                <li>
                  <a
                    onclick="phSetTheme('system')"
                    class="cursor-pointer hover:bg-secondary hover:text-primary-content"
                  >
                    System
                  </a>
                </li>
                {%for theme <- @themes}
                  <li>
                    <a
                      onclick={"phSetTheme('#{theme}')"}
                      class="capitalize cursor-pointer hover:bg-secondary hover:text-primary-content"
                    >
                      {theme}
                    </a>
                  </li>
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

        <main id="page-content" class="flex-1">
          <slot />
        </main>
        <footer class="footer footer-center border-t border-primary/30 text-base-content/70 p-4 text-sm">
          <a href="/" class="link link-hover">&larr; Back to home</a>
        </footer>

        <script>
          {%raw}
          (function () {
            // The identity band, nav, and hero banner above #page-content
            // are identical on every page, so landing at the very top just
            // re-shows the same header on each navigation. The Hologram
            // client runtime forces window.scrollTo(0, 0) on every SPA
            // navigation (loadNewPage, right before history.pushState) -
            // wrapping pushState runs this right after that reset, in the
            // same synchronous tick, so it overrides the jump-to-top with a
            // landing just past the banner instead. Also covers a real full
            // page load or refresh, and browser back/forward (popstate).
            // Stops a bit short of aligning #page-content flush with the
            // viewport top, so the landing scroll distance is a little
            // shorter and the very bottom of the hero stays peeking in.
            var shortfallPx = 120;

            function scrollPastBanner() {
              var el = document.getElementById('page-content');
              if (!el) { return; }
              var targetY = el.getBoundingClientRect().top + window.scrollY - shortfallPx;
              window.scrollTo(0, Math.max(0, targetY));
            }

            scrollPastBanner();

            var originalPushState = history.pushState;
            history.pushState = function () {
              originalPushState.apply(history, arguments);
              scrollPastBanner();
            };

            window.addEventListener('popstate', scrollPastBanner);
          })();
          {/raw}
        </script>
      </body>
    </html>
    """
  end
end
