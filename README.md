# Phoenix Hologram

An Elixir web application built with the [Phoenix](https://www.phoenixframework.org/) framework on the backend and [Hologram](https://www.hologram.page/) for the frontend — Hologram compiles Elixir to WebAssembly, so the entire stack (routing, business logic, and UI components) is written in Elixir with no separate JavaScript framework.

This README is the living plan for the project. Features are additive: each one gets proposed, built, and documented here before the next is started. Treat this file as the single source of truth for "what exists" and "what's next" — update it in the same commit/PR that ships the feature it describes.

## Status

🟡 Planning — no code yet. This document defines the initial scope and the process for growing it.

## Goals

- Stand up a minimal Phoenix + Hologram application as the foundation.
- Add features incrementally, one at a time, each fully working before the next begins.
- Keep this README current as the single changelog + roadmap for the project, rather than letting docs drift from the code.

## Tech Stack

- **Backend**: Elixir, Phoenix
- **Frontend**: Hologram (Elixir-to-WASM UI components, server-communication built in)
- **Database**: TBD (Ecto + PostgreSQL by default, unless a feature requires otherwise)

## Getting Started

_To be filled in once the initial `mix phx.new` scaffold and Hologram integration are committed._

```bash
# placeholder — will be updated once the project is scaffolded
mix deps.get
mix phx.server
```

## Feature Log

Each feature is listed here when planned, and its status updated as it moves through the pipeline. Keep entries short; link out to code/PRs instead of duplicating detail.

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 0 | Project scaffold (Phoenix + Hologram wired together) | 🔲 Not started | Base app, no business features yet |

Status legend: 🔲 Not started · 🟡 In progress · ✅ Done

## Maintenance Practice

This is the part of the plan that matters most: **the README is updated alongside the code, every time.**

1. Before starting a new feature, add a row to the Feature Log above with status `Not started`.
2. While building, flip it to `In progress`.
3. When the feature ships, flip it to `Done`, add a one-line note (what it does / where to find it), and update the Goals/Status sections if the change is significant enough to affect them.
4. Never let this file describe something that isn't true of the current code — if in doubt, the code wins and the README gets fixed.

## Roadmap / Next Steps

- [ ] Scaffold the Phoenix application (`mix phx.new`).
- [ ] Add and configure the Hologram dependency.
- [ ] Verify a minimal Hologram component renders through a Phoenix route.
- [ ] Decide on and document the first real feature to build on top of the scaffold.
