# Outdoor 2x2 Block Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand outdoor traversal from the current prototype street into a continuous `2x2` district with more buildings, more meaningful travel distance, and a data-driven outdoor layout model.

**Architecture:** Introduce one dedicated outdoor layout data file that owns world bounds, block geometry, obstacle placement, threat anchors, and building anchors. Keep building identity in `buildings.json`, but move outdoor placement to anchor ids so `OutdoorController` renders the district from data instead of relying on hardcoded scene geometry and loose `outdoor_position` points.

**Tech Stack:** Godot 4.4.1, GDScript, JSON content files, existing Godot headless test suite

---

## File Structure

### New Files

- `game/data/outdoor_layout.json`
  - Owns the `2x2` outdoor district layout, world bounds, player spawn, block bands, obstacle rects, threat spawns, and building anchors.
- `game/data/events/indoor/convenience_01.json`
  - Indoor event shell for the convenience store.
- `game/data/events/indoor/hardware_01.json`
  - Indoor event shell for the hardware store.
- `game/data/events/indoor/gas_station_01.json`
  - Indoor event shell for the gas station.
- `game/data/events/indoor/laundry_01.json`
  - Indoor event shell for the laundry.

### Modified Files

- `game/data/buildings.json`
  - Add new buildings and replace direct outdoor-point ownership with outdoor anchor ids.
- `game/scripts/autoload/content_library.gd`
  - Load and expose outdoor layout data alongside buildings/items/crafting.
- `game/scripts/outdoor/outdoor_controller.gd`
  - Render ground bands, obstacles, threat spawns, and building markers from outdoor layout data.
- `game/scenes/outdoor/outdoor_mode.tscn`
  - Reduce to reusable hosts and presentation layers only.
- `game/tests/unit/test_outdoor_controller.gd`
  - Lock the wider district, anchor-based placement, and longer travel contract.
- `game/tests/smoke/test_first_playable_loop.gd`
  - Keep smoke coverage aligned with the expanded district.
- `docs/INDEX.md`
  - Add this plan to the active plan list.
- `docs/CURRENT_STATE.md`
  - Update near-term priorities after the plan is active.

### Optional Test Coverage

- `game/tests/unit/test_content_library.gd`
  - Add direct assertions for `outdoor_layout.json` loading if the current content-library test is already the repository’s data-loader contract.

## Task 1: Lock The Outdoor 2x2 Contract In Tests

**Files:**
- Modify: `game/tests/unit/test_outdoor_controller.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Optional Modify: `game/tests/unit/test_content_library.gd`

- [ ] **Step 1: Extend `test_outdoor_controller.gd` to require the larger district**

Add assertions after the existing ground/building host checks so the test requires a materially larger district and more than four buildings:

```gdscript
	assert_true(building_markers.get_child_count() >= 8, "Outdoor mode should render at least eight building markers in the 2x2 district.")

	var world_rect := outdoor_mode.get_world_bounds()
	assert_true(world_rect.size.x >= 2200.0, "Outdoor world width should expand well past the original prototype block.")
	assert_true(world_rect.size.y >= 1800.0, "Outdoor world height should expand into a 2x2 district footprint.")
```

- [ ] **Step 2: Extend `test_outdoor_controller.gd` to require long-distance travel**

Add a travel-distance contract that proves the player can stay in one outdoor scene while moving much farther than the old block allowed:

```gdscript
	var start_position := outdoor_mode.get_player_position()
	outdoor_mode.move_player(Vector2.RIGHT, 6.0)
	outdoor_mode.move_player(Vector2.DOWN, 5.0)
	var traveled_distance := start_position.distance_to(outdoor_mode.get_player_position())
	assert_true(traveled_distance >= 700.0, "Outdoor travel should now support substantially longer continuous movement.")
```

- [ ] **Step 3: Extend `test_outdoor_controller.gd` to require new building ids**

Require the mixed building set to exist and remain enterable by id:

```gdscript
	var expected_buildings := ["mart_01", "apartment_01", "clinic_01", "office_01", "convenience_01", "hardware_01", "gas_station_01", "laundry_01"]
	for building_id in expected_buildings:
		assert_true(content_library.get_building(building_id).size() > 0, "Building '%s' should exist in the expanded district." % building_id)
```

- [ ] **Step 4: Extend the smoke test so the district is not still the old prototype**

In `game/tests/smoke/test_first_playable_loop.gd`, add a simple check after outdoor boot:

```gdscript
	if not assert_true(outdoor_mode.has_method("get_world_bounds"), "Outdoor mode should expose get_world_bounds() for smoke verification."):
		bootstrap.free()
		return
	var world_rect := outdoor_mode.get_world_bounds()
	assert_true(world_rect.size.x >= 2200.0, "Smoke coverage should prove the expanded outdoor district is mounted.")
```

- [ ] **Step 5: Run the focused outdoor tests and confirm they fail first**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-outdoor-2x2-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/apocalypse-outdoor-2x2-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `test_outdoor_controller.gd` fails because building count, world size, and long-travel helpers do not yet match the 2x2 contract.
- `test_first_playable_loop.gd` fails because `get_world_bounds()` does not yet prove the new district.

## Task 2: Add Outdoor Layout Data And ContentLibrary Loading

**Files:**
- Create: `game/data/outdoor_layout.json`
- Modify: `game/data/buildings.json`
- Modify: `game/scripts/autoload/content_library.gd`
- Optional Modify: `game/tests/unit/test_content_library.gd`

- [ ] **Step 1: Create `outdoor_layout.json` with one explicit 2x2 district**

Create the new layout file with stable world bounds, spawn, anchors, roads, and obstacle rectangles:

```json
{
  "world_bounds": { "x": 0, "y": 0, "width": 2400, "height": 1960 },
  "player_spawn": { "x": 240, "y": 360 },
  "building_anchors": {
    "mart_anchor": { "x": 640, "y": 360 },
    "apartment_anchor": { "x": 900, "y": 240 },
    "clinic_anchor": { "x": 980, "y": 520 },
    "office_anchor": { "x": 360, "y": 180 },
    "convenience_anchor": { "x": 1560, "y": 310 },
    "hardware_anchor": { "x": 1780, "y": 620 },
    "gas_station_anchor": { "x": 520, "y": 1320 },
    "laundry_anchor": { "x": 1540, "y": 1380 }
  },
  "roads": [
    { "id": "main_horizontal", "rect": { "x": 0, "y": 300, "width": 2400, "height": 460 } },
    { "id": "cross_vertical", "rect": { "x": 1120, "y": 0, "width": 360, "height": 1960 } },
    { "id": "south_service_lane", "rect": { "x": 240, "y": 1180, "width": 1640, "height": 260 } }
  ],
  "obstacles": [
    { "kind": "vehicle", "rect": { "x": 462, "y": 438, "width": 48, "height": 48 } },
    { "kind": "vehicle", "rect": { "x": 758, "y": 446, "width": 48, "height": 48 } },
    { "kind": "vehicle", "rect": { "x": 1330, "y": 402, "width": 58, "height": 58 } },
    { "kind": "rubble", "rect": { "x": 1620, "y": 1260, "width": 120, "height": 90 } }
  ],
  "threat_spawns": [
    { "id": "pack_01", "position": { "x": 360, "y": 328 }, "forward": { "x": 1, "y": 0 } },
    { "id": "pack_02", "position": { "x": 1640, "y": 1320 }, "forward": { "x": -1, "y": 0 } }
  ]
}
```

- [ ] **Step 2: Extend `buildings.json` so outdoor placement uses anchor ids**

Replace direct point ownership with anchor references and add the four new buildings:

```json
{
  "id": "mart_01",
  "name": "동네 마트",
  "category": "retail",
  "base_candidate": true,
  "outdoor_anchor_id": "mart_anchor",
  "indoor_event_path": "res://data/events/indoor/mart_01.json"
}
```

```json
{
  "id": "hardware_01",
  "name": "철물점",
  "category": "retail",
  "base_candidate": false,
  "outdoor_anchor_id": "hardware_anchor",
  "indoor_event_path": "res://data/events/indoor/hardware_01.json"
}
```

- [ ] **Step 3: Load and expose the outdoor layout from `ContentLibrary`**

Add layout state and accessors:

```gdscript
var outdoor_layout: Dictionary = {}

func load_all() -> void:
	jobs = _load_indexed_array("res://data/jobs.json")
	traits = _load_indexed_array("res://data/traits.json")
	buildings = _load_indexed_array("res://data/buildings.json")
	items = _load_items("res://data/items.json")
	crafting_combinations = _load_crafting_combinations("res://data/crafting_combinations.json")
	outdoor_layout = _load_dictionary("res://data/outdoor_layout.json")

func get_outdoor_layout() -> Dictionary:
	return outdoor_layout.duplicate(true)
```

- [ ] **Step 4: Add a small dictionary loader helper if needed**

If `ContentLibrary` has no generic top-level-object loader, add one:

```gdscript
func _load_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("%s: could not open content file." % path)
		return {}
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		push_error("%s: invalid JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("%s: expected a top-level object." % path)
		return {}
	return (json.data as Dictionary).duplicate(true)
```

- [ ] **Step 5: Run content-level tests**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-outdoor-2x2-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
```

Expected:

- PASS after `ContentLibrary` can read the new layout file and the updated building rows.

## Task 3: Refactor OutdoorController Around Layout Data

**Files:**
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Modify: `game/scenes/outdoor/outdoor_mode.tscn`
- Modify: `game/tests/unit/test_outdoor_controller.gd`

- [ ] **Step 1: Replace hardcoded world constants with layout-driven state**

Remove direct ownership of the old prototype world constants and add layout-backed state:

```gdscript
var _world_bounds := Rect2(0.0, 0.0, 1200.0, 1092.0)
var _road_rows: Array[Dictionary] = []
var _obstacle_rows: Array[Dictionary] = []
var _building_anchor_rows: Dictionary = {}

func get_world_bounds() -> Rect2:
	return _world_bounds
```

- [ ] **Step 2: Add one layout-binding path**

When binding a run, pull layout data from `ContentLibrary` and cache the district model:

```gdscript
func _load_outdoor_layout() -> void:
	var layout := ContentLibrary.get_outdoor_layout()
	var world_bounds_row := layout.get("world_bounds", {})
	_world_bounds = Rect2(
		float(world_bounds_row.get("x", 0.0)),
		float(world_bounds_row.get("y", 0.0)),
		float(world_bounds_row.get("width", 1200.0)),
		float(world_bounds_row.get("height", 1092.0))
	)
	_road_rows = (layout.get("roads", []) as Array).duplicate(true)
	_obstacle_rows = (layout.get("obstacles", []) as Array).duplicate(true)
	_building_anchor_rows = (layout.get("building_anchors", {}) as Dictionary).duplicate(true)
```

- [ ] **Step 3: Resolve building positions from `outdoor_anchor_id`**

Replace `_resolve_building_position` so it no longer reads `outdoor_position` directly:

```gdscript
func _resolve_building_position(building_data: Dictionary) -> Vector2:
	var anchor_id := String(building_data.get("outdoor_anchor_id", ""))
	var anchor_row_variant: Variant = _building_anchor_rows.get(anchor_id, {})
	if typeof(anchor_row_variant) != TYPE_DICTIONARY:
		return DEFAULT_PLAYER_POSITION
	var anchor_row := anchor_row_variant as Dictionary
	return Vector2(
		float(anchor_row.get("x", DEFAULT_PLAYER_POSITION.x)),
		float(anchor_row.get("y", DEFAULT_PLAYER_POSITION.y))
	)
```

- [ ] **Step 4: Generate outdoor geometry from data**

Refactor `_refresh_obstacles()` and add one `_refresh_ground()` path so the scene stops carrying most of the world geometry:

```gdscript
func _refresh_ground() -> void:
	if _ground_host == null:
		return
	for child in _ground_host.get_children():
		child.queue_free()
	for road_row_variant in _road_rows:
		if typeof(road_row_variant) != TYPE_DICTIONARY:
			continue
		var road_row := road_row_variant as Dictionary
		var rect_row := road_row.get("rect", {}) as Dictionary
		var band := Polygon2D.new()
		band.polygon = PackedVector2Array(
			Vector2(float(rect_row.get("x", 0.0)), float(rect_row.get("y", 0.0))),
			Vector2(float(rect_row.get("x", 0.0)) + float(rect_row.get("width", 0.0)), float(rect_row.get("y", 0.0))),
			Vector2(float(rect_row.get("x", 0.0)) + float(rect_row.get("width", 0.0)), float(rect_row.get("y", 0.0)) + float(rect_row.get("height", 0.0))),
			Vector2(float(rect_row.get("x", 0.0)), float(rect_row.get("y", 0.0)) + float(rect_row.get("height", 0.0)))
		)
		band.color = Color(0.22, 0.23, 0.24, 1.0)
		_ground_host.add_child(band)
```

- [ ] **Step 5: Make movement constraints use the layout bounds and data obstacle rects**

Update the movement clamp path to use `_world_bounds` and runtime obstacle rects:

```gdscript
func _constrain_player_position(target_position: Vector2) -> Vector2:
	var clamped := Vector2(
		clampf(target_position.x, _world_bounds.position.x + 24.0, _world_bounds.end.x - 24.0),
		clampf(target_position.y, _world_bounds.position.y + 24.0, _world_bounds.end.y - 24.0)
	)
	for obstacle_row_variant in _obstacle_rows:
		if typeof(obstacle_row_variant) != TYPE_DICTIONARY:
			continue
		var obstacle_row := obstacle_row_variant as Dictionary
		var rect_row := obstacle_row.get("rect", {}) as Dictionary
		var obstacle_rect := Rect2(
			float(rect_row.get("x", 0.0)),
			float(rect_row.get("y", 0.0)),
			float(rect_row.get("width", 0.0)),
			float(rect_row.get("height", 0.0))
		)
		if obstacle_rect.has_point(clamped):
			return _player_position
	return clamped
```

- [ ] **Step 6: Re-run the focused outdoor controller test**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-outdoor-2x2-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
```

Expected:

- PASS with the expanded building count, world bounds, and long-distance travel contract.

## Task 4: Add The New Mixed Building Set And Indoor Event Shells

**Files:**
- Create: `game/data/events/indoor/convenience_01.json`
- Create: `game/data/events/indoor/hardware_01.json`
- Create: `game/data/events/indoor/gas_station_01.json`
- Create: `game/data/events/indoor/laundry_01.json`
- Modify: `game/data/buildings.json`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Create four minimal indoor event files that follow the existing pattern**

Each file should be a valid indoor event shell with a small zone graph and searchable nodes. Example:

```json
{
  "id": "convenience_01",
  "name": "편의점",
  "zones": [
    { "id": "entrance", "name": "입구", "neighbors": ["aisle"] },
    { "id": "aisle", "name": "진열대", "neighbors": ["entrance", "counter"] },
    { "id": "counter", "name": "계산대", "neighbors": ["aisle"] }
  ],
  "start_zone_id": "entrance",
  "search_nodes": [
    { "id": "shelf_01", "zone_id": "aisle", "label": "진열대" },
    { "id": "counter_01", "zone_id": "counter", "label": "카운터" }
  ]
}
```

- [ ] **Step 2: Add the four building rows in `buildings.json`**

Add rows that point to those new event files and new outdoor anchors:

```json
{
  "id": "laundry_01",
  "name": "코인 세탁소",
  "category": "retail",
  "base_candidate": false,
  "outdoor_anchor_id": "laundry_anchor",
  "indoor_event_path": "res://data/events/indoor/laundry_01.json"
}
```

- [ ] **Step 3: Keep smoke coverage aligned with the new building list**

In `test_first_playable_loop.gd`, add one small content-library assertion after the outdoor boot checks:

```gdscript
	for building_id in ["convenience_01", "hardware_01", "gas_station_01", "laundry_01"]:
		assert_true(content_library.get_building(building_id).size() > 0, "Smoke coverage should prove '%s' is mounted in the expanded district." % building_id)
```

- [ ] **Step 4: Run smoke and indoor transition coverage**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-outdoor-2x2-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
XDG_DATA_HOME=/tmp/apocalypse-outdoor-2x2-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
```

Expected:

- PASS with the larger district still booting and indoor transitions still functioning.

## Task 5: Final Regression And Doc Synchronization

**Files:**
- Modify: `docs/INDEX.md`
- Modify: `docs/CURRENT_STATE.md`

- [ ] **Step 1: Add this plan to the active plan list**

Update `docs/INDEX.md` under `## Active Plans` so the newest plan is listed first:

```md
- [Outdoor 2x2 Block Expansion](superpowers/plans/2026-04-15-outdoor-2x2-block-expansion.md)
```

- [ ] **Step 2: Update `CURRENT_STATE.md` to reflect the new top outdoor priority**

Add the plan to the near-term plan stack and keep the immediate-priority wording aligned:

```md
- [Outdoor 2x2 Block Expansion](superpowers/plans/2026-04-15-outdoor-2x2-block-expansion.md)
```

```md
- Expand the outdoor world into a continuous 2x2 district so long-distance travel and building choice become materially meaningful.
```

- [ ] **Step 3: Run the full verification set**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-outdoor-2x2-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
XDG_DATA_HOME=/tmp/apocalypse-outdoor-2x2-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/apocalypse-outdoor-2x2-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
XDG_DATA_HOME=/tmp/apocalypse-outdoor-2x2-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- All four commands exit `0`.
- The district loads as one continuous outdoor space with more buildings and larger movement range.

- [ ] **Step 4: Commit**

```bash
git add docs/INDEX.md docs/CURRENT_STATE.md docs/superpowers/plans/2026-04-15-outdoor-2x2-block-expansion.md game/data/outdoor_layout.json game/data/buildings.json game/data/events/indoor/convenience_01.json game/data/events/indoor/hardware_01.json game/data/events/indoor/gas_station_01.json game/data/events/indoor/laundry_01.json game/scripts/autoload/content_library.gd game/scripts/outdoor/outdoor_controller.gd game/scenes/outdoor/outdoor_mode.tscn game/tests/unit/test_outdoor_controller.gd game/tests/unit/test_content_library.gd game/tests/unit/test_run_controller_live_transition.gd game/tests/smoke/test_first_playable_loop.gd
git commit -m "feat: expand outdoor world into a 2x2 district"
```

## Notes For The Implementer

- Do not leave outdoor world geometry split between scene-authored prototype shapes and layout-driven data if it can be avoided.
- Keep `OutdoorController` as the place where layout data becomes runtime nodes.
- Do not invent new combat systems in this pass.
- If one of the new indoor events needs to stay minimal, keep it minimal, but it must still be a valid indoor destination.
