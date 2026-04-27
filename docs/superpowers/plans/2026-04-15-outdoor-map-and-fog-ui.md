# Outdoor Map And Fog UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a player-following outdoor minimap plus a full-screen visited-only city map overlay, with unvisited territory hidden behind black fog and the world paused while the full map is open.

**Architecture:** Split the two map surfaces by role instead of forcing one visual language everywhere. Keep `OutdoorMapView` for the full-screen block-grid strategy map, add a separate local world-space minimap renderer for real-time outdoor awareness, and let `OutdoorController` supply both the fixed-city block state and the nearby world snapshot. The full-screen overlay must render above the HUD and pause outdoor input/time until dismissed.

**Tech Stack:** Godot 4.4.1, GDScript, TSCN scenes, existing `OutdoorController` / `OutdoorWorldRuntime` / `RunState`, headless Godot tests

---

## File Map

### Create

- `game/scripts/outdoor/outdoor_local_minimap_view.gd`

### Modify

- `game/scripts/outdoor/outdoor_map_view.gd`
- `game/scripts/outdoor/outdoor_minimap.gd`
- `game/scripts/outdoor/outdoor_map_overlay.gd`
- `game/scenes/outdoor/outdoor_minimap.tscn`
- `game/scenes/outdoor/outdoor_map_overlay.tscn`
- `game/scenes/outdoor/outdoor_mode.tscn`
- `game/scripts/outdoor/outdoor_controller.gd`
- `game/tests/unit/test_outdoor_map_view.gd`
- `game/tests/unit/test_outdoor_controller.gd`
- `game/tests/smoke/test_first_playable_loop.gd`
- `docs/INDEX.md`
- `docs/CURRENT_STATE.md`

### Responsibilities

- `game/scripts/outdoor/outdoor_local_minimap_view.gd`
  - Render the nearby outdoor world in player-centered local space with north fixed.
  - Draw roads/ground bands, nearby entrances, obstacles, and threat markers.
- `game/scripts/outdoor/outdoor_map_view.gd`
  - Render the full-screen block-grid strategy map using visited-block fog-of-war.
- `game/scripts/outdoor/outdoor_minimap.gd`
  - Own the upper-right minimap panel and feed local world snapshot data into the local renderer.
- `game/scripts/outdoor/outdoor_map_overlay.gd`
  - Own the full-screen strategy map, close button, and open/close state.
- `game/scripts/outdoor/outdoor_controller.gd`
  - Build the local minimap snapshot, drive the full-screen map from `RunState` visited blocks, and pause outdoor input/time when the overlay is open.
- tests
  - Lock the distinction between local minimap behavior and full-screen fog-of-war behavior, then verify the overlay is clickable and blocks outdoor simulation while open.

### Implementation Note

- The user explicitly prefers one final commit instead of per-task micro-commits. Implement task-by-task, verify each task, and defer Git commit until the full pass is complete.

---

### Task 1: Rewrite The Tests Around The Correct Map Contract

**Files:**
- Modify: `game/tests/unit/test_outdoor_map_view.gd`
- Modify: `game/tests/unit/test_outdoor_controller.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/unit/test_outdoor_map_view.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Rewrite `test_outdoor_map_view.gd` so it only tests the full-screen block map**

Replace the current test body in `game/tests/unit/test_outdoor_map_view.gd` with this contract:

```gdscript
extends "res://tests/support/test_case.gd"

const MAP_VIEW_SCRIPT := "res://scripts/outdoor/outdoor_map_view.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var map_view_script := load(MAP_VIEW_SCRIPT)
	if not assert_true(map_view_script != null, "OutdoorMapView script should load."):
		return

	var map_view = map_view_script.new()
	if not assert_true(map_view != null, "OutdoorMapView should instantiate."):
		return

	map_view.configure(
		{
			"city_blocks": {"width": 4, "height": 4},
			"block_size": {"width": 1920, "height": 1920},
		},
		{"0_0": true, "1_0": true, "1_1": true},
		Vector2i(1, 1),
		Vector2i(1, 1)
	)

	var snapshot: Dictionary = map_view.build_snapshot()
	assert_eq(_state_for(snapshot, "1_1"), "current", "Current block should be highlighted distinctly.")
	assert_eq(_state_for(snapshot, "1_0"), "visited", "Visited non-current blocks should stay visible.")
	assert_eq(_state_for(snapshot, "2_2"), "hidden", "Unvisited blocks should stay blacked out.")
	assert_true((snapshot.get("blocks", []) as Array).size() >= 16, "Full map should still cover the authored city grid.")

	map_view.free()
	pass_test("OUTDOOR_MAP_VIEW_OK")


func _state_for(snapshot: Dictionary, block_key: String) -> String:
	for row_variant in snapshot.get("blocks", []):
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row := row_variant as Dictionary
		if String(row.get("key", "")) == block_key:
			return String(row.get("state", ""))
	return ""
```

- [ ] **Step 2: Extend `test_outdoor_controller.gd` to require a real local minimap and a pausing overlay**

In `game/tests/unit/test_outdoor_controller.gd`, keep the existing minimap/overlay presence assertions but add these checks:

```gdscript
	var minimap_view := outdoor_mode.get_node_or_null("CanvasLayer/Minimap/Margin/MapView") as Control
	var overlay_close := outdoor_mode.get_node_or_null("CanvasLayer/MapOverlay/Panel/VBox/Header/CloseButton") as Button
	if not assert_true(minimap_view != null, "Outdoor minimap should mount a local map renderer."):
		outdoor_mode.free()
		return
	if not assert_true(overlay_close != null, "Outdoor map overlay should expose a close button above the HUD."):
		outdoor_mode.free()
		return
```

Then add a simulation-pause contract:

```gdscript
	outdoor_mode.show_map_overlay()
	var minute_before_pause := run_state.clock.minute_of_day
	outdoor_mode.simulate_seconds(60.0)
	assert_eq(run_state.clock.minute_of_day, minute_before_pause, "Outdoor simulation should pause while the full map overlay is open.")
	outdoor_mode.hide_map_overlay()
	outdoor_mode.simulate_seconds(60.0)
	assert_true(run_state.clock.minute_of_day > minute_before_pause, "Outdoor simulation should resume after the full map closes.")
```

- [ ] **Step 3: Extend the smoke loop to require the same pause/open/close path**

In `game/tests/smoke/test_first_playable_loop.gd`, keep the open/close assertions and add:

```gdscript
	var minute_before_map := run_state.clock.minute_of_day
	outdoor_mode.show_map_overlay()
	outdoor_mode.simulate_seconds(60.0)
	assert_eq(run_state.clock.minute_of_day, minute_before_map, "Smoke coverage should prove the full-screen map pauses outdoor simulation.")
	outdoor_mode.hide_map_overlay()
	outdoor_mode.simulate_seconds(60.0)
	assert_true(run_state.clock.minute_of_day > minute_before_map, "Smoke coverage should prove outdoor simulation resumes after the map closes.")
```

- [ ] **Step 4: Run the focused tests and confirm the current implementation now fails for the right reasons**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-map-ui-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_map_view.gd
XDG_DATA_HOME=/tmp/apocalypse-map-ui-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/apocalypse-map-ui-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `test_outdoor_map_view.gd` may still pass because it targets the full-screen map contract only
- `test_outdoor_controller.gd` should fail because the current minimap is still using the wrong block-grid presentation and the overlay does not pause simulation
- the smoke test should fail for the same pause/resume reason

---

### Task 2: Replace The Outdoor Minimap With A Local World Renderer

**Files:**
- Create: `game/scripts/outdoor/outdoor_local_minimap_view.gd`
- Modify: `game/scripts/outdoor/outdoor_minimap.gd`
- Modify: `game/scenes/outdoor/outdoor_minimap.tscn`
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`

- [ ] **Step 1: Create `outdoor_local_minimap_view.gd` as a player-centered local renderer**

Create `game/scripts/outdoor/outdoor_local_minimap_view.gd`:

```gdscript
extends Control
class_name OutdoorLocalMinimapView

const ROAD_COLOR := Color(0.30, 0.34, 0.39, 0.92)
const ENTRANCE_COLOR := Color(0.92, 0.88, 0.64, 1.0)
const OBSTACLE_COLOR := Color(0.43, 0.47, 0.53, 0.94)
const THREAT_COLOR := Color(0.87, 0.48, 0.48, 1.0)
const PLAYER_COLOR := Color(0.95, 0.84, 0.42, 1.0)
const LOCAL_RADIUS := 420.0

var _player_position := Vector2.ZERO
var _roads: Array[Dictionary] = []
var _entrances: Array[Dictionary] = []
var _obstacles: Array[Dictionary] = []
var _threats: Array[Dictionary] = []


func configure(player_position: Vector2, roads: Array[Dictionary], entrances: Array[Dictionary], obstacles: Array[Dictionary], threats: Array[Dictionary]) -> void:
	_player_position = player_position
	_roads = roads.duplicate(true)
	_entrances = entrances.duplicate(true)
	_obstacles = obstacles.duplicate(true)
	_threats = threats.duplicate(true)
	queue_redraw()
```

- [ ] **Step 2: Add the actual minimap draw loop**

Extend `game/scripts/outdoor/outdoor_local_minimap_view.gd` with:

```gdscript
func _draw() -> void:
	var center := size * 0.5
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.09, 0.90), true)

	for road_row in _roads:
		var rect_row := road_row.get("rect", {}) as Dictionary
		var local_rect := _to_local_rect(Rect2(
			float(rect_row.get("x", 0.0)),
			float(rect_row.get("y", 0.0)),
			float(rect_row.get("width", 0.0)),
			float(rect_row.get("height", 0.0))
		))
		draw_rect(local_rect, ROAD_COLOR, true)

	for obstacle_row in _obstacles:
		var rect_row := obstacle_row.get("rect", {}) as Dictionary
		var local_rect := _to_local_rect(Rect2(
			float(rect_row.get("x", 0.0)),
			float(rect_row.get("y", 0.0)),
			float(rect_row.get("width", 0.0)),
			float(rect_row.get("height", 0.0))
		))
		draw_rect(local_rect, OBSTACLE_COLOR, true)

	for entrance_row in _entrances:
		draw_circle(_to_local_point(entrance_row.get("position", Vector2.ZERO) as Vector2), 4.0, ENTRANCE_COLOR)

	for threat_row in _threats:
		draw_circle(_to_local_point(threat_row.get("position", Vector2.ZERO) as Vector2), 4.0, THREAT_COLOR)

	draw_circle(center, 5.0, PLAYER_COLOR)


func _to_local_point(world_point: Vector2) -> Vector2:
	var offset := world_point - _player_position
	var scale := (size.x * 0.5) / LOCAL_RADIUS
	return (size * 0.5) + Vector2(offset.x * scale, offset.y * scale)


func _to_local_rect(world_rect: Rect2) -> Rect2:
	var top_left := _to_local_point(world_rect.position)
	var bottom_right := _to_local_point(world_rect.end)
	return Rect2(top_left, bottom_right - top_left)
```

- [ ] **Step 3: Replace the minimap scene to use the local renderer**

In `game/scenes/outdoor/outdoor_minimap.tscn`, change `Margin/MapView` to use `res://scripts/outdoor/outdoor_local_minimap_view.gd` instead of `outdoor_map_view.gd`.

Keep the same panel placement and size.

- [ ] **Step 4: Update `OutdoorMinimap` so it accepts local world snapshot data instead of block-grid data**

Replace `configure(...)` in `game/scripts/outdoor/outdoor_minimap.gd` with:

```gdscript
func configure(player_position: Vector2, roads: Array[Dictionary], entrances: Array[Dictionary], obstacles: Array[Dictionary], threats: Array[Dictionary]) -> void:
	if _map_view == null:
		return
	_map_view.configure(player_position, roads, entrances, obstacles, threats)
```

- [ ] **Step 5: Build a local minimap snapshot in `OutdoorController`**

Add this helper to `game/scripts/outdoor/outdoor_controller.gd`:

```gdscript
func _build_minimap_snapshot() -> Dictionary:
	var entrances: Array[Dictionary] = []
	for building_data in _building_rows:
		entrances.append({
			"id": String(building_data.get("id", "")),
			"position": _resolve_building_position(building_data),
		})
	var threats: Array[Dictionary] = []
	for threat_variant in _last_threat_snapshot.get("threats", []):
		if typeof(threat_variant) != TYPE_DICTIONARY:
			continue
		threats.append(threat_variant as Dictionary)
	return {
		"player_position": _player_position,
		"roads": _road_rows,
		"entrances": entrances,
		"obstacles": _obstacle_rows,
		"threats": threats,
	}
```

Then in `_sync_view()` replace the old minimap call with:

```gdscript
	var minimap_snapshot := _build_minimap_snapshot()
	if _minimap != null:
		_minimap.configure(
			minimap_snapshot.get("player_position", Vector2.ZERO) as Vector2,
			minimap_snapshot.get("roads", []) as Array,
			minimap_snapshot.get("entrances", []) as Array,
			minimap_snapshot.get("obstacles", []) as Array,
			minimap_snapshot.get("threats", []) as Array
		)
```

- [ ] **Step 6: Run the controller test and verify the minimap path now uses the local renderer**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-map-ui-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
```

Expected:

- `OUTDOOR_CONTROLLER_OK` for the minimap presence path

---

### Task 3: Keep The Full-Screen Map Strategic And Make It Pause The World

**Files:**
- Modify: `game/scripts/outdoor/outdoor_map_view.gd`
- Modify: `game/scripts/outdoor/outdoor_map_overlay.gd`
- Modify: `game/scenes/outdoor/outdoor_map_overlay.tscn`
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Test: `game/tests/unit/test_outdoor_map_view.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Simplify `OutdoorMapView` so it is full-map only**

Remove the minimap window logic from `game/scripts/outdoor/outdoor_map_view.gd`.

Use this shape for the snapshot:

```gdscript
func build_snapshot() -> Dictionary:
	var city_blocks := _world_layout.get("city_blocks", {}) as Dictionary
	var width := int(city_blocks.get("width", 0))
	var height := int(city_blocks.get("height", 0))
	var rows: Array = []
	for y in range(height):
		for x in range(width):
			var block_coord := Vector2i(x, y)
			rows.append({
				"key": "%d_%d" % [x, y],
				"coord": block_coord,
				"state": _block_state(block_coord),
			})
	return {
		"blocks": rows,
	}
```

Keep the existing current/visited/hidden state handling and full-grid drawing.

- [ ] **Step 2: Put the overlay above the shared HUD**

In `game/scenes/outdoor/outdoor_mode.tscn`, move `MapOverlay` out of the same HUD layer competition and ensure it renders last under the outdoor `CanvasLayer`.

The practical rule is:

- `FrostOverlay`
- `TopRibbon`
- `Minimap`
- `MapOverlay`

and `MapOverlay` must fill the screen, absorb input, and keep its close button clickable.

- [ ] **Step 3: Pause outdoor simulation while the overlay is open**

In `game/scripts/outdoor/outdoor_controller.gd`, change `_process(delta)` so the pause gate is at the top and stops all outdoor simulation:

```gdscript
func _process(delta: float) -> void:
	if run_state == null:
		return

	if is_map_overlay_open():
		if Input.is_action_just_pressed("ui_cancel"):
			hide_map_overlay()
		_sync_view()
		state_changed.emit()
		return
```

Then add the same guard to `simulate_seconds(seconds_elapsed)`:

```gdscript
func simulate_seconds(seconds_elapsed: float) -> void:
	if is_map_overlay_open():
		return
	if run_state == null or seconds_elapsed <= 0.0:
		return
```

This makes test-driven pause behavior explicit instead of only relying on `_process`.

- [ ] **Step 4: Keep the full-screen overlay fed by visited blocks only**

In `_sync_view()` keep the overlay path separate from the minimap path:

```gdscript
	var visited_block_ids := {}
	if run_state != null and run_state.has_method("get_visited_outdoor_block_keys"):
		for block_key in run_state.get_visited_outdoor_block_keys():
			visited_block_ids[String(block_key)] = true
	if _map_overlay != null:
		_map_overlay.configure(world_runtime.world_layout, visited_block_ids, _current_block_coord)
```

Do not feed roads, obstacles, or nearby entrances into the full-screen map in this pass.

- [ ] **Step 5: Run the full focused verification set**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-map-ui-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_map_view.gd
XDG_DATA_HOME=/tmp/apocalypse-map-ui-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/apocalypse-map-ui-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `OUTDOOR_MAP_VIEW_OK`
- `OUTDOOR_CONTROLLER_OK`
- `FIRST_PLAYABLE_LOOP_OK`

---

### Task 4: Keep Routing Docs Honest

**Files:**
- Modify: `docs/INDEX.md`
- Modify: `docs/CURRENT_STATE.md`

- [ ] **Step 1: Ensure routing still points at the revised map spec and plan**

Verify these entries still exist and are still current:

- `docs/INDEX.md`
  - `Outdoor Map And Fog UI Design`
  - `Outdoor Map And Fog UI`
- `docs/CURRENT_STATE.md`
  - current active spec list includes the revised outdoor map spec
  - immediate priorities still mention the outdoor minimap/full-screen map pass

- [ ] **Step 2: Do not add any extra narrative docs in this task**

This task is only for routing accuracy, not for writing additional handoff or worklog material.
