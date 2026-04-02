extends "res://tests/support/test_case.gd"

const HUD_SCENE_PATH := "res://scenes/run/hud.tscn"

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


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var hud_scene := load(HUD_SCENE_PATH) as PackedScene
	if not assert_true(hud_scene != null, "Missing HUD scene: %s" % HUD_SCENE_PATH):
		return

	var hud := hud_scene.instantiate()
	if not assert_true(hud != null, "HUD should instantiate."):
		return

	root.add_child(hud)

	if not assert_true(hud.has_method("set_mode_presentation"), "HUD should expose set_mode_presentation()."):
		hud.free()
		return

	var panel := hud.get_node_or_null("Panel") as PanelContainer
	var title_label := hud.get_node_or_null("Panel/VBox/TitleLabel") as Label
	var clock_label := hud.get_node_or_null("Panel/VBox/ClockLabel") as Label
	var fatigue_label := hud.get_node_or_null("Panel/VBox/FatigueLabel") as Label
	var hunger_label := hud.get_node_or_null("Panel/VBox/HungerLabel") as Label
	var thirst_label := hud.get_node_or_null("Panel/VBox/ThirstLabel") as Label
	var health_label := hud.get_node_or_null("Panel/VBox/HealthLabel") as Label
	if not assert_true(panel != null, "HUD should expose Panel."):
		hud.free()
		return
	if not assert_true(title_label != null, "HUD should expose TitleLabel."):
		hud.free()
		return
	if not assert_true(clock_label != null and fatigue_label != null and hunger_label != null and thirst_label != null and health_label != null, "HUD should expose the first-pass survival labels."):
		hud.free()
		return

	hud.set_mode_presentation("outdoor")
	assert_eq(panel.anchor_left, 1.0, "Outdoor mode should anchor the HUD to the right edge.")
	assert_eq(panel.anchor_right, 1.0, "Outdoor mode should keep the HUD right-anchored.")
	assert_eq(panel.offset_left, -336.0, "Outdoor mode should keep the HUD 16px from the right edge.")
	assert_eq(panel.offset_top, 16.0, "Outdoor mode should pin the HUD top offset to 16.")
	assert_eq(panel.offset_right, -16.0, "Outdoor mode should keep the HUD right margin at 16.")
	assert_eq(panel.offset_bottom, 228.0, "Outdoor mode should leave room for the added survival rows.")
	assert_true(is_equal_approx(panel.modulate.a, 1.0), "Outdoor mode should keep the HUD fully opaque.")
	assert_eq(title_label.text, "외부 생존 정보", "Outdoor mode should use the outdoor HUD title.")

	hud.set_mode_presentation("indoor")
	assert_eq(panel.anchor_left, 1.0, "Indoor mode should keep the HUD right-anchored.")
	assert_eq(panel.anchor_right, 1.0, "Indoor mode should keep the HUD right-anchored.")
	assert_eq(panel.offset_left, -272.0, "Indoor mode should keep the HUD inset from the right edge.")
	assert_eq(panel.offset_top, 20.0, "Indoor mode should pin the HUD top offset to 20.")
	assert_eq(panel.offset_right, -24.0, "Indoor mode should keep the HUD right margin at 24.")
	assert_eq(panel.offset_bottom, 204.0, "Indoor mode should leave room for the added survival rows.")
	assert_true(is_equal_approx(panel.modulate.a, 0.9), "Indoor mode should dim the HUD to alpha 0.9.")
	assert_eq(title_label.text, "실내 생존 정보", "Indoor mode should use the indoor HUD title.")

	var run_state_script := load("res://scripts/run/run_state.gd") as Script
	if not assert_true(run_state_script != null, "HUD test should load RunState."):
		hud.free()
		return
	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(run_state != null, "HUD test should build a run state."):
		hud.free()
		return
	run_state.hunger = 61.0
	run_state.thirst = 38.0
	run_state.health = 54.0
	run_state.fatigue = 28.0
	hud.set_run_state(run_state)

	assert_true(clock_label.text.find("1일차 08:00") != -1, "HUD should keep showing the shared clock.")
	assert_eq(fatigue_label.text, "피로: 안정", "HUD should show fatigue as a readable stage, not a raw exact value.")
	assert_eq(hunger_label.text, "허기: 보통", "HUD should show hunger as a readable stage.")
	assert_eq(thirst_label.text, "갈증: 목마름", "HUD should show thirst as a readable stage.")
	assert_eq(health_label.text, "체력: 부상", "HUD should show health as a readable stage.")

	hud.free()
	pass_test("HUD_PRESENTATION_OK")


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
