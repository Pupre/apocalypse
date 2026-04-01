extends "res://tests/support/test_case.gd"

const BOOTSTRAP_SCENE_PATH := "res://scenes/bootstrap/main.tscn"

var _confirmed_job_id := ""
var _confirmed_trait_ids: Array[String] = []
var _transition_completed_modes: Array[String] = []


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var bootstrap_scene := load(BOOTSTRAP_SCENE_PATH) as PackedScene
	if not assert_true(bootstrap_scene != null, "Missing bootstrap scene: %s" % BOOTSTRAP_SCENE_PATH):
		return

	var bootstrap = bootstrap_scene.instantiate()
	if not assert_true(bootstrap != null, "Failed to instantiate bootstrap scene."):
		return

	root.add_child(bootstrap)

	var active_screen: Node = bootstrap.get_active_screen()
	if not assert_true(active_screen != null, "Bootstrap should show an active screen."):
		bootstrap.free()
		return
	assert_eq(active_screen.name, "TitleMenu", "Bootstrap should start on the title menu.")

	var start_button := active_screen.get_node_or_null("Center/Panel/VBox/StartButton") as Button
	if not assert_true(start_button != null, "Title menu start button is missing."):
		bootstrap.free()
		return

	start_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_active_screen_name_is").bind(bootstrap, "SurvivorCreator"),
		"Timed out waiting for the survivor creator screen."
	):
		bootstrap.free()
		return

	active_screen = bootstrap.get_active_screen()
	if not assert_true(active_screen != null, "Bootstrap should show the survivor creator after start."):
		bootstrap.free()
		return
	assert_eq(active_screen.name, "SurvivorCreator", "Start should swap to the survivor creator.")

	var survivor_creator: Node = active_screen
	if not assert_true(survivor_creator.has_signal("survivor_confirmed"), "Survivor creator should emit survivor_confirmed."):
		bootstrap.free()
		return

	survivor_creator.survivor_confirmed.connect(Callable(self, "_on_survivor_confirmed"))

	var courier_button := survivor_creator.get_node_or_null("Center/Panel/VBox/JobButtons/CourierButton") as Button
	var athlete_button := survivor_creator.get_node_or_null("Center/Panel/VBox/TraitButtons/AthleteButton") as CheckButton
	var unlucky_button := survivor_creator.get_node_or_null("Center/Panel/VBox/TraitButtons/UnluckyButton") as CheckButton
	var confirm_button := survivor_creator.get_node_or_null("Center/Panel/VBox/ConfirmButton") as Button

	if not assert_true(courier_button != null, "Courier button is missing."):
		bootstrap.free()
		return
	if not assert_true(athlete_button != null, "Athlete trait button is missing."):
		bootstrap.free()
		return
	if not assert_true(unlucky_button != null, "Unlucky trait button is missing."):
		bootstrap.free()
		return
	if not assert_true(confirm_button != null, "Confirm button is missing."):
		bootstrap.free()
		return

	courier_button.emit_signal("pressed")
	athlete_button.button_pressed = true
	unlucky_button.button_pressed = true

	var survivor_config: Dictionary = survivor_creator.get_survivor_config()
	assert_eq(String(survivor_config.get("job_id", "")), "courier", "The creator should build the selected job payload.")
	assert_eq(Array(survivor_config.get("trait_ids", [])), ["athlete", "unlucky"], "The creator should preserve the selected trait order.")
	assert_eq(int(survivor_config.get("remaining_points", -1)), 0, "The creator payload should spend all available points.")
	assert_true(not confirm_button.disabled, "The creator confirm button should be enabled before confirmation.")

	confirm_button.emit_signal("pressed")
	assert_eq(_confirmed_job_id, "courier", "Confirm should emit the selected job id.")
	assert_eq(_confirmed_trait_ids, ["athlete", "unlucky"], "Confirm should emit the selected trait order.")
	if not await _wait_until(
		Callable(self, "_active_screen_name_is").bind(bootstrap, "RunShell"),
		"Timed out waiting for the run shell screen."
	):
		bootstrap.free()
		return

	var run_shell: Node = bootstrap.get_node_or_null("RunShell")
	if not assert_true(run_shell != null, "Bootstrap should swap to the run shell after confirmation."):
		bootstrap.free()
		return

	if not assert_true(run_shell.has_method("get_current_mode_name"), "RunController should expose get_current_mode_name() for smoke verification."):
		bootstrap.free()
		return
	if not assert_true(run_shell.has_signal("transition_completed"), "RunController should expose transition_completed for smoke verification."):
		bootstrap.free()
		return
	if not assert_true(
		run_shell.has_method("is_transition_in_progress"),
		"RunController should expose is_transition_in_progress() for smoke verification."
	):
		bootstrap.free()
		return

	assert_eq(run_shell.get_current_mode_name(), "outdoor", "The run should begin in outdoor mode.")
	assert_true(
		not run_shell.is_transition_in_progress(),
		"The run should start without a mode transition in progress."
	)

	var hud: Node = run_shell.get_node_or_null("HUD")
	var transition_layer: Node = run_shell.get_node_or_null("TransitionLayer")
	if not assert_true(hud != null, "Run shell should include a HUD."):
		bootstrap.free()
		return
	if not assert_true(transition_layer != null, "Run shell should include a transition layer."):
		bootstrap.free()
		return
	if not assert_true(
		transition_layer.has_method("set_duration_for_tests"),
		"Transition layer should expose set_duration_for_tests()."
	):
		bootstrap.free()
		return

	transition_layer.set_duration_for_tests(0.0)

	var hud_clock_label := hud.get_node_or_null("Panel/VBox/ClockLabel") as Label
	if not assert_true(hud_clock_label != null, "HUD clock label should be present."):
		bootstrap.free()
		return
	assert_eq(hud_clock_label.text, "1일차 08:00", "The run should start at 08:00.")

	var hud_title_label := hud.get_node_or_null("Panel/VBox/TitleLabel") as Label
	if not assert_true(hud_title_label != null, "HUD title label should be present."):
		bootstrap.free()
		return
	assert_eq(hud_title_label.text, "외부 생존 정보", "Outdoor mode should use the outdoor HUD title.")

	var fade_rect := transition_layer.get_node_or_null("FadeRect") as ColorRect
	if not assert_true(fade_rect != null, "Transition layer should expose a FadeRect node."):
		bootstrap.free()
		return
	assert_eq(fade_rect.color.a, 0.0, "The transition layer should start transparent.")

	var outdoor_mode: Node = run_shell.get_node_or_null("ModeHost/OutdoorMode")
	if not assert_true(outdoor_mode != null, "Run shell should launch the outdoor mode first."):
		bootstrap.free()
		return

	var player_marker := outdoor_mode.get_node_or_null("PlayerMarker") as Polygon2D
	var building_marker := outdoor_mode.get_node_or_null("BuildingMarker") as Polygon2D
	if not assert_true(player_marker != null, "Outdoor player marker should be present."):
		bootstrap.free()
		return
	if not assert_true(building_marker != null, "Outdoor building marker should be present."):
		bootstrap.free()
		return

	var before_outdoor_minutes: int = run_shell.run_state.clock.minute_of_day
	outdoor_mode.simulate_seconds(120.0)
	assert_eq(run_shell.run_state.clock.minute_of_day, before_outdoor_minutes + 120, "Outdoor time should advance the shared clock.")
	assert_eq(hud_clock_label.text, "1일차 10:00", "HUD time should reflect outdoor time spent.")

	outdoor_mode.move_player(Vector2.RIGHT, 1.5)
	assert_true(player_marker.position.distance_to(building_marker.position) <= 72.0, "The player should move into building entry range.")
	var pre_entry_player_position := player_marker.position

	outdoor_mode.try_enter_building("mart_01")
	if not await _await_transition_completion(
		run_shell,
		hud_title_label,
		fade_rect,
		"indoor",
		"실내 생존 정보",
		"IndoorMode",
		"Timed out waiting for the enter transition to settle on indoor mode."
	):
		bootstrap.free()
		return

	assert_eq(run_shell.get_current_mode_name(), "indoor", "Entering the building should swap the run shell to indoor mode.")
	assert_eq(hud_title_label.text, "실내 생존 정보", "Indoor mode should switch the shared HUD presentation.")
	assert_eq(fade_rect.color.a, 0.0, "The transition layer should end transparent after entering a building.")

	var indoor_mode: Node = run_shell.get_node_or_null("ModeHost/IndoorMode")
	if not assert_true(indoor_mode != null, "Run shell should contain the indoor mode after entry."):
		bootstrap.free()
		return

	var location_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/Header/LocationLabel") as Label
	if not assert_true(location_label != null, "Indoor mode should expose a location label."):
		bootstrap.free()
		return
	assert_eq(location_label.text, "위치: 정문 진입부", "Indoor mode should begin at the mart entrance zone.")

	var indoor_time_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/Header/TimeLabel") as Label
	if not assert_true(indoor_time_label != null, "Indoor mode should expose a visible time label."):
		bootstrap.free()
		return
	assert_eq(indoor_time_label.text, "시각: 1일차 10:00", "Indoor mode should carry the shared clock into the indoor UI.")

	var summary_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/SummaryLabel") as Label
	if not assert_true(summary_label != null, "Indoor mode should expose a current-zone summary label."):
		bootstrap.free()
		return
	assert_eq(summary_label.text, "깨진 자동문과 쓰러진 장바구니가 보인다.", "Indoor mode should describe the current entrance zone.")

	var clue_list := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ClueList") as VBoxContainer
	assert_true(clue_list == null, "Indoor mode should not expose a persistent clue list in the main layout.")

	var sleep_preview_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/SleepPreviewLabel") as Label
	assert_true(sleep_preview_label == null, "Indoor mode should not expose sleep preview in the main layout.")

	var action_buttons := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ActionButtons") as VBoxContainer
	if not assert_true(action_buttons != null, "Indoor action buttons should be mounted in the UI tree."):
		bootstrap.free()
		return
	if not assert_true(action_buttons.get_child_count() > 0, "The indoor UI should expose at least one action button."):
		bootstrap.free()
		return
	assert_true(
		_buttons_include_text(action_buttons, "계산대로 이동한다 (30분)"),
		"The entrance zone should show move actions with their time cost."
	)
	assert_true(
		_buttons_include_text(action_buttons, "건물 밖으로 나간다"),
		"The entrance zone should expose leaving the building as a contextual action."
	)
	assert_true(
		not _buttons_include_text(action_buttons, "한 시간 쉰다 (60분)"),
		"Indoor mode should not expose the removed flat rest action."
	)

	var minimap_nodes := indoor_mode.get_node_or_null("Panel/Layout/Sidebar/MinimapPanel/VBox/MapNodes") as Control
	if not assert_true(minimap_nodes != null, "Indoor mode should expose a minimap node container."):
		bootstrap.free()
		return
	assert_eq(_map_labels(minimap_nodes), ["?", "?", "정문 진입부"], "Indoor minimap should start with the current zone and adjacent unknown rooms only.")

	var inventory_items := indoor_mode.get_node_or_null("Panel/Layout/Sidebar/InventoryPanel/VBox/InventoryItems") as VBoxContainer
	if not assert_true(inventory_items != null, "Indoor mode should expose an inventory item list."):
		bootstrap.free()
		return
	assert_eq(_inventory_labels(inventory_items), ["소지품 없음"], "Indoor inventory should start empty before any loot.")

	var move_checkout_button := _find_button_by_text(action_buttons, "계산대로 이동한다 (30분)")
	if not assert_true(move_checkout_button != null, "Indoor mode should expose a movement action into checkout."):
		bootstrap.free()
		return
	assert_true(not move_checkout_button.disabled, "The checkout movement action should be enabled before it is pressed.")

	var result_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ResultLabel") as Label
	if not assert_true(result_label != null, "Indoor result label should be present."):
		bootstrap.free()
		return

	move_checkout_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_label_text_is").bind(location_label, "위치: 계산대"),
		"Timed out waiting for the indoor location to change to checkout."
	):
		bootstrap.free()
		return
	assert_eq(indoor_time_label.text, "시각: 1일차 10:30", "Indoor mode should update the visible time after moving.")
	assert_eq(summary_label.text, "계산대 뒤쪽에는 직원 출입문이 있다.", "Indoor mode should update the summary for the checkout zone.")

	assert_true(
		_buttons_include_text(action_buttons, "계산대를 탐색한다 (30분)"),
		"Checkout should expose its local search action."
	)
	assert_eq(_map_labels(minimap_nodes), ["?", "계산대", "정문 진입부"], "Indoor minimap should keep visited zones visible after moving.")
	assert_true(
		not _buttons_include_text(action_buttons, "건물 밖으로 나간다"),
		"Leaving the building should not stay visible away from the entrance."
	)

	var checkout_search_button := _find_button_by_text(action_buttons, "계산대를 탐색한다 (30분)")
	if not assert_true(checkout_search_button != null, "Checkout search action should be selectable."):
		bootstrap.free()
		return

	checkout_search_button.emit_signal("pressed")
	if not await _wait_until(
			Callable(self, "_is_indoor_action_applied").bind(
				run_shell,
				hud_clock_label,
				result_label,
				action_buttons,
				0,
				"1일차 11:00",
				"발견했다.",
				-1
			),
			"Timed out waiting for the checkout search to apply."
	):
		bootstrap.free()
		return

	assert_eq(run_shell.run_state.inventory.total_bulk(), 0, "Searching should not add loot to inventory until the player picks an item.")
	assert_eq(hud_clock_label.text, "1일차 11:00", "The checkout search should advance shared time.")
	assert_true(result_label.text.find("30분 동안 탐색했다.") != -1, "Indoor feedback should describe the spent time.")
	assert_true(result_label.text.find("라이터") != -1, "Indoor feedback should mention a discovered item.")
	assert_eq(_inventory_labels(inventory_items), ["소지품 없음"], "Indoor inventory should stay empty until the player chooses loot.")

	var take_lighter_button := _find_button_by_text(action_buttons, "라이터 챙긴다")
	if not assert_true(take_lighter_button != null, "Searching checkout should reveal a take action for the lighter."):
		bootstrap.free()
		return

	take_lighter_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_is_indoor_action_applied").bind(
			run_shell,
			hud_clock_label,
			result_label,
			action_buttons,
			1,
			"1일차 11:00",
			"라이터 챙겼다.",
			-1
		),
		"Timed out waiting for the take-loot action to apply."
	):
		bootstrap.free()
		return

	assert_eq(run_shell.run_state.inventory.total_bulk(), 1, "Picking a revealed item should add it to inventory.")
	assert_eq(_inventory_labels(inventory_items), ["라이터 x1"], "Indoor inventory should list the picked item.")

	var return_to_entrance_button := _find_button_by_text(action_buttons, "정문 진입부로 이동한다 (10분)")
	if not assert_true(return_to_entrance_button != null, "Checkout should allow returning to the entrance zone."):
		bootstrap.free()
		return

	return_to_entrance_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_label_text_is").bind(location_label, "위치: 정문 진입부"),
		"Timed out waiting for the indoor location to return to the entrance."
	):
		bootstrap.free()
		return
	assert_eq(indoor_time_label.text, "시각: 1일차 11:10", "Indoor mode should keep the visible time in sync after returning to the entrance.")
	assert_true(
		_buttons_include_text(action_buttons, "건물 밖으로 나간다"),
		"The entrance zone should restore the contextual leave-building action."
	)

	var exit_action_button := _find_button_by_text(action_buttons, "건물 밖으로 나간다")
	if not assert_true(exit_action_button != null, "Indoor mode should expose a leave-building action at the entrance."):
		bootstrap.free()
		return

	exit_action_button.emit_signal("pressed")
	if not await _await_transition_completion(
		run_shell,
		hud_title_label,
		fade_rect,
		"outdoor",
		"외부 생존 정보",
		"OutdoorMode",
		"Timed out waiting for the exit transition to settle on outdoor mode."
	):
		bootstrap.free()
		return

	assert_eq(run_shell.get_current_mode_name(), "outdoor", "Pressing the entrance leave action should return the run shell to outdoor mode.")
	assert_eq(hud_title_label.text, "외부 생존 정보", "Returning outside should restore the outdoor HUD presentation.")
	assert_eq(fade_rect.color.a, 0.0, "The transition layer should end transparent after leaving the building.")

	outdoor_mode = run_shell.get_node_or_null("ModeHost/OutdoorMode")
	if not assert_true(outdoor_mode != null, "Run shell should recreate the outdoor mode after exit."):
		bootstrap.free()
		return

	player_marker = outdoor_mode.get_node_or_null("PlayerMarker") as Polygon2D
	if not assert_true(player_marker != null, "Outdoor mode should restore the player marker after exit."):
		bootstrap.free()
		return
	assert_true(
		player_marker.position.distance_to(pre_entry_player_position) <= 0.01,
		"Exiting the building should restore the previous outdoor player position."
	)

	bootstrap.free()
	bootstrap = null
	bootstrap_scene = null

	pass_test("FIRST_PLAYABLE_LOOP_OK")


func _on_survivor_confirmed(job_id: String, trait_ids: Array[String]) -> void:
	_confirmed_job_id = job_id
	_confirmed_trait_ids = trait_ids.duplicate()


func _active_screen_name_is(bootstrap: Node, expected_name: String) -> bool:
	if bootstrap == null or not bootstrap.has_method("get_active_screen"):
		return false

	var active_screen: Node = bootstrap.get_active_screen()
	return active_screen != null and active_screen.name == expected_name


func _find_button_by_text(container: VBoxContainer, text: String) -> Button:
	if container == null:
		return null

	for child in container.get_children():
		var button := child as Button
		if button != null and button.text == text:
			return button

	return null


func _buttons_include_text(container: VBoxContainer, text: String) -> bool:
	return _find_button_by_text(container, text) != null


func _label_text_is(label: Label, expected_text: String) -> bool:
	return label != null and label.text == expected_text


func _await_transition_completion(
	run_shell: Node,
	hud_title_label: Label,
	fade_rect: ColorRect,
	expected_mode_name: String,
	expected_hud_title: String,
	expected_mode_node_name: String,
	failure_message: String,
	max_frames: int = 30
) -> bool:
	_transition_completed_modes.clear()
	run_shell.transition_completed.connect(Callable(self, "_on_transition_completed"))
	var predicate := Callable(self, "_is_transition_settled").bind(
		run_shell,
		hud_title_label,
		fade_rect,
		expected_mode_name,
		expected_hud_title,
		expected_mode_node_name
	)
	var result := await _wait_until(predicate, failure_message, max_frames)
	if run_shell.transition_completed.is_connected(Callable(self, "_on_transition_completed")):
		run_shell.transition_completed.disconnect(Callable(self, "_on_transition_completed"))
	return result


func _wait_until(predicate: Callable, failure_message: String, max_frames: int = 30) -> bool:
	for _i in range(max_frames):
		if predicate.call():
			return true
		await process_frame

	return assert_true(predicate.call(), failure_message)


func _is_indoor_action_applied(
	run_shell: Node,
	hud_clock_label: Label,
	result_label: Label,
	action_buttons: VBoxContainer,
	expected_inventory_bulk: int,
	expected_clock_text: String,
	expected_feedback_substring: String,
	expected_action_count: int
) -> bool:
	if run_shell == null or hud_clock_label == null or result_label == null or action_buttons == null:
		return false

	return (
		run_shell.run_state.inventory.total_bulk() == expected_inventory_bulk
		and hud_clock_label.text == expected_clock_text
		and result_label.text.find(expected_feedback_substring) != -1
		and (expected_action_count < 0 or action_buttons.get_child_count() == expected_action_count)
	)


func _map_labels(container: Control) -> Array[String]:
	var labels: Array[String] = []
	if container == null:
		return labels

	for child in container.get_children():
		var label := child as Label
		if label != null:
			labels.append(label.text)

	labels.sort()
	return labels


func _inventory_labels(container: VBoxContainer) -> Array[String]:
	var labels: Array[String] = []
	if container == null:
		return labels

	for child in container.get_children():
		var button := child as Button
		if button != null:
			labels.append(button.text)
			continue
		var label := child as Label
		if label != null:
			labels.append(label.text)
			continue
		if child is Container:
			for nested_child in child.get_children():
				var nested_button := nested_child as Button
				if nested_button != null:
					labels.append(nested_button.text)
					break
				var nested_label := nested_child as Label
				if nested_label != null:
					labels.append(nested_label.text)
					break

	return labels


func _is_transition_settled(
	run_shell: Node,
	hud_title_label: Label,
	fade_rect: ColorRect,
	expected_mode_name: String,
	expected_hud_title: String,
	expected_mode_node_name: String
) -> bool:
	if run_shell == null or hud_title_label == null or fade_rect == null:
		return false
	if not run_shell.has_method("get_current_mode_name"):
		return false
	if not run_shell.has_method("is_transition_in_progress"):
		return false

	var mode_host := run_shell.get_node_or_null("ModeHost")
	if mode_host == null:
		return false

	return (
		_transition_completed_modes.has(expected_mode_name)
		and run_shell.get_current_mode_name() == expected_mode_name
		and not run_shell.is_transition_in_progress()
		and hud_title_label.text == expected_hud_title
		and is_equal_approx(fade_rect.color.a, 0.0)
		and mode_host.get_node_or_null(expected_mode_node_name) != null
	)


func _on_transition_completed(mode_name: String) -> void:
	if not _transition_completed_modes.has(mode_name):
		_transition_completed_modes.append(mode_name)
