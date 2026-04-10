# Portrait Phase 1 Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reframe the current build so launching the game immediately reads as a portrait-authored mobile survival game while preserving the existing survival, crafting, codex, indoor memory, and persistence systems.

**Architecture:** Keep the current `RunController`, `RunState`, `OutdoorController`, `IndoorMode`, and `SurvivalSheet` gameplay logic in place. Change the presentation shell in four passes: lock the portrait contract with tests, convert the shared HUD and project baseline, convert the outdoor shell to a portrait top-ribbon plus forward-biased camera, then convert the indoor reading surface from the old horizontal split into a one-column portrait stack.

**Tech Stack:** Godot 4.4.1, GDScript, TSCN scenes, existing `RunController` / `OutdoorController` / `IndoorDirector` / `SurvivalSheet`, headless Godot test scripts

---

## File Map

### Modify

- `game/project.godot`
- `game/scenes/run/hud.tscn`
- `game/scripts/run/hud_presenter.gd`
- `game/scenes/outdoor/outdoor_mode.tscn`
- `game/scripts/outdoor/outdoor_controller.gd`
- `game/scenes/indoor/indoor_mode.tscn`
- `game/scripts/indoor/indoor_mode.gd`
- `game/tests/unit/test_hud_presenter.gd`
- `game/tests/unit/test_outdoor_controller.gd`
- `game/tests/unit/test_shared_crafting_sheet.gd`
- `game/tests/unit/test_indoor_mode.gd`
- `game/tests/unit/test_survivor_creator.gd`
- `game/tests/unit/test_run_controller_live_transition.gd`
- `game/tests/smoke/test_first_playable_loop.gd`

### Responsibilities

- `game/project.godot`
  - Set the portrait baseline viewport and stretch policy used by every scene.
- `game/scenes/run/hud.tscn` / `game/scripts/run/hud_presenter.gd`
  - Replace the old right-side slab with a shallow top ribbon used outdoors.
- `game/scenes/outdoor/outdoor_mode.tscn` / `game/scripts/outdoor/outdoor_controller.gd`
  - Replace the world-attached-looking status slab with a portrait overlay ribbon.
  - Bias the outdoor camera so the player sits below center while world movement stays continuous.
- `game/scenes/indoor/indoor_mode.tscn` / `game/scripts/indoor/indoor_mode.gd`
  - Remove the old `ContextRow` horizontal split from the indoor main surface.
  - Rebuild the indoor stack so `ReadingCard` and `MiniMapCard` sit in one portrait column above the action list.
  - Keep `SurvivalSheet` as the inventory/craft/codex bottom sheet.
- tests
  - Update contracts so they prove the portrait shell is real instead of just visually implied.

---

### Task 1: Lock The Portrait Baseline And Shared HUD

**Files:**
- Modify: `game/tests/unit/test_hud_presenter.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Modify: `game/project.godot`
- Modify: `game/scenes/run/hud.tscn`
- Modify: `game/scripts/run/hud_presenter.gd`

- [ ] **Step 1: Write the failing HUD and portrait-baseline assertions**

Update `game/tests/unit/test_hud_presenter.gd` so it targets the new top ribbon contract instead of the old right-edge panel:

```gdscript
	var top_ribbon := hud.get_node_or_null("TopRibbon") as PanelContainer
	var title_label := hud.get_node_or_null("TopRibbon/Margin/Stack/HeaderRow/TitleLabel") as Label
	var clock_label := hud.get_node_or_null("TopRibbon/Margin/Stack/HeaderRow/ClockLabel") as Label
	var fatigue_label := hud.get_node_or_null("TopRibbon/Margin/Stack/StatsRow/FatigueLabel") as Label
	var hunger_label := hud.get_node_or_null("TopRibbon/Margin/Stack/StatsRow/HungerLabel") as Label
	var thirst_label := hud.get_node_or_null("TopRibbon/Margin/Stack/StatsRow/ThirstLabel") as Label
	var health_label := hud.get_node_or_null("TopRibbon/Margin/Stack/StatsRow/HealthLabel") as Label
	var carry_label := hud.get_node_or_null("TopRibbon/Margin/Stack/StatsRow/CarryLabel") as Label
	if not assert_true(top_ribbon != null, "HUD should expose a TopRibbon panel in portrait mode."):
		hud.free()
		return
	if not assert_true(title_label != null and clock_label != null and fatigue_label != null and hunger_label != null and thirst_label != null and health_label != null and carry_label != null, "Portrait HUD should expose header-row and stats-row labels."):
		hud.free()
		return

	hud.set_mode_presentation("outdoor")
	assert_eq(top_ribbon.anchor_left, 0.0, "Portrait HUD should anchor from the left edge.")
	assert_eq(top_ribbon.anchor_right, 1.0, "Portrait HUD should stretch across the screen width.")
	assert_eq(top_ribbon.offset_left, 12.0, "Portrait HUD should keep a 12px left margin.")
	assert_eq(top_ribbon.offset_top, 12.0, "Portrait HUD should stay near the top edge.")
	assert_eq(top_ribbon.offset_right, -12.0, "Portrait HUD should keep a 12px right margin.")
	assert_eq(top_ribbon.offset_bottom, 116.0, "Portrait HUD should stay shallow instead of occupying a tall side slab.")
```

Add portrait project-setting expectations near the top of `game/tests/smoke/test_first_playable_loop.gd`:

```gdscript
	assert_eq(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)),
		720,
		"The portrait shell should lock the canonical viewport width to 720."
	)
	assert_eq(
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)),
		1280,
		"The portrait shell should lock the canonical viewport height to 1280."
	)
```

- [ ] **Step 2: Run the focused tests and verify they fail against the current landscape HUD**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_hud_presenter.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `test_hud_presenter.gd` fails because `TopRibbon` and its portrait node paths do not exist yet.
- `test_first_playable_loop.gd` fails because the project has no portrait viewport settings yet.

- [ ] **Step 3: Add the portrait baseline and shared top ribbon**

Add the portrait window section to `game/project.godot`:

```ini
[display]

window/size/viewport_width=720
window/size/viewport_height=1280
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
```

Replace the current HUD scene body in `game/scenes/run/hud.tscn` with a shallow top ribbon:

```tscn
[node name="TopRibbon" type="PanelContainer" parent="."]
anchor_right = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = 116.0

[node name="Margin" type="MarginContainer" parent="TopRibbon"]
theme_override_constants/margin_left = 12
theme_override_constants/margin_top = 10
theme_override_constants/margin_right = 12
theme_override_constants/margin_bottom = 10

[node name="Stack" type="VBoxContainer" parent="TopRibbon/Margin"]
theme_override_constants/separation = 8

[node name="HeaderRow" type="HBoxContainer" parent="TopRibbon/Margin/Stack"]
[node name="TitleLabel" type="Label" parent="TopRibbon/Margin/Stack/HeaderRow"]
size_flags_horizontal = 3
text = "외부 생존 정보"
[node name="ClockLabel" type="Label" parent="TopRibbon/Margin/Stack/HeaderRow"]
horizontal_alignment = 2
text = "시각: --"

[node name="StatsRow" type="HBoxContainer" parent="TopRibbon/Margin/Stack"]
theme_override_constants/separation = 10
[node name="FatigueLabel" type="Label" parent="TopRibbon/Margin/Stack/StatsRow"]
text = "피로: --"
[node name="HungerLabel" type="Label" parent="TopRibbon/Margin/Stack/StatsRow"]
text = "허기: --"
[node name="ThirstLabel" type="Label" parent="TopRibbon/Margin/Stack/StatsRow"]
text = "갈증: --"
[node name="HealthLabel" type="Label" parent="TopRibbon/Margin/Stack/StatsRow"]
text = "체력: --"
[node name="CarryLabel" type="Label" parent="TopRibbon/Margin/Stack/StatsRow"]
text = "소지량: --"
```

Update `game/scripts/run/hud_presenter.gd` to cache the new paths and present the outdoor ribbon:

```gdscript
func set_mode_presentation(mode_name: String) -> void:
	_cache_nodes()
	if _panel == null or _title_label == null:
		return

	if mode_name == "indoor":
		visible = false
		return

	visible = true
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.offset_left = 12.0
	_panel.offset_top = 12.0
	_panel.offset_right = -12.0
	_panel.offset_bottom = 116.0
	_panel.modulate = Color(1, 1, 1, 1.0)
	_title_label.text = OUTDOOR_TITLE


func _cache_nodes() -> void:
	_panel = get_node_or_null("TopRibbon") as PanelContainer
	_title_label = get_node_or_null("TopRibbon/Margin/Stack/HeaderRow/TitleLabel") as Label
	_clock_label = get_node_or_null("TopRibbon/Margin/Stack/HeaderRow/ClockLabel") as Label
	_fatigue_label = get_node_or_null("TopRibbon/Margin/Stack/StatsRow/FatigueLabel") as Label
	_hunger_label = get_node_or_null("TopRibbon/Margin/Stack/StatsRow/HungerLabel") as Label
	_thirst_label = get_node_or_null("TopRibbon/Margin/Stack/StatsRow/ThirstLabel") as Label
	_health_label = get_node_or_null("TopRibbon/Margin/Stack/StatsRow/HealthLabel") as Label
	_carry_label = get_node_or_null("TopRibbon/Margin/Stack/StatsRow/CarryLabel") as Label
```

- [ ] **Step 4: Re-run the focused tests and verify they pass**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_hud_presenter.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `HUD_PRESENTATION_OK`
- `test_first_playable_loop.gd` still fails later on outdoor or indoor layout paths, but the new portrait viewport assertions pass. Stop at the first new layout failure and continue to Task 2.

- [ ] **Step 5: Commit**

```bash
git add game/project.godot game/scenes/run/hud.tscn game/scripts/run/hud_presenter.gd game/tests/unit/test_hud_presenter.gd game/tests/smoke/test_first_playable_loop.gd
git commit -m "feat: add portrait project baseline and shared hud ribbon"
```

---

### Task 2: Reframe Outdoor Mode For Portrait

**Files:**
- Modify: `game/scenes/outdoor/outdoor_mode.tscn`
- Modify: `game/scripts/outdoor/outdoor_controller.gd`
- Modify: `game/tests/unit/test_outdoor_controller.gd`
- Modify: `game/tests/unit/test_shared_crafting_sheet.gd`

- [ ] **Step 1: Write the failing outdoor portrait assertions**

Update `game/tests/unit/test_outdoor_controller.gd` to lock the portrait ribbon and forward-biased camera:

```gdscript
	var top_ribbon := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon") as PanelContainer
	var exposure_label := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/HeaderRow/ExposureLabel") as Label
	var hint_label := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/HintLabel") as Label
	var craft_button := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ToolsRow/CraftButton") as Button
	var codex_button := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ToolsRow/CodexButton") as Button
	var world_camera := outdoor_mode.get_node_or_null("WorldCamera") as Camera2D
	if not assert_true(top_ribbon != null and exposure_label != null and hint_label != null and craft_button != null and codex_button != null and world_camera != null, "Outdoor mode should expose a portrait top ribbon and camera."):
		outdoor_mode.free()
		return
	assert_eq(top_ribbon.anchor_left, 0.0, "Outdoor ribbon should start from the left edge.")
	assert_eq(top_ribbon.anchor_right, 1.0, "Outdoor ribbon should stretch across portrait width.")
	assert_true(world_camera.offset.y < 0.0, "Outdoor camera should sit ahead of the player in portrait mode.")
```

Update `game/tests/unit/test_shared_crafting_sheet.gd` so the outdoor shared-sheet buttons are pulled from the new ribbon paths:

```gdscript
	var outdoor_craft_button := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ToolsRow/CraftButton") as Button
	var outdoor_codex_button := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ToolsRow/CodexButton") as Button
```

- [ ] **Step 2: Run the outdoor tests and verify they fail**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_shared_crafting_sheet.gd
```

Expected:

- both tests fail because `CanvasLayer/TopRibbon/...` does not exist yet and `WorldCamera.offset` is still zero.

- [ ] **Step 3: Replace the outdoor slab with a portrait ribbon and camera offset**

Replace the old `StatusPanel` section in `game/scenes/outdoor/outdoor_mode.tscn` with a compact ribbon:

```tscn
[node name="TopRibbon" type="PanelContainer" parent="CanvasLayer"]
anchor_right = 1.0
offset_left = 16.0
offset_top = 16.0
offset_right = -16.0
offset_bottom = 152.0

[node name="Margin" type="MarginContainer" parent="CanvasLayer/TopRibbon"]
theme_override_constants/margin_left = 14
theme_override_constants/margin_top = 12
theme_override_constants/margin_right = 14
theme_override_constants/margin_bottom = 12

[node name="VBox" type="VBoxContainer" parent="CanvasLayer/TopRibbon/Margin"]
theme_override_constants/separation = 8

[node name="HeaderRow" type="HBoxContainer" parent="CanvasLayer/TopRibbon/Margin/VBox"]
[node name="TitleLabel" type="Label" parent="CanvasLayer/TopRibbon/Margin/VBox/HeaderRow"]
size_flags_horizontal = 3
text = "외부"
[node name="ExposureLabel" type="Label" parent="CanvasLayer/TopRibbon/Margin/VBox/HeaderRow"]
horizontal_alignment = 2
text = "노출: 100"

[node name="HintLabel" type="Label" parent="CanvasLayer/TopRibbon/Margin/VBox"]
autowrap_mode = 3
text = "WASD로 이동"

[node name="ToolsRow" type="HBoxContainer" parent="CanvasLayer/TopRibbon/Margin/VBox"]
theme_override_constants/separation = 8
[node name="CraftButton" type="Button" parent="CanvasLayer/TopRibbon/Margin/VBox/ToolsRow"]
text = "조합"
[node name="CodexButton" type="Button" parent="CanvasLayer/TopRibbon/Margin/VBox/ToolsRow"]
text = "도감"
```

Update `game/scripts/outdoor/outdoor_controller.gd` to use the new ribbon paths and add a portrait camera lead:

```gdscript
const PORTRAIT_CAMERA_OFFSET := Vector2(0.0, -220.0)


func _sync_view() -> void:
	if _player_sprite != null:
		_player_sprite.position = _player_position
	if _camera != null:
		_camera.position = _player_position
		_camera.offset = PORTRAIT_CAMERA_OFFSET
```

And update the cached node paths:

```gdscript
func _cache_nodes() -> void:
	_ground_host = get_node_or_null("Ground") as Node2D
	_player_sprite = get_node_or_null("PlayerSprite") as Polygon2D
	_camera = get_node_or_null("WorldCamera") as Camera2D
	_building_host = get_node_or_null("Buildings") as Node2D
	_obstacle_host = get_node_or_null("Obstacles") as Node2D
	_exposure_label = get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/HeaderRow/ExposureLabel") as Label
	_hint_label = get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/HintLabel") as Label
	_craft_button = get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ToolsRow/CraftButton") as Button
	_codex_button = get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ToolsRow/CodexButton") as Button
```

- [ ] **Step 4: Re-run the outdoor tests and verify they pass**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_shared_crafting_sheet.gd
```

Expected:

- `OUTDOOR_CONTROLLER_OK`
- `SHARED_CRAFTING_SHEET_OK`

- [ ] **Step 5: Commit**

```bash
git add game/scenes/outdoor/outdoor_mode.tscn game/scripts/outdoor/outdoor_controller.gd game/tests/unit/test_outdoor_controller.gd game/tests/unit/test_shared_crafting_sheet.gd
git commit -m "feat: reframe outdoor mode for portrait shell"
```

---

### Task 3: Convert Indoor Main Screen To A One-Column Portrait Stack

**Files:**
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Modify: `game/tests/unit/test_survivor_creator.gd`

- [ ] **Step 1: Write the failing indoor portrait assertions**

Update `game/tests/unit/test_indoor_mode.gd` to remove the old `ContextRow` assumption and target the new direct-child portrait layout:

```gdscript
	var context_row := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ContextRow")
	assert_true(context_row == null, "Indoor mode should remove the old horizontal ContextRow in portrait mode.")

	var reading_card := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard") as Control
	var summary_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/VBox/SummaryLabel") as Label
	var result_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/VBox/ResultLabel") as Label
	var inline_minimap_card := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/MiniMapCard") as Control
	var inline_minimap := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/MiniMapCard/MapNodes") as Control
	if not assert_true(reading_card != null and summary_label != null and result_label != null and inline_minimap_card != null and inline_minimap != null, "Indoor mode should expose portrait reading and minimap cards as direct children of MainColumn."):
		indoor_mode.free()
		return
```

Update `game/tests/unit/test_survivor_creator.gd` to follow the new result-label path:

```gdscript
	var result_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/VBox/ResultLabel") as Label
```

- [ ] **Step 2: Run the indoor tests and verify they fail**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survivor_creator.gd
```

Expected:

- `test_indoor_mode.gd` fails because `ContextRow` still exists and the new direct-child portrait paths do not.
- `test_survivor_creator.gd` fails because the result label still lives under `ContextRow`.

- [ ] **Step 3: Rebuild the indoor scene and cache the new node paths**

Replace the current `ContextRow` region in `game/scenes/indoor/indoor_mode.tscn` with direct children under `MainColumn`:

```tscn
[node name="ReadingCard" type="PanelContainer" parent="Panel/Layout/MainColumn"]
size_flags_vertical = 0

[node name="VBox" type="VBoxContainer" parent="Panel/Layout/MainColumn/ReadingCard"]
theme_override_constants/separation = 10

[node name="SummaryLabel" type="Label" parent="Panel/Layout/MainColumn/ReadingCard/VBox"]
autowrap_mode = 3
text = "방 안을 살펴 단서를 찾아본다."

[node name="ResultLabel" type="Label" parent="Panel/Layout/MainColumn/ReadingCard/VBox"]
autowrap_mode = 3
text = ""

[node name="MiniMapCard" type="PanelContainer" parent="Panel/Layout/MainColumn"]
custom_minimum_size = Vector2(0, 160)

[node name="MapNodes" type="Control" parent="Panel/Layout/MainColumn/MiniMapCard"]
custom_minimum_size = Vector2(0, 160)
size_flags_horizontal = 3
script = ExtResource("3")
```

Update `game/scripts/indoor/indoor_mode.gd` to cache the new paths and stop referencing `ContextRow`:

```gdscript
func _cache_nodes() -> void:
	_director = get_node_or_null("Director")
	_title_label = get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/TitleLabel") as Label
	_location_label = get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/LocationLabel") as Label
	_location_value_label = get_node_or_null("Panel/Layout/MainColumn/LocationStrip/HBox/LocationValueLabel") as Label
	_time_label = get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/TimeLabel") as Label
	_stat_chips = get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/StatChips") as HBoxContainer
	_inline_minimap = get_node_or_null("Panel/Layout/MainColumn/MiniMapCard/MapNodes") as Control
	_summary_label = get_node_or_null("Panel/Layout/MainColumn/ReadingCard/VBox/SummaryLabel") as Label
	_result_label = get_node_or_null("Panel/Layout/MainColumn/ReadingCard/VBox/ResultLabel") as Label
	_action_buttons = get_node_or_null("Panel/Layout/MainColumn/ActionScroll/ActionButtons") as VBoxContainer
```

Tighten the panel margins so the whole indoor frame reads as portrait instead of a landscape page centered inside dead space:

```tscn
[node name="Panel" type="PanelContainer" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 20.0
offset_top = 20.0
offset_right = -20.0
offset_bottom = -20.0
```

- [ ] **Step 4: Re-run the indoor tests and verify they pass**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survivor_creator.gd
```

Expected:

- `INDOOR_MODE_OK`
- `SURVIVOR_CREATOR_OK`

- [ ] **Step 5: Commit**

```bash
git add game/scenes/indoor/indoor_mode.tscn game/scripts/indoor/indoor_mode.gd game/tests/unit/test_indoor_mode.gd game/tests/unit/test_survivor_creator.gd
git commit -m "feat: convert indoor main screen to portrait stack"
```

---

### Task 4: Refresh End-To-End Portrait Smoke And Transition Regressions

**Files:**
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Modify: `game/tests/unit/test_run_controller_live_transition.gd`

- [ ] **Step 1: Update smoke expectations to the portrait node paths**

Replace the old indoor node lookups in `game/tests/smoke/test_first_playable_loop.gd`:

```gdscript
	var summary_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/VBox/SummaryLabel") as Label
	var result_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/VBox/ResultLabel") as Label
	var inline_minimap_card := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/MiniMapCard") as Control
```

Add an outdoor HUD ribbon assertion after boot:

```gdscript
	var hud_ribbon := hud.get_node_or_null("TopRibbon") as PanelContainer
	if not assert_true(hud_ribbon != null, "Run shell should expose the portrait HUD ribbon."):
		bootstrap.free()
		return
	assert_eq(hud_ribbon.anchor_left, 0.0, "Portrait HUD should start at the left edge in the full smoke flow.")
	assert_eq(hud_ribbon.anchor_right, 1.0, "Portrait HUD should stretch across the full width in the smoke flow.")
```

Strengthen `game/tests/unit/test_run_controller_live_transition.gd` so it proves the HUD is still an overlay above the world after the ribbon refactor:

```gdscript
	var top_ribbon := hud.get_node_or_null("TopRibbon") as PanelContainer
	if not assert_true(top_ribbon != null, "Transition tests should still see the portrait HUD ribbon mounted in the run shell."):
		run_shell.free()
		return
	assert_true(hud.get_index() > mode_host.get_index(), "HUD should still render above the mode host after the ribbon refactor.")
```

- [ ] **Step 2: Run the smoke and transition tests and verify they fail before the final path updates**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `test_first_playable_loop.gd` fails until every indoor node lookup uses the portrait layout.
- `test_run_controller_live_transition.gd` either passes immediately or fails on a stale HUD path. If it fails, the expected failure is a missing `TopRibbon` lookup.

- [ ] **Step 3: Re-run the complete portrait regression bundle after Tasks 1-3 are in place**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_hud_presenter.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_outdoor_controller.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_shared_crafting_sheet.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survivor_creator.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `HUD_PRESENTATION_OK`
- `OUTDOOR_CONTROLLER_OK`
- `SHARED_CRAFTING_SHEET_OK`
- `INDOOR_MODE_OK`
- `SURVIVOR_CREATOR_OK`
- `RUN_CONTROLLER_LIVE_TRANSITION_OK`
- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 4: Boot the game once headless to prove the portrait shell still launches cleanly**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game --quit-after 1
```

Expected:

- exit code `0`
- no parse errors
- no missing-scene-path errors for `TopRibbon`, `ReadingCard`, `MiniMapCard`, or `SurvivalSheet`

- [ ] **Step 5: Commit**

```bash
git add game/tests/smoke/test_first_playable_loop.gd game/tests/unit/test_run_controller_live_transition.gd
git commit -m "test: refresh portrait shell smoke coverage"
```

---

## Self-Review

### Spec Coverage

- portrait project window baseline
  - covered by Task 1 (`game/project.godot`, smoke assertions)
- outdoor HUD reframing for portrait
  - covered by Task 1 and Task 2 (`hud.tscn`, `hud_presenter.gd`, `outdoor_mode.tscn`, `outdoor_controller.gd`)
- outdoor camera reframing for portrait
  - covered by Task 2 (`WorldCamera.offset` contract)
- indoor main layout reframing for portrait
  - covered by Task 3 (`indoor_mode.tscn`, `indoor_mode.gd`)
- preserve `SurvivalSheet` and current systems
  - preserved by Task 3 and regression-checked in Task 4
- update tests that lock old landscape assumptions
  - covered across Tasks 1-4

### Placeholder Scan

- no `TODO` / `TBD`
- every code-touching step includes exact paths and concrete code blocks
- every verification step includes exact commands and expected outcomes

### Type Consistency

- shared HUD node root is consistently `TopRibbon`
- outdoor ribbon node root is consistently `CanvasLayer/TopRibbon`
- indoor portrait main node paths consistently use `Panel/Layout/MainColumn/ReadingCard/...` and `.../MiniMapCard/...`
