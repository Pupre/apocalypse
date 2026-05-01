extends "res://tests/support/test_case.gd"

const RESOLVER_PATH := "res://scripts/indoor/indoor_action_resolver.gd"
const EVENT_PATH := "res://data/events/indoor/mart_01.json"
const APARTMENT_EVENT_PATH := "res://data/events/indoor/apartment_01.json"
const CLINIC_EVENT_PATH := "res://data/events/indoor/clinic_01.json"
const OFFICE_EVENT_PATH := "res://data/events/indoor/office_01.json"


class FakeRunState:
	var advanced_minutes := 0


	func advance_minutes(amount: int) -> void:
		advanced_minutes += amount


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var resolver_script := load(RESOLVER_PATH) as Script
	if not assert_true(resolver_script != null, "Missing resolver script."):
		return

	var event_data := _load_json(EVENT_PATH)
	if event_data.is_empty():
		return

	var resolver = resolver_script.new()
	var entry_zone_id: String = resolver.get_entry_zone_id(event_data)
	assert_eq(entry_zone_id, "mart_entrance", "Mart should expose its entry zone.")

	var entrance_zone: Dictionary = resolver.get_zone(event_data, entry_zone_id)
	assert_true(not entrance_zone.is_empty(), "Entry zone id should resolve to an actual zone.")
	assert_eq(String(entrance_zone.get("label", "")), "정문 진입부", "Entry zone should expose its label.")
	assert_eq(String(entrance_zone.get("floor_id", "")), "floor_1", "Entry zone should expose its floor id.")
	assert_eq(
		_sorted_strings(entrance_zone.get("event_ids", [])),
		PackedStringArray(["entrance_search_event"]),
		"Entry zone should expose its local search event id."
	)
	assert_eq(
		_sorted_strings(entrance_zone.get("connected_zone_ids", [])),
		PackedStringArray(["checkout", "food_aisle"]),
		"Entry zone should link to the expected adjacent zones."
	)
	for connected_zone_id in entrance_zone.get("connected_zone_ids", []):
		var connected_zone: Dictionary = resolver.get_zone(event_data, String(connected_zone_id))
		assert_true(not connected_zone.is_empty(), "Connected zone ids should resolve to real zones.")

	var move_actions: Array = resolver.get_move_actions(
		event_data,
		{
			"current_zone_id": entry_zone_id,
			"visited_zone_ids": PackedStringArray([entry_zone_id]),
			"zone_flags": {},
		}
	)
	assert_eq(
		_sorted_action_ids(move_actions),
		PackedStringArray(["move_checkout", "move_food_aisle"]),
		"Entry zone should expose move actions for each adjacent zone."
	)

	var household_zone: Dictionary = resolver.get_zone(event_data, "household_goods")
	assert_true(not household_zone.is_empty(), "Household goods zone should exist in the mart graph.")
	assert_eq(String(household_zone.get("label", "")), "생활용품 코너", "Household zone should expose its readable label.")
	assert_true(
		_sorted_strings(household_zone.get("connected_zone_ids", [])).has("back_hall"),
		"Household goods should connect the food aisle route to the back hall."
	)

	var event_state := {
		"current_zone_id": entry_zone_id,
		"visited_zone_ids": PackedStringArray([entry_zone_id]),
		"zone_flags": {},
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
	}
	var zone_aware_actions: Array = resolver.get_actions(event_data, event_state)
	assert_eq(
		_sorted_action_ids(zone_aware_actions),
		PackedStringArray(["move_checkout", "move_food_aisle", "search_mart_entrance"]),
		"Zone-aware action queries should expose the entrance search alongside the entrance-valid movement actions."
	)

	var run_state := FakeRunState.new()
	assert_true(
		resolver.apply_action(run_state, event_data, event_state, "move_checkout"),
		"Resolver should apply generated move actions through the main action API."
	)
	assert_eq(String(event_state.get("current_zone_id", "")), "checkout", "Move actions should update the current zone.")
	assert_eq(run_state.advanced_minutes, 30, "First-time movement should spend the target zone's first-visit cost.")
	assert_eq(
		_sorted_strings(event_state.get("visited_zone_ids", [])),
		PackedStringArray(["checkout", "mart_entrance"]),
		"Move actions should track newly visited zones."
	)

	zone_aware_actions = resolver.get_actions(event_data, event_state)
	assert_true(
		_action_ids(zone_aware_actions).has("move_staff_corridor_gate"),
		"Checkout should expose the next graph edge through zone-aware get_actions."
	)
	assert_true(
		_action_ids(zone_aware_actions).has("move_mart_entrance"),
		"Checkout should still expose the return path through zone-aware get_actions."
	)
	assert_true(
		_action_ids(zone_aware_actions).has("search_checkout_drawer"),
		"Checkout should expose its local search only after entering the checkout zone."
	)

	var food_state := {
		"current_zone_id": "food_aisle",
		"visited_zone_ids": PackedStringArray(["mart_entrance", "food_aisle"]),
		"zone_flags": {},
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
	}
	var food_actions: Array = resolver.get_actions(event_data, food_state)
	assert_true(
		_action_ids(food_actions).has("move_household_goods"),
		"Food aisle should expose movement into the new household goods zone."
	)

	var staff_gate_zone: Dictionary = resolver.get_zone(event_data, "staff_corridor_gate")
	assert_true(not staff_gate_zone.is_empty(), "Staff gate zone should exist in the mart graph.")
	assert_true(
		_sorted_strings(staff_gate_zone.get("connected_zone_ids", [])).has("stair_landing"),
		"Staff gate should connect to the second-floor landing in the raw graph."
	)

	var staff_gate_state := {
		"current_zone_id": "staff_corridor_gate",
		"visited_zone_ids": PackedStringArray(["mart_entrance", "checkout", "staff_corridor_gate"]),
		"zone_flags": {},
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
	}
	var staff_gate_actions: Array = resolver.get_actions(event_data, staff_gate_state)
	assert_true(
		_action_ids(staff_gate_actions).has("force_staff_gate"),
		"Staff gate should expose the noisy brute-force option before the player has a tool."
	)
	assert_true(
		_action_ids(staff_gate_actions).has("move_stair_landing"),
		"Second-floor movement should stay visible even before the staff gate opens."
	)
	assert_true(
		_action_by_id(staff_gate_actions, "move_stair_landing").get("locked", false),
		"The visible second-floor move should be marked as locked before the gate is forced."
	)

	staff_gate_state["zone_flags"] = {"staff_gate_forced": true}
	staff_gate_actions = resolver.get_actions(event_data, staff_gate_state)
	assert_true(
		_action_ids(staff_gate_actions).has("move_stair_landing"),
		"Forcing the staff gate should unlock movement to the second-floor landing."
	)
	assert_true(
		not bool(_action_by_id(staff_gate_actions, "move_stair_landing").get("locked", false)),
		"The second-floor move should no longer be locked after the gate is forced open."
	)

	var stair_landing_zone: Dictionary = resolver.get_zone(event_data, "stair_landing")
	assert_true(not stair_landing_zone.is_empty(), "The second-floor landing should exist.")
	assert_eq(String(stair_landing_zone.get("floor_id", "")), "floor_2", "The second-floor landing should belong to floor 2.")

	var apartment_event_data := _load_json(APARTMENT_EVENT_PATH)
	if apartment_event_data.is_empty():
		return

	var first_floor_hall: Dictionary = resolver.get_zone(apartment_event_data, "first_floor_hall")
	assert_true(not first_floor_hall.is_empty(), "Apartment first-floor hall should exist.")
	assert_true(
		_sorted_strings(first_floor_hall.get("connected_zone_ids", [])).has("stairwell"),
		"Apartment first-floor hall should connect to a stairwell."
	)
	var second_floor_hall: Dictionary = resolver.get_zone(apartment_event_data, "second_floor_hall")
	assert_true(not second_floor_hall.is_empty(), "Apartment should expose a second-floor hall.")
	assert_true(
		_sorted_strings(second_floor_hall.get("connected_zone_ids", [])).has("laundry_room"),
		"Apartment second floor should expose a laundry-room side route."
	)
	var unit_201_room: Dictionary = resolver.get_zone(apartment_event_data, "unit_201_room")
	assert_true(not unit_201_room.is_empty(), "Apartment should expose a second locked unit.")
	assert_eq(
		_sorted_strings(unit_201_room.get("access_requirements", {}).get("required_item_ids", [])),
		PackedStringArray(["apartment_201_key"]),
		"Apartment 201 should require its own key."
	)

	var clinic_event_data := _load_json(CLINIC_EVENT_PATH)
	if clinic_event_data.is_empty():
		return
	var treatment_room: Dictionary = resolver.get_zone(clinic_event_data, "treatment_room")
	assert_true(not treatment_room.is_empty(), "Clinic treatment room should exist.")
	assert_true(
		_sorted_strings(treatment_room.get("connected_zone_ids", [])).has("nurse_station"),
		"Clinic treatment room should connect to a nurse station."
	)
	var clinic_break_room: Dictionary = resolver.get_zone(clinic_event_data, "staff_break_room")
	assert_true(not clinic_break_room.is_empty(), "Clinic should expose a staff break room.")

	var office_event_data := _load_json(OFFICE_EVENT_PATH)
	if office_event_data.is_empty():
		return
	var open_office: Dictionary = resolver.get_zone(office_event_data, "open_office")
	assert_true(not open_office.is_empty(), "Office open workspace should exist.")
	assert_true(
		_sorted_strings(open_office.get("connected_zone_ids", [])).has("meeting_room"),
		"Office workspace should connect to a meeting room."
	)
	var records_room: Dictionary = resolver.get_zone(office_event_data, "records_room")
	assert_true(not records_room.is_empty(), "Office records room should exist.")
	assert_true(
		_sorted_strings(records_room.get("connected_zone_ids", [])).has("server_closet"),
		"Office records room should lead into a deeper server closet."
	)

	pass_test("INDOOR_ZONE_GRAPH_OK")


func _action_ids(actions: Array) -> Array[String]:
	var ids: Array[String] = []
	for action in actions:
		ids.append(String(action.get("id", "")))
	return ids


func _action_by_id(actions: Array, expected_id: String) -> Dictionary:
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action := action_variant as Dictionary
		if String(action.get("id", "")) == expected_id:
			return action
	return {}


func _sorted_action_ids(actions: Array) -> PackedStringArray:
	return _sorted_strings(_action_ids(actions))


func _sorted_strings(values) -> PackedStringArray:
	var items: Array[String] = []
	for value in values:
		items.append(String(value))
	items.sort()
	return PackedStringArray(items)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not assert_true(file != null, "Missing event JSON."):
		return {}

	var json := JSON.new()
	if not assert_eq(json.parse(file.get_as_text()), OK, "Event JSON should parse."):
		return {}

	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}
