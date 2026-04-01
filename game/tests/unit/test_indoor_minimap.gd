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
	minimap.custom_minimum_size = Vector2(280, 220)
	minimap.size = Vector2(280, 220)
	minimap.set_snapshot({
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
	})

	var current_label := _find_label(minimap, "직원 출입문")
	if not assert_true(current_label != null, "Indoor minimap should render a label for the current zone."):
		minimap.free()
		return

	assert_true(
		absf(current_label.position.x - 140.0) <= 24.0 and absf(current_label.position.y - 100.0) <= 24.0,
		"Indoor minimap should keep the current zone centered within the available viewport."
	)

	minimap.free()
	pass_test("INDOOR_MINIMAP_OK")


func _find_label(container: Control, expected_text: String) -> Label:
	for child in container.get_children():
		var label := child as Label
		if label != null and label.text == expected_text:
			return label
	return null
