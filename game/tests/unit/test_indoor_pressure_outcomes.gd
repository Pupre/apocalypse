extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const INDOOR_ACTION_RESOLVER_SCRIPT_PATH := "res://scripts/indoor/indoor_action_resolver.gd"
const MART_EVENT_PATH := "res://data/events/indoor/mart_01.json"
const GARAGE_EVENT_PATH := "res://data/events/indoor/garage_01.json"
const WAREHOUSE_EVENT_PATH := "res://data/events/indoor/warehouse_01.json"

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
	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	var resolver_script := load(INDOOR_ACTION_RESOLVER_SCRIPT_PATH) as Script
	if not assert_true(run_state_script != null, "Missing run state script."):
		return
	if not assert_true(resolver_script != null, "Missing indoor action resolver script."):
		return

	var resolver = resolver_script.new()
	var event_data: Dictionary = resolver.load_event(MART_EVENT_PATH)
	if not assert_true(not event_data.is_empty(), "Mart event data should load."):
		return

	var cold_run_state = _build_run_state(run_state_script)
	var cold_state := _event_state_for_zone("cold_storage")
	var exposure_before := float(cold_run_state.exposure)
	var fatigue_before := float(cold_run_state.fatigue)
	assert_true(resolver.apply_action(cold_run_state, event_data, cold_state, "search_cold_storage"), "Cold storage search should resolve.")
	assert_eq(float(cold_run_state.exposure), exposure_before - 6.0, "Cold storage pressure should reduce exposure.")
	assert_true(float(cold_run_state.fatigue) >= fatigue_before + 2.0, "Cold storage pressure should add fatigue on top of search time.")
	assert_eq(int(cold_state.get("noise", 0)), 1, "Cold storage pressure should add a small noise mark.")
	assert_true(_string_values(cold_state.get("spent_pressure_ids", [])).has("mart_cold_storage_bite"), "Cold storage pressure should be marked spent.")
	assert_eq(String(cold_state.get("last_pressure_message", "")), "냉장 보관실의 찬 공기가 옷 안으로 파고들어 체온을 빼앗는다.", "Cold storage should record a pressure message.")
	assert_true(String(cold_state.get("last_feedback_message", "")).find(String(cold_state.get("last_pressure_message", ""))) != -1, "Action feedback should include the pressure message.")

	var gate_run_state = _build_run_state(run_state_script)
	var gate_state := _event_state_for_zone("staff_corridor_gate")
	var health_before := float(gate_run_state.health)
	var minute_before := int(gate_run_state.clock.minute_of_day)
	fatigue_before = float(gate_run_state.fatigue)
	assert_true(resolver.apply_action(gate_run_state, event_data, gate_state, "force_staff_gate"), "Forced staff gate action should resolve.")
	assert_eq(float(gate_run_state.health), health_before - 1.0, "Forced gate pressure should chip health.")
	assert_true(float(gate_run_state.fatigue) >= fatigue_before + 3.0, "Forced gate pressure should add fatigue on top of action time.")
	assert_eq(int(gate_state.get("noise", 0)), 3, "Forced gate should combine base noise and pressure noise.")
	assert_true(_string_values(gate_state.get("spent_pressure_ids", [])).has("mart_staff_gate_bang"), "Forced gate pressure should be marked spent.")
	assert_true(_string_values(gate_state.get("resolved_noise_threshold_ids", [])).has("noise_attention_3"), "Crossing noise 3 should resolve the first noise escalation.")
	assert_true(not String(gate_state.get("last_noise_message", "")).is_empty(), "Crossing noise 3 should leave a noise feedback message.")
	assert_eq(int(gate_run_state.clock.minute_of_day), minute_before + 15, "Forced gate should include the extra wait from noise escalation.")

	var tool_gate_run_state = _build_run_state(run_state_script)
	assert_true(tool_gate_run_state.inventory.add_item({"id": "screwdriver", "name": "Screwdriver", "bulk": 1}), "Tool gate test should seed a screwdriver.")
	var tool_gate_state := _event_state_for_zone("staff_corridor_gate")
	var tool_gate_actions := _action_ids(resolver.get_actions(event_data, tool_gate_state, tool_gate_run_state))
	assert_true(tool_gate_actions.has("jimmy_staff_gate_with_screwdriver"), "A screwdriver should unlock a quieter staff-gate option.")
	health_before = float(tool_gate_run_state.health)
	fatigue_before = float(tool_gate_run_state.fatigue)
	assert_true(resolver.apply_action(tool_gate_run_state, event_data, tool_gate_state, "jimmy_staff_gate_with_screwdriver"), "Screwdriver staff-gate option should resolve.")
	assert_eq(float(tool_gate_run_state.health), health_before, "Tool gate path should avoid the hand injury from forcing the door.")
	assert_true(float(tool_gate_run_state.fatigue) >= fatigue_before + 1.0, "Tool gate path should still cost effort.")
	assert_eq(int(tool_gate_state.get("noise", 0)), 0, "Tool gate path should stay quiet enough to avoid noise escalation.")
	assert_true(_string_values(tool_gate_state.get("spent_pressure_ids", [])).has("mart_staff_gate_jimmy"), "Tool gate pressure should be marked spent.")
	assert_true(not _action_ids(resolver.get_actions(event_data, tool_gate_state, tool_gate_run_state)).has("force_staff_gate"), "Opening the staff gate should remove the brute-force alternative.")

	var garage_event_data: Dictionary = resolver.load_event(GARAGE_EVENT_PATH)
	if not assert_true(not garage_event_data.is_empty(), "Garage event data should load."):
		return
	var garage_run_state = _build_run_state(run_state_script)
	var garage_state := _event_state_for_zone("service_pit")
	health_before = float(garage_run_state.health)
	assert_true(resolver.apply_action(garage_run_state, garage_event_data, garage_state, "search_service_pit_once"), "Service pit search should resolve.")
	assert_eq(float(garage_run_state.health), health_before - 2.0, "Service pit pressure should chip health.")
	assert_eq(int(garage_state.get("noise", 0)), 1, "Service pit pressure should add noise in the pit, not on the garage floor.")
	assert_true(_string_values(garage_state.get("spent_pressure_ids", [])).has("garage_service_pit_slip"), "Service pit pressure should be marked spent.")

	var warehouse_event_data: Dictionary = resolver.load_event(WAREHOUSE_EVENT_PATH)
	if not assert_true(not warehouse_event_data.is_empty(), "Warehouse event data should load."):
		return
	var warehouse_run_state = _build_run_state(run_state_script)
	var shutter_state := _event_state_for_zone("shutter_gate")
	shutter_state["noise"] = 5
	shutter_state["resolved_noise_threshold_ids"] = PackedStringArray(["noise_attention_3"])
	exposure_before = float(warehouse_run_state.exposure)
	assert_true(resolver.apply_action(warehouse_run_state, warehouse_event_data, shutter_state, "inspect_shutter_gate"), "Warehouse shutter inspection should resolve.")
	assert_eq(int(shutter_state.get("noise", 0)), 7, "Warehouse shutter pressure should add noise to existing site noise.")
	assert_true(_string_values(shutter_state.get("spent_pressure_ids", [])).has("warehouse_shutter_rattle"), "Warehouse shutter pressure should be marked spent.")
	assert_true(_string_values(shutter_state.get("resolved_noise_threshold_ids", [])).has("noise_attention_6"), "Crossing noise 6 should resolve the second noise escalation.")
	assert_eq(float(warehouse_run_state.exposure), exposure_before - 3.0, "Noise 6 escalation should cost exposure while waiting.")

	pass_test("INDOOR_PRESSURE_OUTCOMES_OK")


func _build_run_state(run_state_script: Script):
	return run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)


func _event_state_for_zone(zone_id: String) -> Dictionary:
	return {
		"current_zone_id": zone_id,
		"visited_zone_ids": PackedStringArray([zone_id]),
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"spent_pressure_ids": PackedStringArray(),
		"resolved_noise_threshold_ids": PackedStringArray(),
		"zone_flags": {},
		"zone_loot_entries": {},
		"zone_supply_sources": {},
		"last_pressure_message": "",
		"last_noise_message": "",
		"noise": 0,
	}


func _string_values(values_variant: Variant) -> PackedStringArray:
	var values := PackedStringArray()
	if typeof(values_variant) != TYPE_ARRAY and typeof(values_variant) != TYPE_PACKED_STRING_ARRAY:
		return values

	for value in values_variant:
		values.append(String(value))
	return values


func _action_ids(actions: Array[Dictionary]) -> PackedStringArray:
	var ids := PackedStringArray()
	for action in actions:
		ids.append(String(action.get("id", "")))
	return ids


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
