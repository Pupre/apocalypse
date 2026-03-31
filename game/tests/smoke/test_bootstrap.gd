extends SceneTree

const TestCase := preload("res://tests/support/test_case.gd")
const BOOTSTRAP_SCENE_PATH := "res://scenes/bootstrap/main.tscn"


func _init() -> void:
	var test_case := TestCase.new()
	var bootstrap_scene := load(BOOTSTRAP_SCENE_PATH)
	if not test_case.assert_true(bootstrap_scene != null, "Missing bootstrap scene: %s" % BOOTSTRAP_SCENE_PATH):
		quit(1)
		return

	test_case.pass_test("BOOTSTRAP_SCENE_OK")
	quit(0)
