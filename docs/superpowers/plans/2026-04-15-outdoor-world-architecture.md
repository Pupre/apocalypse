# Outdoor World Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **User workflow note:** Do not create micro-commits during this plan. The user prefers one verified commit after the full pass is working.

**Goal:** Replace the temporary outdoor district scaffolding with a fixed-city block-grid runtime that can scale toward a large continuous city, while migrating the current slice into the new architecture and increasing the first authored district to a spatially readable `2x2` slice with at least `16` buildings.

**Architecture:** Introduce one generic outdoor world schema with a global `world_layout.json`, per-block JSON files, and a dedicated `OutdoorWorldRuntime` that owns block coordinates, `3x3` streaming, anchor resolution, and visited-block tracking. `OutdoorController` becomes a thin presenter over that runtime, while `RunState` owns per-run visited-map knowledge so the world stays globally open but locally hidden.

**Tech Stack:** Godot 4.4.1, GDScript, JSON content files, existing headless Godot test suite

---

## File Structure

### New Files

- `game/data/outdoor/world_layout.json`
  - Global outdoor metadata: fixed block size, authored city dimensions, spawn block, spawn local position, and baseline streaming assumptions.
- `game/data/outdoor/blocks/0_0.json`
  - First authored northwest block: road geometry, snow fields, anchors, obstacles, threat spawns, landmarks.
- `game/data/outdoor/blocks/1_0.json`
  - First authored northeast block.
- `game/data/outdoor/blocks/0_1.json`
  - First authored southwest block.
- `game/data/outdoor/blocks/1_1.json`
  - First authored southeast block.
- `game/scripts/outdoor/outdoor_world_runtime.gd`
  - Pure runtime layer for block-coordinate math, `3x3` active window selection, block loading, anchor lookup, and visited-block marking.
- `game/tests/unit/test_outdoor_world_runtime.gd`
  - Contract tests for block coordinates, active block selection, anchor resolution, and visited-map behavior.
- `game/data/events/indoor/pharmacy_01.json`
  - Minimal indoor shell for a new medical destination in the first authored slice.
- `game/data/events/indoor/restaurant_01.json`
  - Minimal indoor shell for a food-service destination.
- `game/data/events/indoor/bakery_01.json`
  - Minimal indoor shell for another civilian destination.
- `game/data/events/indoor/warehouse_01.json`
  - Minimal indoor shell for a logistics/storage destination.
- `game/data/events/indoor/cafe_01.json`
  - Minimal indoor shell for a small seating/loot destination.
- `game/data/events/indoor/police_box_01.json`
  - Minimal indoor shell for an authority/security destination.
- `game/data/events/indoor/repair_shop_01.json`
  - Minimal indoor shell for a tool/mechanical destination.
- `game/data/events/indoor/residence_01.json`
  - Minimal indoor shell for another residential destination.

### Modified Files

- `game/data/buildings.json`
  - Replace temporary raw outdoor points with `outdoor_block_coord` plus `outdoor_anchor_id`, add the first authored `2x2` slice building set, and keep indoor linkage canonical.
- `game/scripts/autoload/content_library.gd`
  - Load `world_layout.json`, indexed block data, and expose generic outdoor-world accessors.
- `game/scripts/run/run_state.gd`
  - Store per-run visited outdoor blocks and expose helper methods for map knowledge.
- `game/scripts/outdoor/outdoor_controller.gd`
  - Stop owning ad hoc district data; consume `OutdoorWorldRuntime` for block loading, player block transitions, building marker resolution, and world bounds.
- `game/scenes/outdoor/outdoor_mode.tscn`
  - Keep only camera, player, HUD, frost overlay, and streamed-world hosts; remove assumptions tied to one static district scene.
- `game/tests/unit/test_content_library.gd`
  - Lock the outdoor world data contract.
- `game/tests/unit/test_run_models.gd`
  - Lock run-state visited-block behavior.
- `game/tests/unit/test_outdoor_controller.gd`
  - Lock controller integration against the new runtime and the denser first authored slice.
- `game/tests/smoke/test_first_playable_loop.gd`
  - Keep outdoor-to-indoor smoke flow valid after the runtime swap.
- `docs/INDEX.md`
  - Route readers to this plan as the active implementation path.
- `docs/CURRENT_STATE.md`
  - Reflect that the old `2x2 district` plan is superseded by the fixed-city block runtime plan.

## Task 1: Lock The New Outdoor World Contracts In Tests

**Files:**
- Create: `game/tests/unit/test_outdoor_world_runtime.gd`
- Modify: `game/tests/unit/test_content_library.gd`
- Modify: `game/tests/unit/test_run_models.gd`
- Modify: `game/tests/unit/test_outdoor_controller.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Add a new runtime-level test file for block math and `3x3` activation**

Create `game/tests/unit/test_outdoor_world_runtime.gd` with a pure runtime contract:

```gdscript
extends "res://tests/support/test_case.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var runtime_script: Script = load("res://scripts/outdoor/outdoor_world_runtime.gd")
	if not assert_true(runtime_script != null, "OutdoorWorldRuntime script should exist."):
		return

	var runtime = runtime_script.new()
	runtime.configure({
		"block_size": {"width": 960, "height": 960},
		"city_blocks": {"width": 8, "height": 8},
		"spawn_block_coord": {"x": 0, "y": 0},
		"spawn_local_position": {"x": 320, "y": 420}
	}, {
		"0_0": {"anchors": {"mart_anchor": {"x": 640, "y": 360}}},
		"1_0": {"anchors": {"clinic_anchor": {"x": 120, "y": 440}}},
		"0_1": {"anchors": {"gas_station_anchor": {"x": 200, "y": 300}}},
		"1_1": {"anchors": {"laundry_anchor": {"x": 440, "y": 220}}}
	})

	assert_eq(runtime.world_to_block_coord(Vector2(120.0, 840.0)), Vector2i(0, 0), "World coordinates should resolve into fixed block coordinates.")
	assert_eq(runtime.world_to_block_coord(Vector2(1040.0, 120.0)), Vector2i(1, 0), "Crossing one block width should advance the block X coordinate.")
	assert_eq(runtime.world_to_block_coord(Vector2(1040.0, 1160.0)), Vector2i(1, 1), "Crossing width and height should resolve into the southeast block.")

	var active_blocks: Array[Vector2i] = runtime.get_active_block_coords(Vector2i(4, 4))
	assert_eq(active_blocks.size(), 9, "A centered runtime should keep a 3x3 active window.")
	assert_true(active_blocks.has(Vector2i(3, 3)), "The active window should include the northwest neighbor.")
	assert_true(active_blocks.has(Vector2i(4, 4)), "The active window should include the current block.")
	assert_true(active_blocks.has(Vector2i(5, 5)), "The active window should include the southeast neighbor.")

	assert_eq(runtime.resolve_anchor_world_position(Vector2i(1, 0), "clinic_anchor"), Vector2(1080.0, 440.0), "Anchor resolution should add local anchor coordinates to block origins.")

	print("OUTDOOR_WORLD_RUNTIME_OK")
	get_tree().quit()
```

- [ ] **Step 2: Extend `test_content_library.gd` so the old one-file `outdoor_layout.json` is no longer the contract**

Replace the current outdoor layout assertions with world-layout and block-file assertions:

```gdscript
	var world_layout: Dictionary = content_library.get_outdoor_world_layout()
	assert_true(not world_layout.is_empty(), "Outdoor world layout should load into the content library.")
	assert_eq(int((world_layout.get("block_size", {}) as Dictionary).get("width", 0)), 960, "Outdoor world layout should expose a fixed block width.")
	assert_eq(int((world_layout.get("city_blocks", {}) as Dictionary).get("width", 0)), 8, "Outdoor world layout should expose authored city width in blocks.")

	var block_0_0: Dictionary = content_library.get_outdoor_block(Vector2i(0, 0))
	var block_1_1: Dictionary = content_library.get_outdoor_block(Vector2i(1, 1))
	assert_true(not block_0_0.is_empty(), "Outdoor block (0,0) should load.")
	assert_true(not block_1_1.is_empty(), "Outdoor block (1,1) should load.")
	assert_true(typeof(block_0_0.get("building_anchors", {})) == TYPE_DICTIONARY, "Outdoor blocks should expose building anchors.")
	assert_true((block_1_1.get("building_anchors", {}) as Dictionary).size() >= 4, "The first authored southeast block should already contain several building anchors.")
```

- [ ] **Step 3: Extend `test_run_models.gd` to require per-run visited-block tracking**

Add run-state assertions after the existing codex and difficulty checks:

```gdscript
	assert_true(state.has_method("mark_outdoor_block_visited"), "RunState should expose outdoor visited-block helpers.")
	assert_true(state.has_method("is_outdoor_block_visited"), "RunState should expose outdoor visited-block lookup.")
	assert_true(state.has_method("get_visited_outdoor_block_keys"), "RunState should expose a visited-block snapshot.")
	assert_true(state.get_visited_outdoor_block_keys().is_empty(), "Fresh runs should start with no revealed outdoor blocks.")

	state.mark_outdoor_block_visited(Vector2i(0, 0))
	state.mark_outdoor_block_visited(Vector2i(1, 0))
	assert_true(state.is_outdoor_block_visited(Vector2i(0, 0)), "Visited outdoor blocks should remain known for the current run.")
	assert_true(state.is_outdoor_block_visited(Vector2i(1, 0)), "Multiple visited outdoor blocks should accumulate.")
	assert_eq(state.get_visited_outdoor_block_keys().size(), 2, "Visited-block tracking should deduplicate repeated visits.")
```

- [ ] **Step 4: Extend `test_outdoor_controller.gd` so the controller must prove block-based scale rather than one wide prototype lane**

Replace the current `2x2 district` assertions with a stricter first-slice contract:

```gdscript
	assert_true(building_markers.get_child_count() >= 16, "The first authored outdoor slice should expose at least sixteen building markers.")

	var world_rect: Rect2 = outdoor_mode.get_world_bounds()
	assert_true(world_rect.size.x >= 7680.0, "Outdoor world width should reflect the larger fixed-city authoring grid, not just a one-off district rectangle.")
	assert_true(world_rect.size.y >= 7680.0, "Outdoor world height should reflect the larger fixed-city authoring grid.")

	var start_position: Vector2 = outdoor_mode.get_player_position()
	outdoor_mode.move_player(Vector2.RIGHT, 8.0)
	outdoor_mode.move_player(Vector2.DOWN, 8.0)
	var traveled_distance: float = start_position.distance_to(outdoor_mode.get_player_position())
	assert_true(traveled_distance >= 1400.0, "Outdoor travel should support materially longer continuous movement inside the streamed city grid.")
```

- [ ] **Step 5: Extend the smoke test to require a block-backed outdoor runtime**

Add a smoke assertion after outdoor boot:

```gdscript
	if not assert_true(outdoor_mode.has_method("get_active_block_coords"), "Outdoor mode should expose active block coordinates for smoke verification."):
		bootstrap.free()
		return
	var active_blocks: Array = outdoor_mode.get_active_block_coords()
	assert_eq(active_blocks.size(), 9, "Outdoor smoke coverage should boot a 3x3 streamed block window.")
```

- [ ] **Step 6: Run the focused tests and confirm they fail first**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_world_runtime.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_models.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- runtime test fails because `OutdoorWorldRuntime` does not exist
- content-library test fails because `world_layout.json` and block files are not yet loaded
- run-model test fails because `RunState` does not yet track visited outdoor blocks
- controller and smoke tests fail because the controller still uses the temporary one-file district scaffolding

## Task 2: Introduce The Outdoor World Data Model

**Files:**
- Create: `game/data/outdoor/world_layout.json`
- Create: `game/data/outdoor/blocks/0_0.json`
- Create: `game/data/outdoor/blocks/1_0.json`
- Create: `game/data/outdoor/blocks/0_1.json`
- Create: `game/data/outdoor/blocks/1_1.json`
- Modify: `game/data/buildings.json`
- Modify: `game/scripts/autoload/content_library.gd`
- Modify: `game/tests/unit/test_content_library.gd`

- [ ] **Step 1: Create `world_layout.json` with fixed block-size city metadata**

Create the new global layout file:

```json
{
  "block_size": { "width": 960, "height": 960 },
  "city_blocks": { "width": 8, "height": 8 },
  "spawn_block_coord": { "x": 0, "y": 0 },
  "spawn_local_position": { "x": 240, "y": 360 },
  "stream_radius_blocks": 1,
  "block_path_pattern": "res://data/outdoor/blocks/%d_%d.json"
}
```

- [ ] **Step 2: Author the first four block files as a real `2x2` slice inside the larger city grid**

Use one file per block. Example `game/data/outdoor/blocks/0_0.json`:

```json
{
  "block_coord": { "x": 0, "y": 0 },
  "roads": [
    { "id": "north_south", "rect": { "x": 360, "y": 0, "width": 240, "height": 960 } },
    { "id": "east_west", "rect": { "x": 0, "y": 320, "width": 960, "height": 280 } }
  ],
  "snow_fields": [
    { "id": "northwest_snow", "rect": { "x": 0, "y": 0, "width": 320, "height": 300 } }
  ],
  "obstacles": [
    { "kind": "vehicle", "rect": { "x": 180, "y": 430, "width": 52, "height": 52 } },
    { "kind": "rubble", "rect": { "x": 710, "y": 180, "width": 120, "height": 80 } }
  ],
  "building_anchors": {
    "office_anchor": { "x": 180, "y": 180 },
    "mart_anchor": { "x": 720, "y": 240 },
    "cafe_anchor": { "x": 740, "y": 650 },
    "pharmacy_anchor": { "x": 200, "y": 700 }
  },
  "threat_spawns": [
    { "id": "pack_00_a", "position": { "x": 120, "y": 120 }, "forward": { "x": 1, "y": 0 } }
  ],
  "landmarks": [
    { "id": "main_crossing", "label": "교차로", "position": { "x": 480, "y": 460 } }
  ]
}
```

Mirror that schema for `1_0.json`, `0_1.json`, and `1_1.json`, with the first authored slice totaling at least four anchors per block so the slice reaches at least sixteen buildings.

- [ ] **Step 3: Convert `buildings.json` to block-anchor placement**

Replace raw outdoor positions with `outdoor_block_coord` and `outdoor_anchor_id`:

```json
{
  "id": "mart_01",
  "name": "동네 마트",
  "category": "retail",
  "base_candidate": true,
  "outdoor_block_coord": { "x": 0, "y": 0 },
  "outdoor_anchor_id": "mart_anchor",
  "indoor_event_path": "res://data/events/indoor/mart_01.json"
}
```

Add the new first-slice buildings:

```json
{
  "id": "pharmacy_01",
  "name": "약국",
  "category": "medical",
  "base_candidate": false,
  "outdoor_block_coord": { "x": 0, "y": 0 },
  "outdoor_anchor_id": "pharmacy_anchor",
  "indoor_event_path": "res://data/events/indoor/pharmacy_01.json"
}
```

```json
{
  "id": "warehouse_01",
  "name": "창고",
  "category": "industrial",
  "base_candidate": false,
  "outdoor_block_coord": { "x": 1, "y": 1 },
  "outdoor_anchor_id": "warehouse_anchor",
  "indoor_event_path": "res://data/events/indoor/warehouse_01.json"
}
```

- [ ] **Step 4: Load the new world-layout and per-block content in `ContentLibrary`**

Add outdoor-world fields and helpers:

```gdscript
var outdoor_world_layout: Dictionary = {}
var outdoor_blocks: Dictionary = {}

func load_all() -> void:
	jobs = _load_indexed_array("res://data/jobs.json")
	traits = _load_indexed_array("res://data/traits.json")
	buildings = _load_indexed_array("res://data/buildings.json")
	outdoor_world_layout = _load_dictionary("res://data/outdoor/world_layout.json")
	outdoor_blocks = _load_outdoor_blocks("res://data/outdoor/blocks")
	items = _load_items("res://data/items.json")
	crafting_combinations = _load_crafting_combinations("res://data/crafting_combinations.json")

func get_outdoor_world_layout() -> Dictionary:
	return outdoor_world_layout.duplicate(true)

func get_outdoor_block(block_coord: Vector2i) -> Dictionary:
	return (outdoor_blocks.get(_outdoor_block_key(block_coord), {}) as Dictionary).duplicate(true)
```

- [ ] **Step 5: Add a small helper that indexes block JSON files by `<x>_<y>`**

Add an explicit loader:

```gdscript
func _load_outdoor_blocks(path: String) -> Dictionary:
	var indexed: Dictionary = {}
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("%s: could not open outdoor blocks directory." % path)
		return indexed

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var row := _load_dictionary("%s/%s" % [path, file_name])
			var block_coord := row.get("block_coord", {})
			var block_key := "%d_%d" % [int((block_coord as Dictionary).get("x", 0)), int((block_coord as Dictionary).get("y", 0))]
			indexed[block_key] = row
		file_name = dir.get_next()
	dir.list_dir_end()
	return indexed
```

- [ ] **Step 6: Run the content test and make it pass**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
```

Expected:

- `CONTENT_LIBRARY_OK`

## Task 3: Add RunState Map Knowledge And The Outdoor Runtime

**Files:**
- Create: `game/scripts/outdoor/outdoor_world_runtime.gd`
- Create: `game/tests/unit/test_outdoor_world_runtime.gd`
- Modify: `game/scripts/run/run_state.gd`
- Modify: `game/tests/unit/test_run_models.gd`

- [ ] **Step 1: Add per-run visited outdoor block state to `RunState`**

Add storage and helpers:

```gdscript
var visited_outdoor_block_ids: Dictionary = {}

func mark_outdoor_block_visited(block_coord: Vector2i) -> void:
	visited_outdoor_block_ids[_outdoor_block_key(block_coord)] = true

func is_outdoor_block_visited(block_coord: Vector2i) -> bool:
	return bool(visited_outdoor_block_ids.get(_outdoor_block_key(block_coord), false))

func get_visited_outdoor_block_keys() -> Array[String]:
	var keys: Array[String] = []
	for key_variant in visited_outdoor_block_ids.keys():
		keys.append(String(key_variant))
	keys.sort()
	return keys

func _outdoor_block_key(block_coord: Vector2i) -> String:
	return "%d_%d" % [block_coord.x, block_coord.y]
```

Reset this dictionary in `_apply_survivor_config()` alongside `known_recipe_ids` and `read_knowledge_item_ids`.

- [ ] **Step 2: Create `OutdoorWorldRuntime` with fixed block-size coordinate math**

Create `game/scripts/outdoor/outdoor_world_runtime.gd`:

```gdscript
extends RefCounted
class_name OutdoorWorldRuntime

var world_layout: Dictionary = {}
var outdoor_blocks: Dictionary = {}

func configure(layout: Dictionary, block_rows: Dictionary) -> void:
	world_layout = layout.duplicate(true)
	outdoor_blocks = block_rows.duplicate(true)

func get_block_size() -> Vector2i:
	var block_size := world_layout.get("block_size", {}) as Dictionary
	return Vector2i(int(block_size.get("width", 0)), int(block_size.get("height", 0)))

func world_to_block_coord(world_position: Vector2) -> Vector2i:
	var block_size := get_block_size()
	return Vector2i(
		int(floor(world_position.x / float(block_size.x))),
		int(floor(world_position.y / float(block_size.y)))
	)

func get_active_block_coords(center_block: Vector2i) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for y in range(center_block.y - 1, center_block.y + 2):
		for x in range(center_block.x - 1, center_block.x + 2):
			coords.append(Vector2i(x, y))
	return coords
```

- [ ] **Step 3: Add runtime helpers for block lookup and anchor resolution**

Extend the runtime:

```gdscript
func get_block_row(block_coord: Vector2i) -> Dictionary:
	return (outdoor_blocks.get(_block_key(block_coord), {}) as Dictionary).duplicate(true)

func resolve_anchor_world_position(block_coord: Vector2i, anchor_id: String) -> Vector2:
	var block_row := get_block_row(block_coord)
	var anchors := block_row.get("building_anchors", {}) as Dictionary
	var local_anchor := anchors.get(anchor_id, {}) as Dictionary
	var block_origin := get_block_origin(block_coord)
	return block_origin + Vector2(float(local_anchor.get("x", 0.0)), float(local_anchor.get("y", 0.0)))

func get_block_origin(block_coord: Vector2i) -> Vector2:
	var block_size := get_block_size()
	return Vector2(float(block_coord.x * block_size.x), float(block_coord.y * block_size.y))

func _block_key(block_coord: Vector2i) -> String:
	return "%d_%d" % [block_coord.x, block_coord.y]
```

- [ ] **Step 4: Make the new runtime and run-state tests pass**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_world_runtime.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_models.gd
```

Expected:

- `OUTDOOR_WORLD_RUNTIME_OK`
- `RUN_MODELS_OK`

## Task 4: Refactor OutdoorController To The Block Runtime

**Files:**
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Modify: `game/scenes/outdoor/outdoor_mode.tscn`
- Modify: `game/tests/unit/test_outdoor_controller.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Replace one-off district state with the new runtime and streamed hosts**

In `OutdoorController`, replace the temporary layout fields:

```gdscript
const OUTDOOR_WORLD_RUNTIME_SCRIPT := preload("res://scripts/outdoor/outdoor_world_runtime.gd")

var world_runtime = OUTDOOR_WORLD_RUNTIME_SCRIPT.new()
var _current_block_coord := Vector2i.ZERO
var _active_block_coords: Array[Vector2i] = []
var _active_block_nodes: Dictionary = {}
var _world_root: Node2D = null
```

Add a public smoke/helper accessor:

```gdscript
func get_active_block_coords() -> Array[Vector2i]:
	return _active_block_coords.duplicate()
```

- [ ] **Step 2: Load world layout and block rows from `ContentLibrary`**

Replace `_load_outdoor_layout()` with a runtime-backed variant:

```gdscript
func _load_outdoor_world() -> void:
	var content_library = get_node_or_null("/root/ContentLibrary")
	if content_library == null:
		return

	var layout := content_library.get_outdoor_world_layout()
	var block_rows: Dictionary = {}
	for block_coord in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		block_rows[_outdoor_block_key(block_coord)] = content_library.get_outdoor_block(block_coord)
	world_runtime.configure(layout, block_rows)

	var block_size := world_runtime.get_block_size()
	var city_blocks := layout.get("city_blocks", {}) as Dictionary
	_world_bounds = Rect2(
		0.0,
		0.0,
		float(block_size.x * int(city_blocks.get("width", 0))),
		float(block_size.y * int(city_blocks.get("height", 0)))
	)
```

- [ ] **Step 3: Stream the player’s current `3x3` window and mark visited blocks**

When player position changes, recompute block state:

```gdscript
func _sync_block_window() -> void:
	_current_block_coord = world_runtime.world_to_block_coord(_player_position)
	_active_block_coords = world_runtime.get_active_block_coords(_current_block_coord)
	if run_state != null:
		run_state.mark_outdoor_block_visited(_current_block_coord)
	_refresh_streamed_world()
```

Call `_sync_block_window()` from `bind_run_state()`, `move_player()`, and `_process()` after movement.

- [ ] **Step 4: Generate roads, obstacles, threats, and buildings per active block**

Replace single-host generation with per-block generation:

```gdscript
func _refresh_streamed_world() -> void:
	if _world_root == null:
		return
	for child in _world_root.get_children():
		child.queue_free()
	_building_positions.clear()

	for block_coord in _active_block_coords:
		var block_row := world_runtime.get_block_row(block_coord)
		if block_row.is_empty():
			continue
		var block_node := Node2D.new()
		block_node.name = "Block_%d_%d" % [block_coord.x, block_coord.y]
		block_node.position = world_runtime.get_block_origin(block_coord)
		_world_root.add_child(block_node)
		_build_block_ground(block_node, block_row)
		_build_block_obstacles(block_node, block_row)
		_build_block_buildings(block_coord, block_node)
```

- [ ] **Step 5: Resolve buildings by canonical building rows instead of raw world points**

Update building placement:

```gdscript
func _resolve_building_position(building_data: Dictionary) -> Vector2:
	var block_coord_data := building_data.get("outdoor_block_coord", {}) as Dictionary
	var block_coord := Vector2i(int(block_coord_data.get("x", 0)), int(block_coord_data.get("y", 0)))
	var anchor_id := String(building_data.get("outdoor_anchor_id", ""))
	return world_runtime.resolve_anchor_world_position(block_coord, anchor_id)
```

Use this helper everywhere the controller currently reads `outdoor_position`.

- [ ] **Step 6: Make the controller and smoke tests pass**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `OUTDOOR_CONTROLLER_OK`
- `FIRST_PLAYABLE_LOOP_OK`

## Task 5: Densify The First Authored Slice To Match The Requested Spatial Readability

**Files:**
- Modify: `game/data/outdoor/blocks/0_0.json`
- Modify: `game/data/outdoor/blocks/1_0.json`
- Modify: `game/data/outdoor/blocks/0_1.json`
- Modify: `game/data/outdoor/blocks/1_1.json`
- Modify: `game/data/buildings.json`
- Create: `game/data/events/indoor/pharmacy_01.json`
- Create: `game/data/events/indoor/restaurant_01.json`
- Create: `game/data/events/indoor/bakery_01.json`
- Create: `game/data/events/indoor/warehouse_01.json`
- Create: `game/data/events/indoor/cafe_01.json`
- Create: `game/data/events/indoor/police_box_01.json`
- Create: `game/data/events/indoor/repair_shop_01.json`
- Create: `game/data/events/indoor/residence_01.json`
- Modify: `game/tests/unit/test_indoor_loot_tables.gd`
- Modify: `game/tests/unit/test_outdoor_controller.gd`

- [ ] **Step 1: Raise each of the four first-slice blocks to roughly four buildings each**

For each block file, add enough anchors that the authored slice reaches at least sixteen building markers total. Example addition inside `1_1.json`:

```json
"building_anchors": {
  "laundry_anchor": { "x": 180, "y": 180 },
  "warehouse_anchor": { "x": 720, "y": 220 },
  "repair_shop_anchor": { "x": 700, "y": 700 },
  "residence_anchor": { "x": 220, "y": 720 }
}
```

- [ ] **Step 2: Add the missing building rows and indoor shells**

Use the same minimal indoor shell format already used by `convenience_01.json` and similar files. Example:

```json
{
  "building_id": "pharmacy_01",
  "building_name": "약국",
  "zones": [
    {
      "id": "counter",
      "name": "조제대",
      "description": "유리 진열대와 빈 약통이 얼어붙은 채 남아 있다.",
      "connections": []
    }
  ],
  "search_zones": [
    {
      "id": "pharmacy_counter_loot",
      "label": "조제대 뒤를 뒤진다",
      "base_minutes": 18,
      "loot_table_id": "clinic_medical_cache"
    }
  ]
}
```

- [ ] **Step 3: Extend loot-table and controller assertions to require the denser slice**

In `test_indoor_loot_tables.gd`, require the new event shells to load:

```gdscript
for building_id in ["pharmacy_01", "restaurant_01", "bakery_01", "warehouse_01", "cafe_01", "police_box_01", "repair_shop_01", "residence_01"]:
	assert_true(content_library.get_building(building_id).size() > 0, "Expanded authored slice should include '%s'." % building_id)
```

Keep `test_outdoor_controller.gd` locked on `building_markers.get_child_count() >= 16`.

- [ ] **Step 4: Run the density/content regression tests**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_loot_tables.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
```

Expected:

- `INDOOR_LOOT_TABLES_OK`
- `OUTDOOR_CONTROLLER_OK`

## Task 6: Finish The Pass With Full Verification And Routing Updates

**Files:**
- Modify: `docs/INDEX.md`
- Modify: `docs/CURRENT_STATE.md`

- [ ] **Step 1: Route the repository to this plan and demote the temporary `2x2` plan**

Update `docs/INDEX.md`:

```md
## Active Plans

- [Outdoor World Architecture](superpowers/plans/2026-04-15-outdoor-world-architecture.md)
- [Outdoor Threat and Cold Feedback](superpowers/plans/2026-04-13-outdoor-threat-and-cold-feedback.md)
```

Keep the old `Outdoor 2x2 Block Expansion` entry, but label it as superseded instead of active.

- [ ] **Step 2: Update `docs/CURRENT_STATE.md` so near-term priorities reflect the new runtime**

Replace the old district-expansion priority with a block-runtime priority:

```md
- Replace the temporary outdoor district scaffolding with a fixed-city streamed block runtime.
- Author the first dense `2x2` city slice inside that runtime so the outdoor space already reads as a real district rather than a thin lane.
- Keep map revelation per-run and world access globally open.
```

- [ ] **Step 3: Run the full verification sweep**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_models.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_world_runtime.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_loot_tables.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
XDG_DATA_HOME=/tmp/apocalypse-world-arch-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `CONTENT_LIBRARY_OK`
- `RUN_MODELS_OK`
- `OUTDOOR_WORLD_RUNTIME_OK`
- `OUTDOOR_CONTROLLER_OK`
- `INDOOR_LOOT_TABLES_OK`
- `RUN_CONTROLLER_LIVE_TRANSITION_OK`
- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 4: Self-review against the superseding architecture spec**

Before implementation is declared complete, verify these exact points against `docs/superpowers/specs/2026-04-15-outdoor-world-architecture-design.md`:

- fixed-size block grid exists
- controller uses a `3x3` active window
- movement stays continuous across block boundaries
- world is globally open but visited-map state is run-local
- the first slice now reads as a real `2x2` district rather than a stretched lane

If any of those points are false in play, do not close the pass yet.
