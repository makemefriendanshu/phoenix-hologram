defmodule PhoenixHologramWeb.PageController do
  use PhoenixHologramWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
