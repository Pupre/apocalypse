extends "res://tests/support/test_case.gd"

const WARMTH_MODEL_SCRIPT_PATH := "res://scripts/run/warmth_model.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var warmth_model = load(WARMTH_MODEL_SCRIPT_PATH).new()

	var active_effects: Array[Dictionary] = [
		{"id": "hot_water_bottle", "remaining_minutes": 45, "outdoor_exposure_drain_multiplier": 0.82},
		{"id": "warm_tea", "remaining_minutes": 30, "outdoor_exposure_drain_multiplier": 0.88}
	]
	var equipped_items: Array[Dictionary] = []
	assert_true(
		warmth_model.get_outdoor_exposure_drain_multiplier(active_effects, equipped_items) < 1.0,
		"Warmth effects should reduce outdoor exposure drain."
	)

	var ticked: Array[Dictionary] = warmth_model.tick_active_effects(active_effects, 30)
	assert_eq(int(ticked[0].get("remaining_minutes", -1)), 15, "Ticking warmth effects should reduce remaining minutes.")

	var use_effects := {
		"exposure_restore": 12,
		"thirst_restore": 6,
		"fatigue_restore": 4,
		"warmth_minutes": 30,
		"outdoor_exposure_drain_multiplier": 0.88
	}
	var applied: Dictionary = warmth_model.apply_use_effects(40.0, 50.0, 60.0, use_effects)
	assert_true(float(applied.get("exposure", 0.0)) > 40.0, "Warm drinks should restore exposure immediately.")
	assert_eq(int((applied.get("warmth_effect", {}) as Dictionary).get("remaining_minutes", -1)), 30, "Warm drinks should create a timed warmth effect.")

	pass_test("WARMTH_MODEL_OK")
