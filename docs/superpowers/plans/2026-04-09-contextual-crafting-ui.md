# Contextual Crafting UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework indoor crafting so the bag remains the primary surface, crafting is entered contextually from item detail, easy mode only highlights likely matches, and both success and failure resolve inside the same detail sheet.

**Architecture:** Keep `RunState.attempt_craft(...)`, recipe data, codex data, and indoor inventory actions intact. Rewrite only the `SurvivalSheet` presentation/state contract so it stops behaving like a separate crafting tool and instead behaves like contextual inventory interaction layered on top of the existing bag/detail flow. Let `IndoorMode` continue to own feedback mirroring into the main reading/result surface.

**Tech Stack:** Godot 4.4.1, GDScript, TSCN scenes, existing `SurvivalSheet` / `IndoorMode` / `RunState`, headless Godot tests

---

## File Map

### Modify

- `game/scenes/shared/survival_sheet.tscn`
- `game/scripts/ui/survival_sheet.gd`
- `game/scripts/indoor/indoor_mode.gd`
- `game/tests/unit/test_survival_sheet.gd`
- `game/tests/unit/test_indoor_mode.gd`
- `game/tests/smoke/test_first_playable_loop.gd`

### Regression-Only Test Targets

- `game/tests/unit/test_shared_crafting_sheet.gd`
- `game/tests/unit/test_run_models.gd`
- `game/tests/unit/test_run_controller_live_transition.gd`

### Responsibilities

- `game/scenes/shared/survival_sheet.tscn`
  - Replace the current craft chip + single action row with a thinner craft context strip and explicit primary/secondary action rows.
- `game/scripts/ui/survival_sheet.gd`
  - Change crafting from “valid pair only” confirmation to “any second ingredient can be attempted.”
  - Keep the bag list stable while craft context is active.
  - Render neutral copy only.
  - On success, switch selected detail to the crafted result; on failure, preserve the current detail and craft context.
- `game/scripts/indoor/indoor_mode.gd`
  - Continue pushing inventory payloads into the sheet.
  - Mirror craft success/failure feedback back into the indoor reading/result area without forcing the sheet to close.
- tests
  - Lock the new contextual contract before rewriting the UI internals.

---

### Task 1: Lock The Contextual Crafting Contract

**Files:**
- Modify: `game/tests/unit/test_survival_sheet.gd`
- Modify: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/unit/test_survival_sheet.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`

- [ ] **Step 1: Rewrite `test_survival_sheet.gd` around the new bag-first contract**

Add helpers near the top of `game/tests/unit/test_survival_sheet.gd` so the test can inspect primary/secondary action rows without adding test-only production getters:

```gdscript
func _button_texts(container: Control) -> Array[String]:
	var texts: Array[String] = []
	if container == null:
		return texts
	for child in container.get_children():
		var button := child as Button
		if button == null:
			continue
		texts.append(button.text)
	return texts


func _find(container: Node, path: String):
	return container.get_node_or_null(path)
```

Then replace the current craft assertions with the new flow:

```gdscript
	survival_sheet.open_inventory()
	survival_sheet.select_inventory_item("newspaper")

	var primary_actions := _find(survival_sheet, "Sheet/VBox/InventoryPane/ItemDetailCard/VBox/DetailActions/PrimaryActions") as HBoxContainer
	var secondary_actions := _find(survival_sheet, "Sheet/VBox/InventoryPane/ItemDetailCard/VBox/DetailActions/SecondaryActions") as HBoxContainer
	assert_true(_button_texts(primary_actions).has("버린다"), "Normal inventory detail should still prioritize inventory actions.")
	assert_true(_button_texts(secondary_actions).has("조합 시작"), "Crafting should begin from a secondary action inside the detail sheet.")

	survival_sheet.begin_craft_mode("newspaper")
	assert_eq(survival_sheet.get_sheet_state_id(), "inventory_craft_select", "Starting craft mode should enter contextual craft selection.")
	assert_eq(survival_sheet.get_craft_anchor_item_id(), "newspaper", "Craft mode should remember the anchor ingredient.")
	assert_true(survival_sheet.get_highlighted_item_ids().has("cooking_oil"), "Easy mode should still highlight the known compatible ingredient.")

	survival_sheet.select_inventory_item("steel_food_can")
	assert_true(survival_sheet.can_attempt_craft(), "A second ingredient selection should allow a craft attempt even when it is not a valid recipe.")
	var failed_outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(failed_outcome.get("result_type", "")), "invalid", "Invalid pairs should stay as failed attempts instead of being blocked by the UI.")
	assert_eq(survival_sheet.get_selected_item_id(), "steel_food_can", "A failed attempt should keep the current detail item selected.")
	assert_eq(survival_sheet.get_sheet_state_id(), "inventory_craft_select", "A failed attempt should keep contextual craft mode active.")

	survival_sheet.select_inventory_item("cooking_oil")
	assert_true(survival_sheet.can_attempt_craft(), "A highlighted compatible ingredient should also be attemptable.")
	var successful_outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(successful_outcome.get("result_item_id", "")), "dense_fuel", "The known dev craft chain should still succeed.")
	assert_eq(survival_sheet.get_selected_item_id(), "dense_fuel", "Successful crafts should immediately switch the detail sheet to the result item.")
	assert_eq(survival_sheet.get_sheet_state_id(), "inventory_browse", "A successful craft should exit contextual craft mode.")
```

- [ ] **Step 2: Extend `test_indoor_mode.gd` so indoor integration proves the same behavior**

After the existing bag-open assertions in `game/tests/unit/test_indoor_mode.gd`, add one failed craft and one successful craft through the mounted `SurvivalSheet`:

```gdscript
	var survival_sheet := indoor_mode.get_node_or_null("SurvivalSheet") as CanvasLayer
	if not assert_true(survival_sheet != null, "Indoor mode should still mount SurvivalSheet."):
		indoor_mode.free()
		return

	bag_button.emit_signal("pressed")
	await process_frame
	survival_sheet.select_inventory_item("newspaper")
	survival_sheet.begin_craft_mode("newspaper")
	survival_sheet.select_inventory_item("steel_food_can")

	var failed_outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(failed_outcome.get("result_type", "")), "invalid", "Indoor craft flow should allow failed attempts.")
	assert_true(survival_sheet.visible, "A failed craft attempt should not close the survival sheet.")
	assert_eq(survival_sheet.get_selected_item_id(), "steel_food_can", "Indoor failed attempts should keep the currently inspected item selected.")

	survival_sheet.select_inventory_item("cooking_oil")
	var success_outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(success_outcome.get("result_item_id", "")), "dense_fuel", "Indoor craft flow should still produce dense fuel.")
	assert_eq(survival_sheet.get_selected_item_id(), "dense_fuel", "Indoor craft success should jump directly to the result detail.")
```

- [ ] **Step 3: Run the focused tests and verify they fail for the right reason**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-contextual-craft-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survival_sheet.gd
XDG_DATA_HOME=/tmp/apocalypse-contextual-craft-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
```

Expected:

- `test_survival_sheet.gd` fails because the sheet still disables crafting for invalid pairs and has only one flat action row.
- `test_indoor_mode.gd` fails because failed craft attempts are blocked before `RunState.attempt_craft(...)` is called.

- [ ] **Step 4: Re-run both focused tests after implementation and verify they pass**

Use the same two commands from Step 3.

Expected:

- `SURVIVAL_SHEET_OK`
- `INDOOR_MODE_OK`

- [ ] **Step 5: Commit**

```bash
git add game/tests/unit/test_survival_sheet.gd game/tests/unit/test_indoor_mode.gd
git commit -m "test: lock contextual crafting sheet contract"
```

---

### Task 2: Rebuild `SurvivalSheet` Around Contextual Crafting

**Files:**
- Modify: `game/scenes/shared/survival_sheet.tscn`
- Modify: `game/scripts/ui/survival_sheet.gd`
- Test: `game/tests/unit/test_survival_sheet.gd`

- [ ] **Step 1: Replace the current craft chip and flat action row with a bag-first detail layout**

Update `game/scenes/shared/survival_sheet.tscn` so the detail card has a thin craft context strip plus split action rows:

```tscn
[node name="CraftContextStrip" type="HBoxContainer" parent="Sheet/VBox"]
visible = false
theme_override_constants/separation = 8

[node name="CraftContextLabel" type="Label" parent="Sheet/VBox/CraftContextStrip"]
size_flags_horizontal = 3
text = ""

[node name="CancelCraftButton" type="Button" parent="Sheet/VBox/CraftContextStrip"]
text = "취소"

[node name="DetailActions" type="VBoxContainer" parent="Sheet/VBox/InventoryPane/ItemDetailCard/VBox"]
theme_override_constants/separation = 8

[node name="PrimaryActions" type="HBoxContainer" parent="Sheet/VBox/InventoryPane/ItemDetailCard/VBox/DetailActions"]
theme_override_constants/separation = 8

[node name="SecondaryActions" type="HBoxContainer" parent="Sheet/VBox/InventoryPane/ItemDetailCard/VBox/DetailActions"]
theme_override_constants/separation = 8
```

Delete the old `CraftChipRow` references and the single `ActionButtons` node from the scene so the script cannot accidentally keep using the old contract.

- [ ] **Step 2: Change the state machine from “confirm only valid recipes” to “attempt any selected pair”**

In `game/scripts/ui/survival_sheet.gd`, add explicit craft-context state and stop using recipe preview as a button gate:

```gdscript
var _craft_anchor_item_id := ""
var _last_craft_feedback_text := ""


func get_craft_anchor_item_id() -> String:
	return _craft_anchor_item_id


func can_attempt_craft() -> bool:
	if run_state == null:
		return false
	if _sheet_state != STATE_INVENTORY_CRAFT_SELECT:
		return false
	if _craft_anchor_item_id.is_empty() or _selected_item_id.is_empty():
		return false
	if _selected_item_id == _craft_anchor_item_id:
		return run_state.inventory.count_item_by_id(_selected_item_id) >= 2
	return true


func begin_craft_mode(item_id: String) -> void:
	if item_id.is_empty():
		return
	visible = true
	_active_tab = "inventory"
	_selected_item_id = item_id
	_craft_anchor_item_id = item_id
	_last_craft_feedback_text = ""
	_sheet_state = STATE_INVENTORY_CRAFT_SELECT
	_refresh_highlights()
	_render()


func confirm_craft() -> Dictionary:
	if not can_attempt_craft():
		return {
			"ok": false,
			"result_type": "invalid",
			"result_item_id": "",
			"result_text": "재료를 두 개 고른 뒤 조합을 시도한다.",
			"minutes_elapsed": 0,
		}

	var outcome: Dictionary = run_state.attempt_craft(_craft_anchor_item_id, _selected_item_id, _mode_name)
	_last_craft_feedback_text = String(outcome.get("result_text", ""))
	if bool(outcome.get("ok", false)):
		_selected_item_id = String(outcome.get("result_item_id", ""))
		_sheet_state = STATE_INVENTORY_BROWSE
		_craft_anchor_item_id = ""
	else:
		_sheet_state = STATE_INVENTORY_CRAFT_SELECT
	_refresh_highlights()
	_render()
	craft_applied.emit(outcome)
	return outcome
```

Keep `_compatible_secondary_item_ids(...)` for easy-mode highlighting, but only as a highlight source. Do not use it to disable selection or the `조합` button.

- [ ] **Step 3: Rebuild action rendering and on-screen copy so it stays neutral**

Still in `game/scripts/ui/survival_sheet.gd`, split actions into primary vs secondary and render neutral craft copy only:

```gdscript
func _render_craft_context_strip() -> void:
	var active := _sheet_state == STATE_INVENTORY_CRAFT_SELECT and not _craft_anchor_item_id.is_empty()
	_craft_context_strip.visible = active
	if _craft_context_label != null:
		_craft_context_label.text = "조합 중: %s" % _display_name_for_item(_craft_anchor_item_id) if active else ""


func _render_item_actions(selected_sheet: Dictionary) -> void:
	_clear_children(_primary_actions)
	_clear_children(_secondary_actions)
	if not bool(selected_sheet.get("visible", false)):
		return

	for action_variant in selected_sheet.get("actions", []):
		var action := action_variant as Dictionary
		var button := Button.new()
		button.text = String(action.get("label", ""))
		button.pressed.connect(func() -> void:
			inventory_action_requested.emit(String(action.get("id", "")))
		)
		_primary_actions.add_child(button)

	var craft_button := Button.new()
	craft_button.text = "조합" if _sheet_state == STATE_INVENTORY_CRAFT_SELECT else "조합 시작"
	craft_button.disabled = (_sheet_state == STATE_INVENTORY_CRAFT_SELECT and not can_attempt_craft()) or (_sheet_state == STATE_INVENTORY_BROWSE and _selected_item_id.is_empty())
	craft_button.pressed.connect(func() -> void:
		if _sheet_state == STATE_INVENTORY_CRAFT_SELECT:
			confirm_craft()
		else:
			begin_craft_mode(_selected_item_id)
	)
	_secondary_actions.add_child(craft_button)
```

Also update `_mode_message_text(...)` so it never predicts success/failure before the attempt:

```gdscript
func _mode_message_text(selected_sheet: Dictionary) -> String:
	if _sheet_state == STATE_INVENTORY_CRAFT_SELECT:
		if not _last_craft_feedback_text.is_empty():
			return _last_craft_feedback_text
		return "다른 재료를 고른 뒤 조합을 시도한다."
	if bool(selected_sheet.get("visible", false)):
		return String(_inventory_payload.get("feedback_message", ""))
	return ""
```

Finally, make highlighted rows feel stronger without making non-highlighted rows look disabled:

```gdscript
const HINT_PULSE_BASE := Color(1.18, 0.97, 0.46, 1.0)
const HINT_PULSE_TARGET := Color(1.42, 1.08, 0.56, 1.0)

func _refresh_item_button_states() -> void:
	for item_id_variant in _item_buttons.keys():
		var item_id := String(item_id_variant)
		var button := _item_buttons.get(item_id) as Button
		if button == null:
			continue
		var button_color := DEFAULT_BUTTON_MODULATE
		if item_id == _selected_item_id:
			button_color = SELECTED_BUTTON_MODULATE
		elif _sheet_state == STATE_INVENTORY_CRAFT_SELECT and item_id == _craft_anchor_item_id:
			button_color = CRAFT_BASE_BUTTON_MODULATE
		elif _highlighted_item_ids.has(item_id):
			var pulse := 0.5 + (0.5 * sin(_pulse_time * HINT_PULSE_SPEED))
			button_color = HINT_PULSE_BASE.lerp(HINT_PULSE_TARGET, pulse)
		button.modulate = button_color
```

- [ ] **Step 4: Run the focused unit test and verify the state machine is now green**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-contextual-craft-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survival_sheet.gd
```

Expected:

- `SURVIVAL_SHEET_OK`

- [ ] **Step 5: Commit**

```bash
git add game/scenes/shared/survival_sheet.tscn game/scripts/ui/survival_sheet.gd
git commit -m "feat: add contextual bag-first crafting sheet"
```

---

### Task 3: Wire Indoor Feedback And Re-Verify The Playable Loop

**Files:**
- Modify: `game/scripts/indoor/indoor_mode.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/unit/test_indoor_mode.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/unit/test_shared_crafting_sheet.gd`
- Test: `game/tests/unit/test_run_models.gd`
- Test: `game/tests/unit/test_run_controller_live_transition.gd`

- [ ] **Step 1: Keep indoor result feedback in sync without kicking the player out of the sheet**

Tighten `game/scripts/indoor/indoor_mode.gd` so craft results always flow back into the reading/result surface after the sheet handles them:

```gdscript
func _on_survival_sheet_craft_applied(outcome: Dictionary) -> void:
	var feedback := _formatted_craft_feedback(outcome)
	if _director != null and _director.has_method("set_feedback_message"):
		_director.set_feedback_message(feedback)
	_push_inventory_payload_into_sheet()
	_refresh_reading_area()
```

If the current method already looks similar, only normalize it so there is no branch that closes the sheet or loses feedback after a failed attempt.

- [ ] **Step 2: Extend the smoke script so the new flow is protected end-to-end**

In `game/tests/smoke/test_first_playable_loop.gd`, add one invalid attempt followed by one success using the developer starter kit:

```gdscript
	var survival_sheet := indoor_mode.get_node_or_null("SurvivalSheet") as CanvasLayer
	assert_true(survival_sheet != null, "Indoor mode should expose the contextual crafting sheet.")
	survival_sheet.open_inventory()
	survival_sheet.select_inventory_item("newspaper")
	survival_sheet.begin_craft_mode("newspaper")
	survival_sheet.select_inventory_item("steel_food_can")
	var invalid_outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(invalid_outcome.get("result_type", "")), "invalid", "The playable loop should allow failed craft attempts.")
	assert_eq(survival_sheet.get_selected_item_id(), "steel_food_can", "Failed craft attempts should keep the inspected detail in the same sheet.")

	survival_sheet.select_inventory_item("cooking_oil")
	var success_outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(success_outcome.get("result_item_id", "")), "dense_fuel", "The playable loop should still allow the dense fuel craft chain.")
	assert_eq(survival_sheet.get_selected_item_id(), "dense_fuel", "Successful craft attempts should swap directly to the crafted result detail.")
```

- [ ] **Step 3: Run the wider regression set**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-contextual-craft-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_indoor_mode.gd
XDG_DATA_HOME=/tmp/apocalypse-contextual-craft-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
XDG_DATA_HOME=/tmp/apocalypse-contextual-craft-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_shared_crafting_sheet.gd
XDG_DATA_HOME=/tmp/apocalypse-contextual-craft-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_models.gd
XDG_DATA_HOME=/tmp/apocalypse-contextual-craft-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_run_controller_live_transition.gd
```

Expected:

- `INDOOR_MODE_OK`
- `FIRST_PLAYABLE_LOOP_OK`
- `SHARED_CRAFTING_SHEET_OK`
- `RUN_MODELS_OK`
- `RUN_CONTROLLER_LIVE_TRANSITION_OK`

- [ ] **Step 4: Commit**

```bash
git add game/scripts/indoor/indoor_mode.gd game/tests/smoke/test_first_playable_loop.gd
git commit -m "feat: preserve indoor feedback in contextual crafting flow"
```

---

## Self-Review

- Spec coverage:
  - `가방 우선` is covered by Task 2 scene/action split.
  - `모든 조합 시도 허용` is covered by Task 1 failing tests plus Task 2 `can_attempt_craft()` / `confirm_craft()`.
  - `easy는 안내만` is covered by Task 2 highlight-only logic.
  - `중립적 카피` is covered by Task 2 action rendering and mode-message rewrite.
  - `성공 시 결과 상세 치환 / 실패 시 현재 상세 유지` is covered by Task 1 assertions, Task 2 state machine, and Task 3 indoor/smoke regressions.
- Placeholder scan:
  - No `TODO`, `TBD`, or undefined “appropriate handling” steps remain.
- Type consistency:
  - The plan consistently uses `craft_anchor_item_id`, `can_attempt_craft()`, `confirm_craft()`, and `selected_item_id`.
