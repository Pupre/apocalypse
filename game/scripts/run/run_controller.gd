extends Node

const OUTDOOR_MODE_SCENE := preload("res://scenes/outdoor/outdoor_mode.tscn")
const RUN_STATE_SCRIPT := preload("res://scripts/run/run_state.gd")
const INDOOR_MODE_SCENE := preload("res://scenes/indoor/indoor_mode.tscn")

var run_state = null
var _hud_presenter: Node = null
var _mode_host: Node = null
var _current_mode_name := ""


func start_run(survivor_config: Dictionary, building_id: String = "mart_01") -> void:
	run_state = RUN_STATE_SCRIPT.from_survivor_config(survivor_config)
	if run_state == null:
		push_error("RunController could not create a run state.")
		return

	_hud_presenter = get_node_or_null("HUD")
	_mode_host = get_node_or_null("ModeHost")
	_current_mode_name = "outdoor"

	if _hud_presenter != null and _hud_presenter.has_method("set_run_state"):
		_hud_presenter.set_run_state(run_state)

	_refresh_hud()
	_show_outdoor_mode(building_id)


func _show_indoor_mode(building_id: String) -> void:
	if _mode_host == null:
		push_error("RunController is missing the mode host.")
		return

	for child in _mode_host.get_children():
		child.queue_free()

	var indoor_mode := INDOOR_MODE_SCENE.instantiate()
	_mode_host.add_child(indoor_mode)

	if indoor_mode.has_signal("state_changed"):
		indoor_mode.state_changed.connect(Callable(self, "_on_indoor_state_changed"))

	if indoor_mode.has_method("configure"):
		indoor_mode.configure(run_state, building_id)
	_current_mode_name = "indoor"


func _show_outdoor_mode(building_id: String) -> void:
	if _mode_host == null:
		push_error("RunController is missing the mode host.")
		return

	for child in _mode_host.get_children():
		child.queue_free()

	var outdoor_mode := OUTDOOR_MODE_SCENE.instantiate()
	_mode_host.add_child(outdoor_mode)

	if outdoor_mode.has_signal("state_changed"):
		outdoor_mode.state_changed.connect(Callable(self, "_on_mode_state_changed"))

	if outdoor_mode.has_signal("building_entered"):
		outdoor_mode.building_entered.connect(Callable(self, "_on_building_entered"))

	if outdoor_mode.has_method("bind_run_state"):
		outdoor_mode.bind_run_state(run_state, building_id)
	_current_mode_name = "outdoor"


func _on_building_entered(building_id: String) -> void:
	_show_indoor_mode(building_id)


func _on_mode_state_changed() -> void:
	_refresh_hud()


func _on_indoor_state_changed() -> void:
	_refresh_hud()


func _refresh_hud() -> void:
	if _hud_presenter != null and _hud_presenter.has_method("refresh"):
		_hud_presenter.refresh()


func get_current_mode_name() -> String:
	return _current_mode_name


func resolve_first_indoor_action() -> bool:
	if _mode_host == null or _current_mode_name != "indoor":
		return false

	var indoor_mode := _mode_host.get_node_or_null("IndoorMode")
	if indoor_mode == null:
		return false

	var action_buttons := indoor_mode.get_node_or_null("Panel/VBox/ActionButtons") as VBoxContainer
	if action_buttons == null or action_buttons.get_child_count() == 0:
		return false

	var first_button := action_buttons.get_child(0) as Button
	if first_button == null:
		return false

	first_button.emit_signal("pressed")
	return true
