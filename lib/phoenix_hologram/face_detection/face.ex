defmodule PhoenixHologram.FaceDetection.Face do
  use Ecto.Schema
  import Ecto.Changeset

  schema "faces" do
    field(:embedding, PhoenixHologram.FaceDetection.Embedding)

    belongs_to(:movie, PhoenixHologram.FaceDetection.Movie)
    has_many(:detections, PhoenixHologram.FaceDetection.Detection)

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(face, attrs) do
    face
    |> cast(attrs, [:movie_id, :embedding])
    |> validate_required([:movie_id, :embedding])
  end
end
