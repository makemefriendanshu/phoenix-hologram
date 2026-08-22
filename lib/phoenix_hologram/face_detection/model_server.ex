defmodule PhoenixHologram.FaceDetection.ModelServer do
  @moduledoc """
  Owns the YuNet face detector and SFace face-embedding models (loaded
  from `priv/face_detection/models/`, fetched by `mix face_detection.setup`)
  and runs them against single frames. Models are loaded lazily, on first
  use, so the app can boot fine on a machine that hasn't run the setup
  task yet — only actual detection calls fail until it has.
  """

  use GenServer

  @yunet_model "priv/face_detection/models/face_detection_yunet_2023mar.onnx"
  @sface_model "priv/face_detection/models/face_recognition_sface_2021dec.onnx"

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc """
  Detects faces in the image at `image_path`. Returns
  `{:ok, [%{bbox: {x, y, w, h}, confidence: float, embedding: [float]}]}`,
  or `{:error, reason}` — notably `{:error, :models_not_found}` if
  `mix face_detection.setup` hasn't been run yet.
  """
  def detect_faces(image_path) do
    GenServer.call(__MODULE__, {:detect_faces, image_path}, :infinity)
  end

  @impl true
  def init(_opts), do: {:ok, %{detector: nil, recognizer: nil, input_size: nil}}

  @impl true
  def handle_call({:detect_faces, image_path}, _from, state) do
    with {:ok, state} <- ensure_recognizer(state),
         %Evision.Mat{} = img <- Evision.imread(image_path),
         {h, w, _} <- Evision.Mat.shape(img),
         {:ok, state} <- ensure_detector(state, {w, h}) do
      {:reply, {:ok, detect(state, img)}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  defp detect(%{detector: detector, recognizer: recognizer}, img) do
    case Evision.FaceDetectorYN.detect(detector, img) do
      {_n, %Evision.Mat{} = faces} -> extract_faces(faces, recognizer, img)
      {_n, {:error, _}} -> []
    end
  end

  defp extract_faces(faces, recognizer, img) do
    {rows, cols} = Evision.Mat.shape(faces)

    for row_index <- 0..(rows - 1) do
      row = Evision.Mat.roi(faces, {0, row_index, cols, 1})

      [x, y, w, h | _landmarks_and_score] =
        values = row |> Evision.Mat.to_nx() |> Nx.to_flat_list()

      confidence = List.last(values)

      embedding =
        recognizer
        |> Evision.FaceRecognizerSF.alignCrop(img, row)
        |> then(&Evision.FaceRecognizerSF.feature(recognizer, &1))
        |> Evision.Mat.to_nx()
        |> Nx.to_flat_list()

      %{bbox: {x, y, w, h}, confidence: confidence, embedding: embedding}
    end
  end

  defp ensure_recognizer(%{recognizer: recognizer} = state) when not is_nil(recognizer) do
    {:ok, state}
  end

  defp ensure_recognizer(state) do
    with {:ok, path} <- model_path(@sface_model) do
      {:ok, %{state | recognizer: Evision.FaceRecognizerSF.create(path, "")}}
    end
  end

  defp ensure_detector(%{detector: detector, input_size: size} = state, size)
       when not is_nil(detector) do
    {:ok, state}
  end

  defp ensure_detector(%{detector: detector} = state, {w, h} = size) when not is_nil(detector) do
    Evision.FaceDetectorYN.setInputSize(detector, {w, h})
    {:ok, %{state | input_size: size}}
  end

  defp ensure_detector(state, {w, h} = size) do
    with {:ok, path} <- model_path(@yunet_model) do
      detector = Evision.FaceDetectorYN.create(path, "", {w, h})
      {:ok, %{state | detector: detector, input_size: size}}
    end
  end

  defp model_path(relative_path) do
    path = Application.app_dir(:phoenix_hologram, relative_path)

    if File.regular?(path) do
      {:ok, path}
    else
      {:error, :models_not_found}
    end
  end
end
