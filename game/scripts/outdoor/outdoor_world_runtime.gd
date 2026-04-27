extends RefCounted
class_name OutdoorWorldRuntime

var world_layout: Dictionary = {}
var outdoor_blocks: Dictionary = {}


func configure(layout: Dictionary, block_rows: Dictionary) -> void:
	world_layout = layout.duplicate(true)
	outdoor_blocks = block_rows.duplicate(true)


func get_block_size() -> Vector2i:
	var block_size := world_layout.get("block_size", {}) as Dictionary
	return Vector2i(int(block_size.get("width", 0)), int(block_size.get("height", 0)))


func get_city_block_size() -> Vector2i:
	var city_blocks := world_layout.get("city_blocks", {}) as Dictionary
	return Vector2i(int(city_blocks.get("width", 0)), int(city_blocks.get("height", 0)))


func get_stream_radius_blocks() -> int:
	return int(world_layout.get("stream_radius_blocks", 1))


func get_world_bounds() -> Rect2:
	var block_size := get_block_size()
	var city_blocks := get_city_block_size()
	return Rect2(0.0, 0.0, float(block_size.x * city_blocks.x), float(block_size.y * city_blocks.y))


func world_to_block_coord(world_position: Vector2) -> Vector2i:
	var block_size := get_block_size()
	if block_size.x <= 0 or block_size.y <= 0:
		return Vector2i.ZERO
	return Vector2i(
		int(floor(world_position.x / float(block_size.x))),
		int(floor(world_position.y / float(block_size.y)))
	)


func get_block_origin(block_coord: Vector2i) -> Vector2:
	var block_size := get_block_size()
	return Vector2(float(block_coord.x * block_size.x), float(block_coord.y * block_size.y))


func get_active_block_coords(center_block: Vector2i) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	var stream_radius := get_stream_radius_blocks()
	var city_size := get_city_block_size()
	var window_size := stream_radius * 2 + 1
	var min_x := center_block.x - stream_radius
	var min_y := center_block.y - stream_radius
	var max_x := center_block.x + stream_radius
	var max_y := center_block.y + stream_radius
	if min_x < 0:
		max_x += -min_x
		min_x = 0
	if min_y < 0:
		max_y += -min_y
		min_y = 0
	if max_x >= city_size.x:
		var overflow_x := max_x - city_size.x + 1
		min_x = max(0, min_x - overflow_x)
		max_x = city_size.x - 1
	if max_y >= city_size.y:
		var overflow_y := max_y - city_size.y + 1
		min_y = max(0, min_y - overflow_y)
		max_y = city_size.y - 1
	while max_x - min_x + 1 < window_size and max_x + 1 < city_size.x:
		max_x += 1
	while max_x - min_x + 1 < window_size and min_x > 0:
		min_x -= 1
	while max_y - min_y + 1 < window_size and max_y + 1 < city_size.y:
		max_y += 1
	while max_y - min_y + 1 < window_size and min_y > 0:
		min_y -= 1
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			coords.append(Vector2i(x, y))
	return coords


func get_block_row(block_coord: Vector2i) -> Dictionary:
	return (outdoor_blocks.get(_block_key(block_coord), {}) as Dictionary).duplicate(true)


func resolve_anchor_world_position(block_coord: Vector2i, anchor_id: String) -> Vector2:
	var block_row := get_block_row(block_coord)
	var anchors := block_row.get("building_anchors", {}) as Dictionary
	var local_anchor := anchors.get(anchor_id, {}) as Dictionary
	var block_origin := get_block_origin(block_coord)
	return block_origin + Vector2(float(local_anchor.get("x", 0.0)), float(local_anchor.get("y", 0.0)))


func _block_key(block_coord: Vector2i) -> String:
	return "%d_%d" % [block_coord.x, block_coord.y]
