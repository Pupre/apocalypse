# Documentation Index

This is the routing hub for repository documentation.

Start here if you are trying to understand what is current, what is active, and where a new document should live.

## Current

- [Current State](CURRENT_STATE.md): quickest snapshot of the current project direction, active implementation state, and near-term priorities
- [AGENTS](../AGENTS.md): repository entrypoint and reading-order guide

## Active Specs

Active specs live in `docs/superpowers/specs/` and define the current feature direction. Newest first.

- [Context Routing Docs Design](superpowers/specs/2026-04-10-context-routing-docs-design.md)
- [Contextual Crafting UI Design](superpowers/specs/2026-04-09-contextual-crafting-ui-design.md)
- [Portrait Phase 1 Shell Design](superpowers/specs/2026-04-07-portrait-phase1-shell-design.md)
- [Indoor Portrait Survival Sheet Design](superpowers/specs/2026-04-07-indoor-portrait-survival-sheet-design.md)
- [Crafting Codex Lighter Design](superpowers/specs/2026-04-06-crafting-codex-lighter-design.md)

## Active Plans

Active plans live in `docs/superpowers/plans/` and define the current implementation sequence. Newest first.

- [Context Routing Docs](superpowers/plans/2026-04-10-context-routing-docs.md)
- [Contextual Crafting UI](superpowers/plans/2026-04-09-contextual-crafting-ui.md)
- [Portrait Phase 1 Shell](superpowers/plans/2026-04-07-portrait-phase1-shell.md)
- [Indoor Portrait Survival Sheet](superpowers/plans/2026-04-07-indoor-portrait-survival-sheet.md)
- [Crafting Codex Lighter](superpowers/plans/2026-04-06-crafting-codex-lighter.md)
- [Knowledge-Driven Crafting Implementation](superpowers/plans/2026-04-03-knowledge-driven-crafting-implementation.md)
- [Indoor UI Clarity Refinement](superpowers/plans/2026-04-03-indoor-ui-clarity-refinement.md)
- [Survival Stats First Pass](superpowers/plans/2026-04-02-survival-stats-first-pass.md)
- [Outdoor Visual Refresh](superpowers/plans/2026-04-02-outdoor-visual-refresh.md)
- [Indoor UI Restructure](superpowers/plans/2026-04-02-indoor-ui-restructure.md)
- [Indoor UI Clarity Follow-up](superpowers/plans/2026-04-02-indoor-ui-clarity-follow-up.md)
- [Mart Indoor Content Implementation](superpowers/plans/2026-04-01-mart-indoor-content-implementation.md)
- [Mode Transition Presentation Polish](superpowers/plans/2026-03-31-mode-transition-presentation-polish.md)

## Background

Background docs live in `docs/specs/`. They describe long-lived project direction and technical foundations.

- [Core Gameplay Design](specs/core-gameplay-design.md)
- [Godot Technical Architecture](specs/godot-technical-architecture.md)
- [Indoor UI Clarity Follow-up Design](specs/indoor-ui-clarity-follow-up-design.md)
- [Indoor UI Restructure Design](specs/indoor-ui-restructure-design.md)
- [Knowledge-Driven Crafting Design](specs/knowledge-driven-crafting-design.md)
- [Mart Indoor Content Design](specs/mart-indoor-content-design.md)
- [Mode Transition Presentation Design](specs/mode-transition-presentation-design.md)
- [Outdoor Visual Refresh Design](specs/outdoor-visual-refresh-design.md)
- [Survival Stats First Pass Design](specs/survival-stats-first-pass-design.md)

## History

Historical docs live in `docs/handoffs/` and `docs/worklogs/`. Use these when you need to reconstruct how a decision evolved, not to determine current direction.

- Handoffs
  - [2026-04-01 Indoor Prototype Iteration](handoffs/2026-04-01-indoor-prototype-iteration.md)
  - [2026-04-02 Indoor UI Clarity Follow-up](handoffs/2026-04-02-indoor-ui-clarity-follow-up.md)
  - [2026-04-02 Indoor UI Restructure](handoffs/2026-04-02-indoor-ui-restructure.md)
  - [2026-04-02 Outdoor Visual Refresh](handoffs/2026-04-02-outdoor-visual-refresh.md)
- Worklogs
  - [2026-04-01 Indoor Prototype Iteration](worklogs/2026-04-01-indoor-prototype-iteration.md)
  - [2026-04-02 Indoor UI Clarity Follow-up](worklogs/2026-04-02-indoor-ui-clarity-follow-up.md)
  - [2026-04-02 Indoor UI Restructure](worklogs/2026-04-02-indoor-ui-restructure.md)
  - [2026-04-02 Outdoor Visual Refresh](worklogs/2026-04-02-outdoor-visual-refresh.md)
- Legacy plans
  - [First Playable Prototype Implementation Plan](plans/2026-03-31-first-playable-prototype.md)

## Drafts

Drafts live in `docs/drafts/`. Use this lane for unapproved or exploratory docs that have not been promoted into the active routing flow yet.

- [Drafts README](drafts/README.md)

## Setup

Setup docs live in `docs/setup/` and cover environment or export requirements.

- [Godot Android Development Setup](setup/godot-android-development-setup.md)

## Adding New Docs

Classify a new document by its job, then place it in the matching folder:

- Put active feature behavior or UX direction in `docs/superpowers/specs/`.
- Put the implementation sequence for that active work in `docs/superpowers/plans/`.
- Put long-lived background design or architecture in `docs/specs/`.
- Put machine, device, or export setup in `docs/setup/`.
- Put session handoffs and progress logs in `docs/handoffs/` or `docs/worklogs/`.

When you add a new active spec or plan, update this index so readers can find it quickly.

When project direction changes, update `docs/CURRENT_STATE.md` so the snapshot stays ahead of the deeper archive.
