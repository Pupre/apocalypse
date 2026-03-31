extends "res://tests/support/test_case.gd"
const BOOTSTRAP_SCENE_PATH := "res://scenes/bootstrap/main.tscn"


func _init() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"),
		BOOTSTRAP_SCENE_PATH,
		"Project main scene does not point at the bootstrap scene."
	)

	var bootstrap_scene := load(BOOTSTRAP_SCENE_PATH) as PackedScene
	if not assert_true(bootstrap_scene != null, "Missing bootstrap scene: %s" % BOOTSTRAP_SCENE_PATH):
		return

	var bootstrap_instance := bootstrap_scene.instantiate() as Node
	if not assert_true(bootstrap_instance != null, "Failed to instantiate bootstrap scene."):
		return

	bootstrap_instance.free()
	bootstrap_instance = null
	bootstrap_scene = null

	pass_test("BOOTSTRAP_SCENE_OK")
