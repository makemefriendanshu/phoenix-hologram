defmodule PhoenixHologram.FaceDetection.ClusteringTest do
  use ExUnit.Case, async: true

  alias PhoenixHologram.FaceDetection.Clustering

  describe "cluster/2" do
    test "returns an empty list for no detections" do
      assert Clustering.cluster([]) == []
    end

    test "a single detection forms its own cluster" do
      detection = %{label: :a, embedding: [1.0, 0.0, 0.0, 0.0]}
      assert [[^detection]] = Clustering.cluster([detection])
    end

    test "merges near-identical embeddings and keeps dissimilar ones apart" do
      detections = [
        %{label: :a1, embedding: [1.0, 0.0, 0.0, 0.0]},
        %{label: :a2, embedding: [0.98, 0.02, 0.0, 0.0]},
        %{label: :b1, embedding: [0.0, 1.0, 0.0, 0.0]},
        %{label: :b2, embedding: [0.02, 0.98, 0.0, 0.0]}
      ]

      clusters = Clustering.cluster(detections)

      assert labels_by_cluster(clusters) == [[:a1, :a2], [:b1, :b2]]
    end

    test "a stricter threshold can split an otherwise-merged pair" do
      detections = [
        %{label: :a1, embedding: [1.0, 0.0, 0.0, 0.0]},
        %{label: :a2, embedding: [0.9, 0.436, 0.0, 0.0]}
      ]

      assert labels_by_cluster(Clustering.cluster(detections)) == [[:a1, :a2]]
      assert labels_by_cluster(Clustering.cluster(detections, threshold: 0.99)) == [[:a1], [:a2]]
    end
  end

  defp labels_by_cluster(clusters) do
    clusters
    |> Enum.map(fn cluster -> cluster |> Enum.map(& &1.label) |> Enum.sort() end)
    |> Enum.sort()
  end
end
