defmodule PhoenixHologram.FaceDetection.Clustering do
  @moduledoc """
  Groups face detections from a single video into unique identities.

  Each detection is a map that must include an `:embedding` (a list of
  floats, as produced by SFace). Detections whose embeddings are within
  `:threshold` cosine similarity of *any* other detection already in a
  cluster are merged into that cluster (single-linkage), via union-find.
  Everything else about a detection (bbox, frame_time_ms, ...) is passed
  through untouched.
  """

  # SFace's documented same-identity cosine-similarity threshold.
  @default_threshold 0.363

  @doc """
  Clusters `detections` and returns a list of clusters, each a
  non-empty list of the original detection maps, in stable order of
  first appearance.
  """
  def cluster(detections, opts \\ [])
  def cluster([], _opts), do: []

  def cluster(detections, opts) do
    threshold = Keyword.get(opts, :threshold, @default_threshold)
    indexed = Enum.with_index(detections)

    parent =
      indexed
      |> Enum.map(fn {_detection, i} -> {i, i} end)
      |> Map.new()

    parent =
      for {{d1, i}, {d2, j}} <- pairs(indexed),
          reduce: parent do
        parent ->
          if cosine_similarity(d1.embedding, d2.embedding) >= threshold do
            union(parent, i, j)
          else
            parent
          end
      end

    indexed
    |> Enum.group_by(fn {_detection, i} -> find(parent, i) end, fn {detection, _i} ->
      detection
    end)
    |> Enum.sort_by(fn {root, _members} -> root end)
    |> Enum.map(fn {_root, members} -> members end)
  end

  defp pairs(indexed) do
    for {a, i} <- indexed, {b, j} <- indexed, i < j, do: {{a, i}, {b, j}}
  end

  defp find(parent, i) do
    case Map.fetch!(parent, i) do
      ^i -> i
      p -> find(parent, p)
    end
  end

  defp union(parent, i, j) do
    root_i = find(parent, i)
    root_j = find(parent, j)

    if root_i == root_j do
      parent
    else
      Map.put(parent, root_i, root_j)
    end
  end

  defp cosine_similarity(a, b) do
    dot = a |> Enum.zip(b) |> Enum.reduce(0.0, fn {x, y}, acc -> acc + x * y end)
    dot / (norm(a) * norm(b))
  end

  defp norm(vector) do
    vector
    |> Enum.reduce(0.0, fn x, acc -> acc + x * x end)
    |> :math.sqrt()
  end
end
