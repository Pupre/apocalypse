extends "res://tests/support/test_case.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_state_script: Script = load("res://scripts/run/run_state.gd")
	var state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete", "unlucky"]),
		"remaining_points": 0,
	})

	state.advance_minutes(180)

	assert_eq(state.clock.day_index, 1, "Three hours should stay on day one.")
	assert_eq(state.clock.minute_of_day, 660, "Clock should advance from 08:00 to 11:00.")
	assert_eq(int(state.move_speed), 230, "Job and trait modifiers should increase move speed.")

	state.fatigue = 52.0
	var sleep_preview: Dictionary = state.fatigue_model.get_sleep_preview(state.fatigue, -1)
	assert_eq(sleep_preview["sleep_minutes"], 420, "Fatigue preview should map to seven hours of sleep.")

	var added: bool = state.inventory.add_item({"id": "canned_beans", "bulk": 1})
	assert_true(added, "Inventory should accept a small loot item.")

	pass_test("RUN_MODELS_OK")
