extends "res://tests/support/test_case.gd"

const RUN_SHELL_SCENE_PATH := "res://scenes/run/run_shell.tscn"
const CRAFTING_SHEET_SCENE_PATH := "res://scenes/shared/crafting_sheet.tscn"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_shell_scene := load(RUN_SHELL_SCENE_PATH) as PackedScene
	if not assert_true(run_shell_scene != null, "Missing run shell scene: %s" % RUN_SHELL_SCENE_PATH):
		return

	var run_shell := run_shell_scene.instantiate()
	if not assert_true(run_shell != null, "Run shell should instantiate for shared crafting sheet tests."):
		return

	root.add_child(run_shell)
	run_shell.start_run({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
		"difficulty": "easy",
	})

	var transition_layer := run_shell.get_node_or_null("TransitionLayer")
	if not assert_true(transition_layer != null and transition_layer.has_method("set_duration_for_tests"), "Run shell should expose a configurable transition layer for shared crafting tests."):
		run_shell.free()
		return
	transition_layer.set_duration_for_tests(0.0)

	var crafting_sheet := run_shell.get_node_or_null("CraftingSheet")
	if not assert_true(crafting_sheet != null, "Run shell should mount one shared CraftingSheet instance."):
		run_shell.free()
		return
	assert_true(not crafting_sheet.visible, "Crafting sheet should start hidden.")
	assert_true(crafting_sheet.has_method("get_active_tab_id"), "Crafting sheet should expose its current active tab for verification.")

	var outdoor_mode := run_shell.get_node_or_null("ModeHost/OutdoorMode")
	if not assert_true(outdoor_mode != null, "Run shell should start in outdoor mode for crafting tests."):
		run_shell.free()
		return

	var outdoor_craft_button := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ToolsRow/CraftButton") as Button
	var outdoor_codex_button := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ToolsRow/CodexButton") as Button
	if not assert_true(outdoor_craft_button != null and outdoor_codex_button != null, "Outdoor mode should expose craft and codex buttons that open the shared sheet."):
		run_shell.free()
		return

	run_shell.run_state.inventory.add_item({"id": "newspaper", "name": "신문지", "bulk": 1})
	run_shell.run_state.inventory.add_item({"id": "cooking_oil", "name": "식용유", "bulk": 1})
	var outdoor_before_clock: int = run_shell.run_state.clock.minute_of_day

	outdoor_craft_button.emit_signal("pressed")
	await process_frame

	assert_true(crafting_sheet.visible, "Outdoor craft button should open the shared crafting sheet.")
	assert_eq(crafting_sheet.get_context_mode_name(), "outdoor", "Outdoor craft button should open the sheet in outdoor mode.")
	assert_eq(crafting_sheet.get_active_tab_id(), "direct", "Craft button should open the direct-crafting tab by default.")

	var direct_tab_button := crafting_sheet.get_node_or_null("Panel/VBox/Tabs/DirectTabButton") as Button
	var codex_tab_button := crafting_sheet.get_node_or_null("Panel/VBox/Tabs/CodexTabButton") as Button
	var close_button := crafting_sheet.get_node_or_null("Panel/VBox/Header/CloseButton") as Button
	if not assert_true(direct_tab_button != null and codex_tab_button != null and close_button != null, "Crafting sheet should expose stable header and tab controls."):
		run_shell.free()
		return

	codex_tab_button.emit_signal("pressed")
	await process_frame
	assert_eq(crafting_sheet.get_active_tab_id(), "codex", "Codex tab should switch the shared sheet into codex mode.")
	assert_true(_find_label_by_exact_text(crafting_sheet, "???") != null, "Unknown recipes should render as ??? in the codex.")
	assert_true(_find_label_containing(crafting_sheet, "불 / 열") != null, "Codex should group recipes under category headings like 불 / 열.")

	direct_tab_button.emit_signal("pressed")
	await process_frame
	assert_eq(crafting_sheet.get_active_tab_id(), "direct", "Direct tab should switch the shared sheet back into recipe-combine mode.")

	var outdoor_newspaper_button := crafting_sheet.get_node_or_null("Panel/VBox/DirectPane/InventoryScroll/Items/ItemButton_newspaper") as Button
	var outdoor_cooking_oil_button := crafting_sheet.get_node_or_null("Panel/VBox/DirectPane/InventoryScroll/Items/ItemButton_cooking_oil") as Button
	var combine_button := crafting_sheet.get_node_or_null("Panel/VBox/DirectPane/SlotsRow/CombineButton") as Button
	var result_label := crafting_sheet.get_node_or_null("Panel/VBox/DirectPane/ResultCard/ResultLabel") as Label
	if not assert_true(outdoor_newspaper_button != null and outdoor_cooking_oil_button != null and combine_button != null and result_label != null, "Crafting sheet should expose stable direct-crafting controls and item buttons."):
		run_shell.free()
		return

	outdoor_newspaper_button.emit_signal("pressed")
	await process_frame
	if not assert_true(crafting_sheet.has_method("get_highlighted_item_ids"), "Crafting sheet should expose highlighted-item ids for difficulty-aware hint verification."):
		run_shell.free()
		return
	var highlighted_item_ids: Array[String] = crafting_sheet.get_highlighted_item_ids()
	assert_true(
		highlighted_item_ids.has("cooking_oil"),
		"Easy difficulty should highlight at least the dense-fuel-compatible second ingredient after choosing newspaper."
	)
	outdoor_cooking_oil_button.emit_signal("pressed")
	await process_frame
	assert_eq(crafting_sheet.get_highlighted_item_ids(), [], "Selecting both ingredients should clear helper highlights.")
	combine_button.emit_signal("pressed")
	await process_frame

	assert_true(result_label.text.find("고농축 땔감") != -1, "Outdoor crafting should show the crafted dense fuel result.")
	assert_true(
		result_label.text.find("중간 재료") != -1 or result_label.text.find("즉시 사용") != -1 or result_label.text.find("실내 설치") != -1,
		"Craft results should classify the result type."
	)
	assert_eq(run_shell.run_state.inventory.count_item_by_id("dense_fuel"), 1, "Outdoor crafting should add the crafted output.")
	assert_eq(run_shell.run_state.clock.minute_of_day, outdoor_before_clock, "Outdoor crafting should not spend explicit shared-clock minutes.")

	close_button.emit_signal("pressed")
	await process_frame
	assert_true(not crafting_sheet.visible, "Closing the crafting sheet should hide the shared overlay.")

	run_shell.run_state.unlock_recipe("bottled_water__can_stove")
	outdoor_codex_button.emit_signal("pressed")
	await process_frame
	assert_true(crafting_sheet.visible, "Outdoor codex button should reopen the shared sheet.")
	assert_eq(crafting_sheet.get_active_tab_id(), "codex", "Codex button should open the codex tab directly.")
	assert_true(_find_label_containing(crafting_sheet, "신문지 + 식용유 -> 고농축 땔감") != null, "Unlocked dense-fuel recipes should render their real codex row.")
	assert_true(_find_label_containing(crafting_sheet, "도구: 라이터") != null, "Unlocked heat recipes should render their required lighter condition.")

	close_button.emit_signal("pressed")
	await process_frame
	assert_true(not crafting_sheet.visible, "Closing the codex view should hide the shared overlay.")

	outdoor_mode.move_player(Vector2.RIGHT, 1.5)
	outdoor_mode.try_enter_building("mart_01")
	if not await _wait_until(Callable(self, "_is_indoor_ready").bind(run_shell), "Timed out waiting for indoor mode after requesting building entry."):
		run_shell.free()
		return

	var indoor_mode := run_shell.get_node_or_null("ModeHost/IndoorMode")
	var indoor_bag_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/Tools/BagButton") as Button
	var indoor_survival_sheet := indoor_mode.get_node_or_null("SurvivalSheet")
	var indoor_craft_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/Tools/CraftButton") as Button
	var indoor_codex_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/Tools/CodexButton") as Button
	if not assert_true(indoor_bag_button != null and indoor_survival_sheet != null, "Indoor mode should expose its portrait bag entry and SurvivalSheet."):
		run_shell.free()
		return
	assert_true(indoor_craft_button == null and indoor_codex_button == null, "Indoor mode should stop routing through the shared crafting sheet once the portrait SurvivalSheet is mounted.")
	assert_true(not crafting_sheet.visible, "The shared crafting sheet should stay hidden after switching into indoor mode.")

	run_shell.free()

	var crafting_sheet_scene := load(CRAFTING_SHEET_SCENE_PATH) as PackedScene
	if not assert_true(crafting_sheet_scene != null, "Crafting sheet scene should exist for hard-mode hint checks."):
		return
	var hard_crafting_sheet := crafting_sheet_scene.instantiate()
	if not assert_true(hard_crafting_sheet != null, "Crafting sheet should instantiate for hard-mode hint checks."):
		return

	root.add_child(hard_crafting_sheet)
	var hard_run_state_script: Script = load("res://scripts/run/run_state.gd")
	var hard_content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(hard_run_state_script != null and hard_content_library != null, "Hard-mode hint checks require RunState and ContentLibrary."):
		hard_crafting_sheet.free()
		return

	var hard_run_state = hard_run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
		"difficulty": "hard",
	}, hard_content_library)
	if not assert_true(hard_run_state != null, "Hard-mode hint checks should build a run state."):
		hard_crafting_sheet.free()
		return

	hard_run_state.inventory.add_item({"id": "newspaper", "name": "신문지", "bulk": 1})
	hard_run_state.inventory.add_item({"id": "cooking_oil", "name": "식용유", "bulk": 1})
	hard_crafting_sheet.bind_run_state(hard_run_state)
	hard_crafting_sheet.open_for_mode("outdoor")
	await process_frame

	var hard_newspaper_button := hard_crafting_sheet.get_node_or_null("Panel/VBox/DirectPane/InventoryScroll/Items/ItemButton_newspaper") as Button
	if not assert_true(hard_newspaper_button != null, "Hard-mode crafting sheet should still rebuild item buttons."):
		hard_crafting_sheet.free()
		return

	hard_newspaper_button.emit_signal("pressed")
	await process_frame
	assert_eq(hard_crafting_sheet.get_highlighted_item_ids(), [], "Hard difficulty should disable compatibility helper highlights.")
	hard_crafting_sheet.free()

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
