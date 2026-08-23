defmodule PhoenixHologramWeb.FaceThumbnailControllerTest do
  use PhoenixHologramWeb.ConnCase

  test "GET /admin/faces/:id/thumbnail 404s for an unknown face", %{conn: conn} do
    conn = get(conn, ~p"/admin/faces/999999/thumbnail")
    assert conn.status == 404
  end
end
