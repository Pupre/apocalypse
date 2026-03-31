extends Node

signal state_changed

const ACTION_RESOLVER_SCRIPT := preload("res://scripts/indoor/indoor_action_resolver.gd")

var _resolver := ACTION_RESOLVER_SCRIPT.new()
var _run_state = null
var _building_data: Dictionary = {}
var _event_data: Dictionary = {}
var _event_state: Dictionary = {"revealed_clue_ids": PackedStringArray()}


func configure(run_state, building_id: String) -> void:
	_run_state = run_state
	_building_data = _get_building_data(building_id)
	if _building_data.is_empty():
		_event_data = {}
		_event_state = {"revealed_clue_ids": PackedStringArray()}
		state_changed.emit()
		return

	_event_data = _resolver.load_event(String(_building_data.get("indoor_event_path", "")))
	_event_state = {"revealed_clue_ids": PackedStringArray()}
	state_changed.emit()


func get_event_title() -> String:
	if not _event_data.is_empty():
		return String(_event_data.get("name", _building_data.get("name", "Indoor")))

	return String(_building_data.get("name", "Indoor"))


func get_event_summary() -> String:
	return String(_event_data.get("summary", ""))


func get_visible_clues() -> Array[Dictionary]:
	return _resolver.get_visible_clues(_event_data, _event_state)


func get_actions() -> Array[Dictionary]:
	return _resolver.get_actions(_event_data)


func get_sleep_preview() -> Dictionary:
	return _resolver.get_sleep_preview(_run_state)


func apply_action(action_id: String) -> bool:
	if not _resolver.apply_action(_run_state, _event_data, _event_state, action_id):
		return false

	state_changed.emit()
	return true


func _get_building_data(building_id: String) -> Dictionary:
	if not ContentLibrary.has_method("get_building"):
		push_error("ContentLibrary autoload is missing get_building(building_id).")
		return {}

	return ContentLibrary.get_building(building_id)
