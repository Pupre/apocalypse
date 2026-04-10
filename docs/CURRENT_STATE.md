# Current State

- Status: active
- Last updated: 2026-04-10

## Product Direction

- Portrait-first mobile presentation.
- Outdoor play keeps continuous travel risk and long-distance survival pressure active.
- Indoor play is text-heavy and decision-driven.
- Inventory is bag-first, with crafting triggered contextually from what is in the bag and where the survivor is.

## Implemented Baseline

Systems already integrated in `main`:

- Life-world item and recipe expansion.
- Building-specific indoor loot.
- Shared crafting baseline.
- Warmth system.
- Indoor site memory plus drop/re-entry persistence.
- Crafting codex, note-based unlocks, lighter charges, and tool requirements.
- Portrait phase 1 shell and indoor survival sheet work.

## Active Specs

Canonical active-doc inventory lives in `docs/INDEX.md`. The list below is the current working set that most directly affects the game direction right now.

- [Context Routing Docs Design](superpowers/specs/2026-04-10-context-routing-docs-design.md)
- [Contextual Crafting UI Design](superpowers/specs/2026-04-09-contextual-crafting-ui-design.md)
- [Portrait Phase 1 Shell Design](superpowers/specs/2026-04-07-portrait-phase1-shell-design.md)
- [Indoor Portrait Survival Sheet Design](superpowers/specs/2026-04-07-indoor-portrait-survival-sheet-design.md)
- [Crafting Codex Lighter Design](superpowers/specs/2026-04-06-crafting-codex-lighter-design.md)

## Active Plans

For the full active plan inventory, use `docs/INDEX.md`. The list below is the near-term plan stack currently driving implementation.

- [Context Routing Docs](superpowers/plans/2026-04-10-context-routing-docs.md)
- [Contextual Crafting UI](superpowers/plans/2026-04-09-contextual-crafting-ui.md)
- [Portrait Phase 1 Shell](superpowers/plans/2026-04-07-portrait-phase1-shell.md)
- [Indoor Portrait Survival Sheet](superpowers/plans/2026-04-07-indoor-portrait-survival-sheet.md)
- [Crafting Codex Lighter](superpowers/plans/2026-04-06-crafting-codex-lighter.md)

## Immediate Priorities

- Finish the bag-first contextual crafting flow so the bag stays the main inventory surface.
- Tighten the portrait indoor sheet and shell so text-heavy decisions remain readable on mobile.
- Validate the outdoor pressure loop against the current warmth, travel, and building-memory baseline.
- Keep the codex, note unlocks, lighter charges, and tool requirements aligned with the active crafting UI.
- Continuously remove dead code, obsolete UI paths, temporary scaffolding, and other local junk that would otherwise pollute future implementation patterns.

## Temporary Development Conditions

- Dev-only starter items and shortcut grants are still enabled for playtesting.
- Treat them as temporary scaffolding, not production behavior.
- Keep them in place until balance and survival pressure are stable enough to remove them cleanly.
