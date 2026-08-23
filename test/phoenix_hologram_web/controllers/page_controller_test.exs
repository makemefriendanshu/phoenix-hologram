defmodule PhoenixHologramWeb.PageControllerTest do
  use PhoenixHologramWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Watch your films, interactively."
  end
end
