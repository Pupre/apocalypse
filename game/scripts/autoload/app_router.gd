extends Node

const TITLE_MENU_SCENE := preload("res://scenes/menus/title_menu.tscn")
const SURVIVOR_CREATOR_SCENE := preload("res://scenes/menus/survivor_creator.tscn")
const RUN_SHELL_SCENE := preload("res://scenes/run/run_shell.tscn")

var _host: Node = null
var _active_screen: Node = null


func set_host(host: Node) -> void:
	_host = host


func show_title() -> void:
	var title_menu := TITLE_MENU_SCENE.instantiate()
	title_menu.start_requested.connect(Callable(self, "_on_start_requested"))
	_swap_screen(title_menu)


func show_survivor_creator() -> void:
	var survivor_creator := SURVIVOR_CREATOR_SCENE.instantiate()
	survivor_creator.survivor_confirmed.connect(Callable(self, "_on_survivor_confirmed"))
	_swap_screen(survivor_creator)


func launch_run_shell(job_id: String, trait_ids: Array[String]) -> void:
	var run_shell := RUN_SHELL_SCENE.instantiate()
	_swap_screen(run_shell)

	if run_shell.has_method("start_run"):
		run_shell.start_run({
			"job_id": job_id,
			"trait_ids": trait_ids.duplicate(),
			"remaining_points": 0,
		}, "mart_01")


func _on_start_requested() -> void:
	show_survivor_creator()


func _on_survivor_confirmed(job_id: String, trait_ids: Array[String]) -> void:
	launch_run_shell(job_id, trait_ids)


func _swap_screen(screen: Node) -> void:
	if _host == null:
		push_error("AppRouter host is not set.")
		return

	if is_instance_valid(_active_screen):
		_host.remove_child(_active_screen)
		_active_screen.queue_free()

	_active_screen = screen
	if _active_screen != null:
		_host.add_child(_active_screen)
