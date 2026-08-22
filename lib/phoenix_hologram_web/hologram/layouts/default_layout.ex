defmodule PhoenixHologramWeb.Hologram.Layouts.DefaultLayout do
  use Hologram.Component

  alias Hologram.UI.Runtime

  def template do
    ~HOLO"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Phoenix Hologram</title>
        <Runtime />
      </head>
      <body>
        <slot />
      </body>
    </html>
    """
  end
end
