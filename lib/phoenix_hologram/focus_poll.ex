defmodule PhoenixHologram.FocusPoll do
  @moduledoc """
  "Who's in focus?" live polling: for a given scene (a movie + time
  range), each viewer session can vote for one of the faces present in
  that scene. Voting again for the same scene moves the vote rather
  than adding another one, so counts stay one-vote-per-session.
  """

  import Ecto.Query

  alias PhoenixHologram.FocusPoll.Vote
  alias PhoenixHologram.Repo

  @doc "Casts (or moves) this session's vote for a scene. Returns the scene's updated {face_id => count} map."
  @spec vote(integer, integer, integer, integer, String.t()) :: %{integer => non_neg_integer}
  def vote(movie_id, scene_start_ms, scene_end_ms, face_id, session_id) do
    attrs = %{
      movie_id: movie_id,
      scene_start_ms: scene_start_ms,
      scene_end_ms: scene_end_ms,
      face_id: face_id,
      session_id: session_id
    }

    case Repo.get_by(Vote,
           movie_id: movie_id,
           scene_start_ms: scene_start_ms,
           scene_end_ms: scene_end_ms,
           session_id: session_id
         ) do
      nil -> %Vote{} |> Vote.changeset(attrs) |> Repo.insert!()
      existing -> existing |> Vote.changeset(attrs) |> Repo.update!()
    end

    scene_counts(movie_id, scene_start_ms, scene_end_ms)
  end

  @doc "Returns {face_id => vote count} for one scene."
  @spec scene_counts(integer, integer, integer) :: %{integer => non_neg_integer}
  def scene_counts(movie_id, scene_start_ms, scene_end_ms) do
    Vote
    |> where(movie_id: ^movie_id, scene_start_ms: ^scene_start_ms, scene_end_ms: ^scene_end_ms)
    |> group_by([v], v.face_id)
    |> select([v], {v.face_id, count(v.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc "Returns this session's currently-voted face_id for a scene, or nil."
  @spec my_vote(integer, integer, integer, String.t()) :: integer | nil
  def my_vote(movie_id, scene_start_ms, scene_end_ms, session_id) do
    Vote
    |> where(
      movie_id: ^movie_id,
      scene_start_ms: ^scene_start_ms,
      scene_end_ms: ^scene_end_ms,
      session_id: ^session_id
    )
    |> select([v], v.face_id)
    |> Repo.one()
  end

  @doc """
  Returns every vote for a movie as `%{scene_start_ms:, scene_end_ms:, face_id:, session_id:}`
  maps, for callers that need per-scene counts/my-vote across many scenes at
  once — one query instead of two per scene.
  """
  @spec all_votes(integer) :: [map]
  def all_votes(movie_id) do
    Vote
    |> where(movie_id: ^movie_id)
    |> select([v], %{
      scene_start_ms: v.scene_start_ms,
      scene_end_ms: v.scene_end_ms,
      face_id: v.face_id,
      session_id: v.session_id
    })
    |> Repo.all()
  end

  @doc "Returns {face_id => total vote count across all scenes} for a movie, for the admin view."
  @spec face_totals(integer) :: %{integer => non_neg_integer}
  def face_totals(movie_id) do
    Vote
    |> where(movie_id: ^movie_id)
    |> group_by([v], v.face_id)
    |> select([v], {v.face_id, count(v.id)})
    |> Repo.all()
    |> Map.new()
  end
end
