extends "res://tests/support/test_case.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary autoload should be registered."):
		return

	var jobs: Dictionary = content_library.get("jobs")
	var traits: Dictionary = content_library.get("traits")
	var buildings: Dictionary = content_library.get("buildings")
	var items: Dictionary = content_library.get("items")
	assert_eq(jobs.size(), 2, "Prototype jobs should load.")
	assert_eq(traits.size(), 4, "Prototype traits should load.")
	assert_eq(buildings.size(), 4, "Prototype should expose four outdoor buildings.")
	assert_true(buildings.has("mart_01"), "Prototype building should be indexed.")
	assert_true(buildings.has("apartment_01"), "Apartment building should be indexed.")
	assert_true(buildings.has("clinic_01"), "Clinic building should be indexed.")
	assert_true(buildings.has("office_01"), "Office building should be indexed.")
	assert_true(items.has("energy_bar"), "Prototype items should index consumables.")
	assert_true(items.has("bottled_water"), "Prototype items should index thirst recovery items.")
	assert_true(items.has("bandage"), "Prototype items should index health recovery items.")
	assert_true(items.has("instant_coffee"), "Prototype items should index everyday stimulants.")
	assert_true(items.has("stimulant_shot"), "Prototype items should index rare stronger stimulants.")
	assert_true(items.has("small_backpack"), "Prototype items should index equippable gear.")
	assert_true(items.has("running_shoes"), "Prototype items should index movement gear.")
	assert_true(items.has("utility_vest"), "Prototype items should index torso gear from the household goods area.")
	assert_true(float(items["energy_bar"].get("hunger_restore", 0.0)) > 0.0, "Food should expose hunger recovery.")
	assert_true(float(items["bottled_water"].get("thirst_restore", 0.0)) > 0.0, "Water should expose thirst recovery.")
	assert_true(float(items["bandage"].get("health_restore", 0.0)) > 0.0, "Medical items should expose health recovery.")
	assert_true(float(items["instant_coffee"].get("fatigue_restore", 0.0)) > 0.0, "Everyday stimulants should expose fatigue recovery.")
	assert_true(float(items["stimulant_shot"].get("fatigue_restore", 0.0)) > float(items["instant_coffee"].get("fatigue_restore", 0.0)), "Rare stimulants should be stronger than everyday stimulants.")
	pass_test("CONTENT_LIBRARY_OK")
