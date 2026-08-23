defmodule PhoenixHologramWeb.Hologram.Pages.AdminMoviePage do
  @moduledoc """
  Per-movie scene browser: the movie's scene timeline (who's on screen,
  segmented every time that changes), plus every unique face recognised
  in it with a thumbnail and its own timestamp ranges.
  """

  use Hologram.Page
  use Hologram.JS

  alias Hologram.UI.Link
  alias PhoenixHologram.FaceDetection
  alias PhoenixHologram.FaceDetection.{Movie, SceneIndex}
  alias PhoenixHologram.FocusPoll
  alias PhoenixHologram.Repo
  alias PhoenixHologram.VideoMetadata
  alias PhoenixHologramWeb.Hologram.Pages.AdminMoviesPage
  alias PhoenixHologramWeb.Hologram.Pages.PlayerPage

  route "/admin/movies/:id"
  param :id, :integer

  layout PhoenixHologramWeb.Hologram.Layouts.DefaultLayout

  @bucket_ms 5 * 60 * 1000

  def init(params, component, _server) do
    movie_record = Repo.get(Movie, params.id)
    preloaded = movie_record && Repo.preload(movie_record, faces: :detections)

    focus_totals = if movie_record, do: FocusPoll.face_totals(movie_record.id), else: %{}
    scene_votes = if movie_record, do: scene_vote_counts(movie_record.id), else: %{}
    faces = if preloaded, do: Enum.map(preloaded.faces, &face_summary(&1, focus_totals)), else: []
    scene_buckets = if preloaded, do: movie_scene_buckets(preloaded, scene_votes), else: []
    movie = movie_record && build_movie(movie_record)

    component
    |> put_state(:movie, movie)
    |> put_state(:faces, faces)
    |> put_state(:face_count, length(faces))
    |> put_state(:scene_buckets, scene_buckets)
    |> put_state(:scene_open, false)
  end

  def action(:show_scene, params, component) do
    start_seconds = div(params.start_ms, 1000)
    end_seconds = div(params.end_ms, 1000)
    duration_ms = params.end_ms - params.start_ms

    # Media fragment start,end asks the browser itself to stop at the end
    # (native support varies), and :play_scene_video's own JS-side timer
    # enforces it explicitly regardless — belt and suspenders.
    fragment =
      if end_seconds > start_seconds,
        do: "#{start_seconds},#{end_seconds}",
        else: "#{start_seconds}"

    src = "/premiere/videos/#{params.movie_id}#t=#{fragment}"

    component
    |> put_state(:scene_open, true)
    |> put_action(
      name: :play_scene_video,
      params: %{src: src, duration_ms: duration_ms},
      delay: 0
    )
  end

  # The <video> has no `src` in the template at all — it's set here via
  # JS, not as a static attribute (that made the browser start its own
  # implicit fetch on mount, racing an explicit play() call). Calling
  # play() immediately after setting src turned out to still race the
  # browser's own resource-selection for the new source (the same
  # AbortException, just moved) — waiting for `loadedmetadata` before
  # calling play() is what actually settles it. The pause-after-duration
  # timer is a plain JS setTimeout started only once play() truly
  # resolves, so it measures real playback time rather than however long
  # metadata took to load.
  def action(:play_scene_video, params, component) do
    JS.exec("""
    const video = document.getElementById('scene-video');
    if (video) {
      video.pause();
      video.muted = true;
      video.src = #{inspect(params.src)};

      video.addEventListener('loadedmetadata', () => {
        video.play()
          .then(() => {
            if (#{params.duration_ms} > 0) {
              setTimeout(() => video.pause(), #{params.duration_ms});
            }
          })
          .catch((err) => console.warn('scene preview: play() rejected:', err));
      }, { once: true });
    }
    """)

    component
  end

  def action(:close_player, _params, component) do
    JS.exec("""
    const video = document.getElementById('scene-video');
    if (video) { video.pause(); }
    """)

    put_state(component, :scene_open, false)
  end

  # Actions run on the client (compiled to browser JS) — they can't do
  # database access, so this only extracts the form values and hands off
  # to a command (server-side) to actually persist them.
  def action(:save_label, params, component) do
    label = blank_to_nil(params.event["label"])
    subtitle = blank_to_nil(params.event["subtitle"])

    put_command(component, :persist_label,
      face_id: params.face_id,
      label: label,
      subtitle: subtitle
    )
  end

  def action(:label_saved, params, component) do
    faces =
      Enum.map(component.state.faces, fn face ->
        if face.id == params.face_id do
          %{face | label: params.label, subtitle: params.subtitle}
        else
          face
        end
      end)

    put_state(component, :faces, faces)
  end

  def action(:save_movie_title, params, component) do
    title = blank_to_nil(params.event["title"])
    put_command(component, :persist_movie_title, movie_id: params.movie_id, title: title)
  end

  def action(:movie_title_saved, params, component) do
    put_state(component, :movie, %{component.state.movie | title: params.title})
  end

  def command(:persist_label, params, server) do
    {:ok, _face} =
      FaceDetection.label_face(params.face_id, %{label: params.label, subtitle: params.subtitle})

    put_action(server, :label_saved,
      face_id: params.face_id,
      label: params.label,
      subtitle: params.subtitle
    )
  end

  def command(:persist_movie_title, params, server) do
    {:ok, movie} = FaceDetection.rename_movie(params.movie_id, params.title)

    put_action(server, :movie_title_saved,
      movie_id: params.movie_id,
      title: movie.title || movie.path
    )
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp scene_vote_counts(movie_id) do
    movie_id
    |> FocusPoll.all_votes()
    |> Enum.group_by(fn vote -> {vote.scene_start_ms, vote.scene_end_ms, vote.face_id} end)
    |> Map.new(fn {key, votes} -> {key, length(votes)} end)
  end

  defp movie_scene_buckets(preloaded_movie, scene_votes) do
    face_labels = Map.new(preloaded_movie.faces, fn face -> {face.id, face.label} end)

    preloaded_movie.faces
    |> Enum.flat_map(& &1.detections)
    |> SceneIndex.scenes()
    |> Enum.map(fn scene ->
      %{
        time: format_scene(scene),
        start_ms: scene.start_ms,
        end_ms: scene.end_ms,
        faces:
          Enum.map(scene.face_ids, fn face_id ->
            votes = Map.get(scene_votes, {scene.start_ms, scene.end_ms, face_id}, 0)
            label = Map.get(face_labels, face_id) || "Face ##{face_id}"
            %{id: face_id, votes: votes, label: label}
          end)
      }
    end)
    |> Enum.group_by(fn scene -> div(scene.start_ms, @bucket_ms) end)
    |> Enum.sort_by(fn {bucket_index, _scenes} -> bucket_index end)
    |> Enum.map(fn {bucket_index, scenes} ->
      %{
        label:
          "#{format_time(bucket_index * @bucket_ms)}–#{format_time((bucket_index + 1) * @bucket_ms)}",
        scene_count: length(scenes),
        scenes: scenes
      }
    end)
  end

  defp build_movie(movie) do
    %{
      id: movie.id,
      title: movie.title || movie.path,
      status: movie.status,
      description: movie |> VideoMetadata.fetch() |> VideoMetadata.describe(),
      thumbnail_url: "/premiere/videos/#{movie.id}/thumbnail"
    }
  end

  defp face_summary(face, focus_totals) do
    scenes =
      face.detections
      |> SceneIndex.ranges()
      |> Enum.map(fn range ->
        %{time: format_scene(range), start_ms: range.start_ms, end_ms: range.end_ms}
      end)

    %{
      id: face.id,
      label: face.label,
      subtitle: face.subtitle,
      scenes: scenes,
      focus_votes: Map.get(focus_totals, face.id, 0)
    }
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

  def template do
    ~HOLO"""
    <div class="min-h-screen bg-base-200 p-6">
      <div class="max-w-4xl mx-auto">
        <Link to={AdminMoviesPage} class="link link-hover text-sm">&larr; Back to admin</Link>

        {%if @movie == nil}
          <div class="card bg-base-100 shadow-xl mt-4">
            <div class="card-body">
              <p class="text-base-content/70">This film could not be found.</p>
            </div>
          </div>
        {%else}
          <div class="flex flex-col sm:flex-row gap-4 mt-4 mb-6">
            <img
              src={@movie.thumbnail_url}
              alt={@movie.title}
              class="w-full sm:w-96 aspect-video object-cover rounded-box shadow"
            />
            <div>
              <h1 class="text-2xl font-semibold">{@movie.title}</h1>
              <p class="text-sm text-base-content/70">{@movie.description}</p>
              <p class="text-sm text-base-content/60 mb-2">{@face_count} unique face(s) recognised</p>
              <Link to={PlayerPage, id: @movie.id} class="btn btn-primary btn-sm">
                Watch in Premiere Hall
              </Link>
              <details class="mt-2">
                <summary class="text-xs cursor-pointer text-base-content/60">Rename movie</summary>
                <form $submit={:save_movie_title, movie_id: @movie.id} class="flex gap-1 mt-1">
                  <input
                    type="text"
                    name="title"
                    value={@movie.title || ""}
                    placeholder="Movie name"
                    class="input input-xs input-bordered w-full max-w-xs"
                  />
                  <button type="submit" class="btn btn-xs btn-primary">Save</button>
                </form>
              </details>
            </div>
          </div>

          {%if @faces == []}
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <p class="text-base-content/70">
                  No faces detected yet. Run `mix face_detection.ingest` for this movie first.
                </p>
              </div>
            </div>
          {%else}
            <h2 class="text-xl font-semibold mb-3">Scenes</h2>
            <p class="text-sm text-base-content/60 mb-3">
              A new scene starts whenever who's on screen changes.
            </p>
            <div class="flex flex-col gap-2 mb-8">
              {%for bucket <- @scene_buckets}
                <details class="collapse collapse-arrow bg-base-100 border border-base-300 rounded-box">
                  <summary class="collapse-title font-medium">
                    {bucket.label} — {bucket.scene_count} scene(s)
                  </summary>
                  <div class="collapse-content max-h-96 overflow-y-auto">
                    <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                      {%for scene <- bucket.scenes}
                        <div class="card bg-base-200 shadow-sm min-h-40">
                          <div class="card-body items-center justify-center text-center p-3">
                            <h3
                              $click={:show_scene, start_ms: scene.start_ms, end_ms: scene.end_ms, movie_id: @movie.id}
                              class="card-title text-sm cursor-pointer hover:text-primary"
                            >
                              {scene.time}
                            </h3>
                            {%if scene.faces == []}
                              <span class="text-xs text-base-content/60">no one recognised</span>
                            {%else}
                              <div class="flex flex-wrap gap-2 justify-center">
                                {%for face <- scene.faces}
                                  <div class="flex flex-col items-center gap-0.5">
                                    <img
                                      src={"/admin/faces/#{face.id}/thumbnail"}
                                      title={face.label}
                                      class="w-14 h-14 rounded-full object-cover ring ring-base-300"
                                    />
                                    <span class="text-xs text-base-content/60">👁 {face.votes}</span>
                                  </div>
                                {/for}
                              </div>
                            {/if}
                          </div>
                        </div>
                      {/for}
                    </div>
                  </div>
                </details>
              {/for}
            </div>

            <h2 class="text-xl font-semibold mb-3">All recognised faces</h2>
            <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4 max-h-[36rem] overflow-y-auto pr-1">
              {%for face <- @faces}
                <div class="card bg-base-100 shadow-xl">
                  <figure class="px-4 pt-4">
                    <img src={"/admin/faces/#{face.id}/thumbnail"} class="rounded-box w-full aspect-square object-cover" />
                  </figure>
                  <div class="card-body items-center text-center h-64">
                    <h2 class="card-title text-base">{face.label || "Face ##{face.id}"}</h2>
                    {%if face.subtitle}
                      <p class="text-xs text-base-content/60 -mt-2">{face.subtitle}</p>
                    {/if}
                    <div class="badge badge-secondary badge-lg gap-1 text-base">
                      <span class="text-lg leading-none">👁</span> {face.focus_votes} in focus
                    </div>
                    <div class="flex flex-wrap gap-1 justify-center overflow-y-auto w-full flex-1 min-h-0">
                      {%for scene <- face.scenes}
                        <span
                          $click={:show_scene, start_ms: scene.start_ms, end_ms: scene.end_ms, movie_id: @movie.id}
                          class="badge badge-outline cursor-pointer hover:badge-primary"
                        >
                          {scene.time}
                        </span>
                      {/for}
                    </div>
                    <details class="w-full text-left">
                      <summary class="text-xs cursor-pointer text-base-content/60">Edit label</summary>
                      <form $submit={:save_label, face_id: face.id} class="flex flex-col gap-1 mt-1">
                        <input
                          type="text"
                          name="label"
                          value={face.label || ""}
                          placeholder="Name"
                          class="input input-xs input-bordered w-full"
                        />
                        <input
                          type="text"
                          name="subtitle"
                          value={face.subtitle || ""}
                          placeholder="Subtitle"
                          class="input input-xs input-bordered w-full"
                        />
                        <button type="submit" class="btn btn-xs btn-primary">Save</button>
                      </form>
                    </details>
                  </div>
                </div>
              {/for}
            </div>
          {/if}

          <div class={
            if @scene_open do
              "fixed bottom-4 right-4 z-50 w-80 bg-base-100 rounded-box shadow-2xl p-3"
            else
              "hidden"
            end
          }>
            <div class="flex justify-between items-center mb-2">
              <span class="text-sm font-medium">Scene preview (starts muted — unmute in the controls)</span>
              <button $click="close_player" class="btn btn-xs btn-circle btn-ghost">✕</button>
            </div>
            <video id="scene-video" controls muted class="w-full rounded"></video>
          </div>
        {/if}
      </div>
    </div>
    """
  end
end
