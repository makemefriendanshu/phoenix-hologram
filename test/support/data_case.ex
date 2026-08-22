defmodule PhoenixHologram.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring access to the
  application's data layer.

  Such tests rely on `PhoenixHologram.Repo` and also enable the SQL
  sandbox, so changes done to the database are reverted at the end of
  every test.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias PhoenixHologram.Repo
    end
  end

  setup tags do
    PhoenixHologram.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(PhoenixHologram.Repo, shared: not tags[:async])
    ExUnit.Callbacks.on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
