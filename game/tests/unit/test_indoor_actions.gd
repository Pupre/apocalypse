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
	assert_true(_action_ids(actions).has("search_mart_entrance"), "Entrance should expose its own search action.")
	assert_true(not _action_ids(actions).has("rest"), "Entrance should not expose the removed flat rest action.")
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
	assert_true(_action_ids(actions).has("search_checkout_counter"), "Checkout should expose its local search after entering the zone.")
	assert_true(not _action_ids(actions).has("rest"), "Checkout should not expose the removed flat rest action.")

	assert_true(
		not resolver.apply_action(run_state, event_data, {"revealed_clue_ids": PackedStringArray()}, "search_counter"),
		"Global checkout search should no longer resolve from a location-less state."
	)

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
		_action_ids(checkout_actions).has("search_checkout_counter"),
		"Checkout should expose its local search option."
	)
	assert_true(
		_action_ids(checkout_actions).has("move_staff_corridor_gate"),
		"Checkout should expose movement toward the staff gate."
	)

	var hall_state := {
		"current_zone_id": "back_hall",
		"visited_zone_ids": PackedStringArray(["mart_entrance", "food_aisle", "back_hall"]),
		"traversed_edge_ids": PackedStringArray(["food_aisle|mart_entrance", "back_hall|food_aisle"]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"noise": 0,
	}

	var hall_actions: Array = resolver.get_actions(event_data, hall_state)
	assert_true(
		_action_ids(hall_actions).has("search_back_hall_supplies"),
		"Back hall should expose a supply search action."
	)
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
		resolver.apply_action(checkout_run_state, event_data, checkout_event_state, "search_checkout_counter"),
		"Checkout search should resolve through the indoor resolver."
	)
	assert_eq(
		checkout_run_state.clock.minute_of_day,
		before_checkout_clock_minute_of_day + ACTIVE_SEARCH_MINUTES,
		"Checkout search should spend its minute cost."
	)
	assert_true(
		_string_values(checkout_event_state.get("revealed_clue_ids", [])).has("staff_key_board_hint"),
		"Searching the checkout should reveal the staff key board clue."
	)
	var checkout_zone_flags: Dictionary = checkout_event_state.get("zone_flags", {})
	assert_true(
		checkout_zone_flags.has("checkout_counter_searched"),
		"Searching the checkout should set its zone flag."
	)
	assert_eq(
		checkout_run_state.inventory.total_bulk(),
		0,
		"Searching the checkout should only reveal loot, not add it immediately."
	)
	assert_true(
		String(checkout_event_state.get("last_feedback_message", "")).find("발견") != -1,
		"Searching the checkout should report discovered loot."
	)
	assert_true(
		not _action_ids(resolver.get_actions(event_data, checkout_event_state)).has("search_checkout_counter"),
		"Checkout search should be consumed after use."
	)
	checkout_actions = resolver.get_actions(event_data, checkout_event_state)
	var take_checkout_lighter_action_id := _action_id_by_prefix(checkout_actions, "take_checkout_lighter_")
	var take_checkout_energy_bar_action_id := _action_id_by_prefix(checkout_actions, "take_checkout_energy_bar_")
	assert_true(
		not take_checkout_lighter_action_id.is_empty(),
		"Searching the checkout should reveal a take action for the lighter."
	)
	assert_true(
		not take_checkout_energy_bar_action_id.is_empty(),
		"Searching the checkout should reveal a take action for the snack."
	)
	assert_true(
		resolver.apply_action(checkout_run_state, event_data, checkout_event_state, take_checkout_lighter_action_id),
		"Revealed checkout loot should be collectible with a separate action."
	)
	assert_eq(
		checkout_run_state.inventory.total_bulk(),
		1,
		"Picking up a revealed item should add it to inventory."
	)
	assert_true(
		_action_id_by_prefix(resolver.get_actions(event_data, checkout_event_state), "take_checkout_lighter_").is_empty(),
		"Collected loot should disappear from the revealed action list."
	)

	var toolless_gate_run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(toolless_gate_run_state != null, "RunState should build for locked gate tests."):
		return

	var toolless_gate_state := {
		"current_zone_id": "staff_corridor_gate",
		"visited_zone_ids": PackedStringArray(["mart_entrance", "food_aisle", "back_hall", "staff_corridor_gate"]),
		"traversed_edge_ids": PackedStringArray(["food_aisle|mart_entrance", "back_hall|food_aisle", "back_hall|staff_corridor_gate"]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"noise": 0,
	}

	checkout_actions = resolver.get_actions(event_data, toolless_gate_state, toolless_gate_run_state)
	assert_true(
		not _action_ids(checkout_actions).has("force_staff_corridor_gate"),
		"Staff gate zone should hide the force option until the player finds the tool."
	)
	assert_true(
		_action_ids(checkout_actions).has("move_stair_landing"),
		"The second-floor landing should remain visible as a locked route before the gate is forced."
	)
	var blocked_force_clock_minute_of_day: int = toolless_gate_run_state.clock.minute_of_day
	assert_true(
		not resolver.apply_action(toolless_gate_run_state, event_data, toolless_gate_state, "force_staff_corridor_gate"),
		"Trying to use the hidden force action id directly should fail while the player lacks the tool."
	)
	assert_eq(
		toolless_gate_run_state.clock.minute_of_day,
		blocked_force_clock_minute_of_day,
		"Failing to invoke the hidden force action should not spend time."
	)
	var blocked_attempt_clock_minute_of_day: int = toolless_gate_run_state.clock.minute_of_day
	assert_true(
		resolver.apply_action(toolless_gate_run_state, event_data, toolless_gate_state, "move_stair_landing"),
		"Trying the locked second-floor route should still resolve with feedback."
	)
	assert_eq(
		String(toolless_gate_state.get("current_zone_id", "")),
		"staff_corridor_gate",
		"Trying the locked second-floor route should not change the current zone."
	)
	assert_eq(
		toolless_gate_run_state.clock.minute_of_day,
		blocked_attempt_clock_minute_of_day,
		"Trying a locked route should not spend travel time."
	)
	assert_true(
		String(toolless_gate_state.get("last_feedback_message", "")).find("잠겨") != -1,
		"Trying a locked route should explain that the door is locked."
	)

	var gate_run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(gate_run_state != null, "RunState should build for tooled gate tests."):
		return

	var gate_event_state := {
		"current_zone_id": "back_hall",
		"visited_zone_ids": PackedStringArray(["mart_entrance", "food_aisle", "back_hall"]),
		"traversed_edge_ids": PackedStringArray(["food_aisle|mart_entrance", "back_hall|food_aisle"]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"noise": 0,
	}
	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, "search_back_hall_supplies"),
		"Back hall search should reveal supply loot."
	)
	assert_true(
		not _action_id_by_prefix(resolver.get_actions(event_data, gate_event_state, gate_run_state), "take_back_hall_screwdriver_").is_empty(),
		"Back hall search should reveal a take action for the screwdriver."
	)
	assert_true(
		resolver.apply_action(
			gate_run_state,
			event_data,
			gate_event_state,
			_action_id_by_prefix(resolver.get_actions(event_data, gate_event_state, gate_run_state), "take_back_hall_screwdriver_")
		),
		"The player should be able to pick up the screwdriver after finding it."
	)
	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, "move_staff_corridor_gate"),
		"Back hall progression should still allow moving into the staff gate zone."
	)

	checkout_actions = resolver.get_actions(event_data, gate_event_state, gate_run_state)
	assert_true(
		not bool(_action_by_id(checkout_actions, "force_staff_corridor_gate").get("locked", false)),
		"Finding the screwdriver should unlock the force-gate action."
	)

	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, "force_staff_corridor_gate"),
		"Checkout gate forcing should resolve through the same resolver path."
	)
	assert_true(
		bool((gate_event_state.get("zone_flags", {}) as Dictionary).has("staff_gate_forced")),
		"Forcing the staff gate should set its zone flag."
	)
	assert_eq(
		int(gate_event_state.get("noise", 0)),
		2,
		"Forcing the staff gate should add its noise cost."
	)
	checkout_actions = resolver.get_actions(event_data, gate_event_state, gate_run_state)
	assert_true(
		_action_ids(checkout_actions).has("move_stair_landing"),
		"Forcing the staff gate should unlock movement into the second-floor landing."
	)
	assert_true(
		not bool(_action_by_id(checkout_actions, "move_stair_landing").get("locked", false)),
		"The second-floor route should no longer be marked as locked after the gate is forced."
	)

	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, "move_stair_landing"),
		"Staff gate flow should allow moving into the second-floor landing."
	)
	assert_eq(
		String(gate_event_state.get("current_zone_id", "")),
		"stair_landing",
		"Moving after forcing the gate should enter the second-floor landing."
	)
	var landing_actions: Array = resolver.get_actions(event_data, gate_event_state, gate_run_state)
	assert_true(
		_action_ids(landing_actions).has("move_break_room"),
		"Second-floor landing should expose movement into the break room."
	)
	assert_true(
		_action_ids(landing_actions).has("move_office"),
		"Second-floor landing should expose movement into the office."
	)
	assert_true(
		_action_ids(landing_actions).has("move_warehouse"),
		"Second-floor landing should expose movement into the warehouse."
	)

	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, "move_warehouse"),
		"Second-floor landing should allow moving into the warehouse."
	)
	var warehouse_actions: Array = resolver.get_actions(event_data, gate_event_state, gate_run_state)
	assert_true(
		_action_ids(warehouse_actions).has("move_locked_storage"),
		"Locked storage should stay visible as a locked route until the office yields the storage key."
	)
	assert_true(
		bool(_action_by_id(warehouse_actions, "move_locked_storage").get("locked", false)),
		"Locked storage should be marked as locked before the office yields the storage key."
	)
	var blocked_storage_clock_minute_of_day: int = gate_run_state.clock.minute_of_day
	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, "move_locked_storage"),
		"Trying the locked storage route should resolve with blocked feedback."
	)
	assert_eq(
		String(gate_event_state.get("current_zone_id", "")),
		"warehouse",
		"Trying the locked storage route should leave the player in the warehouse."
	)
	assert_eq(
		gate_run_state.clock.minute_of_day,
		blocked_storage_clock_minute_of_day,
		"Trying the locked storage route should not spend travel time."
	)
	assert_true(
		String(gate_event_state.get("last_feedback_message", "")).find("잠겨") != -1,
		"Trying the locked storage route should explain that the way is locked."
	)

	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, "move_stair_landing"),
		"Warehouse should allow returning to the second-floor landing."
	)
	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, "move_office"),
		"Second-floor landing should allow moving into the office."
	)
	var office_actions: Array = resolver.get_actions(event_data, gate_event_state, gate_run_state)
	assert_true(
		_action_ids(office_actions).has("search_office_drawer"),
		"Office should expose a drawer search that can unlock the deeper storage room."
	)
	assert_eq(
		String(_action_by_id(office_actions, "move_stair_landing").get("label", "")),
		"2층 입구로 이동한다",
		"Returning from the office should use a neutral move label instead of the one-way upstairs wording."
	)
	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, "search_office_drawer"),
		"Office drawer search should resolve through the indoor resolver."
	)
	assert_true(
		String(gate_event_state.get("last_feedback_message", "")).find("보관실 열쇠") != -1,
		"Office drawer search should report discovering the storage key."
	)
	assert_eq(
		gate_run_state.inventory.total_bulk(),
		1,
		"Searching the office should not auto-loot the storage key."
	)
	office_actions = resolver.get_actions(event_data, gate_event_state, gate_run_state)
	var take_office_storage_key_action_id := _action_id_by_prefix(office_actions, "take_office_storage_key_")
	assert_true(
		not take_office_storage_key_action_id.is_empty(),
		"Office search should reveal a separate take action for the storage key."
	)
	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, take_office_storage_key_action_id),
		"The storage key should need to be picked up explicitly."
	)
	assert_eq(
		gate_run_state.inventory.total_bulk(),
		2,
		"Picking up the storage key should add it to the player's inventory."
	)

	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, "move_stair_landing"),
		"Office should allow returning to the second-floor landing."
	)
	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, "move_warehouse"),
		"Second-floor landing should allow returning to the warehouse."
	)
	warehouse_actions = resolver.get_actions(event_data, gate_event_state, gate_run_state)
	assert_true(
		_action_ids(warehouse_actions).has("move_locked_storage"),
		"Picking up the office key should unlock warehouse access to the locked storage."
	)
	assert_true(
		not bool(_action_by_id(warehouse_actions, "move_locked_storage").get("locked", false)),
		"Locked storage should no longer be marked as locked after the office search."
	)
	assert_true(
		resolver.apply_action(gate_run_state, event_data, gate_event_state, "move_locked_storage"),
		"After taking the key, the player should be able to actually enter the locked storage."
	)
	assert_eq(
		String(gate_event_state.get("current_zone_id", "")),
		"locked_storage",
		"Entering the storage route after taking the key should move the player into the storage room."
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
		resolver.apply_action(full_run_state, event_data, overflow_event_state, "search_checkout_counter"),
		"Overflow tests should still resolve the search action."
	)
	assert_eq(
		full_run_state.inventory.total_bulk(),
		full_run_state.inventory.carry_limit,
		"Searching should not auto-loot even when inventory is full."
	)
	assert_true(
		resolver.apply_action(
			full_run_state,
			event_data,
			overflow_event_state,
			_action_id_by_prefix(resolver.get_actions(event_data, overflow_event_state), "take_checkout_lighter_")
		),
		"Overflow tests should still resolve the take action."
	)
	assert_eq(
		full_run_state.inventory.total_bulk(),
		full_run_state.inventory.carry_limit + 1,
		"Taking loot should still work one step past the soft carry limit."
	)
	assert_true(
		String(overflow_event_state.get("last_feedback_message", "")).find("라이터") != -1,
		"Overflow loot feedback should still name the picked-up item."
	)
	assert_true(
		full_run_state.get_outdoor_move_speed() < full_run_state.move_speed,
		"Going past the soft carry limit should reduce outdoor movement speed."
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


func _action_by_id(actions: Array, expected_id: String) -> Dictionary:
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action := action_variant as Dictionary
		if String(action.get("id", "")) == expected_id:
			return action
	return {}


func _action_id_by_prefix(actions: Array, expected_prefix: String) -> String:
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action_id := String((action_variant as Dictionary).get("id", ""))
		if action_id.begins_with(expected_prefix):
			return action_id
	return ""


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
