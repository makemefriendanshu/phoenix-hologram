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
    # Admin-authored blurb, event date, and location shown on movie cards
    # in place of raw file metadata (Premiere Hall, admin) — all nil until
    # an admin fills them in, in which case the card just omits them.
    field(:description, :string)
    field(:event_date, :date)
    field(:location, :string)

    has_many(:faces, PhoenixHologram.FaceDetection.Face)

    timestamps(type: :utc_datetime)
  end

  def changeset(movie, attrs) do
    movie
    |> cast(attrs, [:path, :title, :status, :position])
    |> validate_required([:path])
    |> validate_inclusion(:status, @statuses)
  end

  @doc "Changeset for admin-authored listing details: blurb, event date, and location."
  def details_changeset(movie, attrs) do
    cast(movie, attrs, [:description, :event_date, :location])
  end
end
