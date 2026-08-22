defmodule PhoenixHologram.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_hologram,
    adapter: Ecto.Adapters.SQLite3
end
