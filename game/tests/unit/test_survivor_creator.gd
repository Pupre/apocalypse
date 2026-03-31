extends "res://tests/support/test_case.gd"
const SURVIVOR_CREATOR_SCENE_PATH := "res://scenes/menus/survivor_creator.tscn"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var survivor_creator_scene := load(SURVIVOR_CREATOR_SCENE_PATH) as PackedScene
	if not assert_true(survivor_creator_scene != null, "Missing survivor creator scene: %s" % SURVIVOR_CREATOR_SCENE_PATH):
		return

	var survivor_creator := survivor_creator_scene.instantiate()
	if not assert_true(survivor_creator != null, "Failed to instantiate survivor creator scene."):
		return

	survivor_creator.load_content()
	survivor_creator.select_job("courier")
	survivor_creator.toggle_trait("athlete")
	survivor_creator.toggle_trait("unlucky")

	assert_eq(survivor_creator.job_id, "courier", "Expected courier to be the selected job.")
	assert_eq(survivor_creator.trait_ids, ["athlete", "unlucky"], "Traits should preserve selection order.")
	assert_eq(survivor_creator.remaining_points, 0, "Expected selected traits to spend all points.")

	survivor_creator.free()
	survivor_creator = null
	survivor_creator_scene = null

	pass_test("SURVIVOR_CREATOR_OK")
