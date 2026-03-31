extends "res://tests/support/test_case.gd"
const BOOTSTRAP_SCENE_PATH := "res://scenes/bootstrap/main.tscn"


func _init() -> void:
	var bootstrap_scene := load(BOOTSTRAP_SCENE_PATH)
	if not assert_true(bootstrap_scene != null, "Missing bootstrap scene: %s" % BOOTSTRAP_SCENE_PATH):
		return

	pass_test("BOOTSTRAP_SCENE_OK")
