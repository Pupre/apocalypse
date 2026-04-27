extends "res://tests/support/test_case.gd"


func _init() -> void:
	call_deferred("_run_test")


func _content_library():
	return root.get_node_or_null("ContentLibrary")


func _assert_item_contract(item_id: String) -> void:
	var content_library = _content_library()
	if not assert_true(content_library != null, "ContentLibrary autoload should be registered."):
		return
	var row: Dictionary = content_library.get_item(item_id)
	assert_true(not row.is_empty(), "Expected item '%s' to exist." % item_id)
	var description_variant: Variant = row.get("description", "")
	assert_true(typeof(description_variant) == TYPE_STRING and not String(description_variant).is_empty(), "Item '%s' should expose a non-empty description string." % item_id)
	var usage_hint_variant: Variant = row.get("usage_hint", "")
	assert_true(typeof(usage_hint_variant) == TYPE_STRING and not String(usage_hint_variant).is_empty(), "Item '%s' should expose a non-empty usage_hint string." % item_id)
	var cold_hint_variant: Variant = row.get("cold_hint", "")
	assert_true(typeof(cold_hint_variant) == TYPE_STRING and not String(cold_hint_variant).is_empty(), "Item '%s' should expose a non-empty cold_hint string." % item_id)
	var item_tags_variant: Variant = row.get("item_tags", [])
	assert_true(typeof(item_tags_variant) == TYPE_ARRAY and not (item_tags_variant as Array).is_empty(), "Item '%s' should expose a non-empty item_tags array." % item_id)


func _assert_recipe_contract(primary: String, secondary: String, expected_result_item_id: String = "") -> void:
	var content_library = _content_library()
	if not assert_true(content_library != null, "ContentLibrary autoload should be registered."):
		return
	var recipe: Dictionary = content_library.get_crafting_combination(primary, secondary)
	assert_true(not recipe.is_empty(), "Expected recipe '%s + %s'." % [primary, secondary])
	var contexts_variant: Variant = recipe.get("contexts", [])
	assert_true(typeof(contexts_variant) == TYPE_ARRAY and not (contexts_variant as Array).is_empty(), "Recipe '%s + %s' should expose a non-empty contexts array." % [primary, secondary])
	var ingredient_rules_variant: Variant = recipe.get("ingredient_rules", {})
	assert_true(typeof(ingredient_rules_variant) == TYPE_DICTIONARY and not (ingredient_rules_variant as Dictionary).is_empty(), "Recipe '%s + %s' should expose non-empty ingredient_rules." % [primary, secondary])
	var result_items_variant: Variant = recipe.get("result_items", [])
	assert_true(typeof(result_items_variant) == TYPE_ARRAY and not (result_items_variant as Array).is_empty(), "Recipe '%s + %s' should expose a non-empty result_items array." % [primary, secondary])
	var result_items := result_items_variant as Array
	if result_items.is_empty():
		return
	var first_result: Variant = result_items[0]
	assert_true(typeof(first_result) == TYPE_DICTIONARY, "Recipe '%s + %s' should expose a dictionary first result payload." % [primary, secondary])
	var result_item_id_variant: Variant = recipe.get("result_item_id", "")
	assert_true(typeof(result_item_id_variant) == TYPE_STRING and not String(result_item_id_variant).is_empty(), "Recipe '%s + %s' should expose a non-empty top-level result_item_id string." % [primary, secondary])
	if not expected_result_item_id.is_empty():
		assert_eq(String(result_item_id_variant), expected_result_item_id, "Recipe '%s + %s' should point at '%s' in the top-level result_item_id." % [primary, secondary, expected_result_item_id])
		assert_eq(String((first_result as Dictionary).get("id", "")), expected_result_item_id, "Recipe '%s + %s' should point at '%s' in the first result payload." % [primary, secondary, expected_result_item_id])


func _crafting_pair_key(primary_item_id: String, secondary_item_id: String) -> String:
	var ids := [primary_item_id, secondary_item_id]
	ids.sort()
	return "%s__%s" % ids


func _assert_loader_rejects_malformed_crafting_rows() -> void:
	var content_library_script: Script = load("res://scripts/autoload/content_library.gd")
	var content_library_script_loaded := content_library_script != null
	var content_library: Node = null
	if content_library_script_loaded:
		content_library = content_library_script.new()
	var content_library_instantiated := content_library != null

	var temp_path := "user://content_library_loader_regression.json"
	var temp_path_absolute := ProjectSettings.globalize_path(temp_path)
	var temp_file_written := false
	var loaded: Dictionary = {}
	var malformed_json := """[
  {
    "id": "valid_bottled_water_can_stove",
    "ingredients": ["bottled_water", "can_stove"],
    "contexts": ["indoor"],
    "required_tags": [],
    "minutes": 12,
    "ingredient_rules": {
      "bottled_water": "consume",
      "can_stove": "keep"
    },
    "result_items": [
      {"id": "hot_water", "count": 1}
    ],
    "result_item_id": "hot_water",
    "indoor_minutes": 12
  },
  {
    "id": "bad_result_payload_shape",
    "ingredients": ["bad_result_payload_shape", "duct_tape"],
    "contexts": ["indoor"],
    "required_tags": [],
    "minutes": 5,
    "ingredient_rules": {
      "bad_result_payload_shape": "consume",
      "duct_tape": "consume"
    },
    "result_items": [
      "not_a_dictionary"
    ],
    "result_item_id": "ghost_item",
    "indoor_minutes": 5
  },
  {
    "id": "missing_first_result_id",
    "ingredients": ["missing_first_result_id", "rope"],
    "contexts": ["indoor"],
    "required_tags": [],
    "minutes": 5,
    "ingredient_rules": {
      "missing_first_result_id": "consume",
      "rope": "consume"
    },
    "result_items": [
      {"count": 1}
    ],
    "result_item_id": "ghost_item",
    "indoor_minutes": 5
  },
  {
    "id": "mismatched_result_item_id",
    "ingredients": ["mismatched_result_item_id", "tape"],
    "contexts": ["indoor"],
    "required_tags": [],
    "minutes": 5,
    "ingredient_rules": {
      "mismatched_result_item_id": "consume",
      "tape": "consume"
    },
    "result_items": [
      {"id": "expected_result", "count": 1}
    ],
    "result_item_id": "wrong_result",
    "indoor_minutes": 5
  },
  {
    "id": "empty_ingredient_rules",
    "ingredients": ["empty_ingredient_rules", "tape"],
    "contexts": ["indoor"],
    "required_tags": [],
    "minutes": 5,
    "ingredient_rules": {},
    "result_items": [
      {"id": "ignored_result", "count": 1}
    ],
    "result_item_id": "ignored_result",
    "indoor_minutes": 5
  }
]"""

	if content_library_instantiated:
		var file := FileAccess.open(temp_path, FileAccess.WRITE)
		if file != null:
			file.store_string(malformed_json)
			file.close()
			temp_file_written = true
		loaded = content_library._load_crafting_combinations(temp_path)

	var valid_key := _crafting_pair_key("bottled_water", "can_stove")
	var bad_result_payload_shape_key := _crafting_pair_key("bad_result_payload_shape", "duct_tape")
	var missing_first_result_id_key := _crafting_pair_key("missing_first_result_id", "rope")
	var mismatched_result_item_id_key := _crafting_pair_key("mismatched_result_item_id", "tape")
	var empty_ingredient_rules_key := _crafting_pair_key("empty_ingredient_rules", "tape")

	var loaded_has_valid_key := loaded.has(valid_key)
	var loaded_row: Dictionary = {}
	var result_items_variant: Variant = []
	var first_result_variant: Variant = {}
	if loaded_has_valid_key:
		loaded_row = loaded[valid_key]
		result_items_variant = loaded_row.get("result_items", [])
		if typeof(result_items_variant) == TYPE_ARRAY and not (result_items_variant as Array).is_empty():
			first_result_variant = (result_items_variant as Array)[0]
	var file_existed_before_cleanup := FileAccess.file_exists(temp_path_absolute)
	var cleanup_result := DirAccess.remove_absolute(temp_path_absolute)
	var file_exists_after_cleanup := FileAccess.file_exists(temp_path_absolute)
	if content_library != null:
		content_library.free()

	assert_true(content_library_script_loaded, "ContentLibrary script should load for loader regression coverage.")
	assert_true(content_library_instantiated, "ContentLibrary script should instantiate for loader regression coverage.")
	assert_true(temp_file_written, "Should be able to write temporary crafting JSON for loader regression coverage.")
	assert_eq(loaded.size(), 1, "Only the valid crafting row should survive malformed row rejection.")
	assert_true(loaded_has_valid_key, "Valid crafting row should load.")
	assert_true(not loaded.has(bad_result_payload_shape_key), "Rows with non-dictionary first result payloads should be rejected.")
	assert_true(not loaded.has(missing_first_result_id_key), "Rows with missing first result ids should be rejected.")
	assert_true(not loaded.has(mismatched_result_item_id_key), "Rows with mismatched result_item_id should be rejected.")
	assert_true(not loaded.has(empty_ingredient_rules_key), "Rows with empty ingredient_rules should be rejected.")
	if loaded_has_valid_key:
		assert_true(typeof(result_items_variant) == TYPE_ARRAY and not (result_items_variant as Array).is_empty(), "Valid crafting row should keep result_items.")
		assert_true(typeof(first_result_variant) == TYPE_DICTIONARY, "Valid crafting row should keep a dictionary first result payload.")
		assert_eq(String((first_result_variant as Dictionary).get("id", "")), "hot_water", "Valid crafting row should preserve the nested result id.")
		assert_eq(String(loaded_row.get("result_item_id", "")), "hot_water", "Valid crafting row should preserve the top-level result item id.")
	assert_true(file_existed_before_cleanup or not temp_file_written, "Temporary crafting JSON should exist before cleanup when it was written.")
	assert_true(not file_exists_after_cleanup, "Temporary crafting JSON should not exist after cleanup.")
	if file_existed_before_cleanup:
		assert_eq(cleanup_result, OK, "Temporary crafting JSON should be removed after regression coverage.")


func _run_test() -> void:
	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary autoload should be registered."):
		return

	var jobs: Dictionary = content_library.get("jobs")
	var traits: Dictionary = content_library.get("traits")
	var buildings: Dictionary = content_library.get("buildings")
	var outdoor_world_layout: Dictionary = {}
	if content_library.has_method("get_outdoor_world_layout"):
		outdoor_world_layout = content_library.get_outdoor_world_layout()
	var items: Dictionary = content_library.get("items")
	var crafting_combinations_variant: Variant = content_library.get("crafting_combinations")
	var crafting_combinations: Dictionary = {}
	if typeof(crafting_combinations_variant) == TYPE_DICTIONARY:
		crafting_combinations = crafting_combinations_variant
	assert_eq(jobs.size(), 2, "Prototype jobs should load.")
	assert_eq(traits.size(), 4, "Prototype traits should load.")
	assert_true(buildings.size() >= 28, "The authored outdoor slice should expose at least twenty-eight buildings after the 3x3 expansion.")
	assert_true(buildings.has("mart_01"), "Prototype building should be indexed.")
	assert_true(buildings.has("apartment_01"), "Apartment building should be indexed.")
	assert_true(buildings.has("clinic_01"), "Clinic building should be indexed.")
	assert_true(buildings.has("office_01"), "Office building should be indexed.")
	assert_true(buildings.has("convenience_01"), "Convenience store should be indexed.")
	assert_true(buildings.has("hardware_01"), "Hardware store should be indexed.")
	assert_true(buildings.has("gas_station_01"), "Gas station should be indexed.")
	assert_true(buildings.has("laundry_01"), "Laundry should be indexed.")
	assert_true(content_library.has_method("get_outdoor_world_layout"), "ContentLibrary should expose outdoor world layout helpers.")
	assert_true(content_library.has_method("get_outdoor_block"), "ContentLibrary should expose authored outdoor block helpers.")
	assert_true(not outdoor_world_layout.is_empty(), "Outdoor world layout should load into the content library.")
	var block_size: Dictionary = outdoor_world_layout.get("block_size", {})
	var city_blocks: Dictionary = outdoor_world_layout.get("city_blocks", {})
	assert_eq(int(block_size.get("width", 0)), 960, "Outdoor world layout should expose a fixed block width.")
	assert_eq(int(block_size.get("height", 0)), 960, "Outdoor world layout should expose a fixed block height.")
	assert_eq(int(city_blocks.get("width", 0)), 8, "Outdoor world layout should expose authored city width in blocks.")
	assert_eq(int(city_blocks.get("height", 0)), 8, "Outdoor world layout should expose authored city height in blocks.")
	var authored_block_coords := [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 2),
	]
	for block_coord in authored_block_coords:
		var authored_block: Dictionary = content_library.get_outdoor_block(block_coord)
		assert_true(not authored_block.is_empty(), "Outdoor authored block %s should exist." % [block_coord])
	var block_0_0: Dictionary = content_library.get_outdoor_block(Vector2i(0, 0))
	var block_1_1: Dictionary = content_library.get_outdoor_block(Vector2i(1, 1))
	var block_0_0_anchors_variant: Variant = block_0_0.get("building_anchors", {})
	var block_1_1_anchors_variant: Variant = block_1_1.get("building_anchors", {})
	assert_true(typeof(block_0_0_anchors_variant) == TYPE_DICTIONARY, "Outdoor blocks should expose building anchors.")
	assert_true(typeof(block_1_1_anchors_variant) == TYPE_DICTIONARY and (block_1_1_anchors_variant as Dictionary).size() >= 4, "The first authored southeast block should already contain several building anchors.")
	assert_true(items.has("energy_bar"), "Prototype items should index consumables.")
	assert_true(items.has("bottled_water"), "Prototype items should index thirst recovery items.")
	assert_true(items.has("bandage"), "Prototype items should index health recovery items.")
	assert_true(items.has("instant_coffee"), "Prototype items should index everyday stimulants.")
	assert_true(items.has("stimulant_shot"), "Prototype items should index rare stronger stimulants.")
	assert_true(items.has("small_backpack"), "Prototype items should index equippable gear.")
	assert_true(items.has("running_shoes"), "Prototype items should index movement gear.")
	assert_true(items.has("utility_vest"), "Prototype items should index torso gear from the household goods area.")
	assert_true(items.has("newspaper"), "Crafting materials should load into the shared item library.")
	assert_true(items.has("cooking_oil"), "Crafting fuel ingredients should load into the shared item library.")
	assert_true(items.has("rubber_band"), "Crafting binding materials should load into the shared item library.")
	assert_true(items.has("dense_fuel"), "Crafting outputs should load into the shared item library.")
	assert_true(items.has("wet_newspaper"), "Crafting failure outputs should load into the shared item library.")
	assert_true(float(items["energy_bar"].get("hunger_restore", 0.0)) > 0.0, "Food should expose hunger recovery.")
	assert_true(float(items["bottled_water"].get("thirst_restore", 0.0)) > 0.0, "Water should expose thirst recovery.")
	assert_true(float(items["bandage"].get("health_restore", 0.0)) > 0.0, "Medical items should expose health recovery.")
	assert_true(float(items["instant_coffee"].get("fatigue_restore", 0.0)) > 0.0, "Everyday stimulants should expose fatigue recovery.")
	assert_true(float(items["stimulant_shot"].get("fatigue_restore", 0.0)) > float(items["instant_coffee"].get("fatigue_restore", 0.0)), "Rare stimulants should be stronger than everyday stimulants.")
	assert_true(crafting_combinations.size() >= 6, "First-pass crafting recipes should load into the content library.")
	assert_true(content_library.has_method("get_crafting_combination"), "ContentLibrary should expose crafting lookup helpers.")
	_assert_item_contract("matchbox")
	_assert_item_contract("paper_bag")
	_assert_item_contract("lighter")
	_assert_item_contract("improvised_heat_note_01")
	_assert_item_contract("survival_cooking_note_01")
	_assert_item_contract("field_hygiene_note_01")
	if not assert_true(items.has("improvised_heat_note_01"), "Knowledge note items should load into the shared item library."):
		return
	_assert_item_contract("hot_water")
	_assert_item_contract("window_cover_patch")
	_assert_recipe_contract("bottled_water", "can_stove", "hot_water")
	_assert_recipe_contract("bubble_wrap_roll", "duct_tape", "window_cover_patch")
	for required_building_id in ["mart_01", "hardware_01", "apartment_01", "warehouse_01", "garage_01"]:
		var building: Dictionary = content_library.get_building(required_building_id)
		assert_true(not building.is_empty(), "Expected building '%s' to exist." % required_building_id)
		assert_true(String(building.get("depth_tier", "")).begins_with("tier_"), "Building '%s' should expose a depth_tier." % required_building_id)
		assert_true(not String(building.get("entry_briefing", "")).is_empty(), "Building '%s' should expose an outdoor entry briefing." % required_building_id)
	for required_item_id in [
		"butter_cookie_box",
		"sealant_tube",
		"sewing_kit",
		"empty_jerrycan",
		"sealed_window_patch",
		"patched_blanket",
	]:
		_assert_item_contract(required_item_id)
	_assert_recipe_contract("sealant_tube", "clear_plastic_sheet", "sealed_window_patch")
	_assert_recipe_contract("hose_clamp", "siphon_hose", "transfer_hose")
	_assert_recipe_contract("sewing_kit", "old_blanket", "patched_blanket")
	_assert_recipe_contract("shop_towel_bundle", "rubbing_alcohol", "solvent_wipes")
	_assert_recipe_contract("tarp_sheet", "old_blanket", "tarp_bedroll")
	_assert_recipe_contract("foil_tray_pack", "tea_light_candle", "foil_tray_warmer")
	assert_true(bool(items["improvised_heat_note_01"].get("readable", false)), "Knowledge notes should expose readable=true.")
	assert_true(Array(items["improvised_heat_note_01"].get("knowledge_recipe_ids", [])).size() > 0, "Knowledge notes should unlock at least one recipe.")
	assert_eq(int(items["lighter"].get("charges_max", 0)), 5, "Lighter should expose a default charge capacity of 5.")
	assert_eq(String(items["lighter"].get("charge_label", "")), "잔량", "Lighter should expose a readable charge label.")

	var dense_fuel_combo: Dictionary = content_library.get_crafting_combination("newspaper", "cooking_oil")
	assert_eq(String(dense_fuel_combo.get("result_type", "")), "success", "Newspaper plus cooking oil should resolve to a success recipe.")
	assert_eq(String(dense_fuel_combo.get("result_item_id", "")), "dense_fuel", "Newspaper plus cooking oil should make dense fuel.")
	var dense_fuel_results_variant: Variant = dense_fuel_combo.get("result_items", [])
	assert_true(typeof(dense_fuel_results_variant) == TYPE_ARRAY and not (dense_fuel_results_variant as Array).is_empty(), "Newspaper plus cooking oil should expose a non-empty result_items array.")
	var dense_fuel_first_result: Variant = (dense_fuel_results_variant as Array)[0]
	assert_true(typeof(dense_fuel_first_result) == TYPE_DICTIONARY, "Newspaper plus cooking oil should expose a dictionary first result payload.")
	assert_eq(String((dense_fuel_first_result as Dictionary).get("id", "")), "dense_fuel", "Newspaper plus cooking oil should point at dense_fuel in the first result payload.")
	var dense_fuel_required_tool_ids: Variant = dense_fuel_combo.get("required_tool_ids", [])
	assert_true(typeof(dense_fuel_required_tool_ids) == TYPE_ARRAY and (dense_fuel_required_tool_ids as Array).is_empty(), "Assembly recipes should not require a lighter tool.")
	var dense_fuel_tool_charge_costs: Variant = dense_fuel_combo.get("tool_charge_costs", {})
	assert_true(typeof(dense_fuel_tool_charge_costs) == TYPE_DICTIONARY, "Dense fuel should expose tool charge costs.")
	assert_eq(int((dense_fuel_tool_charge_costs as Dictionary).get("lighter", 0)), 0, "Assembly recipes should not spend lighter charges.")
	assert_true(not String(dense_fuel_combo.get("codex_category", "")).is_empty(), "Crafting codex recipes should expose codex_category.")

	var hot_water_combo: Dictionary = content_library.get_crafting_combination("bottled_water", "can_stove")
	assert_true(not String(hot_water_combo.get("codex_category", "")).is_empty(), "Heating recipes should expose codex_category.")
	assert_eq(Array(hot_water_combo.get("required_tool_ids", [])), ["lighter"], "Heating water should require a lighter.")
	assert_eq(int(Dictionary(hot_water_combo.get("tool_charge_costs", {})).get("lighter", 0)), 1, "Heating water should spend one lighter charge.")

	var reverse_lookup: Dictionary = content_library.get_crafting_combination("cooking_oil", "newspaper")
	assert_eq(String(reverse_lookup.get("result_item_id", "")), "dense_fuel", "Crafting lookup should be canonical regardless of ingredient order.")

	var wet_combo: Dictionary = content_library.get_crafting_combination("newspaper", "bottled_water")
	assert_eq(String(wet_combo.get("result_type", "")), "failure", "Newspaper plus water should resolve to a failure recipe.")
	assert_eq(String(wet_combo.get("result_item_id", "")), "wet_newspaper", "Newspaper plus water should make wet newspaper.")
	var wet_result_items_variant: Variant = wet_combo.get("result_items", [])
	assert_true(typeof(wet_result_items_variant) == TYPE_ARRAY and not (wet_result_items_variant as Array).is_empty(), "Newspaper plus water should expose a non-empty result_items array.")
	var wet_first_result: Variant = (wet_result_items_variant as Array)[0]
	assert_true(typeof(wet_first_result) == TYPE_DICTIONARY, "Newspaper plus water should expose a dictionary first result payload.")
	assert_eq(String((wet_first_result as Dictionary).get("id", "")), "wet_newspaper", "Newspaper plus water should point at wet_newspaper in the first result payload.")

	var invalid_combo: Dictionary = content_library.get_crafting_combination("bottled_water", "rubber_band")
	assert_true(invalid_combo.is_empty(), "Unknown crafting pairs should return an empty lookup result.")
	_assert_loader_rejects_malformed_crafting_rows()
	pass_test("CONTENT_LIBRARY_OK")
