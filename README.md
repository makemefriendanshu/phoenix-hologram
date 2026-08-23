# Phoenix Hologram

Elixir web app: Phoenix backend + [Hologram](https://www.hologram.page/) frontend (compiles Elixir to JS, no separate JS framework). Built additively, one working feature at a time; keep this README in sync with the code — update it in the same commit as the feature it describes.

## Status

🟡 Face-recognition premiere pipeline built end to end: ingest → cluster → admin scene browser → viewer page with live focus-voting, comments, and likes. Gaps: showtime scheduling and live broadcast of comments/likes (only focus-vote counts are pushed live).

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

### Pages

- `/` — stock Phoenix page.
- `/hologram` — Hologram demo page.
- `/admin`, `/admin/movies/:id` — per-movie scene timeline and recognised faces (nameable, with thumbnails and timestamp ranges, each badged with its own focus-vote count).
- `/premiere`, `/premiere/:id` — plays a movie with live "who's in focus" voting (multiple faces per scene; each face shows its vote count, a "your vote" indicator, and the full per-vote timestamp history as a hover tooltip — voting identity is scoped to the page load, so refreshing lets you vote again), comments (replies + likes), a like button, and a quality selector (original vs. low-bitrate preview) for playback and downloads (full movie, or independently-retryable parts via a dropdown). Over the ngrok tunnel, large videos are bandwidth-capped (free tier), so playback can stall on multi-GB files — fine on localhost.

## Feature Log

| # | Feature | Status |
|---|---------|--------|
| 0 | Scaffold Phoenix application (no Ecto) | ✅ Done |
| 1 | Add and configure Hologram, verify with a minimal interactive page | ✅ Done |
| 2 | Style the Hologram page with daisyUI | ✅ Done |
| 3 | Add a Reset button to the Hologram counter | ✅ Done |
| 4 | Face detection: ingest video, cluster unique faces | ✅ Done — YuNet+SFace via Evision, ffmpeg for frame sampling. Clusters by running-centroid cosine similarity, not single-linkage (avoids chaining distinct faces together) |
| 5 | Scene index: map each face to its timestamp ranges | ✅ Done — `FaceDetection.SceneIndex` collapses detections into ranges and derives the movie's scene timeline |
| 6 | Admin page: per-movie scene browser grouped by face | ✅ Done — Scenes and All recognised faces laid out side by side, faces ranked by focus-vote count; admins can also cast focus votes from the scene preview, synced live with `/premiere/:id` over the same PubSub channel. Each face's timestamp badges carry a "your vote" indicator, a live vote-count badge, and every vote's timestamp as a hover tooltip |
| 7 | Premiere Hall viewer page: scheduled, synced playback | 🟡 No showtime scheduling yet; playback not synced across viewers |
| 8 | Live comments during a showtime | 🟡 Post/reply/like/delete works but isn't broadcast live to co-viewers |
| 9 | Live focus-voting + share-count tracking | 🟡 Focus voting is live (PubSub) and allows multiple faces per scene; share-count tracking not implemented |

Legend: 🔲 Not started · 🟡 In progress · ✅ Done

## Practice

New feature → add a `Not started` row above → flip to `In progress` while building → flip to `Done` with a one-line note when it ships. Code is truth; if this file drifts from it, fix the file.
