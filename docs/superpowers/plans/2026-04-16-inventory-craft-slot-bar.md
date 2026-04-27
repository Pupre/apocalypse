# Inventory Craft Slot Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the weak inline crafting status inside the shared bag with a separate craft card and make the bottom detail sheet behave like a true blocking sheet over the lower list area.

**Architecture:** Keep `SurvivalSheet` as the single bag surface, but split its temporary overlays into two explicit layers: a top craft card that appears only during contextual crafting, and a bottom opaque detail sheet that owns input over the area it covers. The item list remains the main browsing surface, but only the exposed area above the detail sheet should remain readable and interactable.

**Tech Stack:** Godot 4.4.1, GDScript, TSCN scenes, existing `SurvivalSheet`, headless Godot tests

---

## File Map

### Create

- None required

### Modify

- `game/scenes/shared/survival_sheet.tscn`
- `game/scripts/ui/survival_sheet.gd`
- `game/tests/unit/test_survival_sheet.gd`
- `game/tests/unit/test_shared_crafting_sheet.gd`
- `game/tests/smoke/test_first_playable_loop.gd`
- `docs/INDEX.md`
- `docs/CURRENT_STATE.md`

### Responsibilities

- `game/scenes/shared/survival_sheet.tscn`
  - Replace the old inline craft context strip with a dedicated craft card panel and ensure the bottom detail sheet visually and structurally blocks the lower list area.
- `game/scripts/ui/survival_sheet.gd`
  - Render and drive the craft card, keep `재료 1` / `재료 2` state explicit, and limit list interaction to the exposed area above the detail sheet.
- tests
  - Lock the craft-card behavior, material replacement behavior, explicit confirm flow, and the blocking nature of the bottom detail sheet.

### Implementation Note

- The user explicitly wants one final commit rather than micro-commits. Verify continuously, but defer Git commit until the entire pass is finished.

---

### Task 1: Rewrite The Shared Sheet Tests Around A Real Craft Card

**Files:**
- Modify: `game/tests/unit/test_survival_sheet.gd`
- Modify: `game/tests/unit/test_shared_crafting_sheet.gd`
- Modify: `game/tests/smoke/test_first_playable_loop.gd`
- Test: `game/tests/unit/test_survival_sheet.gd`
- Test: `game/tests/unit/test_shared_crafting_sheet.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Extend `test_survival_sheet.gd` with craft-card assertions**

Add assertions after `begin_craft_mode("newspaper")`:

```gdscript
	var craft_card := _find(survival_sheet, "Sheet/VBox/CraftCard") as Control
	var material_one_label := _find(survival_sheet, "Sheet/VBox/CraftCard/VBox/SlotsRow/MaterialOneValueLabel") as Label
	var material_two_label := _find(survival_sheet, "Sheet/VBox/CraftCard/VBox/SlotsRow/MaterialTwoValueLabel") as Label
	var craft_confirm_button := _find(survival_sheet, "Sheet/VBox/CraftCard/VBox/ActionsRow/CraftConfirmButton") as Button
	var craft_cancel_button := _find(survival_sheet, "Sheet/VBox/CraftCard/VBox/ActionsRow/CraftCancelButton") as Button
	if not assert_true(craft_card != null and material_one_label != null and material_two_label != null, "Craft mode should expose an explicit craft card with material labels."):
		return
	if not assert_true(craft_confirm_button != null and craft_cancel_button != null, "Craft card should expose explicit confirm and cancel buttons."):
		return

	assert_true(craft_card.visible, "Craft card should appear once craft mode begins.")
	assert_eq(material_one_label.text, "신문지", "The initiating item should be locked into 재료 1.")
	assert_eq(material_two_label.text, "비어 있음", "재료 2 should start empty until the player chooses another item.")
	assert_true(not craft_confirm_button.disabled, "A second material is not required yet for the button to exist, only for craft resolution.")
```

Then replace direct `confirm_craft()` calls with button-driven assertions:

```gdscript
	survival_sheet.select_inventory_item("steel_food_can")
	assert_eq(material_two_label.text, "철제 식품 캔", "Selecting another item should assign it to 재료 2.")
	craft_confirm_button.emit_signal("pressed")
```

- [ ] **Step 2: Add replacement assertions for `재료 2`**

Still in `game/tests/unit/test_survival_sheet.gd`, after the failed attempt:

```gdscript
	survival_sheet.select_inventory_item("cooking_oil")
	assert_eq(material_two_label.text, "식용유", "Selecting a different item during craft mode should replace 재료 2.")
	craft_confirm_button.emit_signal("pressed")
```

- [ ] **Step 3: Assert detail sheet blocks the lower list region**

In `game/tests/unit/test_survival_sheet.gd`, add structural assertions after selecting an item:

```gdscript
	var inventory_scroll := _find(survival_sheet, "Sheet/VBox/InventoryPane/InventoryScroll") as ScrollContainer
	if not assert_true(inventory_scroll != null, "Inventory scroll should exist."):
		return
	assert_true(detail_sheet.visible, "Selecting an item should still open the bottom detail sheet.")
	assert_true(detail_sheet.mouse_filter == Control.MOUSE_FILTER_STOP, "Detail sheet should own input in the area it covers.")
	assert_true(detail_sheet.position.y > 0.0, "Detail sheet should live as a lower overlay rather than occupying the full bag sheet.")
```

- [ ] **Step 4: Extend shared outdoor crafting test to assert the same craft card**

In `game/tests/unit/test_shared_crafting_sheet.gd`, after `begin_craft_mode("newspaper")`:

```gdscript
	var craft_card := shared_survival_sheet.get_node_or_null("Sheet/VBox/CraftCard") as Control
	var material_one_label := shared_survival_sheet.get_node_or_null("Sheet/VBox/CraftCard/VBox/SlotsRow/MaterialOneValueLabel") as Label
	var material_two_label := shared_survival_sheet.get_node_or_null("Sheet/VBox/CraftCard/VBox/SlotsRow/MaterialTwoValueLabel") as Label
	if not assert_true(craft_card != null and craft_card.visible, "Outdoor SurvivalSheet should show the same craft card during craft mode."):
		run_shell.free()
		return
	assert_eq(material_one_label.text, "신문지", "Outdoor craft mode should lock the initiating item into 재료 1.")

	shared_survival_sheet.select_inventory_item("cooking_oil")
	assert_eq(material_two_label.text, "식용유", "Outdoor craft mode should fill 재료 2 from the shared list.")
```

- [ ] **Step 5: Keep the smoke test aligned with the explicit craft-card flow**

In `game/tests/smoke/test_first_playable_loop.gd`, keep the successful/failed recipe checks but also assert that the craft card becomes visible in the shared sheet:

```gdscript
	var craft_card := survival_sheet.get_node_or_null("Sheet/VBox/CraftCard") as Control
	if not assert_true(craft_card != null and craft_card.visible, "Craft mode should expose the explicit craft card in the playable loop."):
		bootstrap.free()
		return
```

- [ ] **Step 6: Run the focused tests and confirm the current implementation fails**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-craft-card-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survival_sheet.gd
XDG_DATA_HOME=/tmp/apocalypse-craft-card-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_shared_crafting_sheet.gd
XDG_DATA_HOME=/tmp/apocalypse-craft-card-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `test_survival_sheet.gd` should fail because the current scene still uses the old inline `CraftContextStrip`
- the outdoor/shared test should fail for the same reason

---

### Task 2: Replace The Inline Craft Strip With A Separate Craft Card

**Files:**
- Modify: `game/scenes/shared/survival_sheet.tscn`
- Modify: `game/scripts/ui/survival_sheet.gd`
- Test: `game/tests/unit/test_survival_sheet.gd`

- [ ] **Step 1: Replace `CraftContextStrip` in `survival_sheet.tscn` with a dedicated card**

Replace the existing:

```text
Sheet/VBox/CraftContextStrip
  CraftContextLabel
  CancelCraftButton
```

with:

```text
Sheet/VBox/CraftCard
  VBox
    HeaderLabel
    SlotsRow
      MaterialOneCard
        MaterialOneTitleLabel
        MaterialOneValueLabel
      MaterialTwoCard
        MaterialTwoTitleLabel
        MaterialTwoValueLabel
    ActionsRow
      CraftConfirmButton
      CraftCancelButton
```

The card should:

- start hidden
- have an opaque panel style
- sit above `InventoryPane`
- remain slimmer than the bottom detail sheet

- [ ] **Step 2: Rebind node lookups for the new card**

In `game/scripts/ui/survival_sheet.gd`, replace:

```gdscript
var _craft_context_strip: HBoxContainer = null
var _craft_context_label: Label = null
var _cancel_craft_button: Button = null
```

with:

```gdscript
var _craft_card: Control = null
var _material_one_value_label: Label = null
var _material_two_value_label: Label = null
var _craft_confirm_button: Button = null
var _craft_cancel_button: Button = null
```

Then change `_cache_nodes()` accordingly:

```gdscript
	_craft_card = get_node_or_null("Sheet/VBox/CraftCard") as Control
	_material_one_value_label = get_node_or_null("Sheet/VBox/CraftCard/VBox/SlotsRow/MaterialOneCard/MaterialOneValueLabel") as Label
	_material_two_value_label = get_node_or_null("Sheet/VBox/CraftCard/VBox/SlotsRow/MaterialTwoCard/MaterialTwoValueLabel") as Label
	_craft_confirm_button = get_node_or_null("Sheet/VBox/CraftCard/VBox/ActionsRow/CraftConfirmButton") as Button
	_craft_cancel_button = get_node_or_null("Sheet/VBox/CraftCard/VBox/ActionsRow/CraftCancelButton") as Button
```

- [ ] **Step 3: Render concrete material state instead of text**

Replace `_render_craft_context_strip()` with `_render_craft_card()`:

```gdscript
func _render_craft_card() -> void:
	var craft_active := _sheet_state == STATE_INVENTORY_CRAFT_SELECT and not _craft_base_item_id.is_empty()
	if _craft_card != null:
		_craft_card.visible = craft_active
	if _material_one_value_label != null:
		_material_one_value_label.text = _display_name_for_item(_craft_base_item_id) if craft_active else ""
	if _material_two_value_label != null:
		var second_item_id := ""
		if craft_active and not _selected_item_id.is_empty() and _selected_item_id != _craft_base_item_id:
			second_item_id = _selected_item_id
		_material_two_value_label.text = _display_name_for_item(second_item_id) if not second_item_id.is_empty() else "비어 있음"
	if _craft_confirm_button != null:
		_craft_confirm_button.disabled = not can_attempt_craft()
```

Call `_render_craft_card()` from `_render()` instead of `_render_craft_context_strip()`.

- [ ] **Step 4: Drive the card buttons explicitly**

Update `_bind_buttons()`:

```gdscript
	if _craft_confirm_button != null and not _craft_confirm_button.pressed.is_connected(Callable(self, "_on_craft_confirm_pressed")):
		_craft_confirm_button.pressed.connect(Callable(self, "_on_craft_confirm_pressed"))
	if _craft_cancel_button != null and not _craft_cancel_button.pressed.is_connected(Callable(self, "_on_cancel_craft_pressed")):
		_craft_cancel_button.pressed.connect(Callable(self, "_on_cancel_craft_pressed"))
```

Then add:

```gdscript
func _on_craft_confirm_pressed() -> void:
	confirm_craft()
```

---

### Task 3: Make The Bottom Detail Sheet A True Blocking Sheet

**Files:**
- Modify: `game/scenes/shared/survival_sheet.tscn`
- Modify: `game/scripts/ui/survival_sheet.gd`
- Test: `game/tests/unit/test_survival_sheet.gd`

- [ ] **Step 1: Make the detail sheet structurally own the lower area**

In `game/scenes/shared/survival_sheet.tscn`, ensure:

```text
ItemDetailSheet
  mouse_filter = Stop
  z_index > Sheet
```

and keep it as a separate lower overlay with fixed bottom anchoring. The key contract is:

- the detail sheet is opaque
- it visually covers the lower list region
- it intercepts input in that region

- [ ] **Step 2: Limit list interaction to the exposed area**

In `game/scripts/ui/survival_sheet.gd`, add a helper:

```gdscript
func is_detail_open() -> bool:
	return _item_detail_sheet != null and _item_detail_sheet.visible
```

and ensure `open_inventory()`, `open_codex()`, `close_sheet()`, and `_on_detail_close_pressed()` keep detail visibility and selection state in sync so the only interactable list area is the exposed portion above the sheet.

- [ ] **Step 3: Keep craft mode compatible with the blocking detail sheet**

When craft mode is active and the player taps a candidate item, do not collapse detail. Keep updating the candidate detail in place:

```gdscript
func select_inventory_item(item_id: String) -> void:
	if _sheet_state == STATE_INVENTORY_CRAFT_SELECT and item_id != _selected_item_id:
		_last_craft_feedback_text = ""
	_selected_item_id = item_id
	if not item_id.is_empty():
		_item_detail_sheet.visible = true
	_render_inventory()
```

The craft card and detail sheet should coexist:

- craft card above the list
- detail sheet below the list
- exposed list region between them

---

### Task 4: Verify The New Craft Card And Blocking Detail Flow End-To-End

**Files:**
- Test: `game/tests/unit/test_survival_sheet.gd`
- Test: `game/tests/unit/test_shared_crafting_sheet.gd`
- Test: `game/tests/smoke/test_first_playable_loop.gd`

- [ ] **Step 1: Run focused bag tests**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-craft-card-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_survival_sheet.gd
XDG_DATA_HOME=/tmp/apocalypse-craft-card-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/unit/test_shared_crafting_sheet.gd
```

Expected:

- both pass
- `test_shared_crafting_sheet.gd` may still emit the known `ObjectDB instances leaked at exit` warning, but it must end in success

- [ ] **Step 2: Run the smoke test**

Run:

```bash
XDG_DATA_HOME=/tmp/apocalypse-craft-card-home /home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64 --headless --path /home/muhyeon_shin/packages/apocalypse/game -s res://tests/smoke/test_first_playable_loop.gd
```

Expected:

- `FIRST_PLAYABLE_LOOP_OK`

- [ ] **Step 3: Manual verification checklist**

Open the game and verify:

- opening the bag still feels list-first
- selecting an item opens the opaque lower detail sheet
- the covered lower list region no longer feels visually or interactively ambiguous
- pressing `조합 시작` shows a separate craft card rather than inline text
- `재료 1` stays fixed
- selecting other items replaces `재료 2`
- pressing `조합` resolves the craft
- pressing `취소` exits craft mode cleanly

