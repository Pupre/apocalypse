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

	assert_true(
		_action_ids(event_data.get("events", [])).has("checkout_drawer_event"),
		"Mart indoor data should expose a top-level events collection for zone-local actions."
	)
	assert_true(
		_action_ids(event_data.get("events", [])).has("staff_gate_event"),
		"Mart indoor data should expose a staff gate event in the top-level events collection."
	)

	var resolver = indoor_action_resolver_script.new()
	var checkout_zone_definition: Dictionary = resolver.get_zone(event_data, "checkout")
	assert_true(
		_string_values(checkout_zone_definition.get("event_ids", [])).has("checkout_drawer_event"),
		"Checkout should point at the checkout drawer event by id."
	)
	var staff_gate_zone_definition: Dictionary = resolver.get_zone(event_data, "staff_corridor_gate")
	assert_true(
		_string_values(staff_gate_zone_definition.get("event_ids", [])).has("staff_gate_event"),
		"Staff gate should point at the staff gate event by id."
	)

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(run_state != null, "RunState should build for indoor action tests."):
		return

	var event_state := {
		"current_zone_id": "mart_entrance",
		"visited_zone_ids": PackedStringArray(["mart_entrance"]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"noise": 0,
	}

	var visible_clues: Array = resolver.get_visible_clues(event_data, event_state)
	assert_eq(visible_clues.size(), 1, "Mart clues should start with one visible clue.")

	var actions: Array = resolver.get_actions(event_data, event_state)
	assert_true(_action_ids(actions).has("move_checkout"), "Entrance should expose movement into checkout.")
	assert_true(_action_ids(actions).has("move_food_aisle"), "Entrance should expose movement into food aisle.")
	assert_true(_action_ids(actions).has("rest"), "Entrance should keep the repeatable rest action.")
	assert_true(not _action_ids(actions).has("search_counter"), "Entrance should not expose checkout-only search actions.")

	var before_clock_minute_of_day: int = run_state.clock.minute_of_day
	var before_fatigue: float = run_state.fatigue
	var action_applied: bool = resolver.apply_action(run_state, event_data, event_state, "move_checkout")
	assert_true(action_applied, "Indoor action resolver should allow moving into the checkout zone.")
	assert_eq(
		run_state.clock.minute_of_day,
		before_clock_minute_of_day + ACTIVE_SEARCH_MINUTES,
		"Moving into checkout should spend the connected zone's first-visit cost."
	)
	assert_true(run_state.fatigue > before_fatigue, "Searching the counter should add fatigue through active time.")
	assert_eq(
		int(roundf(run_state.fatigue * 100.0)),
		int(roundf((before_fatigue + EXPECTED_SEARCH_FATIGUE_GAIN) * 100.0)),
		"Movement time should use the run state's active-time fatigue model."
	)
	assert_eq(String(event_state.get("current_zone_id", "")), "checkout", "Moving should update the current zone to checkout.")

	visible_clues = resolver.get_visible_clues(event_data, event_state)
	assert_eq(visible_clues.size(), 1, "Moving zones should not reveal hidden clues on its own.")
	assert_eq(run_state.inventory.total_bulk(), 0, "Moving zones should not add loot on its own.")

	actions = resolver.get_actions(event_data, event_state)
	assert_true(_action_ids(actions).has("search_checkout_drawer"), "Checkout should expose its local drawer search after entering the zone.")
	assert_true(_action_ids(actions).has("rest"), "Repeatable rest should still be available after moving.")

	assert_true(
		not resolver.apply_action(run_state, event_data, {"revealed_clue_ids": PackedStringArray()}, "search_counter"),
		"Global checkout search should no longer resolve from a location-less state."
	)

	var before_rest_clock_minute_of_day: int = run_state.clock.minute_of_day
	var before_rest_fatigue: float = run_state.fatigue
	assert_true(
		resolver.apply_action(run_state, event_data, event_state, "rest"),
		"Repeatable rest actions should still be usable after moving."
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
	assert_true(_action_ids(actions).has("rest"), "Repeatable rest should remain available after use.")
	assert_true(_action_ids(actions).has("search_checkout_drawer"), "Zone-local checkout search should still remain available until used.")
	assert_true(_action_ids(actions).has("move_mart_entrance"), "Checkout should still expose the return move after resting.")

	var checkout_run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(checkout_run_state != null, "RunState should build for checkout option tests."):
		return

	var checkout_event_state := {
		"current_zone_id": "checkout",
		"visited_zone_ids": PackedStringArray(["mart_entrance", "checkout"]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"noise": 0,
	}

	var checkout_actions: Array = resolver.get_actions(event_data, checkout_event_state)
	assert_true(
		_action_ids(checkout_actions).has("search_checkout_drawer"),
		"Checkout should expose its local drawer search option."
	)
	assert_true(
		_action_ids(checkout_actions).has("move_staff_corridor_gate"),
		"Checkout should expose movement toward the staff gate."
	)
	assert_true(
		not _action_ids(checkout_actions).has("force_staff_corridor_gate"),
		"Checkout gate forcing should stay gated until the drawer flag is set."
	)

	var hall_state := {
		"current_zone_id": "back_hall",
		"visited_zone_ids": PackedStringArray(["mart_entrance", "food_aisle", "back_hall"]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"noise": 0,
	}

	var hall_actions: Array = resolver.get_actions(event_data, hall_state)
	assert_true(
		_action_ids(hall_actions).has("wait_and_listen"),
		"Back hall should expose a human-encounter-ready wait and listen option."
	)
	assert_true(
		_clue_ids(event_data.get("clues", [])).has("recent_human_presence_hint"),
		"Mart data should include the recent human presence clue for the back hall."
	)

	var before_checkout_clock_minute_of_day: int = checkout_run_state.clock.minute_of_day
	assert_true(
		resolver.apply_action(checkout_run_state, event_data, checkout_event_state, "search_checkout_drawer"),
		"Checkout drawer search should resolve through the indoor resolver."
	)
	assert_eq(
		checkout_run_state.clock.minute_of_day,
		before_checkout_clock_minute_of_day + ACTIVE_SEARCH_MINUTES,
		"Checkout drawer search should spend its minute cost."
	)
	assert_true(
		_string_values(checkout_event_state.get("revealed_clue_ids", [])).has("staff_key_board_hint"),
		"Searching the checkout drawer should reveal the staff key board clue."
	)
	var checkout_zone_flags: Dictionary = checkout_event_state.get("zone_flags", {})
	assert_true(
		checkout_zone_flags.has("checkout_drawer_opened"),
		"Searching the checkout drawer should set its zone flag."
	)
	assert_eq(
		checkout_run_state.inventory.total_bulk(),
		1,
		"Searching the checkout drawer should add one loot item."
	)
	assert_true(
		not _action_ids(resolver.get_actions(event_data, checkout_event_state)).has("search_checkout_drawer"),
		"Checkout drawer search should be consumed after use."
	)

	checkout_actions = resolver.get_actions(event_data, checkout_event_state)
	assert_true(
		resolver.apply_action(checkout_run_state, event_data, checkout_event_state, "move_staff_corridor_gate"),
		"Checkout flow should allow movement into the staff gate zone."
	)
	assert_eq(
		String(checkout_event_state.get("current_zone_id", "")),
		"staff_corridor_gate",
		"Moving after the checkout search should change the current zone."
	)

	checkout_actions = resolver.get_actions(event_data, checkout_event_state)
	assert_true(
		_action_ids(checkout_actions).has("force_staff_corridor_gate"),
		"Staff gate zone should expose the force option after the drawer flag is set."
	)

	assert_true(
		resolver.apply_action(checkout_run_state, event_data, checkout_event_state, "force_staff_corridor_gate"),
		"Checkout gate forcing should resolve through the same resolver path."
	)
	assert_true(
		checkout_zone_flags.has("staff_gate_forced"),
		"Forcing the staff gate should set its zone flag."
	)
	assert_eq(
		int(checkout_event_state.get("noise", 0)),
		2,
		"Forcing the staff gate should add its noise cost."
	)

	var hall_run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(hall_run_state != null, "RunState should build for back hall option tests."):
		return

	var before_hall_clock_minute_of_day: int = hall_run_state.clock.minute_of_day
	assert_true(
		resolver.apply_action(hall_run_state, event_data, hall_state, "wait_and_listen"),
		"Back hall wait and listen should resolve through the indoor resolver."
	)
	assert_true(
		_string_values(hall_state.get("revealed_clue_ids", [])).has("recent_human_presence_hint"),
		"Waiting in the back hall should reveal the recent human presence clue."
	)
	assert_eq(
		hall_run_state.clock.minute_of_day,
		before_hall_clock_minute_of_day + 10,
		"Waiting in the back hall should spend its minute cost."
	)

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
		"current_zone_id": "checkout",
		"visited_zone_ids": PackedStringArray(["mart_entrance", "checkout"]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"noise": 0,
	}
	assert_true(
		resolver.apply_action(full_run_state, event_data, overflow_event_state, "search_checkout_drawer"),
		"Overflow tests should still resolve the action."
	)
	assert_eq(
		full_run_state.inventory.total_bulk(),
		full_run_state.inventory.carry_limit,
		"Loot should stay out of the inventory when it cannot fit."
	)
	assert_true(
		String(overflow_event_state.get("last_feedback_message", "")).find("통조림 콩") != -1,
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


func _string_values(values) -> PackedStringArray:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))

	return PackedStringArray(result)


func _clue_ids(clues: Array) -> Array[String]:
	var result: Array[String] = []
	for clue_variant in clues:
		if typeof(clue_variant) != TYPE_DICTIONARY:
			continue

		result.append(String((clue_variant as Dictionary).get("id", "")))

	return result


func _action_ids(actions: Array) -> Array[String]:
	var result: Array[String] = []
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue

		result.append(String((action_variant as Dictionary).get("id", "")))

	return result


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
