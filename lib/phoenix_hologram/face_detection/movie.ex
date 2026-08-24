defmodule PhoenixHologram.FaceDetection.Movie do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending processing done failed)

  schema "movies" do
    field(:path, :string)
    field(:title, :string)
    field(:status, :string, default: "pending")
    # Display order across every movie listing (Premiere Hall, admin, nav
    # dropdowns) — nil for movies ingested before this field existed, or
    # any movie nobody has explicitly ordered, sorts after every movie
    # that has a position (see FaceDetection.list_movies_ordered/0).
    field(:position, :integer)

    has_many(:faces, PhoenixHologram.FaceDetection.Face)

    timestamps(type: :utc_datetime)
  end

  def changeset(movie, attrs) do
    movie
    |> cast(attrs, [:path, :title, :status, :position])
    |> validate_required([:path])
    |> validate_inclusion(:status, @statuses)
  end
end
