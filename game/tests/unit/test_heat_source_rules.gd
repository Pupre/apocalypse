extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	if not assert_true(run_state_script != null, "Missing run state script for heat-source tests."):
		return

	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary should be available for heat-source tests."):
		return

	var indoor_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_library)
	if not assert_true(indoor_state != null, "RunState should build for heat-source indoor tests."):
		return

	indoor_state.exposure = 42.0
	indoor_state.enter_indoor_site("mart_01", "mart_entrance")
	var sheltered_exposure: float = indoor_state.exposure
	indoor_state.advance_minutes(60, "indoor")
	assert_eq(indoor_state.exposure, sheltered_exposure, "Indoor time without heat should stop further cold loss but not restore exposure.")
	indoor_state.advance_rest_time(60)
	assert_eq(indoor_state.exposure, sheltered_exposure, "Indoor rest without a heat source should not restore exposure.")

	indoor_state.update_current_indoor_zone("break_room")
	var fixed_heat_modifiers: Dictionary = indoor_state.get_current_indoor_environment_modifiers()
	assert_true(float(fixed_heat_modifiers.get("indoor_heat_score", 0.0)) > 0.0, "Break room should expose a fixed heat source score.")
	var before_fixed_heat_rest: float = indoor_state.exposure
	indoor_state.advance_rest_time(60)
	assert_true(indoor_state.exposure > before_fixed_heat_rest, "Indoor rest at a fixed heat point should restore exposure.")

	var portable_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_library)
	if not assert_true(portable_state != null, "RunState should build for portable heat tests."):
		return

	portable_state.exposure = 38.0
	portable_state.enter_indoor_site("warehouse_01", "loading")
	assert_true(portable_state.inventory.add_item(content_library.get_item("can_stove")), "Portable heat tests should add a can stove.")
	assert_true(portable_state.deploy_item_in_current_site("can_stove"), "Portable heat setup should be deployable indoors.")
	var before_unfueled_rest: float = portable_state.exposure
	portable_state.advance_rest_time(60)
	assert_eq(portable_state.exposure, before_unfueled_rest, "A deployed heat base without ignition or fuel should not restore exposure.")

	assert_true(portable_state.inventory.add_item(content_library.get_item("lighter")), "Portable heat tests should add a lighter.")
	assert_true(portable_state.inventory.add_item(content_library.get_item("oil_rag")), "Portable heat tests should add a fuel source.")
	var before_fueled_rest: float = portable_state.exposure
	portable_state.advance_rest_time(60)
	assert_true(portable_state.exposure > before_fueled_rest, "Portable heat should restore exposure once ignition, fuel, and setup base all exist.")

	var jerrycan_fuel_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_library)
	if not assert_true(jerrycan_fuel_state != null, "RunState should build for salvaged fuel tests."):
		return
	jerrycan_fuel_state.exposure = 36.0
	jerrycan_fuel_state.enter_indoor_site("warehouse_01", "loading")
	assert_true(jerrycan_fuel_state.inventory.add_item(content_library.get_item("can_stove")), "Salvaged fuel tests should add a can stove.")
	assert_true(jerrycan_fuel_state.deploy_item_in_current_site("can_stove"), "Salvaged fuel tests should deploy the can stove.")
	assert_true(jerrycan_fuel_state.inventory.add_item(content_library.get_item("lighter")), "Salvaged fuel tests should add ignition.")
	assert_true(jerrycan_fuel_state.inventory.add_item(content_library.get_item("salvaged_fuel_jerrycan")), "Salvaged fuel tests should add the gas-station fuel item.")
	var before_jerrycan_rest: float = jerrycan_fuel_state.exposure
	jerrycan_fuel_state.advance_rest_time(60)
	assert_true(jerrycan_fuel_state.exposure > before_jerrycan_rest, "A salvaged fuel jerrycan should count as fuel for portable heat recovery.")

	var warmth_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_library)
	if not assert_true(warmth_state != null, "RunState should build for warmth-consumable tests."):
		return

	warmth_state.exposure = 40.0
	assert_true(warmth_state.inventory.add_item(content_library.get_item("warm_tea")), "Warmth tests should add warm tea from content data.")
	var before_drink_exposure: float = warmth_state.exposure
	assert_true(warmth_state.use_inventory_item("warm_tea"), "Warm drinks should remain usable from inventory.")
	assert_true(warmth_state.exposure > before_drink_exposure, "Warm drinks should still provide immediate exposure relief.")
	assert_true(warmth_state.active_warmth_effects.size() == 1, "Warm drinks should still add a timed warmth effect.")

	pass_test("HEAT_SOURCE_RULES_OK")
