extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const INDOOR_ACTION_RESOLVER_SCRIPT_PATH := "res://scripts/indoor/indoor_action_resolver.gd"
const MART_EVENT_PATH := "res://data/events/indoor/mart_01.json"
const INDOOR_EVENT_PATHS := [
	"res://data/events/indoor/mart_01.json",
	"res://data/events/indoor/apartment_01.json",
	"res://data/events/indoor/clinic_01.json",
	"res://data/events/indoor/office_01.json",
	"res://data/events/indoor/convenience_01.json",
	"res://data/events/indoor/hardware_01.json",
	"res://data/events/indoor/gas_station_01.json",
	"res://data/events/indoor/laundry_01.json",
	"res://data/events/indoor/pharmacy_01.json",
	"res://data/events/indoor/restaurant_01.json",
	"res://data/events/indoor/bakery_01.json",
	"res://data/events/indoor/warehouse_01.json",
	"res://data/events/indoor/cafe_01.json",
	"res://data/events/indoor/police_box_01.json",
	"res://data/events/indoor/repair_shop_01.json",
	"res://data/events/indoor/residence_01.json",
]
const MART_DETERMINISM_CASES := [
	{
		"zone_id": "food_aisle",
		"action_id": "search_food_aisle",
	},
	{
		"zone_id": "household_goods",
		"action_id": "search_household_goods",
	},
]
const LEGACY_FOOD_AISLE_IDS := [
	"canned_beans",
	"instant_noodles",
	"bottled_water",
	"canned_tuna",
	"crackers",
]

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
	var resolver_script := load(INDOOR_ACTION_RESOLVER_SCRIPT_PATH) as Script
	if not assert_true(run_state_script != null, "Missing run state script."):
		return
	if not assert_true(resolver_script != null, "Missing indoor action resolver script."):
		return

	var resolver = resolver_script.new()
	for event_path in INDOOR_EVENT_PATHS:
		_assert_all_search_actions_have_loot_tables(resolver, event_path)

	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary autoload should be available for indoor loot-table coverage."):
		return
	for building_id in ["pharmacy_01", "restaurant_01", "bakery_01", "warehouse_01", "cafe_01", "police_box_01", "repair_shop_01", "residence_01"]:
		assert_true(content_library.get_building(building_id).size() > 0, "Expanded authored slice should include '%s'." % building_id)

	var event_data: Dictionary = resolver.load_event(MART_EVENT_PATH)
	if not assert_true(not event_data.is_empty(), "Mart event data should load."):
		return

	var food_option := _option_by_id(event_data, "search_food_aisle")
	if not assert_true(not food_option.is_empty(), "Food aisle search option should exist."):
		return
	var food_outcomes: Dictionary = food_option.get("outcomes", {})
	assert_true(food_outcomes.has("loot_table"), "Food aisle search should define a weighted loot table.")
	assert_true(_loot_table_has_entry(event_data, "search_office_drawer", "improvised_heat_note_01"), "Mart office loot should include a first-pass heat knowledge note.")
	assert_true(_loot_table_has_entry(event_data, "search_office_drawer", "survival_cooking_note_01"), "Mart office loot should include a first-pass cooking knowledge note.")

	var office_event_data: Dictionary = resolver.load_event("res://data/events/indoor/office_01.json")
	assert_true(not office_event_data.is_empty(), "Office event data should load for note-placement checks.")
	assert_true(_loot_table_has_entry(office_event_data, "search_records_room", "field_hygiene_note_01"), "Office records loot should include a field hygiene note.")

	var first_run = _build_run_state(run_state_script, 111)
	var second_run = _build_run_state(run_state_script, 111)
	if not assert_true(first_run != null and second_run != null, "RunState should build for loot table tests."):
		return

	var first_ids := _search_zone_and_collect_ids(resolver, event_data, first_run, "food_aisle", "search_food_aisle")
	var second_ids := _search_zone_and_collect_ids(resolver, event_data, second_run, "food_aisle", "search_food_aisle")

	assert_eq(first_ids, second_ids, "The same world seed should roll the same indoor loot.")
	assert_true(_contains_non_legacy_food_item(first_ids), "Food aisle loot should pull from the expanded cold-survival item pool, not only the legacy fixed set.")
	assert_true(_contains_any_item(first_ids, ["cooking_oil", "tea_bag", "zip_bag", "dish_soap", "shopping_bag"]), "Mart loot should now include general life-world items as well as cold-survival materials.")
	_assert_repeatable_mart_loot_rolls(resolver, event_data, run_state_script)

	pass_test("INDOOR_LOOT_TABLES_OK")


func _assert_all_search_actions_have_loot_tables(resolver, event_path: String) -> void:
	var event_data: Dictionary = resolver.load_event(event_path)
	assert_true(not event_data.is_empty(), "Indoor event data should load: %s" % event_path)
	for event_variant in event_data.get("events", []):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event := event_variant as Dictionary
		if String(event.get("type", "")) != "search":
			continue
		for option_variant in event.get("options", []):
			if typeof(option_variant) != TYPE_DICTIONARY:
				continue
			var option := option_variant as Dictionary
			var outcomes: Dictionary = option.get("outcomes", {})
			var has_loot_outcome := outcomes.has("loot") or outcomes.has("discover_loot") or outcomes.has("loot_table") or outcomes.has("supply_sources")
			var has_pressure_or_state_outcome := outcomes.has("pressure") or outcomes.has("reveal_clue_ids") or outcomes.has("set_flags") or outcomes.has("unlock_zone_ids")
			assert_true(
				has_loot_outcome or has_pressure_or_state_outcome,
				"%s:%s should define loot, pressure, clue, flag, or unlock outcomes." % [event_path, String(option.get("id", ""))]
			)
			if not outcomes.has("loot_table"):
				continue
			var loot_table_variant: Variant = outcomes.get("loot_table", {})
			assert_true(
				typeof(loot_table_variant) == TYPE_DICTIONARY,
				"%s:%s loot_table should be a dictionary." % [event_path, String(option.get("id", ""))]
			)
			if typeof(loot_table_variant) != TYPE_DICTIONARY:
				continue
			var loot_table := loot_table_variant as Dictionary
			assert_true(
				int(loot_table.get("rolls", 0)) > 0,
				"%s:%s loot_table should define positive rolls." % [event_path, String(option.get("id", ""))]
			)
			var entries_variant: Variant = loot_table.get("entries", [])
			assert_true(
				typeof(entries_variant) == TYPE_ARRAY,
				"%s:%s loot_table entries should be an array." % [event_path, String(option.get("id", ""))]
			)
			if typeof(entries_variant) != TYPE_ARRAY:
				continue
			var entries: Array = entries_variant as Array
			assert_true(
				not entries.is_empty(),
				"%s:%s loot_table should define at least one entry." % [event_path, String(option.get("id", ""))]
			)
			for entry_variant in entries:
				assert_true(
					typeof(entry_variant) == TYPE_DICTIONARY,
					"%s:%s loot_table entries should be dictionaries." % [event_path, String(option.get("id", ""))]
				)
				if typeof(entry_variant) != TYPE_DICTIONARY:
					continue
				var entry := entry_variant as Dictionary
				assert_true(
					not String(entry.get("id", "")).is_empty(),
					"%s:%s loot_table entries should define a non-empty id." % [event_path, String(option.get("id", ""))]
				)
				assert_true(
					float(entry.get("weight", 0.0)) > 0.0,
					"%s:%s loot_table entry %s should define a positive weight." % [event_path, String(option.get("id", "")), String(entry.get("id", ""))]
				)


func _assert_repeatable_mart_loot_rolls(resolver, event_data: Dictionary, run_state_script: Script) -> void:
	for case_data in MART_DETERMINISM_CASES:
		var first_run = _build_run_state(run_state_script, 777)
		var second_run = _build_run_state(run_state_script, 777)
		assert_true(first_run != null and second_run != null, "RunState should build for mart determinism checks.")
		var first_ids := _search_zone_and_collect_ids(
			resolver,
			event_data,
			first_run,
			case_data["zone_id"],
			case_data["action_id"]
		)
		var second_ids := _search_zone_and_collect_ids(
			resolver,
			event_data,
			second_run,
			case_data["zone_id"],
			case_data["action_id"]
		)
		assert_eq(
			first_ids,
			second_ids,
			"Mart loot should be deterministic for %s at the same world seed." % String(case_data["action_id"])
		)


func _build_run_state(run_state_script: Script, world_seed: int):
	return run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
		"world_seed": world_seed,
	}, self)


func _search_zone_and_collect_ids(resolver, event_data: Dictionary, run_state, zone_id: String, action_id: String) -> PackedStringArray:
	var event_state := {
		"current_zone_id": zone_id,
		"visited_zone_ids": PackedStringArray([zone_id]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"zone_loot_entries": {},
		"noise": 0,
	}
	assert_true(resolver.apply_action(run_state, event_data, event_state, action_id), "Loot-table search action should resolve.")
	var zone_loot_entries: Dictionary = event_state.get("zone_loot_entries", {})
	var zone_loot_variant: Variant = zone_loot_entries.get(zone_id, [])
	var result := PackedStringArray()
	if typeof(zone_loot_variant) != TYPE_ARRAY:
		return result
	for loot_variant in zone_loot_variant:
		if typeof(loot_variant) != TYPE_DICTIONARY:
			continue
		result.append(String((loot_variant as Dictionary).get("id", "")))
	return result


func _contains_non_legacy_food_item(item_ids: PackedStringArray) -> bool:
	for item_id in item_ids:
		if not LEGACY_FOOD_AISLE_IDS.has(item_id):
			return true
	return false


func _contains_any_item(item_ids: PackedStringArray, expected_ids: Array[String]) -> bool:
	for item_id in item_ids:
		if expected_ids.has(item_id):
			return true
	return false


func _option_by_id(event_data: Dictionary, option_id: String) -> Dictionary:
	for event_variant in event_data.get("events", []):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event := event_variant as Dictionary
		for option_variant in event.get("options", []):
			if typeof(option_variant) != TYPE_DICTIONARY:
				continue
			var option := option_variant as Dictionary
			if String(option.get("id", "")) == option_id:
				return option
	return {}


func _loot_table_has_entry(event_data: Dictionary, option_id: String, item_id: String) -> bool:
	var option := _option_by_id(event_data, option_id)
	if option.is_empty():
		return false
	var outcomes: Dictionary = option.get("outcomes", {})
	var loot_table_variant: Variant = outcomes.get("loot_table", {})
	if typeof(loot_table_variant) != TYPE_DICTIONARY:
		return false
	for entry_variant in (loot_table_variant as Dictionary).get("entries", []):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		if String((entry_variant as Dictionary).get("id", "")) == item_id:
			return true
	return false


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
