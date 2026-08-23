defmodule PhoenixHologramWeb.Hologram.Layouts.DefaultLayout do
  use Hologram.Component

  alias Hologram.UI.Runtime

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
      <body class="min-h-screen flex flex-col">
        <header class="navbar bg-base-100 border-b border-base-300 px-6">
          <a href="/" class="text-lg font-semibold">Phoenix Hologram</a>
        </header>
        <main class="flex-1">
          <slot />
        </main>
        <footer class="footer footer-center bg-base-200 text-base-content/70 p-4 text-sm">
          <a href="/" class="link link-hover">&larr; Back to home</a>
        </footer>
      </body>
    </html>
    """
  end
end
