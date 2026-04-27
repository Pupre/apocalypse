# Outdoor Art Integration Pass 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the temporary outdoor debug presentation with the verified frozen-city asset pack for terrain, buildings, props, and player visuals while keeping the existing fixed-city runtime and tests intact.

**Architecture:** Keep the authored `world_layout + block json + OutdoorWorldRuntime` structure unchanged and swap only the presentation layer. Introduce a small outdoor art resolver plus focused render helpers so terrain, buildings, props, decals, and player visuals are mapped from data into sprites/tiles without reworking the streamed world model.

**Tech Stack:** Godot 4.4 GDScript, PackedScene/Node2D/Sprite2D, existing outdoor runtime, headless Godot test scripts

---

### Task 1: Lock the Art-Pass Contract With Tests

**Files:**
- Modify: `game/tests/unit/test_outdoor_controller.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Write the failing assertions for sprite-based outdoor rendering**

```gdscript
var player_sprite_2d := outdoor_mode.get_node_or_null("PlayerVisual") as Sprite2D
var ground_tiles := outdoor_mode.get_node_or_null("Ground/Tiles") as Node2D
var building_visuals := outdoor_mode.get_node_or_null("Buildings") as Node2D

if not assert_true(player_sprite_2d != null, "Outdoor mode should expose a Sprite2D player visual."):
	outdoor_mode.free()
	return
if not assert_true(ground_tiles != null and ground_tiles.get_child_count() > 0, "Outdoor mode should render terrain tile visuals instead of a single placeholder ground polygon."):
	outdoor_mode.free()
	return
assert_true(building_visuals.get_child_count() >= 16, "Outdoor mode should still render the authored city buildings after art integration.")
```

- [ ] **Step 2: Run the targeted outdoor controller test and verify it fails on the old renderer**

Run:
```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
```

Expected:
```text
FAIL ... Sprite2D player visual ...
```

- [ ] **Step 3: Extend smoke coverage to require art-backed outdoor nodes**

```gdscript
var outdoor_player_visual := outdoor_mode.get_node_or_null("PlayerVisual") as Sprite2D
var outdoor_ground_tiles := outdoor_mode.get_node_or_null("Ground/Tiles") as Node2D
assert_true(outdoor_player_visual != null, "Smoke coverage should verify the outdoor player is sprite-backed.")
assert_true(outdoor_ground_tiles != null and outdoor_ground_tiles.get_child_count() > 0, "Smoke coverage should verify outdoor terrain tiles are mounted.")
```

- [ ] **Step 4: Run smoke and keep the failure as the baseline**

Run:
```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:
```text
FAIL ... outdoor player is sprite-backed ...
```

### Task 2: Add an Outdoor Art Resolver

**Files:**
- Create: `game/scripts/outdoor/outdoor_art_resolver.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`

- [ ] **Step 1: Add a focused resolver for runtime asset paths and mappings**

```gdscript
extends RefCounted
class_name OutdoorArtResolver

const ROOT := "res://../resources/frozen_city_devpack_v2_alpha_verified"
const TERRAIN_ROOT := "%s/terrain" % ROOT
const BUILDING_ROOT := "%s/buildings_cutout" % ROOT
const PROP_ROOT := "%s/props_cutout" % ROOT
const PLAYER_ROOT := "%s/player" % ROOT
const DECAL_ROOT := "%s/decals" % ROOT

const BUILDING_TEXTURE_BY_ID := {
	"mart_01": "%s/building_mart.png" % BUILDING_ROOT,
	"apartment_01": "%s/building_apartment.png" % BUILDING_ROOT,
	"residence_01": "%s/building_apartment.png" % BUILDING_ROOT,
	"clinic_01": "%s/building_clinic.png" % BUILDING_ROOT,
	"office_01": "%s/building_office.png" % BUILDING_ROOT,
	"repair_shop_01": "%s/building_office.png" % BUILDING_ROOT,
	"pharmacy_01": "%s/building_pharmacy.png" % BUILDING_ROOT,
	"cafe_01": "%s/building_cafe.png" % BUILDING_ROOT,
	"restaurant_01": "%s/building_cafe.png" % BUILDING_ROOT,
	"bakery_01": "%s/building_cafe.png" % BUILDING_ROOT,
	"warehouse_01": "%s/building_warehouse.png" % BUILDING_ROOT,
	"hardware_01": "%s/building_warehouse.png" % BUILDING_ROOT,
	"gas_station_01": "%s/building_warehouse.png" % BUILDING_ROOT,
	"laundry_01": "%s/building_warehouse.png" % BUILDING_ROOT,
	"police_box_01": "%s/building_police.png" % BUILDING_ROOT,
}
```

- [ ] **Step 2: Add resolver helpers for terrain, props, decals, and player directions**

```gdscript
func building_texture_path(building_id: String) -> String:
	return String(BUILDING_TEXTURE_BY_ID.get(building_id, "%s/building_office.png" % BUILDING_ROOT))


func terrain_texture_path(tile_id: String) -> String:
	return "%s/%s.png" % [TERRAIN_ROOT, tile_id]


func prop_texture_path(prop_id: String) -> String:
	return "%s/%s.png" % [PROP_ROOT, prop_id]


func decal_texture_path(decal_id: String) -> String:
	return "%s/%s.png" % [DECAL_ROOT, decal_id]


func player_texture_path(direction_id: String, frame_id: String) -> String:
	return "%s/%s_%s.png" % [PLAYER_ROOT, direction_id, frame_id]
```

- [ ] **Step 3: Run the resolver through the outdoor test by asserting one mapped file path**

```gdscript
var resolver := load("res://scripts/outdoor/outdoor_art_resolver.gd").new()
assert_true(String(resolver.building_texture_path("mart_01")).find("building_mart.png") >= 0, "Outdoor art resolver should map mart_01 to the mart building sprite.")
```

- [ ] **Step 4: Run the outdoor controller test again and keep only resolver-related failures**

Run:
```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
```

Expected:
```text
FAIL ... missing Sprite2D player visual / terrain tiles ...
```

### Task 3: Replace the Ground Renderer With Tile Visuals

**Files:**
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Split the ground host into terrain and decal layers**

```gdscript
var _terrain_host: Node2D = null
var _decal_host: Node2D = null

func _cache_nodes() -> void:
	_ground_host = get_node_or_null("Ground") as Node2D
	_terrain_host = get_node_or_null("Ground/Tiles") as Node2D
	_decal_host = get_node_or_null("Ground/Decals") as Node2D
```

- [ ] **Step 2: Replace the placeholder polygon refresh with explicit tile sprite generation**

```gdscript
func _refresh_ground() -> void:
	if _terrain_host == null:
		return
	for child in _terrain_host.get_children():
		child.queue_free()
	for child in _decal_host.get_children():
		child.queue_free()

	for road_row in _road_rows:
		var sprite := Sprite2D.new()
		sprite.texture = load(_terrain_tile_for_row(road_row))
		sprite.centered = false
		sprite.position = Vector2(road_row.get("x", 0.0), road_row.get("y", 0.0))
		_terrain_host.add_child(sprite)
```

- [ ] **Step 3: Add a simple terrain mapping function instead of building a full autotile system**

```gdscript
func _terrain_tile_for_row(road_row: Dictionary) -> String:
	var kind := String(road_row.get("kind", "road_plain"))
	match kind:
		"intersection":
			return _art_resolver.terrain_texture_path("road_intersection")
		"crosswalk_h":
			return _art_resolver.terrain_texture_path("crosswalk_h")
		"crosswalk_v":
			return _art_resolver.terrain_texture_path("crosswalk_v")
		"sidewalk":
			return _art_resolver.terrain_texture_path("sidewalk_snow")
		"snow":
			return _art_resolver.terrain_texture_path("snow_ground")
		_:
			return _art_resolver.terrain_texture_path("road_plain")
```

- [ ] **Step 4: Add a small decal pass for visual breakup**

```gdscript
func _add_ground_decal(texture_path: String, position: Vector2) -> void:
	if _decal_host == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = load(texture_path)
	sprite.position = position
	sprite.centered = true
	_decal_host.add_child(sprite)
```

- [ ] **Step 5: Run outdoor controller and smoke until terrain-based rendering passes**

Run:
```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:
```text
... terrain tile assertions pass ...
```

### Task 4: Replace Building Markers With Building Sprites

**Files:**
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`

- [ ] **Step 1: Swap building polygons for Sprite2D visuals**

```gdscript
var sprite := Sprite2D.new()
sprite.name = "Visual"
sprite.texture = load(_art_resolver.building_texture_path(building_id))
sprite.centered = false
sprite.offset = Vector2(-48, -88)
marker_root.add_child(sprite)
```

- [ ] **Step 2: Keep the small label, but demote it to a secondary overlay**

```gdscript
label.position = Vector2(-32, -18)
label.modulate = Color(0.92, 0.94, 0.98, 0.88)
label.add_theme_font_size_override("font_size", 11)
```

- [ ] **Step 3: Preserve nearby-building readability without reverting to debug shapes**

```gdscript
marker.scale = Vector2.ONE * (1.08 if building_id == nearby_building_id else 1.0)
marker.modulate = Color(1.0, 1.0, 1.0, 1.0) if building_id == nearby_building_id else Color(0.92, 0.92, 0.92, 1.0)
```

- [ ] **Step 4: Run the outdoor controller test and verify the building count still passes**

Run:
```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
```

Expected:
```text
OUTDOOR_CONTROLLER_OK
```

### Task 5: Add Prop Sprites for Street Density

**Files:**
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`

- [ ] **Step 1: Extend obstacle refresh to spawn art-backed props**

```gdscript
var sprite := Sprite2D.new()
sprite.texture = load(_art_resolver.prop_texture_path(_prop_id_for_obstacle(obstacle_row, index)))
sprite.centered = false
sprite.offset = Vector2(-32, -48)
sprite.position = Vector2(float(obstacle_row.get("x", 0.0)), float(obstacle_row.get("y", 0.0)))
_obstacle_host.add_child(sprite)
```

- [ ] **Step 2: Add a deterministic obstacle-to-prop mapping helper**

```gdscript
func _prop_id_for_obstacle(obstacle_row: Dictionary, index: int) -> String:
	var cycle := [
		"frozen_car",
		"roadblock",
		"sandbags",
		"street_lamp",
		"dumpster_snow",
		"dead_tree",
		"crate_stack",
	]
	return cycle[index % cycle.size()]
```

- [ ] **Step 3: Keep at least one obstacle assertion in tests, but check Sprite2D presence instead of placeholder geometry**

```gdscript
var obstacle_visuals := outdoor_mode.get_node_or_null("Obstacles") as Node2D
assert_true(obstacle_visuals.get_child_count() > 0, "Outdoor mode should render art-backed obstacle props.")
```

- [ ] **Step 4: Run the outdoor controller test again**

Run:
```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
```

Expected:
```text
OUTDOOR_CONTROLLER_OK
```

### Task 6: Replace the Player Marker With Directional Sprite Visuals

**Files:**
- Modify: `game/scenes/outdoor/outdoor_mode.tscn`
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Replace `PlayerSprite` polygon node with a `Sprite2D` visual node**

```tscn
[node name="PlayerVisual" type="Sprite2D" parent="."]
position = Vector2(240, 360)
z_index = 20
centered = false
offset = Vector2(-16, -24)
```

- [ ] **Step 2: Add last-direction tracking and frame selection in the controller**

```gdscript
var _player_facing := "down"
var _player_walk_frame := 0
var _player_walk_accumulator := 0.0

func _update_player_visual(direction: Vector2, delta: float) -> void:
	if direction != Vector2.ZERO:
		_player_facing = _facing_for_direction(direction)
		_player_walk_accumulator += delta
		if _player_walk_accumulator >= 0.12:
			_player_walk_accumulator = 0.0
			_player_walk_frame = (_player_walk_frame + 1) % 4
	else:
		_player_walk_frame = 0
	var frame_id := "idle" if direction == Vector2.ZERO else "walk%d" % (_player_walk_frame + 1)
	_player_visual.texture = load(_art_resolver.player_texture_path(_player_facing, frame_id))
```

- [ ] **Step 3: Keep the player position API untouched while changing only the visual**

```gdscript
func _sync_view() -> void:
	if _player_visual != null:
		_player_visual.position = _player_position
```

- [ ] **Step 4: Run the targeted tests and verify smoke still boots**

Run:
```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:
```text
OUTDOOR_CONTROLLER_OK
FIRST_PLAYABLE_LOOP_OK
```

### Task 7: Final Regression Sweep for the Outdoor Art Pass

**Files:**
- Modify: `docs/INDEX.md`
- Modify: `docs/CURRENT_STATE.md`

- [ ] **Step 1: Add the art-pass spec and this plan to the routing docs**

```md
- [Outdoor Art Integration Pass 1 Design](superpowers/specs/2026-04-16-outdoor-art-integration-pass1-design.md)
- [Outdoor Art Integration Pass 1](superpowers/plans/2026-04-16-outdoor-art-integration-pass1.md)
```

- [ ] **Step 2: Update current state so outdoor art integration is part of the active stack**

```md
- Replace placeholder outdoor geometry with frozen-city terrain, buildings, props, and player art while keeping the streamed city runtime stable.
```

- [ ] **Step 3: Run the full relevant regression set**

Run:
```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_hud_presenter.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:
```text
HUD_PRESENTATION_OK
RUN_CONTROLLER_LIVE_TRANSITION_OK
OUTDOOR_CONTROLLER_OK
FIRST_PLAYABLE_LOOP_OK
```

- [ ] **Step 4: Stop and hand back for visual review before any UI bar reskin**

```text
Visual checkpoint: outdoor art pass 1 is in. Verify terrain readability, building silhouettes, player readability, and street density before touching HUD bars or inventory skins.
```
