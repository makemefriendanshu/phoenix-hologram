defmodule PhoenixHologramWeb.Hologram.Pages.AdminAnalyticsPage do
  @moduledoc """
  Visual "admin analytics" dashboard only, shown with sample data (top
  visited URLs, unique IPs by region, and a detailed visit log) —
  matching AdminMoviesPage's "System Portal" section but there is no
  request/visit logging system in the app yet, so nothing here is tied
  to real traffic. Filters, export, and the visit log's rows are all
  decorative, matching how GenerateLinkPage/InviteTeamPage handle
  features with no backend yet. Reached from the "Admin Analytics" link
  in DefaultLayout's site-wide nav bar.
  """

  use Hologram.Page

  alias Hologram.UI.Link
  alias PhoenixHologramWeb.Hologram.Pages.AdminMoviesPage

  @top_urls [
    %{path: "/premiere/videos/1", count: 962},
    %{path: "/rahul-priya-memories", count: 741},
    %{path: "/premiere", count: 588},
    %{path: "/dashboard", count: 405},
    %{path: "/pricing", count: 213}
  ]

  @ip_regions [
    %{label: "Top Regions", count: 158, color: "var(--color-primary)"},
    %{label: "Metro Cities", count: 96, color: "var(--color-secondary)"},
    %{label: "Categories/Other", count: 58, color: "var(--color-accent)"},
    %{label: "International", count: 41, color: "var(--color-info)"},
    %{label: "Unknown", count: 20, color: "var(--color-base-300, #d8cbb0)"}
  ]

  @visit_logs [
    %{
      at: "2026-09-11 10:05:32 AM",
      ip: "203.8.113.10",
      url: "/rahul-priya-memories",
      source: "whatsapp.com",
      action: "Click",
      ms: 300
    },
    %{
      at: "2026-09-11 10:04:18 AM",
      ip: "203.8.113.10",
      url: "/premiere/videos/1",
      source: "whatsapp.com",
      action: "View",
      ms: 206
    },
    %{
      at: "2026-09-11 09:58:47 AM",
      ip: "202.9.44.21",
      url: "/pricing",
      source: "direct",
      action: "View",
      ms: 184
    },
    %{
      at: "2026-09-10 21:12:03 PM",
      ip: "45.114.20.6",
      url: "/dashboard",
      source: "instagram.com",
      action: "Click",
      ms: 267
    },
    %{
      at: "2026-09-10 18:40:55 PM",
      ip: "45.114.20.6",
      url: "/premiere",
      source: "instagram.com",
      action: "View",
      ms: 298
    },
    %{
      at: "2026-09-10 12:02:11 PM",
      ip: "103.21.166.5",
      url: "/rahul-priya-memories",
      source: "email",
      action: "Click",
      ms: 312
    }
  ]

  route "/admin/analytics"

  layout PhoenixHologramWeb.Hologram.Layouts.DefaultLayout

  def init(_params, component, _server) do
    max_count = @top_urls |> Enum.map(& &1.count) |> Enum.max()
    bars = Enum.map(@top_urls, &Map.put(&1, :pct, round(&1.count / max_count * 100)))

    total_ips = @ip_regions |> Enum.map(& &1.count) |> Enum.sum()

    regions =
      @ip_regions
      |> Enum.map(&Map.put(&1, :pct, Float.round(&1.count / total_ips * 100, 1)))

    component
    |> put_state(:bars, bars)
    |> put_state(:regions, regions)
    |> put_state(:total_ips, total_ips)
    |> put_state(:donut_style, "background: conic-gradient(#{donut_gradient(regions)})")
    |> put_state(:visit_logs, @visit_logs)
  end

  defp donut_gradient(regions) do
    {segments, _} =
      Enum.map_reduce(regions, 0.0, fn region, start ->
        stop = start + region.pct
        {"#{region.color} #{start}% #{stop}%", stop}
      end)

    Enum.join(segments, ", ")
  end

  def template do
    ~HOLO"""
    <div class="min-h-screen p-6">
      <div class="max-w-3xl mx-auto">
        <div class="flex items-center justify-center gap-2 mb-4">
          <span class="hero-user-circle w-4 h-4 text-base-content/50"></span>
          <span class="text-xs text-base-content/60">Signed in as Admin (sample data — System Portal)</span>
        </div>

        <div class="flex items-center justify-center gap-3 mb-1">
          <svg viewBox="0 0 24 40" class="w-4 h-8 text-primary/70" fill="none" stroke="currentColor" stroke-width="1.2">
            <path d="M12 2c-6 6-6 20 0 36" />
            <circle cx="10" cy="10" r="2.5" fill="currentColor" stroke="none" opacity="0.55" />
          </svg>
          <h1 class="font-display text-xl sm:text-2xl text-center">
            Admin Analytics Dashboard
          </h1>
          <svg viewBox="0 0 24 40" class="w-4 h-8 text-primary/70 -scale-x-100" fill="none" stroke="currentColor" stroke-width="1.2">
            <path d="M12 2c-6 6-6 20 0 36" />
            <circle cx="10" cy="10" r="2.5" fill="currentColor" stroke="none" opacity="0.55" />
          </svg>
        </div>
        <p class="text-center text-xs text-base-content/50 mb-1">
          Dashboard &gt; Portal Settings &gt; <span class="text-primary">Admin Analytics</span>
        </p>
        <p class="text-center text-sm text-base-content/60 mb-2">
          A preview of link clicks, visitor IPs, and visit logs once request tracking is wired up.
        </p>
        <div class="gold-divider w-24 mx-auto mb-6"></div>

        <div class="card card-stock shadow-xl mb-6">
          <div class="card-body">
            <div class="flex flex-wrap items-center gap-2">
              <input type="text" class="input input-bordered input-sm w-32" value="17 Jun 2026" disabled />
              <span class="text-base-content/40 text-xs">to</span>
              <input type="text" class="input input-bordered input-sm w-32" value="Today" disabled />
              <select class="select select-bordered select-sm" disabled>
                <option>All Links/Specific Link</option>
              </select>
              <select class="select select-bordered select-sm" disabled>
                <option>IP Filter</option>
              </select>
              <span class="btn btn-xs btn-outline pointer-events-none ml-auto">Export Data To CSV/PDF</span>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
          <div class="card card-stock shadow-xl">
            <div class="card-body">
              <h2 class="font-display text-base uppercase tracking-wide">Top Visited URLs (Live 24h)</h2>
              <ul class="flex flex-col gap-2 mt-3">
                {%for bar <- @bars}
                  <li>
                    <div class="flex justify-between text-xs text-base-content/70">
                      <span class="truncate">{bar.path}</span>
                      <span class="shrink-0 ml-2">{bar.count}</span>
                    </div>
                    <div class="w-full h-2 rounded-full bg-base-content/10 mt-1 overflow-hidden">
                      <div class="h-full bg-primary rounded-full" style={"width: #{bar.pct}%"}></div>
                    </div>
                  </li>
                {/for}
              </ul>
            </div>
          </div>

          <div class="card card-stock shadow-xl">
            <div class="card-body items-center text-center justify-center">
              <h2 class="font-display text-base uppercase tracking-wide">Total Link Clicks (All Time)</h2>
              <p class="font-display text-4xl text-primary mt-3">14,582</p>
              <p class="text-xs text-base-content/50 mt-1">Link Clicks</p>
            </div>
          </div>

          <div class="card card-stock shadow-xl">
            <div class="card-body">
              <h2 class="font-display text-base uppercase tracking-wide">Unique IPs Accessing</h2>
              <div class="flex items-center gap-4 mt-3">
                <div class="w-24 h-24 rounded-full shrink-0" style={@donut_style}>
                  <div class="w-full h-full rounded-full flex items-center justify-center" style="background: radial-gradient(circle, var(--color-base-100, #faf3e8) 55%, transparent 56%)">
                    <span class="font-display text-sm">{@total_ips}</span>
                  </div>
                </div>
                <ul class="text-xs text-base-content/70 flex flex-col gap-1">
                  {%for region <- @regions}
                    <li class="flex items-center gap-2">
                      <span class="w-2.5 h-2.5 rounded-full shrink-0" style={"background: #{region.color}"}></span>
                      {region.label} ({region.count})
                    </li>
                  {/for}
                </ul>
              </div>
            </div>
          </div>

          <div class="card card-stock shadow-xl">
            <div class="card-body">
              <h2 class="font-display text-base uppercase tracking-wide">Other Info Metrics</h2>
              <div class="grid grid-cols-2 gap-3 mt-3 text-center">
                <div class="rounded-box border border-base-content/10 py-2">
                  <p class="font-display text-lg text-primary">1,540</p>
                  <p class="text-xs text-base-content/50">Premium Activations</p>
                </div>
                <div class="rounded-box border border-base-content/10 py-2">
                  <p class="font-display text-lg text-primary">00:00:35</p>
                  <p class="text-xs text-base-content/50">Avg. Session Duration</p>
                </div>
                <div class="rounded-box border border-base-content/10 py-2">
                  <p class="font-display text-lg text-primary">+12%</p>
                  <p class="text-xs text-base-content/50">Link Creation Rate</p>
                </div>
                <div class="rounded-box border border-base-content/10 py-2">
                  <p class="text-warning text-sm">★★★★☆</p>
                  <p class="text-xs text-base-content/50">User Feedback Rating</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="card card-stock shadow-xl mt-6">
          <div class="card-body overflow-x-auto">
            <h2 class="font-display text-base uppercase tracking-wide">Detailed Link Visit Logs</h2>
            <table class="table table-zebra table-sm mt-2">
              <thead>
                <tr>
                  <th>Date/Time</th>
                  <th>Visitor IP</th>
                  <th>URL Visited</th>
                  <th>Source/Referrer</th>
                  <th>Action</th>
                  <th>Response Time</th>
                </tr>
              </thead>
              <tbody>
                {%for log <- @visit_logs}
                  <tr>
                    <td class="text-xs whitespace-nowrap">{log.at}</td>
                    <td class="text-xs font-mono whitespace-nowrap">{log.ip}</td>
                    <td class="text-xs max-w-[12rem] truncate">{log.url}</td>
                    <td class="text-xs whitespace-nowrap">{log.source}</td>
                    <td>
                      <span class={
                        if log.action == "Click" do
                          "badge badge-sm badge-primary"
                        else
                          "badge badge-sm badge-outline"
                        end
                      }>{log.action}</span>
                    </td>
                    <td class="text-xs whitespace-nowrap">{log.ms} ms</td>
                  </tr>
                {/for}
              </tbody>
            </table>
          </div>
        </div>

        <div class="flex flex-col items-center gap-3 mt-8">
          <span class="btn btn-primary btn-block gap-2 pointer-events-none">
            <span class="hero-arrow-down-tray w-4 h-4"></span>
            Export Data To CSV/PDF
          </span>
          <Link to={AdminMoviesPage} class="btn btn-outline btn-block gap-2">
            <span class="hero-arrow-right-end-on-rectangle w-4 h-4"></span>
            Back To Admin Portal
          </Link>
        </div>
        <p class="text-center text-xs text-base-content/50 mt-3">
          Visit tracking and export aren't wired up yet — everything above is a preview of the feature.
        </p>

        <div class="flex flex-wrap items-center justify-center gap-x-6 gap-y-2 mt-8 text-xs text-base-content/60">
          <span class="flex items-center gap-1">
            <span class="hero-shield-check w-4 h-4 text-primary"></span>
            Secure &amp; Private
          </span>
          <span class="flex items-center gap-1">
            <span class="hero-chart-bar w-4 h-4 text-primary"></span>
            Live Portal Metrics
          </span>
          <span class="flex items-center gap-1">
            <span class="hero-link w-4 h-4 text-primary"></span>
            Custom Shareable Link
          </span>
        </div>
      </div>
    </div>
    """
  end
end
