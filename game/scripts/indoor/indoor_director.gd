extends Node

signal state_changed

const ACTION_RESOLVER_SCRIPT := preload("res://scripts/indoor/indoor_action_resolver.gd")

var _resolver := ACTION_RESOLVER_SCRIPT.new()
var _run_state = null
var _building_data: Dictionary = {}
var _event_data: Dictionary = {}
var _event_state: Dictionary = _create_initial_event_state()


func configure(run_state, building_id: String) -> void:
	_run_state = run_state
	_building_data = _get_building_data(building_id)
	if _building_data.is_empty():
		_event_data = {}
		_event_state = _create_initial_event_state()
		state_changed.emit()
		return

	_event_data = _resolver.load_event(String(_building_data.get("indoor_event_path", "")))
	_event_state = _create_initial_event_state(_resolver.get_entry_zone_id(_event_data))
	state_changed.emit()


func get_event_title() -> String:
	if not _event_data.is_empty():
		return String(_event_data.get("name", _building_data.get("name", "Indoor")))

	return String(_building_data.get("name", "Indoor"))


func get_event_summary() -> String:
	return String(_event_data.get("summary", ""))


func get_current_zone_id() -> String:
	return String(_event_state.get("current_zone_id", ""))


func get_current_zone_label() -> String:
	var current_zone_id := get_current_zone_id()
	if current_zone_id.is_empty() or _event_data.is_empty():
		return ""

	var current_zone := _resolver.get_zone(_event_data, current_zone_id)
	if current_zone.is_empty():
		return current_zone_id

	var zone_label := String(current_zone.get("label", ""))
	if not zone_label.is_empty():
		return zone_label

	return current_zone_id


func get_current_zone_summary() -> String:
	var current_zone_id := get_current_zone_id()
	if current_zone_id.is_empty() or _event_data.is_empty():
		return get_event_summary()

	var current_zone := _resolver.get_zone(_event_data, current_zone_id)
	if current_zone.is_empty():
		return get_event_summary()

	var zone_summary := String(current_zone.get("summary", ""))
	if not zone_summary.is_empty():
		return zone_summary

	return get_event_summary()


func get_actions() -> Array[Dictionary]:
	var actions := _resolver.get_actions(_event_data, _event_state)
	if _is_at_entry_zone():
		actions.append({
			"id": "exit_building",
			"label": "건물 밖으로 나간다",
			"type": "exit",
		})

	return actions


func get_sleep_preview() -> Dictionary:
	return _resolver.get_sleep_preview(_run_state)


func get_feedback_message() -> String:
	return String(_event_state.get("last_feedback_message", ""))


func apply_action(action_id: String) -> bool:
	if action_id == "exit_building":
		return true

	if not _resolver.apply_action(_run_state, _event_data, _event_state, action_id):
		return false

	state_changed.emit()
	return true


func _get_building_data(building_id: String) -> Dictionary:
	if not ContentLibrary.has_method("get_building"):
		push_error("ContentLibrary autoload is missing get_building(building_id).")
		return {}

	return ContentLibrary.get_building(building_id)


func _create_initial_event_state(current_zone_id: String = "") -> Dictionary:
	var visited_zone_ids := PackedStringArray()
	if not current_zone_id.is_empty():
		visited_zone_ids.append(current_zone_id)

	return {
		"current_zone_id": current_zone_id,
		"visited_zone_ids": visited_zone_ids,
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"noise": 0,
	}


func _is_at_entry_zone() -> bool:
	return get_current_zone_id() == _resolver.get_entry_zone_id(_event_data)
