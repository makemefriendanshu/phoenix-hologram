# Phoenix Hologram

An Elixir web application built with the [Phoenix](https://www.phoenixframework.org/) framework on the backend and [Hologram](https://www.hologram.page/) for the frontend — Hologram compiles Elixir to JavaScript, so the entire stack (routing, business logic, and UI components) is written in Elixir with no separate JavaScript framework.

This README is the living plan for the project. Features are additive: each one gets proposed, built, and documented here before the next is started. Treat this file as the single source of truth for "what exists" and "what's next" — update it in the same commit/PR that ships the feature it describes.

## Status

🟡 Hologram wired in — a minimal interactive page renders through Phoenix at `/hologram`. Next: decide on the first real feature.

## What we're doing

Building a web application where the entire stack — backend routing/business logic and frontend UI — is written in Elixir, with Phoenix serving the backend and Hologram (which compiles Elixir to JavaScript) driving the frontend instead of a separate JavaScript framework. The project is built additively: each feature is proposed, implemented, and fully working before the next one starts, and this README is kept in lockstep with the code as the single changelog and roadmap.

## Why we're doing it

To validate a single-language, full-stack Elixir workflow — no context-switching between a backend language and a JavaScript frontend, no separate build toolchains to keep in sync, and one mental model (the BEAM/OTP) for both server and client-side behavior. Keeping the README as the source of truth also forces scope discipline: nothing ships without its purpose and status being documented alongside it.

## How we'll know we're successful

- The Phoenix + Hologram scaffold boots and serves a Hologram-rendered UI component through a Phoenix route, with no separate JS framework in the stack.
- Each feature added after the scaffold ships fully working, end to end, before the next one begins — no half-finished features left in the codebase.
- The README's Feature Log and Status always match what's actually true of the code, with no drift between docs and implementation.

## Goals

- Stand up a minimal Phoenix + Hologram application as the foundation.
- Add features incrementally, one at a time, each fully working before the next begins.
- Keep this README current as the single changelog + roadmap for the project, rather than letting docs drift from the code.

## Tech Stack

- **Backend**: Elixir, Phoenix
- **Frontend**: Hologram (Elixir-to-WASM UI components, server-communication built in)
- **Database**: TBD (Ecto + PostgreSQL by default, unless a feature requires otherwise)

## Getting Started

```bash
mix setup
mix phx.server
```

Then visit `localhost:4000` for the stock Phoenix page. Hologram is wired in but, like LiveView's code reloader, stays off in `:dev`/`:test` unless explicitly enabled — set `HOLOGRAM_START=1` (or run `mix holo`, which does this for you) and visit `localhost:4000/hologram` for the Hologram-rendered, interactive counter page. Hologram is always on in `:prod`.

## Feature Log

Each feature is listed here when planned, and its status updated as it moves through the pipeline. Keep entries short; link out to code/PRs instead of duplicating detail.

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 0 | Project scaffold (Phoenix + Hologram wired together) | ✅ Done | Phoenix app via `mix phx.new`; Hologram added and verified with an interactive page at `/hologram` (see `lib/phoenix_hologram_web/hologram/`) |

Status legend: 🔲 Not started · 🟡 In progress · ✅ Done

## Maintenance Practice

This is the part of the plan that matters most: **the README is updated alongside the code, every time.**

1. Before starting a new feature, add a row to the Feature Log above with status `Not started`.
2. While building, flip it to `In progress`.
3. When the feature ships, flip it to `Done`, add a one-line note (what it does / where to find it), and update the Goals/Status sections if the change is significant enough to affect them.
4. Never let this file describe something that isn't true of the current code — if in doubt, the code wins and the README gets fixed.

## Roadmap / Next Steps

- [x] Scaffold the Phoenix application (`mix phx.new`).
- [x] Add and configure the Hologram dependency.
- [x] Verify a minimal Hologram component renders through a Phoenix route.
- [ ] Decide on and document the first real feature to build on top of the scaffold.
