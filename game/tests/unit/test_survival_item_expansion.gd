extends "res://tests/support/test_case.gd"


const EXPANSION_ITEMS_PATH := "res://data/items_survival_expansion.json"
const EXPANSION_RECIPES_PATH := "res://data/crafting_combinations_survival_expansion.json"


func _init() -> void:
	call_deferred("_run_test")


func _load_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if not assert_true(file != null, "%s should be readable." % path):
		return []

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if not assert_eq(parse_error, OK, "%s should parse as JSON." % path):
		return []
	if not assert_true(typeof(json.data) == TYPE_ARRAY, "%s should expose an array." % path):
		return []
	return json.data as Array


func _run_test() -> void:
	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary should be available for survival expansion coverage."):
		return

	var generated_items := _load_array(EXPANSION_ITEMS_PATH)
	var generated_recipes := _load_array(EXPANSION_RECIPES_PATH)
	assert_eq(generated_items.size(), 500, "Survival expansion should add exactly 500 new item definitions.")
	assert_eq(generated_recipes.size(), 240, "Survival expansion should add a large first pass of new recipes.")

	var items: Dictionary = content_library.get("items")
	var crafting_combinations: Dictionary = content_library.get("crafting_combinations")
	assert_true(items.size() >= 739, "Merged item library should include the base catalog plus survival expansion.")
	assert_true(crafting_combinations.size() >= 362, "Merged crafting library should include the base recipes plus survival expansion.")

	for item_id in ["surv_food_001", "surv_medical_001", "surv_equipment_001", "surv_crafted_001"]:
		var item: Dictionary = content_library.get_item(item_id)
		assert_true(not item.is_empty(), "Expanded item '%s' should load through ContentLibrary." % item_id)
		assert_true(not String(item.get("description", "")).is_empty(), "Expanded item '%s' should expose description." % item_id)
		assert_true(typeof(item.get("item_tags", [])) == TYPE_ARRAY and not (item.get("item_tags", []) as Array).is_empty(), "Expanded item '%s' should expose tags." % item_id)

	var recipe: Dictionary = content_library.get_crafting_combination("surv_utility_002", "rubber_band")
	assert_true(not recipe.is_empty(), "Generated recipes should be merged into the crafting lookup.")
	assert_eq(String(recipe.get("result_item_id", "")), "surv_crafted_001", "Representative generated recipe should point at its crafted result.")

	if content_library.has_method("get_loot_profile_entries"):
		var mart_entries: Array = content_library.get_loot_profile_entries("mart_01")
		assert_true(mart_entries.size() >= 40, "Contextual mart loot profile should expose a broad item pool.")
		var saw_expansion_item := false
		for entry in mart_entries:
			if String(entry.get("id", "")).begins_with("surv_"):
				saw_expansion_item = true
				break
		assert_true(saw_expansion_item, "Contextual loot profile should include generated expansion items.")
	else:
		assert_true(false, "ContentLibrary should expose get_loot_profile_entries for contextual loot expansion.")

	pass_test("SURVIVAL_ITEM_EXPANSION_OK")
