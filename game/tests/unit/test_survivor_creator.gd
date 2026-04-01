extends "res://tests/support/test_case.gd"

const BOOTSTRAP_SCENE_PATH := "res://scenes/bootstrap/main.tscn"

var _confirmed := false
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

	var title_menu = bootstrap.get_node_or_null("TitleMenu")
	if not assert_true(title_menu != null, "Bootstrap should show the title menu first."):
		bootstrap.free()
		return

	var start_button := title_menu.get_node_or_null("Center/Panel/VBox/StartButton") as Button
	if not assert_true(start_button != null, "Title menu start button is missing."):
		bootstrap.free()
		return

	start_button.emit_signal("pressed")

	var survivor_creator = bootstrap.get_node_or_null("SurvivorCreator")
	if not assert_true(survivor_creator != null, "Bootstrap should swap to the survivor creator after start."):
		bootstrap.free()
		return

	if not assert_true(bootstrap.get_node_or_null("TitleMenu") == null, "Title menu should be replaced after start."):
		bootstrap.free()
		return

	if not assert_true(survivor_creator.has_signal("survivor_confirmed"), "Survivor creator should expose survivor_confirmed."):
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

	assert_true(confirm_button.disabled, "Confirm should be gated until the selection is valid.")

	courier_button.emit_signal("pressed")
	athlete_button.button_pressed = true
	unlucky_button.button_pressed = true

	assert_eq(survivor_creator.job_id, "courier", "Expected courier to be the selected job.")
	assert_eq(survivor_creator.trait_ids, ["athlete", "unlucky"], "Traits should preserve selection order.")
	assert_eq(survivor_creator.remaining_points, 0, "Expected selected traits to spend all points.")
	assert_true(not confirm_button.disabled, "Confirm should enable once the selection is valid.")

	confirm_button.emit_signal("pressed")

	assert_true(_confirmed, "Confirm should emit survivor_confirmed.")
	assert_eq(_confirmed_job_id, "courier", "Confirmed job should match the selected job.")
	assert_eq(_confirmed_trait_ids, ["athlete", "unlucky"], "Confirmed trait order should match the selection order.")

	var run_shell = bootstrap.get_node_or_null("RunShell")
	if not assert_true(run_shell != null, "Bootstrap should swap to the run shell after survivor confirmation."):
		bootstrap.free()
		return

	if not assert_true(bootstrap.get_node_or_null("SurvivorCreator") == null, "Survivor creator should be replaced by the run shell."):
		bootstrap.free()
		return

	var hud = run_shell.get_node_or_null("HUD")
	var mode_host = run_shell.get_node_or_null("ModeHost")
	var outdoor_mode = run_shell.get_node_or_null("ModeHost/OutdoorMode")
	var transition_layer = run_shell.get_node_or_null("TransitionLayer")

	if not assert_true(hud != null, "Run shell should include a HUD."):
		bootstrap.free()
		return
	if not assert_true(mode_host != null, "Run shell should include a mode host."):
		bootstrap.free()
		return
	if not assert_true(outdoor_mode != null, "Run shell should launch the first outdoor mode."):
		bootstrap.free()
		return
	if not assert_true(transition_layer != null, "Run shell should include a transition layer."):
		bootstrap.free()
		return
	if not assert_true(run_shell.has_signal("transition_completed"), "RunController should expose transition_completed for creator verification."):
		bootstrap.free()
		return

	if not assert_true(outdoor_mode.has_method("try_enter_building"), "Outdoor mode should expose building entry."):
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
	assert_eq(hud_clock_label.text, "1일차 08:00", "The run shell should start at the run-state clock.")

	var player_marker := outdoor_mode.get_node_or_null("PlayerMarker") as Polygon2D
	var building_marker := outdoor_mode.get_node_or_null("BuildingMarker") as Polygon2D
	if not assert_true(player_marker != null, "Outdoor player marker should be present."):
		bootstrap.free()
		return
	if not assert_true(building_marker != null, "Outdoor building marker should be present."):
		bootstrap.free()
		return

	assert_true(player_marker.position.distance_to(building_marker.position) > 72.0, "The run should start outside the entry radius.")

	outdoor_mode.move_player(Vector2.RIGHT, 1.5)
	assert_true(player_marker.position.distance_to(building_marker.position) <= 72.0, "Moving right should bring the player into entry range.")

	outdoor_mode.try_enter_building("mart_01")
	if not await _await_transition_completion(
		run_shell,
		"indoor",
		"Timed out waiting for the creator flow to enter indoor mode."
	):
		bootstrap.free()
		return

	var indoor_mode = run_shell.get_node_or_null("ModeHost/IndoorMode")
	if not assert_true(indoor_mode != null, "Entering a building should swap to the indoor mode."):
		bootstrap.free()
		return
	var result_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ResultLabel") as Label
	var action_buttons := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ActionButtons") as VBoxContainer
	if not assert_true(result_label != null, "Indoor result label should be present."):
		bootstrap.free()
		return
	if not assert_true(action_buttons != null, "Indoor action buttons container should be present."):
		bootstrap.free()
		return
	assert_true(action_buttons.get_child_count() >= 1, "Mart indoor mode should expose at least one indoor action.")
	assert_true(
		_find_button_by_text(action_buttons, "계산대를 수색한다 (30분)") == null,
		"The mart entrance should not expose checkout-only search actions."
	)

	var move_checkout_button := _find_button_by_text(action_buttons, "계산대로 이동한다 (30분)")
	if not assert_true(move_checkout_button != null, "The mart entrance should expose movement into the checkout zone."):
		bootstrap.free()
		return

	var location_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/Header/LocationLabel") as Label
	if not assert_true(location_label != null, "Indoor mode should expose a location label in the creator flow."):
		bootstrap.free()
		return

	move_checkout_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_label_text_is").bind(location_label, "위치: 계산대"),
		"Timed out waiting for the creator flow to move into checkout."
	):
		bootstrap.free()
		return

	var search_button := _find_button_by_text(action_buttons, "조용히 서랍을 연다 (30분)")
	if not assert_true(search_button != null, "Checkout should expose the drawer search after moving there."):
		bootstrap.free()
		return

	var expected_feedback := "30분 동안 수색했다."
	search_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_is_indoor_action_applied").bind(
			run_shell,
			hud_clock_label,
			result_label,
			action_buttons,
			"1일차 09:00",
			expected_feedback,
			2
		),
		"Timed out waiting for the indoor action result to settle."
	):
		bootstrap.free()
		return

	assert_eq(hud_clock_label.text, "1일차 09:00", "Moving into checkout and then searching should advance the HUD clock.")
	assert_true(result_label.text.find(expected_feedback) != -1, "Pressing the indoor action should refresh the result feedback.")
	assert_true(
		_find_button_by_text(action_buttons, "조용히 서랍을 연다 (30분)") == null,
		"The one-shot search action should be removed after use."
	)

	bootstrap.free()
	bootstrap = null
	bootstrap_scene = null

	pass_test("SURVIVOR_CREATOR_OK")


func _on_survivor_confirmed(job_id: String, trait_ids: Array[String]) -> void:
	_confirmed = true
	_confirmed_job_id = job_id
	_confirmed_trait_ids = trait_ids.duplicate()


func _await_transition_completion(run_shell: Node, expected_mode_name: String, failure_message: String, max_frames: int = 30) -> bool:
	_transition_completed_modes.clear()
	run_shell.transition_completed.connect(Callable(self, "_on_transition_completed"))
	var predicate := Callable(self, "_has_transition_completed").bind(run_shell, expected_mode_name)
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
	expected_clock_text: String,
	expected_feedback_substring: String,
	expected_action_count: int
) -> bool:
	if run_shell == null or hud_clock_label == null or result_label == null or action_buttons == null:
		return false

	return (
		run_shell.run_state.inventory.total_bulk() == 1
		and hud_clock_label.text == expected_clock_text
		and result_label.text.find(expected_feedback_substring) != -1
		and action_buttons.get_child_count() == expected_action_count
	)


func _find_button_by_text(container: VBoxContainer, expected_text: String) -> Button:
	if container == null:
		return null

	for child in container.get_children():
		var button := child as Button
		if button != null and button.text == expected_text:
			return button

	return null


func _label_text_is(label: Label, expected_text: String) -> bool:
	return label != null and label.text == expected_text


func _has_transition_completed(run_shell: Node, expected_mode_name: String) -> bool:
	if run_shell == null:
		return false
	if not run_shell.has_method("get_current_mode_name"):
		return false
	if not run_shell.has_method("is_transition_in_progress"):
		return false

	return (
		_transition_completed_modes.has(expected_mode_name)
		and run_shell.get_current_mode_name() == expected_mode_name
		and not run_shell.is_transition_in_progress()
	)


func _on_transition_completed(mode_name: String) -> void:
	if not _transition_completed_modes.has(mode_name):
		_transition_completed_modes.append(mode_name)
