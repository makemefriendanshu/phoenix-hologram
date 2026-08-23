defmodule PhoenixHologram.Engagement do
  @moduledoc """
  Likes and comments for movies, and likes on those comments. A like is
  keyed by (subject, session_id), so clicking again within the same
  session toggles it off rather than adding another one.
  """

  import Ecto.Query

  alias PhoenixHologram.Engagement.{Comment, CommentLike, MovieLike}
  alias PhoenixHologram.Repo

  @spec movie_likes_count(integer) :: non_neg_integer
  def movie_likes_count(movie_id) do
    MovieLike |> where(movie_id: ^movie_id) |> Repo.aggregate(:count)
  end

  @spec movie_liked?(integer, String.t()) :: boolean
  def movie_liked?(movie_id, session_id) do
    Repo.exists?(from m in MovieLike, where: m.movie_id == ^movie_id and m.session_id == ^session_id)
  end

  @doc "Toggles this session's like on a movie. Returns {:liked | :unliked, new_count}."
  @spec toggle_movie_like(integer, String.t()) :: {:liked | :unliked, non_neg_integer}
  def toggle_movie_like(movie_id, session_id) do
    case Repo.get_by(MovieLike, movie_id: movie_id, session_id: session_id) do
      nil ->
        %MovieLike{}
        |> MovieLike.changeset(%{movie_id: movie_id, session_id: session_id})
        |> Repo.insert!()

        {:liked, movie_likes_count(movie_id)}

      like ->
        Repo.delete!(like)
        {:unliked, movie_likes_count(movie_id)}
    end
  end

  @doc """
  Lists this movie's top-level comments (newest first), each with its
  replies nested under `:replies` (oldest first, one level deep).
  """
  @spec list_comments(integer, String.t()) :: [map]
  def list_comments(movie_id, session_id) do
    all =
      Comment
      |> where(movie_id: ^movie_id)
      |> order_by(asc: :inserted_at)
      |> Repo.all()

    by_parent = Enum.group_by(all, & &1.parent_id)

    by_parent
    |> Map.get(nil, [])
    |> Enum.reverse()
    |> Enum.map(fn comment ->
      replies = by_parent |> Map.get(comment.id, []) |> Enum.map(&comment_view(&1, session_id))
      comment |> comment_view(session_id) |> Map.put(:replies, replies)
    end)
  end

  @doc "Adds a top-level comment, or a reply when `parent_id` is given."
  @spec add_comment(integer, String.t(), String.t(), String.t(), integer | nil) ::
          {:ok, Comment.t()} | {:error, Ecto.Changeset.t()}
  def add_comment(movie_id, body, session_id, author_name, parent_id \\ nil) do
    %Comment{}
    |> Comment.changeset(%{
      movie_id: movie_id,
      body: body,
      session_id: session_id,
      author_name: author_name,
      parent_id: parent_id
    })
    |> Repo.insert()
  end

  @doc """
  Deletes a comment (and its replies, if any) if it belongs to `session_id`.
  No-op (returns `{:error, :not_found_or_forbidden}`) otherwise.
  """
  @spec delete_comment(integer, String.t()) :: {:ok, Comment.t()} | {:error, atom}
  def delete_comment(comment_id, session_id) do
    case Repo.get(Comment, comment_id) do
      %Comment{session_id: ^session_id} = comment ->
        Repo.delete_all(from c in Comment, where: c.parent_id == ^comment.id)
        Repo.delete(comment)

      _ ->
        {:error, :not_found_or_forbidden}
    end
  end

  @spec comment_likes_count(integer) :: non_neg_integer
  def comment_likes_count(comment_id) do
    CommentLike |> where(comment_id: ^comment_id) |> Repo.aggregate(:count)
  end

  @spec comment_liked?(integer, String.t()) :: boolean
  def comment_liked?(comment_id, session_id) do
    Repo.exists?(
      from c in CommentLike, where: c.comment_id == ^comment_id and c.session_id == ^session_id
    )
  end

  @doc "Toggles this session's like on a comment. Returns {:liked | :unliked, new_count}."
  @spec toggle_comment_like(integer, String.t()) :: {:liked | :unliked, non_neg_integer}
  def toggle_comment_like(comment_id, session_id) do
    case Repo.get_by(CommentLike, comment_id: comment_id, session_id: session_id) do
      nil ->
        %CommentLike{}
        |> CommentLike.changeset(%{comment_id: comment_id, session_id: session_id})
        |> Repo.insert!()

        {:liked, comment_likes_count(comment_id)}

      like ->
        Repo.delete!(like)
        {:unliked, comment_likes_count(comment_id)}
    end
  end

  defp comment_view(comment, session_id) do
    name = display_name(comment.author_name)

    %{
      id: comment.id,
      body: comment.body,
      author_name: name,
      author_initial: name |> String.slice(0, 1) |> String.upcase(),
      likes_count: comment_likes_count(comment.id),
      liked?: comment_liked?(comment.id, session_id),
      own?: comment.session_id == session_id
    }
  end

  defp display_name(nil), do: "Anonymous"
  defp display_name(""), do: "Anonymous"
  defp display_name(name), do: name
end
