extends Control

const GRID_SPACING := Vector2(84, 56)
const MAP_MARGIN := Vector2(24, 24)
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
		label.add_theme_color_override("font_color", _font_color_for_state(String(node.get("state", ""))))
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
			LOCKED_EDGE_COLOR if bool(edge.get("locked", false)) else EDGE_COLOR,
			2.0
		)

	for node_variant in _snapshot.get("nodes", []):
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node := node_variant as Dictionary
		var center := _point_for_node(node)
		draw_circle(center, 8.0, _font_color_for_state(String(node.get("state", ""))))


func _point_for_node(node: Dictionary) -> Vector2:
	var grid_position: Array = node.get("map_position", [])
	var x := 0.0
	var y := 0.0
	if grid_position.size() >= 2:
		x = float(grid_position[0])
		y = float(grid_position[1])

	return MAP_MARGIN + Vector2(x * GRID_SPACING.x, y * GRID_SPACING.y)


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
