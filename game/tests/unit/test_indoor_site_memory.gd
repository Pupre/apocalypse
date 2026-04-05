extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_state = load(RUN_STATE_SCRIPT_PATH).from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	})

	var memory_a: Dictionary = run_state.get_or_create_site_memory("mart_01", "mart_entrance")
	assert_eq(String(memory_a.get("entry_zone_id", "")), "mart_entrance", "New site memory should remember entry zone.")

	run_state.enter_indoor_site("mart_01", "mart_entrance")
	run_state.drop_item_in_current_zone_data({"id": "newspaper", "name": "신문지", "bulk": 1})
	var memory_b: Dictionary = run_state.get_or_create_site_memory("mart_01", "mart_entrance")
	var zone_loot: Dictionary = memory_b.get("zone_loot_entries", {})
	assert_true(zone_loot.has("mart_entrance"), "Dropped items should be stored under the current zone.")

	run_state.enter_indoor_site("office_01", "office_lobby")
	run_state.enter_indoor_site("mart_01", "mart_entrance")
	var memory_c: Dictionary = run_state.get_or_create_site_memory("mart_01", "mart_entrance")
	assert_true((memory_c.get("zone_loot_entries", {}) as Dictionary).has("mart_entrance"), "Site memory should persist across building transitions.")

	pass_test("INDOOR_SITE_MEMORY_OK")
