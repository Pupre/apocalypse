extends "res://tests/support/test_case.gd"

const RUN_SHELL_SCENE_PATH := "res://scenes/run/run_shell.tscn"

var _transition_started_modes: Array[String] = []
var _transition_completed_modes: Array[String] = []


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_shell_scene := load(RUN_SHELL_SCENE_PATH) as PackedScene
	if not assert_true(run_shell_scene != null, "Missing run shell scene: %s" % RUN_SHELL_SCENE_PATH):
		return

	var run_shell := run_shell_scene.instantiate()
	if not assert_true(run_shell != null, "Run shell should instantiate."):
		return

	root.add_child(run_shell)

	if not assert_true(run_shell.has_method("start_run"), "Run shell should expose start_run()."):
		run_shell.free()
		return
	if not assert_true(run_shell.has_signal("transition_started"), "RunController should expose transition_started."):
		run_shell.free()
		return
	if not assert_true(run_shell.has_signal("transition_completed"), "RunController should expose transition_completed."):
		run_shell.free()
		return
	if not assert_true(run_shell.has_method("is_transition_in_progress"), "RunController should expose is_transition_in_progress()."):
		run_shell.free()
		return

	run_shell.start_run({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete", "unlucky"]),
		"remaining_points": 0,
	})

	var transition_layer := run_shell.get_node_or_null("TransitionLayer")
	var mode_host := run_shell.get_node_or_null("ModeHost")
	var outdoor_mode := run_shell.get_node_or_null("ModeHost/OutdoorMode")
	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(transition_layer != null, "Run shell should include a transition layer."):
		run_shell.free()
		return
	if not assert_true(mode_host != null, "Run shell should include a mode host."):
		run_shell.free()
		return
	if not assert_true(outdoor_mode != null, "Run shell should start in outdoor mode."):
		run_shell.free()
		return
	if not assert_true(content_library != null, "ContentLibrary autoload should be present for outdoor building lookups."):
		run_shell.free()
		return
	if not assert_true(
		transition_layer.has_method("set_duration_for_tests"),
		"Transition layer should expose set_duration_for_tests()."
	):
		run_shell.free()
		return

	transition_layer.set_duration_for_tests(0.1)

	var fade_rect := transition_layer.get_node_or_null("FadeRect") as ColorRect
	var player_sprite := outdoor_mode.get_node_or_null("PlayerSprite") as Sprite2D
	var mart_data: Dictionary = content_library.get_building("mart_01")
	var mart_position_data: Dictionary = mart_data.get("outdoor_position", {})
	var mart_position := Vector2(
		float(mart_position_data.get("x", 640.0)),
		float(mart_position_data.get("y", 360.0))
	)
	if not assert_true(fade_rect != null, "Transition layer should expose FadeRect."):
		run_shell.free()
		return
	if not assert_true(player_sprite != null, "Outdoor player sprite should be present."):
		run_shell.free()
		return
	outdoor_mode.move_player(Vector2.RIGHT, 1.5)
	assert_true(player_sprite.position.distance_to(mart_position) <= 72.0, "Player should enter building range before transition test.")

	run_shell.transition_started.connect(Callable(self, "_on_transition_started"))
	run_shell.transition_completed.connect(Callable(self, "_on_transition_completed"))

	outdoor_mode.try_enter_building("mart_01")

	if not await _wait_until(
		Callable(self, "_has_transition_started").bind("indoor"),
		"Timed out waiting for transition_started."
	):
		run_shell.free()
		return

	if not await _wait_until(
		Callable(self, "_is_mid_transition").bind(run_shell, mode_host, fade_rect),
		"Timed out waiting for mid-transition blocking state."
	):
		run_shell.free()
		return

	assert_true(run_shell.is_transition_in_progress(), "RunController should report an active transition during live fade.")
	assert_eq(mode_host.process_mode, Node.PROCESS_MODE_DISABLED, "ModeHost should be disabled while the fade is in progress.")
	assert_eq(fade_rect.mouse_filter, Control.MOUSE_FILTER_STOP, "FadeRect should block pointer input during live fade.")

	if not await _wait_until(
		Callable(self, "_has_transition_completed").bind(run_shell, "indoor"),
		"Timed out waiting for transition_completed."
	):
		run_shell.free()
		return

	assert_true(not run_shell.is_transition_in_progress(), "RunController should clear the transition flag after live fade completes.")
	assert_eq(mode_host.process_mode, Node.PROCESS_MODE_INHERIT, "ModeHost should be re-enabled after live fade completes.")
	assert_eq(fade_rect.mouse_filter, Control.MOUSE_FILTER_IGNORE, "FadeRect should stop blocking pointer input after live fade completes.")

	run_shell.free()
	pass_test("RUN_CONTROLLER_LIVE_TRANSITION_OK")


func _wait_until(predicate: Callable, failure_message: String, max_frames: int = 30) -> bool:
	for _i in range(max_frames):
		if predicate.call():
			return true
		await process_frame

	return assert_true(predicate.call(), failure_message)


func _has_transition_started(expected_mode_name: String) -> bool:
	return _transition_started_modes.has(expected_mode_name)


func _is_mid_transition(run_shell: Node, mode_host: Node, fade_rect: ColorRect) -> bool:
	if run_shell == null or mode_host == null or fade_rect == null:
		return false
	if not run_shell.has_method("is_transition_in_progress"):
		return false

	return (
		run_shell.is_transition_in_progress()
		and mode_host.process_mode == Node.PROCESS_MODE_DISABLED
		and fade_rect.mouse_filter == Control.MOUSE_FILTER_STOP
		and fade_rect.color.a > 0.0
	)


func _has_transition_completed(run_shell: Node, expected_mode_name: String) -> bool:
	if run_shell == null:
		return false
	if not run_shell.has_method("get_current_mode_name"):
		return false
	if not run_shell.has_method("is_transition_in_progress"):
		return false

	return (
		_transition_completed_modes.has(expected_mode_name)
		and run_shell.get_current_mode_name() == expected_mode_name
		and not run_shell.is_transition_in_progress()
	)


func _on_transition_started(mode_name: String) -> void:
	if not _transition_started_modes.has(mode_name):
		_transition_started_modes.append(mode_name)


func _on_transition_completed(mode_name: String) -> void:
	if not _transition_completed_modes.has(mode_name):
		_transition_completed_modes.append(mode_name)
