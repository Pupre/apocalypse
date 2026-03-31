extends "res://tests/support/test_case.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var content_library := root.get_node_or_null("ContentLibrary")
	assert_true(content_library != null, "ContentLibrary autoload should be registered.")
	content_library.call("load_all")
	var jobs: Dictionary = content_library.get("jobs")
	var traits: Dictionary = content_library.get("traits")
	var buildings: Dictionary = content_library.get("buildings")
	assert_eq(jobs.size(), 2, "Prototype jobs should load.")
	assert_eq(traits.size(), 4, "Prototype traits should load.")
	assert_true(buildings.has("mart_01"), "Prototype building should be indexed.")
	pass_test("CONTENT_LIBRARY_OK")
