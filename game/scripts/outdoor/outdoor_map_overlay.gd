extends CanvasLayer
class_name OutdoorMapOverlay

signal close_requested

const UiKitResolver = preload("res://scripts/ui/ui_kit_resolver.gd")
const INDOOR_ACTION_RESOLVER_SCRIPT := preload("res://scripts/indoor/indoor_action_resolver.gd")
const TEXT_PRIMARY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const TEXT_SECONDARY_COLOR := Color(0.92, 0.96, 1.0, 0.98)
const TEXT_MUTED_COLOR := Color(0.76, 0.84, 0.90, 0.96)
const TEXT_OUTLINE_COLOR := Color(0.0, 0.02, 0.04, 1.0)

var _map_view = null
var _close_button: Button = null
var _focus_button: Button = null
var _status_label: Label = null
var _legend_row: HBoxContainer = null
var _detail_layer: Control = null
var _detail_title: Label = null
var _detail_message: Label = null
var _detail_close_button: Button = null
var _detail_map = null
var _resolver := INDOOR_ACTION_RESOLVER_SCRIPT.new()
var _run_state = null
var _ui_kit_resolver = UiKitResolver.new()
var _world_layout: Dictionary = {}
var _building_rows: Array[Dictionary] = []
var _visited_block_ids: Dictionary = {}
var _last_player_position := Vector2.ZERO


func _ready() -> void:
	visible = false
	_map_view = get_node_or_null("Panel/VBox/Margin/MapView")
	_close_button = get_node_or_null("Panel/VBox/Header/CloseButton") as Button
	_focus_button = get_node_or_null("Panel/VBox/Header/FocusButton") as Button
	_status_label = get_node_or_null("Panel/VBox/Header/StatusLabel") as Label
	_legend_row = get_node_or_null("Panel/VBox/LegendRow") as HBoxContainer
	_detail_layer = get_node_or_null("BuildingDetailLayer") as Control
	_detail_title = get_node_or_null("BuildingDetailLayer/Panel/VBox/Header/TitleLabel") as Label
	_detail_message = get_node_or_null("BuildingDetailLayer/Panel/VBox/MessageLabel") as Label
	_detail_close_button = get_node_or_null("BuildingDetailLayer/Panel/VBox/Header/CloseButton") as Button
	_detail_map = get_node_or_null("BuildingDetailLayer/Panel/VBox/IndoorMap")
	_apply_ui_skin()
	if _close_button != null and not _close_button.pressed.is_connected(_on_close_pressed):
		_close_button.pressed.connect(_on_close_pressed)
	if _focus_button != null and not _focus_button.pressed.is_connected(_on_focus_pressed):
		_focus_button.pressed.connect(_on_focus_pressed)
	if _detail_close_button != null and not _detail_close_button.pressed.is_connected(hide_building_detail):
		_detail_close_button.pressed.connect(hide_building_detail)
	if _map_view != null and _map_view.has_signal("building_selected") and not _map_view.building_selected.is_connected(_on_building_selected):
		_map_view.building_selected.connect(_on_building_selected)
	hide_building_detail()


func _apply_ui_skin() -> void:
	var panel := get_node_or_null("Panel") as PanelContainer
	var detail_panel := get_node_or_null("BuildingDetailLayer/Panel") as PanelContainer
	_ui_kit_resolver.apply_panel(panel, "overlay/overlay_map_panel_clean.png")
	_ui_kit_resolver.apply_panel(detail_panel, "overlay/overlay_building_detail_panel.png")
	_ui_kit_resolver.apply_button(
		_close_button,
		"overlay/overlay_close_button_compact_normal.png",
		"overlay/overlay_close_button_compact_pressed.png",
		"overlay/overlay_close_button_compact_pressed.png",
		"overlay/overlay_close_button_compact_normal.png"
	)
	_ui_kit_resolver.apply_button(
		_detail_close_button,
		"overlay/overlay_close_button_compact_normal.png",
		"overlay/overlay_close_button_compact_pressed.png",
		"overlay/overlay_close_button_compact_pressed.png",
		"overlay/overlay_close_button_compact_normal.png"
	)
	_ui_kit_resolver.apply_button(
		_focus_button,
		"overlay/overlay_close_button_compact_normal.png",
		"overlay/overlay_close_button_compact_pressed.png",
		"overlay/overlay_close_button_compact_pressed.png",
		"overlay/overlay_close_button_compact_normal.png"
	)
	_apply_label_style(get_node_or_null("Panel/VBox/Header/TitleLabel") as Label, 18, TEXT_PRIMARY_COLOR, 3)
	_apply_label_style(_status_label, 13, TEXT_SECONDARY_COLOR, 2)
	_apply_label_style(_detail_title, 17, TEXT_PRIMARY_COLOR, 3)
	_apply_label_style(_detail_message, 15, TEXT_SECONDARY_COLOR, 2)
	if _legend_row != null:
		for child in _legend_row.get_children():
			_apply_label_style(child as Label, 12, TEXT_MUTED_COLOR, 1)
	if _close_button != null:
		_close_button.text = ""
		_close_button.tooltip_text = "닫기"
		_close_button.custom_minimum_size = Vector2(42, 42)
		_close_button.icon = _ui_kit_resolver.get_texture("icons/light_24/close.png")
		_close_button.expand_icon = true
	if _focus_button != null:
		_focus_button.text = ""
		_focus_button.tooltip_text = "현재 위치"
		_focus_button.custom_minimum_size = Vector2(42, 42)
		_focus_button.icon = load("res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/target.png") as Texture2D
		_focus_button.expand_icon = true
	if _detail_close_button != null:
		_detail_close_button.text = ""
		_detail_close_button.tooltip_text = "닫기"
		_detail_close_button.custom_minimum_size = Vector2(42, 42)
		_detail_close_button.icon = _ui_kit_resolver.get_texture("icons/light_24/close.png")
		_detail_close_button.expand_icon = true


func configure(world_layout: Dictionary, block_rows: Dictionary, building_rows: Array[Dictionary], visited_block_ids: Dictionary, player_position: Vector2, run_state) -> void:
	_run_state = run_state
	_world_layout = world_layout.duplicate(true)
	_building_rows = building_rows.duplicate(true)
	_visited_block_ids = visited_block_ids.duplicate(true)
	_last_player_position = player_position
	if _map_view == null:
		return
	_map_view.configure(world_layout, block_rows, building_rows, visited_block_ids, player_position)
	_refresh_status_label()


func open() -> void:
	visible = true


func close() -> void:
	visible = false
	hide_building_detail()


func show_building_detail(building_id: String) -> void:
	if _detail_layer == null:
		return
	var building := ContentLibrary.get_building(building_id)
	var building_name := String(building.get("name", building_id))
	if _detail_title != null:
		_detail_title.text = building_name
	if _detail_message != null:
		_detail_message.text = ""
	if _detail_map != null and _detail_map.has_method("set_snapshot"):
		_detail_map.set_snapshot({"nodes": [], "edges": []})
		_detail_map.visible = false

	if _run_state == null or not _run_state.has_method("has_entered_indoor_site") or not _run_state.has_entered_indoor_site(building_id):
		if _detail_message != null:
			_detail_message.text = "아직 내부 구조를 모른다."
		_detail_layer.visible = true
		return

	var event_data := _resolver.load_event(String(building.get("indoor_event_path", "")))
	var site_memory: Dictionary = _run_state.get_site_memory(building_id) if _run_state.has_method("get_site_memory") else {}
	if _detail_message != null:
		_detail_message.text = _known_zone_summary(event_data, site_memory)
	if _detail_map != null and _detail_map.has_method("set_snapshot"):
		_detail_map.visible = true
		_detail_map.set_snapshot(_build_indoor_snapshot(event_data, site_memory))
	_detail_layer.visible = true


func hide_building_detail() -> void:
	if _detail_layer != null:
		_detail_layer.visible = false


func focus_on_player(player_position: Vector2) -> void:
	_last_player_position = player_position
	if _map_view != null and _map_view.has_method("focus_on_world_position"):
		_map_view.focus_on_world_position(player_position)


func _on_close_pressed() -> void:
	close_requested.emit()


func _on_focus_pressed() -> void:
	focus_on_player(_last_player_position)


func _on_building_selected(building_id: String) -> void:
	show_building_detail(building_id)


func _known_zone_summary(event_data: Dictionary, site_memory: Dictionary) -> String:
	var visited_zone_ids: PackedStringArray = site_memory.get("visited_zone_ids", PackedStringArray())
	var labels: Array[String] = []
	for zone_id_variant in visited_zone_ids:
		var zone_id := String(zone_id_variant)
		var zone := _resolver.get_zone(event_data, zone_id)
		if zone.is_empty():
			continue
		labels.append(String(zone.get("label", zone_id)))
	if labels.is_empty():
		return "기록된 내부 정보가 아직 없다."
	return "확인한 구역 %d개: %s" % [labels.size(), ", ".join(labels)]


func _refresh_status_label() -> void:
	if _status_label == null:
		return
	var total_blocks := _total_block_count()
	var visited_count := _visited_block_count()
	var visible_building_count := _visible_building_count()
	_status_label.text = "탐색 %d/%d · 표시 건물 %d" % [visited_count, total_blocks, visible_building_count]


func _total_block_count() -> int:
	var city_blocks := _world_layout.get("city_blocks", {}) as Dictionary
	return int(city_blocks.get("width", 0)) * int(city_blocks.get("height", 0))


func _visited_block_count() -> int:
	var count := 0
	for value_variant in _visited_block_ids.values():
		if bool(value_variant):
			count += 1
	return count


func _visible_building_count() -> int:
	var count := 0
	for building_variant in _building_rows:
		if typeof(building_variant) != TYPE_DICTIONARY:
			continue
		var building := building_variant as Dictionary
		var block_coord_row := building.get("outdoor_block_coord", {}) as Dictionary
		var block_key := "%d_%d" % [int(block_coord_row.get("x", 0)), int(block_coord_row.get("y", 0))]
		if bool(_visited_block_ids.get(block_key, false)):
			count += 1
	return count


func _apply_label_style(label: Label, font_size: int, font_color: Color, outline_size: int) -> void:
	if label == null:
		return
	label.modulate = font_color
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", TEXT_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", outline_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _build_indoor_snapshot(event_data: Dictionary, site_memory: Dictionary) -> Dictionary:
	var visited_zone_ids: PackedStringArray = site_memory.get("visited_zone_ids", PackedStringArray())
	var nodes: Array[Dictionary] = []
	var edges: Array[Dictionary] = []
	for zone_variant in event_data.get("zones", []):
		if typeof(zone_variant) != TYPE_DICTIONARY:
			continue
		var zone := zone_variant as Dictionary
		var zone_id := String(zone.get("id", ""))
		if not visited_zone_ids.has(zone_id):
			continue
		nodes.append({
			"id": zone_id,
			"label": String(zone.get("label", zone_id)),
			"floor_id": String(zone.get("floor_id", "")),
			"map_position": zone.get("map_position", [0, 0]),
			"state": "current" if zone_id == String(site_memory.get("last_known_zone_id", "")) else "visited",
		})
		for connected_zone_id_variant in zone.get("connected_zone_ids", []):
			var connected_zone_id := String(connected_zone_id_variant)
			if not visited_zone_ids.has(connected_zone_id):
				continue
			edges.append({
				"from": zone_id,
				"to": connected_zone_id,
				"locked": false,
			})
	return {
		"current_zone_id": String(site_memory.get("last_known_zone_id", "")),
		"current_floor_id": _current_floor_for_snapshot(nodes, String(site_memory.get("last_known_zone_id", ""))),
		"nodes": nodes,
		"edges": edges,
	}


func _current_floor_for_snapshot(nodes: Array[Dictionary], current_zone_id: String) -> String:
	for node in nodes:
		if String(node.get("id", "")) == current_zone_id:
			return String(node.get("floor_id", ""))
	return ""
