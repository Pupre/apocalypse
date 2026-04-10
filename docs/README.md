# Project Documentation

This repository uses a routing layer on top of the existing `docs/` tree.

## What Lives Where

- `docs/INDEX.md`: the document hub and main map for current, active, background, history, and setup docs
- `docs/CURRENT_STATE.md`: the short snapshot of what the project is right now
- `../AGENTS.md`: the repo entrypoint and reading-order guide for agents

## Document Roles

- Active specs in `docs/superpowers/specs/` define the current feature direction.
- Active plans in `docs/superpowers/plans/` define the current implementation sequence.
- Background docs in `docs/specs/` capture durable product and technical context.
- History docs in `docs/handoffs/`, `docs/worklogs/`, and legacy `docs/plans/` preserve how decisions evolved.
- Setup docs in `docs/setup/` cover environment and export details.
- Drafts in `docs/drafts/` stay unapproved until they are intentionally promoted.

## Lifecycle

- Start with `docs/INDEX.md` when you need the current map.
- Read `docs/CURRENT_STATE.md` when you need the newest snapshot of direction, baseline systems, and near-term priorities.
- Use active specs and plans for in-flight work.
- Use background docs for stable context that still matters.
- Use history docs to reconstruct decisions, not to decide current direction.
- Use setup docs when the task depends on local tooling or export configuration.
