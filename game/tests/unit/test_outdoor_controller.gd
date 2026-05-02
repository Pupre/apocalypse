extends "res://tests/support/test_case.gd"

const OUTDOOR_MODE_SCENE_PATH := "res://scenes/outdoor/outdoor_mode.tscn"
const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
var _test_jobs: Dictionary = {
	"courier": {
		"id": "courier",
		"modifiers": {
			"move_speed": 30.0,
			"fatigue_gain": -0.1,
		},
	},
}

var _test_traits: Dictionary = {
	"athlete": {
		"id": "athlete",
		"modifiers": {
			"move_speed": 40.0,
			"fatigue_gain": -0.15,
		},
	},
}

var _building_entered_count := 0
var _entered_building_id := ""


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var outdoor_scene := load(OUTDOOR_MODE_SCENE_PATH) as PackedScene
	if not assert_true(outdoor_scene != null, "Missing outdoor scene: %s" % OUTDOOR_MODE_SCENE_PATH):
		return

	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	if not assert_true(run_state_script != null, "Missing run state script: %s" % RUN_STATE_SCRIPT_PATH):
		return

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(run_state != null, "RunState should build for outdoor tests."):
		return

	var outdoor_mode = outdoor_scene.instantiate()
	if not assert_true(outdoor_mode != null, "Outdoor mode should instantiate."):
		return

	root.add_child(outdoor_mode)
	outdoor_mode.building_entered.connect(Callable(self, "_on_building_entered"))

	if not assert_true(outdoor_mode.has_method("bind_run_state"), "Outdoor mode should expose bind_run_state()."):
		outdoor_mode.free()
		return

	outdoor_mode.bind_run_state(run_state)

	var ground := outdoor_mode.get_node_or_null("Ground") as Node2D
	var player_sprite := outdoor_mode.get_node_or_null("PlayerVisual") as Sprite2D
	var building_markers := outdoor_mode.get_node_or_null("Buildings") as Node2D
	var obstacles := outdoor_mode.get_node_or_null("Obstacles") as Node2D
	if not assert_true(ground != null, "Outdoor mode should expose a ground host."):
		outdoor_mode.free()
		return
	if not assert_true(player_sprite != null, "Outdoor mode should expose a player visual."):
		outdoor_mode.free()
		return
	if not assert_true(building_markers != null, "Outdoor mode should expose a building marker host."):
		outdoor_mode.free()
		return
	if not assert_true(obstacles != null, "Outdoor mode should expose an obstacle host."):
		outdoor_mode.free()
		return
	assert_true(ground.get_child_count() > 0, "Outdoor ground should render at least one visual layer.")
	assert_true(player_sprite.texture != null, "Outdoor player visual should mount a sprite texture.")
	assert_true(player_sprite.scale.x > 1.0, "Outdoor player visual should be scaled up beyond the raw source sprite for readability.")
	assert_true(building_markers.get_child_count() >= 28, "The authored outdoor slice should expose at least twenty-eight building markers after the 3x3 expansion.")
	assert_true(obstacles.get_child_count() > 0, "Outdoor mode should render at least one obstacle prop.")

	var tile_host := outdoor_mode.get_node_or_null("Ground/Tiles") as Node2D
	var decal_host := outdoor_mode.get_node_or_null("Ground/Decals") as Node2D
	if not assert_true(tile_host != null, "Outdoor mode should expose a terrain tile host."):
		outdoor_mode.free()
		return
	if not assert_true(decal_host != null, "Outdoor mode should expose a terrain decal host."):
		outdoor_mode.free()
		return
	assert_true(tile_host.get_child_count() > 0, "Outdoor terrain should place at least one runtime tile sprite.")
	assert_true(_children_named_with(tile_host, "road_cracked").size() > 0 or _children_named_with(tile_host, "slush_road").size() > 0, "Outdoor terrain should mix cracked or slushy road variants instead of a single repeated lane texture.")
	assert_true(_children_named_with(decal_host, "Hazard").size() >= 8, "The starting active block window should render multiple authored hazard decals across nearby blocks.")
	assert_true(_max_visual_scale(obstacles) > 1.0, "Outdoor obstacle props should be scaled up to fit the authored city block better.")
	assert_true(outdoor_mode.has_method("_effective_obstacle_rect"), "Outdoor controller should expose an internal obstacle hitbox helper for collision debugging.")
	var sample_obstacle := {"kind": "rubble", "rect": {"x": 710.0, "y": 180.0, "width": 120.0, "height": 80.0}}
	var collision_rect: Rect2 = outdoor_mode._effective_obstacle_rect(sample_obstacle)
	assert_true(collision_rect.size.x < 120.0 and collision_rect.size.y < 80.0, "Outdoor obstacle collision should be smaller than the authored staging rect.")
	assert_true(is_equal_approx(collision_rect.end.y, 260.0), "Outdoor obstacle collision should stay anchored to the bottom edge of the authored rect.")

	var top_ribbon := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon") as Control
	var hint_label := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/HintLabel") as Label
	var threat_label := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ThreatLabel") as Label
	var world_camera := outdoor_mode.get_node_or_null("WorldCamera") as Camera2D
	var frost_overlay := outdoor_mode.get_node_or_null("CanvasLayer/FrostOverlay") as ColorRect
	var frost_crystals := outdoor_mode.get_node_or_null("CanvasLayer/FrostCrystals") as TextureRect
	var map_overlay := outdoor_mode.get_node_or_null("MapOverlay") as CanvasLayer
	var full_map_view := outdoor_mode.get_node_or_null("MapOverlay/Panel/VBox/Margin/MapView") as Control
	var overlay_close := outdoor_mode.get_node_or_null("MapOverlay/Panel/VBox/Header/CloseButton") as Button
	if not assert_true(top_ribbon != null, "Outdoor mode should expose a compact outdoor status ribbon."):
		outdoor_mode.free()
		return
	if not assert_true(hint_label != null, "Outdoor mode should expose a hint label in the top ribbon."):
		outdoor_mode.free()
		return
	if not assert_true(threat_label != null, "Outdoor mode should expose a threat label in the top ribbon."):
		outdoor_mode.free()
		return
	if not assert_true(world_camera != null, "Outdoor mode should expose a world camera."):
		outdoor_mode.free()
		return
	if not assert_true(frost_overlay != null, "Outdoor mode should expose a full-screen frost overlay."):
		outdoor_mode.free()
		return
	if not assert_true(frost_crystals != null, "Outdoor mode should expose an image-backed frost crystal overlay."):
		outdoor_mode.free()
		return
	if not assert_true(frost_crystals.texture != null, "Outdoor frost crystals should load the generated frost texture."):
		outdoor_mode.free()
		return
	if not assert_true(map_overlay != null, "Outdoor mode should expose a full-screen map overlay."):
		outdoor_mode.free()
		return
	if not assert_true(full_map_view != null, "Outdoor overlay should mount a full-map renderer."):
		outdoor_mode.free()
		return
	if not assert_true(overlay_close != null, "Outdoor map overlay should expose a close button above the HUD."):
		outdoor_mode.free()
		return
	if not assert_true(outdoor_mode.has_method("get_world_bounds"), "Outdoor mode should expose get_world_bounds() for district-scale verification."):
		outdoor_mode.free()
		return
	assert_eq(top_ribbon.anchor_left, 0.0, "Outdoor TopRibbon should stretch from the left edge.")
	assert_eq(top_ribbon.anchor_right, 1.0, "Outdoor TopRibbon should stretch to the right edge.")
	assert_true(world_camera.offset.y < 0.0, "Portrait outdoor camera should lead upward with a negative Y offset.")
	assert_true(frost_overlay.color.a <= 0.05, "Healthy outdoor exposure should start with almost no frost overlay.")
	assert_true(frost_crystals.modulate.a <= 0.05, "Healthy outdoor exposure should start with almost no frost crystal coverage.")
	assert_true(not map_overlay.visible, "Outdoor map overlay should start closed.")
	assert_eq(String(full_map_view.get_script().resource_path), "res://scripts/outdoor/outdoor_map_view.gd", "Outdoor overlay should use the full-screen spatial map renderer.")
	assert_true(outdoor_mode.has_method("show_map_overlay"), "Outdoor mode should expose show_map_overlay().")
	assert_true(outdoor_mode.has_method("hide_map_overlay"), "Outdoor mode should expose hide_map_overlay().")
	outdoor_mode.show_map_overlay()
	assert_true(map_overlay.visible, "show_map_overlay() should reveal the full-screen map.")
	var minute_before_pause: int = run_state.clock.minute_of_day
	outdoor_mode.simulate_seconds(60.0)
	assert_eq(run_state.clock.minute_of_day, minute_before_pause, "Outdoor simulation should pause while the full map overlay is open.")
	outdoor_mode.hide_map_overlay()
	assert_true(not map_overlay.visible, "hide_map_overlay() should dismiss the full-screen map.")
	if not assert_true(map_overlay.has_method("show_building_detail"), "Outdoor map overlay should expose building-detail inspection."):
		outdoor_mode.free()
		return
	if not assert_true(map_overlay.has_method("hide_building_detail"), "Outdoor map overlay should expose building-detail dismissal."):
		outdoor_mode.free()
		return
	run_state.enter_indoor_site("mart_01", "mart_entrance")
	map_overlay.show_building_detail("mart_01")
	var detail_layer := outdoor_mode.get_node_or_null("MapOverlay/BuildingDetailLayer") as Control
	var detail_title := outdoor_mode.get_node_or_null("MapOverlay/BuildingDetailLayer/Panel/VBox/Header/TitleLabel") as Label
	var detail_message := outdoor_mode.get_node_or_null("MapOverlay/BuildingDetailLayer/Panel/VBox/MessageLabel") as Label
	if not assert_true(detail_layer != null and detail_title != null and detail_message != null, "Outdoor map overlay should expose a dedicated building detail layer."):
		outdoor_mode.free()
		return
	assert_true(detail_layer.visible, "Entered buildings should open the building detail layer from the outdoor map.")
	assert_true(detail_title.text.find("동네 마트") >= 0, "Known building detail should show the building title.")
	assert_true(detail_message.text.find("정문 진입부") >= 0, "Known building detail should expose remembered indoor structure labels.")
	map_overlay.hide_building_detail()
	map_overlay.show_building_detail("office_01")
	assert_true(detail_message.text.find("아직 내부 구조를 모른다") >= 0, "Unentered buildings should refuse to reveal indoor structure.")
	var world_rect: Rect2 = outdoor_mode.get_world_bounds()
	assert_true(world_rect.size.x >= 7680.0, "Outdoor world width should reflect the larger fixed-city authoring grid, not just a one-off district rectangle.")
	assert_true(world_rect.size.y >= 7680.0, "Outdoor world height should reflect the larger fixed-city authoring grid.")

	var start_position: Vector2 = outdoor_mode.get_player_position()
	outdoor_mode.move_player(Vector2.RIGHT, 8.0)
	outdoor_mode.move_player(Vector2.DOWN, 8.0)
	var traveled_distance: float = start_position.distance_to(outdoor_mode.get_player_position())
	assert_true(traveled_distance >= 1400.0, "Outdoor travel should support materially longer continuous movement inside the streamed city grid.")
	outdoor_mode.bind_run_state(run_state)

	var hazard_exposure_before: float = run_state.exposure
	var hazard_fatigue_before: float = run_state.fatigue
	var hazard_health_before: float = run_state.health
	outdoor_mode.move_player(Vector2.RIGHT, 1.25)
	assert_true(run_state.exposure < hazard_exposure_before, "Crossing black ice should reduce exposure beyond passive cold drain.")
	assert_true(run_state.fatigue > hazard_fatigue_before, "Crossing black ice should add fatigue pressure.")
	assert_true(run_state.health < hazard_health_before, "Crossing black ice should be able to cause a small injury.")
	assert_true(hint_label.text != "WASD 이동", "Outdoor hazard contact should temporarily replace the generic movement hint with feedback.")
	assert_true(frost_crystals.modulate.a >= 0.6, "Outdoor hazard contact should immediately flash the image-backed frost overlay.")
	assert_true(world_camera.offset != Vector2(0.0, -220.0), "Outdoor hazard contact should jolt the portrait camera for tactile feedback.")
	outdoor_mode.bind_run_state(run_state)

	var before_clock_minute_of_day: int = run_state.clock.minute_of_day
	var before_exposure: float = run_state.exposure
	var before_hunger: float = run_state.hunger
	var before_thirst: float = run_state.thirst
	var before_fatigue: float = run_state.fatigue

	if not assert_true(outdoor_mode.has_method("simulate_seconds"), "Outdoor mode should expose simulate_seconds()."):
		outdoor_mode.free()
		return

	outdoor_mode.simulate_seconds(180.0)

	assert_eq(
		run_state.clock.minute_of_day,
		before_clock_minute_of_day + 180,
		"Three real minutes should advance three in-game hours."
	)
	assert_true(run_state.exposure < before_exposure, "Outdoor time should drain exposure.")
	assert_true(run_state.hunger < before_hunger, "Outdoor time should reduce hunger reserves.")
	assert_true(run_state.thirst < before_thirst, "Outdoor time should reduce thirst reserves.")
	assert_true(run_state.fatigue > before_fatigue, "Outdoor time should build fatigue.")

	var normal_pressure_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	var overpacked_pressure_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(normal_pressure_state != null and overpacked_pressure_state != null, "RunState should build for outdoor pressure comparisons."):
		outdoor_mode.free()
		return
	assert_true(overpacked_pressure_state.inventory.add_item({"id": "heavy_haul", "carry_weight": 11.0}), "Pressure tests should be able to seed an overpacked carry load.")

	outdoor_mode.bind_run_state(normal_pressure_state, "mart_01", Vector2(0.0, 0.0))
	var normal_pressure_exposure_before: float = normal_pressure_state.exposure
	var normal_pressure_fatigue_before: float = normal_pressure_state.fatigue
	outdoor_mode.simulate_seconds(60.0)
	var normal_pressure_exposure_loss: float = normal_pressure_exposure_before - normal_pressure_state.exposure
	var normal_pressure_fatigue_gain: float = normal_pressure_state.fatigue - normal_pressure_fatigue_before

	outdoor_mode.bind_run_state(overpacked_pressure_state, "mart_01", Vector2(0.0, 0.0))
	var overpacked_pressure_exposure_before: float = overpacked_pressure_state.exposure
	var overpacked_pressure_fatigue_before: float = overpacked_pressure_state.fatigue
	outdoor_mode.simulate_seconds(60.0)
	var overpacked_pressure_exposure_loss: float = overpacked_pressure_exposure_before - overpacked_pressure_state.exposure
	var overpacked_pressure_fatigue_gain: float = overpacked_pressure_state.fatigue - overpacked_pressure_fatigue_before

	assert_true(overpacked_pressure_exposure_loss > normal_pressure_exposure_loss * 1.35, "Overpacked outdoor travel should lose materially more exposure than an ideal carry load.")
	assert_true(overpacked_pressure_fatigue_gain > normal_pressure_fatigue_gain * 1.4, "Overpacked outdoor travel should build fatigue materially faster than an ideal carry load.")
	outdoor_mode.bind_run_state(run_state)

	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary autoload should be available for building lookups."):
		outdoor_mode.free()
		return
	for building_id in [
		"mart_01", "apartment_01", "clinic_01", "office_01",
		"convenience_01", "hardware_01", "gas_station_01", "laundry_01",
		"bookstore_01", "deli_01", "hostel_01",
		"storage_depot_01", "garage_01", "canteen_01",
		"church_01", "corner_store_01",
		"school_gate_01", "butcher_01", "row_house_01",
		"chapel_01", "tea_shop_01"
	]:
		assert_true(content_library.get_building(building_id).size() > 0, "Building '%s' should exist in the expanded district." % building_id)

	var unprotected_exposure_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_library)
	var warmed_exposure_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_library)
	if not assert_true(unprotected_exposure_state != null and warmed_exposure_state != null, "RunState should build for warmth-modified outdoor pressure checks."):
		outdoor_mode.free()
		return
	assert_true(warmed_exposure_state.inventory.add_item(content_library.get_item("warm_tea")), "Warmth pressure tests should add warm tea.")
	assert_true(warmed_exposure_state.use_inventory_item("warm_tea"), "Warm tea should apply its timed outdoor exposure modifier.")

	outdoor_mode.bind_run_state(unprotected_exposure_state, "mart_01", Vector2(0.0, 0.0))
	var unprotected_exposure_before: float = unprotected_exposure_state.exposure
	outdoor_mode.simulate_seconds(20.0)
	var unprotected_exposure_loss: float = unprotected_exposure_before - unprotected_exposure_state.exposure

	outdoor_mode.bind_run_state(warmed_exposure_state, "mart_01", Vector2(0.0, 0.0))
	var warmed_exposure_before: float = warmed_exposure_state.exposure
	outdoor_mode.simulate_seconds(20.0)
	var warmed_exposure_loss: float = warmed_exposure_before - warmed_exposure_state.exposure

	assert_true(warmed_exposure_loss < unprotected_exposure_loss, "Timed warmth effects should reduce outdoor exposure loss while active.")
	outdoor_mode.bind_run_state(run_state)

	var mart_data: Dictionary = content_library.get_building("mart_01")
	var mart_position := Vector2(
		float((mart_data.get("outdoor_position", {}) as Dictionary).get("x", 640.0)),
		float((mart_data.get("outdoor_position", {}) as Dictionary).get("y", 360.0))
	)

	var far_distance := player_sprite.position.distance_to(mart_position)
	assert_true(far_distance > 72.0, "The player should start outside the entry radius.")

	outdoor_mode.try_enter_building("mart_01")
	assert_eq(_building_entered_count, 0, "Trying to enter from far away should not emit building_entered.")

	if not assert_true(outdoor_mode.has_method("try_enter_building"), "Outdoor mode should expose try_enter_building()."):
		outdoor_mode.free()
		return

	if not assert_true(outdoor_mode.has_method("move_player"), "Outdoor mode should expose move_player()."):
		outdoor_mode.free()
		return

	outdoor_mode.move_player(Vector2.RIGHT, 1.5)

	var near_distance := player_sprite.position.distance_to(mart_position)
	assert_true(near_distance <= 72.0, "Moving toward the building should place the player in entry range.")
	assert_true(hint_label.text.find("동네 마트") >= 0, "Nearby building hints should name the target building.")
	assert_true(hint_label.text.find("직원 구역과 재고실") >= 0, "Nearby building hints should surface the authored entry briefing.")

	outdoor_mode.try_enter_building("wrong_building")
	assert_eq(_building_entered_count, 0, "The wrong building id should not emit building_entered.")

	outdoor_mode.try_enter_building("mart_01")

	assert_eq(_building_entered_count, 1, "Trying to enter from nearby should emit building_entered.")
	assert_eq(_entered_building_id, "mart_01", "The emitted building id should match the entry target.")

	var apartment_data: Dictionary = content_library.get_building("apartment_01")
	var apartment_position := Vector2(
		float((apartment_data.get("outdoor_position", {}) as Dictionary).get("x", 0.0)),
		float((apartment_data.get("outdoor_position", {}) as Dictionary).get("y", 0.0))
	)
	outdoor_mode.bind_run_state(run_state, "mart_01", apartment_position)
	outdoor_mode.try_enter_building("apartment_01")
	assert_eq(_building_entered_count, 2, "Trying to enter a second building from its own doorstep should also emit building_entered.")
	assert_eq(_entered_building_id, "apartment_01", "The emitted building id should match the second entry target.")

	var overloaded_run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(overloaded_run_state != null, "RunState should build for overload movement tests."):
		outdoor_mode.free()
		return
	for index in range(12):
		assert_true(overloaded_run_state.inventory.add_item({"id": "weight_%d" % index, "bulk": 1}), "Overload movement tests should be able to fill the inventory.")

	outdoor_mode.bind_run_state(overloaded_run_state, "mart_01", Vector2(0.0, 0.0))
	outdoor_mode.move_player(Vector2.RIGHT, 1.0)
	assert_true(
		outdoor_mode.get_player_position().x < overloaded_run_state.move_speed,
		"Outdoor movement should slow down when the player is carrying more than the soft limit."
	)
	overloaded_run_state.exposure = 18.0
	outdoor_mode.refresh_view()
	assert_true(threat_label.text.length() > 0, "Outdoor top ribbon should always show a readable threat-state line.")
	assert_true(frost_overlay.color.a <= 0.3, "Low exposure should keep the tint veil subtle enough for readability.")
	assert_true(frost_crystals.modulate.a >= 0.6, "Low exposure should visibly grow the image-backed frost crystal overlay.")

	var fresh_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	var tired_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(fresh_state != null and tired_state != null, "RunState should build for fatigue movement checks."):
		outdoor_mode.free()
		return
	tired_state.fatigue = 80.0
	outdoor_mode.bind_run_state(fresh_state, "mart_01", Vector2(0.0, 0.0))
	outdoor_mode.move_player(Vector2.RIGHT, 1.0)
	var fresh_x: float = outdoor_mode.get_player_position().x
	outdoor_mode.bind_run_state(tired_state, "mart_01", Vector2(0.0, 0.0))
	outdoor_mode.move_player(Vector2.RIGHT, 1.0)
	assert_true(outdoor_mode.get_player_position().x < fresh_x, "Higher fatigue should reduce outdoor movement speed.")

	var before_contact_exposure: float = tired_state.exposure
	var before_contact_fatigue: float = tired_state.fatigue
	assert_true(outdoor_mode.has_method("debug_force_threat_contact"), "Outdoor mode should expose a narrow debug_force_threat_contact() hook for deterministic threat tests.")
	outdoor_mode.debug_force_threat_contact()
	assert_true(tired_state.exposure < before_contact_exposure, "Threat contact should reduce exposure.")
	assert_true(tired_state.fatigue > before_contact_fatigue, "Threat contact should increase fatigue.")

	var craft_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_library)
	if not assert_true(craft_state != null, "Outdoor controller should build a craft-specific run state."):
		outdoor_mode.free()
		return
	assert_true(craft_state.inventory.add_item(content_library.get_item("newspaper")), "Outdoor crafting tests should add newspaper.")
	assert_true(craft_state.inventory.add_item(content_library.get_item("cooking_oil")), "Outdoor crafting tests should add cooking oil.")
	outdoor_mode.bind_run_state(craft_state, "mart_01", Vector2(0.0, 0.0))
	if not assert_true(outdoor_mode.has_method("attempt_craft"), "Outdoor mode should expose attempt_craft(...) for the shared crafting sheet."):
		outdoor_mode.free()
		return
	var before_craft_minute: int = craft_state.clock.minute_of_day
	var craft_result: Dictionary = outdoor_mode.attempt_craft("newspaper", "cooking_oil")
	assert_true(bool(craft_result.get("ok", false)), "Outdoor assembly crafting should succeed without a lighter tool.")
	assert_eq(craft_state.clock.minute_of_day, before_craft_minute, "Outdoor crafting should not add an explicit minute cost.")
	assert_true(craft_state.known_recipe_ids.has("newspaper__cooking_oil"), "Outdoor crafting should unlock recipes in the run-state codex.")

	outdoor_mode.free()
	pass_test("OUTDOOR_CONTROLLER_OK")


func _on_building_entered(building_id: String) -> void:
	_building_entered_count += 1
	_entered_building_id = building_id


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})


func _polygon_min_y(points: PackedVector2Array) -> float:
	var min_y := INF
	for point in points:
		min_y = minf(min_y, point.y)
	return min_y


func _children_named_with(container: Node, fragment: String) -> Array[Node]:
	var matches: Array[Node] = []
	if container == null:
		return matches
	for child in container.get_children():
		if String(child.name).find(fragment) >= 0:
			matches.append(child)
	return matches


func _max_visual_scale(container: Node) -> float:
	var max_scale := 0.0
	if container == null:
		return max_scale
	for child in container.get_children():
		var visual := child.get_node_or_null("Visual") as Node2D
		if visual != null:
			max_scale = maxf(max_scale, visual.scale.x)
	return max_scale
