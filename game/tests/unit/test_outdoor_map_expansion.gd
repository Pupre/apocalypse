extends "res://tests/support/test_case.gd"

const OUTDOOR_ART_RESOLVER_SCRIPT := preload("res://scripts/outdoor/outdoor_art_resolver.gd")
const UI_KIT_RESOLVER_SCRIPT := preload("res://scripts/ui/ui_kit_resolver.gd")


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
		assert_true(not String(block.get("layout_id", "")).is_empty(), "Expanded outdoor block %s should expose a layout id for district variety." % [block_coord])
		var roads_variant: Variant = block.get("roads", [])
		var hazards_variant: Variant = block.get("hazards", [])
		var obstacles_variant: Variant = block.get("obstacles", [])
		var anchors_variant: Variant = block.get("building_anchors", {})
		assert_true(typeof(roads_variant) == TYPE_ARRAY and (roads_variant as Array).size() >= 4, "Expanded outdoor block %s should contain layered road geometry." % [block_coord])
		assert_true(typeof(hazards_variant) == TYPE_ARRAY and (hazards_variant as Array).size() >= 3, "Expanded outdoor block %s should contain several travel hazards." % [block_coord])
		assert_true(typeof(obstacles_variant) == TYPE_ARRAY and (obstacles_variant as Array).size() >= 6, "Expanded outdoor block %s should contain varied street props." % [block_coord])
		assert_true(typeof(anchors_variant) == TYPE_DICTIONARY and (anchors_variant as Dictionary).size() >= 1, "Expanded outdoor block %s should expose building anchors." % [block_coord])

	var market_block: Dictionary = content_library.get_outdoor_block(Vector2i(3, 0))
	var market_plaza_block: Dictionary = content_library.get_outdoor_block(Vector2i(4, 0))
	var market_alley_block: Dictionary = content_library.get_outdoor_block(Vector2i(5, 0))
	var center_block: Dictionary = content_library.get_outdoor_block(Vector2i(6, 6))
	var center_detour_block: Dictionary = content_library.get_outdoor_block(Vector2i(4, 6))
	var logistics_block: Dictionary = content_library.get_outdoor_block(Vector2i(7, 8))
	var power_block: Dictionary = content_library.get_outdoor_block(Vector2i(10, 10))
	var rural_block: Dictionary = content_library.get_outdoor_block(Vector2i(3, 11))
	var checkpoint_block: Dictionary = content_library.get_outdoor_block(Vector2i(9, 5))
	assert_eq(String(market_block.get("district_id", "")), "north_market", "The north market should keep a distinct district id.")
	assert_eq(String(center_block.get("district_id", "")), "central_transfer", "The center should keep a distinct transfer district id.")
	assert_eq(String(logistics_block.get("district_id", "")), "logistics_belt", "The southern cargo belt should keep a distinct district id.")
	assert_eq(String(power_block.get("district_id", "")), "power_plant", "The far southeast should now read as a power-plant district.")
	assert_eq(String(rural_block.get("district_id", "")), "rural_greenbelt", "The southwest edge should become a rural greenhouse belt.")
	assert_eq(String(checkpoint_block.get("district_id", "")), "highway_checkpoint", "The eastern road band should become a highway checkpoint district.")
	assert_true(String(market_block.get("layout_id", "")).begins_with("market_"), "North market blocks should use market-specific layout variants.")
	assert_true(_road_signature(market_block) != _road_signature(market_plaza_block), "Adjacent north-market blocks should no longer repeat the same road silhouette.")
	assert_true(_road_signature(market_plaza_block) != _road_signature(market_alley_block), "North-market variants should alternate between arcade, plaza, and back-alley layouts.")
	assert_true(_block_has_road_id(center_block, "bus_loop_top"), "Central transfer blocks should use a bus-loop road layout instead of the generic cross.")
	assert_true(_block_has_road_id(center_detour_block, "underpass_cut"), "Central transfer variants should include an underpass detour silhouette.")
	assert_true(not _block_has_road_id(center_detour_block, "bus_loop_top"), "Not every central transfer block should repeat the bus-loop silhouette.")
	assert_true(_block_has_road_id(logistics_block, "parcel_sorter_floor"), "Logistics blocks should use parcel-sorting or freight-yard silhouettes.")
	assert_true(_block_has_road_id(power_block, "pipeway_vertical"), "Power-plant blocks should expose service pipeway silhouettes.")
	assert_true(_block_has_road_id(rural_block, "greenhouse_lane"), "Rural greenhouse blocks should expose field-lane silhouettes.")
	assert_true(_block_has_road_id(checkpoint_block, "highway_roadblock"), "Highway checkpoint blocks should expose roadblock silhouettes.")
	assert_true(_block_has_obstacle_asset(market_block, "shopping_cart"), "Market blocks should stage retail props.")
	assert_true(_block_has_obstacle_asset(power_block, "barrel_empty"), "Power-plant blocks should stage utility and fuel-yard props.")
	assert_true(_block_has_obstacle_asset(rural_block, "dead_tree"), "Rural blocks should stage open-field and farm-edge props.")

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

	for landmark in [
		{"building_id": "mapx_07_08_a", "tag": "logistics"},
		{"building_id": "mapx_10_10_a", "tag": "power_plant"},
		{"building_id": "mapx_03_11_a", "tag": "rural"},
		{"building_id": "mapx_09_05_a", "tag": "checkpoint"},
	]:
		var landmark_building: Dictionary = content_library.get_building(String(landmark.get("building_id", "")))
		assert_true(not landmark_building.is_empty(), "Regional landmark '%s' should exist." % String(landmark.get("building_id", "")))
		assert_true((landmark_building.get("site_tags", []) as Array).has("big_decision"), "Regional landmark '%s' should be tagged for big decisions." % String(landmark.get("building_id", "")))
		assert_true((landmark_building.get("site_tags", []) as Array).has(String(landmark.get("tag", ""))), "Regional landmark '%s' should carry its world-region tag." % String(landmark.get("building_id", "")))

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
		{
			"building_id": "mapx_07_08_a",
			"event_path": "res://data/events/indoor/mapx_logistics_cold_chain_hub_01.json",
			"event_id": "mapx_logistics_cold_chain_hub_01",
			"story_action_id": "triage_cold_chain_pallet",
		},
		{
			"building_id": "mapx_07_08_a",
			"event_path": "res://data/events/indoor/mapx_logistics_cold_chain_hub_01.json",
			"event_id": "mapx_logistics_cold_chain_hub_01",
			"story_action_id": "copy_dispatch_routes",
			"expected_asset": "indoor/indoor_story_logistics_dispatch_routes_success.png",
		},
		{
			"building_id": "mapx_07_08_a",
			"event_path": "res://data/events/indoor/mapx_logistics_cold_chain_hub_01.json",
			"event_id": "mapx_logistics_cold_chain_hub_01",
			"story_action_id": "drag_full_pallet",
			"expected_asset": "indoor/indoor_story_logistics_pallet_crash_failure.png",
		},
		{
			"building_id": "mapx_10_10_a",
			"event_path": "res://data/events/indoor/mapx_power_plant_control_01.json",
			"event_id": "mapx_power_plant_control_01",
			"story_action_id": "read_heat_trace_note",
			"expected_asset": "indoor/indoor_story_power_heat_trace_note_success.png",
		},
		{
			"building_id": "mapx_10_10_a",
			"event_path": "res://data/events/indoor/mapx_power_plant_control_01.json",
			"event_id": "mapx_power_plant_control_01",
			"story_action_id": "bridge_control_heater",
		},
		{
			"building_id": "mapx_10_10_a",
			"event_path": "res://data/events/indoor/mapx_power_plant_control_01.json",
			"event_id": "mapx_power_plant_control_01",
			"story_action_id": "salvage_pipe_parts",
			"expected_asset": "indoor/indoor_story_power_pipe_gallery_slip_failure.png",
		},
		{
			"building_id": "mapx_03_11_a",
			"event_path": "res://data/events/indoor/mapx_rural_greenhouse_01.json",
			"event_id": "mapx_rural_greenhouse_01",
			"story_action_id": "save_seedling_cache",
		},
		{
			"building_id": "mapx_03_11_a",
			"event_path": "res://data/events/indoor/mapx_rural_greenhouse_01.json",
			"event_id": "mapx_rural_greenhouse_01",
			"story_action_id": "strip_seedling_trays_fast",
			"expected_asset": "indoor/indoor_story_greenhouse_fast_strip_failure.png",
		},
		{
			"building_id": "mapx_03_11_a",
			"event_path": "res://data/events/indoor/mapx_rural_greenhouse_01.json",
			"event_id": "mapx_rural_greenhouse_01",
			"story_action_id": "chip_water_barrel_ice",
			"expected_asset": "indoor/indoor_story_greenhouse_water_barrel_success.png",
		},
		{
			"building_id": "mapx_09_05_a",
			"event_path": "res://data/events/indoor/mapx_highway_checkpoint_01.json",
			"event_id": "mapx_highway_checkpoint_01",
			"story_action_id": "plot_safe_detour",
		},
		{
			"building_id": "mapx_09_05_a",
			"event_path": "res://data/events/indoor/mapx_highway_checkpoint_01.json",
			"event_id": "mapx_highway_checkpoint_01",
			"story_action_id": "cross_roadblock_now",
			"expected_asset": "indoor/indoor_story_checkpoint_exposed_crossing_failure.png",
		},
		{
			"building_id": "mapx_09_05_a",
			"event_path": "res://data/events/indoor/mapx_highway_checkpoint_01.json",
			"event_id": "mapx_highway_checkpoint_01",
			"story_action_id": "search_bus_seats",
			"expected_asset": "indoor/indoor_story_checkpoint_bus_seat_cache_success.png",
		},
		{
			"building_id": "mapx_09_01_b",
			"event_path": "res://data/events/indoor/mapx_civic_triage_clinic_01.json",
			"event_id": "mapx_civic_triage_clinic_01",
			"story_action_id": "sort_safe_medicine_with_gloves",
			"expected_asset": "indoor/indoor_story_civic_triage_gloved_sort_success.png",
		},
		{
			"building_id": "mapx_09_01_b",
			"event_path": "res://data/events/indoor/mapx_civic_triage_clinic_01.json",
			"event_id": "mapx_civic_triage_clinic_01",
			"story_action_id": "sweep_medicine_fast",
			"expected_asset": "indoor/indoor_story_civic_triage_fast_sweep_failure.png",
		},
		{
			"building_id": "mapx_00_05_a",
			"event_path": "res://data/events/indoor/mapx_west_shelter_registration_01.json",
			"event_id": "mapx_west_shelter_registration_01",
			"story_action_id": "take_only_personal_share",
			"expected_asset": "indoor/indoor_story_shelter_personal_share_success.png",
		},
		{
			"building_id": "mapx_00_05_a",
			"event_path": "res://data/events/indoor/mapx_west_shelter_registration_01.json",
			"event_id": "mapx_west_shelter_registration_01",
			"story_action_id": "empty_relief_boxes_fast",
			"expected_asset": "indoor/indoor_story_shelter_empty_boxes_failure.png",
		},
		{
			"building_id": "mapx_02_09_b",
			"event_path": "res://data/events/indoor/mapx_outer_row_house_garage_01.json",
			"event_id": "mapx_outer_row_house_garage_01",
			"story_action_id": "make_garage_carry_sling",
		},
		{
			"building_id": "mapx_08_04_a",
			"event_path": "res://data/events/indoor/mapx_highway_rest_stop_vending_01.json",
			"event_id": "mapx_highway_rest_stop_vending_01",
			"story_action_id": "open_vending_service_panel",
			"expected_asset": "indoor/indoor_story_rest_stop_vending_panel_success.png",
		},
		{
			"building_id": "mapx_06_07_b",
			"event_path": "res://data/events/indoor/mapx_parcel_sorting_center_01.json",
			"event_id": "mapx_parcel_sorting_center_01",
			"story_action_id": "open_random_parcels",
			"expected_asset": "indoor/indoor_story_parcel_random_boxes_failure.png",
		},
		{
			"building_id": "mapx_06_07_b",
			"event_path": "res://data/events/indoor/mapx_parcel_sorting_center_01.json",
			"event_id": "mapx_parcel_sorting_center_01",
			"story_action_id": "map_parcel_routes",
			"expected_asset": "indoor/indoor_story_parcel_route_map_success.png",
		},
		{
			"building_id": "mapx_05_11_a",
			"event_path": "res://data/events/indoor/mapx_rural_farm_storage_01.json",
			"event_id": "mapx_rural_farm_storage_01",
			"story_action_id": "balance_rice_and_tools",
		},
		{
			"building_id": "mapx_09_07_b",
			"event_path": "res://data/events/indoor/mapx_substation_control_01.json",
			"event_id": "mapx_substation_control_01",
			"story_action_id": "reroute_substation_breaker",
		},
		{
			"building_id": "mapx_03_07_c",
			"event_path": "res://data/events/indoor/mapx_school_cafeteria_01.json",
			"event_id": "mapx_school_cafeteria_01",
			"story_action_id": "pack_light_cafeteria_rations",
		},
		{
			"building_id": "mapx_10_06_a",
			"event_path": "res://data/events/indoor/mapx_bus_depot_garage_01.json",
			"event_id": "mapx_bus_depot_garage_01",
			"story_action_id": "read_bus_route_board",
		},
		{
			"building_id": "mapx_08_02_a",
			"event_path": "res://data/events/indoor/mapx_public_health_cold_room_01.json",
			"event_id": "mapx_public_health_cold_room_01",
			"story_action_id": "preserve_cold_room_meds",
		},
		{
			"building_id": "mapx_01_05_c",
			"event_path": "res://data/events/indoor/mapx_shelter_water_checkpoint_01.json",
			"event_id": "mapx_shelter_water_checkpoint_01",
			"story_action_id": "repair_prefilter_and_mark_share",
			"expected_asset": "indoor/indoor_story_shelter_water_prefilter_success.png",
		},
		{
			"building_id": "mapx_07_07_a",
			"event_path": "res://data/events/indoor/mapx_logistics_forklift_workshop_01.json",
			"event_id": "mapx_logistics_forklift_workshop_01",
			"story_action_id": "build_cargo_drag_sled",
		},
		{
			"building_id": "mapx_08_04_a",
			"event_path": "res://data/events/indoor/mapx_highway_rest_stop_vending_01.json",
			"event_id": "mapx_highway_rest_stop_vending_01",
			"story_action_id": "smash_vending_glass",
			"expected_asset": "indoor/indoor_story_rest_stop_vending_glass_failure.png",
		},
		{
			"building_id": "mapx_03_07_c",
			"event_path": "res://data/events/indoor/mapx_school_cafeteria_01.json",
			"event_id": "mapx_school_cafeteria_01",
			"story_action_id": "haul_heavy_cafeteria_rice",
		},
		{
			"building_id": "mapx_01_05_c",
			"event_path": "res://data/events/indoor/mapx_shelter_water_checkpoint_01.json",
			"event_id": "mapx_shelter_water_checkpoint_01",
			"story_action_id": "take_all_checkpoint_water",
			"expected_asset": "indoor/indoor_story_shelter_water_heavy_take_failure.png",
		},
		{
			"building_id": "mapx_07_07_a",
			"event_path": "res://data/events/indoor/mapx_logistics_forklift_workshop_01.json",
			"event_id": "mapx_logistics_forklift_workshop_01",
			"story_action_id": "strip_forklift_battery_tools",
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
	var story_action := _find_story_action(event_data, String(scenario.get("story_action_id", "")))
	assert_true(not story_action.is_empty(), "Scenario event '%s' should include a story cutscene decision." % expected_event_path)
	if not story_action.is_empty():
		var outcomes := story_action.get("outcomes", {}) as Dictionary
		var story_cutscene := outcomes.get("story_cutscene", {}) as Dictionary
		var story_asset := String(story_cutscene.get("asset", ""))
		assert_true(not story_asset.is_empty(), "Scenario event '%s' should expose a story cutscene asset." % expected_event_path)
		var expected_asset := String(scenario.get("expected_asset", ""))
		if not expected_asset.is_empty():
			assert_eq(story_asset, expected_asset, "Scenario action '%s' should use its dedicated result cutscene asset." % String(scenario.get("story_action_id", "")))
		var ui_kit_resolver = UI_KIT_RESOLVER_SCRIPT.new()
		assert_true(ui_kit_resolver.get_texture(story_asset) != null, "Scenario cutscene asset '%s' should resolve to a texture." % story_asset)


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


func _find_story_action(event_data: Dictionary, action_id: String) -> Dictionary:
	var events_variant: Variant = event_data.get("events", [])
	if typeof(events_variant) != TYPE_ARRAY:
		return {}
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
				return {}
			if typeof((outcomes_variant as Dictionary).get("story_cutscene", {})) != TYPE_DICTIONARY:
				return {}
			return option
	return {}


func _block_has_road_id(block: Dictionary, road_id: String) -> bool:
	var roads_variant: Variant = block.get("roads", [])
	if typeof(roads_variant) != TYPE_ARRAY:
		return false
	for road_variant in roads_variant as Array:
		if typeof(road_variant) == TYPE_DICTIONARY and String((road_variant as Dictionary).get("id", "")) == road_id:
			return true
	return false


func _road_signature(block: Dictionary) -> String:
	var ids: Array[String] = []
	var roads_variant: Variant = block.get("roads", [])
	if typeof(roads_variant) != TYPE_ARRAY:
		return ""
	for road_variant in roads_variant as Array:
		if typeof(road_variant) != TYPE_DICTIONARY:
			continue
		ids.append(String((road_variant as Dictionary).get("id", "")))
	return "|".join(PackedStringArray(ids))


func _block_has_obstacle_asset(block: Dictionary, asset_id: String) -> bool:
	var obstacles_variant: Variant = block.get("obstacles", [])
	if typeof(obstacles_variant) != TYPE_ARRAY:
		return false
	for obstacle_variant in obstacles_variant as Array:
		if typeof(obstacle_variant) == TYPE_DICTIONARY and String((obstacle_variant as Dictionary).get("asset_id", "")) == asset_id:
			return true
	return false
