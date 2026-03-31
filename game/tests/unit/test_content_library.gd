extends "res://tests/support/test_case.gd"


func _init() -> void:
	var library := preload("res://scripts/autoload/content_library.gd").new()
	library.load_all()
	assert_eq(library.jobs.size(), 2, "Prototype jobs should load.")
	assert_eq(library.traits.size(), 4, "Prototype traits should load.")
	assert_true(library.buildings.has("mart_01"), "Prototype building should be indexed.")
	library.free()
	pass_test("CONTENT_LIBRARY_OK")
