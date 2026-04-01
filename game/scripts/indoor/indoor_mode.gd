extends Control

signal state_changed
signal exit_requested

var _director: Node = null
var _title_label: Label = null
var _location_label: Label = null
var _time_label: Label = null
var _summary_label: Label = null
var _result_label: Label = null
var _action_buttons: VBoxContainer = null
var _director_connected := false


func configure(run_state, building_id: String = "mart_01") -> void:
	_cache_nodes()
	_bind_director()
	if _director != null and _director.has_method("configure"):
		_director.configure(run_state, building_id)


func _ready() -> void:
	_cache_nodes()
	_bind_director()


func _bind_director() -> void:
	if _director == null or _director_connected or not _director.has_signal("state_changed"):
		return

	_director.state_changed.connect(Callable(self, "_on_director_state_changed"))
	_director_connected = true


func _on_director_state_changed() -> void:
	_refresh_view()
	state_changed.emit()


func _refresh_view() -> void:
	if _director == null:
		return

	if _title_label != null and _director.has_method("get_event_title"):
		_title_label.text = _director.get_event_title()

	if _location_label != null:
		_update_location_label()

	if _time_label != null:
		_update_time_label()

	if _summary_label != null and _director.has_method("get_current_zone_summary"):
		var summary: String = String(_director.get_current_zone_summary())
		_summary_label.text = summary if not summary.is_empty() else "방 안을 살펴 단서를 찾아본다."

	if _result_label != null and _director.has_method("get_feedback_message"):
		_result_label.text = String(_director.get_feedback_message())

	_refresh_action_buttons()


func _refresh_action_buttons() -> void:
	if _action_buttons == null:
		return

	_clear_children(_action_buttons)
	if not _director.has_method("get_actions"):
		return

	for action in _director.get_actions():
		var action_id := String(action.get("id", ""))
		if action_id.is_empty():
			continue

		var button := Button.new()
		button.text = String(action.get("label", action_id))
		button.pressed.connect(Callable(self, "_on_action_pressed").bind(action_id))
		_action_buttons.add_child(button)


func _on_action_pressed(action_id: String) -> void:
	if action_id == "exit_building":
		exit_requested.emit()
		return

	if _director != null and _director.has_method("apply_action"):
		_director.apply_action(action_id)


func _cache_nodes() -> void:
	_director = get_node_or_null("Director")
	_title_label = get_node_or_null("Panel/VBox/Header/TitleLabel") as Label
	_location_label = get_node_or_null("Panel/VBox/Header/LocationLabel") as Label
	_time_label = get_node_or_null("Panel/VBox/Header/TimeLabel") as Label
	_summary_label = get_node_or_null("Panel/VBox/SummaryLabel") as Label
	_result_label = get_node_or_null("Panel/VBox/ResultLabel") as Label
	_action_buttons = get_node_or_null("Panel/VBox/ActionButtons") as VBoxContainer


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _update_location_label() -> void:
	if _location_label == null:
		return

	if _director == null or not _director.has_method("get_current_zone_label"):
		_location_label.text = "위치: 확인 중"
		return

	var zone_label := String(_director.get_current_zone_label())
	_location_label.text = "위치: %s" % (zone_label if not zone_label.is_empty() else "확인 중")


func _update_time_label() -> void:
	if _time_label == null:
		return

	if _director == null or not _director.has_method("get_clock_label"):
		_time_label.text = "시각: 확인 중"
		return

	var clock_label := String(_director.get_clock_label())
	_time_label.text = "시각: %s" % (clock_label if not clock_label.is_empty() else "확인 중")
