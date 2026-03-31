extends "res://tests/support/test_case.gd"

const TRANSITION_LAYER_SCENE_PATH := "res://scenes/run/mode_transition_layer.tscn"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var transition_layer_scene := load(TRANSITION_LAYER_SCENE_PATH) as PackedScene
	if not assert_true(
		transition_layer_scene != null,
		"Missing transition layer scene: %s" % TRANSITION_LAYER_SCENE_PATH
	):
		return

	var transition_layer := transition_layer_scene.instantiate()
	if not assert_true(transition_layer != null, "Transition layer should instantiate."):
		return

	root.add_child(transition_layer)

	if not assert_true(
		transition_layer.layer == 20,
		"Transition layer should pin CanvasLayer.layer to 20."
	):
		transition_layer.free()
		return

	if not assert_true(
		transition_layer.has_method("set_duration_for_tests"),
		"Transition layer should expose set_duration_for_tests()."
	):
		transition_layer.free()
		return

	if not assert_true(
		transition_layer.has_method("fade_out"),
		"Transition layer should expose fade_out()."
	):
		transition_layer.free()
		return

	if not assert_true(
		transition_layer.has_method("fade_in"),
		"Transition layer should expose fade_in()."
	):
		transition_layer.free()
		return

	var fade_rect := transition_layer.get_node_or_null("FadeRect") as ColorRect
	if not assert_true(fade_rect != null, "Transition layer should expose a FadeRect node."):
		transition_layer.free()
		return

	transition_layer.set_duration_for_tests(0.0)

	await transition_layer.fade_out()
	if not assert_true(
		fade_rect.color.a == 1.0,
		"fade_out() should leave the overlay fully opaque."
	):
		transition_layer.free()
		return

	await transition_layer.fade_in()
	if not assert_true(
		fade_rect.color.a == 0.0,
		"fade_in() should restore the overlay to transparent."
	):
		transition_layer.free()
		return

	transition_layer.free()
	pass_test("MODE_TRANSITION_PRESENTER_OK")
