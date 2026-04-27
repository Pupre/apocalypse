extends CanvasLayer
class_name OutdoorMapOverlay

signal close_requested

const UiKitResolver = preload("res://scripts/ui/ui_kit_resolver.gd")
const INDOOR_ACTION_RESOLVER_SCRIPT := preload("res://scripts/indoor/indoor_action_resolver.gd")

var _map_view = null
var _close_button: Button = null
var _detail_layer: Control = null
var _detail_title: Label = null
var _detail_message: Label = null
var _detail_close_button: Button = null
var _detail_map = null
var _resolver := INDOOR_ACTION_RESOLVER_SCRIPT.new()
var _run_state = null
var _ui_kit_resolver = UiKitResolver.new()


func _ready() -> void:
	visible = false
	_map_view = get_node_or_null("Panel/VBox/Margin/MapView")
	_close_button = get_node_or_null("Panel/VBox/Header/CloseButton") as Button
	_detail_layer = get_node_or_null("BuildingDetailLayer") as Control
	_detail_title = get_node_or_null("BuildingDetailLayer/Panel/VBox/Header/TitleLabel") as Label
	_detail_message = get_node_or_null("BuildingDetailLayer/Panel/VBox/MessageLabel") as Label
	_detail_close_button = get_node_or_null("BuildingDetailLayer/Panel/VBox/Header/CloseButton") as Button
	_detail_map = get_node_or_null("BuildingDetailLayer/Panel/VBox/IndoorMap")
	_apply_ui_skin()
	if _close_button != null and not _close_button.pressed.is_connected(_on_close_pressed):
		_close_button.pressed.connect(_on_close_pressed)
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
	if _close_button != null:
		_close_button.text = ""
		_close_button.tooltip_text = "닫기"
		_close_button.custom_minimum_size = Vector2(42, 42)
		_close_button.icon = _ui_kit_resolver.get_texture("icons/light_24/close.png")
		_close_button.expand_icon = true
	if _detail_close_button != null:
		_detail_close_button.text = ""
		_detail_close_button.tooltip_text = "닫기"
		_detail_close_button.custom_minimum_size = Vector2(42, 42)
		_detail_close_button.icon = _ui_kit_resolver.get_texture("icons/light_24/close.png")
		_detail_close_button.expand_icon = true


func configure(world_layout: Dictionary, block_rows: Dictionary, building_rows: Array[Dictionary], visited_block_ids: Dictionary, player_position: Vector2, run_state) -> void:
	_run_state = run_state
	if _map_view == null:
		return
	_map_view.configure(world_layout, block_rows, building_rows, visited_block_ids, player_position)


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
	if _map_view != null and _map_view.has_method("focus_on_world_position"):
		_map_view.focus_on_world_position(player_position)


func _on_close_pressed() -> void:
	close_requested.emit()


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
	return "확인한 구역: %s" % ", ".join(labels)


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
