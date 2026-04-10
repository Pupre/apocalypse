# First Playable Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first desktop-playable Godot prototype where one survivor can be created, spend shared time indoors and outdoors, accumulate fatigue, collect loot, enter buildings, sleep, and die.

**Architecture:** Keep one `RunState` as the source of truth for the active run, swap indoor and outdoor modes inside a persistent `run_shell`, and load prototype jobs, traits, buildings, and indoor events from JSON data files. Use headless Godot smoke scripts for repeatable verification while keeping all runtime assets text-first and Git-friendly.

**Tech Stack:** Godot `4.4.1`, `GDScript`, `.tscn` scenes, JSON content files, headless Godot CLI verification on Linux

---

## File Structure

Commands below assume the Linux Godot binary already installed in this workspace.
Because this Codex sandbox cannot write to the default Godot user-data directory under `/home/muhyeon_shin/.local/share`, every headless verification command explicitly sets `XDG_DATA_HOME=/tmp/godot-data`.

```bash
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64
```

Planned implementation files and responsibilities:

- `game/project.godot`: project metadata, main scene, input map, autoload declarations
- `game/icon.svg`: temporary project icon
- `game/scenes/bootstrap/main.tscn`: root scene host for the app
- `game/scripts/bootstrap/main.gd`: app startup and root host attachment
- `game/scripts/autoload/content_library.gd`: JSON loading and indexed content access
- `game/scripts/autoload/app_router.gd`: top-level scene flow between title, creator, and run shell
- `game/scenes/menus/title_menu.tscn`: initial menu
- `game/scripts/menus/title_menu.gd`: title menu signals
- `game/scenes/menus/survivor_creator.tscn`: job and trait selection scene
- `game/scripts/menus/survivor_creator.gd`: survivor build state and validation
- `game/scripts/run/time_clock.gd`: day and minute tracking
- `game/scripts/run/fatigue_model.gd`: fatigue bands, penalties, and sleep preview math
- `game/scripts/run/inventory_model.gd`: carry limit and item storage
- `game/scripts/run/run_state.gd`: canonical active-run state
- `game/scenes/run/run_shell.tscn`: persistent shell for HUD and active mode host
- `game/scripts/run/run_controller.gd`: mode transitions, run startup, death handling
- `game/scenes/run/hud.tscn`: time, fatigue, exposure, and inventory summary
- `game/scripts/run/hud_presenter.gd`: HUD binding from `RunState`
- `game/scenes/indoor/indoor_mode.tscn`: indoor text exploration UI
- `game/scripts/indoor/indoor_mode.gd`: indoor UI rendering and action button emission
- `game/scripts/indoor/indoor_director.gd`: indoor view model and available actions
- `game/scripts/indoor/indoor_action_resolver.gd`: apply indoor action costs and outcomes
- `game/scenes/outdoor/outdoor_mode.tscn`: outdoor traversal scene
- `game/scripts/outdoor/outdoor_controller.gd`: outdoor time ticking, movement intent, building entry
- `game/scripts/outdoor/exposure_model.gd`: outside exposure depletion
- `game/data/jobs.json`: prototype jobs
- `game/data/traits.json`: prototype traits
- `game/data/buildings.json`: prototype building metadata
- `game/data/events/indoor/mart_01.json`: prototype indoor event data
- `game/tests/support/test_case.gd`: shared headless assertions
- `game/tests/smoke/test_bootstrap.gd`: project bootstrap smoke test
- `game/tests/unit/test_content_library.gd`: content loading verification
- `game/tests/unit/test_survivor_creator.gd`: job and trait selection verification
- `game/tests/unit/test_run_models.gd`: clock, fatigue, and inventory verification
- `game/tests/unit/test_indoor_actions.gd`: indoor resolver verification
- `game/tests/unit/test_outdoor_controller.gd`: outdoor time and exposure verification
- `game/tests/smoke/test_first_playable_loop.gd`: end-to-end prototype smoke flow

### Task 1: Bootstrap the Godot project and headless smoke harness

**Files:**
- Create: `game/project.godot`
- Create: `game/icon.svg`
- Create: `game/scenes/bootstrap/main.tscn`
- Create: `game/scripts/bootstrap/main.gd`
- Create: `game/tests/support/test_case.gd`
- Create: `game/tests/smoke/test_bootstrap.gd`
- Test: `game/tests/smoke/test_bootstrap.gd`

- [ ] **Step 1: Create the minimal project shell and a failing smoke test**

```ini
; game/project.godot
config_version=5

[application]
config/name="Apocalypse"
config/features=PackedStringArray("4.4")
run/main_scene="res://scenes/bootstrap/main.tscn"

[rendering]
renderer/rendering_method="mobile"
textures/vram_compression/import_etc2_astc=true
```

```gdscript
# game/tests/support/test_case.gd
extends SceneTree

func assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)

func assert_eq(actual, expected, message: String) -> void:
	if actual == expected:
		return
	push_error("%s (expected=%s actual=%s)" % [message, str(expected), str(actual)])
	quit(1)

func pass(message: String = "OK") -> void:
	print(message)
	quit()
```

```gdscript
# game/tests/smoke/test_bootstrap.gd
extends "res://tests/support/test_case.gd"

func _initialize() -> void:
	var scene := load("res://scenes/bootstrap/main.tscn")
	assert_true(scene != null, "Missing bootstrap scene")
	pass("BOOTSTRAP_SCENE_OK")
```

- [ ] **Step 2: Run the smoke test and verify it fails because the bootstrap scene does not exist yet**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_bootstrap.gd
```

Expected: FAIL with `Missing bootstrap scene`

- [ ] **Step 3: Add the bootstrap scene, root script, and placeholder icon**

```xml
<!-- game/icon.svg -->
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <rect width="128" height="128" rx="20" fill="#1a1f24"/>
  <path d="M28 84 L64 24 L100 84 Z" fill="#d9d3c7"/>
  <rect x="58" y="76" width="12" height="24" fill="#1a1f24"/>
</svg>
```

```gdscript
# game/scripts/bootstrap/main.gd
extends Node

func _ready() -> void:
	name = "Main"
```

```text
# game/scenes/bootstrap/main.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/bootstrap/main.gd" id="1_main"]

[node name="Main" type="Node"]
script = ExtResource("1_main")
```

- [ ] **Step 4: Re-run the smoke test and verify the project boots**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_bootstrap.gd
```

Expected: PASS with `BOOTSTRAP_SCENE_OK`

- [ ] **Step 5: Commit the bootstrap baseline**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/project.godot game/icon.svg game/scenes/bootstrap/main.tscn game/scripts/bootstrap/main.gd game/tests/support/test_case.gd game/tests/smoke/test_bootstrap.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "chore: bootstrap Godot project"
```

### Task 2: Add prototype content data and JSON loading

**Files:**
- Create: `game/data/jobs.json`
- Create: `game/data/traits.json`
- Create: `game/data/buildings.json`
- Create: `game/scripts/autoload/content_library.gd`
- Create: `game/tests/unit/test_content_library.gd`
- Modify: `game/project.godot`
- Test: `game/tests/unit/test_content_library.gd`

- [ ] **Step 1: Write a failing content-loading test against the missing loader**

```gdscript
# game/tests/unit/test_content_library.gd
extends "res://tests/support/test_case.gd"

func _initialize() -> void:
	var library := preload("res://scripts/autoload/content_library.gd").new()
	library.load_all()
	assert_eq(library.jobs.size(), 2, "Prototype jobs should load")
	assert_eq(library.traits.size(), 4, "Prototype traits should load")
	assert_true(library.buildings.has("mart_01"), "Prototype building should be indexed")
	pass("CONTENT_LIBRARY_OK")
```

- [ ] **Step 2: Run the content test and verify it fails because the loader file does not exist**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
```

Expected: FAIL with a missing script error for `content_library.gd`

- [ ] **Step 3: Add the prototype JSON data and the content loader autoload**

```json
// game/data/jobs.json
[
  {
    "id": "clerk",
    "name": "Store Clerk",
    "description": "Knows where practical supplies tend to be stored.",
    "modifiers": {
      "indoor_find_bias": 0.15,
      "carry_limit": 1
    }
  },
  {
    "id": "courier",
    "name": "Courier",
    "description": "Moves fast and handles route pressure well.",
    "modifiers": {
      "move_speed": 30.0,
      "fatigue_gain": -0.1
    }
  }
]
```

```json
// game/data/traits.json
[
  {
    "id": "athlete",
    "name": "Athlete",
    "cost": -4,
    "modifiers": {
      "move_speed": 40.0,
      "fatigue_gain": -0.15
    }
  },
  {
    "id": "light_sleeper",
    "name": "Light Sleeper",
    "cost": -2,
    "modifiers": {
      "sleep_hours_adjustment": -1
    }
  },
  {
    "id": "unlucky",
    "name": "Unlucky",
    "cost": 4,
    "modifiers": {
      "indoor_find_bias": -0.2
    }
  },
  {
    "id": "heavy_sleeper",
    "name": "Heavy Sleeper",
    "cost": 2,
    "modifiers": {
      "sleep_hours_adjustment": 1
    }
  }
]
```

```json
// game/data/buildings.json
[
  {
    "id": "mart_01",
    "name": "Neighborhood Mart",
    "category": "retail",
    "base_candidate": true,
    "outdoor_position": {
      "x": 640,
      "y": 360
    },
    "indoor_event_path": "res://data/events/indoor/mart_01.json"
  }
]
```

```gdscript
# game/scripts/autoload/content_library.gd
extends Node
class_name ContentLibrary

var jobs: Dictionary = {}
var traits: Dictionary = {}
var buildings: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	jobs = _load_indexed_array("res://data/jobs.json")
	traits = _load_indexed_array("res://data/traits.json")
	buildings = _load_indexed_array("res://data/buildings.json")

func get_job(job_id: String) -> Dictionary:
	return jobs.get(job_id, {})

func get_trait(trait_id: String) -> Dictionary:
	return traits.get(trait_id, {})

func get_building(building_id: String) -> Dictionary:
	return buildings.get(building_id, {})

func _load_indexed_array(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open %s" % path)
		return {}
	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Expected array in %s" % path)
		return {}
	var indexed: Dictionary = {}
	for entry in parsed:
		indexed[entry["id"]] = entry
	return indexed
```

```ini
; game/project.godot
config_version=5

[application]
config/name="Apocalypse"
config/features=PackedStringArray("4.4")
run/main_scene="res://scenes/bootstrap/main.tscn"

[autoload]
ContentLibrary="*res://scripts/autoload/content_library.gd"

[rendering]
renderer/rendering_method="mobile"
textures/vram_compression/import_etc2_astc=true
```

- [ ] **Step 4: Re-run the content test and verify the data indexes correctly**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_content_library.gd
```

Expected: PASS with `CONTENT_LIBRARY_OK`

- [ ] **Step 5: Commit the content baseline**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/data/jobs.json game/data/traits.json game/data/buildings.json game/scripts/autoload/content_library.gd game/tests/unit/test_content_library.gd game/project.godot
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add prototype content library"
```

### Task 3: Build the title menu and survivor creation flow

**Files:**
- Create: `game/scenes/menus/title_menu.tscn`
- Create: `game/scripts/menus/title_menu.gd`
- Create: `game/scenes/menus/survivor_creator.tscn`
- Create: `game/scripts/menus/survivor_creator.gd`
- Create: `game/tests/unit/test_survivor_creator.gd`
- Modify: `game/scripts/bootstrap/main.gd`
- Test: `game/tests/unit/test_survivor_creator.gd`

- [ ] **Step 1: Write a failing survivor-creation test for job and trait selection**

```gdscript
# game/tests/unit/test_survivor_creator.gd
extends "res://tests/support/test_case.gd"

func _initialize() -> void:
	var creator := preload("res://scripts/menus/survivor_creator.gd").new()
	creator.content_library = preload("res://scripts/autoload/content_library.gd").new()
	creator.content_library.load_all()
	creator.select_job("courier")
	creator.toggle_trait("athlete")
	creator.toggle_trait("unlucky")
	var payload := creator.build_payload()
	assert_eq(payload["job_id"], "courier", "Selected job should be stored")
	assert_eq(payload["trait_ids"], PackedStringArray(["athlete", "unlucky"]), "Traits should be preserved in order")
	assert_eq(payload["remaining_points"], 0, "Trait costs should balance back to zero")
	pass("SURVIVOR_CREATOR_OK")
```

- [ ] **Step 2: Run the survivor-creation test and verify it fails because the creator script does not exist yet**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survivor_creator.gd
```

Expected: FAIL with a missing script error for `survivor_creator.gd`

- [ ] **Step 3: Add the title menu scene, survivor creator logic, and bootstrap handoff**

```gdscript
# game/scripts/menus/title_menu.gd
extends Control

signal start_requested

func _ready() -> void:
	$MarginContainer/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	start_requested.emit()
```

```text
# game/scenes/menus/title_menu.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/menus/title_menu.gd" id="1_menu"]

[node name="TitleMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_menu")

[node name="MarginContainer" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_constants/margin_left = 32
theme_override_constants/margin_top = 32
theme_override_constants/margin_right = 32
theme_override_constants/margin_bottom = 32

[node name="VBoxContainer" type="VBoxContainer" parent="MarginContainer"]
layout_mode = 2

[node name="TitleLabel" type="Label" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
text = "Apocalypse"

[node name="StartButton" type="Button" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
text = "New Run"
```

```gdscript
# game/scripts/menus/survivor_creator.gd
extends Control

signal survivor_confirmed(payload: Dictionary)

var content_library: ContentLibrary
var selected_job_id := ""
var selected_trait_ids: PackedStringArray = PackedStringArray()

func _ready() -> void:
	if content_library == null:
		content_library = ContentLibrary
	$MarginContainer/VBoxContainer/JobButtons/CourierButton.pressed.connect(func() -> void: select_job("courier"))
	$MarginContainer/VBoxContainer/JobButtons/ClerkButton.pressed.connect(func() -> void: select_job("clerk"))
	$MarginContainer/VBoxContainer/TraitButtons/AthleteButton.pressed.connect(func() -> void: toggle_trait("athlete"))
	$MarginContainer/VBoxContainer/TraitButtons/LightSleeperButton.pressed.connect(func() -> void: toggle_trait("light_sleeper"))
	$MarginContainer/VBoxContainer/TraitButtons/UnluckyButton.pressed.connect(func() -> void: toggle_trait("unlucky"))
	$MarginContainer/VBoxContainer/TraitButtons/HeavySleeperButton.pressed.connect(func() -> void: toggle_trait("heavy_sleeper"))
	$MarginContainer/VBoxContainer/ConfirmButton.pressed.connect(confirm_selection)
	_refresh_summary()

func select_job(job_id: String) -> void:
	selected_job_id = job_id
	_refresh_summary()

func toggle_trait(trait_id: String) -> void:
	if selected_trait_ids.has(trait_id):
		selected_trait_ids.erase(trait_id)
	else:
		selected_trait_ids.append(trait_id)
	_refresh_summary()

func remaining_points() -> int:
	var total := 0
	for trait_id in selected_trait_ids:
		var trait := content_library.get_trait(trait_id)
		total += int(trait.get("cost", 0))
	return total

func build_payload() -> Dictionary:
	return {
		"job_id": selected_job_id,
		"trait_ids": selected_trait_ids.duplicate(),
		"remaining_points": remaining_points()
	}

func confirm_selection() -> void:
	if selected_job_id == "" or remaining_points() < 0:
		return
	survivor_confirmed.emit(build_payload())

func _refresh_summary() -> void:
	if not has_node("MarginContainer/VBoxContainer/SummaryLabel"):
		return
	$MarginContainer/VBoxContainer/SummaryLabel.text = "Job: %s | Points: %d" % [selected_job_id, remaining_points()]
```

```text
# game/scenes/menus/survivor_creator.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/menus/survivor_creator.gd" id="1_creator"]

[node name="SurvivorCreator" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_creator")

[node name="MarginContainer" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_constants/margin_left = 32
theme_override_constants/margin_top = 32
theme_override_constants/margin_right = 32
theme_override_constants/margin_bottom = 32

[node name="VBoxContainer" type="VBoxContainer" parent="MarginContainer"]
layout_mode = 2

[node name="SummaryLabel" type="Label" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
text = "Job: none | Points: 0"

[node name="JobButtons" type="HBoxContainer" parent="MarginContainer/VBoxContainer"]
layout_mode = 2

[node name="CourierButton" type="Button" parent="MarginContainer/VBoxContainer/JobButtons"]
layout_mode = 2
text = "Courier"

[node name="ClerkButton" type="Button" parent="MarginContainer/VBoxContainer/JobButtons"]
layout_mode = 2
text = "Store Clerk"

[node name="TraitButtons" type="GridContainer" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
columns = 2

[node name="AthleteButton" type="Button" parent="MarginContainer/VBoxContainer/TraitButtons"]
layout_mode = 2
text = "Athlete (-4)"

[node name="LightSleeperButton" type="Button" parent="MarginContainer/VBoxContainer/TraitButtons"]
layout_mode = 2
text = "Light Sleeper (-2)"

[node name="UnluckyButton" type="Button" parent="MarginContainer/VBoxContainer/TraitButtons"]
layout_mode = 2
text = "Unlucky (+4)"

[node name="HeavySleeperButton" type="Button" parent="MarginContainer/VBoxContainer/TraitButtons"]
layout_mode = 2
text = "Heavy Sleeper (+2)"

[node name="ConfirmButton" type="Button" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
text = "Confirm Survivor"
```

```gdscript
# game/scripts/bootstrap/main.gd
extends Node

func _ready() -> void:
	name = "Main"
	var title_menu := preload("res://scenes/menus/title_menu.tscn").instantiate()
	add_child(title_menu)
	title_menu.start_requested.connect(_show_survivor_creator)

func _show_survivor_creator() -> void:
	for child in get_children():
		child.queue_free()
	var creator := preload("res://scenes/menus/survivor_creator.tscn").instantiate()
	add_child(creator)
```

- [ ] **Step 4: Re-run the survivor-creation test and verify the payload is built correctly**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survivor_creator.gd
```

Expected: PASS with `SURVIVOR_CREATOR_OK`

- [ ] **Step 5: Commit the menu and survivor creator flow**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/scenes/menus/title_menu.tscn game/scripts/menus/title_menu.gd game/scenes/menus/survivor_creator.tscn game/scripts/menus/survivor_creator.gd game/tests/unit/test_survivor_creator.gd game/scripts/bootstrap/main.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add survivor creation flow"
```

### Task 4: Implement the shared run models for time, fatigue, and inventory

**Files:**
- Create: `game/scripts/run/time_clock.gd`
- Create: `game/scripts/run/fatigue_model.gd`
- Create: `game/scripts/run/inventory_model.gd`
- Create: `game/scripts/run/run_state.gd`
- Create: `game/tests/unit/test_run_models.gd`
- Test: `game/tests/unit/test_run_models.gd`

- [ ] **Step 1: Write a failing model test for the shared time and fatigue math**

```gdscript
# game/tests/unit/test_run_models.gd
extends "res://tests/support/test_case.gd"

func _initialize() -> void:
	var state := preload("res://scripts/run/run_state.gd").from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete", "light_sleeper"]),
		"remaining_points": 0
	})
	state.advance_minutes(180)
	assert_eq(state.clock.day_index, 1, "Three hours should stay on day one")
	assert_eq(state.clock.minute_of_day, 660, "Clock should advance from 08:00 to 11:00")
	assert_eq(int(state.move_speed), 230, "Job and trait modifiers should increase move speed")
	state.fatigue += 52.0
	var sleep_preview := state.get_sleep_preview()
	assert_eq(sleep_preview["sleep_minutes"], 420, "Fatigue preview should map to seven hours of sleep")
	var added := state.inventory.add_item({"id": "canned_beans", "bulk": 1})
	assert_true(added, "Inventory should accept a small loot item")
	pass("RUN_MODELS_OK")
```

- [ ] **Step 2: Run the model test and verify it fails because the run scripts do not exist yet**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_models.gd
```

Expected: FAIL with a missing script error for `run_state.gd`

- [ ] **Step 3: Add the shared runtime models**

```gdscript
# game/scripts/run/time_clock.gd
extends RefCounted
class_name TimeClock

var day_index := 1
var minute_of_day := 480

func advance_minutes(amount: int) -> void:
	minute_of_day += amount
	while minute_of_day >= 1440:
		minute_of_day -= 1440
		day_index += 1

func get_clock_label() -> String:
	var hours := minute_of_day / 60
	var minutes := minute_of_day % 60
	return "Day %d %02d:%02d" % [day_index, hours, minutes]
```

```gdscript
# game/scripts/run/fatigue_model.gd
extends RefCounted
class_name FatigueModel

func get_band(value: float) -> String:
	if value < 15.0:
		return "light"
	if value < 35.0:
		return "steady"
	if value < 55.0:
		return "tired"
	if value < 75.0:
		return "exhausted"
	return "critical"

func get_sleep_preview(fatigue_value: float, sleep_hours_adjustment: int) -> Dictionary:
	var base_hours := 6 + int(floor(fatigue_value / 20.0))
	var total_hours := clampi(base_hours + sleep_hours_adjustment, 4, 12)
	return {
		"sleep_minutes": total_hours * 60,
		"band": get_band(fatigue_value)
	}

func outdoor_efficiency_multiplier(fatigue_value: float) -> float:
	return clamp(1.0 - (fatigue_value / 160.0), 0.55, 1.0)
```

```gdscript
# game/scripts/run/inventory_model.gd
extends RefCounted
class_name InventoryModel

var carry_limit := 8
var items: Array[Dictionary] = []

func total_bulk() -> int:
	var total := 0
	for item in items:
		total += int(item.get("bulk", 1))
	return total

func can_add(item: Dictionary) -> bool:
	return total_bulk() + int(item.get("bulk", 1)) <= carry_limit

func add_item(item: Dictionary) -> bool:
	if not can_add(item):
		return false
	items.append(item.duplicate(true))
	return true
```

```gdscript
# game/scripts/run/run_state.gd
extends RefCounted
class_name RunState

var clock := TimeClock.new()
var fatigue_model := FatigueModel.new()
var inventory := InventoryModel.new()
var survivor: Dictionary = {}
var fatigue := 0.0
var hunger := 0.0
var health := 100.0
var exposure := 100.0
var move_speed := 160.0
var fatigue_gain_multiplier := 1.0
var current_mode := "outdoor"
var current_building_id := ""

static func from_survivor_config(config: Dictionary) -> RunState:
	var state := RunState.new()
	state.survivor = config.duplicate(true)
	state._apply_content_modifiers()
	return state

func advance_minutes(amount: int) -> void:
	clock.advance_minutes(amount)
	fatigue += (float(amount) / 30.0) * fatigue_gain_multiplier
	hunger += float(amount) / 60.0

func advance_sleep_time(minutes: int) -> void:
	clock.advance_minutes(minutes)
	hunger += float(minutes) / 60.0

func get_sleep_preview() -> Dictionary:
	return fatigue_model.get_sleep_preview(fatigue, _sleep_hours_adjustment())

func is_dead() -> bool:
	return health <= 0.0 or exposure <= 0.0

func _apply_content_modifiers() -> void:
	var carry_bonus := 0
	var job := ContentLibrary.get_job(survivor.get("job_id", ""))
	move_speed += float(job.get("modifiers", {}).get("move_speed", 0.0))
	fatigue_gain_multiplier += float(job.get("modifiers", {}).get("fatigue_gain", 0.0))
	carry_bonus += int(job.get("modifiers", {}).get("carry_limit", 0))
	for trait_id in survivor.get("trait_ids", PackedStringArray()):
		var trait := ContentLibrary.get_trait(trait_id)
		move_speed += float(trait.get("modifiers", {}).get("move_speed", 0.0))
		fatigue_gain_multiplier += float(trait.get("modifiers", {}).get("fatigue_gain", 0.0))
		carry_bonus += int(trait.get("modifiers", {}).get("carry_limit", 0))
	inventory.carry_limit += carry_bonus

func _sleep_hours_adjustment() -> int:
	var adjustment := 0
	for trait_id in survivor.get("trait_ids", PackedStringArray()):
		var trait := ContentLibrary.get_trait(trait_id)
		adjustment += int(trait.get("modifiers", {}).get("sleep_hours_adjustment", 0))
	return adjustment
```

- [ ] **Step 4: Re-run the model test and verify the shared run state behaves correctly**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_models.gd
```

Expected: PASS with `RUN_MODELS_OK`

- [ ] **Step 5: Commit the shared run models**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/scripts/run/time_clock.gd game/scripts/run/fatigue_model.gd game/scripts/run/inventory_model.gd game/scripts/run/run_state.gd game/tests/unit/test_run_models.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add shared run models"
```

### Task 5: Add the run shell, app router, HUD, and indoor prototype

**Files:**
- Create: `game/scripts/autoload/app_router.gd`
- Create: `game/scenes/run/run_shell.tscn`
- Create: `game/scenes/run/hud.tscn`
- Create: `game/scripts/run/run_controller.gd`
- Create: `game/scripts/run/hud_presenter.gd`
- Create: `game/scenes/indoor/indoor_mode.tscn`
- Create: `game/scripts/indoor/indoor_mode.gd`
- Create: `game/scripts/indoor/indoor_director.gd`
- Create: `game/scripts/indoor/indoor_action_resolver.gd`
- Create: `game/data/events/indoor/mart_01.json`
- Create: `game/tests/unit/test_indoor_actions.gd`
- Modify: `game/project.godot`
- Modify: `game/scripts/bootstrap/main.gd`
- Test: `game/tests/unit/test_indoor_actions.gd`

- [ ] **Step 1: Write a failing indoor-actions test for clue surfacing and loot application**

```gdscript
# game/tests/unit/test_indoor_actions.gd
extends "res://tests/support/test_case.gd"

func _initialize() -> void:
	var state := preload("res://scripts/run/run_state.gd").from_survivor_config({
		"job_id": "clerk",
		"trait_ids": PackedStringArray(["heavy_sleeper"]),
		"remaining_points": 2
	})
	var director := preload("res://scripts/indoor/indoor_director.gd").new()
	var view := director.open_building("mart_01")
	assert_true(view["clues"].has("lingering warmth"), "Indoor clues should be visible before acting")
	var resolver := preload("res://scripts/indoor/indoor_action_resolver.gd").new()
	resolver.apply_action(state, view["actions"][0])
	assert_eq(state.clock.minute_of_day, 540, "One indoor action should consume one hour")
	assert_eq(state.inventory.items.size(), 1, "Indoor search should add one loot item")
	pass("INDOOR_ACTIONS_OK")
```

- [ ] **Step 2: Run the indoor test and verify it fails because the indoor scripts and event data do not exist yet**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_actions.gd
```

Expected: FAIL with a missing script error for `indoor_director.gd`

- [ ] **Step 3: Add the router, run shell, HUD, and indoor prototype**

```ini
; game/project.godot
config_version=5

[application]
config/name="Apocalypse"
config/features=PackedStringArray("4.4")
run/main_scene="res://scenes/bootstrap/main.tscn"

[autoload]
AppRouter="*res://scripts/autoload/app_router.gd"
ContentLibrary="*res://scripts/autoload/content_library.gd"

[rendering]
renderer/rendering_method="mobile"
textures/vram_compression/import_etc2_astc=true
```

```gdscript
# game/scripts/autoload/app_router.gd
extends Node
class_name AppRouter

var host_root: Node

func attach_host(root: Node) -> void:
	host_root = root

func show_title() -> void:
	_swap_scene(preload("res://scenes/menus/title_menu.tscn").instantiate())

func show_survivor_creator() -> void:
	_swap_scene(preload("res://scenes/menus/survivor_creator.tscn").instantiate())

func show_run_shell(payload: Dictionary) -> void:
	var run_shell := preload("res://scenes/run/run_shell.tscn").instantiate()
	run_shell.start_new_run(payload)
	_swap_scene(run_shell)

func _swap_scene(next_scene: Node) -> void:
	for child in host_root.get_children():
		child.queue_free()
	host_root.add_child(next_scene)
```

```gdscript
# game/scripts/bootstrap/main.gd
extends Node

func _ready() -> void:
	name = "Main"
	AppRouter.attach_host(self)
	AppRouter.show_title()
	await get_tree().process_frame
	var title_menu := get_child(0)
	title_menu.start_requested.connect(AppRouter.show_survivor_creator)
```

```gdscript
# game/scripts/run/hud_presenter.gd
extends Control

func render(run_state: RunState) -> void:
	$VBoxContainer/TimeLabel.text = run_state.clock.get_clock_label()
	$VBoxContainer/FatigueLabel.text = "Fatigue: %s" % run_state.fatigue_model.get_band(run_state.fatigue)
	$VBoxContainer/ExposureLabel.text = "Exposure: %d" % int(run_state.exposure)
	$VBoxContainer/InventoryLabel.text = "Items: %d/%d" % [run_state.inventory.total_bulk(), run_state.inventory.carry_limit]
```

```text
# game/scenes/run/hud.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/run/hud_presenter.gd" id="1_hud"]

[node name="Hud" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_hud")

[node name="VBoxContainer" type="VBoxContainer" parent="."]
layout_mode = 1
offset_left = 16.0
offset_top = 16.0

[node name="TimeLabel" type="Label" parent="VBoxContainer"]
layout_mode = 2
text = "Day 1 08:00"

[node name="FatigueLabel" type="Label" parent="VBoxContainer"]
layout_mode = 2
text = "Fatigue: light"

[node name="ExposureLabel" type="Label" parent="VBoxContainer"]
layout_mode = 2
text = "Exposure: 100"

[node name="InventoryLabel" type="Label" parent="VBoxContainer"]
layout_mode = 2
text = "Items: 0/8"
```

```json
// game/data/events/indoor/mart_01.json
{
  "building_id": "mart_01",
  "clues": [
    "lingering warmth",
    "recently disturbed shelves"
  ],
  "actions": [
    {
      "id": "search_checkout",
      "label": "Search the checkout lane",
      "minutes": 60,
      "fatigue": 8,
      "loot": [
        {
          "id": "canned_beans",
          "name": "Canned Beans",
          "bulk": 1
        }
      ]
    },
    {
      "id": "sleep",
      "label": "Sleep for the night",
      "minutes": 0,
      "fatigue": -999
    }
  ]
}
```

```gdscript
# game/scripts/indoor/indoor_director.gd
extends RefCounted
class_name IndoorDirector

func open_building(building_id: String) -> Dictionary:
	var building := ContentLibrary.get_building(building_id)
	var file := FileAccess.open(building["indoor_event_path"], FileAccess.READ)
	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	return {
		"building_id": building_id,
		"title": building["name"],
		"clues": parsed["clues"],
		"actions": parsed["actions"]
	}
```

```gdscript
# game/scripts/indoor/indoor_action_resolver.gd
extends RefCounted
class_name IndoorActionResolver

func apply_action(run_state: RunState, action: Dictionary) -> void:
	if action["id"] == "sleep":
		var preview := run_state.get_sleep_preview()
		run_state.advance_sleep_time(preview["sleep_minutes"])
		run_state.fatigue = maxf(0.0, run_state.fatigue - 35.0)
		return
	run_state.advance_minutes(int(action.get("minutes", 60)))
	run_state.fatigue += float(action.get("fatigue", 0))
	for item in action.get("loot", []):
		run_state.inventory.add_item(item)
```

```gdscript
# game/scripts/run/run_controller.gd
extends Control
class_name RunController

var run_state: RunState
var indoor_director := IndoorDirector.new()
var indoor_resolver := IndoorActionResolver.new()

func start_new_run(payload: Dictionary) -> void:
	run_state = RunState.from_survivor_config(payload)
	_show_indoor("mart_01")

func _show_indoor(building_id: String) -> void:
	run_state.current_mode = "indoor"
	run_state.current_building_id = building_id
	var indoor_mode := preload("res://scenes/indoor/indoor_mode.tscn").instantiate()
	$ModeHost.add_child(indoor_mode)
	indoor_mode.render_view(indoor_director.open_building(building_id), run_state)
	indoor_mode.action_requested.connect(_on_indoor_action_requested)
	$Hud.render(run_state)

func _on_indoor_action_requested(action: Dictionary) -> void:
	indoor_resolver.apply_action(run_state, action)
	$Hud.render(run_state)
```

```text
# game/scenes/run/run_shell.tscn
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/run/run_controller.gd" id="1_controller"]
[ext_resource type="PackedScene" path="res://scenes/run/hud.tscn" id="2_hud"]

[node name="RunShell" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_controller")

[node name="Hud" parent="." instance=ExtResource("2_hud")]

[node name="ModeHost" type="Control" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = 96.0
```

```gdscript
# game/scripts/indoor/indoor_mode.gd
extends Control

signal action_requested(action: Dictionary)

func render_view(view: Dictionary, run_state: RunState) -> void:
	$MarginContainer/VBoxContainer/TitleLabel.text = view["title"]
	$MarginContainer/VBoxContainer/ClueLabel.text = ", ".join(view["clues"])
	var preview := run_state.get_sleep_preview()
	$MarginContainer/VBoxContainer/SleepPreviewLabel.text = "Sleep Preview: %d hours" % int(preview["sleep_minutes"] / 60)
	for child in $MarginContainer/VBoxContainer/ActionList.get_children():
		child.queue_free()
	for action in view["actions"]:
		var button := Button.new()
		button.text = "%s (%dh)" % [action["label"], int(action.get("minutes", 0) / 60)]
		button.pressed.connect(func() -> void: action_requested.emit(action))
		$MarginContainer/VBoxContainer/ActionList.add_child(button)
```

```text
# game/scenes/indoor/indoor_mode.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/indoor/indoor_mode.gd" id="1_mode"]

[node name="IndoorMode" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_mode")

[node name="MarginContainer" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_constants/margin_left = 32
theme_override_constants/margin_top = 120
theme_override_constants/margin_right = 32
theme_override_constants/margin_bottom = 32

[node name="VBoxContainer" type="VBoxContainer" parent="MarginContainer"]
layout_mode = 2

[node name="TitleLabel" type="Label" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
text = "Building"

[node name="ClueLabel" type="Label" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
text = "Clues"

[node name="SleepPreviewLabel" type="Label" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
text = "Sleep Preview"

[node name="ActionList" type="VBoxContainer" parent="MarginContainer/VBoxContainer"]
layout_mode = 2
```

- [ ] **Step 4: Re-run the indoor test and verify clue visibility plus loot application**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_actions.gd
```

Expected: PASS with `INDOOR_ACTIONS_OK`

- [ ] **Step 5: Commit the run shell and indoor prototype**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/scripts/autoload/app_router.gd game/scenes/run/run_shell.tscn game/scenes/run/hud.tscn game/scripts/run/run_controller.gd game/scripts/run/hud_presenter.gd game/scenes/indoor/indoor_mode.tscn game/scripts/indoor/indoor_mode.gd game/scripts/indoor/indoor_director.gd game/scripts/indoor/indoor_action_resolver.gd game/data/events/indoor/mart_01.json game/tests/unit/test_indoor_actions.gd game/project.godot game/scripts/bootstrap/main.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add indoor prototype shell"
```

### Task 6: Implement the outdoor traversal prototype and shared-time depletion

**Files:**
- Create: `game/scenes/outdoor/outdoor_mode.tscn`
- Create: `game/scripts/outdoor/outdoor_controller.gd`
- Create: `game/scripts/outdoor/exposure_model.gd`
- Create: `game/tests/unit/test_outdoor_controller.gd`
- Modify: `game/scripts/run/run_controller.gd`
- Test: `game/tests/unit/test_outdoor_controller.gd`

- [ ] **Step 1: Write a failing outdoor test for real-time minute conversion and exposure drain**

```gdscript
# game/tests/unit/test_outdoor_controller.gd
extends "res://tests/support/test_case.gd"

func _initialize() -> void:
	var state := preload("res://scripts/run/run_state.gd").from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete", "unlucky"]),
		"remaining_points": 0
	})
	var controller := preload("res://scripts/outdoor/outdoor_controller.gd").new()
	controller.bind_run_state(state)
	controller.simulate_seconds(180.0)
	assert_eq(state.clock.minute_of_day, 660, "Three real minutes should advance three in-game hours")
	assert_true(state.exposure < 100.0, "Outdoor time should drain exposure")
	pass("OUTDOOR_CONTROLLER_OK")
```

- [ ] **Step 2: Run the outdoor test and verify it fails because the outdoor controller does not exist yet**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
```

Expected: FAIL with a missing script error for `outdoor_controller.gd`

- [ ] **Step 3: Add the outdoor mode, exposure model, and run transition**

```gdscript
# game/scripts/outdoor/exposure_model.gd
extends RefCounted
class_name ExposureModel

func drain(current_value: float, seconds_elapsed: float, fatigue_value: float) -> float:
	var base_loss := seconds_elapsed / 12.0
	var fatigue_penalty := clamp(fatigue_value / 200.0, 0.0, 0.25)
	return maxf(0.0, current_value - (base_loss * (1.0 + fatigue_penalty)))
```

```gdscript
# game/scripts/outdoor/outdoor_controller.gd
extends Node2D
class_name OutdoorController

signal building_entered(building_id: String)

var run_state: RunState
var exposure_model := ExposureModel.new()
var seconds_buffer := 0.0
var player_position := Vector2(240, 360)

func bind_run_state(value: RunState) -> void:
	run_state = value
	$PlayerMarker.position = player_position
	var building := ContentLibrary.get_building("mart_01")
	$BuildingMarker.position = Vector2(building["outdoor_position"]["x"], building["outdoor_position"]["y"])

func _process(delta: float) -> void:
	if run_state == null:
		return
	simulate_seconds(delta)
	var axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_position += axis * run_state.move_speed * delta
	$PlayerMarker.position = player_position
	var is_near_building := player_position.distance_to($BuildingMarker.position) < 64.0
	$CanvasLayer/HintLabel.text = "Press E to enter" if is_near_building else "Move with WASD"
	if is_near_building and Input.is_action_just_pressed("enter_building"):
		try_enter_building("mart_01")

func simulate_seconds(seconds_elapsed: float) -> void:
	seconds_buffer += seconds_elapsed
	var full_minutes := int(floor(seconds_buffer))
	if full_minutes <= 0:
		return
	seconds_buffer -= float(full_minutes)
	run_state.advance_minutes(full_minutes)
	run_state.exposure = exposure_model.drain(run_state.exposure, float(full_minutes), run_state.fatigue)

func try_enter_building(building_id: String) -> void:
	building_entered.emit(building_id)
```

```text
# game/scenes/outdoor/outdoor_mode.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/outdoor/outdoor_controller.gd" id="1_outdoor"]

[node name="OutdoorMode" type="Node2D"]
script = ExtResource("1_outdoor")

[node name="PlayerMarker" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-12, -12, 12, -12, 0, 14)
color = Color(0.85, 0.85, 0.85, 1)

[node name="BuildingMarker" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-18, -18, 18, -18, 18, 18, -18, 18)
color = Color(0.45, 0.7, 0.45, 1)

[node name="CanvasLayer" type="CanvasLayer" parent="."]

[node name="HintLabel" type="Label" parent="CanvasLayer"]
offset_left = 16.0
offset_top = 120.0
text = "Move with WASD"
```

```gdscript
# game/scripts/run/run_controller.gd
extends Control
class_name RunController

var run_state: RunState
var indoor_director := IndoorDirector.new()
var indoor_resolver := IndoorActionResolver.new()

func start_new_run(payload: Dictionary) -> void:
	run_state = RunState.from_survivor_config(payload)
	show_outdoor()

func show_outdoor() -> void:
	_clear_mode_host()
	run_state.current_mode = "outdoor"
	var outdoor_mode := preload("res://scenes/outdoor/outdoor_mode.tscn").instantiate()
	$ModeHost.add_child(outdoor_mode)
	outdoor_mode.bind_run_state(run_state)
	outdoor_mode.building_entered.connect(_show_indoor)
	$Hud.render(run_state)

func _show_indoor(building_id: String) -> void:
	_clear_mode_host()
	run_state.current_mode = "indoor"
	run_state.current_building_id = building_id
	var indoor_mode := preload("res://scenes/indoor/indoor_mode.tscn").instantiate()
	$ModeHost.add_child(indoor_mode)
	indoor_mode.render_view(indoor_director.open_building(building_id), run_state)
	$Hud.render(run_state)

func _process(_delta: float) -> void:
	if run_state != null:
		$Hud.render(run_state)
		if run_state.is_dead():
			_clear_mode_host()

func _clear_mode_host() -> void:
	for child in $ModeHost.get_children():
		child.queue_free()
```

- [ ] **Step 4: Re-run the outdoor test and verify shared-time conversion works**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
```

Expected: PASS with `OUTDOOR_CONTROLLER_OK`

- [ ] **Step 5: Commit the outdoor traversal prototype**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/scenes/outdoor/outdoor_mode.tscn game/scripts/outdoor/outdoor_controller.gd game/scripts/outdoor/exposure_model.gd game/tests/unit/test_outdoor_controller.gd game/scripts/run/run_controller.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add outdoor traversal prototype"
```

### Task 7: Verify the first playable loop end to end

**Files:**
- Create: `game/tests/smoke/test_first_playable_loop.gd`
- Modify: `game/scripts/menus/survivor_creator.gd`
- Modify: `game/scripts/bootstrap/main.gd`
- Modify: `game/scripts/run/run_controller.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Write a failing end-to-end smoke test that exercises the whole prototype loop**

```gdscript
# game/tests/smoke/test_first_playable_loop.gd
extends "res://tests/support/test_case.gd"

func _initialize() -> void:
	var run_shell := preload("res://scenes/run/run_shell.tscn").instantiate()
	root.add_child(run_shell)
	run_shell.start_new_run({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete", "unlucky"]),
		"remaining_points": 0
	})
	await process_frame
	var outdoor_mode := run_shell.get_node("ModeHost").get_child(0)
	outdoor_mode.simulate_seconds(120.0)
	outdoor_mode.try_enter_building("mart_01")
	await process_frame
	assert_eq(run_shell.run_state.current_mode, "indoor", "Entering a building should swap to indoor mode")
	assert_true(run_shell.run_state.clock.minute_of_day > 480, "Outdoor travel should spend shared time")
	run_shell.resolve_first_indoor_action()
	assert_true(run_shell.run_state.inventory.items.size() >= 1, "Indoor search should add loot before the loop ends")
	pass("FIRST_PLAYABLE_LOOP_OK")
```

- [ ] **Step 2: Run the smoke test and verify it fails because the run shell does not expose the helper methods yet**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected: FAIL with an unknown method error for `resolve_first_indoor_action`

- [ ] **Step 3: Add the missing integration hooks and final scene transitions**

```gdscript
# game/scripts/menus/survivor_creator.gd
extends Control

signal survivor_confirmed(payload: Dictionary)

var content_library: ContentLibrary
var selected_job_id := ""
var selected_trait_ids: PackedStringArray = PackedStringArray()

func _ready() -> void:
	if content_library == null:
		content_library = ContentLibrary
	$MarginContainer/VBoxContainer/JobButtons/CourierButton.pressed.connect(func() -> void: select_job("courier"))
	$MarginContainer/VBoxContainer/JobButtons/ClerkButton.pressed.connect(func() -> void: select_job("clerk"))
	$MarginContainer/VBoxContainer/TraitButtons/AthleteButton.pressed.connect(func() -> void: toggle_trait("athlete"))
	$MarginContainer/VBoxContainer/TraitButtons/LightSleeperButton.pressed.connect(func() -> void: toggle_trait("light_sleeper"))
	$MarginContainer/VBoxContainer/TraitButtons/UnluckyButton.pressed.connect(func() -> void: toggle_trait("unlucky"))
	$MarginContainer/VBoxContainer/TraitButtons/HeavySleeperButton.pressed.connect(func() -> void: toggle_trait("heavy_sleeper"))
	$MarginContainer/VBoxContainer/ConfirmButton.pressed.connect(confirm_selection)
	_refresh_summary()

func select_job(job_id: String) -> void:
	selected_job_id = job_id
	_refresh_summary()

func toggle_trait(trait_id: String) -> void:
	if selected_trait_ids.has(trait_id):
		selected_trait_ids.erase(trait_id)
	else:
		selected_trait_ids.append(trait_id)
	_refresh_summary()

func remaining_points() -> int:
	var total := 0
	for trait_id in selected_trait_ids:
		total += int(content_library.get_trait(trait_id).get("cost", 0))
	return total

func build_payload() -> Dictionary:
	return {
		"job_id": selected_job_id,
		"trait_ids": selected_trait_ids.duplicate(),
		"remaining_points": remaining_points()
	}

func confirm_selection() -> void:
	if selected_job_id == "" or remaining_points() < 0:
		return
	survivor_confirmed.emit(build_payload())

func _refresh_summary() -> void:
	if not has_node("MarginContainer/VBoxContainer/SummaryLabel"):
		return
	$MarginContainer/VBoxContainer/SummaryLabel.text = "Job: %s | Points: %d" % [selected_job_id, remaining_points()]
```

```gdscript
# game/scripts/bootstrap/main.gd
extends Node

func _ready() -> void:
	name = "Main"
	_ensure_input_actions()
	AppRouter.attach_host(self)
	AppRouter.show_title()
	await get_tree().process_frame
	_connect_current_scene()

func _ensure_input_actions() -> void:
	_bind_key("move_up", KEY_W)
	_bind_key("move_down", KEY_S)
	_bind_key("move_left", KEY_A)
	_bind_key("move_right", KEY_D)
	_bind_key("enter_building", KEY_E)

func _bind_key(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventKey and existing.physical_keycode == keycode:
			return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)

func _connect_current_scene() -> void:
	if get_child_count() == 0:
		return
	var current := get_child(0)
	if current.has_signal("start_requested"):
		current.start_requested.connect(_on_start_requested)
	if current.has_signal("survivor_confirmed"):
		current.survivor_confirmed.connect(_on_survivor_confirmed)

func _on_start_requested() -> void:
	AppRouter.show_survivor_creator()
	await get_tree().process_frame
	_connect_current_scene()

func _on_survivor_confirmed(payload: Dictionary) -> void:
	AppRouter.show_run_shell(payload)
```

```gdscript
# game/scripts/run/run_controller.gd
extends Control
class_name RunController

var run_state: RunState
var indoor_director := IndoorDirector.new()
var indoor_resolver := IndoorActionResolver.new()
var current_indoor_view: Dictionary = {}

func start_new_run(payload: Dictionary) -> void:
	run_state = RunState.from_survivor_config(payload)
	show_outdoor()

func show_outdoor() -> void:
	_clear_mode_host()
	run_state.current_mode = "outdoor"
	var outdoor_mode := preload("res://scenes/outdoor/outdoor_mode.tscn").instantiate()
	$ModeHost.add_child(outdoor_mode)
	outdoor_mode.bind_run_state(run_state)
	outdoor_mode.building_entered.connect(_show_indoor)
	$Hud.render(run_state)

func _show_indoor(building_id: String) -> void:
	_clear_mode_host()
	run_state.current_mode = "indoor"
	run_state.current_building_id = building_id
	current_indoor_view = indoor_director.open_building(building_id)
	var indoor_mode := preload("res://scenes/indoor/indoor_mode.tscn").instantiate()
	$ModeHost.add_child(indoor_mode)
	indoor_mode.render_view(current_indoor_view, run_state)
	indoor_mode.action_requested.connect(_on_indoor_action_requested)
	$Hud.render(run_state)

func resolve_first_indoor_action() -> void:
	if current_indoor_view.is_empty():
		return
	_on_indoor_action_requested(current_indoor_view["actions"][0])

func _on_indoor_action_requested(action: Dictionary) -> void:
	indoor_resolver.apply_action(run_state, action)
	$Hud.render(run_state)

func _process(_delta: float) -> void:
	if run_state != null:
		$Hud.render(run_state)
		if run_state.is_dead():
			_clear_mode_host()

func _clear_mode_host() -> void:
	for child in $ModeHost.get_children():
		child.queue_free()
```

- [ ] **Step 4: Re-run the end-to-end smoke test and verify the first playable loop works**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected: PASS with `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 5: Commit the first playable loop**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/tests/smoke/test_first_playable_loop.gd game/scripts/menus/survivor_creator.gd game/scripts/bootstrap/main.gd game/scripts/run/run_controller.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: connect first playable prototype loop"
```

## Self-Review

Spec coverage check:

- Core gameplay spec requirements covered:
  - shared day clock: Tasks 4, 5, 6, 7
  - outdoor real-time traversal: Task 6
  - indoor text exploration: Task 5
  - job and trait survivor creation: Task 3
  - fatigue and sleep preview: Tasks 4 and 5
  - inventory and loot transfer: Tasks 4, 5, and 7
  - enter and leave buildings cleanly: Tasks 6 and 7
  - death path via health or exposure depletion: Task 6 baseline through `RunState.is_dead()`

Placeholder scan:

- No `TODO`, `TBD`, or deferred code markers remain in the task steps
- Every task names exact files and verification commands

Type consistency check:

- `RunState`, `IndoorDirector`, `IndoorActionResolver`, and `OutdoorController` use consistent names across all tasks
- `show_outdoor()` and `resolve_first_indoor_action()` are introduced before the final smoke test depends on them
