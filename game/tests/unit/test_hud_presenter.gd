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

	var hud_layer := hud as CanvasLayer
	if not assert_true(hud_layer != null, "HUD should mount in a CanvasLayer so outdoor survival info stays in the screen overlay instead of the world view."):
		hud.free()
		return
	assert_eq(hud_layer.layer, 10, "HUD CanvasLayer should reserve a stable overlay layer above the world scene.")

	if not assert_true(hud.has_method("set_mode_presentation"), "HUD should expose set_mode_presentation()."):
		hud.free()
		return

	var top_ribbon := hud.get_node_or_null("TopRibbon") as PanelContainer
	var title_label := hud.get_node_or_null("TopRibbon/Margin/Stack/HeaderRow/TitleLabel") as Label
	var clock_label := hud.get_node_or_null("TopRibbon/Margin/Stack/HeaderRow/ClockLabel") as Label
	var fatigue_label := hud.get_node_or_null("TopRibbon/Margin/Stack/StatsRow/FatigueLabel") as Label
	var hunger_label := hud.get_node_or_null("TopRibbon/Margin/Stack/StatsRow/HungerLabel") as Label
	var thirst_label := hud.get_node_or_null("TopRibbon/Margin/Stack/StatsRow/ThirstLabel") as Label
	var health_label := hud.get_node_or_null("TopRibbon/Margin/Stack/StatsRow/HealthLabel") as Label
	var carry_label := hud.get_node_or_null("TopRibbon/Margin/Stack/StatsRow/CarryLabel") as Label
	if not assert_true(top_ribbon != null, "HUD should expose TopRibbon."):
		hud.free()
		return
	if not assert_true(title_label != null, "HUD should expose TitleLabel."):
		hud.free()
		return
	if not assert_true(clock_label != null and fatigue_label != null and hunger_label != null and thirst_label != null and health_label != null and carry_label != null, "HUD should expose the first-pass survival labels."):
		hud.free()
		return

	hud.set_mode_presentation("outdoor")
	assert_eq(top_ribbon.anchor_left, 0.0, "Outdoor mode should stretch the HUD from the left edge.")
	assert_eq(top_ribbon.anchor_top, 0.0, "Outdoor mode should pin the HUD to the top edge.")
	assert_eq(top_ribbon.anchor_right, 1.0, "Outdoor mode should stretch the HUD to the right edge.")
	assert_eq(top_ribbon.anchor_bottom, 0.0, "Outdoor mode should keep the HUD top-aligned instead of depending on scene defaults.")
	assert_eq(top_ribbon.offset_left, 12.0, "Outdoor mode should keep the HUD 12px from the left edge.")
	assert_eq(top_ribbon.offset_top, 12.0, "Outdoor mode should keep the HUD 12px from the top edge.")
	assert_eq(top_ribbon.offset_right, -12.0, "Outdoor mode should keep the HUD 12px from the right edge.")
	assert_eq(top_ribbon.offset_bottom, 116.0, "Outdoor mode should leave room for the shared ribbon rows.")
	assert_true(is_equal_approx(top_ribbon.modulate.a, 1.0), "Outdoor mode should keep the HUD fully opaque.")
	assert_eq(title_label.text, "외부 생존 정보", "Outdoor mode should use the outdoor HUD title.")

	hud.set_mode_presentation("indoor")
	assert_true(not hud.visible, "Indoor mode should hide the shared HUD so the reading-first indoor UI owns the screen.")

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
	hud.set_mode_presentation("outdoor")
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
