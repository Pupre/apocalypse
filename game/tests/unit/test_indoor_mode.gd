extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const INDOOR_MODE_SCENE_PATH := "res://scenes/indoor/indoor_mode.tscn"

var _test_jobs: Dictionary = {
	"courier": {
		"id": "courier",
		"modifiers": {
			"move_speed": 30.0,
			"fatigue_gain": -0.1,
		},
	},
}

var _test_traits: Dictionary = {
	"athlete": {
		"id": "athlete",
		"modifiers": {
			"move_speed": 40.0,
			"fatigue_gain": -0.15,
		},
	},
}

var _exit_requested_count := 0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	var indoor_scene := load(INDOOR_MODE_SCENE_PATH) as PackedScene
	if not assert_true(indoor_scene != null, "Missing indoor mode scene: %s" % INDOOR_MODE_SCENE_PATH):
		return
	if not assert_true(run_state_script != null, "Missing run state script: %s" % RUN_STATE_SCRIPT_PATH):
		return

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(run_state != null, "RunState should build for indoor mode tests."):
		return

	var indoor_mode = indoor_scene.instantiate()
	if not assert_true(indoor_mode != null, "Indoor mode should instantiate."):
		return

	root.add_child(indoor_mode)
	indoor_mode.configure(run_state, "mart_01")

	if not assert_true(indoor_mode.has_signal("exit_requested"), "Indoor mode should emit exit_requested."):
		indoor_mode.free()
		return

	indoor_mode.exit_requested.connect(Callable(self, "_on_exit_requested"))

	var exit_button := indoor_mode.get_node_or_null("Panel/VBox/Header/ExitButton") as Button
	if not assert_true(exit_button != null, "Indoor mode should expose an ExitButton."):
		indoor_mode.free()
		return
	assert_eq(exit_button.text, "건물 밖으로", "Indoor mode should label the exit action as 건물 밖으로.")

	var location_label := indoor_mode.get_node_or_null("Panel/VBox/Header/LocationLabel") as Label
	if not assert_true(location_label != null, "Indoor mode should expose a LocationLabel."):
		indoor_mode.free()
		return
	assert_eq(
		location_label.text,
		"위치: 정문 진입부",
		"Indoor mode should show the mart entry zone label after configure."
	)

	var backdrop := indoor_mode.get_node_or_null("Backdrop") as ColorRect
	if not assert_true(backdrop != null, "Indoor mode should expose a Backdrop node for the reading surface."):
		indoor_mode.free()
		return

	var director := indoor_mode.get_node_or_null("Director")
	if not assert_true(director != null and director.has_method("apply_action"), "Indoor mode should expose its Director node."):
		indoor_mode.free()
		return

	assert_true(
		director.apply_action("move_checkout"),
		"Director should allow moving to the checkout zone from the entry zone."
	)
	assert_eq(
		location_label.text,
		"위치: 계산대",
		"Indoor mode should refresh the location label after the director changes zone."
	)

	exit_button.emit_signal("pressed")
	assert_eq(_exit_requested_count, 1, "Pressing ExitButton should emit exit_requested exactly once.")

	indoor_mode.free()
	pass_test("INDOOR_MODE_OK")


func _on_exit_requested() -> void:
	_exit_requested_count += 1


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
