extends "res://tests/support/test_case.gd"


const REPRESENTATIVE_ITEMS := {
	"kitchen": ["canned_coffee", "soy_sauce_bottle", "gochujang_tube"],
	"hygiene": ["soap_bar", "laundry_detergent", "wet_wipes"],
	"repair": ["hammer", "pliers", "zip_ties"],
	"office": ["notebook", "binder_clip_box", "stapler"],
	"textile": ["hoodie", "thermal_bottom", "sleep_socks"],
	"containers": ["shopping_bag", "food_storage_container", "cardboard_box"],
	"medical": ["disinfectant_bottle", "alcohol_swab", "thermometer"],
	"electronics": ["portable_radio", "power_bank", "headlamp"],
	"vehicle": ["ice_scraper", "jumper_cable", "umbrella"],
}

const REPRESENTATIVE_RECIPES := [
	["hot_water", "instant_soup_powder", "warm_soup"],
	["hot_water", "instant_cocoa_mix", "warm_cocoa"],
	["thermos", "hot_water", "sealed_hot_water"],
	["thermos", "warm_cocoa", "sealed_warm_cocoa"],
	["zip_bag", "alcohol_swab", "field_hygiene_kit"],
	["cardboard_box", "packing_tape", "storage_bundle"],
]


func _init() -> void:
	call_deferred("_run_test")


func _load_raw_item_lookup() -> Dictionary:
	var file := FileAccess.open("res://data/items.json", FileAccess.READ)
	if not assert_true(file != null, "Raw items.json should be readable for life-world catalog tests."):
		return {}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if not assert_eq(parse_error, OK, "Raw items.json should parse for life-world catalog tests."):
		return {}

	var parsed: Variant = json.data
	if not assert_true(typeof(parsed) == TYPE_ARRAY, "Raw items.json should expose a top-level array."):
		return {}

	var lookup: Dictionary = {}
	for row_variant in parsed as Array:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row := row_variant as Dictionary
		var item_id := String(row.get("id", ""))
		if item_id.is_empty():
			continue
		lookup[item_id] = row
	return lookup


func _assert_raw_item_contract(raw_items: Dictionary, item_id: String) -> void:
	var row: Dictionary = raw_items.get(item_id, {})
	assert_true(not row.is_empty(), "Raw items.json should include representative item '%s'." % item_id)
	assert_true(row.has("description"), "Raw item '%s' should explicitly author description in items.json." % item_id)
	assert_true(row.has("usage_hint"), "Raw item '%s' should explicitly author usage_hint in items.json." % item_id)
	assert_true(row.has("cold_hint"), "Raw item '%s' should explicitly author cold_hint in items.json." % item_id)
	assert_true(row.has("item_tags"), "Raw item '%s' should explicitly author item_tags in items.json." % item_id)
	var description_variant: Variant = row.get("description", "")
	assert_true(typeof(description_variant) == TYPE_STRING and not String(description_variant).is_empty(), "Raw item '%s' should author a non-empty description string." % item_id)
	var usage_hint_variant: Variant = row.get("usage_hint", "")
	assert_true(typeof(usage_hint_variant) == TYPE_STRING and not String(usage_hint_variant).is_empty(), "Raw item '%s' should author a non-empty usage_hint string." % item_id)
	var cold_hint_variant: Variant = row.get("cold_hint", "")
	assert_true(typeof(cold_hint_variant) == TYPE_STRING and not String(cold_hint_variant).is_empty(), "Raw item '%s' should author a non-empty cold_hint string." % item_id)
	var item_tags_variant: Variant = row.get("item_tags", [])
	assert_true(typeof(item_tags_variant) == TYPE_ARRAY and not (item_tags_variant as Array).is_empty(), "Raw item '%s' should author a non-empty item_tags array." % item_id)


func _run_test() -> void:
	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary should be registered for life-world catalog tests."):
		return

	var raw_items := _load_raw_item_lookup()
	var missing_items: Array[String] = []
	var missing_recipes: Array[String] = []

	for family in REPRESENTATIVE_ITEMS.keys():
		for item_id in REPRESENTATIVE_ITEMS[family]:
			_assert_raw_item_contract(raw_items, item_id)
			var row: Dictionary = content_library.get_item(item_id)
			if row.is_empty():
				missing_items.append("%s: %s" % [family, item_id])
				continue
			var description_variant: Variant = row.get("description", "")
			assert_true(typeof(description_variant) == TYPE_STRING and not String(description_variant).is_empty(), "Life-world item '%s' should expose a non-empty description string." % item_id)
			var usage_hint_variant: Variant = row.get("usage_hint", "")
			assert_true(typeof(usage_hint_variant) == TYPE_STRING and not String(usage_hint_variant).is_empty(), "Life-world item '%s' should expose a non-empty usage_hint string." % item_id)
			var cold_hint_variant: Variant = row.get("cold_hint", "")
			assert_true(typeof(cold_hint_variant) == TYPE_STRING and not String(cold_hint_variant).is_empty(), "Life-world item '%s' should expose a non-empty cold_hint string." % item_id)
			var item_tags_variant: Variant = row.get("item_tags", [])
			assert_true(typeof(item_tags_variant) == TYPE_ARRAY and not (item_tags_variant as Array).is_empty(), "Life-world item '%s' should expose a non-empty item_tags array." % item_id)

	for recipe_row in REPRESENTATIVE_RECIPES:
		var recipe: Dictionary = content_library.get_crafting_combination(recipe_row[0], recipe_row[1])
		if recipe.is_empty():
			missing_recipes.append("%s + %s -> %s" % [recipe_row[0], recipe_row[1], recipe_row[2]])
			continue
		var contexts_variant: Variant = recipe.get("contexts", [])
		assert_true(typeof(contexts_variant) == TYPE_ARRAY and not (contexts_variant as Array).is_empty(), "Life-world recipe '%s + %s' should expose a non-empty contexts array." % [recipe_row[0], recipe_row[1]])
		var ingredient_rules_variant: Variant = recipe.get("ingredient_rules", {})
		assert_true(typeof(ingredient_rules_variant) == TYPE_DICTIONARY and not (ingredient_rules_variant as Dictionary).is_empty(), "Life-world recipe '%s + %s' should expose non-empty ingredient_rules." % [recipe_row[0], recipe_row[1]])
		var result_items_variant: Variant = recipe.get("result_items", [])
		assert_true(typeof(result_items_variant) == TYPE_ARRAY and not (result_items_variant as Array).is_empty(), "Life-world recipe '%s + %s' should expose a non-empty result_items array." % [recipe_row[0], recipe_row[1]])
		var first_result: Variant = (result_items_variant as Array)[0]
		assert_true(typeof(first_result) == TYPE_DICTIONARY, "Life-world recipe '%s + %s' should expose a dictionary first result payload." % [recipe_row[0], recipe_row[1]])
		assert_eq(String((first_result as Dictionary).get("id", "")), String(recipe_row[2]), "Life-world recipe should point at the intended output in the first result payload.")
		assert_eq(String(recipe.get("result_item_id", "")), String(recipe_row[2]), "Life-world recipe should point at the intended output.")

	if not missing_items.is_empty() or not missing_recipes.is_empty():
		var failure_lines: Array[String] = []
		if not missing_items.is_empty():
			failure_lines.append("Missing representative items (%d):" % missing_items.size())
			for item_summary in missing_items:
				failure_lines.append("- %s" % item_summary)
		if not missing_recipes.is_empty():
			failure_lines.append("Missing representative recipes (%d):" % missing_recipes.size())
			for recipe_summary in missing_recipes:
				failure_lines.append("- %s" % recipe_summary)
		assert_true(false, "\n".join(failure_lines))
		return

	pass_test("LIFE_WORLD_ITEM_MATRIX_OK")
