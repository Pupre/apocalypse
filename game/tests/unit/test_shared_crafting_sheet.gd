extends "res://tests/support/test_case.gd"

const RUN_SHELL_SCENE_PATH := "res://scenes/run/run_shell.tscn"
const SURVIVAL_SHEET_SCENE_PATH := "res://scenes/shared/survival_sheet.tscn"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_shell_scene := load(RUN_SHELL_SCENE_PATH) as PackedScene
	if not assert_true(run_shell_scene != null, "Missing run shell scene: %s" % RUN_SHELL_SCENE_PATH):
		return

	var run_shell := run_shell_scene.instantiate()
	if not assert_true(run_shell != null, "Run shell should instantiate for shared bag tests."):
		return

	root.add_child(run_shell)
	run_shell.start_run({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
		"difficulty": "easy",
	})

	var transition_layer := run_shell.get_node_or_null("TransitionLayer")
	if not assert_true(transition_layer != null and transition_layer.has_method("set_duration_for_tests"), "Run shell should expose a configurable transition layer for shared bag tests."):
		run_shell.free()
		return
	transition_layer.set_duration_for_tests(0.0)

	var shared_survival_sheet := run_shell.get_node_or_null("SurvivalSheet")
	if not assert_true(shared_survival_sheet != null, "Run shell should mount one shared SurvivalSheet instance for outdoor bag flow."):
		run_shell.free()
		return
	assert_true(not shared_survival_sheet.visible, "Shared SurvivalSheet should start hidden.")
	assert_true(shared_survival_sheet.has_method("open_codex"), "Shared SurvivalSheet should expose codex helpers.")

	var legacy_crafting_sheet := run_shell.get_node_or_null("CraftingSheet")
	var legacy_codex_panel := run_shell.get_node_or_null("CodexPanel")
	assert_true(legacy_crafting_sheet == null and legacy_codex_panel == null, "Run shell should remove the old shared CraftingSheet/CodexPanel stack.")

	var hud := run_shell.get_node_or_null("HUD")
	var outdoor_bag_button := hud.get_node_or_null("TopRibbon/Margin/Stack/HeaderShell/HeaderMargin/HeaderRow/BagButton") as Button
	if not assert_true(outdoor_bag_button != null, "Outdoor HUD should expose a bag button that opens the shared SurvivalSheet."):
		run_shell.free()
		return

	outdoor_bag_button.emit_signal("pressed")
	await process_frame

	assert_true(shared_survival_sheet.visible, "Outdoor bag button should open the shared SurvivalSheet.")
	assert_eq(shared_survival_sheet.get_active_tab_id(), "inventory", "Outdoor bag button should open the inventory tab by default.")
	assert_eq(shared_survival_sheet.get_sheet_state_id(), "inventory_browse", "Outdoor bag button should open in browse mode.")
	var detail_sheet := shared_survival_sheet.get_node_or_null("ItemDetailSheet") as Control
	if not assert_true(detail_sheet != null, "Shared SurvivalSheet should expose the bottom detail sheet."):
		run_shell.free()
		return
	assert_true(not detail_sheet.visible, "Outdoor bag should start list-first with no selected detail.")

	shared_survival_sheet.select_inventory_item("newspaper")
	assert_true(detail_sheet.visible, "Selecting an outdoor inventory item should open the bottom detail sheet.")
	assert_eq(detail_sheet.mouse_filter, Control.MOUSE_FILTER_STOP, "Outdoor detail sheet should also own input in the area it covers.")
	shared_survival_sheet.begin_craft_mode("newspaper")
	assert_true(shared_survival_sheet.get_highlighted_item_ids().has("cooking_oil"), "Easy difficulty should still highlight compatible outdoor ingredients inside SurvivalSheet.")
	var craft_card := shared_survival_sheet.get_node_or_null("CraftCard") as Control
	var material_one_icon_rect := shared_survival_sheet.get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialOneCard/Padding/VBox/ValueRow/MaterialOneIconSlot/IconCenter/MaterialOneIconRect") as TextureRect
	var material_one_label := shared_survival_sheet.get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialOneCard/Padding/VBox/ValueRow/MaterialOneValueLabel") as Label
	var material_two_icon_rect := shared_survival_sheet.get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialTwoCard/Padding/VBox/ValueRow/MaterialTwoIconSlot/IconCenter/MaterialTwoIconRect") as TextureRect
	var material_two_label := shared_survival_sheet.get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialTwoCard/Padding/VBox/ValueRow/MaterialTwoValueLabel") as Label
	var craft_confirm_button := shared_survival_sheet.get_node_or_null("CraftCard/Padding/VBox/ActionsRow/CraftConfirmButton") as Button
	if not assert_true(craft_card != null and craft_card.visible, "Outdoor SurvivalSheet should show the same craft card during craft mode."):
		run_shell.free()
		return
	if not assert_true(material_one_label != null and material_two_label != null and craft_confirm_button != null, "Outdoor craft mode should expose craft card labels and confirm action."):
		run_shell.free()
		return
	if not assert_true(material_one_icon_rect != null and material_two_icon_rect != null, "Outdoor craft mode should expose craft card icon slots."):
		run_shell.free()
		return
	assert_eq(material_one_label.text, "신문지", "Outdoor craft mode should lock the initiating item into 재료 1.")
	assert_true(material_one_icon_rect.texture != null and material_one_icon_rect.visible, "Outdoor craft mode should show the 재료 1 icon.")
	assert_eq(material_two_label.text, "비어 있음", "Outdoor craft mode should start with an empty 재료 2 slot.")
	shared_survival_sheet.select_inventory_item("cooking_oil")
	assert_eq(material_two_label.text, "식용유", "Outdoor craft mode should fill 재료 2 from the shared list.")
	assert_true(material_two_icon_rect.texture != null and material_two_icon_rect.visible, "Outdoor craft mode should show the 재료 2 icon after selection.")
	var outdoor_before_clock: int = run_shell.run_state.clock.minute_of_day
	var crafted_outcome: Dictionary = shared_survival_sheet.confirm_craft()
	assert_eq(String(crafted_outcome.get("result_item_id", "")), "dense_fuel", "Outdoor SurvivalSheet crafting should still resolve the dense fuel recipe.")
	assert_eq(run_shell.run_state.inventory.count_item_by_id("dense_fuel"), 1, "Outdoor SurvivalSheet crafting should add the crafted output.")
	assert_eq(run_shell.run_state.clock.minute_of_day, outdoor_before_clock, "Outdoor crafting should not spend shared-clock minutes.")
	assert_eq(shared_survival_sheet.get_selected_item_id(), "dense_fuel", "Successful outdoor crafting should focus the result item in the same shared sheet.")

	shared_survival_sheet.open_codex()
	assert_eq(shared_survival_sheet.get_active_tab_id(), "codex", "The codex should remain reachable inside the outdoor shared sheet.")
	assert_true(_find_label_by_exact_text(shared_survival_sheet, "???") != null, "Unknown recipes should still render as ??? in the codex.")
	assert_true(_find_label_containing(shared_survival_sheet, "불 / 열") != null, "Codex should still group recipes under category headings like 불 / 열.")

	outdoor_bag_button.emit_signal("pressed")
	await process_frame
	assert_true(not shared_survival_sheet.visible, "Pressing the outdoor bag button again should close the shared SurvivalSheet.")

	var outdoor_mode := run_shell.get_node_or_null("ModeHost/OutdoorMode")
	if not assert_true(outdoor_mode != null, "Run shell should still start in outdoor mode for shared bag tests."):
		run_shell.free()
		return

	outdoor_mode.move_player(Vector2.RIGHT, 1.5)
	outdoor_mode.try_enter_building("mart_01")
	if not await _wait_until(Callable(self, "_is_indoor_ready").bind(run_shell), "Timed out waiting for indoor mode after requesting building entry."):
		run_shell.free()
		return

	var indoor_mode := run_shell.get_node_or_null("ModeHost/IndoorMode")
	var indoor_bag_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/BagButton") as Button
	var indoor_survival_sheet := indoor_mode.get_node_or_null("SurvivalSheet")
	var indoor_craft_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/CraftButton") as Button
	var indoor_codex_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/CodexButton") as Button
	if not assert_true(indoor_bag_button != null and indoor_survival_sheet != null, "Indoor mode should expose its portrait bag entry and SurvivalSheet."):
		run_shell.free()
		return
	assert_true(indoor_craft_button == null and indoor_codex_button == null, "Indoor mode should keep craft/codex inside SurvivalSheet instead of dedicated buttons.")
	assert_true(not shared_survival_sheet.visible, "The run-level shared SurvivalSheet should stay hidden after switching into indoor mode.")

	run_shell.free()

	var survival_sheet_scene := load(SURVIVAL_SHEET_SCENE_PATH) as PackedScene
	if not assert_true(survival_sheet_scene != null, "Shared SurvivalSheet scene should exist for hard-mode hint checks."):
		return
	var hard_survival_sheet := survival_sheet_scene.instantiate()
	if not assert_true(hard_survival_sheet != null, "Shared SurvivalSheet should instantiate for hard-mode hint checks."):
		return

	root.add_child(hard_survival_sheet)
	var hard_run_state_script: Script = load("res://scripts/run/run_state.gd")
	var hard_content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(hard_run_state_script != null and hard_content_library != null, "Hard-mode hint checks require RunState and ContentLibrary."):
		hard_survival_sheet.free()
		return

	var hard_run_state = hard_run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
		"difficulty": "hard",
	}, hard_content_library)
	if not assert_true(hard_run_state != null, "Hard-mode hint checks should build a run state."):
		hard_survival_sheet.free()
		return

	hard_run_state.inventory.add_item({"id": "newspaper", "name": "신문지", "bulk": 1})
	hard_run_state.inventory.add_item({"id": "cooking_oil", "name": "식용유", "bulk": 1})
	hard_survival_sheet.bind_run_state(hard_run_state)
	hard_survival_sheet.set_mode_name("outdoor")
	hard_survival_sheet.open_inventory()
	await process_frame

	hard_survival_sheet.begin_craft_mode("newspaper")
	await process_frame
	assert_eq(hard_survival_sheet.get_highlighted_item_ids(), [], "Hard difficulty should hide compatibility hints until the recipe is actually known.")
	var known_outcome: Dictionary = hard_run_state.crafting_resolver.resolve("newspaper", "cooking_oil", "outdoor", hard_content_library)
	hard_run_state.unlock_recipe(String(known_outcome.get("recipe_id", "")))
	hard_survival_sheet.begin_craft_mode("newspaper")
	await process_frame
	assert_true(hard_survival_sheet.get_highlighted_item_ids().has("cooking_oil"), "Hard difficulty should still surface compatibility for recipes that are already recorded in the codex.")
	hard_survival_sheet.free()

	pass_test("SHARED_CRAFTING_SHEET_OK")


func _wait_until(predicate: Callable, failure_message: String, max_frames: int = 30) -> bool:
	for _index in range(max_frames):
		if predicate.call():
			return true
		await process_frame

	return assert_true(predicate.call(), failure_message)


func _is_indoor_ready(run_shell: Node) -> bool:
	if run_shell == null:
		return false
	if not run_shell.has_method("get_current_mode_name"):
		return false

	return run_shell.get_current_mode_name() == "indoor" and run_shell.get_node_or_null("ModeHost/IndoorMode") != null


func _find_label_by_exact_text(container: Node, expected_text: String) -> Label:
	if container == null:
		return null

	for child in container.get_children():
		var label := child as Label
		if label != null and label.text == expected_text:
			return label
		var nested := _find_label_by_exact_text(child, expected_text)
		if nested != null:
			return nested

	return null


func _find_label_containing(container: Node, expected_fragment: String) -> Label:
	if container == null:
		return null

	for child in container.get_children():
		var label := child as Label
		if label != null and label.text.find(expected_fragment) != -1:
			return label
		var nested := _find_label_containing(child, expected_fragment)
		if nested != null:
			return nested

	return null
