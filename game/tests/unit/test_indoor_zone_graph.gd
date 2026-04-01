extends "res://tests/support/test_case.gd"

const RESOLVER_PATH := "res://scripts/indoor/indoor_action_resolver.gd"
const EVENT_PATH := "res://data/events/indoor/mart_01.json"


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
	assert_eq(resolver.get_entry_zone_id(event_data), "mart_entrance", "Mart should expose its entry zone.")

	var entrance_zone: Dictionary = resolver.get_zone(event_data, "mart_entrance")
	assert_eq(String(entrance_zone.get("label", "")), "정문 진입부", "Entry zone should expose its label.")

	var move_actions: Array = resolver.get_move_actions(
		event_data,
		{
			"current_zone_id": "mart_entrance",
			"visited_zone_ids": PackedStringArray(["mart_entrance"]),
			"zone_flags": {},
		}
	)
	assert_eq(
		_action_ids(move_actions),
		["move_checkout", "move_food_aisle"],
		"Entry zone should only expose the first adjacent move actions."
	)

	pass_test("INDOOR_ZONE_GRAPH_OK")


func _action_ids(actions: Array) -> Array[String]:
	var ids: Array[String] = []
	for action in actions:
		ids.append(String(action.get("id", "")))
	return ids


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not assert_true(file != null, "Missing event JSON."):
		return {}

	var json := JSON.new()
	if not assert_eq(json.parse(file.get_as_text()), OK, "Event JSON should parse."):
		return {}

	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}
