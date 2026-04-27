extends "res://tests/support/test_case.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var runtime_script: Script = load("res://scripts/outdoor/outdoor_world_runtime.gd")
	if not assert_true(runtime_script != null, "OutdoorWorldRuntime script should exist."):
		return

	var runtime = runtime_script.new()
	runtime.configure({
		"block_size": {"width": 960, "height": 960},
		"city_blocks": {"width": 8, "height": 8},
		"spawn_block_coord": {"x": 0, "y": 0},
		"spawn_local_position": {"x": 320, "y": 420}
	}, {
		"0_0": {"building_anchors": {"mart_anchor": {"x": 640, "y": 360}}},
		"1_0": {"building_anchors": {"clinic_anchor": {"x": 120, "y": 440}}},
		"0_1": {"building_anchors": {"gas_station_anchor": {"x": 200, "y": 300}}},
		"1_1": {"building_anchors": {"laundry_anchor": {"x": 440, "y": 220}}}
	})

	assert_eq(runtime.world_to_block_coord(Vector2(120.0, 840.0)), Vector2i(0, 0), "World coordinates should resolve into fixed block coordinates.")
	assert_eq(runtime.world_to_block_coord(Vector2(1040.0, 120.0)), Vector2i(1, 0), "Crossing one block width should advance the block X coordinate.")
	assert_eq(runtime.world_to_block_coord(Vector2(1040.0, 1160.0)), Vector2i(1, 1), "Crossing width and height should resolve into the southeast block.")

	var active_blocks: Array[Vector2i] = runtime.get_active_block_coords(Vector2i(4, 4))
	assert_eq(active_blocks.size(), 9, "A centered runtime should keep a 3x3 active window.")
	assert_true(active_blocks.has(Vector2i(3, 3)), "The active window should include the northwest neighbor.")
	assert_true(active_blocks.has(Vector2i(4, 4)), "The active window should include the current block.")
	assert_true(active_blocks.has(Vector2i(5, 5)), "The active window should include the southeast neighbor.")

	assert_eq(runtime.resolve_anchor_world_position(Vector2i(1, 0), "clinic_anchor"), Vector2(1080.0, 440.0), "Anchor resolution should add local anchor coordinates to block origins.")

	pass_test("OUTDOOR_WORLD_RUNTIME_OK")
