extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const INDOOR_ACTION_RESOLVER_SCRIPT_PATH := "res://scripts/indoor/indoor_action_resolver.gd"
const TEST_SEEDS := [101, 202, 303, 404, 505]

const BUILDING_CASES := [
	{
		"event_path": "res://data/events/indoor/mart_01.json",
		"search_cases": [
			{"zone_id": "food_aisle", "action_id": "search_food_aisle"},
			{"zone_id": "household_goods", "action_id": "search_household_goods"},
			{"zone_id": "back_hall", "action_id": "search_back_hall_supplies"},
		],
		"family_cases": [
			{"label": "food staples", "expected_ids": ["cooking_oil", "tea_bag", "instant_soup_powder"]},
			{"label": "cleaning goods", "expected_ids": ["dish_soap", "scrub_sponge"]},
			{"label": "carry and storage", "expected_ids": ["zip_bag", "shopping_bag", "food_storage_container", "cardboard_box", "plastic_storage_bin"]},
		],
	},
	{
		"event_path": "res://data/events/indoor/apartment_01.json",
		"search_cases": [
			{"zone_id": "janitor_closet", "action_id": "search_janitor_closet"},
			{"zone_id": "laundry_room", "action_id": "search_laundry_room"},
			{"zone_id": "unit_201_room", "action_id": "search_unit_201_room"},
		],
		"family_cases": [
			{"label": "laundry supplies", "expected_ids": ["laundry_detergent", "dish_soap", "scrub_sponge"]},
			{"label": "bedroom clothing", "expected_ids": ["hoodie", "sleep_socks"]},
			{"label": "home storage", "expected_ids": ["cardboard_box", "food_storage_container", "towel", "dishcloth"]},
		],
	},
	{
		"event_path": "res://data/events/indoor/clinic_01.json",
		"search_cases": [
			{"zone_id": "reception", "action_id": "search_reception"},
			{"zone_id": "treatment_room", "action_id": "search_treatment_room"},
			{"zone_id": "medicine_storage", "action_id": "search_medicine_storage"},
		],
		"family_cases": [
			{"label": "sanitation items", "expected_ids": ["alcohol_swab", "disinfectant_bottle", "hand_sanitizer_gel"]},
			{"label": "diagnostic tools", "expected_ids": ["thermometer"]},
			{"label": "wound care", "expected_ids": ["sterile_gauze_roll", "cotton_swab_pack"]},
			{"label": "medicine", "expected_ids": ["cold_medicine", "fever_reducer", "anti_inflammatory_ointment", "painkillers"]},
		],
	},
	{
		"event_path": "res://data/events/indoor/office_01.json",
		"search_cases": [
			{"zone_id": "open_office", "action_id": "search_open_office"},
			{"zone_id": "records_room", "action_id": "search_records_room"},
			{"zone_id": "server_closet", "action_id": "search_server_closet"},
		],
		"family_cases": [
			{"label": "paper goods", "expected_ids": ["notebook", "memo_pad", "file_folder"]},
			{"label": "binding supplies", "expected_ids": ["binder_clip_box", "staples_box"]},
			{"label": "desk electronics", "expected_ids": ["portable_radio", "power_strip", "power_bank", "charging_cable", "usb_charger", "spare_batteries"]},
		],
	},
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
	for case_data in BUILDING_CASES:
		var event_data: Dictionary = resolver.load_event(case_data["event_path"])
		if not assert_true(not event_data.is_empty(), "Event data should load: %s" % case_data["event_path"]):
			return

		var first_trace := _collect_building_roll_trace(resolver, event_data, run_state_script, case_data["search_cases"])
		var second_trace := _collect_building_roll_trace(resolver, event_data, run_state_script, case_data["search_cases"])
		assert_eq(
			first_trace,
			second_trace,
			"%s should roll the same per-seed building-profile loot trace for the same deterministic seed set." % case_data["event_path"]
		)

		var aggregated_ids := _collect_building_roll_ids(resolver, event_data, run_state_script, case_data["search_cases"])
		for family_case in case_data["family_cases"]:
			assert_true(
				_contains_any_item(aggregated_ids, family_case["expected_ids"]),
				"%s should expose %s across its representative search zones." % [case_data["event_path"], String(family_case["label"])]
			)

	pass_test("LIFE_WORLD_LOOT_PROFILES_OK")


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


func _collect_building_roll_trace(resolver, event_data: Dictionary, run_state_script: Script, search_cases: Array) -> Array:
	var trace: Array = []
	for seed in TEST_SEEDS:
		var run_state = _build_run_state(run_state_script, seed)
		assert_true(run_state != null, "RunState should build for loot profile tests.")
		for search_case_variant in search_cases:
			if typeof(search_case_variant) != TYPE_DICTIONARY:
				continue
			var search_case := search_case_variant as Dictionary
			trace.append({
				"seed": seed,
				"zone_id": String(search_case.get("zone_id", "")),
				"action_id": String(search_case.get("action_id", "")),
				"rolled_ids": _search_zone_and_collect_ids(
					resolver,
					event_data,
					run_state,
					String(search_case.get("zone_id", "")),
					String(search_case.get("action_id", ""))
				),
			})
	return trace


func _collect_building_roll_ids(resolver, event_data: Dictionary, run_state_script: Script, search_cases: Array) -> PackedStringArray:
	var aggregated_ids := PackedStringArray()
	for seed in TEST_SEEDS:
		var run_state = _build_run_state(run_state_script, seed)
		assert_true(run_state != null, "RunState should build for loot profile tests.")
		for search_case_variant in search_cases:
			if typeof(search_case_variant) != TYPE_DICTIONARY:
				continue
			var search_case := search_case_variant as Dictionary
			var rolled_ids := _search_zone_and_collect_ids(
				resolver,
				event_data,
				run_state,
				String(search_case.get("zone_id", "")),
				String(search_case.get("action_id", ""))
			)
			for item_id in rolled_ids:
				if not aggregated_ids.has(item_id):
					aggregated_ids.append(item_id)
	return aggregated_ids


func _contains_any_item(item_ids: PackedStringArray, expected_ids: Array) -> bool:
	for item_id in item_ids:
		if expected_ids.has(item_id):
			return true
	return false


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
