extends Control

signal state_changed

var _director: Node = null
var _title_label: Label = null
var _summary_label: Label = null
var _sleep_preview_label: Label = null
var _clue_list: VBoxContainer = null
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

	if _summary_label != null and _director.has_method("get_event_summary"):
		var summary: String = String(_director.get_event_summary())
		_summary_label.text = summary if not summary.is_empty() else "Search the room for clues."

	if _sleep_preview_label != null and _director.has_method("get_sleep_preview"):
		_sleep_preview_label.text = _sleep_preview_text(_director.get_sleep_preview())

	_refresh_clue_list()
	_refresh_action_buttons()


func _refresh_clue_list() -> void:
	if _clue_list == null:
		return

	_clear_children(_clue_list)
	if not _director.has_method("get_visible_clues"):
		return

	for clue in _director.get_visible_clues():
		var clue_label := Label.new()
		clue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		clue_label.text = "• %s" % String(clue.get("text", clue.get("id", "")))
		_clue_list.add_child(clue_label)


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
	if _director != null and _director.has_method("apply_action"):
		_director.apply_action(action_id)


func _sleep_preview_text(preview: Dictionary) -> String:
	if preview.is_empty():
		return "Sleep preview: unavailable"

	return "Sleep preview: %d min (%s)" % [int(preview.get("sleep_minutes", 0)), String(preview.get("band", "unknown"))]


func _cache_nodes() -> void:
	_director = get_node_or_null("Director")
	_title_label = get_node_or_null("Panel/VBox/TitleLabel") as Label
	_summary_label = get_node_or_null("Panel/VBox/SummaryLabel") as Label
	_sleep_preview_label = get_node_or_null("Panel/VBox/SleepPreviewLabel") as Label
	_clue_list = get_node_or_null("Panel/VBox/ClueList") as VBoxContainer
	_action_buttons = get_node_or_null("Panel/VBox/ActionButtons") as VBoxContainer


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
