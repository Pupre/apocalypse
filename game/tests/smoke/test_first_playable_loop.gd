extends "res://tests/support/test_case.gd"

const BOOTSTRAP_SCENE_PATH := "res://scenes/bootstrap/main.tscn"

var _confirmed_job_id := ""
var _confirmed_trait_ids: Array[String] = []


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
	await process_frame

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

	confirm_button.emit_signal("pressed")
	assert_eq(_confirmed_job_id, "courier", "Confirm should emit the selected job id.")
	assert_eq(_confirmed_trait_ids, ["athlete", "unlucky"], "Confirm should emit the selected trait order.")

	await process_frame

	var run_shell: Node = bootstrap.get_node_or_null("RunShell")
	if not assert_true(run_shell != null, "Bootstrap should swap to the run shell after confirmation."):
		bootstrap.free()
		return

	if not assert_true(run_shell.has_method("get_current_mode_name"), "RunController should expose get_current_mode_name() for smoke verification."):
		bootstrap.free()
		return

	assert_eq(run_shell.get_current_mode_name(), "outdoor", "The run should begin in outdoor mode.")

	var hud: Node = run_shell.get_node_or_null("HUD")
	if not assert_true(hud != null, "Run shell should include a HUD."):
		bootstrap.free()
		return

	var hud_clock_label := hud.get_node_or_null("Panel/VBox/ClockLabel") as Label
	if not assert_true(hud_clock_label != null, "HUD clock label should be present."):
		bootstrap.free()
		return
	assert_eq(hud_clock_label.text, "Day 1 08:00", "The run should start at 08:00.")

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
	assert_eq(hud_clock_label.text, "Day 1 10:00", "HUD time should reflect outdoor time spent.")

	outdoor_mode.move_player(Vector2.RIGHT, 1.5)
	assert_true(player_marker.position.distance_to(building_marker.position) <= 72.0, "The player should move into building entry range.")

	outdoor_mode.try_enter_building("mart_01")
	await process_frame

	assert_eq(run_shell.get_current_mode_name(), "indoor", "Entering the building should swap the run shell to indoor mode.")

	var indoor_mode: Node = run_shell.get_node_or_null("ModeHost/IndoorMode")
	if not assert_true(indoor_mode != null, "Run shell should contain the indoor mode after entry."):
		bootstrap.free()
		return

	var action_buttons := indoor_mode.get_node_or_null("Panel/VBox/ActionButtons") as VBoxContainer
	if not assert_true(action_buttons != null, "Indoor action buttons should be mounted in the UI tree."):
		bootstrap.free()
		return
	if not assert_true(action_buttons.get_child_count() > 0, "The indoor UI should expose at least one action button."):
		bootstrap.free()
		return

	var first_action_button := action_buttons.get_child(0) as Button
	if not assert_true(first_action_button != null, "The first indoor action should be a button."):
		bootstrap.free()
		return
	assert_true(not first_action_button.disabled, "The first indoor action should be enabled before it is pressed.")

	first_action_button.emit_signal("pressed")
	await process_frame

	assert_eq(run_shell.run_state.inventory.total_bulk(), 1, "The first indoor action should add loot to inventory.")
	assert_eq(hud_clock_label.text, "Day 1 10:30", "The first indoor action should advance shared time.")

	var result_label := indoor_mode.get_node_or_null("Panel/VBox/ResultLabel") as Label
	if not assert_true(result_label != null, "Indoor result label should be present."):
		bootstrap.free()
		return
	assert_true(result_label.text.find("Spent 30 minutes searching.") != -1, "Indoor feedback should describe the spent time.")

	bootstrap.free()
	bootstrap = null
	bootstrap_scene = null

	pass_test("FIRST_PLAYABLE_LOOP_OK")


func _on_survivor_confirmed(job_id: String, trait_ids: Array[String]) -> void:
	_confirmed_job_id = job_id
	_confirmed_trait_ids = trait_ids.duplicate()
