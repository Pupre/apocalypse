extends Node

const TITLE_MENU_SCENE := preload("res://scenes/menus/title_menu.tscn")
const SURVIVOR_CREATOR_SCENE := preload("res://scenes/menus/survivor_creator.tscn")

var _active_screen: Node


func _ready() -> void:
	_show_title_menu()


func _show_title_menu() -> void:
	_swap_screen(TITLE_MENU_SCENE.instantiate() as Node)


func _show_survivor_creator() -> void:
	_swap_screen(SURVIVOR_CREATOR_SCENE.instantiate() as Node)


func _swap_screen(screen: Node) -> void:
	if is_instance_valid(_active_screen):
		remove_child(_active_screen)
		_active_screen.queue_free()

	_active_screen = screen
	if _active_screen == null:
		return

	if _active_screen.has_signal("start_requested"):
		_active_screen.connect("start_requested", Callable(self, "_show_survivor_creator"))

	add_child(_active_screen)
