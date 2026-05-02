extends Control

const ItemIconResolver = preload("res://scripts/ui/item_icon_resolver.gd")
const UiKitResolver = preload("res://scripts/ui/ui_kit_resolver.gd")
const TEXT_PRIMARY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const TEXT_SECONDARY_COLOR := Color(0.94, 0.97, 1.0, 0.98)
const TEXT_EVENT_SUCCESS_COLOR := Color(0.82, 1.0, 0.9, 1.0)
const TEXT_EVENT_WARNING_COLOR := Color(1.0, 0.9, 0.72, 1.0)
const TEXT_OUTLINE_COLOR := Color(0.0, 0.02, 0.04, 1.0)
const ACTION_ICON_SIZE := 16

signal state_changed
signal exit_requested
signal toast_requested(toast_type: String, message: String, duration: float, icon_item_id: String)

const ACTION_SECTION_ORDER := ["interaction", "loot", "move", "locked"]
const ACTION_SECTION_TITLES := {
	"interaction": "여기서 할 일",
	"loot": "챙길 물건",
	"move": "다른 구역",
	"locked": "막힌 길",
}
const ACTION_ICON_PATHS := {
	"move": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/arrowRight.png",
	"interaction": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/question.png",
	"loot": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/basket.png",
	"locked": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/locked.png",
	"exit": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/home.png",
}

var _director: Node = null
var _run_state = null
var _title_label: Label = null
var _location_label: Label = null
var _location_caption_label: Label = null
var _location_value_label: Label = null
var _time_label: Label = null
var _gauge_row = null
var _inline_minimap: Control = null
var _event_illustration: TextureRect = null
var _summary_label: Label = null
var _zone_status_row: HBoxContainer = null
var _result_label: Label = null
var _action_buttons: VBoxContainer = null
var _map_button: Button = null
var _bag_button: Button = null
var _survival_sheet: CanvasLayer = null
var _minimap_overlay: Control = null
var _minimap_close_button: Button = null
var _minimap: Control = null
var _supply_picker_overlay: PanelContainer = null
var _supply_picker_title: Label = null
var _supply_picker_status: Label = null
var _supply_picker_quantity: Label = null
var _supply_picker_minus_button: Button = null
var _supply_picker_plus_button: Button = null
var _supply_picker_max_button: Button = null
var _supply_picker_cancel_button: Button = null
var _supply_picker_confirm_button: Button = null
var _director_connected := false
var _buttons_bound := false
var _icon_cache: Dictionary = {}
var _item_icon_resolver = ItemIconResolver.new()
var _ui_kit_resolver = UiKitResolver.new()
var _skin_applied := false
var _last_toast_feedback_message := ""
var _active_supply_picker: Dictionary = {"visible": false}


func configure(run_state, building_id: String = "mart_01") -> void:
	_run_state = run_state
	_last_toast_feedback_message = ""
	_cache_nodes()
	_bind_ui_buttons()
	_bind_director()
	if _survival_sheet != null and _survival_sheet.has_method("bind_run_state"):
		_survival_sheet.bind_run_state(run_state)
		_survival_sheet.set_mode_name("indoor")
	if _director != null and _director.has_method("configure"):
		_director.configure(run_state, building_id)


func _ready() -> void:
	_cache_nodes()
	_bind_ui_buttons()
	_bind_director()


func _bind_director() -> void:
	if _director == null or _director_connected or not _director.has_signal("state_changed"):
		return

	_director.state_changed.connect(Callable(self, "_on_director_state_changed"))
	_director_connected = true


func _bind_ui_buttons() -> void:
	if _buttons_bound:
		return

	if _map_button != null and not _map_button.pressed.is_connected(Callable(self, "_on_map_button_pressed")):
		_map_button.pressed.connect(Callable(self, "_on_map_button_pressed"))
	if _bag_button != null and not _bag_button.pressed.is_connected(Callable(self, "_on_bag_button_pressed")):
		_bag_button.pressed.connect(Callable(self, "_on_bag_button_pressed"))
	if _survival_sheet != null and _survival_sheet.has_signal("close_requested") and not _survival_sheet.close_requested.is_connected(Callable(self, "_on_survival_sheet_closed")):
		_survival_sheet.close_requested.connect(Callable(self, "_on_survival_sheet_closed"))
	if _survival_sheet != null and _survival_sheet.has_signal("inventory_action_requested") and not _survival_sheet.inventory_action_requested.is_connected(Callable(self, "_on_survival_sheet_action_requested")):
		_survival_sheet.inventory_action_requested.connect(Callable(self, "_on_survival_sheet_action_requested"))
	if _survival_sheet != null and _survival_sheet.has_signal("craft_applied") and not _survival_sheet.craft_applied.is_connected(Callable(self, "_on_survival_sheet_craft_applied")):
		_survival_sheet.craft_applied.connect(Callable(self, "_on_survival_sheet_craft_applied"))
	if _minimap_close_button != null and not _minimap_close_button.pressed.is_connected(Callable(self, "_on_minimap_close_pressed")):
		_minimap_close_button.pressed.connect(Callable(self, "_on_minimap_close_pressed"))
	if _supply_picker_minus_button != null and not _supply_picker_minus_button.pressed.is_connected(Callable(self, "_on_supply_picker_minus_pressed")):
		_supply_picker_minus_button.pressed.connect(Callable(self, "_on_supply_picker_minus_pressed"))
	if _supply_picker_plus_button != null and not _supply_picker_plus_button.pressed.is_connected(Callable(self, "_on_supply_picker_plus_pressed")):
		_supply_picker_plus_button.pressed.connect(Callable(self, "_on_supply_picker_plus_pressed"))
	if _supply_picker_max_button != null and not _supply_picker_max_button.pressed.is_connected(Callable(self, "_on_supply_picker_max_pressed")):
		_supply_picker_max_button.pressed.connect(Callable(self, "_on_supply_picker_max_pressed"))
	if _supply_picker_cancel_button != null and not _supply_picker_cancel_button.pressed.is_connected(Callable(self, "_on_supply_picker_cancel_pressed")):
		_supply_picker_cancel_button.pressed.connect(Callable(self, "_on_supply_picker_cancel_pressed"))
	if _supply_picker_confirm_button != null and not _supply_picker_confirm_button.pressed.is_connected(Callable(self, "_on_supply_picker_confirm_pressed")):
		_supply_picker_confirm_button.pressed.connect(Callable(self, "_on_supply_picker_confirm_pressed"))

	_buttons_bound = true


func _on_director_state_changed() -> void:
	_refresh_view()
	_emit_feedback_toast_if_needed("info")
	state_changed.emit()


func _refresh_view() -> void:
	if _director == null:
		return

	_refresh_top_bar()
	_refresh_reading_area()
	_push_inventory_payload_into_sheet()
	_refresh_action_buttons()
	_refresh_minimap()
	_refresh_supply_picker()


func refresh_view() -> void:
	_refresh_view()


func _refresh_top_bar() -> void:
	if _title_label != null and _director.has_method("get_event_title"):
		_title_label.text = _director.get_event_title()

	var zone_label := ""
	if _director.has_method("get_current_zone_label"):
		zone_label = String(_director.get_current_zone_label())
	if _location_value_label != null:
		_location_value_label.text = zone_label if not zone_label.is_empty() else "확인 중"
	if _location_label != null:
		_location_label.visible = false

	if _time_label != null:
		if _director.has_method("get_clock_label"):
			var clock_label := String(_director.get_clock_label())
			_time_label.text = "시각: %s" % (clock_label if not clock_label.is_empty() else "확인 중")
		else:
			_time_label.text = "시각: 확인 중"
	if _gauge_row != null and _gauge_row.has_method("set_run_state"):
		_gauge_row.set_run_state(_run_state)


func _refresh_reading_area() -> void:
	_refresh_event_illustration()

	if _summary_label != null and _director.has_method("get_current_zone_summary"):
		var summary := String(_director.get_current_zone_summary())
		_summary_label.text = summary if not summary.is_empty() else "방 안을 살펴 단서를 찾아본다."
	_refresh_zone_status_row()

	if _result_label != null and _director.has_method("get_feedback_message"):
		var feedback_message := String(_director.get_feedback_message())
		_result_label.visible = not feedback_message.is_empty()
		_result_label.text = _format_feedback_message(feedback_message)
		_apply_label_style(_result_label, 15, _feedback_message_color(feedback_message), 3)


func _refresh_zone_status_row() -> void:
	if _zone_status_row == null:
		return
	_clear_children(_zone_status_row)
	if _director == null or not _director.has_method("get_current_zone_status_rows"):
		_zone_status_row.visible = false
		return

	var status_rows: Array[String] = _director.get_current_zone_status_rows()
	_zone_status_row.visible = not status_rows.is_empty()
	for status_text in status_rows:
		if status_text.strip_edges().is_empty():
			continue
		_zone_status_row.add_child(_create_status_chip(status_text))
	_zone_status_row.queue_sort()


func _refresh_action_buttons() -> void:
	if _action_buttons == null:
		return

	_clear_children(_action_buttons)
	if _director == null or not _director.has_method("get_actions"):
		return

	var grouped_actions := _group_actions(_director.get_actions())
	for section_id in ACTION_SECTION_ORDER:
		var actions = grouped_actions.get(section_id, [])
		if actions.is_empty():
			continue

		var section_box := VBoxContainer.new()
		section_box.add_theme_constant_override("separation", 6)
		_action_buttons.add_child(section_box)

		var heading_panel := PanelContainer.new()
		_ui_kit_resolver.apply_panel(heading_panel, "indoor/indoor_section_header_plain_compact.png")
		section_box.add_child(heading_panel)

		var heading_padding := MarginContainer.new()
		heading_padding.add_theme_constant_override("margin_left", 12)
		heading_padding.add_theme_constant_override("margin_top", 6)
		heading_padding.add_theme_constant_override("margin_right", 12)
		heading_padding.add_theme_constant_override("margin_bottom", 6)
		heading_panel.add_child(heading_padding)

		var heading_row := HBoxContainer.new()
		heading_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heading_row.add_theme_constant_override("separation", 8)
		heading_padding.add_child(heading_row)

		var heading := Label.new()
		heading.text = String(ACTION_SECTION_TITLES.get(section_id, section_id))
		_apply_label_style(heading, 15, TEXT_PRIMARY_COLOR, 2)
		heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heading_row.add_child(heading)

		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heading_row.add_child(spacer)

		if section_id == "move":
			var exit_action: Dictionary = {}
			if _director != null and _director.has_method("get_exit_action"):
				exit_action = _director.get_exit_action()
			if not exit_action.is_empty():
				heading_row.add_child(_create_exit_shortcut_button(exit_action))

		for action in actions:
			var action_id := String(action.get("id", ""))
			if action_id.is_empty():
				continue
			if String(action.get("type", "")) == "exit":
				continue

			var button := _create_action_button(action as Dictionary, section_id)
			button.pressed.connect(Callable(self, "_on_action_pressed").bind(action_id))
			section_box.add_child(button)


func _group_actions(actions: Array[Dictionary]) -> Dictionary:
	var grouped := {
		"move": [],
		"interaction": [],
		"loot": [],
		"locked": [],
	}

	for action in actions:
		var action_id := String(action.get("id", ""))
		if action_id.is_empty():
			continue

		var section_id := _section_for_action(action)
		var bucket = grouped.get(section_id, [])
		bucket.append(action)
		grouped[section_id] = bucket

	return grouped


func _section_for_action(action: Dictionary) -> String:
	var action_type := String(action.get("type", ""))
	if bool(action.get("locked", false)) and action_type == "move":
		return "locked"
	if action_type == "take_loot" or action_type == "take_supply" or action_type == "take_supply_detail":
		return "loot"
	if action_type == "move" or action_type == "exit":
		return "move"
	return "interaction"


func _create_action_button(action: Dictionary, section_id: String) -> Button:
	var action_id := String(action.get("id", ""))
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(0, 66)
	button.focus_mode = Control.FOCUS_NONE
	button.set_meta("action_id", action_id)
	var style_paths := _action_style_paths(action, section_id)
	_ui_kit_resolver.apply_button(button, String(style_paths[0]), String(style_paths[1]))
	button.add_theme_constant_override("h_separation", 0)

	var padding := MarginContainer.new()
	padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	padding.add_theme_constant_override("margin_left", 12)
	padding.add_theme_constant_override("margin_top", 7)
	padding.add_theme_constant_override("margin_right", 12)
	padding.add_theme_constant_override("margin_bottom", 7)
	button.add_child(padding)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	padding.add_child(row)

	var icon_holder := CenterContainer.new()
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.custom_minimum_size = Vector2(26, 0)
	icon_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(icon_holder)

	var icon_slot := PanelContainer.new()
	icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_slot.custom_minimum_size = Vector2(24, 24)
	_ui_kit_resolver.apply_panel(icon_slot, "sheet/inventory_icon_slot.png")
	icon_holder.add_child(icon_slot)

	var icon_center := CenterContainer.new()
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_slot.add_child(icon_center)

	var icon_rect := TextureRect.new()
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.custom_minimum_size = Vector2(ACTION_ICON_SIZE, ACTION_ICON_SIZE)
	icon_rect.texture = _action_icon(action, section_id)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_center.add_child(icon_rect)

	var text_column := VBoxContainer.new()
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.add_theme_constant_override("separation", 2)
	row.add_child(text_column)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.text = String(action.get("label", action_id))
	_apply_label_style(label, 16, TEXT_PRIMARY_COLOR, 3)
	text_column.add_child(label)

	var detail_text := _action_detail_text(action, section_id)
	var detail_label := Label.new()
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail_label.text = detail_text
	_apply_label_style(detail_label, 13, _action_detail_color(action, section_id), 2)
	text_column.add_child(detail_label)

	var meta_column := VBoxContainer.new()
	meta_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_column.custom_minimum_size = Vector2(76, 0)
	meta_column.alignment = BoxContainer.ALIGNMENT_CENTER
	meta_column.add_theme_constant_override("separation", 3)
	row.add_child(meta_column)

	var chip := _create_action_chip(_action_chip_text(action, section_id), _action_chip_color(action, section_id))
	meta_column.add_child(chip)

	var time_text := _action_time_text(action)
	if not time_text.is_empty():
		var time_label := Label.new()
		time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_label.text = time_text
		_apply_label_style(time_label, 12, TEXT_SECONDARY_COLOR, 2)
		meta_column.add_child(time_label)

	button.tooltip_text = "%s\n%s" % [label.text, detail_text] if not detail_text.is_empty() else label.text
	return button


func _action_style_paths(action: Dictionary, section_id: String) -> Array[String]:
	if bool(action.get("locked", false)):
		return ["indoor/indoor_action_row_locked_idle.png", "indoor/indoor_action_row_locked_idle.png"]
	if _action_has_risk(action):
		return ["indoor/indoor_action_row_risk_idle.png", "indoor/indoor_action_row_risk_pressed.png"]
	if section_id == "loot":
		return ["indoor/indoor_action_row_loot_idle.png", "indoor/indoor_action_row_loot_pressed.png"]
	return ["indoor/indoor_action_row_compact_idle.png", "indoor/indoor_action_row_compact_pressed.png"]


func _action_detail_text(action: Dictionary, section_id: String) -> String:
	var explicit_detail := String(action.get("detail_label", ""))
	if not explicit_detail.is_empty():
		return explicit_detail
	if bool(action.get("locked", false)):
		var blocked := String(action.get("blocked_feedback", ""))
		return blocked if not blocked.is_empty() else "조건을 맞춰야 열린다"
	match section_id:
		"move":
			return "위치를 바꾸면 시간이 흐른다"
		"loot":
			return _loot_action_detail(action)
		"interaction":
			return "결과에 따라 다음 선택지가 열린다"
		_:
			return ""


func _loot_action_detail(action: Dictionary) -> String:
	var action_type := String(action.get("type", ""))
	if action_type == "take_supply_detail":
		var item_name := String(action.get("item_name", "물건"))
		var max_quantity := int(action.get("max_quantity", 0))
		if max_quantity > 0:
			return "%s · 최대 %d개까지 선택" % [item_name, max_quantity]
		return "%s · 지금은 챙길 수 없음" % item_name
	if action_type == "take_supply":
		var quantity_remaining := int(action.get("quantity_remaining", 0))
		return "남은 재고 %d개" % quantity_remaining if quantity_remaining > 0 else "재고 확인 필요"
	var loot_variant: Variant = action.get("loot", {})
	if typeof(loot_variant) == TYPE_DICTIONARY:
		var loot := loot_variant as Dictionary
		var loot_name := String(loot.get("name", loot.get("id", "물건")))
		return "%s · 가방 여유 확인" % loot_name
	return "가방 여유 확인"


func _action_detail_color(action: Dictionary, section_id: String) -> Color:
	if bool(action.get("locked", false)) or _action_has_risk(action):
		return TEXT_EVENT_WARNING_COLOR
	if section_id == "loot":
		return TEXT_EVENT_SUCCESS_COLOR
	return TEXT_SECONDARY_COLOR


func _action_time_text(action: Dictionary) -> String:
	var minutes := int(action.get("minute_cost", action.get("sleep_minutes", action.get("rest_minutes", 0))))
	return "%d분" % minutes if minutes > 0 else ""


func _action_chip_text(action: Dictionary, section_id: String) -> String:
	if bool(action.get("locked", false)):
		return "막힘"
	if _action_has_risk(action):
		return "위험"
	if section_id == "loot":
		return "획득"
	if String(action.get("type", "")) == "move":
		return "이동"
	if int(action.get("rest_minutes", 0)) > 0:
		return "회복"
	if int(action.get("sleep_minutes", 0)) > 0:
		return "수면"
	return "탐색"


func _action_chip_color(action: Dictionary, section_id: String) -> Color:
	if bool(action.get("locked", false)):
		return Color(0.18, 0.21, 0.24, 0.94)
	if _action_has_risk(action):
		return Color(0.58, 0.27, 0.16, 0.96)
	if section_id == "loot":
		return Color(0.16, 0.42, 0.34, 0.96)
	if String(action.get("type", "")) == "move":
		return Color(0.18, 0.36, 0.45, 0.96)
	return Color(0.24, 0.31, 0.39, 0.96)


func _create_action_chip(text: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(58, 19)
	panel.add_theme_stylebox_override("panel", _action_chip_style(color))

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = text
	_apply_label_style(label, 11, TEXT_PRIMARY_COLOR, 2)
	panel.add_child(label)
	return panel


func _create_status_chip(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _status_chip_style(text))

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_apply_label_style(label, 12, _status_chip_text_color(text), 2)
	panel.add_child(label)
	return panel


func _status_chip_style(text: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _status_chip_color(text)
	style.border_color = Color(0.78, 0.9, 0.96, 0.48)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style


func _status_chip_color(text: String) -> Color:
	if text.find("소란") >= 0:
		return Color(0.52, 0.25, 0.16, 0.96)
	if text.find("수색 완료") >= 0:
		return Color(0.14, 0.35, 0.32, 0.96)
	if text.find("남아 있는 물건") >= 0:
		return Color(0.15, 0.30, 0.40, 0.96)
	return Color(0.18, 0.24, 0.30, 0.96)


func _status_chip_text_color(text: String) -> Color:
	return TEXT_EVENT_WARNING_COLOR if text.find("소란") >= 0 else TEXT_SECONDARY_COLOR


func _action_chip_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.72, 0.86, 0.92, 0.52)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _action_has_risk(action: Dictionary) -> bool:
	var pressure: Dictionary = {}
	var pressure_variant: Variant = action.get("pressure", {})
	if typeof(pressure_variant) == TYPE_DICTIONARY:
		pressure = pressure_variant as Dictionary
	var noise := int(action.get("noise_cost", 0)) + int(pressure.get("noise", 0))
	if noise > 0:
		return true
	for key in ["health_loss", "exposure_loss", "fatigue_gain"]:
		if float(pressure.get(key, 0.0)) > 0.0:
			return true
	return false


func _create_exit_shortcut_button(exit_action: Dictionary) -> Button:
	var button := Button.new()
	button.name = "ExitShortcutButton"
	button.text = _compact_exit_button_label(exit_action)
	button.tooltip_text = String(exit_action.get("label", "건물 밖으로 나간다"))
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(108, 32)
	button.icon = _load_icon(String(ACTION_ICON_PATHS.get("exit", "")))
	button.expand_icon = false
	button.add_theme_constant_override("h_separation", 6)
	_ui_kit_resolver.apply_button(
		button,
		"sheet/sheet_button_secondary_normal.png",
		"sheet/sheet_button_secondary_pressed.png"
	)
	_apply_button_text_style(button, 13, TEXT_PRIMARY_COLOR, 2)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.pressed.connect(Callable(self, "_on_exit_button_pressed"))
	return button


func _compact_exit_button_label(exit_action: Dictionary) -> String:
	var minutes := int(exit_action.get("minute_cost", 0))
	if minutes > 0:
		return "나가기 (%d분)" % minutes
	return "나가기"


func _action_icon(action: Dictionary, section_id: String) -> Texture2D:
	var action_type := String(action.get("type", ""))
	if action_type == "take_loot":
		var loot_variant: Variant = action.get("loot", {})
		if typeof(loot_variant) == TYPE_DICTIONARY:
			var loot := loot_variant as Dictionary
			var loot_id := String(loot.get("id", ""))
			var item_icon := _item_icon_resolver.get_item_icon(loot_id)
			if item_icon != null:
				return item_icon
	if action_type == "take_supply" or action_type == "take_supply_detail":
		var supply_item_id := String(action.get("item_id", ""))
		var supply_icon := _item_icon_resolver.get_item_icon(supply_item_id)
		if supply_icon != null:
			return supply_icon
	if action_type == "exit":
		return _load_icon(String(ACTION_ICON_PATHS.get("exit", "")))
	return _load_icon(String(ACTION_ICON_PATHS.get(section_id, "")))


func _load_icon(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _icon_cache.has(path):
		return _icon_cache[path] as Texture2D

	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return null

	var image := Image.new()
	var err := image.load(absolute_path)
	if err != OK:
		return null
	if image.get_width() != ACTION_ICON_SIZE or image.get_height() != ACTION_ICON_SIZE:
		image.resize(ACTION_ICON_SIZE, ACTION_ICON_SIZE, Image.INTERPOLATE_LANCZOS)

	var texture := ImageTexture.create_from_image(image)
	_icon_cache[path] = texture
	return texture


func _refresh_minimap() -> void:
	if _director == null or not _director.has_method("get_map_snapshot"):
		return

	var snapshot: Dictionary = _director.get_map_snapshot()
	if _inline_minimap != null and _inline_minimap.has_method("set_snapshot"):
		_inline_minimap.set_snapshot(snapshot)
	if _minimap != null and _minimap.has_method("set_snapshot"):
		_minimap.set_snapshot(snapshot)


func _refresh_event_illustration() -> void:
	if _event_illustration == null:
		return

	var asset_path := "indoor/indoor_event_convenience_frozen.png"
	if _director != null and _director.has_method("get_event_illustration_asset"):
		var candidate := String(_director.get_event_illustration_asset())
		if not candidate.is_empty():
			asset_path = candidate

	var texture := _ui_kit_resolver.get_texture(asset_path)
	if texture == null:
		texture = _ui_kit_resolver.get_texture("indoor/indoor_event_convenience_frozen.png")
	_event_illustration.texture = texture
	_event_illustration.visible = texture != null


func _on_map_button_pressed() -> void:
	if _minimap_overlay == null:
		return
	_minimap_overlay.visible = not _minimap_overlay.visible
	if _minimap_overlay.visible:
		_close_bag_sheet()


func _on_bag_button_pressed() -> void:
	if _survival_sheet == null or not _survival_sheet.has_method("open_inventory"):
		return
	if _survival_sheet.visible:
		_survival_sheet.close_sheet()
		return
	if _minimap_overlay != null:
		_minimap_overlay.visible = false
	_survival_sheet.open_inventory()
	_push_inventory_payload_into_sheet()


func _on_exit_button_pressed() -> void:
	_request_exit()


func _request_exit() -> void:
	if _director == null or not _director.has_method("get_exit_action"):
		return
	var exit_action: Dictionary = _director.get_exit_action()
	if exit_action.is_empty():
		return
	if _director.has_method("apply_action"):
		_director.apply_action("exit_building")
	exit_requested.emit()


func _on_minimap_close_pressed() -> void:
	if _minimap_overlay != null:
		_minimap_overlay.visible = false


func _close_bag_sheet() -> void:
	if _survival_sheet != null and _survival_sheet.visible and _survival_sheet.has_method("close_sheet"):
		_survival_sheet.close_sheet()


func _on_action_pressed(action_id: String) -> void:
	if action_id.begins_with("take_supply_") and action_id.ends_with("_detail"):
		_open_supply_picker(action_id)
		return
	if action_id == "exit_building":
		if _director != null and _director.has_method("apply_action"):
			_director.apply_action(action_id)
		exit_requested.emit()
		return

	if _director != null and _director.has_method("apply_action"):
		_director.apply_action(action_id)


func _cache_nodes() -> void:
	_director = get_node_or_null("Director")
	_title_label = get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/TitleLabel") as Label
	_location_label = get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/LocationLabel") as Label
	_location_caption_label = get_node_or_null("Panel/Layout/MainColumn/LocationStrip/Padding/HBox/LocationCaptionLabel") as Label
	_location_value_label = get_node_or_null("Panel/Layout/MainColumn/LocationStrip/Padding/HBox/LocationValueLabel") as Label
	_time_label = get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/TimeLabel") as Label
	_gauge_row = get_node_or_null("Panel/Layout/MainColumn/TopBar/GaugeRow")
	_inline_minimap = get_node_or_null("Panel/Layout/MainColumn/MiniMapCard/Padding/MapNodes") as Control
	_event_illustration = get_node_or_null("Panel/Layout/MainColumn/ReadingCard/Padding/VBox/EventIllustration") as TextureRect
	_summary_label = get_node_or_null("Panel/Layout/MainColumn/ReadingCard/Padding/VBox/SummaryLabel") as Label
	_zone_status_row = get_node_or_null("Panel/Layout/MainColumn/ReadingCard/Padding/VBox/ZoneStatusRow") as HBoxContainer
	_result_label = get_node_or_null("Panel/Layout/MainColumn/ReadingCard/Padding/VBox/ResultLabel") as Label
	_action_buttons = get_node_or_null("Panel/Layout/MainColumn/ActionScroll/ActionButtons") as VBoxContainer
	_map_button = get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/MapButton") as Button
	_bag_button = get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/BagButton") as Button
	_survival_sheet = get_node_or_null("SurvivalSheet") as CanvasLayer
	_minimap_overlay = get_node_or_null("MinimapOverlay") as Control
	_minimap_close_button = get_node_or_null("MinimapOverlay/Padding/VBox/Header/CloseButton") as Button
	_minimap = get_node_or_null("MinimapOverlay/Padding/VBox/MapNodes") as Control
	_supply_picker_overlay = get_node_or_null("SupplyPickerOverlay") as PanelContainer
	_supply_picker_title = get_node_or_null("SupplyPickerOverlay/Padding/VBox/TitleLabel") as Label
	_supply_picker_status = get_node_or_null("SupplyPickerOverlay/Padding/VBox/StatusLabel") as Label
	_supply_picker_quantity = get_node_or_null("SupplyPickerOverlay/Padding/VBox/QuantityRow/QuantityValueLabel") as Label
	_supply_picker_minus_button = get_node_or_null("SupplyPickerOverlay/Padding/VBox/QuantityRow/MinusButton") as Button
	_supply_picker_plus_button = get_node_or_null("SupplyPickerOverlay/Padding/VBox/QuantityRow/PlusButton") as Button
	_supply_picker_max_button = get_node_or_null("SupplyPickerOverlay/Padding/VBox/QuantityRow/MaxButton") as Button
	_supply_picker_cancel_button = get_node_or_null("SupplyPickerOverlay/Padding/VBox/ButtonRow/CancelButton") as Button
	_supply_picker_confirm_button = get_node_or_null("SupplyPickerOverlay/Padding/VBox/ButtonRow/ConfirmButton") as Button
	_apply_ui_skin()


func _apply_ui_skin() -> void:
	if _skin_applied:
		return
	_skin_applied = true

	var panel := get_node_or_null("Panel") as PanelContainer
	var location_strip := get_node_or_null("Panel/Layout/MainColumn/LocationStrip") as PanelContainer
	var reading_card := get_node_or_null("Panel/Layout/MainColumn/ReadingCard") as PanelContainer
	var minimap_card := get_node_or_null("Panel/Layout/MainColumn/MiniMapCard") as PanelContainer
	var minimap_panel := get_node_or_null("MinimapOverlay") as PanelContainer

	_ui_kit_resolver.apply_panel(panel, "overlay/overlay_map_panel_clean.png")
	_ui_kit_resolver.apply_panel(location_strip, "indoor/indoor_location_strip_compact.png")
	_ui_kit_resolver.apply_panel(reading_card, "indoor/indoor_reading_panel_plain.png")
	_ui_kit_resolver.apply_panel(minimap_card, "indoor/indoor_minimap_frame.png")
	_ui_kit_resolver.apply_panel(minimap_panel, "structure/structure_panel_bg.png")
	_ui_kit_resolver.apply_panel(_supply_picker_overlay, "indoor/indoor_reading_panel_plain.png")
	if _event_illustration != null:
		_event_illustration.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_refresh_event_illustration()
	_ui_kit_resolver.apply_button(
		_map_button,
		"hud/hud_icon_button_compact_normal.png",
		"hud/hud_icon_button_compact_pressed.png",
		"hud/hud_icon_button_compact_normal.png",
		"hud/hud_icon_button_compact_disabled.png"
	)
	_ui_kit_resolver.apply_button(
		_bag_button,
		"hud/hud_icon_button_compact_normal.png",
		"hud/hud_icon_button_compact_pressed.png",
		"hud/hud_icon_button_compact_normal.png",
		"hud/hud_icon_button_compact_disabled.png"
	)
	_ui_kit_resolver.apply_button(
		_supply_picker_minus_button,
		"sheet/sheet_button_secondary_normal.png",
		"sheet/sheet_button_secondary_pressed.png"
	)
	_ui_kit_resolver.apply_button(
		_supply_picker_plus_button,
		"sheet/sheet_button_secondary_normal.png",
		"sheet/sheet_button_secondary_pressed.png"
	)
	_ui_kit_resolver.apply_button(
		_supply_picker_max_button,
		"sheet/sheet_button_secondary_normal.png",
		"sheet/sheet_button_secondary_pressed.png"
	)
	_ui_kit_resolver.apply_button(
		_supply_picker_cancel_button,
		"sheet/sheet_button_secondary_normal.png",
		"sheet/sheet_button_secondary_pressed.png"
	)
	_ui_kit_resolver.apply_button(
		_supply_picker_confirm_button,
		"sheet/sheet_button_secondary_normal.png",
		"sheet/sheet_button_secondary_pressed.png"
	)
	if _title_label != null:
		_apply_label_style(_title_label, 15, TEXT_PRIMARY_COLOR, 3)
	if _time_label != null:
		_apply_label_style(_time_label, 15, TEXT_SECONDARY_COLOR, 3)
	if _location_caption_label != null:
		_apply_label_style(_location_caption_label, 14, TEXT_SECONDARY_COLOR, 2)
	if _location_value_label != null:
		_apply_label_style(_location_value_label, 17, TEXT_PRIMARY_COLOR, 3)
	if _summary_label != null:
		_apply_label_style(_summary_label, 16, TEXT_PRIMARY_COLOR, 3)
	if _result_label != null:
		_apply_label_style(_result_label, 15, TEXT_SECONDARY_COLOR, 3)
	if _supply_picker_title != null:
		_apply_label_style(_supply_picker_title, 16, TEXT_PRIMARY_COLOR, 2)
	if _supply_picker_status != null:
		_apply_label_style(_supply_picker_status, 13, TEXT_SECONDARY_COLOR, 1)
	if _supply_picker_quantity != null:
		_apply_label_style(_supply_picker_quantity, 18, TEXT_PRIMARY_COLOR, 2)
	if _map_button != null:
		_map_button.text = ""
		_map_button.tooltip_text = "구조도"
		_map_button.custom_minimum_size = Vector2(36, 36)
		_map_button.icon = _ui_kit_resolver.get_texture("icons/light_24/structure.png")
		_map_button.expand_icon = false
		_map_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _bag_button != null:
		_bag_button.text = ""
		_bag_button.tooltip_text = "가방"
		_bag_button.custom_minimum_size = Vector2(36, 36)
		_bag_button.icon = _ui_kit_resolver.get_texture("icons/light_24/bag.png")
		_bag_button.expand_icon = false
		_bag_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_refresh_supply_picker()


func _push_inventory_payload_into_sheet() -> void:
	if _survival_sheet == null or _director == null or not _survival_sheet.has_method("set_inventory_payload"):
		return

	var payload := {
		"title": _director.get_inventory_title() if _director.has_method("get_inventory_title") else "가방",
		"status_text": _director.get_inventory_status_text() if _director.has_method("get_inventory_status_text") else "",
		"rows": _director.get_inventory_rows() if _director.has_method("get_inventory_rows") else [],
		"selected_sheet": _director.get_selected_inventory_sheet() if _director.has_method("get_selected_inventory_sheet") else {"visible": false},
		"feedback_message": _director.get_feedback_message() if _director.has_method("get_feedback_message") else "",
	}
	_survival_sheet.set_inventory_payload(payload)


func _on_survival_sheet_closed() -> void:
	if _director != null and _director.has_method("apply_action"):
		_director.apply_action("close_inventory_sheet")


func _on_survival_sheet_action_requested(action_id: String) -> void:
	if _director == null or not _director.has_method("apply_action"):
		return
	_director.apply_action(action_id)
	_push_inventory_payload_into_sheet()


func _on_survival_sheet_craft_applied(outcome: Dictionary) -> void:
	var feedback := _formatted_craft_feedback(outcome)
	if _director != null and _director.has_method("set_feedback_message"):
		_director.set_feedback_message(feedback)
	elif _result_label != null:
		_result_label.text = feedback
	_emit_feedback_toast(feedback, _craft_toast_type(outcome), 2.0, _craft_toast_icon_item_id(outcome))
	_last_toast_feedback_message = feedback
	_push_inventory_payload_into_sheet()
	_refresh_reading_area()


func _formatted_craft_feedback(outcome: Dictionary) -> String:
	var lines: Array[String] = []
	var result_item_data: Dictionary = outcome.get("result_item_data", {})
	var result_item_name := String(result_item_data.get("name", outcome.get("result_item_id", "")))
	if not result_item_name.is_empty():
		lines.append(result_item_name)
	var result_text := String(outcome.get("result_text", ""))
	if not result_text.is_empty():
		lines.append(result_text)
	var minutes_elapsed := int(outcome.get("minutes_elapsed", 0))
	if minutes_elapsed > 0:
		lines.append("%d분이 지났다." % minutes_elapsed)
	return "\n".join(lines)


func _format_feedback_message(message: String) -> String:
	if message.is_empty():
		return ""
	var tone := _feedback_message_tone(message)
	return "%s · %s" % [tone, message]


func _feedback_message_color(message: String) -> Color:
	var tone := _feedback_message_tone(message)
	if tone == "위험":
		return TEXT_EVENT_WARNING_COLOR
	if tone == "획득":
		return TEXT_EVENT_SUCCESS_COLOR
	return TEXT_SECONDARY_COLOR


func _feedback_message_tone(message: String) -> String:
	if message.find("챙겼다") >= 0 or message.find("먹었다") >= 0 or message.find("고농축 땔감") >= 0:
		return "획득"
	if message.find("발견") >= 0 or message.find("확인") >= 0:
		return "단서"
	for keyword in ["소란", "못했다", "다쳤", "긁", "한기", "잠겨", "위험"]:
		if message.find(keyword) >= 0:
			return "위험"
	return "상황"


func _emit_feedback_toast(message: String, toast_type: String = "info", duration: float = 2.0, icon_item_id: String = "") -> void:
	if message.is_empty():
		return
	toast_requested.emit(toast_type, message, duration, icon_item_id)


func _craft_toast_type(outcome: Dictionary) -> String:
	match String(outcome.get("result_type", "invalid")):
		"success":
			return "success"
		"failure", "invalid":
			return "warning"
		_:
			return "info"


func _craft_toast_icon_item_id(outcome: Dictionary) -> String:
	return String(outcome.get("result_item_id", "")) if _craft_toast_type(outcome) == "success" else ""


func _emit_feedback_toast_if_needed(toast_type: String = "info", duration: float = 2.0) -> void:
	if _director == null or not _director.has_method("get_feedback_message"):
		return
	var message := String(_director.get_feedback_message())
	if message.is_empty() or message == _last_toast_feedback_message:
		return
	_last_toast_feedback_message = message
	_emit_feedback_toast(message, toast_type, duration, "")


func _open_supply_picker(action_id: String) -> void:
	if _director == null or not _director.has_method("get_supply_picker_payload"):
		return
	_active_supply_picker = _director.get_supply_picker_payload(action_id)
	if not bool(_active_supply_picker.get("visible", false)):
		return
	_refresh_supply_picker()


func _close_supply_picker() -> void:
	_active_supply_picker = {"visible": false}
	_refresh_supply_picker()


func _refresh_supply_picker() -> void:
	if _supply_picker_overlay == null:
		return
	var is_visible := bool(_active_supply_picker.get("visible", false))
	_supply_picker_overlay.visible = is_visible
	if not is_visible:
		return
	var item_name := String(_active_supply_picker.get("item_name", "물건"))
	var item_id := String(_active_supply_picker.get("item_id", ""))
	var remaining := int(_active_supply_picker.get("quantity_remaining", 0))
	var max_quantity: int = max(0, int(_active_supply_picker.get("max_quantity", 0)))
	var selected_quantity: int = clampi(int(_active_supply_picker.get("selected_quantity", 1)), 1, max(1, max_quantity))
	_active_supply_picker["selected_quantity"] = selected_quantity
	if _supply_picker_title != null:
		_supply_picker_title.text = "%s 수량 선택" % item_name
	if _supply_picker_status != null:
		_supply_picker_status.text = _supply_picker_status_text(item_id, remaining, max_quantity, selected_quantity)
	if _supply_picker_quantity != null:
		_supply_picker_quantity.text = str(selected_quantity)
	if _supply_picker_minus_button != null:
		_supply_picker_minus_button.disabled = selected_quantity <= 1
	if _supply_picker_plus_button != null:
		_supply_picker_plus_button.disabled = selected_quantity >= max_quantity
	if _supply_picker_max_button != null:
		_supply_picker_max_button.disabled = selected_quantity >= max_quantity or max_quantity <= 0
	if _supply_picker_confirm_button != null:
		_supply_picker_confirm_button.disabled = max_quantity <= 0
		_supply_picker_confirm_button.text = "%d개 챙긴다" % selected_quantity if max_quantity > 0 else "챙길 수 없음"


func _supply_picker_status_text(item_id: String, remaining: int, max_quantity: int, selected_quantity: int) -> String:
	var parts: Array[String] = [
		"남은 재고 %d개" % remaining,
		"지금 최대 %d개" % max_quantity,
	]
	var item_weight := _supply_item_weight(item_id)
	if item_weight > 0.0 and selected_quantity > 0:
		parts.append("이번 무게 +%.1fkg" % (item_weight * float(selected_quantity)))
	return " · ".join(parts)


func _supply_item_weight(item_id: String) -> float:
	if item_id.is_empty() or ContentLibrary == null:
		return 0.0
	var item_data: Dictionary = ContentLibrary.get_item(item_id)
	return float(item_data.get("carry_weight", item_data.get("bulk", 0.0)))


func _on_supply_picker_minus_pressed() -> void:
	if not bool(_active_supply_picker.get("visible", false)):
		return
	_active_supply_picker["selected_quantity"] = max(1, int(_active_supply_picker.get("selected_quantity", 1)) - 1)
	_refresh_supply_picker()


func _on_supply_picker_plus_pressed() -> void:
	if not bool(_active_supply_picker.get("visible", false)):
		return
	var max_quantity: int = max(1, int(_active_supply_picker.get("max_quantity", 1)))
	_active_supply_picker["selected_quantity"] = min(max_quantity, int(_active_supply_picker.get("selected_quantity", 1)) + 1)
	_refresh_supply_picker()


func _on_supply_picker_max_pressed() -> void:
	if not bool(_active_supply_picker.get("visible", false)):
		return
	_active_supply_picker["selected_quantity"] = max(1, int(_active_supply_picker.get("max_quantity", 1)))
	_refresh_supply_picker()


func _on_supply_picker_cancel_pressed() -> void:
	_close_supply_picker()


func _on_supply_picker_confirm_pressed() -> void:
	if not bool(_active_supply_picker.get("visible", false)):
		return
	if _director == null or not _director.has_method("apply_supply_pickup"):
		return
	var zone_id := String(_active_supply_picker.get("zone_id", ""))
	var source_id := String(_active_supply_picker.get("source_id", ""))
	var quantity := int(_active_supply_picker.get("selected_quantity", 0))
	if zone_id.is_empty() or source_id.is_empty() or quantity <= 0:
		return
	if _director.apply_supply_pickup(zone_id, source_id, quantity):
		_close_supply_picker()


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _apply_label_style(label: Label, font_size: int, font_color: Color, outline_size: int = 1) -> void:
	if label == null:
		return
	label.modulate = font_color
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", TEXT_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", outline_size)


func _apply_button_text_style(button: Button, font_size: int, font_color: Color, outline_size: int = 1) -> void:
	if button == null:
		return
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(font_color.r, font_color.g, font_color.b, 0.55))
	button.add_theme_color_override("font_outline_color", TEXT_OUTLINE_COLOR)
	button.add_theme_constant_override("outline_size", outline_size)
