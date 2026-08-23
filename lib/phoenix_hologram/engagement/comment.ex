defmodule PhoenixHologram.Engagement.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :movie_id, :id
    field :parent_id, :id
    field :body, :string
    field :session_id, :string
    timestamps(updated_at: false)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:movie_id, :parent_id, :body, :session_id])
    |> validate_required([:movie_id, :body, :session_id])
    |> validate_length(:body, min: 1, max: 2000)
  end
end
