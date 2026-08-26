defmodule PhoenixHologram.Leads do
  @moduledoc """
  Captures "Start your story" signups from the home page.
  """

  alias PhoenixHologram.Leads.Lead
  alias PhoenixHologram.Repo

  def create_lead(attrs) do
    %Lead{}
    |> Lead.changeset(attrs)
    |> Repo.insert()
  end
end
