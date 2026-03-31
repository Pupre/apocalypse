extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const INDOOR_ACTION_RESOLVER_SCRIPT_PATH := "res://scripts/indoor/indoor_action_resolver.gd"
const INDOOR_EVENT_PATH := "res://data/events/indoor/mart_01.json"

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

	var action_applied: bool = resolver.apply_action(run_state, event_data, event_state, "search_counter")
	assert_true(action_applied, "Indoor action resolver should apply the search_counter action.")

	visible_clues = resolver.get_visible_clues(event_data, event_state)
	assert_eq(visible_clues.size(), 2, "Searching the counter should reveal the hidden clue.")
	assert_eq(run_state.inventory.total_bulk(), 1, "Searching the counter should add one loot item.")

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
