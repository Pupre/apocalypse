# Mode Transition Presentation Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make outdoor and indoor mode changes feel like distinct scene transitions through fade masking, mode-aware HUD presentation, and a full indoor-to-outdoor return loop.

**Architecture:** Keep `run_shell` as the persistent run owner, add one dedicated transition layer under it, and continue swapping active mode scenes inside `ModeHost`. The shell owns fade timing and HUD mode presentation; indoor mode only emits an explicit exit intent, while the shared `RunState` remains the single source of truth.

**Tech Stack:** Godot `4.4.1`, `GDScript`, `.tscn` scenes, headless Godot CLI verification on Linux

---

## File Structure

Commands below assume the Linux Godot binary already installed in this workspace.
Because this Codex sandbox cannot write to the default Godot user-data directory under `/home/muhyeon_shin/.local/share`, every headless verification command explicitly sets `XDG_DATA_HOME=/tmp/godot-data`.

```bash
/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64
```

Planned implementation files and responsibilities:

- `game/scenes/run/mode_transition_layer.tscn`: fullscreen fade layer owned by the run shell
- `game/scripts/run/mode_transition_presenter.gd`: fade-in and fade-out API for mode swaps
- `game/scenes/run/run_shell.tscn`: persistent host for HUD, transition layer, and `ModeHost`
- `game/scripts/run/run_controller.gd`: asynchronous mode switching, fade orchestration, and indoor exit handling
- `game/scenes/run/hud.tscn`: shared HUD layout whose panel presentation changes by mode
- `game/scripts/run/hud_presenter.gd`: bind `RunState` values and apply indoor/outdoor presentation presets
- `game/scenes/indoor/indoor_mode.tscn`: indoor reading surface plus explicit exit button
- `game/scripts/indoor/indoor_mode.gd`: emit `exit_requested` and continue rendering indoor actions
- `game/tests/unit/test_mode_transition_presenter.gd`: verify fade layer alpha changes deterministically
- `game/tests/unit/test_hud_presenter.gd`: verify shared HUD switches between outdoor and indoor presets
- `game/tests/unit/test_indoor_mode.gd`: verify indoor mode emits exit requests and exposes the dedicated reading surface
- `game/tests/smoke/test_first_playable_loop.gd`: verify enter-building and leave-building round-trip through the shell

### Task 1: Add a dedicated run-shell transition layer

**Files:**
- Create: `game/scenes/run/mode_transition_layer.tscn`
- Create: `game/scripts/run/mode_transition_presenter.gd`
- Create: `game/tests/unit/test_mode_transition_presenter.gd`
- Test: `game/tests/unit/test_mode_transition_presenter.gd`

- [ ] **Step 1: Write a failing unit test for the missing transition layer**

```gdscript
# game/tests/unit/test_mode_transition_presenter.gd
extends "res://tests/support/test_case.gd"

const TRANSITION_LAYER_SCENE_PATH := "res://scenes/run/mode_transition_layer.tscn"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var transition_scene := load(TRANSITION_LAYER_SCENE_PATH) as PackedScene
	if not assert_true(transition_scene != null, "Missing transition layer scene: %s" % TRANSITION_LAYER_SCENE_PATH):
		return

	var transition_layer = transition_scene.instantiate()
	if not assert_true(transition_layer != null, "Transition layer should instantiate."):
		return

	root.add_child(transition_layer)

	if not assert_true(transition_layer.has_method("set_duration_for_tests"), "Transition layer should expose set_duration_for_tests()."):
		transition_layer.free()
		return
	if not assert_true(transition_layer.has_method("fade_out"), "Transition layer should expose fade_out()."):
		transition_layer.free()
		return
	if not assert_true(transition_layer.has_method("fade_in"), "Transition layer should expose fade_in()."):
		transition_layer.free()
		return

	transition_layer.set_duration_for_tests(0.0)
	await transition_layer.fade_out()

	var fade_rect := transition_layer.get_node_or_null("FadeRect") as ColorRect
	if not assert_true(fade_rect != null, "Transition layer should expose a FadeRect node."):
		transition_layer.free()
		return
	assert_eq(fade_rect.color.a, 1.0, "fade_out() should leave the overlay fully opaque.")

	await transition_layer.fade_in()
	assert_eq(fade_rect.color.a, 0.0, "fade_in() should restore the overlay to transparent.")

	transition_layer.free()
	pass_test("MODE_TRANSITION_PRESENTER_OK")
```

- [ ] **Step 2: Run the unit test and verify it fails because the scene does not exist yet**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_mode_transition_presenter.gd
```

Expected: FAIL with `Missing transition layer scene`

- [ ] **Step 3: Add the transition layer scene and fade presenter**

```text
# game/scenes/run/mode_transition_layer.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/run/mode_transition_presenter.gd" id="1"]

[node name="ModeTransitionLayer" type="CanvasLayer"]
layer = 20
script = ExtResource("1")

[node name="FadeRect" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
color = Color(0, 0, 0, 0)
```

```gdscript
# game/scripts/run/mode_transition_presenter.gd
extends CanvasLayer

@export var fade_duration := 0.25

var _fade_rect: ColorRect = null


func _ready() -> void:
	_fade_rect = get_node_or_null("FadeRect") as ColorRect
	_set_alpha(0.0)


func set_duration_for_tests(seconds: float) -> void:
	fade_duration = maxf(seconds, 0.0)


func fade_out() -> void:
	await _fade_to(1.0)


func fade_in() -> void:
	await _fade_to(0.0)


func _fade_to(target_alpha: float) -> void:
	if _fade_rect == null:
		return

	if fade_duration <= 0.0:
		_set_alpha(target_alpha)
		await get_tree().process_frame
		return

	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", target_alpha, fade_duration)
	await tween.finished


func _set_alpha(alpha: float) -> void:
	if _fade_rect == null:
		return
	_fade_rect.color = Color(_fade_rect.color.r, _fade_rect.color.g, _fade_rect.color.b, alpha)
```

- [ ] **Step 4: Re-run the unit test and verify the fade layer works**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_mode_transition_presenter.gd
```

Expected: PASS with `MODE_TRANSITION_PRESENTER_OK`

- [ ] **Step 5: Commit the transition-layer baseline**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/scenes/run/mode_transition_layer.tscn game/scripts/run/mode_transition_presenter.gd game/tests/unit/test_mode_transition_presenter.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add run mode transition layer"
```

### Task 2: Apply mode-aware HUD presentation and fade-masked shell switching

**Files:**
- Modify: `game/scenes/run/run_shell.tscn`
- Modify: `game/scenes/run/hud.tscn`
- Modify: `game/scripts/run/run_controller.gd`
- Modify: `game/scripts/run/hud_presenter.gd`
- Create: `game/tests/unit/test_hud_presenter.gd`
- Test: `game/tests/unit/test_hud_presenter.gd`

- [ ] **Step 1: Write a failing HUD presenter test for mode-specific layout changes**

```gdscript
# game/tests/unit/test_hud_presenter.gd
extends "res://tests/support/test_case.gd"

const HUD_SCENE_PATH := "res://scenes/run/hud.tscn"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var hud_scene := load(HUD_SCENE_PATH) as PackedScene
	if not assert_true(hud_scene != null, "Missing HUD scene: %s" % HUD_SCENE_PATH):
		return

	var hud = hud_scene.instantiate()
	if not assert_true(hud != null, "HUD should instantiate."):
		return

	root.add_child(hud)

	if not assert_true(hud.has_method("set_mode_presentation"), "HUD should expose set_mode_presentation()."):
		hud.free()
		return

	var panel := hud.get_node_or_null("Panel") as PanelContainer
	var title_label := hud.get_node_or_null("Panel/VBox/TitleLabel") as Label
	if not assert_true(panel != null, "HUD should expose Panel."):
		hud.free()
		return
	if not assert_true(title_label != null, "HUD should expose TitleLabel."):
		hud.free()
		return

	hud.set_mode_presentation("outdoor")
	var outdoor_width := panel.offset_right - panel.offset_left
	assert_eq(title_label.text, "외부 생존 정보", "Outdoor mode should use the outdoor HUD title.")

	hud.set_mode_presentation("indoor")
	var indoor_width := panel.offset_right - panel.offset_left
	assert_eq(title_label.text, "실내 생존 정보", "Indoor mode should use the indoor HUD title.")
	assert_true(indoor_width < outdoor_width, "Indoor HUD should be visually narrower than outdoor HUD.")
	assert_true(panel.modulate.a < 1.0, "Indoor HUD should feel more subdued than outdoor HUD.")

	hud.free()
	pass_test("HUD_PRESENTATION_OK")
```

- [ ] **Step 2: Run the HUD test and verify it fails because the presenter does not support modes yet**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_hud_presenter.gd
```

Expected: FAIL with `HUD should expose set_mode_presentation()`

- [ ] **Step 3: Mount the transition layer in the shell, add HUD mode presets, and wire the controller through fade-out -> swap -> fade-in**

```text
# game/scenes/run/run_shell.tscn
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/run/run_controller.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/run/hud.tscn" id="2"]
[ext_resource type="PackedScene" path="res://scenes/run/mode_transition_layer.tscn" id="3"]

[node name="RunShell" type="Node"]
script = ExtResource("1")

[node name="HUD" parent="." instance=ExtResource("2")]

[node name="TransitionLayer" parent="." instance=ExtResource("3")]

[node name="ModeHost" type="Node" parent="."]
```

```text
# game/scenes/run/hud.tscn
[node name="Panel" type="PanelContainer" parent="."]
offset_left = 16.0
offset_top = 16.0
offset_right = 336.0
offset_bottom = 180.0
modulate = Color(1, 1, 1, 1)

[node name="TitleLabel" type="Label" parent="Panel/VBox"]
text = "외부 생존 정보"
```

```gdscript
# game/scripts/run/hud_presenter.gd
extends Control

const OUTDOOR_TITLE := "외부 생존 정보"
const INDOOR_TITLE := "실내 생존 정보"

var run_state = null
var _panel: PanelContainer = null
var _title_label: Label = null
var _clock_label: Label = null
var _fatigue_label: Label = null
var _hunger_label: Label = null
var _carry_label: Label = null


func set_run_state(state) -> void:
	run_state = state
	refresh()


func set_mode_presentation(mode_name: String) -> void:
	_cache_nodes()
	if _panel == null or _title_label == null:
		return

	if mode_name == "indoor":
		_panel.offset_left = 24.0
		_panel.offset_top = 20.0
		_panel.offset_right = 272.0
		_panel.offset_bottom = 156.0
		_panel.modulate = Color(1, 1, 1, 0.9)
		_title_label.text = INDOOR_TITLE
		return

	_panel.offset_left = 16.0
	_panel.offset_top = 16.0
	_panel.offset_right = 336.0
	_panel.offset_bottom = 180.0
	_panel.modulate = Color(1, 1, 1, 1.0)
	_title_label.text = OUTDOOR_TITLE
```

```gdscript
# game/scripts/run/run_controller.gd
extends Node

const OUTDOOR_MODE_SCENE := preload("res://scenes/outdoor/outdoor_mode.tscn")
const INDOOR_MODE_SCENE := preload("res://scenes/indoor/indoor_mode.tscn")
const RUN_STATE_SCRIPT := preload("res://scripts/run/run_state.gd")

var run_state = null
var _hud_presenter: Node = null
var _transition_layer: Node = null
var _mode_host: Node = null
var _current_mode_name := ""
var _current_building_id := "mart_01"
var _transition_in_progress := false


func start_run(survivor_config: Dictionary, building_id: String = "mart_01") -> void:
	run_state = RUN_STATE_SCRIPT.from_survivor_config(survivor_config)
	if run_state == null:
		push_error("RunController could not create a run state.")
		return

	_hud_presenter = get_node_or_null("HUD")
	_transition_layer = get_node_or_null("TransitionLayer")
	_mode_host = get_node_or_null("ModeHost")
	_current_building_id = building_id

	if _hud_presenter != null and _hud_presenter.has_method("set_run_state"):
		_hud_presenter.set_run_state(run_state)
	if _hud_presenter != null and _hud_presenter.has_method("set_mode_presentation"):
		_hud_presenter.set_mode_presentation("outdoor")

	_show_outdoor_mode(building_id)
	_refresh_hud()


func _on_building_entered(building_id: String) -> void:
	await _transition_to_mode("indoor", building_id)


func _transition_to_mode(mode_name: String, building_id: String) -> void:
	if _transition_in_progress:
		return
	_transition_in_progress = true

	if _transition_layer != null and _transition_layer.has_method("fade_out"):
		await _transition_layer.fade_out()

	if mode_name == "indoor":
		_show_indoor_mode(building_id)
	else:
		_show_outdoor_mode(building_id)

	if _hud_presenter != null and _hud_presenter.has_method("set_mode_presentation"):
		_hud_presenter.set_mode_presentation(mode_name)
	_refresh_hud()

	if _transition_layer != null and _transition_layer.has_method("fade_in"):
		await _transition_layer.fade_in()

	_transition_in_progress = false
```

- [ ] **Step 4: Re-run the HUD presenter test and verify the shared HUD now changes by mode**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_hud_presenter.gd
```

Expected: PASS with `HUD_PRESENTATION_OK`

- [ ] **Step 5: Commit the shell transition wiring**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/scenes/run/run_shell.tscn game/scenes/run/hud.tscn game/scripts/run/run_controller.gd game/scripts/run/hud_presenter.gd game/tests/unit/test_hud_presenter.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add mode-aware run shell transitions"
```

### Task 3: Strengthen the indoor reading surface and add explicit building exit

**Files:**
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scripts/run/run_controller.gd`
- Create: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Write a failing indoor mode test for the missing exit button and signal**

```gdscript
# game/tests/unit/test_indoor_mode.gd
extends "res://tests/support/test_case.gd"

const INDOOR_MODE_SCENE_PATH := "res://scenes/indoor/indoor_mode.tscn"

var _exit_requested_count := 0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var indoor_scene := load(INDOOR_MODE_SCENE_PATH) as PackedScene
	if not assert_true(indoor_scene != null, "Missing indoor mode scene: %s" % INDOOR_MODE_SCENE_PATH):
		return

	var indoor_mode = indoor_scene.instantiate()
	if not assert_true(indoor_mode != null, "Indoor mode should instantiate."):
		return

	root.add_child(indoor_mode)

	if not assert_true(indoor_mode.has_signal("exit_requested"), "Indoor mode should emit exit_requested."):
		indoor_mode.free()
		return

	indoor_mode.exit_requested.connect(Callable(self, "_on_exit_requested"))

	var exit_button := indoor_mode.get_node_or_null("Panel/VBox/Header/ExitButton") as Button
	if not assert_true(exit_button != null, "Indoor mode should expose an ExitButton."):
		indoor_mode.free()
		return

	var backdrop := indoor_mode.get_node_or_null("Backdrop") as ColorRect
	if not assert_true(backdrop != null, "Indoor mode should expose a Backdrop node for the reading surface."):
		indoor_mode.free()
		return

	exit_button.emit_signal("pressed")
	assert_eq(_exit_requested_count, 1, "Pressing ExitButton should emit exit_requested exactly once.")

	indoor_mode.free()
	pass_test("INDOOR_MODE_OK")


func _on_exit_requested() -> void:
	_exit_requested_count += 1
```

- [ ] **Step 2: Run the indoor mode test and verify it fails because the exit affordance does not exist yet**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
```

Expected: FAIL with `Indoor mode should emit exit_requested`

- [ ] **Step 3: Add the indoor backdrop, explicit exit button, and hook the shell back to outdoor mode**

```text
# game/scenes/indoor/indoor_mode.tscn
[node name="IndoorMode" type="Control"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Backdrop" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.08, 0.08, 0.08, 0.92)

[node name="Panel" type="PanelContainer" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 64.0
offset_top = 48.0
offset_right = -64.0
offset_bottom = -48.0

[node name="Header" type="HBoxContainer" parent="Panel/VBox"]
theme_override_constants/separation = 12

[node name="TitleLabel" type="Label" parent="Panel/VBox/Header"]
size_flags_horizontal = 3
text = "실내"

[node name="ExitButton" type="Button" parent="Panel/VBox/Header"]
text = "건물 밖으로"
```

```gdscript
# game/scripts/indoor/indoor_mode.gd
extends Control

signal state_changed
signal exit_requested

var _director: Node = null
var _title_label: Label = null
var _summary_label: Label = null
var _sleep_preview_label: Label = null
var _result_label: Label = null
var _clue_list: VBoxContainer = null
var _action_buttons: VBoxContainer = null
var _exit_button: Button = null
var _director_connected := false


func _ready() -> void:
	_cache_nodes()
	_bind_director()
	if _exit_button != null and not _exit_button.pressed.is_connected(Callable(self, "_on_exit_pressed")):
		_exit_button.pressed.connect(Callable(self, "_on_exit_pressed"))


func _on_exit_pressed() -> void:
	exit_requested.emit()


func _cache_nodes() -> void:
	_director = get_node_or_null("Director")
	_title_label = get_node_or_null("Panel/VBox/Header/TitleLabel") as Label
	_summary_label = get_node_or_null("Panel/VBox/SummaryLabel") as Label
	_sleep_preview_label = get_node_or_null("Panel/VBox/SleepPreviewLabel") as Label
	_result_label = get_node_or_null("Panel/VBox/ResultLabel") as Label
	_clue_list = get_node_or_null("Panel/VBox/ClueList") as VBoxContainer
	_action_buttons = get_node_or_null("Panel/VBox/ActionButtons") as VBoxContainer
	_exit_button = get_node_or_null("Panel/VBox/Header/ExitButton") as Button
```

```gdscript
# game/scripts/run/run_controller.gd
func _show_indoor_mode(building_id: String) -> void:
	if _mode_host == null:
		push_error("RunController is missing the mode host.")
		return

	_current_building_id = building_id
	for child in _mode_host.get_children():
		child.queue_free()

	var indoor_mode := INDOOR_MODE_SCENE.instantiate()
	_mode_host.add_child(indoor_mode)

	if indoor_mode.has_signal("state_changed"):
		indoor_mode.state_changed.connect(Callable(self, "_on_indoor_state_changed"))
	if indoor_mode.has_signal("exit_requested"):
		indoor_mode.exit_requested.connect(Callable(self, "_on_indoor_exit_requested"))
	if indoor_mode.has_method("configure"):
		indoor_mode.configure(run_state, building_id)
	_current_mode_name = "indoor"


func _on_indoor_exit_requested() -> void:
	await _transition_to_mode("outdoor", _current_building_id)
```

- [ ] **Step 4: Re-run the indoor mode test and verify the explicit exit affordance works**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
```

Expected: PASS with `INDOOR_MODE_OK`

- [ ] **Step 5: Commit the indoor presentation pass**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/scenes/indoor/indoor_mode.tscn game/scripts/indoor/indoor_mode.gd game/scripts/run/run_controller.gd game/tests/unit/test_indoor_mode.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: add indoor exit presentation"
```

### Task 4: Extend the smoke loop to cover enter and leave transitions

**Files:**
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Expand the smoke test to assert the full round-trip and resting transition state**

```gdscript
# game/tests/smoke/test_first_playable_loop.gd
var transition_layer: Node = run_shell.get_node_or_null("TransitionLayer")
if not assert_true(transition_layer != null, "Run shell should mount the transition layer."):
	bootstrap.free()
	return

if transition_layer.has_method("set_duration_for_tests"):
	transition_layer.set_duration_for_tests(0.0)

outdoor_mode.try_enter_building("mart_01")
await process_frame
await process_frame

assert_eq(run_shell.get_current_mode_name(), "indoor", "Entering the building should swap the run shell to indoor mode.")

var hud_title_label := hud.get_node_or_null("Panel/VBox/TitleLabel") as Label
if not assert_true(hud_title_label != null, "HUD title label should be present."):
	bootstrap.free()
	return
assert_eq(hud_title_label.text, "실내 생존 정보", "Indoor mode should switch the shared HUD presentation.")

var fade_rect := transition_layer.get_node_or_null("FadeRect") as ColorRect
if not assert_true(fade_rect != null, "Transition layer should expose FadeRect."):
	bootstrap.free()
	return
assert_eq(fade_rect.color.a, 0.0, "The transition layer should end transparent after entering a building.")

var exit_button := indoor_mode.get_node_or_null("Panel/VBox/Header/ExitButton") as Button
if not assert_true(exit_button != null, "Indoor mode should expose an exit button."):
	bootstrap.free()
	return

exit_button.emit_signal("pressed")
await process_frame
await process_frame

assert_eq(run_shell.get_current_mode_name(), "outdoor", "Leaving the building should return the run shell to outdoor mode.")
assert_eq(hud_title_label.text, "외부 생존 정보", "Returning outside should restore the outdoor HUD presentation.")
assert_true(run_shell.get_node_or_null("ModeHost/OutdoorMode") != null, "Outdoor mode should be remounted after exit.")
assert_eq(fade_rect.color.a, 0.0, "The transition layer should end transparent after leaving the building.")
```

- [ ] **Step 2: Run the smoke test and verify it fails until the round-trip behavior is complete**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected: FAIL on the first missing transition or exit assertion

- [ ] **Step 3: Finish any remaining shell wiring required by the smoke test and run the focused verification set**

```gdscript
# game/scripts/run/run_controller.gd
func _show_outdoor_mode(building_id: String) -> void:
	if _mode_host == null:
		push_error("RunController is missing the mode host.")
		return

	_current_building_id = building_id
	for child in _mode_host.get_children():
		child.queue_free()

	var outdoor_mode := OUTDOOR_MODE_SCENE.instantiate()
	_mode_host.add_child(outdoor_mode)

	if outdoor_mode.has_signal("state_changed"):
		outdoor_mode.state_changed.connect(Callable(self, "_on_mode_state_changed"))
	if outdoor_mode.has_signal("building_entered"):
		outdoor_mode.building_entered.connect(Callable(self, "_on_building_entered"))
	if outdoor_mode.has_method("bind_run_state"):
		outdoor_mode.bind_run_state(run_state, building_id)
	_current_mode_name = "outdoor"
```

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_mode_transition_presenter.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_hud_presenter.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `MODE_TRANSITION_PRESENTER_OK`
- `HUD_PRESENTATION_OK`
- `INDOOR_MODE_OK`
- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 4: Run the existing regression checks that touch the same shell and indoor flow**

Run:

```bash
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_actions.gd
XDG_DATA_HOME=/tmp/godot-data /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
```

Expected:

- `INDOOR_ACTIONS_OK`
- `OUTDOOR_CONTROLLER_OK`

- [ ] **Step 5: Commit the end-to-end transition polish**

```bash
git -C /home/muhyeon_shin/packages/apocalypse add game/tests/smoke/test_first_playable_loop.gd game/scripts/run/run_controller.gd
git -C /home/muhyeon_shin/packages/apocalypse commit -m "feat: polish indoor outdoor mode transitions"
```

## Self-Review Checklist

- Spec coverage:
  - fade-masked mode switching: Task 1 and Task 2
  - shared HUD with mode-specific feel: Task 2
  - stronger indoor reading space: Task 3
  - indoor-to-outdoor return path: Task 3 and Task 4
  - end-to-end acceptance criteria: Task 4
- Placeholder scan: no `TODO`, `TBD`, or implied follow-up steps remain in the plan
- Type consistency:
  - transition API uses `fade_out()`, `fade_in()`, and `set_duration_for_tests()`
  - HUD API uses `set_mode_presentation(mode_name: String)`
  - indoor return path uses `exit_requested`

