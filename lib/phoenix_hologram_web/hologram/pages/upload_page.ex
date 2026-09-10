defmodule PhoenixHologramWeb.Hologram.Pages.UploadPage do
  @moduledoc """
  Visual "upload your videos" page only, shown with sample data (three
  fake filenames, a fixed progress bar), matching DashboardPage's
  approach — there is no file-upload backend in the app yet (no
  multipart upload handler, no storage/quota tracking beyond the mix
  task that ingests movies from disk). "Complete Upload & Proceed to
  Curation Now" and "Save Progress & Complete Later" link to real
  destinations that already exist (Admin View, Dashboard) rather than
  a fake upload flow that goes nowhere.
  """

  use Hologram.Page

  alias Hologram.UI.Link
  alias PhoenixHologramWeb.Hologram.Pages.AdminMoviesPage
  alias PhoenixHologramWeb.Hologram.Pages.DashboardPage

  @sample_files [
    "Sangeet_Rituals_HighRes.mov",
    "Reception_Highlight_4K.mp4",
    "Mehendi_Moments.mp4"
  ]

  route "/upload"

  layout PhoenixHologramWeb.Hologram.Layouts.DefaultLayout

  def init(_params, component, _server) do
    put_state(component, :sample_files, @sample_files)
  end

  def template do
    ~HOLO"""
    <div class="min-h-screen p-6">
      <div class="max-w-2xl mx-auto">
        <div class="flex items-center justify-center gap-2 mb-4">
          <span class="hero-user-circle w-4 h-4 text-base-content/50"></span>
          <span class="text-xs text-base-content/60">Signed in as Rahul P. &amp; Priya S. (sample account)</span>
        </div>

        <div class="flex items-center justify-center gap-3 mb-1">
          <svg viewBox="0 0 24 40" class="w-4 h-8 text-primary/70" fill="none" stroke="currentColor" stroke-width="1.2">
            <path d="M12 2c-6 6-6 20 0 36" />
            <circle cx="10" cy="10" r="2.5" fill="currentColor" stroke="none" opacity="0.55" />
          </svg>
          <h1 class="font-display text-xl sm:text-2xl text-center">
            Upload Your Vivah Videos (Legacy Preview)
          </h1>
          <svg viewBox="0 0 24 40" class="w-4 h-8 text-primary/70 -scale-x-100" fill="none" stroke="currentColor" stroke-width="1.2">
            <path d="M12 2c-6 6-6 20 0 36" />
            <circle cx="10" cy="10" r="2.5" fill="currentColor" stroke="none" opacity="0.55" />
          </svg>
        </div>
        <p class="text-center text-sm text-base-content/60 mb-2">
          A preview of what uploading will look like once it is built.
        </p>
        <div class="gold-divider w-24 mx-auto mb-6"></div>

        <span class="btn btn-primary btn-block gap-2 pointer-events-none mb-6">
          <span class="hero-arrow-up-tray w-4 h-4"></span>
          New Upload Preview (Drag &amp; Drop Or Click To Add)
        </span>

        <div class="text-center mb-6">
          <p class="text-xs text-base-content/50 uppercase tracking-wide">Your exclusive premium features</p>
          <p class="text-sm font-display">Advanced Curation &amp; 4K Storage Activated</p>
        </div>

        <div class="card card-stock shadow-xl mb-6">
          <div class="card-body items-center text-center">
            <span class="hero-arrow-up-tray w-8 h-8 text-primary"></span>
            <p class="font-display text-lg">Upload</p>
            <progress class="progress progress-primary w-full max-w-xs" value="50" max="100"></progress>
            <p class="text-xs text-base-content/60">5GB upload in progress | 3 of 10 files uploaded</p>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
          <div class="card card-stock shadow-xl">
            <div class="card-body">
              <ul class="text-sm text-base-content/70 flex flex-col gap-1.5">
                {%for {file, index} <- Enum.with_index(@sample_files, 1)}
                  <li class="flex items-center gap-2">
                    <span class="hero-document w-4 h-4 shrink-0 text-base-content/40"></span>
                    {index}. {file}
                  </li>
                {/for}
              </ul>
              <p class="text-xs mt-2">
                <span class="link link-hover text-base-content/50">Add More Files</span>
              </p>
            </div>
          </div>

          <div class="card bg-secondary text-secondary-content shadow-xl">
            <div class="card-body">
              <p class="font-display text-sm uppercase tracking-wide">Premium Upload Status</p>
              <ul class="text-sm flex flex-col gap-1.5 mt-2">
                <li class="flex items-center gap-2">
                  <span class="hero-circle-stack w-4 h-4 shrink-0"></span>
                  Current usage: 15GB / 1TB
                </li>
                <li class="flex items-center gap-2">
                  <span class="hero-video-camera w-4 h-4 shrink-0"></span>
                  Accepted formats: MP4, MOV
                </li>
                <li class="flex items-center gap-2">
                  <span class="hero-sparkles w-4 h-4 shrink-0"></span>
                  4K enabled
                </li>
              </ul>
            </div>
          </div>
        </div>

        <div class="flex flex-col items-center gap-3">
          <Link to={AdminMoviesPage} class="btn btn-primary btn-block gap-2">
            <span class="hero-check-circle w-4 h-4"></span>
            Complete Upload &amp; Proceed To Curation Now
          </Link>
          <Link to={DashboardPage} class="btn btn-outline btn-block gap-2">
            <span class="hero-clock w-4 h-4"></span>
            Save Progress &amp; Complete Later
          </Link>
        </div>
        <p class="text-center text-xs text-base-content/50 mt-3">
          Uploading isn't wired up yet — the buttons above take you to what is real today: Admin View and your Dashboard.
        </p>

        <div class="flex flex-wrap items-center justify-center gap-x-6 gap-y-2 mt-8 text-xs text-base-content/60">
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
