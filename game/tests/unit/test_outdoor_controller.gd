extends "res://tests/support/test_case.gd"

const OUTDOOR_MODE_SCENE_PATH := "res://scenes/outdoor/outdoor_mode.tscn"
const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"

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

var _building_entered := false
var _entered_building_id := ""


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var outdoor_scene := load(OUTDOOR_MODE_SCENE_PATH) as PackedScene
	if not assert_true(outdoor_scene != null, "Missing outdoor scene: %s" % OUTDOOR_MODE_SCENE_PATH):
		return

	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	if not assert_true(run_state_script != null, "Missing run state script: %s" % RUN_STATE_SCRIPT_PATH):
		return

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(run_state != null, "RunState should build for outdoor tests."):
		return

	var outdoor_mode = outdoor_scene.instantiate()
	if not assert_true(outdoor_mode != null, "Outdoor mode should instantiate."):
		return

	root.add_child(outdoor_mode)
	outdoor_mode.building_entered.connect(Callable(self, "_on_building_entered"))

	if not assert_true(outdoor_mode.has_method("bind_run_state"), "Outdoor mode should expose bind_run_state()."):
		outdoor_mode.free()
		return

	outdoor_mode.bind_run_state(run_state)

	var before_clock_minute_of_day: int = run_state.clock.minute_of_day
	var before_exposure: float = run_state.exposure

	if not assert_true(outdoor_mode.has_method("simulate_seconds"), "Outdoor mode should expose simulate_seconds()."):
		outdoor_mode.free()
		return

	outdoor_mode.simulate_seconds(180.0)

	assert_eq(
		run_state.clock.minute_of_day,
		before_clock_minute_of_day + 180,
		"Three real minutes should advance three in-game hours."
	)
	assert_true(run_state.exposure < before_exposure, "Outdoor time should drain exposure.")

	if not assert_true(outdoor_mode.has_method("try_enter_building"), "Outdoor mode should expose try_enter_building()."):
		outdoor_mode.free()
		return

	outdoor_mode.try_enter_building("mart_01")

	assert_true(_building_entered, "Trying to enter a building should emit building_entered.")
	assert_eq(_entered_building_id, "mart_01", "The emitted building id should match the entry target.")

	outdoor_mode.free()
	pass_test("OUTDOOR_CONTROLLER_OK")


func _on_building_entered(building_id: String) -> void:
	_building_entered = true
	_entered_building_id = building_id


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
