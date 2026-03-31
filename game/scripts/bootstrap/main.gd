extends Node

const TITLE_MENU_SCENE := preload("res://scenes/menus/title_menu.tscn")
const SURVIVOR_CREATOR_SCENE := preload("res://scenes/menus/survivor_creator.tscn")

var _active_screen: Node


func _ready() -> void:
	_show_title_menu()


func _show_title_menu() -> void:
	var title_menu = TITLE_MENU_SCENE.instantiate()
	title_menu.start_requested.connect(Callable(self, "_show_survivor_creator"))
	_swap_screen(title_menu)


func _show_survivor_creator() -> void:
	_swap_screen(SURVIVOR_CREATOR_SCENE.instantiate())


func _swap_screen(screen: Node) -> void:
	if is_instance_valid(_active_screen):
		remove_child(_active_screen)
		_active_screen.queue_free()

	_active_screen = screen
	if _active_screen != null:
		add_child(_active_screen)
