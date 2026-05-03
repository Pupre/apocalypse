extends "res://tests/support/test_case.gd"

const OUTDOOR_ART_RESOLVER_SCRIPT := preload("res://scripts/outdoor/outdoor_art_resolver.gd")


func _init() -> void:
	call_deferred("_run_test")


func _content_library():
	return root.get_node_or_null("ContentLibrary")


func _run_test() -> void:
	var content_library = _content_library()
	if not assert_true(content_library != null, "ContentLibrary autoload should be registered."):
		return

	var layout: Dictionary = content_library.get_outdoor_world_layout()
	var city_blocks: Dictionary = layout.get("city_blocks", {})
	assert_eq(int(city_blocks.get("width", 0)), 12, "Expanded outdoor city should be twelve blocks wide.")
	assert_eq(int(city_blocks.get("height", 0)), 12, "Expanded outdoor city should be twelve blocks tall.")

	for block_coord in [Vector2i(3, 0), Vector2i(6, 6), Vector2i(11, 11)]:
		var block: Dictionary = content_library.get_outdoor_block(block_coord)
		assert_true(not block.is_empty(), "Expanded outdoor block %s should load." % [block_coord])
		assert_true(not String(block.get("district_id", "")).is_empty(), "Expanded outdoor block %s should expose a district id." % [block_coord])
		var roads_variant: Variant = block.get("roads", [])
		var hazards_variant: Variant = block.get("hazards", [])
		var obstacles_variant: Variant = block.get("obstacles", [])
		var anchors_variant: Variant = block.get("building_anchors", {})
		assert_true(typeof(roads_variant) == TYPE_ARRAY and (roads_variant as Array).size() >= 4, "Expanded outdoor block %s should contain layered road geometry." % [block_coord])
		assert_true(typeof(hazards_variant) == TYPE_ARRAY and (hazards_variant as Array).size() >= 3, "Expanded outdoor block %s should contain several travel hazards." % [block_coord])
		assert_true(typeof(obstacles_variant) == TYPE_ARRAY and (obstacles_variant as Array).size() >= 6, "Expanded outdoor block %s should contain varied street props." % [block_coord])
		assert_true(typeof(anchors_variant) == TYPE_DICTIONARY and (anchors_variant as Dictionary).size() >= 1, "Expanded outdoor block %s should expose building anchors." % [block_coord])

	var building_rows: Array[Dictionary] = content_library.get_building_rows()
	var generated_count := 0
	var scenario_count := 0
	for building in building_rows:
		var building_id := String(building.get("id", ""))
		if not building_id.begins_with("mapx_"):
			continue
		generated_count += 1
		if not String(building.get("scenario_hook", "")).is_empty():
			scenario_count += 1
		assert_true(not String(building.get("entry_briefing", "")).is_empty(), "Generated building '%s' should have an outdoor entry briefing." % building_id)
		assert_true(typeof(building.get("site_tags", [])) == TYPE_ARRAY and (building.get("site_tags", []) as Array).has("map_expansion"), "Generated building '%s' should be tagged as map expansion content." % building_id)
		assert_true(not String(building.get("indoor_event_path", "")).is_empty(), "Generated building '%s' should link into an indoor event template." % building_id)

	assert_true(generated_count >= 160, "The first map expansion pass should add a large outer district building set.")
	assert_eq(scenario_count, generated_count, "Every generated building should carry a scenario hook for future event deepening.")

	var far_building: Dictionary = content_library.get_building("mapx_11_11_a")
	assert_true(not far_building.is_empty(), "A far southeast generated building should exist.")
	var far_position_variant: Variant = far_building.get("outdoor_position", {})
	assert_true(typeof(far_position_variant) == TYPE_DICTIONARY, "Far generated building should resolve an outdoor position.")
	var far_position := far_position_variant as Dictionary
	assert_true(float(far_position.get("x", 0.0)) > 10560.0, "Far generated building should resolve beyond the old 8x8 city width.")
	assert_true(float(far_position.get("y", 0.0)) > 10560.0, "Far generated building should resolve beyond the old 8x8 city height.")

	var art_resolver = OUTDOOR_ART_RESOLVER_SCRIPT.new()
	assert_true(art_resolver.get_building_texture(far_building) != null, "Generated buildings should resolve to an existing category fallback texture.")

	for scenario in [
		{
			"building_id": "mapx_03_00_a",
			"event_path": "res://data/events/indoor/mapx_north_market_bookstore_01.json",
			"event_id": "mapx_north_market_bookstore_01",
			"story_action_id": "tape_stacks_and_clear",
		},
		{
			"building_id": "mapx_06_06_a",
			"event_path": "res://data/events/indoor/mapx_central_transfer_corner_store_01.json",
			"event_id": "mapx_central_transfer_corner_store_01",
			"story_action_id": "wipe_window_with_plastic",
		},
		{
			"building_id": "mapx_11_11_a",
			"event_path": "res://data/events/indoor/mapx_industrial_fuel_yard_01.json",
			"event_id": "mapx_industrial_fuel_yard_01",
			"story_action_id": "siphon_pump_residue",
		},
		{
			"building_id": "mapx_00_08_a",
			"event_path": "res://data/events/indoor/mapx_west_shelter_general_store_01.json",
			"event_id": "mapx_west_shelter_general_store_01",
			"story_action_id": "take_only_needed_supply",
		},
		{
			"building_id": "mapx_09_04_a",
			"event_path": "res://data/events/indoor/mapx_east_medical_convenience_01.json",
			"event_id": "mapx_east_medical_convenience_01",
			"story_action_id": "sort_triage_with_gloves",
		},
	]:
		_assert_scenario_building(content_library, scenario)

	pass_test("OUTDOOR_MAP_EXPANSION_OK")


func _assert_scenario_building(content_library: Node, scenario: Dictionary) -> void:
	var building_id := String(scenario.get("building_id", ""))
	var expected_event_path := String(scenario.get("event_path", ""))
	var building: Dictionary = content_library.get_building(building_id)
	assert_true(not building.is_empty(), "Scenario building '%s' should exist." % building_id)
	assert_eq(String(building.get("indoor_event_path", "")), expected_event_path, "Scenario building '%s' should use its dedicated indoor event file." % building_id)
	assert_true((building.get("site_tags", []) as Array).has("big_decision"), "Scenario building '%s' should be tagged for big decision content." % building_id)

	var event_data := _load_json(expected_event_path)
	assert_eq(String(event_data.get("id", "")), String(scenario.get("event_id", "")), "Scenario event file should expose the expected id.")
	assert_true(_has_story_action(event_data, String(scenario.get("story_action_id", ""))), "Scenario event '%s' should include a story cutscene decision." % expected_event_path)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not assert_true(file != null, "Missing scenario indoor event data: %s" % path):
		return {}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if not assert_eq(parse_error, OK, "Scenario indoor event data should parse cleanly: %s" % path):
		return {}

	if not assert_true(typeof(json.data) == TYPE_DICTIONARY, "Scenario indoor event data should be a dictionary: %s" % path):
		return {}

	return json.data


func _has_story_action(event_data: Dictionary, action_id: String) -> bool:
	var events_variant: Variant = event_data.get("events", [])
	if typeof(events_variant) != TYPE_ARRAY:
		return false
	for event_variant in events_variant as Array:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event := event_variant as Dictionary
		var options_variant: Variant = event.get("options", [])
		if typeof(options_variant) != TYPE_ARRAY:
			continue
		for option_variant in options_variant as Array:
			if typeof(option_variant) != TYPE_DICTIONARY:
				continue
			var option := option_variant as Dictionary
			if String(option.get("id", "")) != action_id:
				continue
			var outcomes_variant: Variant = option.get("outcomes", {})
			if typeof(outcomes_variant) != TYPE_DICTIONARY:
				return false
			return typeof((outcomes_variant as Dictionary).get("story_cutscene", {})) == TYPE_DICTIONARY
	return false
