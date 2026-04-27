# Current State

- Status: active
- Last updated: 2026-04-20
 

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

- [Toast Feedback System Design](superpowers/specs/2026-04-20-toast-feedback-system-design.md)
- [Indoor Depth and Item Expansion Design](superpowers/specs/2026-04-20-indoor-depth-item-expansion-design.md)
- [Outdoor 3x3 Authored Slice Design](superpowers/specs/2026-04-17-outdoor-3x3-authored-slice-design.md)
- [Portrait UI Framework Design](superpowers/specs/2026-04-17-portrait-ui-framework-design.md)
- [Outdoor Art Integration Pass 1 Design](superpowers/specs/2026-04-16-outdoor-art-integration-pass1-design.md)
- [Inventory Craft Slot Bar Design](superpowers/specs/2026-04-16-inventory-craft-slot-bar-design.md)
- [Inventory Bottom Sheet Redesign](superpowers/specs/2026-04-16-inventory-bottom-sheet-redesign.md)
- [Outdoor Spatial Map UI Design](superpowers/specs/2026-04-15-outdoor-spatial-map-ui-design.md)
- [Outdoor Map And Fog UI Design](superpowers/specs/2026-04-15-outdoor-map-and-fog-ui-design.md)
- [Outdoor Threat and Cold Feedback Design](superpowers/specs/2026-04-13-outdoor-threat-and-cold-feedback-design.md)
- [Outdoor World Architecture Design](superpowers/specs/2026-04-15-outdoor-world-architecture-design.md)
- [Outdoor 2x2 Block Expansion Design](superpowers/specs/2026-04-15-outdoor-2x2-block-expansion-design.md) (superseded)
- [Context Routing Docs Design](superpowers/specs/2026-04-10-context-routing-docs-design.md)
- [Contextual Crafting UI Design](superpowers/specs/2026-04-09-contextual-crafting-ui-design.md)
- [Portrait Phase 1 Shell Design](superpowers/specs/2026-04-07-portrait-phase1-shell-design.md)
- [Indoor Portrait Survival Sheet Design](superpowers/specs/2026-04-07-indoor-portrait-survival-sheet-design.md)
- [Crafting Codex Lighter Design](superpowers/specs/2026-04-06-crafting-codex-lighter-design.md)

## Active Plans

For the full active plan inventory, use `docs/INDEX.md`. The list below is the near-term plan stack currently driving implementation.

- [Toast Feedback System](superpowers/plans/2026-04-20-toast-feedback-system.md)
- [Indoor Depth and Item Expansion](superpowers/plans/2026-04-20-indoor-depth-item-expansion.md)
- [Outdoor 3x3 Authored Slice](superpowers/plans/2026-04-17-outdoor-3x3-authored-slice.md)
- [Portrait UI Framework](superpowers/plans/2026-04-17-portrait-ui-framework.md)
- [Outdoor Art Integration Pass 1](superpowers/plans/2026-04-16-outdoor-art-integration-pass1.md)
- [Inventory Craft Slot Bar](superpowers/plans/2026-04-16-inventory-craft-slot-bar.md)
- [Inventory Bottom Sheet Redesign](superpowers/plans/2026-04-16-inventory-bottom-sheet-redesign.md)
- [Outdoor Map And Fog UI](superpowers/plans/2026-04-15-outdoor-map-and-fog-ui.md)
- [Outdoor World Architecture](superpowers/plans/2026-04-15-outdoor-world-architecture.md)
- [Outdoor 2x2 Block Expansion](superpowers/plans/2026-04-15-outdoor-2x2-block-expansion.md) (superseded)
- [Outdoor Threat and Cold Feedback](superpowers/plans/2026-04-13-outdoor-threat-and-cold-feedback.md)
- [Context Routing Docs](superpowers/plans/2026-04-10-context-routing-docs.md)
- [Contextual Crafting UI](superpowers/plans/2026-04-09-contextual-crafting-ui.md)
- [Portrait Phase 1 Shell](superpowers/plans/2026-04-07-portrait-phase1-shell.md)
- [Indoor Portrait Survival Sheet](superpowers/plans/2026-04-07-indoor-portrait-survival-sheet.md)
- [Crafting Codex Lighter](superpowers/plans/2026-04-06-crafting-codex-lighter.md)

## Immediate Priorities

- Add a shared toast feedback layer for short pickup/craft/warning reactions without removing the existing result text yet.
- Deepen the existing building set before pushing outdoor radius again: anchor four buildings into real multi-zone sites and lift the rest out of one-zone shells.
- Expand the item compendium with more believable site-specific finds, not just more raw crafting materials.
- Expand crafted items and cross-recipes so new and existing items can coexist in a deeper authored crafting graph.
- Maintain a separate resource-request ledger for newly introduced buildings and items so art generation can track content growth cleanly.
- Unify outdoor and indoor under one shared portrait top ribbon before generating more UI art.
- Replace text-only survival status in the HUD/top bar with compact gauges for health, hunger, thirst, fatigue, and cold.
- Replace placeholder outdoor geometry with frozen-city terrain, buildings, props, and player art while keeping the streamed city runtime stable.
- Redesign the shared bag UI around a list-first base state with contextual bottom detail instead of a permanently split inventory/detail layout.
- Replace the weak inline craft-status text with an explicit craft slot bar that still keeps the bag as the main surface.
- Finish the bag-first contextual crafting flow so the bag stays the main inventory surface.
- Tighten the portrait indoor sheet and shell so text-heavy decisions remain readable on mobile.
- Build the first outdoor pressure loop with animal pursuit, cold feedback, and more game-like real-time tension.
- Replace the temporary outdoor district scaffolding with a fixed-city streamed block runtime built on fixed-size blocks.
- Expand the first authored city slice from `2x2` to a full contiguous `3x3` so outdoor travel stops feeling tiny before deeper loot/story passes land.
- Keep the city globally open while revealing map knowledge per run from visited blocks only.
- Replace the mismatched outdoor minimap/full-map split with a coherent spatial map stack: local minimap, draggable full outdoor map, fog-of-war, and separate indoor building-detail layer.
- Keep the codex, note unlocks, lighter charges, and tool requirements aligned with the active crafting UI.
- Continuously remove dead code, obsolete UI paths, temporary scaffolding, and other local junk that would otherwise pollute future implementation patterns.

## Temporary Development Conditions

- Dev-only starter items and shortcut grants are still enabled for playtesting.
- Treat them as temporary scaffolding, not production behavior.
- Keep them in place until balance and survival pressure are stable enough to remove them cleanly.
