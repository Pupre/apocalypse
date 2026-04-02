extends Node2D
class_name OutdoorController

signal state_changed
signal building_entered(building_id: String)

const EXPOSURE_MODEL_SCRIPT := preload("res://scripts/outdoor/exposure_model.gd")
const DEFAULT_BUILDING_ID := "mart_01"
const DEFAULT_PLAYER_POSITION := Vector2(240.0, 360.0)
const ENTER_RADIUS := 72.0
const WORLD_BOUNDS := Rect2(0.0, 0.0, 1200.0, 1092.0)
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
}
const OBSTACLE_RECTS := [
	Rect2(462.0, 438.0, 48.0, 48.0),
	Rect2(758.0, 446.0, 48.0, 48.0),
]

var run_state = null
var exposure_model := EXPOSURE_MODEL_SCRIPT.new()
var _seconds_buffer := 0.0
var _player_position := DEFAULT_PLAYER_POSITION
var _building_rows: Array[Dictionary] = []
var _building_positions: Dictionary = {}
var _player_sprite: Polygon2D = null
var _camera: Camera2D = null
var _ground_host: Node2D = null
var _building_host: Node2D = null
var _obstacle_host: Node2D = null
var _building_markers: Dictionary = {}
var _exposure_label: Label = null
var _hint_label: Label = null


func _ready() -> void:
	_cache_nodes()
	_refresh_buildings()
	_refresh_obstacles()
	_sync_view()


func bind_run_state(value, building_id: String = DEFAULT_BUILDING_ID, player_position = null) -> void:
	run_state = value
	_seconds_buffer = 0.0
	_player_position = player_position if typeof(player_position) == TYPE_VECTOR2 else DEFAULT_PLAYER_POSITION
	_cache_nodes()
	_refresh_buildings()
	_refresh_obstacles()
	_sync_view()
	state_changed.emit()


func simulate_seconds(seconds_elapsed: float) -> void:
	if run_state == null or seconds_elapsed <= 0.0:
		return

	_seconds_buffer += seconds_elapsed
	var full_minutes := int(floor(_seconds_buffer))
	if full_minutes <= 0:
		return

	_seconds_buffer -= float(full_minutes)
	run_state.advance_minutes(full_minutes, "outdoor")
	run_state.exposure = exposure_model.drain(run_state.exposure, float(full_minutes), run_state.fatigue)
	_sync_view()
	state_changed.emit()


func move_player(direction: Vector2, seconds_elapsed: float) -> void:
	if run_state == null or direction == Vector2.ZERO or seconds_elapsed <= 0.0:
		return

	var effective_move_speed: float = float(run_state.move_speed)
	if run_state.has_method("get_outdoor_move_speed"):
		effective_move_speed = float(run_state.get_outdoor_move_speed())

	var target_position := _player_position + direction.normalized() * effective_move_speed * seconds_elapsed
	_player_position = _constrain_player_position(target_position)
	_sync_view()
	state_changed.emit()


func try_enter_building(building_id: String) -> bool:
	if building_id.is_empty() or not _is_player_near_building(building_id):
		return false

	building_entered.emit(building_id)
	return true


func get_player_position() -> Vector2:
	return _player_position


func _process(delta: float) -> void:
	if run_state == null:
		return

	simulate_seconds(delta)
	var direction := Input.get_vector(MOVE_LEFT_ACTION, MOVE_RIGHT_ACTION, MOVE_UP_ACTION, MOVE_DOWN_ACTION)
	if direction != Vector2.ZERO:
		move_player(direction, delta)

	var nearby_building_id := _get_nearby_building_id()
	if not nearby_building_id.is_empty() and Input.is_action_just_pressed(ENTER_BUILDING_ACTION):
		try_enter_building(nearby_building_id)


func _is_player_near_building(building_id: String) -> bool:
	var building_position_variant = _building_positions.get(building_id, null)
	if typeof(building_position_variant) != TYPE_VECTOR2:
		return false

	return _player_position.distance_to(building_position_variant) <= ENTER_RADIUS


func _refresh_buildings() -> void:
	_building_rows = _get_building_rows()
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

		var base := Polygon2D.new()
		base.name = "Base"
		base.polygon = [
			Vector2(-42, -14),
			Vector2(42, -14),
			Vector2(42, 14),
			Vector2(-42, 14),
		]
		base.color = _building_color(String(building_data.get("category", "")))
		marker_root.add_child(base)

		var door := Polygon2D.new()
		door.name = "Door"
		door.position = Vector2(0, 16)
		door.polygon = [
			Vector2(-10, -6),
			Vector2(10, -6),
			Vector2(10, 6),
			Vector2(-10, 6),
		]
		door.color = Color(0.96, 0.92, 0.76, 0.95)
		marker_root.add_child(door)

		var label := Label.new()
		label.name = "Label"
		label.text = BUILDING_LABELS.get(building_id, String(building_data.get("name", "건물")))
		label.position = Vector2(-36, -34)
		label.size = Vector2(72, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		marker_root.add_child(label)

		_building_host.add_child(marker_root)
		_building_markers[building_id] = marker_root


func _refresh_obstacles() -> void:
	if _obstacle_host == null:
		return

	for child in _obstacle_host.get_children():
		var obstacle := child as CanvasItem
		if obstacle != null:
			obstacle.modulate = Color(0.9, 0.9, 0.9, 1.0)


func _sync_view() -> void:
	if _player_sprite != null:
		_player_sprite.position = _player_position
	if _camera != null:
		_camera.position = _player_position

	var nearby_building_id := _get_nearby_building_id()
	for building_data in _building_rows:
		var building_id := String(building_data.get("id", ""))
		var marker: Node2D = _building_markers.get(building_id, null)
		if marker == null:
			continue
		marker.position = _resolve_building_position(building_data)
		marker.scale = Vector2.ONE * (1.12 if building_id == nearby_building_id else 1.0)
		marker.modulate = Color(1.0, 1.0, 1.0, 1.0) if building_id == nearby_building_id else Color(0.88, 0.88, 0.88, 1.0)

	if _exposure_label != null and run_state != null:
		_exposure_label.text = "노출: %d" % int(roundf(run_state.exposure))

	if _hint_label != null:
		if not nearby_building_id.is_empty():
			var nearby_building_data := _get_building_data(nearby_building_id)
			_hint_label.text = "E 키로 %s 진입" % String(nearby_building_data.get("name", "건물"))
		else:
			_hint_label.text = "WASD로 이동"


func _cache_nodes() -> void:
	_ground_host = get_node_or_null("Ground") as Node2D
	_player_sprite = get_node_or_null("PlayerSprite") as Polygon2D
	_camera = get_node_or_null("WorldCamera") as Camera2D
	_building_host = get_node_or_null("Buildings") as Node2D
	_obstacle_host = get_node_or_null("Obstacles") as Node2D
	_exposure_label = get_node_or_null("CanvasLayer/StatusPanel/VBox/ExposureLabel") as Label
	_hint_label = get_node_or_null("CanvasLayer/StatusPanel/VBox/HintLabel") as Label


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


func _get_building_data(building_id: String) -> Dictionary:
	if not ContentLibrary.has_method("get_building"):
		push_error("ContentLibrary autoload is missing get_building(building_id).")
		return {}

	return ContentLibrary.get_building(building_id)


func _resolve_building_position(building_data: Dictionary) -> Vector2:
	var outdoor_position: Dictionary = building_data.get("outdoor_position", {})
	return Vector2(
		float(outdoor_position.get("x", 640.0)),
		float(outdoor_position.get("y", 360.0))
	)


func _building_color(category: String) -> Color:
	match category:
		"medical":
			return Color(0.56, 0.37, 0.37, 0.92)
		"office":
			return Color(0.36, 0.47, 0.63, 0.92)
		"residential":
			return Color(0.63, 0.53, 0.35, 0.92)
		_:
			return Color(0.41, 0.49, 0.38, 0.92)


func _constrain_player_position(target_position: Vector2) -> Vector2:
	var clamped := Vector2(
		clampf(target_position.x, WORLD_BOUNDS.position.x + 24.0, WORLD_BOUNDS.end.x - 24.0),
		clampf(target_position.y, WORLD_BOUNDS.position.y + 24.0, WORLD_BOUNDS.end.y - 24.0)
	)
	for obstacle_rect in OBSTACLE_RECTS:
		if obstacle_rect.has_point(clamped):
			return _player_position
	return clamped
