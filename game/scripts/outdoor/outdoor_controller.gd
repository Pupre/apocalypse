extends Node2D
class_name OutdoorController

signal state_changed
signal building_entered(building_id: String)

const EXPOSURE_MODEL_SCRIPT := preload("res://scripts/outdoor/exposure_model.gd")
const DEFAULT_BUILDING_ID := "mart_01"
const DEFAULT_PLAYER_POSITION := Vector2(240.0, 360.0)
const ENTER_RADIUS := 72.0

var run_state = null
var exposure_model := EXPOSURE_MODEL_SCRIPT.new()
var _seconds_buffer := 0.0
var _building_id := DEFAULT_BUILDING_ID
var _player_position := DEFAULT_PLAYER_POSITION
var _building_position := Vector2.ZERO
var _player_marker: Polygon2D = null
var _building_marker: Polygon2D = null
var _exposure_label: Label = null
var _hint_label: Label = null
var _building_name := "Building"


func _ready() -> void:
	_cache_nodes()
	_sync_view()


func bind_run_state(value, building_id: String = DEFAULT_BUILDING_ID) -> void:
	run_state = value
	_building_id = building_id
	_seconds_buffer = 0.0
	_player_position = DEFAULT_PLAYER_POSITION
	_cache_nodes()
	_refresh_building_position()
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
	run_state.advance_minutes(full_minutes)
	run_state.exposure = exposure_model.drain(run_state.exposure, float(full_minutes), run_state.fatigue)
	_sync_view()
	state_changed.emit()


func move_player(direction: Vector2, seconds_elapsed: float) -> void:
	if run_state == null or direction == Vector2.ZERO or seconds_elapsed <= 0.0:
		return

	_player_position += direction.normalized() * run_state.move_speed * seconds_elapsed
	_sync_view()
	state_changed.emit()


func try_enter_building(building_id: String) -> void:
	if building_id.is_empty():
		return

	building_entered.emit(building_id)


func _process(delta: float) -> void:
	if run_state == null:
		return

	simulate_seconds(delta)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		move_player(direction, delta)

	if _is_player_near_building() and Input.is_action_just_pressed("ui_accept"):
		try_enter_building(_building_id)


func _is_player_near_building() -> bool:
	return _player_position.distance_to(_building_position) <= ENTER_RADIUS


func _refresh_building_position() -> void:
	var building_data := _get_building_data(_building_id)
	_building_name = String(building_data.get("name", "Building"))
	var outdoor_position: Dictionary = building_data.get("outdoor_position", {})
	if outdoor_position.is_empty():
		_building_position = Vector2(640.0, 360.0)
		return

	_building_position = Vector2(
		float(outdoor_position.get("x", 640.0)),
		float(outdoor_position.get("y", 360.0))
	)


func _sync_view() -> void:
	if _player_marker != null:
		_player_marker.position = _player_position

	if _building_marker != null:
		_building_marker.position = _building_position

	if _exposure_label != null and run_state != null:
		_exposure_label.text = "Exposure: %d" % int(roundf(run_state.exposure))

	if _hint_label != null:
		if _is_player_near_building():
			_hint_label.text = "Press Enter to enter %s" % _building_name
		else:
			_hint_label.text = "Move with WASD"


func _cache_nodes() -> void:
	_player_marker = get_node_or_null("PlayerMarker") as Polygon2D
	_building_marker = get_node_or_null("BuildingMarker") as Polygon2D
	_exposure_label = get_node_or_null("CanvasLayer/StatusPanel/VBox/ExposureLabel") as Label
	_hint_label = get_node_or_null("CanvasLayer/StatusPanel/VBox/HintLabel") as Label


func _get_building_data(building_id: String) -> Dictionary:
	if not ContentLibrary.has_method("get_building"):
		push_error("ContentLibrary autoload is missing get_building(building_id).")
		return {}

	return ContentLibrary.get_building(building_id)
