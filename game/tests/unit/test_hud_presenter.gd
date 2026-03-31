extends "res://tests/support/test_case.gd"

const HUD_SCENE_PATH := "res://scenes/run/hud.tscn"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var hud_scene := load(HUD_SCENE_PATH) as PackedScene
	if not assert_true(hud_scene != null, "Missing HUD scene: %s" % HUD_SCENE_PATH):
		return

	var hud := hud_scene.instantiate()
	if not assert_true(hud != null, "HUD should instantiate."):
		return

	root.add_child(hud)

	if not assert_true(hud.has_method("set_mode_presentation"), "HUD should expose set_mode_presentation()."):
		hud.free()
		return

	var panel := hud.get_node_or_null("Panel") as PanelContainer
	var title_label := hud.get_node_or_null("Panel/VBox/TitleLabel") as Label
	if not assert_true(panel != null, "HUD should expose Panel."):
		hud.free()
		return
	if not assert_true(title_label != null, "HUD should expose TitleLabel."):
		hud.free()
		return

	hud.set_mode_presentation("outdoor")
	assert_eq(panel.offset_left, 16.0, "Outdoor mode should pin the HUD left offset to 16.")
	assert_eq(panel.offset_top, 16.0, "Outdoor mode should pin the HUD top offset to 16.")
	assert_eq(panel.offset_right, 336.0, "Outdoor mode should pin the HUD right offset to 336.")
	assert_eq(panel.offset_bottom, 180.0, "Outdoor mode should pin the HUD bottom offset to 180.")
	assert_true(is_equal_approx(panel.modulate.a, 1.0), "Outdoor mode should keep the HUD fully opaque.")
	assert_eq(title_label.text, "외부 생존 정보", "Outdoor mode should use the outdoor HUD title.")

	hud.set_mode_presentation("indoor")
	assert_eq(panel.offset_left, 24.0, "Indoor mode should pin the HUD left offset to 24.")
	assert_eq(panel.offset_top, 20.0, "Indoor mode should pin the HUD top offset to 20.")
	assert_eq(panel.offset_right, 272.0, "Indoor mode should pin the HUD right offset to 272.")
	assert_eq(panel.offset_bottom, 156.0, "Indoor mode should pin the HUD bottom offset to 156.")
	assert_true(is_equal_approx(panel.modulate.a, 0.9), "Indoor mode should dim the HUD to alpha 0.9.")
	assert_eq(title_label.text, "실내 생존 정보", "Indoor mode should use the indoor HUD title.")

	hud.free()
	pass_test("HUD_PRESENTATION_OK")
