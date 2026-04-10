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
var _codex_requested_count := 0


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
	outdoor_mode.codex_requested.connect(Callable(self, "_on_codex_requested"))

	if not assert_true(outdoor_mode.has_method("bind_run_state"), "Outdoor mode should expose bind_run_state()."):
		outdoor_mode.free()
		return

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

	var ground := outdoor_mode.get_node_or_null("Ground") as Node2D
	var player_sprite := outdoor_mode.get_node_or_null("PlayerSprite") as Polygon2D
	var building_markers := outdoor_mode.get_node_or_null("Buildings") as Node2D
	var obstacles := outdoor_mode.get_node_or_null("Obstacles") as Node2D
	if not assert_true(ground != null, "Outdoor mode should expose a ground host."):
		outdoor_mode.free()
		return
	if not assert_true(player_sprite != null, "Outdoor mode should expose a player marker."):
		outdoor_mode.free()
		return
	if not assert_true(building_markers != null, "Outdoor mode should expose a building marker host."):
		outdoor_mode.free()
		return
	if not assert_true(obstacles != null, "Outdoor mode should expose an obstacle host."):
		outdoor_mode.free()
		return
	assert_true(ground.get_child_count() > 0, "Outdoor ground should render at least one visual layer.")
	assert_true(player_sprite.polygon.size() >= 3, "Outdoor player marker should render a visible polygon.")
	assert_eq(building_markers.get_child_count(), 4, "Outdoor mode should render four building markers.")
	assert_true(obstacles.get_child_count() > 0, "Outdoor mode should render at least one obstacle prop.")

	var asphalt := outdoor_mode.get_node_or_null("Ground/Asphalt") as Polygon2D
	if not assert_true(asphalt != null, "Outdoor mode should expose the asphalt backdrop polygon."):
		outdoor_mode.free()
		return
	assert_true(
		_polygon_min_y(asphalt.polygon) <= -float(ProjectSettings.get_setting("display/window/size/viewport_height")),
		"Outdoor asphalt should extend at least one portrait viewport above the original world top so the lead stays covered."
	)

	var top_ribbon := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon") as PanelContainer
	var exposure_label := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/HeaderRow/ExposureLabel") as Label
	var hint_label := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/HintLabel") as Label
	var craft_button := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ToolsRow/CraftButton") as Button
	var codex_button := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ToolsRow/CodexButton") as Button
	var world_camera := outdoor_mode.get_node_or_null("WorldCamera") as Camera2D
	if not assert_true(top_ribbon != null, "Outdoor mode should expose a portrait TopRibbon panel."):
		outdoor_mode.free()
		return
	if not assert_true(exposure_label != null, "Outdoor mode should expose an exposure label in the top ribbon."):
		outdoor_mode.free()
		return
	if not assert_true(hint_label != null, "Outdoor mode should expose a hint label in the top ribbon."):
		outdoor_mode.free()
		return
	if not assert_true(craft_button != null and codex_button != null, "Outdoor mode should expose craft and codex buttons in the top ribbon."):
		outdoor_mode.free()
		return
	if not assert_true(world_camera != null, "Outdoor mode should expose a world camera."):
		outdoor_mode.free()
		return
	assert_eq(top_ribbon.anchor_left, 0.0, "Outdoor TopRibbon should stretch from the left edge.")
	assert_eq(top_ribbon.anchor_right, 1.0, "Outdoor TopRibbon should stretch to the right edge.")
	assert_true(world_camera.offset.y < 0.0, "Portrait outdoor camera should lead upward with a negative Y offset.")

	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary autoload should be available for building lookups."):
		outdoor_mode.free()
		return

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

	codex_button.emit_signal("pressed")
	assert_eq(_codex_requested_count, 1, "Pressing the outdoor codex button should request the shared crafting codex.")

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


func _on_codex_requested() -> void:
	_codex_requested_count += 1


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})


func _polygon_min_y(points: PackedVector2Array) -> float:
	var min_y := INF
	for point in points:
		min_y = minf(min_y, point.y)
	return min_y
