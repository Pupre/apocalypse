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
var _minimap: Control = null
var _inventory_title_label: Label = null
var _inventory_status_label: Label = null
var _inventory_items: VBoxContainer = null
var _item_sheet: Control = null
var _item_sheet_title: Label = null
var _item_sheet_description: Label = null
var _item_sheet_effect: Label = null
var _item_sheet_actions: HBoxContainer = null
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
	_refresh_minimap()
	_refresh_inventory()
	_refresh_item_sheet()


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
	_title_label = get_node_or_null("Panel/Layout/MainColumn/Header/TitleLabel") as Label
	_location_label = get_node_or_null("Panel/Layout/MainColumn/Header/LocationLabel") as Label
	_time_label = get_node_or_null("Panel/Layout/MainColumn/Header/TimeLabel") as Label
	_summary_label = get_node_or_null("Panel/Layout/MainColumn/SummaryLabel") as Label
	_result_label = get_node_or_null("Panel/Layout/MainColumn/ResultLabel") as Label
	_action_buttons = get_node_or_null("Panel/Layout/MainColumn/ActionButtons") as VBoxContainer
	_minimap = get_node_or_null("Panel/Layout/Sidebar/MinimapPanel/VBox/MapNodes") as Control
	_inventory_title_label = get_node_or_null("Panel/Layout/Sidebar/InventoryPanel/VBox/TitleLabel") as Label
	_inventory_status_label = get_node_or_null("Panel/Layout/Sidebar/InventoryPanel/VBox/StatusLabel") as Label
	_inventory_items = get_node_or_null("Panel/Layout/Sidebar/InventoryPanel/VBox/InventoryItems") as VBoxContainer
	_item_sheet = get_node_or_null("ItemSheet") as Control
	_item_sheet_title = get_node_or_null("ItemSheet/VBox/ItemNameLabel") as Label
	_item_sheet_description = get_node_or_null("ItemSheet/VBox/ItemDescriptionLabel") as Label
	_item_sheet_effect = get_node_or_null("ItemSheet/VBox/ItemEffectLabel") as Label
	_item_sheet_actions = get_node_or_null("ItemSheet/VBox/ActionButtons") as HBoxContainer


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


func _refresh_minimap() -> void:
	if _minimap == null or _director == null or not _director.has_method("get_map_snapshot"):
		return

	if _minimap.has_method("set_snapshot"):
		_minimap.set_snapshot(_director.get_map_snapshot())


func _refresh_inventory() -> void:
	if _inventory_items == null:
		return

	_clear_children(_inventory_items)
	if _inventory_title_label != null:
		if _director != null and _director.has_method("get_inventory_title"):
			_inventory_title_label.text = String(_director.get_inventory_title())
		else:
			_inventory_title_label.text = "소지품"
	if _inventory_status_label != null:
		if _director != null and _director.has_method("get_inventory_status_text"):
			_inventory_status_label.text = String(_director.get_inventory_status_text())
		else:
			_inventory_status_label.text = ""

	if _director == null or not _director.has_method("get_inventory_rows"):
		return

	for row_variant in _director.get_inventory_rows():
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue

		var row := row_variant as Dictionary
		var label_text := String(row.get("label", ""))
		var action_id := String(row.get("action_id", ""))
		if action_id.is_empty():
			var label := Label.new()
			label.text = label_text
			_inventory_items.add_child(label)
			continue

		var item_button := Button.new()
		item_button.text = label_text
		item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item_button.pressed.connect(Callable(self, "_on_action_pressed").bind(action_id))
		_inventory_items.add_child(item_button)


func _refresh_item_sheet() -> void:
	if _item_sheet == null:
		return

	if _director == null or not _director.has_method("get_selected_inventory_sheet"):
		_item_sheet.visible = false
		return

	var sheet: Dictionary = _director.get_selected_inventory_sheet()
	if not bool(sheet.get("visible", false)):
		_item_sheet.visible = false
		return

	_item_sheet.visible = true
	if _item_sheet_title != null:
		_item_sheet_title.text = String(sheet.get("title", "아이템"))
	if _item_sheet_description != null:
		_item_sheet_description.text = String(sheet.get("description", ""))
	if _item_sheet_effect != null:
		_item_sheet_effect.text = String(sheet.get("effect_text", ""))

	if _item_sheet_actions != null:
		_clear_children(_item_sheet_actions)
		for action_variant in sheet.get("actions", []):
			if typeof(action_variant) != TYPE_DICTIONARY:
				continue

			var action := action_variant as Dictionary
			var action_id := String(action.get("id", ""))
			if action_id.is_empty():
				continue

			var button := Button.new()
			button.text = String(action.get("label", action_id))
			button.pressed.connect(Callable(self, "_on_action_pressed").bind(action_id))
			_item_sheet_actions.add_child(button)
