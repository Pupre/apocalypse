extends "res://tests/support/test_case.gd"

const RUN_SHELL_SCENE_PATH := "res://scenes/run/run_shell.tscn"


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

	var outdoor_mode := run_shell.get_node_or_null("ModeHost/OutdoorMode")
	if not assert_true(outdoor_mode != null, "Run shell should start in outdoor mode for crafting tests."):
		run_shell.free()
		return

	var outdoor_craft_button := outdoor_mode.get_node_or_null("CanvasLayer/StatusPanel/VBox/CraftButton") as Button
	if not assert_true(outdoor_craft_button != null, "Outdoor mode should expose a craft button that opens the shared sheet."):
		run_shell.free()
		return

	run_shell.run_state.inventory.add_item({"id": "newspaper", "name": "신문지", "bulk": 1})
	run_shell.run_state.inventory.add_item({"id": "cooking_oil", "name": "식용유", "bulk": 1})
	var outdoor_before_clock: int = run_shell.run_state.clock.minute_of_day

	outdoor_craft_button.emit_signal("pressed")
	await process_frame

	assert_true(crafting_sheet.visible, "Outdoor craft button should open the shared crafting sheet.")
	assert_true(crafting_sheet.has_method("get_context_mode_name"), "Crafting sheet should expose its current context mode for verification.")
	assert_eq(crafting_sheet.get_context_mode_name(), "outdoor", "Outdoor craft button should open the sheet in outdoor mode.")

	var outdoor_newspaper_button := crafting_sheet.get_node_or_null("Panel/VBox/InventoryScroll/Items/ItemButton_newspaper") as Button
	var outdoor_cooking_oil_button := crafting_sheet.get_node_or_null("Panel/VBox/InventoryScroll/Items/ItemButton_cooking_oil") as Button
	var combine_button := crafting_sheet.get_node_or_null("Panel/VBox/SlotsRow/CombineButton") as Button
	var close_button := crafting_sheet.get_node_or_null("Panel/VBox/Header/CloseButton") as Button
	var result_label := crafting_sheet.get_node_or_null("Panel/VBox/ResultCard/ResultLabel") as Label
	if not assert_true(outdoor_newspaper_button != null and outdoor_cooking_oil_button != null and combine_button != null and close_button != null and result_label != null, "Crafting sheet should expose stable controls and item buttons."):
		run_shell.free()
		return

	outdoor_newspaper_button.emit_signal("pressed")
	await process_frame
	outdoor_cooking_oil_button.emit_signal("pressed")
	await process_frame
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

	outdoor_mode.move_player(Vector2.RIGHT, 1.5)
	outdoor_mode.try_enter_building("mart_01")
	if not await _wait_until(Callable(self, "_is_indoor_ready").bind(run_shell), "Timed out waiting for indoor mode after requesting building entry."):
		run_shell.free()
		return

	var indoor_mode := run_shell.get_node_or_null("ModeHost/IndoorMode")
	var indoor_craft_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/Tools/CraftButton") as Button
	if not assert_true(indoor_craft_button != null, "Indoor mode should expose a craft button that opens the shared sheet."):
		run_shell.free()
		return

	run_shell.run_state.inventory.add_item({"id": "newspaper", "name": "신문지", "bulk": 1})
	run_shell.run_state.inventory.add_item({"id": "bottled_water", "name": "생수", "bulk": 1})
	var indoor_before_clock: int = run_shell.run_state.clock.minute_of_day

	indoor_craft_button.emit_signal("pressed")
	await process_frame

	assert_true(crafting_sheet.visible, "Indoor craft button should reopen the same shared crafting sheet instance.")
	assert_eq(crafting_sheet.get_context_mode_name(), "indoor", "Indoor craft button should open the sheet in indoor mode.")

	var indoor_newspaper_button := crafting_sheet.get_node_or_null("Panel/VBox/InventoryScroll/Items/ItemButton_newspaper") as Button
	var indoor_bottled_water_button := crafting_sheet.get_node_or_null("Panel/VBox/InventoryScroll/Items/ItemButton_bottled_water") as Button
	if not assert_true(indoor_newspaper_button != null and indoor_bottled_water_button != null, "Crafting sheet should rebuild its item list for indoor inventory state."):
		run_shell.free()
		return

	indoor_newspaper_button.emit_signal("pressed")
	await process_frame
	indoor_bottled_water_button.emit_signal("pressed")
	await process_frame
	combine_button = crafting_sheet.get_node_or_null("Panel/VBox/SlotsRow/CombineButton") as Button
	result_label = crafting_sheet.get_node_or_null("Panel/VBox/ResultCard/ResultLabel") as Label
	combine_button.emit_signal("pressed")
	await process_frame

	assert_true(result_label.text.find("젖은 신문지") != -1, "Indoor crafting should show the configured failure result item.")
	assert_eq(run_shell.run_state.inventory.count_item_by_id("wet_newspaper"), 1, "Indoor crafting should add the configured failure output.")
	assert_true(run_shell.run_state.clock.minute_of_day > indoor_before_clock, "Indoor crafting should advance the shared clock.")

	run_shell.free()
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
