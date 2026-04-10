extends Control

signal state_changed
signal exit_requested

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
var _survival_sheet: CanvasLayer = null
var _minimap_overlay: Control = null
var _minimap_close_button: Button = null
var _minimap: Control = null
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


func configure(run_state, building_id: String = "mart_01") -> void:
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
	_push_inventory_payload_into_sheet()
	_refresh_action_buttons()
	_refresh_minimap()
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
	if _survival_sheet == null or not _survival_sheet.has_method("open_inventory"):
		return
	if _survival_sheet.visible:
		_survival_sheet.close_sheet()
		return
	_clear_stat_detail_selection()
	if _minimap_overlay != null:
		_minimap_overlay.visible = false
	_survival_sheet.open_inventory()
	_push_inventory_payload_into_sheet()


func _on_minimap_close_pressed() -> void:
	if _minimap_overlay != null:
		_minimap_overlay.visible = false
	_clear_stat_detail_selection()


func _on_stat_detail_close_pressed() -> void:
	_clear_stat_detail_selection()


func _close_bag_sheet() -> void:
	if _survival_sheet != null and _survival_sheet.visible and _survival_sheet.has_method("close_sheet"):
		_survival_sheet.close_sheet()
	_clear_stat_detail_selection()


func _on_action_pressed(action_id: String) -> void:
	if action_id == "exit_building":
		exit_requested.emit()
		return

	if _director != null and _director.has_method("apply_action"):
		_director.apply_action(action_id)


func _on_stat_chip_pressed(chip_id: String) -> void:
	if _survival_sheet != null and _survival_sheet.visible:
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
	_inline_minimap = get_node_or_null("Panel/Layout/MainColumn/MiniMapCard/MapNodes") as Control
	_summary_label = get_node_or_null("Panel/Layout/MainColumn/ReadingCard/VBox/SummaryLabel") as Label
	_result_label = get_node_or_null("Panel/Layout/MainColumn/ReadingCard/VBox/ResultLabel") as Label
	_action_buttons = get_node_or_null("Panel/Layout/MainColumn/ActionScroll/ActionButtons") as VBoxContainer
	_map_button = get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/Tools/MapButton") as Button
	_bag_button = get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/Tools/BagButton") as Button
	_survival_sheet = get_node_or_null("SurvivalSheet") as CanvasLayer
	_minimap_overlay = get_node_or_null("MinimapOverlay") as Control
	_minimap_close_button = get_node_or_null("MinimapOverlay/VBox/Header/CloseButton") as Button
	_minimap = get_node_or_null("MinimapOverlay/VBox/MapNodes") as Control
	_stat_detail_sheet = get_node_or_null("StatDetailSheet") as Control
	_stat_detail_title = get_node_or_null("StatDetailSheet/VBox/Header/TitleLabel") as Label
	_stat_detail_close_button = get_node_or_null("StatDetailSheet/VBox/Header/CloseButton") as Button
	_stat_detail_value = get_node_or_null("StatDetailSheet/VBox/ValueLabel") as Label
	_stat_detail_rule = get_node_or_null("StatDetailSheet/VBox/RuleLabel") as Label
	_stat_detail_recovery = get_node_or_null("StatDetailSheet/VBox/RecoveryLabel") as Label


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


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
