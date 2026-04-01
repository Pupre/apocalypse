extends "res://tests/support/test_case.gd"

const RESOLVER_PATH := "res://scripts/indoor/indoor_action_resolver.gd"
const EVENT_PATH := "res://data/events/indoor/mart_01.json"


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
		PackedStringArray(),
		"Entry zone should expose an explicit event id list even when empty."
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
		PackedStringArray(["move_checkout", "move_food_aisle", "rest"]),
		"Zone-aware action queries should only expose entrance-valid actions at the mart entrance."
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
		"Checkout should expose its local drawer search only after entering the checkout zone."
	)

	pass_test("INDOOR_ZONE_GRAPH_OK")


func _action_ids(actions: Array) -> Array[String]:
	var ids: Array[String] = []
	for action in actions:
		ids.append(String(action.get("id", "")))
	return ids


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
