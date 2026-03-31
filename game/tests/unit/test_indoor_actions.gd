extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const INDOOR_ACTION_RESOLVER_SCRIPT_PATH := "res://scripts/indoor/indoor_action_resolver.gd"
const INDOOR_EVENT_PATH := "res://data/events/indoor/mart_01.json"
const ACTIVE_SEARCH_MINUTES := 30
const EXPECTED_SEARCH_FATIGUE_GAIN := 0.75

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


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	var indoor_action_resolver_script := load(INDOOR_ACTION_RESOLVER_SCRIPT_PATH) as Script
	if not assert_true(run_state_script != null, "Missing run state script: %s" % RUN_STATE_SCRIPT_PATH):
		return
	if not assert_true(indoor_action_resolver_script != null, "Missing indoor action resolver script: %s" % INDOOR_ACTION_RESOLVER_SCRIPT_PATH):
		return

	var event_data := _load_json(INDOOR_EVENT_PATH)
	if event_data.is_empty():
		return

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(run_state != null, "RunState should build for indoor action tests."):
		return

	var resolver = indoor_action_resolver_script.new()
	var event_state := {
		"revealed_clue_ids": PackedStringArray(),
	}

	var visible_clues: Array = resolver.get_visible_clues(event_data, event_state)
	assert_eq(visible_clues.size(), 1, "Mart clues should start with one visible clue.")

	var actions: Array = resolver.get_actions(event_data, event_state)
	assert_eq(actions.size(), 2, "Mart indoor actions should start with the active search and rest actions.")

	var before_clock_minute_of_day: int = run_state.clock.minute_of_day
	var before_fatigue: float = run_state.fatigue
	var action_applied: bool = resolver.apply_action(run_state, event_data, event_state, "search_counter")
	assert_true(action_applied, "Indoor action resolver should apply the search_counter action.")
	assert_eq(
		run_state.clock.minute_of_day,
		before_clock_minute_of_day + ACTIVE_SEARCH_MINUTES,
		"Searching the counter should spend active minutes."
	)
	assert_true(run_state.fatigue > before_fatigue, "Searching the counter should add fatigue through active time.")
	assert_eq(
		int(roundf(run_state.fatigue * 100.0)),
		int(roundf((before_fatigue + EXPECTED_SEARCH_FATIGUE_GAIN) * 100.0)),
		"Active search time should use the run state's active-time fatigue model."
	)

	visible_clues = resolver.get_visible_clues(event_data, event_state)
	assert_eq(visible_clues.size(), 2, "Searching the counter should reveal the hidden clue.")
	assert_eq(run_state.inventory.total_bulk(), 1, "Searching the counter should add one loot item.")

	actions = resolver.get_actions(event_data, event_state)
	assert_eq(actions.size(), 1, "Search actions should be spent after use.")
	assert_eq(String(actions[0].get("id", "")), "rest", "Only the rest action should remain after searching the counter.")

	assert_true(
		not resolver.apply_action(run_state, event_data, event_state, "search_counter"),
		"Spent indoor actions should not be reusable."
	)

	var before_rest_clock_minute_of_day: int = run_state.clock.minute_of_day
	var before_rest_fatigue: float = run_state.fatigue
	assert_true(
		resolver.apply_action(run_state, event_data, event_state, "rest"),
		"Repeatable rest actions should still be usable after searching."
	)
	assert_eq(
		run_state.clock.minute_of_day,
		before_rest_clock_minute_of_day + 60,
		"Rest should use sleep minutes and advance the clock."
	)
	assert_eq(
		run_state.fatigue,
		before_rest_fatigue,
		"Rest should not add active-time fatigue."
	)
	assert_true(
		resolver.apply_action(run_state, event_data, event_state, "rest"),
		"Repeatable rest actions should stay usable after being used once."
	)
	assert_eq(
		run_state.clock.minute_of_day,
		before_rest_clock_minute_of_day + 120,
		"Repeatable rest should keep advancing the clock."
	)
	actions = resolver.get_actions(event_data, event_state)
	assert_eq(actions.size(), 1, "Repeatable rest should remain available after use.")
	assert_eq(String(actions[0].get("id", "")), "rest", "Rest should remain in the action list after use.")

	var full_run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(full_run_state != null, "RunState should build for loot overflow tests."):
		return

	for index in range(full_run_state.inventory.carry_limit):
		assert_true(full_run_state.inventory.add_item({"id": "filler_%d" % index, "bulk": 1}), "Inventory filler should fit before testing overflow feedback.")

	var overflow_event_state := {
		"revealed_clue_ids": PackedStringArray(),
	}
	assert_true(
		resolver.apply_action(full_run_state, event_data, overflow_event_state, "search_counter"),
		"Overflow tests should still resolve the action."
	)
	assert_eq(
		full_run_state.inventory.total_bulk(),
		full_run_state.inventory.carry_limit,
		"Loot should stay out of the inventory when it cannot fit."
	)
	assert_true(
		String(overflow_event_state.get("last_feedback_message", "")).find("Canned Beans") != -1,
		"Overflowing loot should leave feedback that names the blocked item."
	)

	pass_test("INDOOR_ACTIONS_OK")


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not assert_true(file != null, "Missing indoor event data: %s" % path):
		return {}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if not assert_eq(parse_error, OK, "Indoor event data should parse cleanly."):
		return {}

	if not assert_true(typeof(json.data) == TYPE_DICTIONARY, "Indoor event data should be a dictionary."):
		return {}

	return json.data


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
