extends "res://tests/support/test_case.gd"

const MINIMAP_SCRIPT_PATH := "res://scripts/indoor/indoor_minimap.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var minimap_script := load(MINIMAP_SCRIPT_PATH) as Script
	if not assert_true(minimap_script != null, "Missing indoor minimap script: %s" % MINIMAP_SCRIPT_PATH):
		return

	var minimap = minimap_script.new() as Control
	if not assert_true(minimap != null, "Indoor minimap should instantiate as a control."):
		return

	root.add_child(minimap)
	minimap.custom_minimum_size = Vector2(200, 132)
	minimap.size = Vector2(200, 132)
	var snapshot := {
		"current_zone_id": "staff_corridor_gate",
		"current_floor_id": "floor_1",
		"nodes": [
			{
				"id": "mart_entrance",
				"label": "정문 진입부",
				"state": "visited",
				"floor_id": "floor_1",
				"map_position": [0, 1],
			},
			{
				"id": "staff_corridor_gate",
				"label": "직원 출입문",
				"state": "current",
				"floor_id": "floor_1",
				"map_position": [2, 1],
			},
			{
				"id": "stair_landing",
				"label": "잠김",
				"state": "locked",
				"floor_id": "floor_2",
				"map_position": [3, 1],
			},
		],
		"edges": [
			{"from": "mart_entrance", "to": "staff_corridor_gate", "locked": false},
			{"from": "staff_corridor_gate", "to": "stair_landing", "locked": true},
		],
	}
	minimap.set_snapshot(snapshot)
	await process_frame

	var current_node := _find_node(snapshot, "staff_corridor_gate")
	if not assert_true(current_node != null, "Indoor minimap should render the current zone node."):
		minimap.free()
		return

	var current_map_point := _map_point_for_node(current_node)
	var expected_center: Vector2 = minimap.size * 0.5
	assert_true(
		current_map_point.distance_to(expected_center) <= 12.0,
		"Indoor minimap should keep the current room centered even in the compact inline-card viewport."
	)

	minimap.free()
	pass_test("INDOOR_MINIMAP_OK")


func _find_node(snapshot: Dictionary, expected_id: String) -> Dictionary:
	var nodes: Array = snapshot.get("nodes", [])
	for node_variant in nodes:
		if typeof(node_variant) != TYPE_DICTIONARY:
			continue
		var node := node_variant as Dictionary
		if String(node.get("id", "")) == expected_id:
			return node
	return {}


func _map_point_for_node(node: Dictionary) -> Vector2:
	var grid_position: Array = node.get("map_position", [])
	var x := 0.0
	var y := 0.0
	if grid_position.size() >= 2:
		x = float(grid_position[0])
		y = float(grid_position[1])
	return Vector2(24.0 + x * 84.0, 24.0 + y * 56.0)
