# Survival Stats First Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the first production-facing survival layer for `허기`, `갈증`, `체력`, and `피로` so scavenging, consumption, rest, sleep, and time pressure all affect indoor and outdoor play in a readable way.

**Architecture:** Extend `RunState` into the single source of truth for survival numbers and stage labels, then route time passage, item consumption, indoor actions, and outdoor movement through that model. Player-facing UI should show readable stage summaries while item panels and action results expose exact stat deltas where needed.

**Tech Stack:** Godot 4, GDScript, JSON item metadata, existing indoor/outdoor controllers, headless Godot tests

---

### Task 1: Expand the Core Survival Model in RunState

**Files:**
- Modify: `game/scripts/run/run_state.gd`
- Test: `game/tests/unit/test_run_models.gd`

- [ ] **Step 1: Write the failing run-state expectations**

Extend `game/tests/unit/test_run_models.gd` so it asserts:

- `갈증` exists alongside `허기`, `체력`, and `피로`
- stage helpers exist for all four stats
- passive time passage changes `허기`, `갈증`, and `피로`
- outdoor passage is harsher than indoor passage
- `허기` or `갈증` at zero causes ongoing health loss

- [ ] **Step 2: Run the run-model test to verify failure**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_run_models.gd
```

Expected: FAIL because thirst, stage display helpers, and zero-state damage are not implemented yet.

- [ ] **Step 3: Implement the first-pass survival math**

Update `game/scripts/run/run_state.gd` to:

- add numeric `thirst`
- add stage-label helpers for `허기`, `갈증`, `체력`, `피로`
- split passive decay into indoor/outdoor-aware methods
- apply harsher thirst decay than hunger
- apply continuous health loss when hunger or thirst is zero
- keep health recovery explicit only

- [ ] **Step 4: Re-run the run-model test**

Run the same command from Step 2.

Expected: `RUN_MODELS_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scripts/run/run_state.gd \
  game/tests/unit/test_run_models.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add first-pass survival state model"
```

### Task 2: Wire Exact Item Effects for Food, Drink, Medicine, and Stimulants

**Files:**
- Modify: `game/data/items.json`
- Modify: `game/scripts/run/run_state.gd`
- Test: `game/tests/unit/test_content_library.gd`
- Test: `game/tests/unit/test_run_models.gd`

- [ ] **Step 1: Write the failing item-metadata expectations**

Extend tests so they assert:

- drink items expose thirst recovery
- medicine items expose health recovery
- stimulants expose fatigue adjustment metadata
- item panels can rely on exact deltas instead of only flavor text

- [ ] **Step 2: Run the relevant tests to verify failure**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_content_library.gd
```

Then:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_run_models.gd
```

Expected: FAIL because thirst/health/fatigue item fields are incomplete or unused.

- [ ] **Step 3: Update item data and consumption handling**

Modify `game/data/items.json` and `game/scripts/run/run_state.gd` to support:

- `허기` recovery
- `갈증` recovery
- `체력` recovery
- `피로` reduction from stimulants
- explicit item-use time costs
- future-friendly metadata for “short description + exact deltas”

Prefer keeping weak stimulants common and stronger stimulants rare.

- [ ] **Step 4: Re-run the tests**

Run the same two commands from Step 2.

Expected:

- `CONTENT_LIBRARY_OK`
- `RUN_MODELS_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/data/items.json \
  game/scripts/run/run_state.gd \
  game/tests/unit/test_content_library.gd \
  game/tests/unit/test_run_models.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add survival item effect metadata"
```

### Task 3: Surface Survival Stages and Exact Item Effects in the UI

**Files:**
- Modify: `game/scenes/run/hud.tscn`
- Modify: `game/scripts/run/hud_presenter.gd`
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Test: `game/tests/unit/test_hud_presenter.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Write the failing UI expectations**

Extend UI tests so they assert:

- both indoor and outdoor HUDs show stage labels for `허기`, `갈증`, `체력`, `피로`
- the indoor item action sheet shows exact stat deltas such as `갈증 +30`
- exact numbers are not promoted to always-visible main HUD labels

- [ ] **Step 2: Run UI tests to verify failure**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_hud_presenter.gd
```

Then:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_mode.gd
```

Expected: FAIL because survival stages and exact item effect strings are not shown yet.

- [ ] **Step 3: Implement first-pass survival UI**

Update HUD and indoor UI so they:

- show readable stage labels for the four survival stats
- keep the main HUD concise
- show exact effect numbers in the item detail/action sheet
- remain compatible with the current Korean-first UI style

- [ ] **Step 4: Re-run the UI tests**

Run the same commands from Step 2.

Expected:

- `HUD_PRESENTATION_OK`
- `INDOOR_MODE_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/scenes/run/hud.tscn \
  game/scripts/run/hud_presenter.gd \
  game/scenes/indoor/indoor_mode.tscn \
  game/scripts/indoor/indoor_mode.gd \
  game/tests/unit/test_hud_presenter.gd \
  game/tests/unit/test_indoor_mode.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: show first-pass survival stats in ui"
```

### Task 4: Add Rest, Sleep Integration, and Fatigue Penalties

**Files:**
- Modify: `game/data/events/indoor/*.json`
- Modify: `game/scripts/indoor/indoor_action_resolver.gd`
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Modify: `game/scripts/run/run_state.gd`
- Test: `game/tests/unit/test_indoor_actions.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Write the failing behavior expectations**

Extend tests so they assert:

- rest is only available in safe indoor zones
- rest lowers fatigue a little and consumes time
- sleep lowers fatigue more strongly while still advancing hunger/thirst more slowly
- high fatigue increases indoor action time
- high fatigue reduces outdoor move speed

- [ ] **Step 2: Run the affected tests to verify failure**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_indoor_actions.gd
```

Then:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/unit/test_outdoor_controller.gd
```

Expected: FAIL because rest/sleep survival integration and fatigue penalties are incomplete.

- [ ] **Step 3: Implement the survival-pressure loop**

Update indoor/outdoor logic so:

- safe zones can offer `휴식`
- sleep still advances hunger/thirst at slower rates
- indoor time costs scale with fatigue
- outdoor move speed scales down with fatigue
- eating and drinking continue to consume time anywhere

- [ ] **Step 4: Re-run targeted and smoke tests**

Run the same two commands from Step 2.

Then:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `INDOOR_ACTIONS_OK`
- `OUTDOOR_CONTROLLER_OK`
- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 5: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  game/data/events/indoor \
  game/scripts/indoor/indoor_action_resolver.gd \
  game/scripts/outdoor/outdoor_controller.gd \
  game/scripts/run/run_state.gd \
  game/tests/unit/test_indoor_actions.gd \
  game/tests/unit/test_outdoor_controller.gd \
  game/tests/smoke/test_first_playable_loop.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: integrate survival pressure into indoor and outdoor play"
```

### Task 5: Run Full Regression and Record the Iteration

**Files:**
- Modify: `docs/worklogs/2026-04-02-outdoor-visual-refresh.md`
- Modify: `docs/handoffs/2026-04-02-outdoor-visual-refresh.md`

- [ ] **Step 1: Run the full regression suite**

Run:

```bash
export XDG_DATA_HOME=/tmp/codex-godot-home
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 \
  --headless \
  --path /home/muhyeon_shin/packages/apocalypse/game \
  -s res://tests/run_all.gd
```

Expected: all current unit and smoke tests pass.

- [ ] **Step 2: Record the survival-stats iteration**

Update the active worklog and handoff files with:

- what survival stats were added
- what first-pass penalties were intentionally included
- what was intentionally deferred
- which systems now depend on the new survival model

- [ ] **Step 3: Commit**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add \
  docs/worklogs/2026-04-02-outdoor-visual-refresh.md \
  docs/handoffs/2026-04-02-outdoor-visual-refresh.md
git -C /home/muhyeon_shin/packages/apocalypse commit -m "docs: record survival stats first-pass implementation"
```
