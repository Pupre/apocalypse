extends Control

signal state_changed
signal exit_requested
signal craft_requested

const ACTION_SECTION_ORDER := ["move", "interaction", "loot", "locked"]
const ACTION_SECTION_TITLES := {
	"move": "이동",
	"interaction": "탐색 / 상호작용",
	"loot": "발견한 물건",
	"locked": "잠긴 길",
}
const ACTION_ICON_PATHS := {
	"move": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/arrowRight.png",
	"interaction": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/question.png",
	"loot": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/basket.png",
	"locked": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/locked.png",
	"exit": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/home.png",
}

var _director: Node = null
var _title_label: Label = null
var _location_label: Label = null
var _location_value_label: Label = null
var _time_label: Label = null
var _stat_chips: HBoxContainer = null
var _inline_minimap: Control = null
var _summary_label: Label = null
var _result_label: Label = null
var _action_buttons: VBoxContainer = null
var _map_button: Button = null
var _bag_button: Button = null
var _craft_button: Button = null
var _minimap_overlay: Control = null
var _minimap_close_button: Button = null
var _minimap: Control = null
var _bag_sheet: Control = null
var _bag_title_label: Label = null
var _bag_status_label: Label = null
var _bag_close_button: Button = null
var _carried_tab_button: Button = null
var _equipped_tab_button: Button = null
var _inventory_column: Control = null
var _inventory_items: VBoxContainer = null
var _item_sheet: Control = null
var _item_sheet_title: Label = null
var _item_sheet_description: Label = null
var _item_sheet_effect: Label = null
var _item_sheet_actions: HBoxContainer = null
var _stat_detail_sheet: Control = null
var _stat_detail_title: Label = null
var _stat_detail_value: Label = null
var _stat_detail_rule: Label = null
var _stat_detail_recovery: Label = null
var _stat_detail_close_button: Button = null
var _selected_chip_id := ""
var _director_connected := false
var _buttons_bound := false
var _icon_cache: Dictionary = {}
var _active_bag_tab := "carried"


func configure(run_state, building_id: String = "mart_01") -> void:
	_cache_nodes()
	_bind_ui_buttons()
	_bind_director()
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
	if _craft_button != null and not _craft_button.pressed.is_connected(Callable(self, "_on_craft_button_pressed")):
		_craft_button.pressed.connect(Callable(self, "_on_craft_button_pressed"))
	if _minimap_close_button != null and not _minimap_close_button.pressed.is_connected(Callable(self, "_on_minimap_close_pressed")):
		_minimap_close_button.pressed.connect(Callable(self, "_on_minimap_close_pressed"))
	if _bag_close_button != null and not _bag_close_button.pressed.is_connected(Callable(self, "_on_bag_close_pressed")):
		_bag_close_button.pressed.connect(Callable(self, "_on_bag_close_pressed"))
	if _carried_tab_button != null and not _carried_tab_button.pressed.is_connected(Callable(self, "_on_carried_tab_pressed")):
		_carried_tab_button.pressed.connect(Callable(self, "_on_carried_tab_pressed"))
	if _equipped_tab_button != null and not _equipped_tab_button.pressed.is_connected(Callable(self, "_on_equipped_tab_pressed")):
		_equipped_tab_button.pressed.connect(Callable(self, "_on_equipped_tab_pressed"))
	if _stat_detail_close_button != null and not _stat_detail_close_button.pressed.is_connected(Callable(self, "_on_stat_detail_close_pressed")):
		_stat_detail_close_button.pressed.connect(Callable(self, "_on_stat_detail_close_pressed"))

	_buttons_bound = true


func _on_director_state_changed() -> void:
	_refresh_view()
	state_changed.emit()


func _refresh_view() -> void:
	if _director == null:
		return

	_refresh_top_bar()
	_refresh_reading_area()
	_refresh_action_buttons()
	_refresh_minimap()
	_refresh_bag_sheet()
	_refresh_item_sheet()
	_refresh_stat_detail_sheet()


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

	_refresh_stat_chips()


func _refresh_stat_chips() -> void:
	if _stat_chips == null:
		return

	_clear_children(_stat_chips)
	if _director == null or not _director.has_method("get_survival_chip_rows"):
		return

	for chip_variant in _director.get_survival_chip_rows():
		if typeof(chip_variant) != TYPE_DICTIONARY:
			continue

		var chip := chip_variant as Dictionary
		var chip_id := String(chip.get("id", ""))
		var button := Button.new()
		button.flat = false
		button.toggle_mode = false
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.name = chip_id
		button.icon = _load_icon(_survival_chip_icon_path(String(chip.get("icon_id", ""))))
		button.text = String(chip.get("display_value_text", chip.get("stage", "")))
		button.tooltip_text = "%s: %s" % [String(chip.get("label", "")), String(chip.get("stage", ""))]
		button.pressed.connect(Callable(self, "_on_stat_chip_pressed").bind(chip_id))
		_stat_chips.add_child(button)


func _refresh_reading_area() -> void:
	if _summary_label != null and _director.has_method("get_current_zone_summary"):
		var summary := String(_director.get_current_zone_summary())
		var summary_lines: Array[String] = []
		summary_lines.append(summary if not summary.is_empty() else "방 안을 살펴 단서를 찾아본다.")
		if _director.has_method("get_current_zone_status_rows"):
			var status_rows: Array[String] = _director.get_current_zone_status_rows()
			if not status_rows.is_empty():
				summary_lines.append("")
				for row in status_rows:
					summary_lines.append(row)
		_summary_label.text = "\n".join(summary_lines)

	if _result_label != null and _director.has_method("get_feedback_message"):
		_result_label.text = String(_director.get_feedback_message())


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

		var section_panel := PanelContainer.new()
		_action_buttons.add_child(section_panel)

		var section_box := VBoxContainer.new()
		section_box.add_theme_constant_override("separation", 6)
		section_panel.add_child(section_box)

		var heading := Label.new()
		heading.text = String(ACTION_SECTION_TITLES.get(section_id, section_id))
		heading.modulate = Color(0.88, 0.88, 0.88, 0.95)
		section_box.add_child(heading)

		for action in actions:
			var action_id := String(action.get("id", ""))
			if action_id.is_empty():
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
	if action_type == "take_loot":
		return "loot"
	if action_type == "move" or action_type == "exit":
		return "move"
	return "interaction"


func _create_action_button(action: Dictionary, section_id: String) -> Button:
	var action_id := String(action.get("id", ""))
	var button := Button.new()
	button.text = String(action.get("label", action_id))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 46)
	button.icon = _action_icon(action, section_id)
	button.expand_icon = true

	match section_id:
		"loot":
			button.modulate = Color(0.92, 1.0, 0.92, 1.0)
		"locked":
			button.modulate = Color(0.72, 0.72, 0.72, 0.96)
		"move":
			button.modulate = Color(0.92, 0.96, 1.0, 1.0)
		_:
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)

	return button


func _action_icon(action: Dictionary, section_id: String) -> Texture2D:
	var action_type := String(action.get("type", ""))
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

	var texture := ImageTexture.create_from_image(image)
	_icon_cache[path] = texture
	return texture


func _survival_chip_icon_path(chip_id: String) -> String:
	if _director != null and _director.has_method("get_survival_chip_icon_path"):
		return String(_director.get_survival_chip_icon_path(chip_id))
	return ""


func _refresh_minimap() -> void:
	if _director == null or not _director.has_method("get_map_snapshot"):
		return

	var snapshot: Dictionary = _director.get_map_snapshot()
	if _inline_minimap != null and _inline_minimap.has_method("set_snapshot"):
		_inline_minimap.set_snapshot(snapshot)
	if _minimap != null and _minimap.has_method("set_snapshot"):
		_minimap.set_snapshot(snapshot)


func _refresh_bag_sheet() -> void:
	if _bag_title_label != null:
		if _director != null and _director.has_method("get_inventory_title"):
			_bag_title_label.text = String(_director.get_inventory_title())
		else:
			_bag_title_label.text = "가방"

	if _bag_status_label != null:
		if _director != null and _director.has_method("get_inventory_status_text"):
			_bag_status_label.text = String(_director.get_inventory_status_text())
		else:
			_bag_status_label.text = ""

	if _carried_tab_button != null:
		_carried_tab_button.button_pressed = _active_bag_tab == "carried"
		_apply_tab_visual_state(_carried_tab_button, _active_bag_tab == "carried")
	if _equipped_tab_button != null:
		_equipped_tab_button.button_pressed = _active_bag_tab == "equipped"
		_apply_tab_visual_state(_equipped_tab_button, _active_bag_tab == "equipped")

	if _inventory_items == null:
		return

	_clear_children(_inventory_items)
	if _director == null:
		return

	if _active_bag_tab == "equipped":
		if _director.has_method("get_equipped_rows"):
			var equipped_count := 0
			for row_variant in _director.get_equipped_rows():
				if typeof(row_variant) != TYPE_DICTIONARY:
					continue
				equipped_count += 1
				_inventory_items.add_child(_create_equipped_row(row_variant as Dictionary))
			if equipped_count == 0:
				_inventory_items.add_child(
					_create_empty_state_row("EquippedEmptyRow", "EmptyLabel", "장착중인 장비 없음")
				)
		return

	if not _director.has_method("get_inventory_rows"):
		return

	for row_variant in _director.get_inventory_rows():
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue

		_inventory_items.add_child(_create_inventory_row(row_variant as Dictionary))


func _create_inventory_row(row: Dictionary) -> Control:
	var label_text := String(row.get("label", ""))
	var action_id := String(row.get("action_id", ""))
	if action_id.is_empty():
		return _create_empty_state_row("InventoryEmptyRow", "EmptyLabel", label_text)

	var row_panel := _create_row_panel("InventoryRow_%s" % action_id, _row_panel_style(Color(0.086, 0.102, 0.129, 0.98), Color(0.22, 0.29, 0.38, 1.0)))
	var row_box := _create_row_box()
	row_panel.add_child(row_box)

	var item_button := Button.new()
	item_button.name = "RowButton"
	item_button.text = label_text
	item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	item_button.custom_minimum_size = Vector2(0, 40)
	item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_button.expand_icon = true
	item_button.icon = _load_icon(String(ACTION_ICON_PATHS.get("move", "")))
	item_button.pressed.connect(Callable(self, "_on_action_pressed").bind(action_id))
	row_box.add_child(item_button)

	var hint_label := Label.new()
	hint_label.name = "DetailLabel"
	hint_label.text = String(row.get("detail_text", ""))
	hint_label.modulate = Color(0.82, 0.86, 0.9, 0.96)
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.visible = not hint_label.text.is_empty()
	row_box.add_child(hint_label)
	return row_panel


func _create_equipped_row(row: Dictionary) -> Control:
	if String(row.get("kind", "")) == "empty":
		return _create_empty_state_row(
			"EquippedEmptyRow",
			"EmptyLabel",
			String(row.get("summary_text", String(row.get("state_text", ""))))
		)

	var summary_text := String(row.get("summary_text", ""))
	if summary_text.is_empty():
		return _create_empty_state_row("EquippedEmptyRow", "EmptyLabel", String(row.get("state_text", "")))

	var slot_id := String(row.get("slot_id", ""))
	var row_name := "EquippedRow"
	if not slot_id.is_empty():
		row_name = "EquippedRow_%s" % slot_id
	var row_panel := _create_row_panel(row_name, _row_panel_style(Color(0.106, 0.125, 0.157, 1.0), Color(0.34, 0.5, 0.66, 1.0)))
	row_panel.custom_minimum_size = Vector2(0, 88)
	var row_box := _create_row_box()
	row_box.add_theme_constant_override("separation", 4)
	row_panel.add_child(row_box)

	var summary_label := Label.new()
	summary_label.name = "SummaryLabel"
	summary_label.text = summary_text
	summary_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_label.modulate = Color(0.74, 0.86, 1.0, 0.96)
	row_box.add_child(summary_label)

	var item_text := String(row.get("item_name", ""))
	if not item_text.is_empty():
		var item_label := Label.new()
		item_label.name = "ItemLabel"
		item_label.text = item_text
		item_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_box.add_child(item_label)

	var detail_text := String(row.get("detail_text", ""))
	if not detail_text.is_empty():
		var effect_label := Label.new()
		effect_label.name = "EffectLabel"
		effect_label.text = detail_text
		effect_label.autowrap_mode = 3
		effect_label.modulate = Color(0.9, 0.9, 0.9, 0.9)
		effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_box.add_child(effect_label)

	return row_panel


func _create_row_panel(row_name: String, stylebox: StyleBoxFlat = null) -> PanelContainer:
	var row_panel := PanelContainer.new()
	row_panel.name = row_name
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.custom_minimum_size = Vector2(0, 60)
	if stylebox != null:
		row_panel.add_theme_stylebox_override("panel", stylebox)
	return row_panel


func _create_row_box() -> VBoxContainer:
	var row_box := VBoxContainer.new()
	row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_box.add_theme_constant_override("separation", 2)
	return row_box


func _create_empty_state_row(row_name: String, label_name: String, label_text: String) -> Control:
	var row_panel := _create_row_panel(row_name, _row_panel_style(Color(0.075, 0.086, 0.11, 0.98), Color(0.18, 0.22, 0.28, 1.0)))
	var row_box := _create_row_box()
	row_panel.add_child(row_box)

	var empty_label := Label.new()
	empty_label.name = label_name
	empty_label.text = label_text
	empty_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.modulate = Color(0.82, 0.86, 0.9, 0.96)
	empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_box.add_child(empty_label)
	return row_panel


func _row_panel_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	return style


func _refresh_item_sheet() -> void:
	if _item_sheet == null:
		return

	if _bag_sheet == null or not _bag_sheet.visible:
		_sync_item_detail_layout(false)
		_item_sheet.visible = false
		return

	if _director == null or not _director.has_method("get_selected_inventory_sheet"):
		_sync_item_detail_layout(false)
		_item_sheet.visible = false
		return

	var sheet: Dictionary = _director.get_selected_inventory_sheet()
	if not bool(sheet.get("visible", false)):
		_sync_item_detail_layout(false)
		_item_sheet.visible = false
		return

	_sync_item_detail_layout(true)
	_item_sheet.visible = true
	if _item_sheet_title != null:
		_item_sheet_title.text = String(sheet.get("title", "아이템"))
	if _item_sheet_description != null:
		_item_sheet_description.text = _formatted_item_sheet_description(sheet)
	if _item_sheet_effect != null:
		_item_sheet_effect.text = _formatted_item_sheet_effect(sheet)

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


func _formatted_item_sheet_description(sheet: Dictionary) -> String:
	var lines: Array[String] = []
	var description := String(sheet.get("description", ""))
	if not description.is_empty():
		lines.append(description)
	var usage_hint := String(sheet.get("usage_hint", ""))
	if not usage_hint.is_empty():
		lines.append("용도: %s" % usage_hint)
	var cold_hint := String(sheet.get("cold_hint", ""))
	if not cold_hint.is_empty():
		lines.append("한파: %s" % cold_hint)
	return "\n".join(lines)


func _formatted_item_sheet_effect(sheet: Dictionary) -> String:
	var lines: Array[String] = []
	var item_tags_variant: Variant = sheet.get("item_tags", [])
	if typeof(item_tags_variant) == TYPE_ARRAY:
		var tag_labels: Array[String] = []
		for tag_variant in item_tags_variant:
			var tag_label := String(tag_variant)
			if tag_label.is_empty():
				continue
			tag_labels.append("#%s" % tag_label)
		if not tag_labels.is_empty():
			lines.append(" ".join(tag_labels))
	var effect_text := String(sheet.get("effect_text", ""))
	if not effect_text.is_empty():
		lines.append(effect_text)
	return "\n".join(lines)


func _sync_item_detail_layout(detail_visible: bool) -> void:
	if _item_sheet != null:
		_item_sheet.visible = detail_visible
		_item_sheet.custom_minimum_size = Vector2(300, 0) if detail_visible else Vector2.ZERO
		_item_sheet.size_flags_horizontal = Control.SIZE_FILL if detail_visible else 0
	if _inventory_column != null:
		_inventory_column.custom_minimum_size = Vector2(340, 0) if detail_visible else Vector2.ZERO


func _apply_tab_visual_state(button: Button, active: bool) -> void:
	if button == null:
		return
	button.modulate = Color(1, 1, 1, 1) if active else Color(0.76, 0.79, 0.84, 0.94)
	var normal_style := _tab_style(active)
	var hover_style := _tab_style(active, true)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("focus", normal_style)
	button.add_theme_stylebox_override("pressed", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("hover_pressed", hover_style)


func _tab_style(active: bool, hovered: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	if active:
		style.bg_color = Color(0.23, 0.35, 0.48, 1.0) if not hovered else Color(0.27, 0.4, 0.54, 1.0)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.76, 0.88, 1.0, 1.0)
	else:
		style.bg_color = Color(0.1, 0.12, 0.15, 0.98) if not hovered else Color(0.13, 0.16, 0.2, 1.0)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.26, 0.31, 0.37, 1.0)
	return style


func _refresh_stat_detail_sheet() -> void:
	if _stat_detail_sheet == null:
		return

	if _director == null or _selected_chip_id.is_empty() or not _director.has_method("get_survival_chip_detail"):
		_stat_detail_sheet.visible = false
		return

	var detail: Dictionary = _director.get_survival_chip_detail(_selected_chip_id)
	if detail.is_empty():
		_stat_detail_sheet.visible = false
		return

	_stat_detail_sheet.visible = true
	if _stat_detail_title != null:
		_stat_detail_title.text = String(detail.get("label", "상태"))
	if _stat_detail_value != null:
		_stat_detail_value.text = String(detail.get("detail_value_text", ""))
	if _stat_detail_rule != null:
		_stat_detail_rule.text = String(detail.get("rule_text", ""))
	if _stat_detail_recovery != null:
		_stat_detail_recovery.text = String(detail.get("recovery_text", ""))


func _on_map_button_pressed() -> void:
	if _minimap_overlay == null:
		return
	_minimap_overlay.visible = not _minimap_overlay.visible
	if _minimap_overlay.visible:
		_clear_stat_detail_selection()
		_close_bag_sheet()


func _on_bag_button_pressed() -> void:
	if _bag_sheet == null:
		return
	_bag_sheet.visible = not _bag_sheet.visible
	if _bag_sheet.visible:
		_clear_stat_detail_selection()
		if _minimap_overlay != null:
			_minimap_overlay.visible = false
	else:
		_close_item_sheet_selection()
	_refresh_bag_sheet()
	_refresh_item_sheet()


func _on_craft_button_pressed() -> void:
	craft_requested.emit()


func _on_minimap_close_pressed() -> void:
	if _minimap_overlay != null:
		_minimap_overlay.visible = false
	_clear_stat_detail_selection()


func _on_bag_close_pressed() -> void:
	_close_bag_sheet()


func _on_carried_tab_pressed() -> void:
	_active_bag_tab = "carried"
	_close_item_sheet_selection()
	_refresh_bag_sheet()


func _on_equipped_tab_pressed() -> void:
	_active_bag_tab = "equipped"
	_close_item_sheet_selection()
	_refresh_bag_sheet()


func _on_stat_detail_close_pressed() -> void:
	_clear_stat_detail_selection()


func _close_bag_sheet() -> void:
	if _bag_sheet != null:
		_bag_sheet.visible = false
	_clear_stat_detail_selection()
	_close_item_sheet_selection()
	_refresh_item_sheet()


func _close_item_sheet_selection() -> void:
	if _director != null and _director.has_method("apply_action"):
		_director.apply_action("close_inventory_sheet")
	elif _item_sheet != null:
		_item_sheet.visible = false


func _on_action_pressed(action_id: String) -> void:
	if action_id == "exit_building":
		exit_requested.emit()
		return

	if _director != null and _director.has_method("apply_action"):
		_director.apply_action(action_id)


func _on_stat_chip_pressed(chip_id: String) -> void:
	if _bag_sheet != null and _bag_sheet.visible:
		_close_bag_sheet()
	if _minimap_overlay != null and _minimap_overlay.visible:
		_minimap_overlay.visible = false
		_clear_stat_detail_selection()
	if _selected_chip_id == chip_id and _stat_detail_sheet != null and _stat_detail_sheet.visible:
		_clear_stat_detail_selection()
		return
	_selected_chip_id = chip_id
	_refresh_stat_detail_sheet()


func _clear_stat_detail_selection() -> void:
	_selected_chip_id = ""
	if _stat_detail_sheet != null:
		_stat_detail_sheet.visible = false


func _cache_nodes() -> void:
	_director = get_node_or_null("Director")
	_title_label = get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/TitleLabel") as Label
	_location_label = get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/LocationLabel") as Label
	_location_value_label = get_node_or_null("Panel/Layout/MainColumn/LocationStrip/HBox/LocationValueLabel") as Label
	_time_label = get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/TimeLabel") as Label
	_stat_chips = get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/StatChips") as HBoxContainer
	_inline_minimap = get_node_or_null("Panel/Layout/MainColumn/ContextRow/MiniMapCard/MapNodes") as Control
	_summary_label = get_node_or_null("Panel/Layout/MainColumn/ContextRow/ReadingCard/VBox/SummaryLabel") as Label
	_result_label = get_node_or_null("Panel/Layout/MainColumn/ContextRow/ReadingCard/VBox/ResultLabel") as Label
	_action_buttons = get_node_or_null("Panel/Layout/MainColumn/ActionScroll/ActionButtons") as VBoxContainer
	_map_button = get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/Tools/MapButton") as Button
	_bag_button = get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/Tools/BagButton") as Button
	_craft_button = get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/Tools/CraftButton") as Button
	_minimap_overlay = get_node_or_null("MinimapOverlay") as Control
	_minimap_close_button = get_node_or_null("MinimapOverlay/VBox/Header/CloseButton") as Button
	_minimap = get_node_or_null("MinimapOverlay/VBox/MapNodes") as Control
	_bag_sheet = get_node_or_null("BagSheet") as Control
	_bag_title_label = get_node_or_null("BagSheet/VBox/Header/TitleLabel") as Label
	_bag_status_label = get_node_or_null("BagSheet/VBox/Header/StatusLabel") as Label
	_bag_close_button = get_node_or_null("BagSheet/VBox/Header/CloseButton") as Button
	_carried_tab_button = get_node_or_null("BagSheet/VBox/Tabs/CarriedTabButton") as Button
	_equipped_tab_button = get_node_or_null("BagSheet/VBox/Tabs/EquippedTabButton") as Button
	_inventory_column = get_node_or_null("BagSheet/VBox/ContentRow/InventoryColumn") as Control
	_inventory_items = get_node_or_null("BagSheet/VBox/ContentRow/InventoryColumn/InventoryScroll/InventoryItems") as VBoxContainer
	_item_sheet = get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel") as Control
	_item_sheet_title = get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel/VBox/ItemNameLabel") as Label
	_item_sheet_description = get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel/VBox/ItemDescriptionLabel") as Label
	_item_sheet_effect = get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel/VBox/ItemEffectLabel") as Label
	_item_sheet_actions = get_node_or_null("BagSheet/VBox/ContentRow/ItemDetailPanel/VBox/ActionButtons") as HBoxContainer
	_stat_detail_sheet = get_node_or_null("StatDetailSheet") as Control
	_stat_detail_title = get_node_or_null("StatDetailSheet/VBox/Header/TitleLabel") as Label
	_stat_detail_close_button = get_node_or_null("StatDetailSheet/VBox/Header/CloseButton") as Button
	_stat_detail_value = get_node_or_null("StatDetailSheet/VBox/ValueLabel") as Label
	_stat_detail_rule = get_node_or_null("StatDetailSheet/VBox/RuleLabel") as Label
	_stat_detail_recovery = get_node_or_null("StatDetailSheet/VBox/RecoveryLabel") as Label


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
