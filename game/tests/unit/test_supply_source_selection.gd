extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const INDOOR_ACTION_RESOLVER_SCRIPT_PATH := "res://scripts/indoor/indoor_action_resolver.gd"
const MART_EVENT_PATH := "res://data/events/indoor/mart_01.json"
const HARDWARE_EVENT_PATH := "res://data/events/indoor/hardware_01.json"
const WAREHOUSE_EVENT_PATH := "res://data/events/indoor/warehouse_01.json"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	var resolver_script := load(INDOOR_ACTION_RESOLVER_SCRIPT_PATH) as Script
	if not assert_true(run_state_script != null, "Missing run state script for supply-source tests."):
		return
	if not assert_true(resolver_script != null, "Missing indoor resolver script for supply-source tests."):
		return

	var mart_event: Dictionary = _load_json(MART_EVENT_PATH)
	var hardware_event: Dictionary = _load_json(HARDWARE_EVENT_PATH)
	var warehouse_event: Dictionary = _load_json(WAREHOUSE_EVENT_PATH)
	if mart_event.is_empty() or hardware_event.is_empty() or warehouse_event.is_empty():
		return

	var resolver = resolver_script.new()
	assert_true(_event_has_supply_sources(mart_event), "Mart should expose quantity-bearing supply sources.")
	assert_true(_event_has_supply_sources(hardware_event), "Hardware store should expose quantity-bearing supply sources.")
	assert_true(_event_has_supply_sources(warehouse_event), "Warehouse should expose quantity-bearing supply sources.")

	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary should be available for supply-source tests."):
		return

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_library)
	if not assert_true(run_state != null, "RunState should build for supply-source tests."):
		return

	var event_state := {
		"current_zone_id": "food_aisle",
		"visited_zone_ids": PackedStringArray(["mart_entrance", "food_aisle"]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"zone_loot_entries": {},
		"zone_supply_sources": {},
		"noise": 0,
	}
	assert_true(
		resolver.apply_action(run_state, mart_event, event_state, "search_food_aisle"),
		"Food aisle search should reveal quantity-bearing stock."
	)
	var supply_actions: Array[Dictionary] = resolver.get_actions(mart_event, event_state, run_state)
	var take_one_action_id := _action_id_by_prefix(supply_actions, "take_supply_food_aisle_water_shelf_1")
	var take_three_action_id := _action_id_by_prefix(supply_actions, "take_supply_food_aisle_water_shelf_3")
	var take_max_action_id := _action_id_by_prefix(supply_actions, "take_supply_food_aisle_water_shelf_max")
	var take_detail_action_id := _action_id_by_prefix(supply_actions, "take_supply_food_aisle_water_shelf_detail")
	assert_true(not take_one_action_id.is_empty(), "Food aisle should expose a 1-item supply pickup action.")
	assert_true(not take_three_action_id.is_empty(), "Food aisle should expose a 3-item supply pickup action.")
	assert_true(not take_max_action_id.is_empty(), "Food aisle should expose a max supply pickup action.")
	assert_true(not take_detail_action_id.is_empty(), "Food aisle should expose a detailed quantity supply pickup action.")

	assert_true(
		resolver.apply_action(run_state, mart_event, event_state, take_three_action_id),
		"Supply pickup should allow taking three items at once."
	)
	assert_eq(run_state.inventory.count_item_by_id("bottled_water"), 3, "Taking three from a supply source should add three carried items.")
	assert_eq(_remaining_supply_quantity(event_state, "food_aisle", "water_shelf"), 9, "Taking three should reduce the remaining supply quantity.")

	var overloaded_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_library)
	if not assert_true(overloaded_state != null, "RunState should build for max-clamp supply tests."):
		return
	for index in range(11):
		assert_true(overloaded_state.inventory.add_item({"id": "weight_%d" % index, "carry_weight": 1, "bulk": 1}), "Supply clamp tests should be able to prefill carried weight.")

	var overloaded_event_state := {
		"current_zone_id": "food_aisle",
		"visited_zone_ids": PackedStringArray(["mart_entrance", "food_aisle"]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"zone_loot_entries": {},
		"zone_supply_sources": {},
		"noise": 0,
	}
	assert_true(
		resolver.apply_action(overloaded_state, mart_event, overloaded_event_state, "search_food_aisle"),
		"Food aisle search should still reveal stock for an overloaded carrier."
	)
	var overloaded_actions: Array[Dictionary] = resolver.get_actions(mart_event, overloaded_event_state, overloaded_state)
	var overloaded_max_action_id := _action_id_by_prefix(overloaded_actions, "take_supply_food_aisle_water_shelf_max")
	assert_true(not overloaded_max_action_id.is_empty(), "Even near the cap, the supply source should still offer a max pickup action.")
	assert_true(
		resolver.apply_action(overloaded_state, mart_event, overloaded_event_state, overloaded_max_action_id),
		"Max pickup should clamp to the legal carry allowance instead of failing outright."
	)
	assert_eq(overloaded_state.inventory.count_item_by_id("bottled_water"), 1, "Max pickup should clamp to the remaining legal carry allowance.")
	assert_eq(_remaining_supply_quantity(overloaded_event_state, "food_aisle", "water_shelf"), 11, "Clamped max pickup should only consume the legal amount from the source.")

	pass_test("SUPPLY_SOURCE_SELECTION_OK")


func _event_has_supply_sources(event_data: Dictionary) -> bool:
	for event_variant in event_data.get("events", []):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		for option_variant in (event_variant as Dictionary).get("options", []):
			if typeof(option_variant) != TYPE_DICTIONARY:
				continue
			var outcomes_variant: Variant = (option_variant as Dictionary).get("outcomes", {})
			if typeof(outcomes_variant) != TYPE_DICTIONARY:
				continue
			var supply_sources_variant: Variant = (outcomes_variant as Dictionary).get("supply_sources", [])
			if typeof(supply_sources_variant) == TYPE_ARRAY and not (supply_sources_variant as Array).is_empty():
				return true
	return false


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not assert_true(file != null, "Failed to open JSON file: %s" % path):
		return {}

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	if not assert_eq(parse_result, OK, "Failed to parse JSON file: %s" % path):
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		assert_true(false, "Expected top-level object in JSON file: %s" % path)
		return {}
	return json.data as Dictionary


func _remaining_supply_quantity(event_state: Dictionary, zone_id: String, source_id: String) -> int:
	var zone_supply_variant: Variant = event_state.get("zone_supply_sources", {})
	if typeof(zone_supply_variant) != TYPE_DICTIONARY:
		return -1
	var zone_sources_variant: Variant = (zone_supply_variant as Dictionary).get(zone_id, [])
	if typeof(zone_sources_variant) != TYPE_ARRAY:
		return -1
	for source_variant in zone_sources_variant:
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source := source_variant as Dictionary
		if String(source.get("id", "")) == source_id:
			return int(source.get("quantity_remaining", -1))
	return -1


func _action_id_by_prefix(actions: Array, prefix: String) -> String:
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action := action_variant as Dictionary
		var action_id := String(action.get("id", ""))
		if action_id.begins_with(prefix):
			return action_id
	return ""
