extends Control

const GRID_SPACING := Vector2(84, 56)
const MAP_MARGIN := Vector2(24, 24)
const FLOOR_SEPARATION := 84.0
const EDGE_COLOR := Color(0.6, 0.6, 0.6, 0.6)
const LOCKED_EDGE_COLOR := Color(0.4, 0.4, 0.4, 0.35)
const CURRENT_COLOR := Color(1.0, 0.91, 0.45, 1.0)
const VISITED_COLOR := Color(0.92, 0.92, 0.92, 1.0)
const UNKNOWN_COLOR := Color(0.7, 0.7, 0.7, 1.0)
const LOCKED_COLOR := Color(0.8, 0.5, 0.5, 1.0)

var _snapshot: Dictionary = {
	"nodes": [],
	"edges": [],
}


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_rebuild_nodes()
	queue_redraw()


func _rebuild_nodes() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	for node_variant in _snapshot.get("nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue

		var node := node_variant as Dictionary
		var label := Label.new()
		label.text = String(node.get("label", "?"))
		label.position = _point_for_node(node) - Vector2(0, 10)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", _node_color(node))
		add_child(label)


func _draw() -> void:
	var node_points := {}
	for node_variant in _snapshot.get("nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node := node_variant as Dictionary
		node_points[String(node.get("id", ""))] = _point_for_node(node)

	for edge_variant in _snapshot.get("edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue

		var edge := edge_variant as Dictionary
		var from_id := String(edge.get("from", ""))
		var to_id := String(edge.get("to", ""))
		if not node_points.has(from_id) or not node_points.has(to_id):
			continue

		draw_line(
			node_points[from_id],
			node_points[to_id],
			_edge_color(edge, from_id, to_id),
			2.0
		)

	for node_variant in _snapshot.get("nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node := node_variant as Dictionary
		var center := _point_for_node(node)
		draw_circle(center, 8.0, _node_color(node))


func _point_for_node(node: Dictionary) -> Vector2:
	return _raw_point_for_node(node) + _display_offset()


func _raw_point_for_node(node: Dictionary) -> Vector2:
	var grid_position: Array = node.get("map_position", [])
	var x := 0.0
	var y := 0.0
	if grid_position.size() >= 2:
		x = float(grid_position[0])
		y = float(grid_position[1])

	var point := MAP_MARGIN + Vector2(x * GRID_SPACING.x, y * GRID_SPACING.y)
	var current_floor_id := String(_snapshot.get("current_floor_id", ""))
	var node_floor_id := String(node.get("floor_id", ""))
	if not current_floor_id.is_empty() and not node_floor_id.is_empty() and node_floor_id != current_floor_id:
		var floor_delta := _floor_index(node_floor_id) - _floor_index(current_floor_id)
		point.y += floor_delta * FLOOR_SEPARATION

	return point


func _display_offset() -> Vector2:
	var current_node := _current_node()
	if current_node.is_empty():
		return Vector2.ZERO

	var viewport_size := size
	if viewport_size == Vector2.ZERO:
		viewport_size = custom_minimum_size
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(280, 220)

	return (viewport_size * 0.5) - _raw_point_for_node(current_node)


func _font_color_for_state(state: String) -> Color:
	match state:
		"current":
			return CURRENT_COLOR
		"visited":
			return VISITED_COLOR
		"locked":
			return LOCKED_COLOR
		_:
			return UNKNOWN_COLOR


func _node_color(node: Dictionary) -> Color:
	var color := _font_color_for_state(String(node.get("state", "")))
	var current_floor_id := String(_snapshot.get("current_floor_id", ""))
	var node_floor_id := String(node.get("floor_id", ""))
	if not current_floor_id.is_empty() and not node_floor_id.is_empty() and node_floor_id != current_floor_id:
		color.a *= 0.45
	return color


func _edge_color(edge: Dictionary, from_id: String, to_id: String) -> Color:
	var color := LOCKED_EDGE_COLOR if bool(edge.get("locked", false)) else EDGE_COLOR
	var current_floor_id := String(_snapshot.get("current_floor_id", ""))
	if current_floor_id.is_empty():
		return color

	var from_floor_id := _node_floor_id(from_id)
	var to_floor_id := _node_floor_id(to_id)
	if (not from_floor_id.is_empty() and from_floor_id != current_floor_id) or (not to_floor_id.is_empty() and to_floor_id != current_floor_id):
		color.a *= 0.45
	return color


func _current_node() -> Dictionary:
	var current_zone_id := String(_snapshot.get("current_zone_id", ""))
	for node_variant in _snapshot.get("nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node := node_variant as Dictionary
		if String(node.get("id", "")) == current_zone_id or String(node.get("state", "")) == "current":
			return node
	return {}


func _node_floor_id(node_id: String) -> String:
	for node_variant in _snapshot.get("nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node := node_variant as Dictionary
		if String(node.get("id", "")) == node_id:
			return String(node.get("floor_id", ""))
	return ""


func _floor_index(floor_id: String) -> int:
	var parts := floor_id.split("_")
	if parts.size() == 2 and String(parts[1]).is_valid_int():
		return int(parts[1])
	return 0
