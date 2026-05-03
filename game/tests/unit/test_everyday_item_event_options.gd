extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const INDOOR_ACTION_RESOLVER_SCRIPT_PATH := "res://scripts/indoor/indoor_action_resolver.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	var indoor_action_resolver_script := load(INDOOR_ACTION_RESOLVER_SCRIPT_PATH) as Script
	if not assert_true(run_state_script != null, "RunState script should load for everyday event option tests."):
		return
	if not assert_true(indoor_action_resolver_script != null, "IndoorActionResolver should load for everyday event option tests."):
		return

	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary should be available for everyday event option tests."):
		return

	var resolver = indoor_action_resolver_script.new()
	_assert_convenience_glass_glove_option(run_state_script, content_library, resolver)
	_assert_cafe_filter_option(run_state_script, content_library, resolver)
	_assert_laundry_equipment_options(run_state_script, content_library, resolver)
	_assert_apartment_draft_and_laundry_options(run_state_script, content_library, resolver)

	pass_test("EVERYDAY_ITEM_EVENT_OPTIONS_OK")


func _assert_convenience_glass_glove_option(run_state_script: Script, content_library: Node, resolver) -> void:
	var event_data := _load_json("res://data/events/indoor/convenience_01.json")
	var run_state = _new_run_state(run_state_script, content_library)
	var event_state := _event_state("counter")

	var locked_action: Dictionary = _action_by_id(resolver.get_actions(event_data, event_state, run_state), "search_counter_with_glass_search_gloves")
	assert_true(not locked_action.is_empty(), "Convenience counter should preview the glass-search glove option.")
	assert_true(bool(locked_action.get("locked", false)), "Glass-search glove option should be locked without the crafted gloves.")

	_add_item(run_state, content_library, "evd_glass_search_gloves")
	var action: Dictionary = _action_by_id(resolver.get_actions(event_data, event_state, run_state), "search_counter_with_glass_search_gloves")
	assert_true(not bool(action.get("locked", false)), "Glass-search glove option should unlock when the survivor carries the crafted gloves.")
	var before_health := float(run_state.health)
	var before_gloves: int = run_state.inventory.count_item_by_id("evd_glass_search_gloves")
	assert_true(resolver.apply_action(run_state, event_data, event_state, "search_counter_with_glass_search_gloves"), "Unlocked glass-search action should resolve.")
	assert_true(_zone_flags(event_state).has("counter_cleared"), "Glass-search action should clear the counter.")
	assert_eq(run_state.inventory.count_item_by_id("evd_glass_search_gloves"), before_gloves, "Glass-search gloves should work like reusable equipment.")
	assert_eq(snapped(float(run_state.health), 0.01), snapped(before_health, 0.01), "Careful glove search should avoid the broken-glass health loss.")
	var cutscene: Dictionary = event_state.get("pending_story_cutscene", {})
	assert_eq(String(cutscene.get("asset", "")), "indoor/indoor_story_convenience_glass_counter_success.png", "Careful glove search should trigger the convenience counter story illustration.")


func _assert_cafe_filter_option(run_state_script: Script, content_library: Node, resolver) -> void:
	var event_data := _load_json("res://data/events/indoor/cafe_01.json")
	var run_state = _new_run_state(run_state_script, content_library)
	var event_state := _event_state("counter")

	var locked_action: Dictionary = _action_by_id(resolver.get_actions(event_data, event_state, run_state), "filter_cafe_machine_water")
	assert_true(not locked_action.is_empty(), "Cafe counter should preview the prefilter water option.")
	assert_true(bool(locked_action.get("locked", false)), "Cafe prefilter option should be locked without the crafted prefilter.")

	_add_item(run_state, content_library, "evd_clean_water_prefilter")
	var action: Dictionary = _action_by_id(resolver.get_actions(event_data, event_state, run_state), "filter_cafe_machine_water")
	assert_true(not bool(action.get("locked", false)), "Cafe prefilter option should unlock when the prefilter exists.")
	assert_true(resolver.apply_action(run_state, event_data, event_state, "filter_cafe_machine_water"), "Cafe prefilter action should resolve.")
	assert_eq(run_state.inventory.count_item_by_id("evd_clean_water_prefilter"), 0, "The improvised filter should be consumed after filtering dirty machine water.")
	assert_true(_zone_supply_sources(event_state, "counter").size() > 0, "Cafe prefilter action should expose a water supply source.")

	var seating_state := _event_state("seating_area")
	_add_item(run_state, content_library, "evd_window_gap_roll")
	var window_action: Dictionary = _action_by_id(resolver.get_actions(event_data, seating_state, run_state), "seal_cafe_window_and_search")
	assert_true(not bool(window_action.get("locked", false)), "Window gap roll should unlock the cafe seating deep search.")
	assert_true(resolver.apply_action(run_state, event_data, seating_state, "seal_cafe_window_and_search"), "Cafe window-sealing search should resolve.")
	assert_true(_zone_flags(seating_state).has("cafe_seating_gap_blocked"), "Cafe window-sealing search should set its completion flag.")
	assert_eq(run_state.inventory.count_item_by_id("evd_window_gap_roll"), 0, "Installed cafe window gap roll should be consumed by the room setup.")
	var cutscene: Dictionary = seating_state.get("pending_story_cutscene", {})
	assert_eq(String(cutscene.get("asset", "")), "indoor/indoor_story_cafe_window_gap_success.png", "Cafe window-sealing search should trigger its story illustration.")


func _assert_laundry_equipment_options(run_state_script: Script, content_library: Node, resolver) -> void:
	var event_data := _load_json("res://data/events/indoor/laundry_01.json")
	var run_state = _new_run_state(run_state_script, content_library)
	var washer_state := _event_state("washer_row")

	_add_item(run_state, content_library, "evd_foot_dry_kit")
	var washer_action: Dictionary = _action_by_id(resolver.get_actions(event_data, washer_state, run_state), "search_washer_row_with_foot_dry_kit")
	assert_true(not washer_action.is_empty(), "Laundry washer row should expose a foot-dry deep search.")
	assert_true(not bool(washer_action.get("locked", false)), "Foot-dry kit should unlock the wet-floor deep search.")
	assert_true(resolver.apply_action(run_state, event_data, washer_state, "search_washer_row_with_foot_dry_kit"), "Foot-dry deep search should resolve.")
	assert_true(_zone_flags(washer_state).has("washer_row_deep_cleared"), "Foot-dry deep search should mark the washer row deep search complete.")
	assert_eq(run_state.inventory.count_item_by_id("evd_foot_dry_kit"), 1, "Foot-dry kit should remain reusable as worn preparation.")

	var shelf_state := _event_state("detergent_shelf")
	var locked_shelf_action: Dictionary = _action_by_id(resolver.get_actions(event_data, shelf_state, run_state), "search_detergent_shelf_with_hand_protection")
	assert_true(bool(locked_shelf_action.get("locked", false)), "Detergent deep search should still need hand protection.")
	_add_item(run_state, content_library, "evd_rubber_glove_single")
	var shelf_action: Dictionary = _action_by_id(resolver.get_actions(event_data, shelf_state, run_state), "search_detergent_shelf_with_hand_protection")
	assert_true(not bool(shelf_action.get("locked", false)), "Any matching hand-protection item should unlock the detergent deep search.")
	assert_true(resolver.apply_action(run_state, event_data, shelf_state, "search_detergent_shelf_with_hand_protection"), "Detergent shelf deep search should resolve.")
	assert_true(_zone_flags(shelf_state).has("detergent_shelf_deep_cleared"), "Detergent deep search should mark its flag.")


func _assert_apartment_draft_and_laundry_options(run_state_script: Script, content_library: Node, resolver) -> void:
	var event_data := _load_json("res://data/events/indoor/apartment_01.json")
	var run_state = _new_run_state(run_state_script, content_library)
	var room_state := _event_state("unit_101_room")

	_add_item(run_state, content_library, "evd_door_draft_snake")
	var draft_action: Dictionary = _action_by_id(resolver.get_actions(event_data, room_state, run_state), "seal_unit_101_draft_and_search")
	assert_true(not draft_action.is_empty(), "Apartment unit 101 should expose a draft-blocking deep search.")
	assert_true(not bool(draft_action.get("locked", false)), "Door draft snake should unlock the 101 deep search.")
	assert_true(resolver.apply_action(run_state, event_data, room_state, "seal_unit_101_draft_and_search"), "Apartment draft-blocking search should resolve.")
	assert_true(_zone_flags(room_state).has("unit_101_draft_shelter_cleared"), "Apartment draft-blocking search should set its completion flag.")
	assert_eq(run_state.inventory.count_item_by_id("evd_door_draft_snake"), 0, "Installed door draft snake should be consumed by the room setup.")

	var laundry_state := _event_state("laundry_room")
	_add_item(run_state, content_library, "evd_foot_dry_kit")
	var laundry_action: Dictionary = _action_by_id(resolver.get_actions(event_data, laundry_state, run_state), "stabilize_laundry_room_feet_and_search")
	assert_true(not bool(laundry_action.get("locked", false)), "Foot-dry kit should unlock the apartment laundry deep search.")
	assert_true(resolver.apply_action(run_state, event_data, laundry_state, "stabilize_laundry_room_feet_and_search"), "Apartment laundry deep search should resolve.")
	assert_true(_zone_flags(laundry_state).has("apartment_laundry_deep_cleared"), "Apartment laundry deep search should set its completion flag.")
	assert_true(_string_values(laundry_state.get("revealed_clue_ids", [])).has("boiler_key_hint"), "Apartment laundry deep search should still reveal the boiler clue.")


func _new_run_state(run_state_script: Script, content_library: Node):
	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
		"difficulty": "easy",
	}, content_library)
	assert_true(run_state != null, "RunState should build for everyday event option tests.")
	return run_state


func _add_item(run_state, content_library: Node, item_id: String) -> void:
	var item: Dictionary = content_library.get_item(item_id)
	assert_true(not item.is_empty(), "Expected item '%s' to exist in content library." % item_id)
	assert_true(run_state.inventory.add_item(item), "Expected item '%s' to fit in the test inventory." % item_id)


func _event_state(zone_id: String) -> Dictionary:
	return {
		"current_zone_id": zone_id,
		"visited_zone_ids": PackedStringArray([zone_id]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"noise": 0,
	}


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not assert_true(file != null, "Missing indoor event data: %s" % path):
		return {}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if not assert_eq(parse_error, OK, "Indoor event data should parse cleanly: %s" % path):
		return {}

	if not assert_true(typeof(json.data) == TYPE_DICTIONARY, "Indoor event data should be a dictionary: %s" % path):
		return {}

	return json.data


func _action_by_id(actions: Array, expected_id: String) -> Dictionary:
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action := action_variant as Dictionary
		if String(action.get("id", "")) == expected_id:
			return action
	return {}


func _zone_flags(event_state: Dictionary) -> Dictionary:
	var flags_variant: Variant = event_state.get("zone_flags", {})
	return flags_variant as Dictionary if typeof(flags_variant) == TYPE_DICTIONARY else {}


func _zone_supply_sources(event_state: Dictionary, zone_id: String) -> Array:
	var zone_sources_variant: Variant = event_state.get("zone_supply_sources", {})
	if typeof(zone_sources_variant) != TYPE_DICTIONARY:
		return []
	var zone_sources := zone_sources_variant as Dictionary
	var sources_variant: Variant = zone_sources.get(zone_id, [])
	return sources_variant as Array if typeof(sources_variant) == TYPE_ARRAY else []


func _string_values(values) -> PackedStringArray:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))

	return PackedStringArray(result)
