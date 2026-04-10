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

	for item_id in ["newspaper", "cooking_oil", "lighter", "steel_food_can", "bottled_water"]:
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

	survival_sheet.open_codex()
	assert_eq(survival_sheet.get_active_tab_id(), "codex", "The codex should still be reachable inside the same sheet.")

	survival_sheet.queue_free()
	pass_test("SURVIVAL_SHEET_OK")
