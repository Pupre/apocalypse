extends "res://tests/support/test_case.gd"

const MAP_VIEW_SCRIPT := "res://scripts/outdoor/outdoor_map_view.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var map_view_script := load(MAP_VIEW_SCRIPT)
	if not assert_true(map_view_script != null, "OutdoorMapView script should load."):
		return

	var map_view = map_view_script.new()
	if not assert_true(map_view != null, "OutdoorMapView should instantiate."):
		return

	map_view.configure(
		{
			"city_blocks": {"width": 8, "height": 8},
			"block_size": {"width": 960, "height": 960},
		},
		{
			"0_0": {
				"block_coord": {"x": 0, "y": 0},
				"district_id": "north_market",
				"layout_id": "market_lane",
				"roads": [
					{"id": "main_road", "rect": {"x": 0, "y": 320, "width": 960, "height": 280}},
				],
				"obstacles": [
					{"kind": "vehicle", "rect": {"x": 180, "y": 430, "width": 52, "height": 52}},
				],
			},
			"1_0": {
				"block_coord": {"x": 1, "y": 0},
				"district_id": "central_transfer",
				"layout_id": "bus_loop",
				"roads": [
					{"id": "side_road", "rect": {"x": 0, "y": 320, "width": 960, "height": 280}},
				],
				"obstacles": [],
			},
		},
		[
			{
				"id": "mart_01",
				"name": "동네 마트",
				"category": "retail",
				"outdoor_block_coord": {"x": 0, "y": 0},
				"outdoor_position": {"x": 640, "y": 360},
			},
			{
				"id": "office_01",
				"name": "사무실",
				"category": "office",
				"outdoor_block_coord": {"x": 1, "y": 0},
				"outdoor_position": {"x": 1320, "y": 360},
			},
		],
		{"0_0": true},
		Vector2(640.0, 360.0)
	)

	var snapshot: Dictionary = map_view.build_snapshot()
	assert_true((snapshot.get("roads", []) as Array).size() >= 2, "Full map should expose authored world-space roads, not only abstract blocks.")
	assert_true((snapshot.get("obstacles", []) as Array).size() >= 1, "Full map should expose authored obstacle geometry.")
	assert_eq(_building_state(snapshot, "mart_01"), "visible", "Buildings in visited outdoor space should stay visible on the spatial map.")
	assert_eq(_building_state(snapshot, "office_01"), "hidden", "Buildings in unvisited outdoor space should stay hidden behind fog.")
	assert_true((snapshot.get("fog_blocks", []) as Array).size() >= 1, "Full map should still track hidden outdoor territory for fog-of-war.")
	assert_eq(_district_id_for(snapshot, "0_0"), "north_market", "Visited blocks should expose their district id so the full map can color city regions.")
	assert_eq(_district_id_for(snapshot, "1_0"), "", "Hidden blocks should keep their district identity behind fog-of-war.")
	var view_rect := _rect_from_row(snapshot.get("view_rect", {}))
	assert_true(view_rect.size.y >= 4200.0, "Full map should open at a much broader city-planning scale than the local minimap.")

	var center_before := snapshot.get("view_center", Vector2.ZERO) as Vector2
	map_view.pan_by(Vector2(120.0, -48.0))
	var center_after := map_view.build_snapshot().get("view_center", Vector2.ZERO) as Vector2
	assert_true(center_after != center_before, "Full map dragging should change the world-space view center.")
	assert_eq(String(map_view.pick_building_id_at_world(Vector2(640.0, 360.0))), "mart_01", "Spatial map hit-testing should resolve nearby building exteriors.")

	map_view.free()
	pass_test("OUTDOOR_MAP_VIEW_OK")


func _building_state(snapshot: Dictionary, building_id: String) -> String:
	for row_variant in snapshot.get("buildings", []):
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row := row_variant as Dictionary
		if String(row.get("id", "")) == building_id:
			return String(row.get("state", ""))
	return ""


func _district_id_for(snapshot: Dictionary, block_key: String) -> String:
	for row_variant in snapshot.get("district_blocks", []):
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row := row_variant as Dictionary
		if String(row.get("key", "")) == block_key:
			return String(row.get("district_id", ""))
	return ""


func _rect_from_row(rect_variant: Variant) -> Rect2:
	if typeof(rect_variant) != TYPE_DICTIONARY:
		return Rect2()
	var rect_row := rect_variant as Dictionary
	return Rect2(
		float(rect_row.get("x", 0.0)),
		float(rect_row.get("y", 0.0)),
		float(rect_row.get("width", 0.0)),
		float(rect_row.get("height", 0.0))
	)
