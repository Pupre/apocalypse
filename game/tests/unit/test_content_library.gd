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
	assert_true(buildings.has("mart_01"), "Prototype building should be indexed.")
	assert_true(items.has("energy_bar"), "Prototype items should index consumables.")
	assert_true(items.has("small_backpack"), "Prototype items should index equippable gear.")
	assert_true(items.has("running_shoes"), "Prototype items should index movement gear.")
	assert_true(items.has("utility_vest"), "Prototype items should index torso gear from the household goods area.")
	pass_test("CONTENT_LIBRARY_OK")
