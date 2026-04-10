extends PanelContainer

signal close_requested

var _item_rows: Array[Dictionary] = []
var _selected_entry: Dictionary = {}
var _item_list: VBoxContainer = null
var _attempt_list: VBoxContainer = null
var _close_button: Button = null
var _buttons_bound := false


func _ready() -> void:
	_cache_nodes()
	_bind_buttons()


func configure(item_rows: Array[Dictionary], selected_entry: Dictionary) -> void:
	_cache_nodes()
	_bind_buttons()
	_item_rows = _duplicate_rows(item_rows)
	_selected_entry = selected_entry.duplicate(true)
	_render_item_rows()
	_render_attempt_rows()


func get_attempt_labels() -> Array[String]:
	var labels: Array[String] = []
	var attempts: Array = _selected_entry.get("attempts", [])
	for attempt_variant in attempts:
		if typeof(attempt_variant) != TYPE_DICTIONARY:
			continue
		labels.append(_attempt_label(attempt_variant as Dictionary))
	return labels


func _bind_buttons() -> void:
	if _buttons_bound:
		return
	if _close_button != null and not _close_button.pressed.is_connected(Callable(self, "_on_close_pressed")):
		_close_button.pressed.connect(Callable(self, "_on_close_pressed"))
	_buttons_bound = true


func _render_item_rows() -> void:
	if _item_list == null:
		return

	_clear_children(_item_list)
	if _item_rows.is_empty():
		var empty_label := Label.new()
		empty_label.text = "기록된 아이템이 없다."
		_item_list.add_child(empty_label)
		return

	for row in _item_rows:
		var label := Label.new()
		label.text = "%s (%d)" % [
			String(row.get("label", row.get("item_id", "아이템"))),
			int(row.get("attempt_count", 0))
		]
		label.autowrap_mode = 3
		_item_list.add_child(label)


func _render_attempt_rows() -> void:
	if _attempt_list == null:
		return

	_clear_children(_attempt_list)
	var attempt_labels := get_attempt_labels()
	if attempt_labels.is_empty():
		var empty_label := Label.new()
		empty_label.text = "기록된 조합이 없다."
		_attempt_list.add_child(empty_label)
		return

	for attempt_label in attempt_labels:
		var label := Label.new()
		label.text = attempt_label
		label.autowrap_mode = 3
		_attempt_list.add_child(label)


func _attempt_label(attempt: Dictionary) -> String:
	var other_item_name := String(attempt.get("other_item_name", attempt.get("other_item_id", "?")))
	var result_type := String(attempt.get("result_type", "invalid"))
	if result_type == "invalid":
		return "+ %s -> 변화 없음" % other_item_name

	var result_label := String(attempt.get("result_label", attempt.get("result_item_name", attempt.get("result_item_id", "?"))))
	return "+ %s -> %s" % [other_item_name, result_label]


func _duplicate_rows(rows: Array[Dictionary]) -> Array[Dictionary]:
	var duplicated: Array[Dictionary] = []
	for row in rows:
		duplicated.append(row.duplicate(true))
	return duplicated


func _cache_nodes() -> void:
	_item_list = get_node_or_null("VBox/ContentRow/ItemColumn/ItemList") as VBoxContainer
	_attempt_list = get_node_or_null("VBox/ContentRow/AttemptColumn/AttemptList") as VBoxContainer
	_close_button = get_node_or_null("VBox/Header/CloseButton") as Button


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_close_pressed() -> void:
	close_requested.emit()
