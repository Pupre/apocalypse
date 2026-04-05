extends "res://tests/support/test_case.gd"

const BOOTSTRAP_SCENE := preload("res://scenes/bootstrap/main.tscn")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var bootstrap := BOOTSTRAP_SCENE.instantiate()
	if not assert_true(bootstrap != null, "Bootstrap scene should instantiate for UI theme setup."):
		return

	root.add_child(bootstrap)
	await process_frame

	var theme := root.theme
	if not assert_true(theme != null, "Bootstrap should install an application theme on the root window."):
		return

	assert_true(
		theme.default_font != null,
		"Application theme should provide a bundled default font so Korean text does not depend on OS fallback."
	)

	bootstrap.queue_free()
	await process_frame
	pass_test("UI_THEME_OK")
