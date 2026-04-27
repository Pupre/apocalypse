extends "res://tests/support/test_case.gd"

const RESOLVER_SCRIPT_PATH := "res://scripts/ui/ui_kit_resolver.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var resolver_script := load(RESOLVER_SCRIPT_PATH) as Script
	if not assert_true(resolver_script != null, "UiKitResolver script should load."):
		return

	var resolver = resolver_script.new()
	if not assert_true(resolver != null, "UiKitResolver should instantiate."):
		return

	var header_texture: Texture2D = resolver.get_texture("hud/hud_header_chip_compact.png")
	if not assert_true(header_texture != null, "Resolver should load the compact HUD header texture from the v2 devkit."):
		return
	assert_eq(header_texture.get_width(), 620, "Compact HUD header texture width should match the v2 asset manifest.")
	assert_eq(header_texture.get_height(), 40, "Compact HUD header texture height should match the v2 asset manifest.")

	var header_style: StyleBoxTexture = resolver.get_stylebox("hud/hud_header_chip_compact.png")
	if not assert_true(header_style != null, "Resolver should build a stylebox for the compact HUD header texture."):
		return
	assert_eq(int(header_style.texture_margin_left), 22, "Resolver should read the compact HUD header left 9-slice from the master bundle manifest.")
	assert_eq(int(header_style.texture_margin_right), 22, "Resolver should read the compact HUD header right 9-slice from the master bundle manifest.")
	assert_eq(int(header_style.texture_margin_top), 14, "Resolver should read the compact HUD header top 9-slice from the master bundle manifest.")
	assert_eq(int(header_style.texture_margin_bottom), 14, "Resolver should read the compact HUD header bottom 9-slice from the master bundle manifest.")

	var icon_slot_style: StyleBoxTexture = resolver.get_stylebox("sheet/inventory_icon_slot.png")
	if not assert_true(icon_slot_style != null, "Resolver should build a stylebox for the compact inventory icon slot."):
		return
	assert_eq(int(icon_slot_style.texture_margin_left), 12, "Resolver should read the compact inventory icon slot left 9-slice from the master inventory pack manifest.")
	assert_eq(int(icon_slot_style.texture_margin_top), 12, "Resolver should read the compact inventory icon slot top 9-slice from the master inventory pack manifest.")

	var structure_panel_style: StyleBoxTexture = resolver.get_stylebox("structure/structure_panel_bg.png")
	if not assert_true(structure_panel_style != null, "Resolver should build a stylebox for the structure panel background from the master structure pack."):
		return
	assert_eq(int(structure_panel_style.texture_margin_left), 22, "Resolver should read the structure panel left 9-slice from the master structure pack manifest.")
	assert_eq(int(structure_panel_style.texture_margin_top), 22, "Resolver should read the structure panel top 9-slice from the master structure pack manifest.")

	pass_test("UI_KIT_RESOLVER_OK")
