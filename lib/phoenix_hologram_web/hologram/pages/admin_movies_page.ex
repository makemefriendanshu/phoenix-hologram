defmodule PhoenixHologramWeb.Hologram.Pages.AdminMoviesPage do
  @moduledoc """
  Admin index: every ingested movie, with how many unique faces were
  recognised in it so far. Links into `AdminMoviePage` for the
  per-movie scene browser. Also hosts the "Promo Requests" review queue
  for UpgradePage's "Know the founder personally?" free-access
  requests — approving one there grants the requested tier through
  `PhoenixHologram.PromoRequests.approve_promo_request/1`, the only
  place that actually happens (submitting a request no longer grants
  anything by itself).
  """

  use Hologram.Page

  alias Hologram.UI.Link
  alias PhoenixHologram.FaceDetection
  alias PhoenixHologram.PromoRequests
  alias PhoenixHologram.Repo
  alias PhoenixHologramWeb.Hologram.Pages.AdminMoviePage
  alias PhoenixHologramWeb.Hologram.Pages.PlayerPage

  route "/admin"

  layout PhoenixHologramWeb.Hologram.Layouts.DefaultLayout

  def init(_params, component, server) do
    movies =
      FaceDetection.list_movies_ordered()
      |> Repo.preload(:faces)
      |> Enum.map(fn movie ->
        %{
          id: movie.id,
          title: movie.title || movie.path,
          status: movie.status,
          face_count: length(movie.faces),
          description: movie.description,
          event_line: format_event_line(movie),
          thumbnail_url: "/premiere/videos/#{movie.id}/thumbnail",
          highlight?: highlight_card?(movie)
        }
      end)

    component =
      component
      |> put_state(:movies, movies)
      |> put_state(:promo_requests, PromoRequests.list_promo_requests_view())

    # Every open AdminMoviesPage tab picks up new/approved/rejected promo
    # requests live — PromoRequests broadcasts on this channel from
    # create_promo_request/1, approve_promo_request/1, and
    # reject_promo_request/1, each carrying the freshly formatted list.
    server = put_subscription(server, :promo_requests_changed)

    {component, server}
  end

  def action(:approve_promo_request, params, component) do
    put_command(component, :approve_promo_request, id: params.id)
  end

  def action(:reject_promo_request, params, component) do
    put_command(component, :reject_promo_request, id: params.id)
  end

  def action(:promo_requests_reloaded, params, component) do
    put_state(component, :promo_requests, params.requests)
  end

  # These commands don't need to return the reloaded list themselves
  # (via put_action) — the context functions already broadcast it on
  # :promo_requests_changed, which this page (like every other open one)
  # is subscribed to, so the update arrives the same way regardless of
  # which tab triggered it.
  def command(:approve_promo_request, %{id: id}, server) do
    PromoRequests.approve_promo_request(id)
    server
  end

  def command(:reject_promo_request, %{id: id}, server) do
    PromoRequests.reject_promo_request(id)
    server
  end

  defp highlight_card?(movie) do
    title = movie.title || ""
    String.contains?(String.downcase(title), "happy birthday")
  end

  defp format_event_line(movie) do
    case [format_event_date(movie.event_date), movie.location] |> Enum.reject(&is_nil/1) do
      [] -> nil
      parts -> Enum.join(parts, " | ")
    end
  end

  defp format_event_date(nil), do: nil
  defp format_event_date(date), do: date |> Calendar.strftime("%d %b %Y") |> String.upcase()

  def template do
    ~HOLO"""
    <div class="min-h-screen">
      <div class="p-6">
        <div class="max-w-3xl mx-auto">
          <div class="flex items-center justify-center gap-3 mb-1">
            <svg viewBox="0 0 24 40" class="w-4 h-8 text-primary/70" fill="none" stroke="currentColor" stroke-width="1.2">
              <path d="M12 2c-6 6-6 20 0 36" />
              <circle cx="10" cy="10" r="2.5" fill="currentColor" stroke="none" opacity="0.55" />
            </svg>
            <h2 class="font-display text-xl sm:text-2xl text-center">
              Gallery &amp; Recognised Faces
            </h2>
            <svg viewBox="0 0 24 40" class="w-4 h-8 text-primary/70 -scale-x-100" fill="none" stroke="currentColor" stroke-width="1.2">
              <path d="M12 2c-6 6-6 20 0 36" />
              <circle cx="10" cy="10" r="2.5" fill="currentColor" stroke="none" opacity="0.55" />
            </svg>
          </div>
          <div class="gold-divider w-24 mx-auto mb-6"></div>

          <div class="mb-8">
            <div class="flex items-center justify-center gap-2 mb-3">
              <h3 class="font-display text-lg text-center">Promo Requests</h3>
              {%if @promo_requests != []}
                <span class="badge badge-outline badge-primary">
                  {Enum.count(@promo_requests, &(&1.status == "pending"))} pending
                </span>
              {/if}
            </div>

            {%if @promo_requests == []}
              <div class="card card-stock shadow-xl">
                <div class="card-body">
                  <p class="text-base-content/70">No free-access requests yet.</p>
                </div>
              </div>
            {%else}
              <div class="card card-stock shadow-xl overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>When</th>
                      <th>Description</th>
                      <th>Amount</th>
                      <th>Code</th>
                      <th>Status</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    {%for request <- @promo_requests}
                      <tr>
                        <td class="text-xs whitespace-nowrap">{request.requested_at}</td>
                        <td class="text-sm max-w-[16rem]">{request.description}</td>
                        <td class="text-sm whitespace-nowrap">&#8377;{request.amount}</td>
                        <td class="text-xs font-mono">{request.code}</td>
                        <td>
                          <span class={
                            case request.status do
                              "approved" -> "badge badge-success"
                              "rejected" -> "badge badge-error"
                              _ -> "badge badge-warning"
                            end
                          }>
                            {request.status}
                          </span>
                        </td>
                        <td class="whitespace-nowrap">
                          {%if request.status == "pending"}
                            <button $click={:approve_promo_request, id: request.id} class="btn btn-xs btn-primary">
                              Approve
                            </button>
                            <button $click={:reject_promo_request, id: request.id} class="btn btn-xs btn-outline">
                              Reject
                            </button>
                          {/if}
                          {%if request.status == "rejected"}
                            <button $click={:approve_promo_request, id: request.id} class="btn btn-xs btn-primary">
                              Approve Anyway
                            </button>
                          {/if}
                          {%if request.status == "approved"}
                            <button $click={:reject_promo_request, id: request.id} class="btn btn-xs btn-outline">
                              Revoke
                            </button>
                          {/if}
                        </td>
                      </tr>
                    {/for}
                  </tbody>
                </table>
              </div>
            {/if}
          </div>

          <div class="gold-divider w-24 mx-auto mb-6"></div>

          {%if @movies == []}
            <div class="card card-stock shadow-xl">
              <div class="card-body">
                <p class="text-base-content/70">
                  No movies yet. Ingest one with `mix face_detection.ingest`.
                </p>
              </div>
            </div>
          {%else}
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {%for movie <- @movies}
                <div class={
                  if movie.highlight? do
                    "card sm:col-span-2 border-2 border-primary bg-secondary text-secondary-content shadow-xl hover:shadow-2xl transition overflow-hidden"
                  else
                    "card card-stock shadow-xl hover:shadow-2xl transition overflow-hidden"
                  end
                }>
                  <Link to={AdminMoviePage, id: movie.id}>
                    <figure class="aspect-video bg-base-300">
                      <img src={movie.thumbnail_url} alt={movie.title} class="w-full h-full object-cover" />
                    </figure>
                  </Link>
                  <div class="card-body items-center text-center">
                    <h2 class="card-title font-display">
                      <Link to={PlayerPage, id: movie.id} class="hover:underline">{movie.title}</Link>
                    </h2>
                    {%if movie.description}
                      <p class={
                        if movie.highlight? do
                          "text-sm text-secondary-content/80"
                        else
                          "text-sm text-base-content/70"
                        end
                      }>{movie.description}</p>
                    {/if}
                    {%if movie.event_line}
                      <p class={
                        if movie.highlight? do
                          "text-xs tracking-wide text-secondary-content/70"
                        else
                          "text-xs tracking-wide text-base-content/50"
                        end
                      }>{movie.event_line}</p>
                    {/if}
                    <div class="flex gap-2">
                      <span class="badge badge-outline badge-primary">{movie.status}</span>
                      <span class={
                        if movie.highlight? do
                          "badge badge-primary"
                        else
                          "badge badge-secondary"
                        end
                      }>{movie.face_count} face(s)</span>
                    </div>
                    <div class="flex flex-wrap justify-center gap-2 mt-2">
                      <Link to={AdminMoviePage, id: movie.id} class="btn btn-sm btn-secondary">
                        Manage Faces ⚙
                      </Link>
                      <Link to={PlayerPage, id: movie.id} class="btn btn-sm btn-primary">
                        Watch ▶
                      </Link>
                    </div>
                  </div>
                </div>
              {/for}
            </div>
          {/if}
        </div>
      </div>
    </div>
    """
  end
end
