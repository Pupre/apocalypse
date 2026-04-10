# Indoor Portrait Survival Sheet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild indoor play around a portrait-first `SurvivalSheet` bottom sheet so inventory, codex, and crafting share one mobile interaction flow without breaking existing indoor simulation systems.

**Architecture:** Keep the current indoor simulation, `RunState`, and codex/crafting data model intact. Add a new reusable `SurvivalSheet` UI component that owns portrait inventory/codex/craft-mode presentation, but continue to let `IndoorDirector` own indoor inventory actions and feedback. Mount the new sheet directly inside `IndoorMode` for this first cycle, leaving the legacy shared `CraftingSheet` in place for outdoor only.

**Tech Stack:** Godot 4.4.1, GDScript, TSCN scenes, existing `IndoorDirector` / `RunState` / `CraftingResolver` / codex data in `ContentLibrary`, headless Godot tests

---

## File Map

### Create

- `game/scenes/shared/survival_sheet.tscn`
- `game/scripts/ui/survival_sheet.gd`
- `game/tests/unit/test_survival_sheet.gd`

### Modify

- `game/scenes/indoor/indoor_mode.tscn`
- `game/scripts/indoor/indoor_mode.gd`
- `game/scripts/indoor/indoor_director.gd`
- `game/tests/unit/test_indoor_mode.gd`
- `game/tests/smoke/test_first_playable_loop.gd`

### Regression-Only Test Targets

- `game/tests/unit/test_shared_crafting_sheet.gd`
- `game/tests/unit/test_run_models.gd`
- `game/tests/unit/test_run_controller_live_transition.gd`

### Responsibilities

- `survival_sheet.tscn` / `survival_sheet.gd`
  - Present portrait inventory + codex tabs
  - Own craft-mode UI state and highlight behavior
  - Call `RunState.attempt_craft(...)` for actual recipe resolution
- `indoor_mode.tscn` / `indoor_mode.gd`
  - Replace old `BagSheet` UI with the new `SurvivalSheet`
  - Remove indoor-only `조합` / `도감` top-bar buttons
  - Feed inventory payloads and director feedback into the sheet
- `indoor_director.gd`
  - Continue to own inspect/use/drop/read/equip indoor actions
  - Expose richer inventory rows for portrait rendering
  - Accept feedback text from craft results so the main indoor result card stays in sync
- tests
  - Lock portrait layout, craft-mode behavior, and indoor integration before the scene rewrite

---

### Task 1: Lock The Portrait Indoor Contract

**Files:**
- Create: `game/tests/unit/test_survival_sheet.gd`
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/unit/test_survival_sheet.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Create the failing `SurvivalSheet` state-machine test**

Create `game/tests/unit/test_survival_sheet.gd` with the new public contract:

```gdscript
extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const SURVIVAL_SHEET_SCENE_PATH := "res://scenes/shared/survival_sheet.tscn"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	var survival_sheet_scene := load(SURVIVAL_SHEET_SCENE_PATH) as PackedScene
	if not assert_true(run_state_script != null, "RunState script should load for SurvivalSheet tests."):
		return
	if not assert_true(survival_sheet_scene != null, "SurvivalSheet scene should exist."):
		return

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
		"difficulty": "easy",
	}, ContentLibrary)
	if not assert_true(run_state != null, "RunState should build for SurvivalSheet tests."):
		return

	for item_id in ["newspaper", "cooking_oil", "lighter", "steel_food_can", "bottled_water"]:
		assert_true(run_state.inventory.add_item(ContentLibrary.get_item(item_id)), "Starter item '%s' should be added." % item_id)

	var survival_sheet = survival_sheet_scene.instantiate()
	root.add_child(survival_sheet)
	survival_sheet.bind_run_state(run_state)
	survival_sheet.set_mode_name("indoor")

	survival_sheet.open_inventory()
	assert_eq(survival_sheet.get_active_tab_id(), "inventory", "SurvivalSheet should open on the inventory tab.")
	assert_eq(survival_sheet.get_sheet_state_id(), "inventory_browse", "Opening inventory should enter browse mode.")

	survival_sheet.select_inventory_item("newspaper")
	survival_sheet.begin_craft_mode("newspaper")
	assert_eq(survival_sheet.get_sheet_state_id(), "inventory_craft_select", "Starting craft mode should switch the sheet state.")
	assert_true(survival_sheet.get_highlighted_item_ids().has("cooking_oil"), "Easy mode should highlight compatible second ingredients.")

	survival_sheet.select_inventory_item("steel_food_can")
	assert_eq(survival_sheet.get_sheet_state_id(), "inventory_craft_select", "Selecting a non-compatible item should not exit craft mode.")
	assert_true(not survival_sheet.can_confirm_craft(), "Non-compatible selections should not enable crafting.")

	survival_sheet.select_inventory_item("cooking_oil")
	assert_true(survival_sheet.can_confirm_craft(), "Compatible second ingredients should enable crafting.")
	var outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(outcome.get("result_item_id", "")), "dense_fuel", "The first dev-chain craft should still succeed.")
	assert_eq(survival_sheet.get_selected_item_id(), "dense_fuel", "Successful craft should immediately select the new result item.")
	assert_eq(survival_sheet.get_sheet_state_id(), "inventory_browse", "Successful craft should return to normal browse mode.")

	survival_sheet.open_codex()
	assert_eq(survival_sheet.get_active_tab_id(), "codex", "The codex should still be reachable inside the same sheet.")

	survival_sheet.queue_free()
	pass_test("SURVIVAL_SHEET_OK")
```

- [ ] **Step 2: Extend the indoor integration test to the new portrait contract**

Replace the old indoor bag assertions in `game/tests/unit/test_indoor_mode.gd` with these checks:

```gdscript
	var craft_button := _find_descendant_by_name_and_type(top_bar, "CraftButton", "Button") as Button
	assert_true(craft_button == null, "Indoor mode should remove the dedicated craft button in portrait mode.")

	var codex_button := _find_descendant_by_name_and_type(top_bar, "CodexButton", "Button") as Button
	assert_true(codex_button == null, "Indoor mode should remove the dedicated codex button in portrait mode.")

	var survival_sheet := indoor_mode.get_node_or_null("SurvivalSheet") as CanvasLayer
	if not assert_true(survival_sheet != null, "Indoor mode should mount the new SurvivalSheet."):
		indoor_mode.free()
		return
	assert_true(not survival_sheet.visible, "Indoor mode should keep the SurvivalSheet hidden by default.")

	bag_button.emit_signal("pressed")
	await process_frame
	assert_true(survival_sheet.visible, "Indoor mode should open the SurvivalSheet from the bag button.")
	assert_eq(survival_sheet.get_active_tab_id(), "inventory", "Opening from the top bar should land on inventory.")
```

Also add one end-to-end craft interaction inside the indoor scene:

```gdscript
	survival_sheet.select_inventory_item("newspaper")
	survival_sheet.begin_craft_mode("newspaper")
	assert_true(survival_sheet.get_highlighted_item_ids().has("cooking_oil"), "Indoor SurvivalSheet should surface easy-mode craft hints.")
	survival_sheet.select_inventory_item("cooking_oil")
	var craft_outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(craft_outcome.get("result_item_id", "")), "dense_fuel", "Indoor craft flow should still create dense fuel.")
	assert_eq(survival_sheet.get_selected_item_id(), "dense_fuel", "Indoor craft flow should select the crafted result.")
```

- [ ] **Step 3: Run the two tests and verify they fail**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survival_sheet.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
```

Expected:

- `test_survival_sheet.gd` fails because the scene and script do not exist yet
- `test_indoor_mode.gd` fails because `CraftButton`, `CodexButton`, and `BagSheet` still describe the old layout

- [ ] **Step 4: Re-run both tests after implementation and verify they pass**

Use the same two commands from Step 3.

Expected:

- `SURVIVAL_SHEET_OK`
- `INDOOR_MODE_OK`

- [ ] **Step 5: Commit**

```bash
git add game/tests/unit/test_survival_sheet.gd game/tests/unit/test_indoor_mode.gd game/scenes/shared/survival_sheet.tscn game/scripts/ui/survival_sheet.gd
git commit -m "test: lock portrait indoor survival sheet contract"
```

---

### Task 2: Build The Reusable `SurvivalSheet`

**Files:**
- Create: `game/scenes/shared/survival_sheet.tscn`
- Create: `game/scripts/ui/survival_sheet.gd`
- Test: `game/tests/unit/test_survival_sheet.gd`

- [ ] **Step 1: Create the portrait bottom-sheet scene skeleton**

Create `game/scenes/shared/survival_sheet.tscn` with the minimum node tree the tests will target:

```tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/survival_sheet.gd" id="1"]

[node name="SurvivalSheet" type="CanvasLayer"]
script = ExtResource("1")

[node name="Sheet" type="PanelContainer" parent="."]
visible = false
offset_left = 16.0
offset_top = 220.0
offset_right = 374.0
offset_bottom = 820.0

[node name="VBox" type="VBoxContainer" parent="Sheet"]

[node name="Tabs" type="HBoxContainer" parent="Sheet/VBox"]
[node name="InventoryTabButton" type="Button" parent="Sheet/VBox/Tabs"]
text = "가방"
[node name="CodexTabButton" type="Button" parent="Sheet/VBox/Tabs"]
text = "도감"
[node name="CloseButton" type="Button" parent="Sheet/VBox/Tabs"]
text = "닫기"

[node name="CraftChipRow" type="HBoxContainer" parent="Sheet/VBox"]
[node name="CraftBaseChip" type="Label" parent="Sheet/VBox/CraftChipRow"]
[node name="CancelCraftButton" type="Button" parent="Sheet/VBox/CraftChipRow"]
text = "조합 취소"

[node name="InventoryPane" type="VBoxContainer" parent="Sheet/VBox"]
[node name="InventoryScroll" type="ScrollContainer" parent="Sheet/VBox/InventoryPane"]
[node name="InventoryItems" type="VBoxContainer" parent="Sheet/VBox/InventoryPane/InventoryScroll"]
[node name="ItemDetailCard" type="PanelContainer" parent="Sheet/VBox/InventoryPane"]
[node name="ItemNameLabel" type="Label" parent="Sheet/VBox/InventoryPane/ItemDetailCard"]
[node name="ItemDescriptionLabel" type="Label" parent="Sheet/VBox/InventoryPane/ItemDetailCard"]
[node name="ItemEffectLabel" type="Label" parent="Sheet/VBox/InventoryPane/ItemDetailCard"]
[node name="ModeMessageLabel" type="Label" parent="Sheet/VBox/InventoryPane/ItemDetailCard"]
[node name="ActionButtons" type="HBoxContainer" parent="Sheet/VBox/InventoryPane/ItemDetailCard"]

[node name="CodexPane" type="VBoxContainer" parent="Sheet/VBox"]
[node name="CodexScroll" type="ScrollContainer" parent="Sheet/VBox/CodexPane"]
[node name="CodexRows" type="VBoxContainer" parent="Sheet/VBox/CodexPane/CodexScroll"]
```

- [ ] **Step 2: Add the `SurvivalSheet` state machine and public API**

Create `game/scripts/ui/survival_sheet.gd` with these concrete entry points:

```gdscript
extends CanvasLayer

signal close_requested
signal inventory_action_requested(action_id: String)
signal craft_applied(outcome: Dictionary)

const STATE_HIDDEN := "hidden"
const STATE_INVENTORY_BROWSE := "inventory_browse"
const STATE_INVENTORY_CRAFT_SELECT := "inventory_craft_select"
const STATE_CODEX_BROWSE := "codex_browse"

var run_state = null
var _mode_name := "indoor"
var _active_tab := "inventory"
var _sheet_state := STATE_HIDDEN
var _selected_item_id := ""
var _craft_base_item_id := ""
var _highlighted_item_ids: Array[String] = []
var _inventory_payload := {
	"title": "",
	"status_text": "",
	"rows": [],
	"selected_sheet": {"visible": false},
	"feedback_message": "",
}

func bind_run_state(value) -> void:
	run_state = value
	_render_codex()

func set_mode_name(value: String) -> void:
	_mode_name = value

func open_inventory() -> void:
	visible = true
	_active_tab = "inventory"
	_sheet_state = STATE_INVENTORY_BROWSE
	_render()

func open_codex() -> void:
	visible = true
	_active_tab = "codex"
	_sheet_state = STATE_CODEX_BROWSE
	_render()

func close_sheet() -> void:
	visible = false
	_active_tab = "inventory"
	_sheet_state = STATE_HIDDEN
	_craft_base_item_id = ""
	_highlighted_item_ids.clear()
	close_requested.emit()

func set_inventory_payload(payload: Dictionary) -> void:
	_inventory_payload = payload.duplicate(true)
	_render_inventory()

func get_active_tab_id() -> String:
	return _active_tab

func get_sheet_state_id() -> String:
	return _sheet_state

func get_selected_item_id() -> String:
	return _selected_item_id

func get_highlighted_item_ids() -> Array[String]:
	return _highlighted_item_ids.duplicate()
```

- [ ] **Step 3: Reuse the existing crafting hint and codex logic inside the new sheet**

Port the existing craft-hint logic from `game/scripts/ui/crafting_sheet.gd` rather than re-inventing it:

```gdscript
func begin_craft_mode(item_id: String) -> void:
	_selected_item_id = item_id
	_craft_base_item_id = item_id
	_sheet_state = STATE_INVENTORY_CRAFT_SELECT
	_refresh_highlights()
	_render_inventory()
	_render_item_detail()

func select_inventory_item(item_id: String) -> void:
	_selected_item_id = item_id
	_render_inventory()
	_render_item_detail()

func can_confirm_craft() -> bool:
	return not _craft_base_item_id.is_empty() and not String(_current_recipe_outcome().get("recipe_id", "")).is_empty()

func confirm_craft() -> Dictionary:
	var outcome: Dictionary = run_state.attempt_craft(_craft_base_item_id, _selected_item_id, _mode_name)
	_craft_base_item_id = ""
	_selected_item_id = String(outcome.get("result_item_id", ""))
	_sheet_state = STATE_INVENTORY_BROWSE
	_refresh_highlights()
	_render_inventory()
	_render_item_detail()
	_render_codex()
	craft_applied.emit(outcome)
	return outcome

func _refresh_highlights() -> void:
	_highlighted_item_ids.clear()
	if _sheet_state != STATE_INVENTORY_CRAFT_SELECT or _craft_base_item_id.is_empty():
		return
	if run_state != null and run_state.has_method("is_hard_mode") and run_state.is_hard_mode():
		return
	_highlighted_item_ids = _compatible_secondary_item_ids(_craft_base_item_id)

func _compatible_secondary_item_ids(primary_item_id: String) -> Array[String]:
	var candidate_ids: Array[String] = []
	var grouped := _group_inventory_rows_by_item_id()
	for item_id_variant in grouped.keys():
		var item_id := String(item_id_variant)
		if item_id == primary_item_id and int(grouped[item_id]) < 2:
			continue
		var preview := run_state.crafting_resolver.resolve(primary_item_id, item_id, _mode_name, ContentLibrary)
		if String(preview.get("recipe_id", "")).is_empty():
			continue
		candidate_ids.append(item_id)
	return candidate_ids
```

For codex rendering, copy the existing `_recipe_is_known`, `_all_codex_rows`, `_create_known_codex_row`, and `_create_unknown_codex_row` behavior from `game/scripts/ui/crafting_sheet.gd` instead of inventing a second codex format.

- [ ] **Step 4: Render action buttons and route non-craft actions through signals**

Keep `SurvivalSheet` presentation-focused. It should emit indoor inventory actions and only execute actual crafting itself:

```gdscript
func _render_item_actions(selected_sheet: Dictionary) -> void:
	_clear_children(_action_buttons)

	for action_variant in selected_sheet.get("actions", []):
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action := action_variant as Dictionary
		var action_id := String(action.get("id", ""))
		var action_label := String(action.get("label", action_id))
		if action_id.begins_with("read_inventory_") or action_id.begins_with("consume_inventory_") or action_id.begins_with("equip_inventory_") or action_id.begins_with("drop_inventory_"):
			var button := Button.new()
			button.text = action_label
			button.pressed.connect(func() -> void:
				inventory_action_requested.emit(action_id)
			)
			_action_buttons.add_child(button)

	var craft_button := Button.new()
	craft_button.text = "이걸로 조합" if _sheet_state != STATE_INVENTORY_CRAFT_SELECT else "조합"
	craft_button.disabled = _selected_item_id.is_empty() or (_sheet_state == STATE_INVENTORY_CRAFT_SELECT and not can_confirm_craft())
	craft_button.pressed.connect(func() -> void:
		if _sheet_state == STATE_INVENTORY_CRAFT_SELECT:
			confirm_craft()
		else:
			begin_craft_mode(_selected_item_id)
	)
	_action_buttons.add_child(craft_button)
```

- [ ] **Step 5: Run the isolated sheet test and verify it passes**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survival_sheet.gd
```

Expected: `SURVIVAL_SHEET_OK`

- [ ] **Step 6: Commit**

```bash
git add game/scenes/shared/survival_sheet.tscn game/scripts/ui/survival_sheet.gd game/tests/unit/test_survival_sheet.gd
git commit -m "feat: add portrait survival sheet"
```

---

### Task 3: Replace Indoor `BagSheet` With `SurvivalSheet`

**Files:**
- Modify: `game/scenes/indoor/indoor_mode.tscn`
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/scripts/indoor/indoor_director.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Replace the old indoor sheet nodes in the scene**

Edit `game/scenes/indoor/indoor_mode.tscn` so the indoor scene no longer owns the legacy bag layout:

```tscn
[ext_resource type="PackedScene" path="res://scenes/shared/survival_sheet.tscn" id="4"]

[node name="Tools" type="HBoxContainer" parent="Panel/Layout/MainColumn/TopBar/StatusRow"]
theme_override_constants/separation = 8

[node name="MapButton" type="Button" parent="Panel/Layout/MainColumn/TopBar/StatusRow/Tools"]
text = "구조도"

[node name="BagButton" type="Button" parent="Panel/Layout/MainColumn/TopBar/StatusRow/Tools"]
text = "가방"

[node name="SurvivalSheet" parent="." instance=ExtResource("4")]
```

Delete these old node groups from the scene:

- `CraftButton`
- `CodexButton`
- the entire `BagSheet` subtree

- [ ] **Step 2: Give `IndoorDirector` the richer inventory payload and feedback setter**

Extend `game/scripts/indoor/indoor_director.gd` so `SurvivalSheet` can render more than plain labels:

```gdscript
func get_inventory_rows() -> Array[Dictionary]:
	...
	for item_id in order:
		var item_data := _item_definition(item_id)
		rows.append({
			"kind": "carried",
			"item_id": item_id,
			"count": int(counts[item_id]),
			"label": "%s x%d" % [_item_name(item_data, item_id), int(counts[item_id])],
			"tag_texts": _item_tags(item_data),
			"charges_text": _item_charges_text(item_id, item_data),
			"action_id": "inspect_inventory_%s" % item_id,
			"detail_text": "",
		})
	return rows

func set_feedback_message(message: String) -> void:
	_event_state["last_feedback_message"] = message
	state_changed.emit()

func _item_charges_text(item_id: String, item_data: Dictionary) -> String:
	if _run_state == null or not _run_state.has_method("get_tool_charges"):
		return ""
	var max_charges := int(item_data.get("charges_max", 0))
	if max_charges <= 0:
		return ""
	return "잔량 %d / %d" % [_run_state.get_tool_charges(item_id), max_charges]
```

Keep `apply_action(action_id)` as the single indoor action router. `SurvivalSheet` should emit those ids; `IndoorMode` should not duplicate consume/read/drop/equip logic.

- [ ] **Step 3: Rewire `IndoorMode` to drive the new sheet**

Remove all old bag-sheet cache fields from `game/scripts/indoor/indoor_mode.gd` and replace them with a single `SurvivalSheet` reference:

```gdscript
var _survival_sheet: CanvasLayer = null

func _cache_nodes() -> void:
	...
	_survival_sheet = get_node_or_null("SurvivalSheet") as CanvasLayer

func configure(run_state, building_id: String = "mart_01") -> void:
	...
	if _survival_sheet != null and _survival_sheet.has_method("bind_run_state"):
		_survival_sheet.bind_run_state(run_state)
		_survival_sheet.set_mode_name("indoor")
```

In `_bind_ui_buttons()` connect the new sheet signals:

```gdscript
	if _survival_sheet != null and _survival_sheet.has_signal("close_requested") and not _survival_sheet.close_requested.is_connected(Callable(self, "_on_survival_sheet_closed")):
		_survival_sheet.close_requested.connect(Callable(self, "_on_survival_sheet_closed"))
	if _survival_sheet != null and _survival_sheet.has_signal("inventory_action_requested") and not _survival_sheet.inventory_action_requested.is_connected(Callable(self, "_on_survival_sheet_action_requested")):
		_survival_sheet.inventory_action_requested.connect(Callable(self, "_on_survival_sheet_action_requested"))
	if _survival_sheet != null and _survival_sheet.has_signal("craft_applied") and not _survival_sheet.craft_applied.is_connected(Callable(self, "_on_survival_sheet_craft_applied")):
		_survival_sheet.craft_applied.connect(Callable(self, "_on_survival_sheet_craft_applied"))
```

Route the bag button to the new entrypoint:

```gdscript
func _on_bag_button_pressed() -> void:
	_close_all_overlays()
	if _survival_sheet != null and _survival_sheet.has_method("open_inventory"):
		_survival_sheet.open_inventory()
		_push_inventory_payload_into_sheet()
```

Add the two bridge handlers:

```gdscript
func _on_survival_sheet_action_requested(action_id: String) -> void:
	if _director == null or not _director.has_method("apply_action"):
		return
	_director.apply_action(action_id)
	_push_inventory_payload_into_sheet()

func _on_survival_sheet_craft_applied(outcome: Dictionary) -> void:
	if _director != null and _director.has_method("set_feedback_message"):
		_director.set_feedback_message(_formatted_craft_feedback(outcome))
	_push_inventory_payload_into_sheet()
	_refresh_view()
```

- [ ] **Step 4: Push the director payload into the sheet on every indoor refresh**

Add one focused helper instead of rebuilding the old bag UI tree:

```gdscript
func _push_inventory_payload_into_sheet() -> void:
	if _survival_sheet == null or _director == null or not _survival_sheet.has_method("set_inventory_payload"):
		return

	_survival_sheet.set_inventory_payload({
		"title": _director.get_inventory_title(),
		"status_text": _director.get_inventory_status_text(),
		"rows": _director.get_inventory_rows(),
		"selected_sheet": _director.get_selected_inventory_sheet(),
		"feedback_message": _director.get_feedback_message(),
	})
```

Then call `_push_inventory_payload_into_sheet()` from `_refresh_view()` after `_refresh_reading_area()`.

- [ ] **Step 5: Run the indoor integration test and verify it passes**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
```

Expected: `INDOOR_MODE_OK`

- [ ] **Step 6: Commit**

```bash
git add game/scenes/indoor/indoor_mode.tscn game/scripts/indoor/indoor_mode.gd game/scripts/indoor/indoor_director.gd game/tests/unit/test_indoor_mode.gd
git commit -m "feat: move indoor inventory to portrait survival sheet"
```

---

### Task 4: Regress The Starter Craft Loop And Outdoor Compatibility

**Files:**
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/unit/test_shared_crafting_sheet.gd`
- Test: `game/tests/unit/test_run_models.gd`
- Test: `game/tests/unit/test_run_controller_live_transition.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Extend the smoke test to exercise the new indoor craft path**

Add this scenario to `game/tests/smoke/test_first_playable_loop.gd` after entering the indoor mart:

```gdscript
	var indoor_mode := _find_descendant_by_name_and_type(run_shell, "IndoorMode")
	var bag_button := _find_descendant_by_name_and_type(indoor_mode, "BagButton", "Button") as Button
	bag_button.emit_signal("pressed")
	await process_frame

	var survival_sheet := indoor_mode.get_node_or_null("SurvivalSheet")
	if not assert_true(survival_sheet != null and survival_sheet.visible, "Indoor bag flow should open the SurvivalSheet."):
		return

	survival_sheet.select_inventory_item("newspaper")
	survival_sheet.begin_craft_mode("newspaper")
	assert_true(survival_sheet.get_highlighted_item_ids().has("cooking_oil"), "The dev starter kit should surface a compatible oil craft hint.")

	survival_sheet.select_inventory_item("cooking_oil")
	var dense_fuel_outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(dense_fuel_outcome.get("result_item_id", "")), "dense_fuel", "Indoor portrait crafting should produce dense fuel in the smoke loop.")
	assert_eq(survival_sheet.get_selected_item_id(), "dense_fuel", "The crafted result should remain selected for immediate inspection.")
```

- [ ] **Step 2: Run the regression bundle before code cleanup**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_shared_crafting_sheet.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_models.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- Outdoor shared crafting sheet still passes unchanged
- Run-state difficulty / codex / lighter regressions still pass unchanged
- Live transition test still passes
- Smoke loop now covers the new indoor `SurvivalSheet` craft interaction

- [ ] **Step 3: Trim any obsolete indoor bag code after the regressions are green**

Delete unused indoor-only bag helpers from `game/scripts/indoor/indoor_mode.gd` once the new flow is green:

```gdscript
# delete old fields and methods once no call sites remain:
var _bag_sheet: Control = null
var _bag_title_label: Label = null
var _bag_status_label: Label = null
var _bag_close_button: Button = null
var _carried_tab_button: Button = null
var _equipped_tab_button: Button = null
var _inventory_column: Control = null
var _inventory_items: VBoxContainer = null
var _item_sheet: Control = null
...
func _refresh_bag_sheet() -> void:
	pass
```

Replace those deletions with the single `_push_inventory_payload_into_sheet()` path from Task 3.

- [ ] **Step 4: Re-run the full verification bundle**

Run the same four commands from Step 2, then add the isolated sheet test:

```bash
XDG_DATA_HOME=/tmp/apocalypse-portrait-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survival_sheet.gd
```

Expected:

- `SURVIVAL_SHEET_OK`
- `INDOOR_MODE_OK`
- `SHARED_CRAFTING_SHEET_OK`
- `RUN_MODELS_OK`
- `RUN_CONTROLLER_LIVE_TRANSITION_OK`
- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 5: Commit**

```bash
git add game/tests/smoke/test_first_playable_loop.gd game/scripts/indoor/indoor_mode.gd game/tests/unit/test_survival_sheet.gd game/tests/unit/test_indoor_mode.gd
git commit -m "test: verify indoor portrait survival sheet flow"
```

---

## Self-Review Checklist

- Spec coverage:
  - portrait indoor layout: Tasks 1 and 3
  - integrated bottom sheet: Tasks 2 and 3
  - `이걸로 조합` mobile flow: Tasks 1, 2, and 4
  - codex inside the same sheet: Task 2
  - strong easy-mode highlights and hard-mode compatibility: Tasks 1 and 2 with regression in Task 4
  - immediate crafted-result inspection: Tasks 1, 2, and 4
- Placeholder scan:
  - No `TODO`, `TBD`, or “similar to above” references remain
- Type consistency:
  - `SurvivalSheet` public API is fixed to `bind_run_state`, `set_mode_name`, `open_inventory`, `open_codex`, `set_inventory_payload`, `select_inventory_item`, `begin_craft_mode`, `can_confirm_craft`, `confirm_craft`, `get_active_tab_id`, `get_sheet_state_id`, `get_selected_item_id`, and `get_highlighted_item_ids`

