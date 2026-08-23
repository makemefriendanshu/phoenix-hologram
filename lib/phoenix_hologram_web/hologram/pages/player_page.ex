defmodule PhoenixHologramWeb.Hologram.Pages.PlayerPage do
  use Hologram.Page

  alias Hologram.UI.Link
  alias PhoenixHologram.Engagement
  alias PhoenixHologram.FaceDetection.{Movie, SceneIndex}
  alias PhoenixHologram.FocusPoll
  alias PhoenixHologram.Repo
  alias PhoenixHologram.VideoMetadata
  alias PhoenixHologram.VideoSegments
  alias PhoenixHologramWeb.Hologram.Pages.PremierePage

  route "/premiere/:id"
  param :id, :integer

  layout PhoenixHologramWeb.Hologram.Layouts.DefaultLayout

  def init(params, component, server) do
    movie_record = Repo.get(Movie, params.id)
    movie = build_details(movie_record)
    session_id = server.session_id

    component =
      component
      |> put_state(:movie, movie)
      |> put_state(:session_id, session_id)
      |> put_state(:movie_likes_count, movie && Engagement.movie_likes_count(movie.id) || 0)
      |> put_state(:movie_liked?, (movie && Engagement.movie_liked?(movie.id, session_id)) || false)
      |> put_state(:comments, (movie && Engagement.list_comments(movie.id, session_id)) || [])
      |> put_state(:new_comment_body, "")
      |> put_state(:replying_to, nil)
      |> put_state(:reply_body, "")

    scenes_list = (movie_record && movie_scenes(movie_record, session_id)) || []
    scenes_by_key = Map.new(scenes_list, &{scene_key(&1), &1})

    component =
      component
      |> put_state(:scenes, scenes_by_key)
      |> put_state(:current_scene, find_current_scene(scenes_list, 0))
      |> put_state(:scene_boundaries_json, scene_boundaries_json(scenes_list))

    server = if movie, do: put_subscription(server, {:focus_votes, movie.id}), else: server

    {component, server}
  end

  # Only start/end timestamps — enough for the client-side JS to figure out
  # which scene index is current as the video plays, without needing the
  # full per-scene face/vote data on that side.
  defp scene_boundaries_json(scenes) do
    scenes
    |> Enum.map(&%{start_ms: &1.start_ms, end_ms: &1.end_ms})
    |> Jason.encode!()
  end

  # Detections are sampled at ~1fps, so most scenes are single-instant
  # (start_ms == end_ms) with gaps between them — an exact-range match
  # would show "no one recognised" for nearly the whole video. Instead,
  # treat a scene as the current "who's on screen" state from its start
  # until the next detected change, capped so a long stretch with no
  # faces at all eventually clears rather than showing stale info.
  @stale_scene_tolerance_ms 5_000

  # Matches the "start:end" key the inline JS already computes to detect
  # scene transitions — reusing it lets the server do an O(1) Map lookup
  # instead of a linear scan through hundreds of scenes on every change.
  defp scene_key(%{start_ms: start_ms, end_ms: end_ms}), do: "#{start_ms}:#{end_ms}"
  defp scene_key(start_ms, end_ms), do: "#{start_ms}:#{end_ms}"

  defp find_current_scene(scenes, current_ms) do
    scenes
    |> Enum.filter(&(&1.start_ms <= current_ms))
    |> List.last()
    |> case do
      nil -> nil
      scene -> if current_ms - scene.end_ms <= @stale_scene_tolerance_ms, do: scene, else: nil
    end
  end

  defp movie_scenes(movie_record, session_id) do
    votes_by_scene =
      movie_record.id
      |> FocusPoll.all_votes()
      |> Enum.group_by(&{&1.scene_start_ms, &1.scene_end_ms})

    movie_record
    |> Repo.preload(faces: :detections)
    |> Map.fetch!(:faces)
    |> Enum.flat_map(& &1.detections)
    |> SceneIndex.scenes()
    |> Enum.map(fn scene ->
      scene_votes = Map.get(votes_by_scene, {scene.start_ms, scene.end_ms}, [])
      counts = Enum.frequencies_by(scene_votes, & &1.face_id)

      my_voted_faces =
        scene_votes |> Enum.filter(&(&1.session_id == session_id)) |> MapSet.new(& &1.face_id)

      %{
        start_ms: scene.start_ms,
        end_ms: scene.end_ms,
        time: format_scene(scene),
        faces:
          Enum.map(scene.face_ids, fn face_id ->
            %{
              id: face_id,
              thumbnail_url: "/admin/faces/#{face_id}/thumbnail",
              votes: Map.get(counts, face_id, 0),
              mine?: MapSet.member?(my_voted_faces, face_id)
            }
          end)
      }
    end)
  end

  defp format_scene(%{start_ms: start_ms, end_ms: end_ms}) do
    if start_ms == end_ms do
      format_time(start_ms)
    else
      "#{format_time(start_ms)}–#{format_time(end_ms)}"
    end
  end

  defp format_time(ms) do
    total_seconds = div(ms, 1000)
    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)
    padded_seconds = seconds |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{minutes}:#{padded_seconds}"
  end

  defp build_details(nil), do: nil

  defp build_details(movie) do
    metadata = VideoMetadata.fetch(movie)

    %{
      id: movie.id,
      title: movie.title || movie.path,
      status: movie.status,
      description: VideoMetadata.describe(metadata),
      video_url: "/premiere/videos/#{movie.id}",
      thumbnail_url: "/premiere/videos/#{movie.id}/thumbnail",
      download_url: "/premiere/videos/#{movie.id}/download",
      segment_downloads: segment_downloads(movie)
    }
  end

  defp segment_downloads(movie) do
    segment_count = movie |> VideoSegments.ensure_generated!() |> length()

    Enum.map(1..segment_count, fn part ->
      %{part: part, url: "/premiere/videos/#{movie.id}/download/#{part}"}
    end)
  end

  # Dispatched from plain JS (see the inline script in the template) only
  # when the resolved scene key actually changes — not on every tick — so
  # playback tracking doesn't force a full page re-render 5x/second. The
  # key is the same "start:end" string the JS already computed, so this
  # is an O(1) Map lookup rather than a scan through hundreds of scenes.
  def action(:scene_changed, params, component) do
    scene = Map.get(component.state.scenes, params.scene_key)
    put_state(component, :current_scene, scene)
  end

  def action(:update_comment_body, params, component) do
    put_state(component, :new_comment_body, params.event.value)
  end

  def action(:update_reply_body, params, component) do
    put_state(component, :reply_body, params.event.value)
  end

  def action(:start_reply, params, component) do
    component
    |> put_state(:replying_to, params.comment_id)
    |> put_state(:reply_body, "")
  end

  def action(:cancel_reply, _params, component) do
    component
    |> put_state(:replying_to, nil)
    |> put_state(:reply_body, "")
  end

  def action(:movie_like_toggled, params, component) do
    component
    |> put_state(:movie_likes_count, params.count)
    |> put_state(:movie_liked?, params.liked?)
  end

  def action(:comment_added, params, component) do
    component
    |> put_state(:comments, params.comments)
    |> put_state(:new_comment_body, "")
  end

  def action(:reply_added, params, component) do
    component
    |> put_state(:comments, params.comments)
    |> put_state(:reply_body, "")
    |> put_state(:replying_to, nil)
  end

  def action(:comments_updated, params, component) do
    put_state(component, :comments, params.comments)
  end

  def action(:focus_vote_updated, params, component) do
    my_session_id = component.state.session_id
    is_mine = params.voter_session_id == my_session_id
    key = scene_key(params.scene_start_ms, params.scene_end_ms)

    scenes =
      Map.update!(component.state.scenes, key, fn scene ->
        faces =
          Enum.map(scene.faces, fn face ->
            votes = Map.get(params.counts, face.id, 0)

            mine? =
              if is_mine and face.id == params.face_id, do: params.voted?, else: face.mine?

            %{face | votes: votes, mine?: mine?}
          end)

        %{scene | faces: faces}
      end)

    current_scene =
      case component.state.current_scene do
        %{start_ms: s, end_ms: e} when s == params.scene_start_ms and e == params.scene_end_ms ->
          Map.get(scenes, key)

        other ->
          other
      end

    component
    |> put_state(:scenes, scenes)
    |> put_state(:current_scene, current_scene)
  end

  def command(:like_movie, %{movie_id: movie_id}, server) do
    {status, count} = Engagement.toggle_movie_like(movie_id, server.session_id)
    put_action(server, :movie_like_toggled, count: count, liked?: status == :liked)
  end

  def command(:add_comment, %{movie_id: movie_id, body: body}, server) do
    Engagement.add_comment(movie_id, body, server.session_id)
    comments = Engagement.list_comments(movie_id, server.session_id)
    put_action(server, :comment_added, comments: comments)
  end

  def command(:add_reply, %{movie_id: movie_id, parent_id: parent_id, body: body}, server) do
    Engagement.add_comment(movie_id, body, server.session_id, parent_id)
    comments = Engagement.list_comments(movie_id, server.session_id)
    put_action(server, :reply_added, comments: comments)
  end

  def command(:like_comment, %{movie_id: movie_id, comment_id: comment_id}, server) do
    Engagement.toggle_comment_like(comment_id, server.session_id)
    comments = Engagement.list_comments(movie_id, server.session_id)
    put_action(server, :comments_updated, comments: comments)
  end

  def command(:delete_comment, %{movie_id: movie_id, comment_id: comment_id}, server) do
    Engagement.delete_comment(comment_id, server.session_id)
    comments = Engagement.list_comments(movie_id, server.session_id)
    put_action(server, :comments_updated, comments: comments)
  end

  def command(
        :cast_focus_vote,
        %{movie_id: movie_id, scene_start_ms: scene_start_ms, scene_end_ms: scene_end_ms, face_id: face_id},
        server
      ) do
    {counts, voted?} =
      FocusPoll.toggle_vote(movie_id, scene_start_ms, scene_end_ms, face_id, server.session_id)

    put_broadcast(server, {:focus_votes, movie_id}, :focus_vote_updated,
      scene_start_ms: scene_start_ms,
      scene_end_ms: scene_end_ms,
      counts: counts,
      voter_session_id: server.session_id,
      face_id: face_id,
      voted?: voted?
    )
  end

  def template do
    ~HOLO"""
    <div class="min-h-screen bg-base-200 p-6">
      <div class="max-w-5xl mx-auto">
        <Link to={PremierePage} class="link link-hover text-sm">&larr; Back to Premiere Hall</Link>

        {%if @movie == nil}
          <div class="card bg-base-100 shadow-xl mt-4">
            <div class="card-body">
              <p class="text-base-content/70">This film could not be found.</p>
            </div>
          </div>
        {%else}
          <h1 class="text-2xl font-semibold mt-4 mb-1">{@movie.title}</h1>
          <div class="flex items-center gap-3 mb-4">
            <p class="text-sm text-base-content/70">{@movie.description}</p>
            <span class="badge badge-outline">{@movie.status}</span>
          </div>

          <div class="flex flex-col lg:flex-row gap-4 lg:items-stretch">
            <div class="flex-1 min-w-0">
              <video
                id="player-video"
                data-scene-boundaries={@scene_boundaries_json}
                controls
                poster={@movie.thumbnail_url}
                class="w-full rounded-box shadow-xl"
                src={@movie.video_url}
              >
              </video>
              <script>
                {%raw}
                (function () {
                  if (window.__focusPollAttached) { return; }
                  window.__focusPollAttached = true;

                  var scenes = null;
                  var staleToleranceMs = 5000;
                  var lastKey = "unset";

                  function resolveScene(currentMs) {
                    var idx = -1;
                    for (var i = 0; i < scenes.length; i++) {
                      if (scenes[i].start_ms <= currentMs) {
                        idx = i;
                      } else {
                        break;
                      }
                    }
                    if (idx === -1) { return null; }
                    if (currentMs - scenes[idx].end_ms > staleToleranceMs) { return null; }
                    return scenes[idx];
                  }

                  setInterval(function () {
                    var video = document.getElementById('player-video');
                    if (!video) { return; }

                    if (scenes === null) {
                      scenes = JSON.parse(video.dataset.sceneBoundaries || "[]");
                    }

                    var currentMs = Math.round(video.currentTime * 1000);
                    var scene = resolveScene(currentMs);
                    var key = scene ? (scene.start_ms + ":" + scene.end_ms) : "none";

                    if (key !== lastKey) {
                      lastKey = key;
                      Hologram.dispatchAction('scene_changed', 'page', { scene_key: key });
                    }
                  }, 200);
                })();
                {/raw}
              </script>

              <div class="mt-4 flex items-center gap-2">
                <button
                  $click={command: :like_movie, params: %{movie_id: @movie.id}}
                  class={if @movie_liked? do "btn btn-sm btn-error" else "btn btn-sm btn-outline" end}
                >
                  {%if @movie_liked?}♥ Liked{%else}♥ Like{/if}
                </button>
                <span class="text-sm text-base-content/70">{@movie_likes_count} like(s)</span>
              </div>
            </div>

            <div class="lg:w-96 shrink-0 flex flex-col">
              <div class="card bg-base-100 shadow flex-1 flex flex-col min-h-0 overflow-hidden">
                <div class="card-body py-4 flex-1 flex flex-col min-h-0">
                  <h2 class="text-lg font-semibold mb-1">Who's in focus?</h2>
                  {%if @current_scene == nil}
                    <p class="text-sm text-base-content/60">No one recognised at this point in the video.</p>
                  {%else}
                    <div class="flex items-center gap-2 mb-2">
                      <span class="badge badge-outline whitespace-nowrap">{@current_scene.time}</span>
                      <span class="text-xs text-base-content/60">Vote live for who's on screen</span>
                    </div>
                    <div class="flex-1 min-h-0 flex flex-col gap-3 overflow-y-auto">
                      {%for face <- @current_scene.faces}
                        <button
                          $click={command: :cast_focus_vote, params: %{movie_id: @movie.id, scene_start_ms: @current_scene.start_ms, scene_end_ms: @current_scene.end_ms, face_id: face.id}}
                          class={if face.mine? do "btn btn-primary h-auto py-3 justify-start gap-3" else "btn btn-outline h-auto py-3 justify-start gap-3" end}
                        >
                          <img src={face.thumbnail_url} class="w-16 h-16 rounded-full object-cover shrink-0" />
                          <span class="text-base normal-case">{face.votes} vote(s)</span>
                        </button>
                      {/for}
                    </div>
                  {/if}
                </div>
              </div>
            </div>
          </div>

          <div class="mt-6">
            <h2 class="text-sm font-semibold mb-2">Download</h2>
            <a href={@movie.download_url} download class="btn btn-sm btn-outline mb-2">
              Download full movie
            </a>
            <p class="text-xs text-base-content/60 mb-2">
              Or download in parts — each part is its own independently playable clip
              (no need to join them), useful on a slow connection since each can be
              retried on its own:
            </p>
            <div class="flex flex-wrap gap-2">
              {%for segment <- @movie.segment_downloads}
                <a href={segment.url} download class="btn btn-xs btn-outline">
                  Part {segment.part}
                </a>
              {/for}
            </div>
          </div>

          <div class="mt-8">
            <h2 class="text-lg font-semibold mb-3">Comments</h2>

            <form $submit={command: :add_comment, params: %{movie_id: @movie.id, body: @new_comment_body}}>
              <div class="flex gap-2 mb-4">
                <input
                  type="text"
                  value={@new_comment_body}
                  $change="update_comment_body"
                  placeholder="Add a comment..."
                  class="input input-bordered input-sm flex-1"
                />
                <button type="submit" class="btn btn-sm btn-primary">Post</button>
              </div>
            </form>

            <div class="max-h-96 overflow-y-auto pr-1">
            {%if @comments == []}
              <p class="text-sm text-base-content/60">No comments yet.</p>
            {%else}
              <div class="flex flex-col gap-3">
                {%for comment <- @comments}
                  <div class="card bg-base-100 shadow">
                    <div class="card-body py-3">
                      <div class="flex items-center justify-between">
                        <p class="text-sm">{comment.body}</p>
                        <div class="flex items-center gap-2 shrink-0 ml-3">
                          <button
                            $click={command: :like_comment, params: %{movie_id: @movie.id, comment_id: comment.id}}
                            class={if comment.liked? do "btn btn-xs btn-error" else "btn btn-xs btn-ghost" end}
                          >
                            ♥ {comment.likes_count}
                          </button>
                          <button
                            $click={action: :start_reply, params: %{comment_id: comment.id}}
                            class="btn btn-xs btn-ghost"
                          >
                            Reply
                          </button>
                          {%if comment.own?}
                            <button
                              $click={command: :delete_comment, params: %{movie_id: @movie.id, comment_id: comment.id}}
                              class="btn btn-xs btn-ghost text-error"
                            >
                              Delete
                            </button>
                          {/if}
                        </div>
                      </div>

                      <form
                        $submit={command: :add_reply, params: %{movie_id: @movie.id, parent_id: comment.id, body: @reply_body}}
                        class={if @replying_to == comment.id do "mt-2 ml-4" else "hidden" end}
                      >
                        <div class="flex gap-2">
                          <input
                            type="text"
                            value={@reply_body}
                            $change="update_reply_body"
                            placeholder="Write a reply..."
                            class="input input-bordered input-xs flex-1"
                          />
                          <button type="submit" class="btn btn-xs btn-primary">Reply</button>
                          <button type="button" $click="cancel_reply" class="btn btn-xs btn-ghost">
                            Cancel
                          </button>
                        </div>
                      </form>

                      {%if comment.replies != []}
                        <div class="flex flex-col gap-2 mt-3 ml-6 border-l-2 border-base-300 pl-3">
                          {%for reply <- comment.replies}
                            <div class="flex items-center justify-between">
                              <p class="text-sm">{reply.body}</p>
                              <div class="flex items-center gap-2 shrink-0 ml-3">
                                <button
                                  $click={command: :like_comment, params: %{movie_id: @movie.id, comment_id: reply.id}}
                                  class={if reply.liked? do "btn btn-xs btn-error" else "btn btn-xs btn-ghost" end}
                                >
                                  ♥ {reply.likes_count}
                                </button>
                                {%if reply.own?}
                                  <button
                                    $click={command: :delete_comment, params: %{movie_id: @movie.id, comment_id: reply.id}}
                                    class="btn btn-xs btn-ghost text-error"
                                  >
                                    Delete
                                  </button>
                                {/if}
                              </div>
                            </div>
                          {/for}
                        </div>
                      {/if}
                    </div>
                  </div>
                {/for}
              </div>
            {/if}
            </div>
          </div>
        {/if}
      </div>
    </div>
    """
  end
end
