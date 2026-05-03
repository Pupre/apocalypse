extends Control
class_name OutdoorMapView

signal building_selected(building_id: String)

const BASE_COLOR := Color(0.05, 0.07, 0.09, 0.96)
const ROAD_COLOR := Color(0.30, 0.34, 0.39, 0.95)
const OBSTACLE_COLOR := Color(0.43, 0.47, 0.53, 0.94)
const PLAYER_COLOR := Color(0.95, 0.84, 0.42, 1.0)
const FOG_COLOR := Color(0.01, 0.02, 0.03, 0.94)
const FRAME_COLOR := Color(1.0, 1.0, 1.0, 0.08)
const DISTRICT_COLORS := {
	"north_market": Color(0.18, 0.32, 0.25, 0.88),
	"east_medical": Color(0.30, 0.22, 0.28, 0.88),
	"south_residential": Color(0.31, 0.27, 0.19, 0.88),
	"south_industrial": Color(0.28, 0.30, 0.33, 0.88),
	"west_shelter": Color(0.19, 0.27, 0.32, 0.88),
	"central_transfer": Color(0.30, 0.25, 0.18, 0.88),
	"mixed_edge": Color(0.18, 0.21, 0.24, 0.88),
}
const BUILDING_COLORS := {
	"medical": Color(0.61, 0.43, 0.46, 1.0),
	"office": Color(0.38, 0.51, 0.68, 1.0),
	"residential": Color(0.67, 0.57, 0.39, 1.0),
	"food_service": Color(0.73, 0.51, 0.36, 1.0),
	"industrial": Color(0.57, 0.57, 0.63, 1.0),
	"security": Color(0.56, 0.60, 0.74, 1.0),
	"retail": Color(0.46, 0.59, 0.45, 1.0),
}
const DEFAULT_DISTRICT_COLOR := Color(0.12, 0.15, 0.19, 0.88)
const DEFAULT_BUILDING_COLOR := Color(0.62, 0.66, 0.70, 1.0)
const DEFAULT_VISIBLE_WORLD_HEIGHT := 4600.0

var _world_layout: Dictionary = {}
var _block_rows: Dictionary = {}
var _building_rows: Array = []
var _visited_block_ids: Dictionary = {}
var _player_position := Vector2.ZERO
var _view_center_world := Vector2.ZERO
var _view_initialized := false
var _dragging := false
var _drag_start_screen := Vector2.ZERO
var _drag_last_screen := Vector2.ZERO
var _drag_distance := 0.0


func configure(world_layout: Dictionary, block_rows: Dictionary, building_rows: Array, visited_block_ids: Dictionary, player_position: Vector2) -> void:
	_world_layout = world_layout.duplicate(true)
	_block_rows = block_rows.duplicate(true)
	_building_rows = building_rows.duplicate(true)
	_visited_block_ids = visited_block_ids.duplicate(true)
	_player_position = player_position
	if not _view_initialized:
		_view_center_world = player_position
		_view_initialized = true
	queue_redraw()


func build_snapshot() -> Dictionary:
	var world_bounds := _world_bounds()
	var roads: Array[Dictionary] = []
	var obstacles: Array[Dictionary] = []
	var fog_blocks: Array[Dictionary] = []
	var district_blocks: Array[Dictionary] = []
	var block_size := _block_size()
	var city_blocks := _city_blocks()

	for y in range(city_blocks.y):
		for x in range(city_blocks.x):
			var block_coord := Vector2i(x, y)
			var block_key := _block_key(block_coord)
			var block_rect := Rect2(_block_origin(block_coord), Vector2(block_size.x, block_size.y))
			var is_visible := _is_block_visible(block_coord)
			if not is_visible:
				fog_blocks.append({
					"key": block_key,
					"coord": block_coord,
					"rect": _rect_to_row(block_rect),
				})
			var block_row_variant: Variant = _block_rows.get(block_key, {})
			if typeof(block_row_variant) != TYPE_DICTIONARY:
				continue
			var block_row := block_row_variant as Dictionary
			if is_visible:
				district_blocks.append({
					"key": block_key,
					"coord": block_coord,
					"district_id": String(block_row.get("district_id", "mixed_edge")),
					"layout_id": String(block_row.get("layout_id", "")),
					"rect": _rect_to_row(block_rect),
				})
			for road_variant in block_row.get("roads", []):
				if typeof(road_variant) != TYPE_DICTIONARY:
					continue
				var road := road_variant as Dictionary
				roads.append({
					"id": String(road.get("id", "")),
					"state": "visible" if is_visible else "hidden",
					"rect": _offset_rect_row(road.get("rect", {}), block_rect.position),
				})
			for obstacle_variant in block_row.get("obstacles", []):
				if typeof(obstacle_variant) != TYPE_DICTIONARY:
					continue
				var obstacle := obstacle_variant as Dictionary
				obstacles.append({
					"kind": String(obstacle.get("kind", "")),
					"state": "visible" if is_visible else "hidden",
					"rect": _offset_rect_row(obstacle.get("rect", {}), block_rect.position),
				})

	var buildings: Array[Dictionary] = []
	for building_variant in _building_rows:
		if typeof(building_variant) != TYPE_DICTIONARY:
			continue
		var building := building_variant as Dictionary
		var block_coord_row := building.get("outdoor_block_coord", {}) as Dictionary
		var block_coord := Vector2i(int(block_coord_row.get("x", 0)), int(block_coord_row.get("y", 0)))
		var position := _vector2_from_row(building.get("outdoor_position", {}))
		buildings.append({
			"id": String(building.get("id", "")),
			"name": String(building.get("name", "")),
			"category": String(building.get("category", "")),
			"position": position,
			"state": "visible" if _is_block_visible(block_coord) else "hidden",
			"block_key": _block_key(block_coord),
		})

	return {
		"world_rect": _rect_to_row(world_bounds),
		"view_rect": _rect_to_row(_visible_world_rect()),
		"view_center": _view_center_world,
		"player_position": _player_position,
		"roads": roads,
		"obstacles": obstacles,
		"buildings": buildings,
		"fog_blocks": fog_blocks,
		"district_blocks": district_blocks,
	}


func pan_by(screen_delta: Vector2) -> void:
	if screen_delta == Vector2.ZERO:
		return
	_view_center_world = _clamp_view_center(_view_center_world - _screen_delta_to_world(screen_delta))
	queue_redraw()


func focus_on_world_position(world_position: Vector2) -> void:
	_view_center_world = _clamp_view_center(world_position)
	queue_redraw()


func pick_building_id_at_world(world_point: Vector2) -> String:
	var best_id := ""
	var best_distance := INF
	for building_variant in build_snapshot().get("buildings", []):
		if typeof(building_variant) != TYPE_DICTIONARY:
			continue
		var building := building_variant as Dictionary
		if String(building.get("state", "")) != "visible":
			continue
		var building_position := building.get("position", Vector2.ZERO) as Vector2
		var distance := world_point.distance_to(building_position)
		if distance <= 88.0 and distance < best_distance:
			best_distance = distance
			best_id = String(building.get("id", ""))
	return best_id


func _draw() -> void:
	var snapshot := build_snapshot()
	draw_rect(Rect2(Vector2.ZERO, size), BASE_COLOR, true)
	var visible_world_rect := _visible_world_rect()

	for fog_variant in snapshot.get("fog_blocks", []):
		if typeof(fog_variant) != TYPE_DICTIONARY:
			continue
		var fog_row := fog_variant as Dictionary
		var fog_rect := _row_to_rect(fog_row.get("rect", {}))
		draw_rect(_world_rect_to_local(fog_rect, visible_world_rect), FOG_COLOR, true)

	for district_variant in snapshot.get("district_blocks", []):
		if typeof(district_variant) != TYPE_DICTIONARY:
			continue
		var district_row := district_variant as Dictionary
		var district_rect := _row_to_rect(district_row.get("rect", {}))
		var district_local_rect := _world_rect_to_local(district_rect, visible_world_rect)
		draw_rect(district_local_rect, _district_color(String(district_row.get("district_id", ""))), true)
		draw_rect(district_local_rect, FRAME_COLOR, false, 1.0)

	for road_variant in snapshot.get("roads", []):
		if typeof(road_variant) != TYPE_DICTIONARY:
			continue
		var road := road_variant as Dictionary
		if String(road.get("state", "")) != "visible":
			continue
		draw_rect(_world_rect_to_local(_row_to_rect(road.get("rect", {})), visible_world_rect), ROAD_COLOR, true)

	for obstacle_variant in snapshot.get("obstacles", []):
		if typeof(obstacle_variant) != TYPE_DICTIONARY:
			continue
		var obstacle := obstacle_variant as Dictionary
		if String(obstacle.get("state", "")) != "visible":
			continue
		draw_rect(_world_rect_to_local(_row_to_rect(obstacle.get("rect", {})), visible_world_rect), OBSTACLE_COLOR, true)

	for building_variant in snapshot.get("buildings", []):
		if typeof(building_variant) != TYPE_DICTIONARY:
			continue
		var building := building_variant as Dictionary
		if String(building.get("state", "")) != "visible":
			continue
		var local_position := _world_point_to_local(building.get("position", Vector2.ZERO) as Vector2, visible_world_rect)
		var building_rect := Rect2(local_position - Vector2(10.0, 8.0), Vector2(20.0, 16.0))
		draw_rect(building_rect, _building_color(String(building.get("category", ""))), true)
		draw_rect(building_rect, FRAME_COLOR, false, 1.0)

	var player_local := _world_point_to_local(_player_position, visible_world_rect)
	draw_circle(player_local, 6.0, PLAYER_COLOR)
	draw_rect(Rect2(Vector2.ZERO, size), FRAME_COLOR, false, 1.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_start_screen = event.position
			_drag_last_screen = event.position
			_drag_distance = 0.0
		else:
			var released_position: Vector2 = event.position
			var total_drag := _drag_distance
			_dragging = false
			if total_drag <= 6.0:
				var building_id := pick_building_id_at_world(_local_to_world_point(released_position, _visible_world_rect()))
				if not building_id.is_empty():
					building_selected.emit(building_id)
	elif event is InputEventMouseMotion and _dragging:
		var delta: Vector2 = event.position - _drag_last_screen
		_drag_last_screen = event.position
		_drag_distance += delta.length()
		pan_by(delta)
	elif event is InputEventScreenDrag:
		pan_by(event.relative)


func _screen_delta_to_world(screen_delta: Vector2) -> Vector2:
	var visible_world_rect := _visible_world_rect()
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ZERO
	return Vector2(
		(screen_delta.x / size.x) * visible_world_rect.size.x,
		(screen_delta.y / size.y) * visible_world_rect.size.y
	)


func _visible_world_rect() -> Rect2:
	var world_bounds := _world_bounds()
	var viewport_size := size
	if viewport_size == Vector2.ZERO:
		viewport_size = custom_minimum_size
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(640.0, 960.0)
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var visible_height := DEFAULT_VISIBLE_WORLD_HEIGHT
	var visible_width := visible_height * aspect
	var origin := _view_center_world - Vector2(visible_width * 0.5, visible_height * 0.5)
	var rect := Rect2(origin, Vector2(visible_width, visible_height))
	if rect.size.x >= world_bounds.size.x:
		rect.position.x = world_bounds.position.x
		rect.size.x = world_bounds.size.x
	else:
		rect.position.x = clampf(rect.position.x, world_bounds.position.x, world_bounds.end.x - rect.size.x)
	if rect.size.y >= world_bounds.size.y:
		rect.position.y = world_bounds.position.y
		rect.size.y = world_bounds.size.y
	else:
		rect.position.y = clampf(rect.position.y, world_bounds.position.y, world_bounds.end.y - rect.size.y)
	return rect


func _world_point_to_local(world_point: Vector2, visible_world_rect: Rect2) -> Vector2:
	var relative := world_point - visible_world_rect.position
	return Vector2(
		(relative.x / maxf(visible_world_rect.size.x, 1.0)) * size.x,
		(relative.y / maxf(visible_world_rect.size.y, 1.0)) * size.y
	)


func _local_to_world_point(local_point: Vector2, visible_world_rect: Rect2) -> Vector2:
	return visible_world_rect.position + Vector2(
		(local_point.x / maxf(size.x, 1.0)) * visible_world_rect.size.x,
		(local_point.y / maxf(size.y, 1.0)) * visible_world_rect.size.y
	)


func _world_rect_to_local(world_rect: Rect2, visible_world_rect: Rect2) -> Rect2:
	var top_left := _world_point_to_local(world_rect.position, visible_world_rect)
	var bottom_right := _world_point_to_local(world_rect.end, visible_world_rect)
	return Rect2(top_left, bottom_right - top_left).abs()


func _is_block_visible(block_coord: Vector2i) -> bool:
	return bool(_visited_block_ids.get(_block_key(block_coord), false))


func _world_bounds() -> Rect2:
	var block_size := _block_size()
	var city_blocks := _city_blocks()
	return Rect2(0.0, 0.0, float(block_size.x * city_blocks.x), float(block_size.y * city_blocks.y))


func _block_size() -> Vector2i:
	var block_size := _world_layout.get("block_size", {}) as Dictionary
	return Vector2i(int(block_size.get("width", 0)), int(block_size.get("height", 0)))


func _city_blocks() -> Vector2i:
	var city_blocks := _world_layout.get("city_blocks", {}) as Dictionary
	return Vector2i(int(city_blocks.get("width", 0)), int(city_blocks.get("height", 0)))


func _block_origin(block_coord: Vector2i) -> Vector2:
	var block_size := _block_size()
	return Vector2(float(block_coord.x * block_size.x), float(block_coord.y * block_size.y))


func _block_key(block_coord: Vector2i) -> String:
	return "%d_%d" % [block_coord.x, block_coord.y]


func _vector2_from_row(row_variant: Variant) -> Vector2:
	if typeof(row_variant) != TYPE_DICTIONARY:
		return Vector2.ZERO
	var row := row_variant as Dictionary
	return Vector2(float(row.get("x", 0.0)), float(row.get("y", 0.0)))


func _offset_rect_row(rect_variant: Variant, block_origin: Vector2) -> Dictionary:
	if typeof(rect_variant) != TYPE_DICTIONARY:
		return {}
	var rect_row := rect_variant as Dictionary
	return {
		"x": float(rect_row.get("x", 0.0)) + block_origin.x,
		"y": float(rect_row.get("y", 0.0)) + block_origin.y,
		"width": float(rect_row.get("width", 0.0)),
		"height": float(rect_row.get("height", 0.0)),
	}


func _row_to_rect(rect_variant: Variant) -> Rect2:
	if typeof(rect_variant) != TYPE_DICTIONARY:
		return Rect2()
	var rect_row := rect_variant as Dictionary
	return Rect2(
		float(rect_row.get("x", 0.0)),
		float(rect_row.get("y", 0.0)),
		float(rect_row.get("width", 0.0)),
		float(rect_row.get("height", 0.0))
	)


func _rect_to_row(rect: Rect2) -> Dictionary:
	return {
		"x": rect.position.x,
		"y": rect.position.y,
		"width": rect.size.x,
		"height": rect.size.y,
	}


func _clamp_view_center(world_position: Vector2) -> Vector2:
	var visible_rect := _visible_world_rect()
	var world_bounds := _world_bounds()
	var half_size := visible_rect.size * 0.5
	return Vector2(
		clampf(world_position.x, world_bounds.position.x + half_size.x, world_bounds.end.x - half_size.x),
		clampf(world_position.y, world_bounds.position.y + half_size.y, world_bounds.end.y - half_size.y)
	)


func _building_color(category: String) -> Color:
	return BUILDING_COLORS.get(category, DEFAULT_BUILDING_COLOR)


func _district_color(district_id: String) -> Color:
	return DISTRICT_COLORS.get(district_id, DEFAULT_DISTRICT_COLOR)
