# Portrait UI Framework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish one shared portrait UI frame, starting with a common top ribbon and compact survival gauges used by both outdoor and indoor play.

**Architecture:** Introduce a shared top-ribbon scene plus a compact gauge row, then route both outdoor HUD and indoor top area through that shared surface. Preserve current bag and map flows while replacing text-only survival labels with stable gauge presentation.

**Tech Stack:** Godot 4.4, GDScript, shared scenes under `game/scenes/shared`, existing `RunState` survival values, current portrait HUD/bag/map flows.

---

### Task 1: Add A Shared Portrait Top Ribbon Scene

**Files:**
- Create: `game/scenes/shared/top_ribbon.tscn`
- Create: `game/scripts/ui/top_ribbon.gd`
- Test: `game/tests/unit/test_hud_presenter.gd`

- [ ] **Step 1: Write the failing test expectations**

Update the HUD-side test to require a reusable two-row ribbon shape:

```gdscript
var top_ribbon := hud.get_node_or_null("TopRibbon")
var header_row := hud.get_node_or_null("TopRibbon/Margin/Stack/HeaderRow")
var gauge_row := hud.get_node_or_null("TopRibbon/Margin/Stack/GaugeRow")
assert_true(top_ribbon != null)
assert_true(header_row != null)
assert_true(gauge_row != null)
```

- [ ] **Step 2: Run the targeted test and confirm failure**

Run:

```bash
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/unit/test_hud_presenter.gd
```

Expected: FAIL because the old HUD still exposes `StatsRow` labels rather than the new gauge row contract.

- [ ] **Step 3: Create the shared top ribbon scene and script**

Create `game/scenes/shared/top_ribbon.tscn` as a compact panel with:

- header row: location, time, map button, bag button
- gauge row: five gauge slots

Create `game/scripts/ui/top_ribbon.gd` with bind/update helpers for:

- location text
- clock text
- button visibility/text
- gauge values and stage labels

- [ ] **Step 4: Replace the old HUD root with the shared ribbon instance**

Modify `game/scenes/run/hud.tscn` to instance `top_ribbon.tscn` instead of owning the old label-only structure directly.

Update `game/scripts/run/hud_presenter.gd` to talk to the shared ribbon script rather than individual text labels.

- [ ] **Step 5: Re-run the HUD test**

Run:

```bash
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/unit/test_hud_presenter.gd
```

Expected: PASS

### Task 2: Replace Text-Only Survival Labels With Compact Gauges

**Files:**
- Modify: `game/scripts/ui/top_ribbon.gd`
- Modify: `game/scripts/run/hud_presenter.gd`
- Test: `game/tests/unit/test_hud_presenter.gd`

- [ ] **Step 1: Extend the HUD test to assert gauge rendering**

Add expectations that:

- five gauges exist
- health / hunger / thirst / fatigue / cold all render through gauge nodes
- carry text is removed from the persistent outdoor ribbon

- [ ] **Step 2: Run the targeted test and confirm failure**

Run:

```bash
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/unit/test_hud_presenter.gd
```

Expected: FAIL because the ribbon still renders text-only placeholders or missing gauge slots.

- [ ] **Step 3: Implement compact gauge rendering**

Update `top_ribbon.gd` so each survival stat is shown as:

- icon node
- fill bar
- small stage/value label

Map existing run-state accessors onto these five slots:

- `get_health_stage()`
- `get_hunger_stage()`
- `get_thirst_stage()`
- `get_fatigue_stage()`
- `get_temperature_stage()` or the existing cold/exposure presentation source

- [ ] **Step 4: Re-run the HUD test**

Run:

```bash
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/unit/test_hud_presenter.gd
```

Expected: PASS

### Task 3: Use The Same Ribbon Family In Indoor Mode

**Files:**
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Write the failing indoor test expectations**

Extend the indoor test so it expects:

- shared top-ribbon structure, not the current ad hoc `TopBar` internals
- same global button family
- same five survival gauges

- [ ] **Step 2: Run the indoor test and confirm failure**

Run:

```bash
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/unit/test_indoor_mode.gd
```

Expected: FAIL because indoor still owns a separate top-bar layout.

- [ ] **Step 3: Replace the indoor top bar with the shared ribbon instance**

Modify `game/scenes/indoor/indoor_mode.tscn`:

- remove the bespoke top-bar row stack
- instance the shared `top_ribbon.tscn`
- keep indoor-specific structure button text if needed

Modify `game/scripts/indoor/indoor_mode.gd` so it populates the shared ribbon with:

- indoor location
- time
- structure button
- bag button
- survival gauges

- [ ] **Step 4: Re-run the indoor test**

Run:

```bash
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/unit/test_indoor_mode.gd
```

Expected: PASS

### Task 4: Verify Bag and Map Entry Flows Still Work

**Files:**
- Modify: `game/tests/unit/test_run_controller_live_transition.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Add regression checks around ribbon buttons**

Add assertions that:

- outdoor ribbon map button still opens the full map overlay
- outdoor ribbon bag button still opens the shared bag
- indoor ribbon structure button still opens indoor structure view
- indoor ribbon bag button still opens the shared bag

- [ ] **Step 2: Run targeted regressions and confirm current failures if any**

Run:

```bash
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/unit/test_run_controller_live_transition.gd
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/smoke/test_first_playable_loop.gd
```

Expected: any broken node paths or missing signal wiring should fail here.

- [ ] **Step 3: Fix ribbon signal wiring and node paths**

Update any controller/presenter paths needed so the new shared ribbon still drives:

- map open/close
- bag open/close
- indoor structure open/close

- [ ] **Step 4: Re-run regressions**

Run:

```bash
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/unit/test_run_controller_live_transition.gd
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/smoke/test_first_playable_loop.gd
```

Expected: PASS

### Task 5: Final Verification

**Files:**
- Verify only

- [ ] **Step 1: Run the focused suite**

Run:

```bash
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/unit/test_hud_presenter.gd
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/unit/test_indoor_mode.gd
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/unit/test_run_controller_live_transition.gd
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game res://tests/smoke/test_first_playable_loop.gd
HOME=/tmp ../.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path game --quit-after 1
```

Expected:

- unit tests pass
- smoke test passes
- headless boot exits cleanly

- [ ] **Step 2: Update current-state docs if the implementation changed visible direction**

Update:

- `docs/CURRENT_STATE.md`
- `docs/INDEX.md`

Only if implementation materially changes the active direction beyond what the spec already captured.
