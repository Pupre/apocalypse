# Outdoor Threat and Cold Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make outdoor play feel like a dangerous cold-weather survival loop by adding animal pursuit, stronger outdoor HUD feedback, and a persistent freezing-screen effect tied to the existing exposure system.

**Architecture:** Keep outdoor traversal continuous and player-centered. Add one focused outdoor threat controller for pursuit logic, extend `RunState` with outdoor-contact penalties and readable cold-stage helpers, and reframe the existing outdoor scene/HUD around immediate danger feedback instead of static prototype labels. Preserve indoor transitions, crafting, codex, and the current survival resource model.

**Tech Stack:** Godot 4.4.1, GDScript, TSCN scenes, existing `OutdoorController` / `RunState` / `HUD`, headless Godot tests

---

## File Map

### Create

- `game/scripts/outdoor/outdoor_threat_director.gd`
- `game/tests/unit/test_outdoor_threat_director.gd`

### Modify

- `game/scripts/run/run_state.gd`
- `game/scripts/outdoor/outdoor_controller.gd`
- `game/scripts/run/hud_presenter.gd`
- `game/scenes/outdoor/outdoor_mode.tscn`
- `game/scenes/run/hud.tscn`
- `game/tests/unit/test_outdoor_controller.gd`
- `game/tests/unit/test_hud_presenter.gd`
- `game/tests/smoke/test_first_playable_loop.gd`

### Responsibilities

- `game/scripts/outdoor/outdoor_threat_director.gd`
  - Own outdoor animal threat state, sight checks, chase state, and contact detection.
- `game/scripts/run/run_state.gd`
  - Expose readable cold-state helpers and apply contact penalties through the existing survival resources.
- `game/scripts/outdoor/outdoor_controller.gd`
  - Feed player/world data into the threat director, update outdoor ribbons, and drive the freezing overlay.
- `game/scripts/run/hud_presenter.gd`
  - Surface body-temperature status in the shared outdoor HUD ribbon.
- `game/scenes/outdoor/outdoor_mode.tscn`
  - Add threat visuals, threat-state labels, and a full-screen frost overlay layer.
- tests
  - Lock detection/chase/contact behavior, cold UI copy, and the smoke-loop contract before and after the refactor.

### Implementation Note

- The user explicitly prefers one final commit instead of per-task micro-commits. Implement the plan task-by-task, verify each task, and defer Git commit until the full pass is complete.

---

### Task 1: Lock The Outdoor Threat Contract In Tests

**Files:**
- Create: `game/tests/unit/test_outdoor_threat_director.gd`
- Modify: `game/tests/unit/test_outdoor_controller.gd`
- Modify: `game/tests/unit/test_hud_presenter.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/unit/test_outdoor_threat_director.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`
- Test: `game/tests/unit/test_hud_presenter.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Add a focused unit test for sight, chase persistence, and contact**

Create `game/tests/unit/test_outdoor_threat_director.gd` with one self-contained fake loop:

```gdscript
extends "res://tests/support/test_case.gd"

const THREAT_DIRECTOR_SCRIPT := "res://scripts/outdoor/outdoor_threat_director.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var threat_director = load(THREAT_DIRECTOR_SCRIPT).new()
	if not assert_true(threat_director != null, "Threat director should instantiate."):
		return

	threat_director.configure([
		{
			"id": "pack_01",
			"position": Vector2(320, 340),
			"forward": Vector2.RIGHT,
		},
	])

	var calm: Dictionary = threat_director.tick(Vector2(80, 340), 0.5)
	assert_eq(String(calm.get("threat_state", "")), "idle", "A threat should stay idle when the player is outside sight and proximity.")

	var spotted: Dictionary = threat_director.tick(Vector2(380, 340), 0.5)
	assert_eq(String(spotted.get("threat_state", "")), "chasing", "A threat should switch to chasing when the player enters sight.")

	var lingering: Dictionary = threat_director.tick(Vector2(260, 340), 0.5)
	assert_eq(String(lingering.get("threat_state", "")), "chasing", "Chase state should persist briefly even after line-of-sight breaks.")

	var contact: Dictionary = threat_director.tick(Vector2(322, 340), 0.25)
	assert_true(bool(contact.get("contact", false)), "A threat should report contact when it reaches the player.")

	pass_test("OUTDOOR_THREAT_DIRECTOR_OK")
```

- [ ] **Step 2: Extend `test_outdoor_controller.gd` to lock the new outdoor UI and contact wiring**

Add assertions after the existing ribbon/camera checks in `game/tests/unit/test_outdoor_controller.gd`:

```gdscript
	var threat_label := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ThreatLabel") as Label
	var frost_overlay := outdoor_mode.get_node_or_null("CanvasLayer/FrostOverlay") as ColorRect
	if not assert_true(threat_label != null, "Outdoor mode should expose a threat label in the top ribbon."):
		outdoor_mode.free()
		return
	if not assert_true(frost_overlay != null, "Outdoor mode should expose a full-screen frost overlay."):
		outdoor_mode.free()
		return
	assert_true(frost_overlay.color.a <= 0.05, "Healthy outdoor exposure should start with almost no frost overlay.")

	run_state.exposure = 18.0
	outdoor_mode.refresh_view()
	assert_true(threat_label.text.length() > 0, "Outdoor top ribbon should always show a readable threat-state line.")
	assert_true(frost_overlay.color.a >= 0.35, "Low exposure should visibly intensify the frost overlay.")
```

Then force a contact event through a test-only controller entrypoint:

```gdscript
	var before_contact_exposure := run_state.exposure
	var before_contact_fatigue := run_state.fatigue
	assert_true(outdoor_mode.has_method("debug_force_threat_contact"), "Outdoor mode should expose a narrow debug_force_threat_contact() hook for deterministic threat tests.")
	outdoor_mode.debug_force_threat_contact()
	assert_true(run_state.exposure < before_contact_exposure, "Threat contact should reduce exposure.")
	assert_true(run_state.fatigue > before_contact_fatigue, "Threat contact should increase fatigue.")
```

- [ ] **Step 3: Extend `test_hud_presenter.gd` to require a body-temperature label in outdoor mode**

In `game/tests/unit/test_hud_presenter.gd`, add a new label lookup and assertions:

```gdscript
	var temperature_label := hud.get_node_or_null("TopRibbon/Margin/Stack/StatsRow/TemperatureLabel") as Label
	if not assert_true(temperature_label != null, "HUD should expose a body-temperature label in outdoor mode."):
		hud.free()
		return
```

Then assert stage copy after setting the run state:

```gdscript
	run_state.exposure = 22.0
	hud.refresh()
	assert_eq(temperature_label.text, "체온: 위험", "Outdoor HUD should translate low exposure into a readable body-temperature warning.")
```

- [ ] **Step 4: Extend the smoke loop so outdoor boot proves the new loop is mounted**

In `game/tests/smoke/test_first_playable_loop.gd`, add assertions right after the existing outdoor ribbon check:

```gdscript
	var threat_label := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ThreatLabel") as Label
	var frost_overlay := outdoor_mode.get_node_or_null("CanvasLayer/FrostOverlay") as ColorRect
	if not assert_true(threat_label != null, "Outdoor mode should expose a threat label in smoke coverage."):
		bootstrap.free()
		return
	if not assert_true(frost_overlay != null, "Outdoor mode should mount a frost overlay in smoke coverage."):
		bootstrap.free()
		return
	assert_true(threat_label.text.length() > 0, "Outdoor mode should show a readable threat line at boot.")
```

- [ ] **Step 5: Run the focused tests to verify they fail for the expected missing features**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-outdoor-threat-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_threat_director.gd
XDG_DATA_HOME=/tmp/apocalypse-outdoor-threat-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/apocalypse-outdoor-threat-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_hud_presenter.gd
XDG_DATA_HOME=/tmp/apocalypse-outdoor-threat-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- the new threat-director test fails because the script does not exist
- the outdoor-controller test fails because the threat label, frost overlay, and debug contact hook do not exist
- the HUD test fails because `TemperatureLabel` does not exist
- the smoke test fails because the outdoor scene does not mount the new threat UI

---

### Task 2: Add The Threat Director And Contact Penalties

**Files:**
- Create: `game/scripts/outdoor/outdoor_threat_director.gd`
- Modify: `game/scripts/run/run_state.gd`
- Test: `game/tests/unit/test_outdoor_threat_director.gd`

- [ ] **Step 1: Create `outdoor_threat_director.gd` as one focused pursuit-state module**

Create `game/scripts/outdoor/outdoor_threat_director.gd` with a minimal API that the controller can call every frame:

```gdscript
extends RefCounted
class_name OutdoorThreatDirector

const DEFAULT_SIGHT_DISTANCE := 220.0
const DEFAULT_PROXIMITY_DISTANCE := 72.0
const DEFAULT_CHASE_MEMORY_SECONDS := 3.5
const DEFAULT_MOVE_SPEED := 96.0
const DEFAULT_CONTACT_DISTANCE := 20.0

var _threats: Array[Dictionary] = []


func configure(threat_rows: Array[Dictionary]) -> void:
	_threats = []
	for row in threat_rows:
		_threats.append({
			"id": String(row.get("id", "")),
			"position": row.get("position", Vector2.ZERO),
			"forward": (row.get("forward", Vector2.RIGHT) as Vector2).normalized(),
			"state": "idle",
			"memory_seconds": 0.0,
		})


func tick(player_position: Vector2, delta: float) -> Dictionary:
	var any_chasing := false
	var made_contact := false
	for threat in _threats:
		var offset: Vector2 = player_position - (threat.get("position", Vector2.ZERO) as Vector2)
		var distance := offset.length()
		var sees_player := _is_in_sight(threat, offset) or distance <= DEFAULT_PROXIMITY_DISTANCE
		if sees_player:
			threat["state"] = "chasing"
			threat["memory_seconds"] = DEFAULT_CHASE_MEMORY_SECONDS
		elif String(threat.get("state", "")) == "chasing":
			var memory_left := max(0.0, float(threat.get("memory_seconds", 0.0)) - delta)
			threat["memory_seconds"] = memory_left
			if memory_left <= 0.0:
				threat["state"] = "idle"
		if String(threat.get("state", "")) == "chasing":
			any_chasing = true
			var next_position := (threat.get("position", Vector2.ZERO) as Vector2) + offset.normalized() * DEFAULT_MOVE_SPEED * delta
			threat["position"] = next_position
			if next_position.distance_to(player_position) <= DEFAULT_CONTACT_DISTANCE:
				made_contact = true
	return {
		"threat_state": "chasing" if any_chasing else "idle",
		"contact": made_contact,
		"threats": _threats.duplicate(true),
	}


func _is_in_sight(threat: Dictionary, offset: Vector2) -> bool:
	if offset.length() > DEFAULT_SIGHT_DISTANCE:
		return false
	var forward: Vector2 = (threat.get("forward", Vector2.RIGHT) as Vector2).normalized()
	var direction := offset.normalized()
	return forward.dot(direction) >= 0.25
```

- [ ] **Step 2: Add readable cold-stage helpers and an outdoor-contact penalty entrypoint to `RunState`**

In `game/scripts/run/run_state.gd`, add two helpers close to the other readable stage helpers:

```gdscript
func get_temperature_stage() -> String:
	if exposure <= 15.0:
		return "위독"
	if exposure <= 30.0:
		return "위험"
	if exposure <= 55.0:
		return "한기"
	if exposure <= 80.0:
		return "서늘"
	return "안정"


func apply_outdoor_threat_contact() -> Dictionary:
	exposure = max(0.0, exposure - 18.0)
	fatigue = min(MAX_SURVIVAL_VALUE, fatigue + 8.0)
	clock.advance_minutes(3)
	return {
		"exposure": exposure,
		"fatigue": fatigue,
		"minute_of_day": clock.minute_of_day,
	}
```

Keep this intentionally narrow. The first pass only needs a stable penalty contract, not a generic combat system.

- [ ] **Step 3: Run the new threat-director and model tests until they pass**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-outdoor-threat-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_threat_director.gd
XDG_DATA_HOME=/tmp/apocalypse-outdoor-threat-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_models.gd
```

Expected:

- `OUTDOOR_THREAT_DIRECTOR_OK`
- `RUN_MODELS_OK`

---

### Task 3: Reframe Outdoor Presentation Around Threat And Cold

**Files:**
- Modify: `game/scenes/outdoor/outdoor_mode.tscn`
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Modify: `game/scenes/run/hud.tscn`
- Modify: `game/scripts/run/hud_presenter.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`
- Test: `game/tests/unit/test_hud_presenter.gd`

- [ ] **Step 1: Expand the outdoor scene with threat visuals and a frost overlay**

Update `game/scenes/outdoor/outdoor_mode.tscn` to add:

```tscn
[node name="Threats" type="Node2D" parent="."]

[node name="WolfPack01" type="Polygon2D" parent="Threats"]
position = Vector2(360, 328)
polygon = PackedVector2Array(0, -14, 14, -2, 10, 12, -10, 12, -14, -2)
color = Color(0.73, 0.76, 0.8, 0.95)
z_index = 18

[node name="FrostOverlay" type="ColorRect" parent="CanvasLayer"]
anchor_left = 0.0
anchor_top = 0.0
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
color = Color(0.78, 0.88, 1.0, 0.0)

[node name="ThreatLabel" type="Label" parent="CanvasLayer/TopRibbon/Margin/VBox"]
autowrap_mode = 3
text = "주변이 불안하다"
```

Keep `ThreatLabel` between `HintLabel` and `ToolsRow` so the panel still reads like a shallow ribbon.

- [ ] **Step 2: Wire the threat director, contact events, and frost strength into `OutdoorController`**

At the top of `game/scripts/outdoor/outdoor_controller.gd`, add the preload and cache members:

```gdscript
const OUTDOOR_THREAT_DIRECTOR_SCRIPT := preload("res://scripts/outdoor/outdoor_threat_director.gd")

var threat_director = OUTDOOR_THREAT_DIRECTOR_SCRIPT.new()
var _threat_host: Node2D = null
var _frost_overlay: ColorRect = null
var _threat_label: Label = null
var _debug_contact_requested := false
```

Then cache the new nodes in `_cache_nodes()`:

```gdscript
	_threat_host = get_node_or_null("Threats") as Node2D
	_frost_overlay = get_node_or_null("CanvasLayer/FrostOverlay") as ColorRect
	_threat_label = get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ThreatLabel") as Label
```

Configure the single first-pass pack in `_ready()` / `bind_run_state(...)`:

```gdscript
	threat_director.configure([
		{
			"id": "pack_01",
			"position": Vector2(360.0, 328.0),
			"forward": Vector2.RIGHT,
		},
	])
```

Update `_process(delta)` to tick threats after movement:

```gdscript
	var threat_snapshot: Dictionary = threat_director.tick(_player_position, delta)
	if _debug_contact_requested:
		threat_snapshot["contact"] = true
		_debug_contact_requested = false
	if bool(threat_snapshot.get("contact", false)) and run_state != null:
		run_state.apply_outdoor_threat_contact()
	_sync_threat_view(threat_snapshot)
```

Add the narrow test hook:

```gdscript
func debug_force_threat_contact() -> void:
	_debug_contact_requested = true
	_process(0.01)
```

Implement `_sync_threat_view(...)` and frost intensity:

```gdscript
func _sync_threat_view(snapshot: Dictionary) -> void:
	var threat_state := String(snapshot.get("threat_state", "idle"))
	if _threat_label != null:
		_threat_label.text = "추적 중" if threat_state == "chasing" else "주변이 불안하다"
	if _frost_overlay != null and run_state != null:
		var frost_alpha := clamp((100.0 - run_state.exposure) / 120.0, 0.0, 0.7)
		_frost_overlay.color = Color(0.78, 0.88, 1.0, frost_alpha)
```

- [ ] **Step 3: Surface body-temperature status in the shared HUD**

Add one label to `game/scenes/run/hud.tscn` inside `StatsRow`:

```tscn
[node name="TemperatureLabel" type="Label" parent="TopRibbon/Margin/Stack/StatsRow"]
text = "체온: --"
```

Cache and refresh it in `game/scripts/run/hud_presenter.gd`:

```gdscript
var _temperature_label: Label
```

```gdscript
	_temperature_label = get_node_or_null("TopRibbon/Margin/Stack/StatsRow/TemperatureLabel") as Label
```

```gdscript
	if _temperature_label != null:
		_temperature_label.text = "체온: %s" % run_state.get_temperature_stage()
```

```gdscript
	if _temperature_label != null:
		_temperature_label.text = "체온: --"
```

- [ ] **Step 4: Run the focused outdoor UI tests until they pass**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-outdoor-threat-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/apocalypse-outdoor-threat-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_hud_presenter.gd
```

Expected:

- `OUTDOOR_CONTROLLER_OK`
- `HUD_PRESENTATION_OK`

---

### Task 4: Re-run The Real Loop And Check For Regressions

**Files:**
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/unit/test_run_controller_live_transition.gd`
- Test: `game/tests/unit/test_shared_crafting_sheet.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Keep smoke coverage focused on “outdoor still boots, pressures, and transitions”**

Do not broaden the smoke test into AI micro-behavior. Keep the added assertions limited to mounted UI and preserved transitions:

```gdscript
	assert_true(threat_label.text.length() > 0, "Outdoor mode should mount a readable threat-state line.")
	assert_true(frost_overlay.color.a >= 0.0, "Outdoor mode should mount the frost overlay even before exposure drops.")
```

This keeps the smoke loop stable while the fine-grained behavior stays in unit tests.

- [ ] **Step 2: Run the transition and shared-crafting regressions**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-outdoor-threat-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
XDG_DATA_HOME=/tmp/apocalypse-outdoor-threat-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_shared_crafting_sheet.gd
```

Expected:

- `RUN_CONTROLLER_LIVE_TRANSITION_OK`
- `SHARED_CRAFTING_SHEET_OK`

- [ ] **Step 3: Run the full first-playable smoke test and verify the outdoor pass did not break the main loop**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-outdoor-threat-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 4: Manual gameplay spot-check**

Run:

```bash
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --path /home/muhyeon_shin/packages/apocalypse/game
```

Manual checks:

- outdoor top ribbon now reads like danger/status UI instead of a prototype label block
- at least one visible animal threat is present
- low exposure noticeably thickens the frost overlay
- threat contact visibly disrupts the run state
- building entry still immediately escapes back into the indoor loop

---

## Self-Review

### Spec coverage

- animal pursuit loop: Task 2 and Task 3
- outdoor HUD/game-feel shift: Task 1 and Task 3
- persistent freezing-screen effect: Task 1 and Task 3
- no new HP system, only survival-resource penalties: Task 2
- keep indoor/crafting/transition baseline intact: Task 4

No spec gaps remain.

### Placeholder scan

- No `TODO`, `TBD`, or “implement later” placeholders remain.
- Each code-changing task includes concrete file paths, code snippets, and exact commands.

### Type consistency

- `RunState.get_temperature_stage()` is the single readable temperature helper used by the HUD.
- `RunState.apply_outdoor_threat_contact()` is the single outdoor-contact penalty entrypoint.
- `OutdoorThreatDirector.tick(...)` is the single per-frame threat update call expected by `OutdoorController`.

The plan uses one consistent set of names across tasks.
