extends "res://tests/support/test_case.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary should be available for everyday item layer tests."):
		return

	var items: Dictionary = content_library.get("items")
	var crafting_combinations: Dictionary = content_library.get("crafting_combinations")
	assert_true(items.size() >= 858, "Merged item library should include the everyday item layer.")
	assert_true(crafting_combinations.size() >= 418, "Merged crafting library should include the everyday recipe layer.")

	for item_id in [
		"evd_cling_film_roll",
		"evd_coffee_filter_pack",
		"evd_hair_tie_pack",
		"evd_family_photo_strip",
		"evd_dead_power_bank",
		"evd_dry_tinder_pouch",
		"evd_shoulder_carry_sling",
	]:
		var item: Dictionary = content_library.get_item(item_id)
		assert_true(not item.is_empty(), "Everyday item '%s' should load." % item_id)
		assert_true(not String(item.get("description", "")).is_empty(), "Everyday item '%s' should expose description." % item_id)
		var tags: Array = item.get("item_tags", [])
		assert_true(tags.has("ordinary_world") or tags.has("crafted"), "Everyday item '%s' should keep a world or crafted identity tag." % item_id)

	var dead_power_bank: Dictionary = content_library.get_item("evd_dead_power_bank")
	assert_true(Array(dead_power_bank.get("item_tags", [])).has("barter"), "Dead electronics should remain useful as barter or future repair material, not pure survival filler.")

	var photo: Dictionary = content_library.get_item("evd_family_photo_strip")
	assert_true(Array(photo.get("item_tags", [])).has("story"), "Personal objects should preserve lived-world story tags.")

	var sling: Dictionary = content_library.get_item("evd_shoulder_carry_sling")
	assert_eq(String(sling.get("equip_slot", "")), "hand_carry", "Plausible improvised carry gear should equip through the hand-carry slot.")
	assert_true(float(sling.get("carry_capacity_bonus", 0.0)) > 0.0, "Improvised carry gear should improve carrying capacity.")

	_assert_recipe(content_library, "plastic_bag", "newspaper", "evd_dry_tinder_pouch")
	_assert_recipe(content_library, "evd_led_keychain_light", "evd_hair_tie_pack", "evd_hand_loop_light")
	_assert_recipe(content_library, "evd_coffee_filter_pack", "evd_empty_coffee_can", "evd_clean_water_prefilter")
	_assert_recipe(content_library, "evd_pillowcase", "evd_shoelace_pair", "evd_shoulder_carry_sling")
	_assert_recipe(content_library, "evd_sports_drink_powder", "bottled_water", "evd_mixed_sports_drink")

	var mart_entries: Array = content_library.get_loot_profile_entries("mart_01")
	assert_true(_loot_has(mart_entries, "evd_freezer_bag_box"), "Mart contextual loot should include everyday freezer bags.")
	assert_true(_loot_has(mart_entries, "evd_hair_tie_pack"), "Mart contextual loot should include small ordinary utility objects.")

	var apartment_entries: Array = content_library.get_loot_profile_entries("apartment_01")
	assert_true(_loot_has(apartment_entries, "evd_pillowcase"), "Residential loot should include bedroom textile objects.")
	assert_true(_loot_has(apartment_entries, "evd_family_photo_strip"), "Residential loot should include personal story objects.")

	pass_test("EVERYDAY_ITEM_CRAFTING_LAYER_OK")


func _assert_recipe(content_library: Node, primary: String, secondary: String, expected_result: String) -> void:
	var recipe: Dictionary = content_library.get_crafting_combination(primary, secondary)
	assert_true(not recipe.is_empty(), "Expected everyday recipe '%s + %s'." % [primary, secondary])
	assert_eq(String(recipe.get("result_item_id", "")), expected_result, "Everyday recipe should resolve to the intended result.")
	assert_true(not String(recipe.get("result_text", "")).is_empty(), "Everyday recipe should explain why the combination works.")


func _loot_has(entries: Array, item_id: String) -> bool:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry := entry_variant as Dictionary
		if String(entry.get("id", "")) == item_id:
			return true
	return false
