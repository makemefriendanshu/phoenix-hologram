defmodule PhoenixHologram.FaceDetection.Movie do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending processing done failed)

  schema "movies" do
    field(:path, :string)
    field(:title, :string)
    field(:status, :string, default: "pending")

    has_many(:faces, PhoenixHologram.FaceDetection.Face)

    timestamps(type: :utc_datetime)
  end

  def changeset(movie, attrs) do
    movie
    |> cast(attrs, [:path, :title, :status])
    |> validate_required([:path])
    |> validate_inclusion(:status, @statuses)
  end
end
