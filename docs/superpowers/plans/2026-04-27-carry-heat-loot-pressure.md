# Carry, Heat, and Loot Pressure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **User workflow note:** Do not try to land this as one giant blind rewrite. Execute in three verified checkpoints: `carry/weight`, then `heat/camp`, then `quantity supply`. Do not move to the next checkpoint until the current one is stable.

**Goal:** Replace the current count-style carrying model with a weight-driven hauling model, make outdoor cold pressure depend on real heat-source setup instead of passive indoor recovery, and let large-stock scavenging sites expose meaningful quantity choices instead of only one-off item rolls.

**Architecture:** Keep `RunState` as the runtime authority for survival state, movement speed, and carried state. Replace `InventoryModel` bulk math with carry-weight math, keep bag upgrades as equipment-driven modifiers, and use a distinct `carry_weight` field so item carry math never collides with existing loot-table `"weight"` roll fields. Heat recovery remains run-state driven, but now depends on explicit heat-source rules instead of item warmth alone. Large-stock sites gain authored `supply_sources` contracts layered onto existing indoor JSON instead of replacing the current zone-memory system.

**Tech Stack:** Godot 4.4.1, GDScript, JSON-authored items/jobs/traits/indoor sites, existing headless Godot test suite

---

## File Map

### Create

- `game/tests/unit/test_inventory_weight_model.gd`
  - Regression suite for carry-weight math, overloaded/overpacked thresholds, and add-item rejection.
- `game/tests/unit/test_heat_source_rules.gd`
  - Regression suite for indoor cold stabilization, outdoor loss, and heat-source recovery gating.
- `game/tests/unit/test_supply_source_selection.gd`
  - Regression suite for quantity-bearing sources and `1 / 3 / max / custom` selection behavior.

### Modify

- `game/data/items.json`
  - Add `carry_weight` and future quantity-source compatibility metadata to carried items.
- `game/data/jobs.json`
  - Replace `carry_limit` modifiers with weight-capacity modifiers.
- `game/data/traits.json`
  - Support future carry-weight-affecting traits if needed.
- `game/data/buildings.json`
  - Add heat-source and supply-source affordance metadata where building-level hints are needed.
- `game/data/events/indoor/mart_01.json`
- `game/data/events/indoor/hardware_01.json`
- `game/data/events/indoor/warehouse_01.json`
  - Add first quantity-bearing supply sources to the highest-value stock sites.
- `game/scripts/run/inventory_model.gd`
  - Replace bulk accounting with carry-weight accounting and explicit overloaded/overpacked state.
- `game/scripts/run/run_state.gd`
  - Rework carry-derived movement penalties, bag modifiers, pickup blocking, and heat-source recovery rules.
- `game/scripts/run/warmth_model.gd`
  - Separate passive warmth item effects from explicit heat recovery rules.
- `game/scripts/run/run_controller.gd`
  - Surface new pickup rejection and supply-source selection flows in outdoor play.
- `game/scripts/outdoor/outdoor_controller.gd`
  - Apply stronger outdoor cold pressure and expose nearby-site tension through the new state contract.
- `game/scripts/indoor/indoor_director.gd`
  - Replace `(bulk/carry_limit)` strings with weight/carry-state messaging and broker quantity-source actions.
- `game/scripts/indoor/indoor_mode.gd`
  - Present heat/carry feedback and supply-source choice prompts within the indoor flow.
- `game/scripts/ui/survival_sheet.gd`
  - Show `current weight / max weight`, per-item `carry_weight`, and the new carry-state labels.
- `game/tests/unit/test_content_library.gd`
  - Lock the new canonical item/job fields.
- `game/tests/unit/test_survival_sheet.gd`
  - Lock bag UI weight strings and overpacked pickup messaging.
- `game/tests/unit/test_indoor_mode.gd`
  - Lock indoor carry/heat/supply-source interaction behavior.
- `game/tests/unit/test_outdoor_controller.gd`
  - Lock outdoor cold pressure and movement-speed effects.
- `game/tests/smoke/test_first_playable_loop.gd`
  - Keep the first playable loop stable as carry and loot pressure semantics change.
- `docs/INDEX.md`
  - Route readers to the new active plan.
- `docs/CURRENT_STATE.md`
  - Make this plan the near-term execution driver.

### Responsibilities

- `InventoryModel`
  - Own pure carry math only: total carried weight, ideal/load/overpack thresholds, and add-item eligibility.
- `RunState`
  - Own gameplay consequences of carry and heat: movement penalties, fatigue implications, camp requirements, and pickup rejection reasons.
- `IndoorDirector` / `IndoorMode`
  - Translate state into readable indoor choices and compact bag/supply UX.
- `OutdoorController`
  - Make outside pressure visible and mechanically meaningful while staying consistent with run-state rules.
- `SurvivalSheet`
  - Show the numbers the player needs for planning: per-item weight, current load, carry state, and inability-to-pick-up feedback.

### Implementation Notes

- Do **not** reuse the field name `weight` for carry. Indoor loot tables already use `"weight"` as weighted-random roll strength. Use `carry_weight`, `carry_capacity_bonus`, `ideal_carry_bonus`, or similarly explicit names.
- Keep the first pass narrow on item semantics. Partial consumption, split water use, and fuel volume are future work. This pass only needs the data model to leave room for them.
- Do not try to convert every site to quantity-bearing scavenging in one go. First pass is `mart_01`, `hardware_01`, and `warehouse_01`.
- Preserve one-off pickups for keys, notes, unique tools, and authored reveals.

---

## Task 1: Lock The Carry-Weight Contract Before Refactoring

**Files:**
- Create: `game/tests/unit/test_inventory_weight_model.gd`
- Modify: `game/tests/unit/test_content_library.gd`

- [ ] **Step 1: Add a focused carry-model regression suite**

Create `game/tests/unit/test_inventory_weight_model.gd` to lock:

- `InventoryModel` total carried weight
- ideal / overloaded / overpacked thresholds
- add-item rejection when overpacked
- same-item stacks still represented as repeated carried entries for now

The suite should exercise at least:

- empty inventory returns `0.0` weight
- adding two `carry_weight` items sums correctly
- a bag/capacity bonus changes threshold behavior
- `overpacked` blocks `add_item`

- [ ] **Step 2: Raise the content contract for weight fields**

Update `game/tests/unit/test_content_library.gd` so the canonical item and modifier data now expects:

- `carry_weight` on carried items
- no gameplay dependence on `bulk` for newly touched content
- job/item carry modifiers renamed away from `carry_limit`

At minimum, lock contracts for:

- one basic consumable
- one water item
- one bag item
- one heavy equipment item
- the `clerk` job modifier row

- [ ] **Step 3: Confirm the current implementation fails the new tests**

Run the new inventory-weight test and the updated content-library test before touching implementation.

Expected:

- both fail because runtime and data are still bulk-driven

---

## Task 2: Replace Bulk With Carry Weight In Runtime And UI

**Files:**
- Modify: `game/data/items.json`
- Modify: `game/data/jobs.json`
- Modify: `game/data/traits.json`
- Modify: `game/scripts/run/inventory_model.gd`
- Modify: `game/scripts/run/run_state.gd`
- Modify: `game/scripts/indoor/indoor_director.gd`
- Modify: `game/scripts/ui/survival_sheet.gd`
- Modify: `game/tests/unit/test_survival_sheet.gd`
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Modify: `game/tests/unit/test_outdoor_controller.gd`

- [ ] **Step 1: Introduce explicit carry fields in data**

Revise item and modifier data:

- `bulk`-based carry semantics -> `carry_weight`
- `carry_limit_bonus` -> `carry_capacity_bonus`
- if needed, also add a separate bag comfort field such as `ideal_carry_bonus`
- `jobs.json` and future trait modifiers should use carry-capacity names, not `carry_limit`

Do not remove legacy fields until runtime no longer reads them, but the new pass should treat the new fields as canonical.

- [ ] **Step 2: Refactor `InventoryModel` into weight math**

Replace:

- `carry_limit`
- `total_bulk()`
- `max_bulk()`
- `overflow_bulk()`

with carry-weight equivalents such as:

- `carry_capacity`
- `ideal_carry_capacity`
- `overpack_capacity`
- `total_carry_weight()`
- `get_carry_state()`
- `can_add(item)` based on overpack cap

`InventoryModel` should stay presentation-agnostic. It should not decide movement penalties itself.

- [ ] **Step 3: Rework `RunState` derived stats around carry-state bands**

Update `RunState` so it:

- calculates capacity from base state + job + bag/equipment
- exposes `get_carry_state_id()`
- exposes `get_carry_weight_summary()` for UI use
- applies outdoor movement penalty from carry state instead of raw overflow bulk
- keeps `과적` movable but blocks further pickup

Recommended first-pass banding:

- `적정`: normal speed
- `과중`: noticeable outdoor movement penalty
- `과적`: stronger penalty, pickup blocked

- [ ] **Step 4: Replace bag strings and item detail text**

Update bag presentation so it shows:

- `현재 중량 / 최대 중량`
- carry-state text
- per-item weight in row/detail text
- bag equipment bonuses in the new weight vocabulary

Replace current strings like:

- `소지품 (%d/%d)`
- `소지 한도 +%d`
- `과적: 실외 이동속도 %d%%`

with explicit weight language.

- [ ] **Step 5: Verify the carry-only checkpoint before touching heat**

Run at least:

- `test_inventory_weight_model.gd`
- `test_content_library.gd`
- `test_survival_sheet.gd`
- `test_indoor_mode.gd`
- `test_outdoor_controller.gd`
- `test_first_playable_loop.gd`

Do not start Task 3 until the carry checkpoint is green.

---

## Task 3: Make Heat Recovery Depend On Real Heat Sources

**Files:**
- Create: `game/tests/unit/test_heat_source_rules.gd`
- Modify: `game/scripts/run/warmth_model.gd`
- Modify: `game/scripts/run/run_state.gd`
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Modify: `game/scripts/indoor/indoor_director.gd`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/data/items.json`
- Modify: `game/data/buildings.json`

- [ ] **Step 1: Lock the new heat contract in tests**

Add tests for:

- outdoor time drains exposure
- indoor time stops further drain but does not restore exposure
- warmth consumables may still give short buffs, but real recovery requires a valid heat source
- a portable heat device can be carried and reused
- fixed-site heat sources remain site-bound

- [ ] **Step 2: Split “warmth buff” from “true heat recovery”**

`WarmthModel` and `RunState` should distinguish:

- short-lived exposure mitigation from drinks/consumables
- actual recovery made possible by a valid heat-source setup

The first pass should model heat-source validity as:

- ignition tool present
- fuel present
- setup base present

Do not build a full camp-building UI yet. This pass only needs the rule contract and enough state to support future actions.

- [ ] **Step 3: Apply the new indoor/outdoor exposure semantics**

Make the runtime semantics explicit:

- outdoor: exposure drains
- indoor without heat source: no passive drain, no passive recovery
- indoor with heat source: recovery is possible through actions/setup

- [ ] **Step 4: Surface the rules in player-facing copy**

Update indoor/outdoor feedback so the player understands:

- entering shelter stopped the decline
- recovery still needs heat
- carrying portable heat gear is a meaningful strategic choice

- [ ] **Step 5: Verify the heat checkpoint**

Run the new heat-source test plus:

- `test_indoor_mode.gd`
- `test_outdoor_controller.gd`
- `test_first_playable_loop.gd`

Do not move to quantity-bearing scavenging until the exposure model is stable.

---

## Task 4: Add Quantity-Bearing Supply Sources To High-Stock Sites

**Files:**
- Create: `game/tests/unit/test_supply_source_selection.gd`
- Modify: `game/data/events/indoor/mart_01.json`
- Modify: `game/data/events/indoor/hardware_01.json`
- Modify: `game/data/events/indoor/warehouse_01.json`
- Modify: `game/scripts/indoor/indoor_director.gd`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scripts/ui/survival_sheet.gd`
- Modify: `game/scripts/run/run_state.gd`
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Define a supply-source contract in indoor event JSON**

Add an authored pattern for large-stock sources, for example:

- supply source id
- item id
- available quantity
- optional per-action time
- optional depletion memory

Keep it layered onto existing site memory and action resolution. Do not replace the current loot/reveal system for one-off authored finds.

- [ ] **Step 2: Add the first quantity-bearing sites**

Author quantity-bearing sources for:

- `mart_01`
- `hardware_01`
- `warehouse_01`

Examples:

- water stock
- canned food stock
- snack shelf
- tape/fastener shelf
- screwdriver/tool bin
- tarp/jerrycan stock

The point is not to create infinite loot. The point is to let the player see abundance and choose how much to carry away.

- [ ] **Step 3: Implement the first-pass quantity selection UX**

Support:

- `1개`
- `3개`
- `최대`
- `세부`

First pass can keep `세부` lightweight, but the selection flow must respect:

- remaining quantity
- available carry space
- current carry state
- time cost if applicable

- [ ] **Step 4: Make quantity choices respect overpack blocking**

Quantity pickup logic must stop at the new carry rules:

- if the chosen amount exceeds overpack allowance, reject or clamp appropriately
- `최대` should mean “maximum legal pickup under current carry limits”, not “full stock regardless of state”

- [ ] **Step 5: Verify the scavenging checkpoint**

Run:

- `test_supply_source_selection.gd`
- `test_indoor_mode.gd`
- `test_first_playable_loop.gd`

and confirm the new quantity-bearing scavenging does not break the rest of the indoor loop.

---

## Task 5: Documentation And Stabilization Pass

**Files:**
- Modify: `docs/INDEX.md`
- Modify: `docs/CURRENT_STATE.md`

- [ ] **Step 1: Route the active plan**

Add this implementation plan to `docs/INDEX.md` under active plans and place it above older April 20 plans.

- [ ] **Step 2: Update the current state snapshot**

Update `docs/CURRENT_STATE.md` so the near-term plan stack and immediate priorities reflect:

- carry-weight migration first
- heat-source-based recovery second
- quantity-bearing supply sources third

- [ ] **Step 3: Do one final verification sweep**

Before wrap-up, run the focused unit tests for the touched checkpoint plus `test_first_playable_loop.gd`.

If you complete the whole umbrella in one session, also rerun:

- `test_content_library.gd`
- `test_outdoor_controller.gd`
- `test_indoor_mode.gd`
- `test_survival_sheet.gd`

Do not claim the pass is stable until the active checkpoint tests are green.
