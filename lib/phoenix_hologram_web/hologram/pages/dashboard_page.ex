defmodule PhoenixHologramWeb.Hologram.Pages.DashboardPage do
  @moduledoc """
  Visual "my account" dashboard only, shown with sample data (Rahul &
  Priya, a 65%-curated timeline) since there is no user/account system
  in the app yet — nothing here is tied to a real logged-in couple.
  Buttons that have a genuine destination in the app today (Admin View,
  Pricing, Generate Shareable Link) link there for real; the rest
  ("Invite Team", "View Timeline Preview") are decorative, matching how
  LoginPage/RegisterPage/PricingPage handle features with no backend yet.
  """

  use Hologram.Page

  alias Hologram.UI.Link
  alias PhoenixHologramWeb.Hologram.Pages.AdminMoviesPage
  alias PhoenixHologramWeb.Hologram.Pages.GenerateLinkPage
  alias PhoenixHologramWeb.Hologram.Pages.UpgradePage
  alias PhoenixHologramWeb.Hologram.Pages.UploadPage

  route "/dashboard"

  layout PhoenixHologramWeb.Hologram.Layouts.DefaultLayout

  def template do
    ~HOLO"""
    <div class="min-h-screen p-6">
      <div class="max-w-3xl mx-auto">
        <div class="flex items-center justify-center gap-2 mb-4">
          <span class="hero-user-circle w-4 h-4 text-base-content/50"></span>
          <span class="text-xs text-base-content/60">Signed in as Rahul P. &amp; Priya S. (sample account)</span>
        </div>

        <div class="flex items-center justify-center gap-3 mb-1">
          <svg viewBox="0 0 24 40" class="w-4 h-8 text-primary/70" fill="none" stroke="currentColor" stroke-width="1.2">
            <path d="M12 2c-6 6-6 20 0 36" />
            <circle cx="10" cy="10" r="2.5" fill="currentColor" stroke="none" opacity="0.55" />
          </svg>
          <h1 class="font-display text-xl sm:text-3xl text-center">
            Rahul &amp; Priya's Wedding Journey
          </h1>
          <svg viewBox="0 0 24 40" class="w-4 h-8 text-primary/70 -scale-x-100" fill="none" stroke="currentColor" stroke-width="1.2">
            <path d="M12 2c-6 6-6 20 0 36" />
            <circle cx="10" cy="10" r="2.5" fill="currentColor" stroke="none" opacity="0.55" />
          </svg>
        </div>
        <p class="text-center text-sm text-base-content/60 mb-2">
          A preview of what every couple's dashboard will look like.
        </p>
        <div class="gold-divider w-24 mx-auto mb-8"></div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
          <div class="card card-stock shadow-xl">
            <div class="card-body items-center text-center">
              <div class="radial-progress text-primary" style="--value:65; --size:8rem; --thickness:0.7rem;" role="progressbar">
                <span class="font-display text-2xl text-base-content">65%</span>
              </div>
              <p class="text-sm text-base-content/60 -mt-1">Complete</p>
              <Link to={UpgradePage} class="btn btn-primary btn-sm mt-2">Get Premium</Link>
            </div>
          </div>

          <div class="card card-stock shadow-xl">
            <div class="card-body">
              <h2 class="font-display text-base uppercase tracking-wide">My Wedding Timeline Status</h2>
              <p class="text-sm text-base-content/70 mt-2">
                Your unique timeline is being curated.
              </p>
              <p class="text-sm text-base-content/70 mt-1">
                Next: add Sangeet &amp; Reception descriptions.
              </p>
            </div>
          </div>
        </div>

        <div class="mt-6 card card-stock shadow-xl">
          <div class="card-body">
            <h2 class="font-display text-base uppercase tracking-wide">My Uploaded Event Videos</h2>
            <ul class="text-sm text-base-content/70 mt-2 flex flex-col gap-1.5">
              <li class="flex items-center gap-2">
                <span class="badge badge-warning badge-sm">Pending Review</span>
                Sangeet
              </li>
              <li class="flex items-center gap-2">
                <span class="badge badge-success badge-sm">Upload Complete</span>
                Reception
              </li>
            </ul>
            <div class="mt-4">
              <Link to={UploadPage} class="btn btn-primary btn-sm gap-2">
                <span class="hero-cloud-arrow-up w-4 h-4"></span>
                Upload More Videos
              </Link>
            </div>
          </div>
        </div>

        <h2 class="font-display text-base text-center uppercase tracking-wide mt-8 mb-3">Quick Actions</h2>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <Link to={AdminMoviesPage} class="btn btn-secondary btn-block h-auto py-3 flex-col gap-1">
            <span class="hero-pencil-square w-5 h-5"></span>
            <span class="text-xs">Edit Event Details</span>
          </Link>
          <span class="btn btn-secondary btn-block h-auto py-3 flex-col gap-1 pointer-events-none">
            <span class="hero-envelope w-5 h-5"></span>
            <span class="text-xs">Invite Team</span>
          </span>
          <Link to={GenerateLinkPage} class="btn btn-secondary btn-block h-auto py-3 flex-col gap-1">
            <span class="hero-link w-5 h-5"></span>
            <span class="text-xs">Generate Shareable Link</span>
          </Link>
        </div>
        <p class="text-center text-xs text-base-content/50 mt-3">
          Team invites are coming soon.
        </p>

        <p class="text-center text-sm text-base-content/70 mt-8">
          Status: In Progress (curated to 65%)
        </p>

        <div class="flex flex-wrap items-center justify-center gap-x-6 gap-y-2 mt-6 text-xs text-base-content/60">
          <span class="flex items-center gap-1">
            <span class="hero-shield-check w-4 h-4 text-primary"></span>
            Secure &amp; Private
          </span>
          <span class="flex items-center gap-1">
            <span class="hero-film w-4 h-4 text-primary"></span>
            Professional Curation
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
