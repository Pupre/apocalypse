extends Node

const APP_FONT_PATH := "res://assets/fonts/NotoSansKR-VF.ttf"
const APP_FONT_SIZE := 15

func _ready() -> void:
	_install_ui_theme()

	var app_router := get_node_or_null("/root/AppRouter")
	if app_router == null:
		push_error("AppRouter autoload is missing.")
		return

	app_router.set_host(self)
	app_router.show_title()


func get_active_screen() -> Node:
	if get_child_count() == 0:
		return null

	return get_child(0)


func _install_ui_theme() -> void:
	var font := FontFile.new()
	var error := font.load_dynamic_font(APP_FONT_PATH)
	if error != OK:
		push_error("App font is missing: %s" % APP_FONT_PATH)
		return

	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = APP_FONT_SIZE
	get_tree().root.theme = theme
