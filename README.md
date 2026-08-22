# Phoenix Hologram

Elixir web app: Phoenix backend + [Hologram](https://www.hologram.page/) frontend. Hologram compiles Elixir to JavaScript, so there's no separate JS framework. Built additively, one fully-working feature at a time; this README tracks status and stays in sync with the code — update it in the same commit as the feature it describes.

## Status

🟡 Scaffold + Hologram wired in, verified at `/hologram` (styled with daisyUI; counter with Increment/Reset). Next: pick the first real feature.

## Links

- Live demo: https://marked-navally-eldon.ngrok-free.dev/hologram
- Jira project: https://home.atlassian.com/o/a7222d2d-be5e-4578-b4c9-32861c2cc4c5/s/711a8a41-4bbd-40db-8c37-f122f871ce2f/project/VSZJZPCZ-1

## Stack

- Backend: Elixir, Phoenix
- Frontend: Hologram
- DB: none yet — Ecto + PostgreSQL if/when a feature needs one

## Run

```bash
mix setup
mix phx.server
```

- `/` — stock Phoenix page.
- `/hologram` — Hologram page. Off by default in `:dev`/`:test`; set `HOLOGRAM_START=1` or run `mix holo`. Always on in `:prod`.

## Feature Log

| # | Feature | Status |
|---|---------|--------|
| 0 | Scaffold Phoenix application (no Ecto) | ✅ Done |
| 1 | Add and configure Hologram, verify with a minimal interactive page | ✅ Done |
| 2 | Style the Hologram page with daisyUI | ✅ Done |
| 3 | Add a Reset button to the Hologram counter | ✅ Done |

Legend: 🔲 Not started · 🟡 In progress · ✅ Done

## Roadmap

- [x] Scaffold Phoenix (`mix phx.new`)
- [x] Add Hologram
- [x] Verify a Hologram page renders
- [ ] Pick the first real feature

## Practice

New feature → add a `Not started` row above → flip to `In progress` while building → flip to `Done` with a one-line note when it ships. Code is truth; if this file drifts from it, fix the file.
