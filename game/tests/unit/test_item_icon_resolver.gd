extends "res://tests/support/test_case.gd"

const ITEM_ICON_RESOLVER_SCRIPT_PATH := "res://scripts/ui/item_icon_resolver.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var resolver_script := load(ITEM_ICON_RESOLVER_SCRIPT_PATH) as Script
	if not assert_true(resolver_script != null, "Item icon resolver script should load."):
		return

	var resolver = resolver_script.new()
	if not assert_true(resolver != null, "Item icon resolver should instantiate."):
		return

	var icon_24: Texture2D = resolver.get_item_icon("butter_cookie_box")
	if not assert_true(icon_24 != null, "Newly integrated addon items should resolve a 24px cutout icon."):
		return
	assert_eq(icon_24.get_width(), 24, "Default item icon variant should stay on the 24px cutout asset.")
	assert_eq(icon_24.get_height(), 24, "Default item icon variant should keep the 24px cutout height.")

	var icon_32: Texture2D = resolver.get_item_icon("butter_cookie_box", "cutout_32")
	if not assert_true(icon_32 != null, "Addon items should also resolve the optional 32px cutout icon."):
		return
	assert_eq(icon_32.get_width(), 32, "32px item icon variant should resolve the 32px cutout asset.")
	assert_eq(icon_32.get_height(), 32, "32px item icon variant should keep the 32px cutout height.")

	var generated_icon: Texture2D = resolver.get_item_icon("surv_equipment_001")
	if not assert_true(generated_icon != null, "Generated survival expansion items should resolve a 24px cutout icon."):
		return
	assert_eq(generated_icon.get_width(), 24, "Generated survival item icon should resolve the 24px cutout asset.")
	assert_eq(generated_icon.get_height(), 24, "Generated survival item icon should keep the 24px cutout height.")

	var everyday_icon: Texture2D = resolver.get_item_icon("evd_coffee_filter_pack")
	if not assert_true(everyday_icon != null, "Curated everyday items should resolve a 24px cutout icon."):
		return
	assert_eq(everyday_icon.get_width(), 24, "Everyday item icon should resolve the 24px cutout asset.")
	assert_eq(everyday_icon.get_height(), 24, "Everyday item icon should keep the 24px cutout height.")

	var missing_icon: Texture2D = resolver.get_item_icon("missing_item_id")
	assert_true(missing_icon == null, "Unknown item ids should still resolve to null.")

	pass_test("ITEM_ICON_RESOLVER_OK")
