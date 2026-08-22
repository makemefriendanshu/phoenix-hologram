defmodule PhoenixHologram.FaceDetection.Detection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "face_detections" do
    field(:frame_time_ms, :integer)
    field(:bbox_x, :float)
    field(:bbox_y, :float)
    field(:bbox_w, :float)
    field(:bbox_h, :float)
    field(:confidence, :float)

    belongs_to(:face, PhoenixHologram.FaceDetection.Face)
  end

  def changeset(detection, attrs) do
    detection
    |> cast(attrs, [:face_id, :frame_time_ms, :bbox_x, :bbox_y, :bbox_w, :bbox_h, :confidence])
    |> validate_required([
      :face_id,
      :frame_time_ms,
      :bbox_x,
      :bbox_y,
      :bbox_w,
      :bbox_h,
      :confidence
    ])
  end
end
