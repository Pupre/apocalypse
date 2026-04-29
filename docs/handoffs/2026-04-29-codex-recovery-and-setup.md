# 2026-04-29 Codex Recovery And Setup

This document is the fast handoff for a new Codex session on a fresh machine.

Use this when:

- the repo was freshly cloned
- the next agent needs the current project direction quickly
- the next agent should continue the current implementation without re-discovering the whole project

## Read Order

Do not read the whole repo blindly.

Read in this order:

1. [AGENTS.md](../../AGENTS.md)
2. [Current State](../CURRENT_STATE.md)
3. [Carry, Heat, and Loot Pressure Design](../superpowers/specs/2026-04-27-carry-heat-loot-pressure-design.md)
4. [Carry, Heat, and Loot Pressure Plan](../superpowers/plans/2026-04-27-carry-heat-loot-pressure.md)
5. This handoff

After that, read only the files relevant to the current task.

## Current Product Direction

The game direction is now much clearer than the early prototype stage.

- portrait-first mobile survival game
- outdoor play is about cold, travel risk, and route judgment
- indoor play is text-heavy, authored, and decision-driven
- the fantasy is not generic looting, but disaster-preparedness prioritization
- the player should feel:
  - supplies exist in meaningful quantity
  - I cannot carry everything
  - what I choose now affects what I can survive later
  - a building may be reachable, but the real question is whether I can return or establish heat there

The current active umbrella spec for that direction is:

- [Carry, Heat, and Loot Pressure Design](../superpowers/specs/2026-04-27-carry-heat-loot-pressure-design.md)

## Where The Project Stands

Latest already-committed baseline before the current patch:

- `2eb12c1 feat: integrate addon item icon pack`

Recent committed baseline before that:

- `60d5e05 feat: expand survival content and unify UI systems`

Current work after those commits:

- carry-weight model pass
- heat-source / indoor-vs-outdoor temperature rules
- first quantity-bearing supply sources

At the time this handoff was written, those changes were in the working tree and should be pushed together with this document.

## What Is Already Implemented

### 1. Carry-Weight Baseline

The old count/bulk-style carry baseline has been partially replaced with weight-driven hauling.

Implemented:

- items now use explicit `carry_weight`
- jobs can affect carry-related thresholds
- inventory model evaluates total carry weight
- player load is expressed as:
  - `적정`
  - `과중`
  - `과적`
- `과적` blocks additional pickup instead of hard-freezing movement

Key files:

- [items.json](../../game/data/items.json)
- [jobs.json](../../game/data/jobs.json)
- [inventory_model.gd](../../game/scripts/run/inventory_model.gd)
- [run_state.gd](../../game/scripts/run/run_state.gd)
- [survival_sheet.gd](../../game/scripts/ui/survival_sheet.gd)

Tests:

- [test_inventory_weight_model.gd](../../game/tests/unit/test_inventory_weight_model.gd)

### 2. Heat Source Rules

The intended cold model is now partially encoded.

Current rule set:

- outdoors causes heat loss
- indoors stops further heat loss
- indoors does not automatically restore heat
- meaningful recovery requires a heat source
- some sites have fixed heat sources
- portable heat setups are now part of the design direction, but not fully rolled out in UX/content

Current authored fixed heat sources:

- `mart_01 / break_room`
- `apartment_01 / boiler_room`

Key files:

- [buildings.json](../../game/data/buildings.json)
- [run_state.gd](../../game/scripts/run/run_state.gd)
- [indoor_director.gd](../../game/scripts/indoor/indoor_director.gd)

Tests:

- [test_heat_source_rules.gd](../../game/tests/unit/test_heat_source_rules.gd)

### 3. Quantity-Bearing Supply Sources

The first pass of “large-stock sites should not feel like they only contain one of everything” is in.

Implemented:

- authored supply sources with remaining quantity
- actions:
  - `1개`
  - `3개`
  - `최대한`
  - `세부`
- quantity selection overlay in indoor mode
- remaining stock persists in site memory

Current authored first-pass sites:

- `mart_01`
- `hardware_01`
- `warehouse_01`

Current authored examples:

- mart food aisle:
  - `bottled_water x12`
  - `instant_soup_powder x8`
- hardware parts shelf:
  - `hose_clamp x10`
  - `rubber_gasket x12`
- warehouse loading:
  - `trash_bag_roll x6`
  - `empty_jerrycan x4`

Key files:

- [mart_01.json](../../game/data/events/indoor/mart_01.json)
- [hardware_01.json](../../game/data/events/indoor/hardware_01.json)
- [warehouse_01.json](../../game/data/events/indoor/warehouse_01.json)
- [indoor_action_resolver.gd](../../game/scripts/indoor/indoor_action_resolver.gd)
- [indoor_director.gd](../../game/scripts/indoor/indoor_director.gd)
- [indoor_mode.gd](../../game/scripts/indoor/indoor_mode.gd)
- [indoor_mode.tscn](../../game/scenes/indoor/indoor_mode.tscn)

Tests:

- [test_supply_source_selection.gd](../../game/tests/unit/test_supply_source_selection.gd)
- [test_indoor_mode.gd](../../game/tests/unit/test_indoor_mode.gd)

## What Is Not Finished Yet

The system direction is good, but the pressure loop is not done yet.

Still pending:

- stronger outdoor cold pressure tuning
- stronger coupling between carry state and risky outdoor travel
- broader rollout of quantity-bearing supply sources to more authored sites
- portable heat-source setup / recovery UX and site authoring
- partial consumption candidates are still design-only, not implemented

The next most natural implementation task is:

- tune outdoor pressure until the player starts thinking
  - “저 건물까지 갈 수는 있는데, 돌아올 수 있나?”

## Current Active Goal

The immediate active goal is no longer “just add more content.”

It is:

- make outdoor trips materially dangerous
- make carry decisions materially consequential
- make high-stock scavenging feel like selective hauling, not single-item loot rolls

That means the next pass should focus more on:

- pressure tuning
- route risk
- return-vs-relocate judgment

and less on:

- new cosmetic UI cleanup
- wider map expansion before pressure is real

## Important Active Docs

These are the documents that matter most right now.

### Active Specs

- [Carry, Heat, and Loot Pressure Design](../superpowers/specs/2026-04-27-carry-heat-loot-pressure-design.md)
- [Indoor Depth and Item Expansion Design](../superpowers/specs/2026-04-20-indoor-depth-item-expansion-design.md)
- [Toast Feedback System Design](../superpowers/specs/2026-04-20-toast-feedback-system-design.md)
- [Portrait UI Framework Design](../superpowers/specs/2026-04-17-portrait-ui-framework-design.md)
- [Outdoor 3x3 Authored Slice Design](../superpowers/specs/2026-04-17-outdoor-3x3-authored-slice-design.md)

### Active Plans

- [Carry, Heat, and Loot Pressure](../superpowers/plans/2026-04-27-carry-heat-loot-pressure.md)
- [Indoor Depth and Item Expansion](../superpowers/plans/2026-04-20-indoor-depth-item-expansion.md)
- [Toast Feedback System](../superpowers/plans/2026-04-20-toast-feedback-system.md)
- [Portrait UI Framework](../superpowers/plans/2026-04-17-portrait-ui-framework.md)
- [Outdoor 3x3 Authored Slice](../superpowers/plans/2026-04-17-outdoor-3x3-authored-slice.md)

### Background Docs

- [Core Gameplay Design](../specs/core-gameplay-design.md)
- [Godot Technical Architecture](../specs/godot-technical-architecture.md)

## Files To Inspect First For The Current Patch

If continuing the current carry/heat/loot pressure work, inspect these first:

- [run_state.gd](../../game/scripts/run/run_state.gd)
- [inventory_model.gd](../../game/scripts/run/inventory_model.gd)
- [indoor_action_resolver.gd](../../game/scripts/indoor/indoor_action_resolver.gd)
- [indoor_director.gd](../../game/scripts/indoor/indoor_director.gd)
- [indoor_mode.gd](../../game/scripts/indoor/indoor_mode.gd)
- [indoor_mode.tscn](../../game/scenes/indoor/indoor_mode.tscn)
- [items.json](../../game/data/items.json)
- [buildings.json](../../game/data/buildings.json)
- [mart_01.json](../../game/data/events/indoor/mart_01.json)
- [hardware_01.json](../../game/data/events/indoor/hardware_01.json)
- [warehouse_01.json](../../game/data/events/indoor/warehouse_01.json)

## Verification Commands

These are the key regression commands used in the current environment.

Use Godot 4.4.1 headless with the project path:

```bash
XDG_DATA_HOME=/tmp/codex-godot-home \
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
--headless --path /home/muhyeon_shin/packages/apocalypse/game -s <test-script>
```

The high-signal checks for the current patch are:

```bash
res://tests/unit/test_inventory_weight_model.gd
res://tests/unit/test_heat_source_rules.gd
res://tests/unit/test_supply_source_selection.gd
res://tests/unit/test_indoor_mode.gd
res://tests/smoke/test_first_playable_loop.gd
```

At the time this handoff was written, those all passed.

## Fresh Laptop / Fresh Codex Setup

### Required Local Tools

Minimum:

- `git`
- `bash`
- Godot `4.4.1`

Strongly preferred:

- the same headless Godot binary version used in this repo
- a local writable temp/data path for test runs

If the new machine does not have the exact Godot binary path used above, use any equivalent Godot `4.4.1 stable` binary and adjust the command.

### Codex Skills Used In Practice

This repo does not require custom project-local MCP servers just to continue development.

The useful Codex skills for this project were:

- `using-superpowers`
- `brainstorming`
- `test-driven-development`
- `verification-before-completion`
- `writing-plans`
- `systematic-debugging`

Optional but useful:

- `worklog-driven-dev`
- `requesting-code-review`

### MCP / Plugin Notes

Required for core repo work:

- none beyond normal shell/file editing

Optional:

- GitHub plugin if you want PR/issue/CI integration

Image generation note:

- if the environment exposes the built-in `image_gen` tool, image generation can work without a local `OPENAI_API_KEY`
- if using the local CLI fallback image workflow, `OPENAI_API_KEY` is required

### What The Next Codex Session Should Be Told

If starting a new Codex session on a fresh clone, a short prompt like this is enough:

```text
Read AGENTS.md, docs/CURRENT_STATE.md, docs/handoffs/2026-04-29-codex-recovery-and-setup.md, and the carry/heat/loot pressure spec and plan. Then continue the next implementation pass from the current carry-weight + heat-source + quantity-supply baseline. Prioritize outdoor pressure tuning next.
```

That should be enough context for a competent follow-up session to continue without a long manual explanation.
