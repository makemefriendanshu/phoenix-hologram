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
mix premiere.generate_previews # (after app.start) cache 720p/2.5Mbps preview proxies for movies that lack one, for bandwidth-constrained playback
```

### Theme

All Hologram pages (everything except `/`) share one `DefaultLayout` (`lib/phoenix_hologram_web/hologram/layouts/default_layout.ex`), which renders a "Shubh Vivaha" wedding-invitation banner — gold/cream palette, a Cinzel/Cormorant Garamond display face, a floral heart logo (`priv/static/images/logo.svg`) beside the identity band + nav, and a crossfading photo hero built from the ingested movies' thumbnails — above every page's own content, so it only has to be maintained in one place. `/` (the stock Phoenix landing page) gets the same gold/cream palette and background via `app.css`, styled independently since it isn't a Hologram page. The same logo doubles as the browser-tab favicon (`priv/static/favicon.svg`, with a rasterized `favicon.ico` fallback for browsers without SVG favicon support) and as the browser-tab title, "Shubh Vivaha", on every page.

Every page also has a "Theme" picker (top-right on `/`, in the nav bar on Hologram pages) listing all 35 daisyUI themes plus "System" — `light`/`dark` are the bespoke gold/cream and maroon/gold wedding palettes (`app.css`), the other 33 are daisyUI's stock presets. The full theme name list lives in `PhoenixHologramWeb.DaisyThemes`. The picked theme is stored under the `phx:theme` `localStorage` key, shared by `root.html.heex` and `DefaultLayout`, so it carries over between `/` and the Hologram pages.

### Loading spinner

Every page (`root.html.heex` and `DefaultLayout`) shows a full-page overlay — the wedding logo above a gold spinner ring — if the initial load is taking a moment, so a slow connection doesn't leave visitors staring at a blank tab. It's built and torn down entirely in an inline `<script>`/`<style>` placed ahead of the `app.css` `<link>` in `<head>` (a stylesheet blocks execution of any synchronous `<script>` after it, so the overlay has to come first to render before app.css itself has necessarily finished loading), revealed only after a short delay so a fast load never flashes it, and hidden once `window.load` fires. On Hologram pages it's appended outside `<body>` rather than declared in the page template, since the Hologram client runtime replaces its whole rendered DOM tree on mount and would otherwise wipe out the overlay's state.

### Pages

- `/` — landing page.
- `/hologram` — Hologram demo page.
- `/admin`, `/admin/movies/:id` — per-movie scene timeline and recognised faces (nameable, with thumbnails and timestamp ranges badged as playable clips, each carrying a focus-vote count that always matches the scene shown when clicked). The scene-preview modal shows the clip and the "who's in focus" voting panel side by side.
- `/premiere`, `/premiere/:id` — plays a movie, with:
  - live "who's in focus" voting: multiple named faces per scene, each showing its vote count, a "your vote" indicator, and the full per-vote timestamp history as a hover tooltip (voting identity is scoped to the page load, so refreshing lets you vote again) — laid out as the same compact, wrapping card grid as the admin scene-preview panel; the panel label swaps to a "pause to vote" hint when scenes are cutting over too fast (< 1.5s apart) to reliably click a vote in time
  - comments (replies + likes), each poster naming themselves and shown with an avatar of their name's initial
  - a like button — toggles liked/unliked within the current view, but (like focus votes) isn't remembered across reloads: refreshing always resets it to "ready to like", e.g. for a shared/kiosk screen, while the total count persists
  - a view count — recorded once per movie per page load, the first time playback actually starts (pausing/scrubbing/replaying doesn't add more)
  - a themed quality-picker dropdown (original vs. low-bitrate preview) for playback and downloads (full movie, or independently-retryable parts via a dropdown)

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
| 9 | Live focus-voting + share-count tracking | 🟡 Focus voting is live (PubSub) and allows multiple faces per scene, with a "pause to vote" hint during fast scene cuts; share-count tracking not implemented |
| 10 | Gold/cream wedding-invitation theme across all pages | ✅ Done — see [Theme](#theme) |
| 11 | Selectable daisyUI theme picker on every page | ✅ Done — see [Theme](#theme) |
| 12 | Movie view count | ✅ Done — recorded once per movie per page load, the first time playback starts |
| 13 | Wedding logo + favicon | ✅ Done — see [Theme](#theme) |
| 14 | Branded full-page loading spinner on slow initial loads | ✅ Done — see [Loading spinner](#loading-spinner) |

Legend: 🔲 Not started · 🟡 In progress · ✅ Done

## Practice

New feature → add a `Not started` row above → flip to `In progress` while building → flip to `Done` with a one-line note when it ships. Keep this README in sync with the code — update it in the same commit as the feature it describes. Code is truth; if this file drifts from it, fix the file.
