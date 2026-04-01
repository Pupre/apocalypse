extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const INDOOR_DIRECTOR_SCRIPT_PATH := "res://scripts/indoor/indoor_director.gd"

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
	var indoor_director_script := load(INDOOR_DIRECTOR_SCRIPT_PATH) as Script
	if not assert_true(run_state_script != null, "Missing run state script: %s" % RUN_STATE_SCRIPT_PATH):
		return
	if not assert_true(indoor_director_script != null, "Missing indoor director script: %s" % INDOOR_DIRECTOR_SCRIPT_PATH):
		return

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(run_state != null, "RunState should build for indoor director tests."):
		return

	var director = indoor_director_script.new()
	root.add_child(director)
	director.configure(run_state, "mart_01")

	assert_eq(director.get_current_zone_id(), "mart_entrance", "Director should initialize at the mart entry zone.")
	assert_eq(
		director.get_current_zone_label(),
		"정문 진입부",
		"Director should expose the readable label for the current zone."
	)
	assert_eq(
		_edge_ids(director.get_map_snapshot()),
		["checkout|mart_entrance", "food_aisle|mart_entrance"],
		"At the entrance, the minimap should only show routes that leave the current zone."
	)

	var event_state: Dictionary = director._event_state
	assert_eq(String(event_state.get("current_zone_id", "")), "mart_entrance", "Event state should track the entry zone.")
	assert_true(
		_string_values(event_state.get("visited_zone_ids", [])).has("mart_entrance"),
		"Event state should mark the entry zone as visited."
	)
	assert_true(event_state.has("revealed_clue_ids"), "Event state should keep revealed clue ids.")
	assert_true(event_state.has("spent_action_ids"), "Event state should keep spent action ids.")
	assert_true(event_state.has("zone_flags"), "Event state should keep zone flags.")
	assert_true(event_state.has("traversed_edge_ids"), "Event state should keep traversed indoor edge ids.")
	assert_eq(int(event_state.get("noise", -1)), 0, "Event state should start with zero noise.")

	assert_true(director.apply_action("move_food_aisle"), "Director should allow moving into the food aisle.")
	assert_eq(
		_edge_ids(director.get_map_snapshot()),
		["back_hall|food_aisle", "food_aisle|mart_entrance"],
		"After moving through the food aisle, the minimap should preserve the traveled path and only expose the aisle's current exits."
	)

	assert_true(director.apply_action("move_back_hall"), "Director should allow moving into the back area.")
	assert_eq(
		_edge_ids(director.get_map_snapshot()),
		["back_hall|food_aisle", "back_hall|staff_corridor_gate", "food_aisle|mart_entrance"],
		"The back area should not reveal hidden checkout links until the player actually travels through them."
	)

	assert_true(director.apply_action("move_staff_corridor_gate"), "Director should allow moving to the staff door from the back area.")
	assert_eq(
		_edge_ids(director.get_map_snapshot()),
		["back_hall|food_aisle", "back_hall|staff_corridor_gate", "checkout|staff_corridor_gate", "food_aisle|mart_entrance", "staff_corridor_gate|stair_landing"],
		"At the staff door, the minimap should only add routes that can be seen directly from the current position."
	)

	director.free()
	pass_test("INDOOR_DIRECTOR_OK")


func _string_values(values) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result


func _edge_ids(snapshot: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for edge_variant in snapshot.get("edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge := edge_variant as Dictionary
		var from_id := String(edge.get("from", ""))
		var to_id := String(edge.get("to", ""))
		var edge_id := "%s|%s" % [from_id, to_id] if from_id < to_id else "%s|%s" % [to_id, from_id]
		if not ids.has(edge_id):
			ids.append(edge_id)
	ids.sort()
	return ids


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
