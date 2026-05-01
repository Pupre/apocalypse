extends Node2D
class_name OutdoorController

signal state_changed
signal building_entered(building_id: String)

const EXPOSURE_MODEL_SCRIPT := preload("res://scripts/outdoor/exposure_model.gd")
const OUTDOOR_THREAT_DIRECTOR_SCRIPT := preload("res://scripts/outdoor/outdoor_threat_director.gd")
const OUTDOOR_WORLD_RUNTIME_SCRIPT := preload("res://scripts/outdoor/outdoor_world_runtime.gd")
const OUTDOOR_ART_RESOLVER_SCRIPT := preload("res://scripts/outdoor/outdoor_art_resolver.gd")
const DEFAULT_BUILDING_ID := "mart_01"
const DEFAULT_PLAYER_POSITION := Vector2(240.0, 360.0)
const PORTRAIT_CAMERA_OFFSET := Vector2(0.0, -220.0)
const ENTER_RADIUS := 72.0
const TERRAIN_TILE_SIZE := 32.0
const MOVE_LEFT_ACTION := "move_left"
const MOVE_RIGHT_ACTION := "move_right"
const MOVE_UP_ACTION := "move_up"
const MOVE_DOWN_ACTION := "move_down"
const ENTER_BUILDING_ACTION := "enter_building"
const BUILDING_LABELS := {
	"mart_01": "마트",
	"apartment_01": "아파트",
	"clinic_01": "의원",
	"office_01": "사무실",
	"convenience_01": "편의점",
	"hardware_01": "철물점",
	"gas_station_01": "주유소",
	"laundry_01": "세탁소",
	"pharmacy_01": "약국",
	"restaurant_01": "식당",
	"bakery_01": "빵집",
	"warehouse_01": "창고",
	"cafe_01": "카페",
	"police_box_01": "파출소",
	"repair_shop_01": "수리점",
	"residence_01": "주택",
}

var run_state = null
var exposure_model := EXPOSURE_MODEL_SCRIPT.new()
var threat_director = OUTDOOR_THREAT_DIRECTOR_SCRIPT.new()
var world_runtime = OUTDOOR_WORLD_RUNTIME_SCRIPT.new()
var art_resolver = OUTDOOR_ART_RESOLVER_SCRIPT.new()
var _seconds_buffer := 0.0
var _player_position := DEFAULT_PLAYER_POSITION
var _player_spawn := DEFAULT_PLAYER_POSITION
var _world_bounds := Rect2(0.0, 0.0, 1200.0, 1092.0)
var _current_block_coord := Vector2i.ZERO
var _active_block_coords: Array[Vector2i] = []
var _building_rows: Array[Dictionary] = []
var _road_rows: Array[Dictionary] = []
var _snow_field_rows: Array[Dictionary] = []
var _obstacle_rows: Array[Dictionary] = []
var _threat_rows: Array[Dictionary] = []
var _building_anchor_rows: Dictionary = {}
var _building_positions: Dictionary = {}
var _last_threat_snapshot := {
	"threat_state": "idle",
	"contact": false,
	"threats": [],
}
var _contact_cooldown_seconds := 0.0
var _player_visual: Sprite2D = null
var _camera: Camera2D = null
var _top_ribbon: PanelContainer = null
var _ground_host: Node2D = null
var _ground_backdrop_host: Node2D = null
var _ground_tiles_host: Node2D = null
var _ground_decals_host: Node2D = null
var _building_host: Node2D = null
var _obstacle_host: Node2D = null
var _threat_host: Node2D = null
var _building_markers: Dictionary = {}
var _threat_markers: Dictionary = {}
var _hint_label: Label = null
var _threat_label: Label = null
var _frost_overlay: ColorRect = null
var _map_overlay = null
var _debug_contact_requested := false
var _player_facing_id := "down"
var _player_walk_seconds := 0.0


func _ready() -> void:
	_cache_nodes()
	_bind_ui_buttons()
	_load_outdoor_layout()
	_sync_active_blocks()
	_refresh_ground()
	_refresh_buildings()
	_refresh_obstacles()
	_configure_threats()
	_sync_view()


func bind_run_state(value, building_id: String = DEFAULT_BUILDING_ID, player_position = null) -> void:
	run_state = value
	_seconds_buffer = 0.0
	_contact_cooldown_seconds = 0.0
	_player_walk_seconds = 0.0
	_player_facing_id = "down"
	_cache_nodes()
	_bind_ui_buttons()
	_load_outdoor_layout()
	_player_position = player_position if typeof(player_position) == TYPE_VECTOR2 else _player_spawn
	_sync_active_blocks()
	_refresh_ground()
	_refresh_buildings()
	_refresh_obstacles()
	_configure_threats()
	hide_map_overlay()
	_sync_view()
	state_changed.emit()


func attempt_craft(primary_item_id: String, secondary_item_id: String) -> Dictionary:
	if run_state == null or not run_state.has_method("attempt_craft"):
		return {
			"ok": false,
			"result_type": "invalid",
			"result_item_id": "",
			"result_text": "런 상태를 찾지 못했다.",
			"minutes_elapsed": 0,
		}

	return run_state.attempt_craft(primary_item_id, secondary_item_id, "outdoor")


func simulate_seconds(seconds_elapsed: float) -> void:
	if is_map_overlay_open():
		return
	if run_state == null or seconds_elapsed <= 0.0:
		return

	_seconds_buffer += seconds_elapsed
	var full_minutes := int(floor(_seconds_buffer))
	if full_minutes <= 0:
		return

	_seconds_buffer -= float(full_minutes)
	_advance_outdoor_minutes(full_minutes)
	_sync_view()
	state_changed.emit()


func move_player(direction: Vector2, seconds_elapsed: float) -> void:
	if run_state == null or direction == Vector2.ZERO or seconds_elapsed <= 0.0:
		return

	_player_facing_id = _resolve_facing_id(direction)
	_player_walk_seconds += seconds_elapsed
	var effective_move_speed: float = float(run_state.move_speed)
	if run_state.has_method("get_outdoor_move_speed"):
		effective_move_speed = float(run_state.get_outdoor_move_speed())

	var target_position := _player_position + direction.normalized() * effective_move_speed * seconds_elapsed
	_player_position = _constrain_player_position(target_position)
	_sync_active_blocks()
	_refresh_ground()
	_refresh_buildings()
	_refresh_obstacles()
	_configure_threats()
	_sync_view()
	state_changed.emit()


func try_enter_building(building_id: String) -> bool:
	if building_id.is_empty() or not _is_player_near_building(building_id):
		return false

	building_entered.emit(building_id)
	return true


func get_player_position() -> Vector2:
	return _player_position


func get_world_bounds() -> Rect2:
	return _world_bounds


func get_active_block_coords() -> Array[Vector2i]:
	return _active_block_coords.duplicate()


func refresh_view() -> void:
	_sync_view()


func show_map_overlay() -> void:
	if _map_overlay != null:
		if _map_overlay.has_method("focus_on_player"):
			_map_overlay.focus_on_player(_player_position)
		_map_overlay.open()
		_sync_view()


func hide_map_overlay() -> void:
	if _map_overlay != null:
		_map_overlay.close()


func is_map_overlay_open() -> bool:
	return _map_overlay != null and _map_overlay.visible


func debug_force_threat_contact() -> void:
	if run_state == null:
		return
	run_state.apply_outdoor_threat_contact()
	_last_threat_snapshot = {
		"threat_state": "chasing",
		"contact": true,
		"threats": _last_threat_snapshot.get("threats", []),
	}
	_sync_view()
	state_changed.emit()


func _process(delta: float) -> void:
	if run_state == null:
		return

	if is_map_overlay_open():
		if Input.is_action_just_pressed("ui_cancel"):
			hide_map_overlay()
		_sync_view()
		state_changed.emit()
		return

	simulate_seconds(delta)
	_contact_cooldown_seconds = max(0.0, _contact_cooldown_seconds - delta)
	var direction := Input.get_vector(MOVE_LEFT_ACTION, MOVE_RIGHT_ACTION, MOVE_UP_ACTION, MOVE_DOWN_ACTION)
	if direction != Vector2.ZERO:
		move_player(direction, delta)
	else:
		_player_walk_seconds = 0.0

	var threat_snapshot: Dictionary = threat_director.tick(_player_position, delta)
	if _debug_contact_requested:
		threat_snapshot["contact"] = true
		_debug_contact_requested = false
	if bool(threat_snapshot.get("contact", false)) and run_state != null and _contact_cooldown_seconds <= 0.0:
		run_state.apply_outdoor_threat_contact()
		_contact_cooldown_seconds = 1.5
	_last_threat_snapshot = threat_snapshot
	_sync_view()
	state_changed.emit()

	var nearby_building_id := _get_nearby_building_id()
	if not nearby_building_id.is_empty() and Input.is_action_just_pressed(ENTER_BUILDING_ACTION):
		try_enter_building(nearby_building_id)


func _advance_outdoor_minutes(minutes: int) -> void:
	for _minute in range(minutes):
		var exposure_multiplier := 1.0
		if run_state.has_method("get_outdoor_exposure_drain_multiplier"):
			exposure_multiplier = float(run_state.get_outdoor_exposure_drain_multiplier())
		run_state.advance_minutes(1, "outdoor")
		run_state.exposure = exposure_model.drain(run_state.exposure, 1.0, run_state.fatigue, exposure_multiplier)


func _is_player_near_building(building_id: String) -> bool:
	var building_position_variant = _building_positions.get(building_id, null)
	if typeof(building_position_variant) != TYPE_VECTOR2:
		return false

	return _player_position.distance_to(building_position_variant) <= ENTER_RADIUS


func _refresh_buildings() -> void:
	_building_rows = _get_active_building_rows()
	_building_positions.clear()

	if _building_host != null:
		for child in _building_host.get_children():
			child.free()
	_building_markers.clear()

	for building_data in _building_rows:
		var building_id := String(building_data.get("id", ""))
		if building_id.is_empty():
			continue

		var building_position := _resolve_building_position(building_data)
		_building_positions[building_id] = building_position
		if _building_host == null:
			continue

		var marker_root := Node2D.new()
		marker_root.name = "%sMarker" % building_id
		marker_root.position = building_position
		marker_root.z_index = 12

		var visual := Sprite2D.new()
		visual.name = "Visual"
		visual.texture = art_resolver.get_building_texture(building_data)
		_configure_bottom_center_sprite(visual)
		visual.scale = Vector2.ONE * 1.2
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		marker_root.add_child(visual)

		var label := Label.new()
		label.name = "Label"
		label.text = BUILDING_LABELS.get(building_id, String(building_data.get("name", "건물")))
		label.position = Vector2(-56, -118)
		label.size = Vector2(112, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		marker_root.add_child(label)

		_building_host.add_child(marker_root)
		_building_markers[building_id] = marker_root


func _refresh_obstacles() -> void:
	if _obstacle_host == null:
		return

	for child in _obstacle_host.get_children():
		child.free()

	for index in range(_obstacle_rows.size()):
		var obstacle_row: Dictionary = _obstacle_rows[index]
		var rect_row_variant: Variant = obstacle_row.get("rect", {})
		if typeof(rect_row_variant) != TYPE_DICTIONARY:
			continue
		var rect_row := rect_row_variant as Dictionary
		var obstacle_rect := Rect2(
			float(rect_row.get("x", 0.0)),
			float(rect_row.get("y", 0.0)),
			float(rect_row.get("width", 0.0)),
			float(rect_row.get("height", 0.0))
		)
		var obstacle_root := Node2D.new()
		obstacle_root.name = "Obstacle_%d" % index
		obstacle_root.position = obstacle_rect.position + Vector2(obstacle_rect.size.x * 0.5, obstacle_rect.size.y)
		obstacle_root.z_index = 11

		var prop_sprite := Sprite2D.new()
		prop_sprite.name = "Visual"
		prop_sprite.texture = art_resolver.get_prop_texture(String(obstacle_row.get("kind", "")), obstacle_rect)
		_configure_bottom_center_sprite(prop_sprite)
		prop_sprite.scale = Vector2.ONE * _obstacle_scale(String(obstacle_row.get("kind", "")), obstacle_rect)
		prop_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		obstacle_root.add_child(prop_sprite)

		_obstacle_host.add_child(obstacle_root)


func _load_outdoor_layout() -> void:
	_load_outdoor_world_runtime()


func _load_outdoor_world_runtime() -> void:
	var layout: Dictionary = ContentLibrary.get_outdoor_world_layout()
	var block_rows: Dictionary = {}
	var city_blocks_variant: Variant = layout.get("city_blocks", {})
	var city_blocks := city_blocks_variant as Dictionary if typeof(city_blocks_variant) == TYPE_DICTIONARY else {}
	for y in range(int(city_blocks.get("height", 0))):
		for x in range(int(city_blocks.get("width", 0))):
			var block_coord := Vector2i(x, y)
			var block_row: Dictionary = ContentLibrary.get_outdoor_block(block_coord)
			if block_row.is_empty():
				continue
			block_rows["%d_%d" % [x, y]] = block_row

	world_runtime.configure(layout, block_rows)
	_world_bounds = world_runtime.get_world_bounds()
	var spawn_block_variant: Variant = layout.get("spawn_block_coord", {})
	var spawn_block := spawn_block_variant as Dictionary if typeof(spawn_block_variant) == TYPE_DICTIONARY else {}
	var spawn_local := _vector2_from_row(layout.get("spawn_local_position", {}), DEFAULT_PLAYER_POSITION)
	_player_spawn = world_runtime.get_block_origin(Vector2i(int(spawn_block.get("x", 0)), int(spawn_block.get("y", 0)))) + spawn_local
	_sync_active_blocks()


func _sync_active_blocks() -> void:
	_current_block_coord = world_runtime.world_to_block_coord(_player_position)
	_active_block_coords = world_runtime.get_active_block_coords(_current_block_coord)
	if run_state != null and run_state.has_method("mark_outdoor_block_visited"):
		run_state.mark_outdoor_block_visited(_current_block_coord)
	_rebuild_active_rows()


func _rebuild_active_rows() -> void:
	_road_rows.clear()
	_snow_field_rows.clear()
	_obstacle_rows.clear()
	_threat_rows.clear()
	_building_anchor_rows.clear()

	for block_coord in _active_block_coords:
		var block_row: Dictionary = world_runtime.get_block_row(block_coord)
		if block_row.is_empty():
			continue
		var block_origin := world_runtime.get_block_origin(block_coord)
		_append_rect_rows(_road_rows, block_row.get("roads", []), block_origin)
		_append_rect_rows(_snow_field_rows, block_row.get("snow_fields", []), block_origin)
		_append_rect_rows(_obstacle_rows, block_row.get("obstacles", []), block_origin)
		_append_threat_rows(block_row.get("threat_spawns", []), block_origin)
		_append_anchor_rows(block_row.get("building_anchors", {}), block_origin)


func _append_rect_rows(target_rows: Array[Dictionary], source_variant: Variant, block_origin: Vector2) -> void:
	if typeof(source_variant) != TYPE_ARRAY:
		return
	for row_variant in source_variant as Array:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row := (row_variant as Dictionary).duplicate(true)
		var rect_variant: Variant = row.get("rect", {})
		if typeof(rect_variant) != TYPE_DICTIONARY:
			continue
		var rect_row := (rect_variant as Dictionary).duplicate(true)
		rect_row["x"] = float(rect_row.get("x", 0.0)) + block_origin.x
		rect_row["y"] = float(rect_row.get("y", 0.0)) + block_origin.y
		row["rect"] = rect_row
		target_rows.append(row)


func _append_threat_rows(source_variant: Variant, block_origin: Vector2) -> void:
	if typeof(source_variant) != TYPE_ARRAY:
		return
	for row_variant in source_variant as Array:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row := row_variant as Dictionary
		_threat_rows.append({
			"id": String(row.get("id", "")),
			"position": _vector2_from_row(row.get("position", {}), Vector2.ZERO) + block_origin,
			"forward": _vector2_from_row(row.get("forward", {}), Vector2.RIGHT),
		})


func _append_anchor_rows(source_variant: Variant, block_origin: Vector2) -> void:
	if typeof(source_variant) != TYPE_DICTIONARY:
		return
	for anchor_id_variant in (source_variant as Dictionary).keys():
		var anchor_id := String(anchor_id_variant)
		var anchor_row_variant: Variant = (source_variant as Dictionary).get(anchor_id, {})
		if typeof(anchor_row_variant) != TYPE_DICTIONARY:
			continue
		var world_position := _vector2_from_row(anchor_row_variant, Vector2.ZERO) + block_origin
		_building_anchor_rows[anchor_id] = {"x": world_position.x, "y": world_position.y}


func _refresh_ground() -> void:
	if _ground_host == null or _ground_backdrop_host == null or _ground_tiles_host == null or _ground_decals_host == null:
		return

	for child in _ground_backdrop_host.get_children():
		child.free()
	for child in _ground_tiles_host.get_children():
		child.free()
	for child in _ground_decals_host.get_children():
		child.free()

	var viewport_height: float = float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var backdrop_rect := Rect2(
		Vector2(_world_bounds.position.x, _world_bounds.position.y - viewport_height - 160.0),
		Vector2(_world_bounds.size.x, _world_bounds.size.y + viewport_height + 160.0)
	)
	var backdrop := _make_textured_rect(
		"Backdrop",
		backdrop_rect,
		art_resolver.get_terrain_texture("snow_ground")
	)
	_ground_backdrop_host.add_child(backdrop)

	for road_row in _road_rows:
		var rect_row_variant: Variant = road_row.get("rect", {})
		if typeof(rect_row_variant) != TYPE_DICTIONARY:
			continue
		var rect_row := rect_row_variant as Dictionary
		var road_rect := Rect2(
			float(rect_row.get("x", 0.0)),
			float(rect_row.get("y", 0.0)),
			float(rect_row.get("width", 0.0)),
			float(rect_row.get("height", 0.0))
		)
		var is_horizontal: bool = road_rect.size.x >= road_rect.size.y
		var road_texture_id := _road_texture_id(road_row, road_rect, is_horizontal)
		var road_band := _make_textured_rect(
			"%s_%s" % [String(road_row.get("id", "Road")), road_texture_id],
			road_rect,
			art_resolver.get_terrain_texture(road_texture_id)
		)
		_ground_tiles_host.add_child(road_band)

	for snow_field_row in _snow_field_rows:
		var rect_row_variant: Variant = snow_field_row.get("rect", {})
		if typeof(rect_row_variant) != TYPE_DICTIONARY:
			continue
		var rect_row := rect_row_variant as Dictionary
		var snow_rect := Rect2(
			float(rect_row.get("x", 0.0)),
			float(rect_row.get("y", 0.0)),
			float(rect_row.get("width", 0.0)),
			float(rect_row.get("height", 0.0))
		)
		var snow_band := _make_textured_rect(
			"%sSnow" % String(snow_field_row.get("id", "Snow")),
			snow_rect,
			art_resolver.get_terrain_texture("sidewalk_snow")
		)
		_ground_tiles_host.add_child(snow_band)
		var snow_patch := _make_decal_sprite(
			"%sDecal" % String(snow_field_row.get("id", "Snow")),
			snow_rect.position + (snow_rect.size * 0.5),
			art_resolver.get_decal_texture("snow_patch"),
			Vector2.ONE * 2.0
		)
		_ground_decals_host.add_child(snow_patch)

	for block_coord in _active_block_coords:
		var block_origin := world_runtime.get_block_origin(block_coord)
		var block_size := world_runtime.get_block_size()
		var block_rect := Rect2(block_origin, Vector2(block_size.x, block_size.y))
		var wind_streak := _make_decal_sprite(
			"Wind_%d_%d" % [block_coord.x, block_coord.y],
			block_rect.position + Vector2(block_rect.size.x * 0.5, block_rect.size.y * 0.3),
			art_resolver.get_decal_texture("wind_streak"),
			Vector2.ONE * 2.0
		)
		_ground_decals_host.add_child(wind_streak)


func _configure_threats() -> void:
	threat_director.configure(_threat_rows)
	if _threat_host != null:
		for child in _threat_host.get_children():
			child.free()
	_threat_markers.clear()
	for threat_row in _threat_rows:
		var threat_id := String(threat_row.get("id", ""))
		if threat_id.is_empty() or _threat_host == null:
			continue
		var marker := Polygon2D.new()
		marker.name = threat_id
		marker.position = threat_row.get("position", Vector2.ZERO)
		marker.polygon = PackedVector2Array([
			Vector2(0, -14),
			Vector2(14, -2),
			Vector2(10, 12),
			Vector2(-10, 12),
			Vector2(-14, -2)
		])
		marker.color = Color(0.73, 0.76, 0.8, 0.95)
		marker.z_index = 18
		_threat_host.add_child(marker)
		_threat_markers[threat_id] = marker
	_last_threat_snapshot = {
		"threat_state": "idle",
		"contact": false,
		"threats": _threat_rows.duplicate(true),
	}


func _sync_view() -> void:
	if _player_visual != null:
		_player_visual.position = _player_position
		_player_visual.texture = art_resolver.get_player_texture(_player_facing_id, _player_walk_seconds > 0.0, int(floor(_player_walk_seconds * 8.0)))
		_configure_bottom_center_sprite(_player_visual)
		_player_visual.scale = Vector2.ONE * 1.28
		_player_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _camera != null:
		_camera.position = _player_position
		_camera.offset = PORTRAIT_CAMERA_OFFSET
		_camera.limit_left = int(_world_bounds.position.x)
		_camera.limit_top = int(_world_bounds.position.y)
		_camera.limit_right = int(_world_bounds.end.x)
		_camera.limit_bottom = int(_world_bounds.end.y)

	var nearby_building_id := _get_nearby_building_id()
	for building_data in _building_rows:
		var building_id := String(building_data.get("id", ""))
		var marker: Node2D = _building_markers.get(building_id, null)
		if marker == null:
			continue
		marker.position = _resolve_building_position(building_data)
		marker.scale = Vector2.ONE * (1.12 if building_id == nearby_building_id else 1.0)
		marker.modulate = Color(1.0, 1.0, 1.0, 1.0) if building_id == nearby_building_id else Color(0.88, 0.88, 0.88, 1.0)

	if _hint_label != null:
		if not nearby_building_id.is_empty():
			var nearby_building_data := _get_building_data(nearby_building_id)
			var building_name := String(nearby_building_data.get("name", "건물"))
			var entry_briefing := String(nearby_building_data.get("entry_briefing", "")).strip_edges()
			_hint_label.text = "[E] %s 진입" % building_name if entry_briefing.is_empty() else "[E] %s 진입 · %s" % [building_name, entry_briefing]
		else:
			_hint_label.text = "WASD 이동"
	var visited_block_ids := {}
	if run_state != null and run_state.has_method("get_visited_outdoor_block_keys"):
		for block_key in run_state.get_visited_outdoor_block_keys():
			visited_block_ids[String(block_key)] = true
	if _map_overlay != null:
		_map_overlay.configure(world_runtime.world_layout, world_runtime.outdoor_blocks, _get_building_rows(), visited_block_ids, _player_position, run_state)
	_sync_threat_view(_last_threat_snapshot)


func _cache_nodes() -> void:
	_top_ribbon = get_node_or_null("CanvasLayer/TopRibbon") as PanelContainer
	_ground_host = get_node_or_null("Ground") as Node2D
	_ground_backdrop_host = get_node_or_null("Ground/Backdrop") as Node2D
	_ground_tiles_host = get_node_or_null("Ground/Tiles") as Node2D
	_ground_decals_host = get_node_or_null("Ground/Decals") as Node2D
	_player_visual = get_node_or_null("PlayerVisual") as Sprite2D
	_camera = get_node_or_null("WorldCamera") as Camera2D
	_building_host = get_node_or_null("Buildings") as Node2D
	_obstacle_host = get_node_or_null("Obstacles") as Node2D
	_threat_host = get_node_or_null("Threats") as Node2D
	_hint_label = get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/HintLabel") as Label
	_threat_label = get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ThreatLabel") as Label
	_frost_overlay = get_node_or_null("CanvasLayer/FrostOverlay") as ColorRect
	_map_overlay = get_node_or_null("MapOverlay")
	_refresh_threat_markers()


func _bind_ui_buttons() -> void:
	if _map_overlay != null and _map_overlay.has_signal("close_requested") and not _map_overlay.close_requested.is_connected(Callable(self, "hide_map_overlay")):
		_map_overlay.close_requested.connect(Callable(self, "hide_map_overlay"))


func _refresh_threat_markers() -> void:
	_threat_markers.clear()
	if _threat_host == null:
		return
	for child in _threat_host.get_children():
		_threat_markers[child.name] = child


func _sync_threat_view(snapshot: Dictionary) -> void:
	var threat_state := String(snapshot.get("threat_state", "idle"))
	if _threat_label != null:
		_threat_label.text = "추적 중" if threat_state == "chasing" else "주변이 불안하다"
	if _frost_overlay != null and run_state != null:
		var frost_alpha: float = clampf((60.0 - run_state.exposure) / 60.0, 0.0, 0.7)
		_frost_overlay.color = Color(0.78, 0.88, 1.0, frost_alpha)
	var threat_rows_variant: Variant = snapshot.get("threats", [])
	if typeof(threat_rows_variant) != TYPE_ARRAY:
		return
	for threat_variant in threat_rows_variant:
		if typeof(threat_variant) != TYPE_DICTIONARY:
			continue
		var threat_row := threat_variant as Dictionary
		var threat_id := String(threat_row.get("id", ""))
		if threat_id.is_empty():
			continue
		var threat_position_variant: Variant = threat_row.get("position", Vector2.ZERO)
		if typeof(threat_position_variant) != TYPE_VECTOR2:
			continue
		var marker := _threat_markers.get(threat_id, null) as Node2D
		if marker != null:
			marker.position = threat_position_variant
			marker.modulate = Color(1.0, 0.92, 0.92, 1.0) if threat_state == "chasing" else Color(1.0, 1.0, 1.0, 1.0)


func _get_nearby_building_id() -> String:
	var closest_building_id := ""
	var closest_distance := INF
	for building_data in _building_rows:
		var building_id := String(building_data.get("id", ""))
		if building_id.is_empty():
			continue
		var building_position = _building_positions.get(building_id, Vector2.ZERO)
		var distance := _player_position.distance_to(building_position)
		if distance <= ENTER_RADIUS and distance < closest_distance:
			closest_distance = distance
			closest_building_id = building_id
	return closest_building_id


func _get_building_rows() -> Array[Dictionary]:
	if ContentLibrary.has_method("get_building_rows"):
		return ContentLibrary.get_building_rows()

	var default_building := _get_building_data(DEFAULT_BUILDING_ID)
	return [] if default_building.is_empty() else [default_building]


func _get_active_building_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for building_data in _get_building_rows():
		var block_coord_variant: Variant = building_data.get("outdoor_block_coord", {})
		if typeof(block_coord_variant) != TYPE_DICTIONARY:
			rows.append(building_data)
			continue
		var block_coord_row := block_coord_variant as Dictionary
		var block_coord := Vector2i(int(block_coord_row.get("x", 0)), int(block_coord_row.get("y", 0)))
		if _active_block_coords.has(block_coord):
			rows.append(building_data)
	return rows


func _get_building_data(building_id: String) -> Dictionary:
	if not ContentLibrary.has_method("get_building"):
		push_error("ContentLibrary autoload is missing get_building(building_id).")
		return {}

	return ContentLibrary.get_building(building_id)


func _resolve_building_position(building_data: Dictionary) -> Vector2:
	var anchor_id := String(building_data.get("outdoor_anchor_id", ""))
	var anchor_row_variant: Variant = _building_anchor_rows.get(anchor_id, {})
	if typeof(anchor_row_variant) == TYPE_DICTIONARY:
		return _vector2_from_row(anchor_row_variant, DEFAULT_PLAYER_POSITION)
	return _vector2_from_row(building_data.get("outdoor_position", {}), DEFAULT_PLAYER_POSITION)


func _constrain_player_position(target_position: Vector2) -> Vector2:
	var clamped := Vector2(
		clampf(target_position.x, _world_bounds.position.x + 24.0, _world_bounds.end.x - 24.0),
		clampf(target_position.y, _world_bounds.position.y + 24.0, _world_bounds.end.y - 24.0)
	)
	for obstacle_row in _obstacle_rows:
		var rect_row_variant: Variant = obstacle_row.get("rect", {})
		if typeof(rect_row_variant) != TYPE_DICTIONARY:
			continue
		var rect_row := rect_row_variant as Dictionary
		var effective_obstacle_rect := _effective_obstacle_rect(obstacle_row)
		if effective_obstacle_rect.has_point(clamped):
			return _player_position
	return clamped


func _vector2_from_row(source_variant: Variant, fallback: Vector2) -> Vector2:
	if typeof(source_variant) == TYPE_VECTOR2:
		return source_variant
	if typeof(source_variant) != TYPE_DICTIONARY:
		return fallback
	var source_row := source_variant as Dictionary
	return Vector2(
		float(source_row.get("x", fallback.x)),
		float(source_row.get("y", fallback.y))
	)


func _effective_obstacle_rect(obstacle_row: Dictionary) -> Rect2:
	var rect_row_variant: Variant = obstacle_row.get("rect", {})
	if typeof(rect_row_variant) != TYPE_DICTIONARY:
		return Rect2()
	var rect_row := rect_row_variant as Dictionary
	var source_rect := Rect2(
		float(rect_row.get("x", 0.0)),
		float(rect_row.get("y", 0.0)),
		float(rect_row.get("width", 0.0)),
		float(rect_row.get("height", 0.0))
	)
	var kind := String(obstacle_row.get("kind", ""))
	var width_scale := 0.62
	var height_scale := 0.42
	match kind:
		"vehicle":
			width_scale = 0.68
			height_scale = 0.44
		"rubble":
			width_scale = 0.52
			height_scale = 0.34
		"barrier":
			width_scale = 0.72
			height_scale = 0.36
	var collision_size := Vector2(
		maxf(12.0, source_rect.size.x * width_scale),
		maxf(10.0, source_rect.size.y * height_scale)
	)
	var collision_position := Vector2(
		source_rect.position.x + (source_rect.size.x - collision_size.x) * 0.5,
		source_rect.end.y - collision_size.y
	)
	return Rect2(collision_position, collision_size)


func _make_textured_rect(name: String, rect: Rect2, texture: Texture2D) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = name
	polygon.position = rect.position
	polygon.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(rect.size.x, 0.0),
		rect.size,
		Vector2(0.0, rect.size.y)
	])
	polygon.uv = PackedVector2Array([
		Vector2.ZERO,
		Vector2(rect.size.x, 0.0),
		rect.size,
		Vector2(0.0, rect.size.y)
	])
	polygon.texture = texture
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	if texture == null:
		polygon.color = Color(0.2, 0.22, 0.25, 1.0)
	else:
		polygon.color = Color.WHITE
	return polygon


func _make_decal_sprite(name: String, world_position: Vector2, texture: Texture2D, scale_value: Vector2 = Vector2.ONE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = name
	sprite.position = world_position
	sprite.texture = texture
	sprite.centered = true
	sprite.scale = scale_value
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.75)
	sprite.z_index = 4
	return sprite


func _configure_bottom_center_sprite(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	sprite.centered = false
	if sprite.texture == null:
		sprite.offset = Vector2(-16.0, -32.0)
		return
	sprite.offset = Vector2(-sprite.texture.get_width() * 0.5, -float(sprite.texture.get_height()))


func _road_texture_id(road_row: Dictionary, road_rect: Rect2, is_horizontal: bool) -> String:
	var road_id := String(road_row.get("id", ""))
	if road_id == "east_west" and int(road_rect.position.y / 320.0) % 2 == 0:
		return "road_cracked"
	if road_id == "north_south" and int(road_rect.position.x / 360.0) % 2 == 1:
		return "slush_road"
	return "road_lane_h" if is_horizontal else "road_lane_v"


func _obstacle_scale(obstacle_kind: String, obstacle_rect: Rect2) -> float:
	match obstacle_kind:
		"vehicle":
			return 1.35
		"rubble":
			return 1.15 if obstacle_rect.size.x >= 100.0 else 1.05
		_:
			return 1.05


func _resolve_facing_id(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "down" if direction.y > 0.0 else "up"
