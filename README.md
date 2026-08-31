# Phoenix Hologram

Elixir web app: Phoenix backend + [Hologram](https://www.hologram.page/) frontend (compiles Elixir to JS, no separate JS framework). Built additively, one working feature at a time.

## Status

🟡 Face-recognition premiere pipeline built end to end: ingest → cluster → admin scene browser → viewer page with live focus-voting, comments, likes, and view counts. Gaps: showtime scheduling and live broadcast of comments/likes (only focus-vote counts are pushed live).

## Links

- Live demo: https://marked-navally-eldon.ngrok-free.dev/premiere
- [Jira project](https://home.atlassian.com/o/a7222d2d-be5e-4578-b4c9-32861c2cc4c5/s/711a8a41-4bbd-40db-8c37-f122f871ce2f/project/VSZJZPCZ-1)

## Stack

Elixir/Phoenix, Hologram, SQLite via Ecto (Postgres isn't available on every dev machine here).

## Run

```bash
mix setup       # one-time: deps, JS/CSS toolchain, asset build
mix phx.server  # start the app at localhost:4000
```

Face detection needs its own one-time asset download (models + `ffmpeg`) before you can ingest a movie:

```bash
mix face_detection.setup             # downloads YuNet/SFace models and ffmpeg into priv/face_detection/
mix face_detection.ingest PATH       # ingest a movie: detect, cluster, and persist faces
mix face_detection.ingest PATH --title "Reception"
```

Other mix tasks:

```bash
mix test                       # ecto.create + ecto.migrate + test
mix precommit                  # compile --warnings-as-errors, deps.unlock --unused, format, test
mix premiere.generate_previews # (after app.start) cache 720p/2.5Mbps "preview" and 360p/700kbps "minimal" proxies for movies that lack them, for bandwidth-constrained playback
```

### Theme

Every page is a Hologram page sharing one `DefaultLayout` (`lib/phoenix_hologram_web/hologram/layouts/default_layout.ex`) — gold/cream palette, a Cinzel/Cormorant Garamond display face, and a crossfading photo hero built from the ingested movies' thumbnails, rendered above every page's own content so it only has to be maintained in one place. Its identity band + nav render one of two ways depending on the page's `banner` prop: `/` (`banner: :home`, set by `HomePage`) gets a marketing-style header — a `ShubhVivahs.com` wordmark (`priv/static/images/home-logo.png`) flanked on desktop by a pair of hanging brass-lamp images (`priv/static/images/brass-lamp.png`, hidden below the `sm` breakpoint to keep mobile to one row), a "Your Digital Wedding Memory Platform" tagline, and a nav bar linking to in-page sections (How It Works, View Core Example, Create Yours) alongside the Feature Walkthrough/Recognised Faces/Theme dropdowns. Every other page keeps the original floral-heart logo (`priv/static/images/logo.svg`) identity band and Premiere Hall/Recognised Faces/Theme nav. The floral logo doubles as the browser-tab favicon (`priv/static/favicon.svg`, with a rasterized `favicon.ico` fallback for browsers without SVG favicon support) and the browser-tab title, "Shubh Vivaha", on every page regardless of which header is showing.

Every page also has a "Theme" picker (in the nav bar) listing all 35 daisyUI themes plus "System" — `light`/`dark` are the bespoke gold/cream and maroon/gold wedding palettes (`app.css`), the other 33 are daisyUI's stock presets. The full theme name list lives in `PhoenixHologramWeb.DaisyThemes`. The picked theme is stored under the `phx:theme` `localStorage` key, shared by `root.html.heex` and `DefaultLayout`, so it carries over between pages.

### Footer

`DefaultLayout`'s footer (below every page's `<slot />`) carries the same contact/social/CTA block as the marketing mockup: a WhatsApp-linked phone number, Instagram/YouTube icons, a "Register" button that jumps to `/`'s lead-capture form, and a copyright line with a server-computed year (`footer_year` state, set from `Date.utc_today().year`).

### Milestone highlight in movie listings

Any movie whose title contains "happy birthday" (case-insensitive) renders full-width (`sm:col-span-2`) with a gold/maroon card instead of the standard cream `card-stock` card, across all three listing grids (`/`, `/premiere`, `/admin`) — matching the milestone-card treatment in the design mockup, driven by a `highlight_card?/1` check in each page module rather than a hardcoded movie id. Every card's title is also a link into `/premiere/:id`, not just its thumbnail and "View Video" button.

### Loading spinner

Every page (`root.html.heex` and `DefaultLayout`) shows a full-page overlay — the wedding logo above a gold spinner ring — if the initial load is taking a moment, so a slow connection doesn't leave visitors staring at a blank tab. It's built and torn down entirely in an inline `<script>`/`<style>` placed ahead of the `app.css` `<link>` in `<head>` (a stylesheet blocks execution of any synchronous `<script>` after it, so the overlay has to come first to render before app.css itself has necessarily finished loading), revealed only after a short delay so a fast load never flashes it, and hidden once `window.load` fires. On Hologram pages it's appended outside `<body>` rather than declared in the page template, since the Hologram client runtime replaces its whole rendered DOM tree on mount and would otherwise wipe out the overlay's state.

### Mobile layout

`html { font-size: 27px }` (`app.css`) scales every rem-based Tailwind/daisyUI size ~1.7x site-wide, so a plain `w-64` renders at 432px, not the usual 256px — fine on desktop, but a fixed-width dropdown or a few "small" nested margins/gaps can blow past a phone's viewport. The quality-picker dropdown and the comment reply threads on `/premiere/:id` both hit this; fixed with a viewport-relative `max-w-[calc(...)]` cap and `sm:`-only spacing/avatar sizing so mobile gets a tighter layout without touching desktop. The `/` marketing nav hit it too — with 7 links/dropdowns in one `flex flex-wrap` bar, the scaled-up text and `tracking-[0.15em]` letter-spacing left room for only one item per line on phones, reading as a vertical list instead of a nav bar; fixed with `sm:`-only font-size and tracking so mobile packs several items per line without touching desktop. Any new fixed-width or deeply-nested mobile UI should be checked against this scaling before assuming a Tailwind class "looks about right" — rendering it (`/run`) at a mobile viewport is the only way to be sure, since this scaling isn't visible from the class names alone.

### Pages

- `/` — landing page.
- `/hologram` — Hologram demo page.
- `/premiere`, `/admin` — the movie listing grid: title, thumbnail, and, once an admin has filled them in from `/admin/movies/:id`, a blurb plus a "date | location" line — in place of raw file metadata (resolution/size are still shown in the player's quality picker, see below).
- `/admin`, `/admin/movies/:id` — per-movie scene timeline and recognised faces (nameable, with thumbnails and timestamp ranges badged as playable clips, each carrying a focus-vote count that always matches the scene shown when clicked). The scene-preview modal shows the clip and the "who's in focus" voting panel side by side. `/admin/movies/:id` also has an "Edit listing details" panel for that movie's blurb, event date, and location.
- `/premiere/:id` — plays a movie, with:
  - live "who's in focus" voting: multiple named faces per scene, each showing its vote count, a "your vote" indicator, a "leading" badge on whichever face(s) currently hold the most votes in that scene (ties badge everyone tied for first), and the full per-vote timestamp history as a hover tooltip (voting identity is scoped to the page load, so refreshing lets you vote again) — laid out as the same compact, wrapping card grid as the admin scene-preview panel. Playback pauses the instant a vote is clicked and resumes once it's confirmed saved, and the panel label swaps to a "pause to vote" hint when scenes are cutting over too fast (< 1.5s apart) to reliably click a vote in time. Stays correct while playing an individual part too: each part file's own clock restarts at 0, so the client adds back that part's probed start offset before matching scenes, rather than the scene lookup silently going stale
  - comments (replies + likes), each poster naming themselves and shown with an avatar of their name's initial
  - a like button — toggles liked/unliked within the current view, but (like focus votes) isn't remembered across reloads: refreshing always resets it to "ready to like", e.g. for a shared/kiosk screen, while the total count persists
  - a view count — recorded once per movie per page load, the first time playback actually starts (pausing/scrubbing/replaying doesn't add more)
  - a themed quality-picker dropdown (original, 720p "preview", or 360p "minimal") for playback and downloads (full movie, or independently-retryable parts via a dropdown) — see [Mobile layout](#mobile-layout) for how it (and the comment threads above) stay on-screen on phones

  Over the ngrok tunnel, large videos are bandwidth-capped (free tier), so playback can stall on multi-GB files — fine on localhost.

## Feature Log

| # | Feature | Status |
|---|---------|--------|
| 0 | Scaffold Phoenix application (no Ecto) | ✅ Done |
| 1 | Add and configure Hologram, verify with a minimal interactive page | ✅ Done |
| 2 | Style the Hologram page with daisyUI | ✅ Done |
| 3 | Add a Reset button to the Hologram counter | ✅ Done |
| 4 | Face detection: ingest video, cluster unique faces | ✅ Done — YuNet+SFace via Evision, ffmpeg for frame sampling. Clusters by running-centroid cosine similarity, not single-linkage (avoids chaining distinct faces together) |
| 5 | Scene index: map each face to its timestamp ranges | ✅ Done — `FaceDetection.SceneIndex` collapses detections into ranges and derives the movie's scene timeline |
| 6 | Admin page: per-movie scene browser grouped by face | ✅ Done — Scenes and All recognised faces laid out side by side, faces ranked by focus-vote count; admins can also cast focus votes from the scene preview, synced live with `/premiere/:id` over the same PubSub channel. Timestamp badges read as playable clips (play-icon chip) and each one's vote count always matches the scene that opens when clicked, so a face's "N in focus" total is exactly the sum of its badges. A single-instant badge (start == end, most of them, since detections sample at ~1fps) parks the player on that exact frame rather than playing past it. Each badge also carries a "your vote" indicator and every vote's timestamp as a hover tooltip. Casting a vote stays responsive on movies with hundreds of scenes — the client-side update after a vote is O(1) per affected timestamp range and O(1) per scene bucket, not a full rescan (that rescan used to hang or crash the tab on a click). Saving a movie title or a face label auto-collapses its edit panel |
| 7 | Premiere Hall viewer page: scheduled, synced playback | 🟡 No showtime scheduling yet; playback not synced across viewers |
| 8 | Live comments during a showtime | 🟡 Post/reply/like/delete works, each poster names themselves and gets an initial avatar, but isn't broadcast live to co-viewers |
| 9 | Live focus-voting + share-count tracking | 🟡 Focus voting is live (PubSub) and allows multiple faces per scene, with a "pause to vote" hint during fast scene cuts, a "leading" badge on the current top vote-getter(s), and playback auto-pausing/resuming around each vote click; share-count tracking not implemented |
| 10 | Gold/cream wedding-invitation theme across all pages | ✅ Done — see [Theme](#theme) |
| 11 | Selectable daisyUI theme picker on every page | ✅ Done — see [Theme](#theme) |
| 12 | Movie view count | ✅ Done — recorded once per movie per page load, the first time playback starts |
| 13 | Wedding logo + favicon | ✅ Done — see [Theme](#theme) |
| 14 | Branded full-page loading spinner on slow initial loads | ✅ Done — see [Loading spinner](#loading-spinner) |
| 15 | Admin-authored blurb + date/location on movie cards | ✅ Done — replaces the raw resolution/size line on `/premiere` and `/admin`; edited per movie from `/admin/movies/:id` |
| 16 | Marketing-style header + nav on `/`, distinct from the rest of the site | ✅ Done — see [Theme](#theme); mobile nav wrapping fixed, see [Mobile layout](#mobile-layout) |
| 17 | Marketing footer (contact/social/register) + milestone-video highlight in listings | ✅ Done — see [Footer](#footer) and [Milestone highlight in movie listings](#milestone-highlight-in-movie-listings) |

Legend: 🔲 Not started · 🟡 In progress · ✅ Done

## Practice

New feature → add a `Not started` row above → flip to `In progress` while building → flip to `Done` with a one-line note when it ships. Keep this README in sync with the code — update it in the same commit as the feature it describes. Code is truth; if this file drifts from it, fix the file.
