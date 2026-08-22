# Phoenix Hologram

Elixir web app: Phoenix backend + [Hologram](https://www.hologram.page/) frontend. Hologram compiles Elixir to JavaScript, so there's no separate JS framework. Built additively, one fully-working feature at a time; this README tracks status and stays in sync with the code — update it in the same commit as the feature it describes.

## Status

🟡 Scaffold + Hologram wired in, verified at `/hologram` (styled with daisyUI; counter with Increment/Reset). Next: face-recognition premiere pipeline — see [Plan](#plan-face-recognition-premiere) below.

## Links

- Live demo: https://marked-navally-eldon.ngrok-free.dev/premiere
- Jira project: https://home.atlassian.com/o/a7222d2d-be5e-4578-b4c9-32861c2cc4c5/s/711a8a41-4bbd-40db-8c37-f122f871ce2f/project/VSZJZPCZ-1

## Stack

- Backend: Elixir, Phoenix
- Frontend: Hologram
- DB: SQLite via Ecto (`PhoenixHologram.Repo`) — Postgres isn't available on every
  dev machine here, and SQLite needs no server

## Run

```bash
mix setup
mix phx.server
```

- `/` — stock Phoenix page.
- `/hologram` — Hologram page. Off by default in `:dev`/`:test`; set `HOLOGRAM_START=1` or run `mix holo`. Always on in `:prod`.
- `/premiere` — lists movies from the `movies` table; `/premiere/:id` plays one. Note: over the ngrok tunnel above, large video files are bandwidth-capped to a few MB/s (free-tier limit), so playback can stall or error on multi-GB files — fine over localhost.
- `mix face_detection.setup` — one-time download of the face detection models (+ a
  bundled `ffmpeg` if none is on PATH); needed before `mix face_detection.ingest PATH`
  will work.

## Feature Log

| # | Feature | Status |
|---|---------|--------|
| 0 | Scaffold Phoenix application (no Ecto) | ✅ Done |
| 1 | Add and configure Hologram, verify with a minimal interactive page | ✅ Done |
| 2 | Style the Hologram page with daisyUI | ✅ Done |
| 3 | Add a Reset button to the Hologram counter | ✅ Done |
| 4 | Face detection service: ingest video, cluster unique faces | ✅ Done — YuNet+SFace via Evision, ffmpeg for frame sampling, clustered by cosine similarity, persisted to SQLite (`mix face_detection.setup` then `mix face_detection.ingest PATH`) |
| 5 | Scene index: map each detected face to its timestamp ranges | 🔲 Not started |
| 6 | Admin page: per-movie scene browser grouped by face | 🔲 Not started |
| 7 | Premiere Hall viewer page: schedule a showtime, play its scenes in sync for viewers | 🔲 Not started |
| 8 | Live comments during a showtime | 🔲 Not started |
| 9 | Live "who's in focus" polling + share-count tracking | 🔲 Not started |

Legend: 🔲 Not started · 🟡 In progress · ✅ Done

## Plan: Face Recognition Premiere

Scan wedding/event videos (`Anshuman  &  Mausam  Wedding/`, gitignored,
local-only) for unique faces, review results in an admin page, then screen
them in a live "premiere hall". Planning only — Feature Log rows 4-9 track
delivery.

- **O1 Recognize faces**: ingest `.mp4` → detect faces per frame → cluster into unique identities → persist their scene/timestamp ranges.
- **O2 Admin visibility**: per-movie page of scenes grouped by face; label/merge identities; preview a scene inline.
- **O3 Viewer page**: admin schedules a showtime; viewers get a page with synced scene playback showing who's in the current scene.
- **O4 Live comments**: post a comment during a showtime; broadcasts live to co-viewers; admin can moderate.
- **O5 "Who's in focus" polling**: viewers poll on who's in the current scene; results tallied live; track participant/share counts.

## Practice

New feature → add a `Not started` row above → flip to `In progress` while building → flip to `Done` with a one-line note when it ships. Code is truth; if this file drifts from it, fix the file.
