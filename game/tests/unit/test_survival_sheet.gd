extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const SURVIVAL_SHEET_SCENE_PATH := "res://scenes/shared/survival_sheet.tscn"


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


func _find_button_by_name(container: Node, button_name: String) -> Button:
	if container == null:
		return null
	for child in container.get_children():
		var button := child as Button
		if button != null and button.name == button_name:
			return button
		var nested := _find_button_by_name(child, button_name)
		if nested != null:
			return nested
	return null


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	var survival_sheet_scene := load(SURVIVAL_SHEET_SCENE_PATH) as PackedScene
	if not assert_true(run_state_script != null, "RunState script should load for SurvivalSheet tests."):
		return
	if not assert_true(survival_sheet_scene != null, "SurvivalSheet scene should exist."):
		return

	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary should be available for SurvivalSheet tests."):
		return

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
		"difficulty": "easy",
	}, content_library)
	if not assert_true(run_state != null, "RunState should build for SurvivalSheet tests."):
		return

	for item_id in ["newspaper", "cooking_oil", "lighter", "steel_food_can", "bottled_water", "improvised_heat_note_01"]:
		assert_true(run_state.inventory.add_item(content_library.get_item(item_id)), "Starter item '%s' should be added." % item_id)

	var survival_sheet = survival_sheet_scene.instantiate()
	if not assert_true(survival_sheet != null, "SurvivalSheet should instantiate."):
		return

	root.add_child(survival_sheet)
	survival_sheet.bind_run_state(run_state)
	survival_sheet.set_mode_name("indoor")

	survival_sheet.open_inventory()
	assert_eq(survival_sheet.get_active_tab_id(), "inventory", "SurvivalSheet should open on the inventory tab.")
	assert_eq(survival_sheet.get_sheet_state_id(), "inventory_browse", "Opening inventory should enter browse mode.")
	var detail_sheet := _find(survival_sheet, "ItemDetailSheet") as Control
	var sheet_panel := _find(survival_sheet, "Sheet") as PanelContainer
	var craft_card_panel := _find(survival_sheet, "CraftCard") as PanelContainer
	var inventory_scroll := _find(survival_sheet, "Sheet/VBox/InventoryPane/InventoryScroll") as ScrollContainer
	var detail_inset := _find(survival_sheet, "Sheet/VBox/InventoryPane/InventoryScroll/InventoryContent/DetailInset") as Control
	if not assert_true(detail_sheet != null, "SurvivalSheet should expose a bottom detail sheet container."):
		return
	if not assert_true(inventory_scroll != null, "SurvivalSheet should expose the inventory scroll container."):
		return
	if not assert_true(detail_inset != null, "SurvivalSheet should expose a detail inset spacer for the occluded lower list region."):
		return
	var sheet_style := sheet_panel.get_theme_stylebox("panel") as StyleBoxTexture
	var detail_style := detail_sheet.get_theme_stylebox("panel") as StyleBoxTexture
	if not assert_true(sheet_style != null and sheet_style.texture != null, "SurvivalSheet should use a texture-backed compact main sheet panel."):
		return
	if not assert_true(detail_style != null and detail_style.texture != null, "SurvivalSheet should use a texture-backed compact detail panel."):
		return
	assert_eq(sheet_style.texture.get_width(), 648, "Main bag sheet should use the master inventory sheet background asset.")
	assert_eq(detail_style.texture.get_width(), 600, "Detail sheet should use the master inventory detail panel asset.")
	assert_eq(detail_style.texture.get_height(), 264, "Detail sheet should use the master inventory detail panel height.")
	var sheet_title := _find(survival_sheet, "Sheet/VBox/Header/TitleRow/TitleLabel") as Label
	var sheet_status := _find(survival_sheet, "Sheet/VBox/Header/StatusLabel") as Label
	var browse_hint_label := _find(survival_sheet, "Sheet/VBox/InventoryPane/BrowseHintLabel") as Label
	var equipment_rows := _find(survival_sheet, "Sheet/VBox/InventoryPane/EquipmentRows") as GridContainer
	var inventory_items := _find(survival_sheet, "Sheet/VBox/InventoryPane/InventoryScroll/InventoryContent/InventoryItems") as VBoxContainer
	if not assert_true(sheet_title != null and sheet_status != null, "SurvivalSheet should expose title and status labels."):
		return
	if not assert_true(browse_hint_label != null and inventory_items != null, "SurvivalSheet should expose the browse hint and item list."):
		return
	if not assert_true(equipment_rows != null, "SurvivalSheet should expose a grid-based equipment strip."):
		return
	assert_eq(sheet_title.get_theme_font_size("font_size"), 19, "Bag title should use the larger readability-focused heading size.")
	assert_eq(sheet_status.get_theme_font_size("font_size"), 15, "Bag status should use the larger secondary compact font size.")
	assert_true(browse_hint_label.text.find("먹고 마실 것") != -1, "Bag browse hint should teach the survival-intent grouping.")
	assert_eq(equipment_rows.columns, 4, "Equipment strip should use a four-column mobile grid instead of one cramped horizontal row.")
	assert_true(equipment_rows.get_child_count() >= 13, "Equipment strip should show the full loadout slot set, including hand-carry.")
	assert_true(_has_label_text(inventory_items, "먹고 마실 것"), "Bag list should group food and drink by survival intent.")
	assert_true(_has_label_text(inventory_items, "불과 도구"), "Bag list should group tools by survival intent.")
	assert_true(_has_label_text(inventory_items, "읽을 것"), "Bag list should group readable knowledge separately.")
	var browse_inset_height := detail_inset.custom_minimum_size.y
	assert_true(not detail_sheet.visible, "Opening the bag should start in list-first browse mode with no detail sheet expanded.")

	survival_sheet.set_inventory_payload({
		"title": "가방",
		"status_text": "",
		"equipped_rows": [{
			"kind": "equipped",
			"item_id": "small_backpack",
			"slot_id": "back",
			"slot_label": "등",
			"item_name": "작은 배낭",
			"detail_text": "운반 한계 +4.0kg / 장착 슬롯: 등",
			"action_id": "unequip_inventory_slot_back",
		}],
		"rows": [],
		"selected_sheet": {"visible": false},
		"feedback_message": "",
	})
	await process_frame
	assert_true(_has_button_text(equipment_rows, "해제"), "Equipped chips should expose an immediate unequip button.")

	survival_sheet.select_inventory_item("newspaper")
	assert_true(detail_sheet.visible, "Selecting an item should open the bottom detail sheet.")
	assert_eq(detail_sheet.mouse_filter, Control.MOUSE_FILTER_STOP, "The bottom detail sheet should own input over the area it covers.")
	assert_true(detail_inset.custom_minimum_size.y > browse_inset_height, "Opening detail should add a lower inset so hidden rows can be scrolled upward into the visible list region.")
	var item_icon_rect := _find(survival_sheet, "ItemDetailSheet/VBox/Header/ItemIconRect") as TextureRect
	if not assert_true(item_icon_rect != null, "Detail header should expose an item icon slot."):
		return
	assert_true(item_icon_rect.visible, "Selecting an item should show the detail header icon.")
	assert_true(item_icon_rect.texture != null, "Detail header should render the selected item icon.")
	var item_name_label := _find(survival_sheet, "ItemDetailSheet/VBox/Header/ItemNameLabel") as Label
	var item_description_label := _find(survival_sheet, "ItemDetailSheet/VBox/DetailScroll/DetailBody/ItemDescriptionLabel") as Label
	var item_effect_label := _find(survival_sheet, "ItemDetailSheet/VBox/DetailScroll/DetailBody/ItemEffectLabel") as Label
	assert_true(item_name_label != null and item_description_label != null and item_effect_label != null, "Detail sheet should expose title and body labels.")
	assert_eq(item_name_label.get_theme_font_size("font_size"), 17, "Item title should use the stronger detail heading size.")
	assert_eq(item_description_label.get_theme_font_size("font_size"), 16, "Item description should use the larger compact body font size.")
	assert_eq(item_effect_label.get_theme_font_size("font_size"), 15, "Item effect text should use the larger secondary compact font size.")
	var mode_message_label := _find(survival_sheet, "ItemDetailSheet/VBox/DetailScroll/DetailBody/ModeMessageLabel") as Label
	if not assert_true(mode_message_label != null, "Detail sheet should expose a mode message label."):
		return
	survival_sheet.set_inventory_payload({
		"title": "가방",
		"status_text": "",
		"rows": [],
		"selected_sheet": {"visible": false},
		"feedback_message": "붕대 챙겼다.",
	})
	survival_sheet.select_inventory_item("bottled_water")
	assert_true(not mode_message_label.visible, "Generic inventory detail should not leak the last global loot feedback into every item detail.")
	assert_eq(mode_message_label.text, "", "Generic inventory detail should keep the mode message empty outside craft mode.")
	var first_row_button := _find_button_by_name(survival_sheet, "RowButton")
	if not assert_true(first_row_button != null, "Inventory rows should still expose row buttons."):
		return
	var first_row := first_row_button.get_parent() if first_row_button != null else null
	var first_row_icon := _find_descendant_of_type(first_row, "TextureRect") as TextureRect
	assert_true(first_row_icon != null and first_row_icon.texture != null, "Inventory rows should render an item icon beside the label.")
	var first_row_style := first_row_button.get_theme_stylebox("normal") as StyleBoxTexture
	if not assert_true(first_row_style != null and first_row_style.texture != null, "Inventory rows should use a texture-backed compact row style."):
		return
	assert_eq(first_row_style.texture.get_width(), 604, "Inventory rows should use the master inventory row asset.")
	assert_eq(first_row_style.texture.get_height(), 66, "Inventory rows should use the master inventory row height.")
	assert_eq(first_row_button.get_theme_font_size("font_size"), 15, "Inventory rows should use the larger compact body font size.")
	assert_eq(first_row_button.modulate, Color(1, 1, 1, 1), "Inventory rows should not tint the compact kit with extra highlight colors.")
	assert_eq(first_row_button.mouse_filter, Control.MOUSE_FILTER_PASS, "Inventory rows should not trap drag input and block list scrolling.")
	assert_true(first_row_button.mouse_force_pass_scroll_events, "Inventory rows should pass wheel scroll events through to the list scroll container.")
	var primary_actions := _find(survival_sheet, "ItemDetailSheet/VBox/DetailActions/PrimaryActions") as VBoxContainer
	var secondary_actions := _find(survival_sheet, "ItemDetailSheet/VBox/DetailActions/SecondaryActions") as VBoxContainer
	assert_true(_button_texts(primary_actions).has("버린다"), "Normal inventory detail should still prioritize inventory actions.")
	assert_true(_button_texts(secondary_actions).has("조합 시작"), "Crafting should begin from a secondary action inside the detail sheet.")

	survival_sheet.begin_craft_mode("newspaper")
	await process_frame
	assert_eq(survival_sheet.get_sheet_state_id(), "inventory_craft_select", "Starting craft mode should enter contextual craft selection.")
	assert_eq(survival_sheet.get_craft_anchor_item_id(), "newspaper", "Craft mode should remember the anchor ingredient.")
	assert_true(survival_sheet.get_highlighted_item_ids().has("cooking_oil"), "Easy mode should still highlight the known compatible ingredient.")
	assert_true(not detail_sheet.visible, "Craft mode should collapse the detail sheet and keep the list dominant.")
	assert_eq(detail_inset.custom_minimum_size.y, 0.0, "Craft mode should remove the detail inset once the detail sheet is collapsed.")
	assert_true(browse_hint_label.text.find("조합 가능") != -1, "Craft mode should retune the hint toward choosing a compatible second material.")
	assert_true(_has_label_text(inventory_items, "기준 재료"), "Craft mode should place the initiating item under a clear anchor section.")
	assert_true(_has_label_text(inventory_items, "조합 가능"), "Craft mode should surface compatible ingredients as their own section.")
	var highlighted_row := _find_row_by_item_id(survival_sheet, "cooking_oil")
	var highlighted_badge := _find_descendant_by_name(highlighted_row, "CompatibilityBadge") as Control
	assert_true(
		highlighted_badge != null and highlighted_badge.visible,
		"Craft mode should expose a visible compatibility marker on highlighted secondary ingredients."
	)
	var highlighted_panel := highlighted_row as Control
	assert_true(
		highlighted_panel != null and highlighted_panel.modulate != Color(1, 1, 1, 1),
		"Craft mode should now pulse the full compatible row instead of only the tiny badge."
	)
	var sheet := _find(survival_sheet, "Sheet") as Control
	var craft_card := _find(survival_sheet, "CraftCard") as Control
	var material_one_icon_rect := _find(survival_sheet, "CraftCard/Padding/VBox/SlotsRow/MaterialOneCard/Padding/VBox/ValueRow/MaterialOneIconSlot/IconCenter/MaterialOneIconRect") as TextureRect
	var material_one_label := _find(survival_sheet, "CraftCard/Padding/VBox/SlotsRow/MaterialOneCard/Padding/VBox/ValueRow/MaterialOneValueLabel") as Label
	var material_two_icon_rect := _find(survival_sheet, "CraftCard/Padding/VBox/SlotsRow/MaterialTwoCard/Padding/VBox/ValueRow/MaterialTwoIconSlot/IconCenter/MaterialTwoIconRect") as TextureRect
	var material_two_label := _find(survival_sheet, "CraftCard/Padding/VBox/SlotsRow/MaterialTwoCard/Padding/VBox/ValueRow/MaterialTwoValueLabel") as Label
	var craft_confirm_button := _find(survival_sheet, "CraftCard/Padding/VBox/ActionsRow/CraftConfirmButton") as Button
	var craft_cancel_button := _find(survival_sheet, "CraftCard/Padding/VBox/ActionsRow/CraftCancelButton") as Button
	if not assert_true(craft_card != null and material_one_label != null and material_two_label != null, "Craft mode should expose an explicit craft card with material labels."):
		return
	if not assert_true(craft_confirm_button != null and craft_cancel_button != null, "Craft card should expose explicit confirm and cancel buttons."):
		return
	if not assert_true(material_one_icon_rect != null and material_two_icon_rect != null, "Craft card should expose icon slots for both materials."):
		return
	assert_true(craft_card.visible, "Craft card should appear once craft mode begins.")
	var craft_style := craft_card_panel.get_theme_stylebox("panel") as StyleBoxTexture
	if not assert_true(craft_style != null and craft_style.texture != null, "Craft card should use a texture-backed attached compact card style."):
		return
	assert_eq(craft_style.texture.get_width(), 600, "Craft card should now use the inner detail-panel asset so it reads as a section inside the bag sheet.")
	assert_eq(craft_style.texture.get_height(), 264, "Craft card should now use the inner detail-panel height.")
	assert_true(craft_card.get_parent() == survival_sheet, "Craft card should now live as a separate overlay above the bag sheet.")
	assert_eq(material_one_label.text, "신문지", "The initiating item should be locked into 재료 1.")
	assert_true(material_one_icon_rect.texture != null and material_one_icon_rect.visible, "재료 1 should show the initiating item icon.")
	assert_eq(material_two_label.text, "비어 있음", "재료 2 should start empty until the player chooses another item.")
	assert_true(material_two_icon_rect.texture == null and not material_two_icon_rect.visible, "재료 2 icon slot should stay empty until the player chooses another item.")
	assert_true(craft_confirm_button.disabled, "The craft confirm button should stay disabled until a second material is chosen.")
	assert_eq(craft_cancel_button.get_index(), 0, "Craft cancel button should render on the left side of the actions row.")
	assert_eq(craft_confirm_button.get_index(), 1, "Craft confirm button should render on the right side of the actions row.")
	var craft_mode_first_row_button := _find_button_by_name(survival_sheet, "RowButton")
	assert_eq(craft_mode_first_row_button.modulate, Color(1, 1, 1, 1), "Craft-mode highlighting should still leave the row button itself neutral while the row surface pulses.")
	var initial_craft_bar_height := craft_card.size.y

	survival_sheet.select_inventory_item("steel_food_can")
	assert_true(survival_sheet.can_attempt_craft(), "A second ingredient selection should allow a craft attempt even when it is not a valid recipe.")
	assert_eq(material_two_label.text, "철제 식품 캔", "Selecting another item should assign it to 재료 2.")
	assert_true(material_two_icon_rect.texture != null and material_two_icon_rect.visible, "Selecting 재료 2 should also show its icon in the craft card.")
	assert_true(not craft_confirm_button.disabled, "Picking 재료 2 should enable the explicit craft confirm button.")
	assert_eq(craft_card.size.y, initial_craft_bar_height, "Craft bar height should remain stable after choosing the second material.")
	var failed_outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(failed_outcome.get("result_type", "")), "invalid", "Invalid pairs should stay as failed attempts instead of being blocked by the UI.")
	assert_eq(survival_sheet.get_selected_item_id(), "steel_food_can", "A failed attempt should keep the current detail item selected.")
	assert_eq(survival_sheet.get_sheet_state_id(), "inventory_craft_select", "A failed attempt should keep contextual craft mode active.")

	survival_sheet.select_inventory_item("cooking_oil")
	assert_true(survival_sheet.can_attempt_craft(), "A highlighted compatible ingredient should also be attemptable.")
	assert_eq(material_two_label.text, "식용유", "Selecting a different item during craft mode should replace 재료 2.")
	var successful_outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(successful_outcome.get("result_item_id", "")), "dense_fuel", "The known dev craft chain should still succeed.")
	assert_eq(survival_sheet.get_selected_item_id(), "dense_fuel", "Successful crafts should immediately switch the detail sheet to the result item.")
	assert_eq(survival_sheet.get_sheet_state_id(), "inventory_browse", "A successful craft should exit contextual craft mode.")
	assert_true(detail_sheet.visible, "Successful crafts should keep the detail sheet open on the crafted result.")

	survival_sheet.open_codex()
	assert_eq(survival_sheet.get_active_tab_id(), "codex", "The codex should still be reachable inside the same sheet.")
	assert_true(not detail_sheet.visible, "Switching to the codex should collapse the inventory detail sheet.")
	var codex_rows: Node = _find(survival_sheet, "Sheet/VBox/CodexPane/CodexScroll/CodexRows")
	var codex_icon_rect := _find_descendant_of_type(codex_rows, "TextureRect") as TextureRect
	assert_true(codex_icon_rect != null, "Known codex entries should render an item icon.")

	survival_sheet.queue_free()
	pass_test("SURVIVAL_SHEET_OK")


func _find_descendant_of_type(container: Node, type_name: String):
	if container == null:
		return null
	for child in container.get_children():
		if child.is_class(type_name):
			return child
		var nested = _find_descendant_of_type(child, type_name)
		if nested != null:
			return nested
	return null


func _find_row_by_item_id(container: Node, item_id: String) -> Control:
	if container == null:
		return null
	for child in container.get_children():
		var control := child as Control
		if control != null and String(control.get_meta("item_id", "")) == item_id:
			return control
		var nested = _find_row_by_item_id(child, item_id)
		if nested != null:
			return nested
	return null


func _find_descendant_by_name(container: Node, expected_name: String) -> Node:
	if container == null:
		return null
	for child in container.get_children():
		if String(child.name) == expected_name:
			return child
		var nested = _find_descendant_by_name(child, expected_name)
		if nested != null:
			return nested
	return null


func _has_label_text(container: Node, expected_text: String) -> bool:
	if container == null:
		return false
	for child in container.get_children():
		var label := child as Label
		if label != null and label.text == expected_text:
			return true
		if _has_label_text(child, expected_text):
			return true
	return false


func _has_button_text(container: Node, expected_text: String) -> bool:
	if container == null:
		return false
	for child in container.get_children():
		var button := child as Button
		if button != null and button.text == expected_text:
			return true
		if _has_button_text(child, expected_text):
			return true
	return false
