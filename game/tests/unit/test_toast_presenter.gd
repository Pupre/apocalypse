extends "res://tests/support/test_case.gd"

const TOAST_SCENE_PATH := "res://scenes/shared/toast_presenter.tscn"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var toast_scene := load(TOAST_SCENE_PATH) as PackedScene
	if not assert_true(toast_scene != null, "Toast presenter scene should load."):
		return

	var toast := toast_scene.instantiate() as CanvasLayer
	if not assert_true(toast != null, "Toast presenter should instantiate as a CanvasLayer."):
		return

	root.add_child(toast)
	var shell := toast.get_node_or_null("ToastShell") as Control
	var message_label := toast.get_node_or_null("ToastShell/Margin/Row/MessageLabel") as Label
	var icon_slot := toast.get_node_or_null("ToastShell/Margin/Row/IconSlot") as Control
	var icon_rect := toast.get_node_or_null("ToastShell/Margin/Row/IconSlot/IconCenter/IconRect") as TextureRect
	var fallback_glyph := toast.get_node_or_null("ToastShell/Margin/Row/IconSlot/IconCenter/FallbackGlyph") as Label
	if not assert_true(shell != null and message_label != null and icon_slot != null and icon_rect != null and fallback_glyph != null, "Toast presenter should expose a shell, icon slot, and message label."):
		toast.free()
		return

	assert_true(not shell.visible, "Toast should start hidden.")

	toast.show_toast("success", "붕대 챙겼다.", 0.4)
	assert_true(shell.visible, "Toast should become visible when shown.")
	assert_eq(message_label.text, "붕대 챙겼다.", "Toast should render the requested message.")
	assert_true(icon_slot.visible, "Toast should keep a visible icon slot for the left-side feedback mark.")
	assert_eq(fallback_glyph.text, "✓", "Success toasts should use the success fallback glyph when no item icon is supplied.")
	assert_true(not icon_rect.visible, "Success toasts without an item icon should keep the generic success glyph visible.")

	toast.show_toast("success", "붕대 챙겼다.", 0.4)
	assert_eq(message_label.text, "붕대 챙겼다.", "Showing the same toast should refresh rather than duplicate.")

	toast.show_toast("warning", "가방이 가득 찼다.", 0.4)
	assert_eq(message_label.text, "가방이 가득 찼다.", "New toast messages should replace the previous toast immediately.")
	assert_eq(fallback_glyph.text, "X", "Warning toasts should use a clear failure glyph.")
	assert_true(not icon_rect.visible, "Warning toasts should not show a generic item icon.")

	toast.show_toast("success", "생수를 만들었다.", 0.4, "bottled_water")
	assert_true(icon_rect.visible, "Success toasts with a result item should show that item icon.")
	assert_true(not fallback_glyph.visible, "Item-backed success toasts should hide the fallback glyph.")

	await root.get_tree().create_timer(0.6).timeout
	assert_true(not shell.visible, "Toast should auto-hide after its duration elapses.")

	toast.free()
	pass_test("TOAST_PRESENTER_OK")
