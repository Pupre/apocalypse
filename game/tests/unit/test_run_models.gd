extends "res://tests/support/test_case.gd"


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
	"light_sleeper": {
		"id": "light_sleeper",
		"modifiers": {
			"sleep_hours_adjustment": -1,
		},
	},
}


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_state_script: Script = load("res://scripts/run/run_state.gd")
	var time_clock_script: Script = load("res://scripts/run/time_clock.gd")
	var content_source = self

	var clock = time_clock_script.new()
	assert_eq(clock.day_index, 1, "TimeClock should start on day one.")
	assert_eq(clock.minute_of_day, 480, "TimeClock should start at 08:00.")
	assert_eq(clock.get_clock_label(), "1일차 08:00", "TimeClock should expose a readable label.")

	clock.advance_minutes(-30)
	assert_eq(clock.day_index, 1, "Negative clock input should not rewind the day.")
	assert_eq(clock.minute_of_day, 480, "Negative clock input should not rewind the time.")

	clock.advance_minutes(180)
	assert_eq(clock.day_index, 1, "Advancing the clock should stay on day one for three hours.")
	assert_eq(clock.minute_of_day, 660, "TimeClock should advance to 11:00 after three hours.")
	assert_eq(clock.get_clock_label(), "1일차 11:00", "Clock label should update after advancing.")

	var state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete", "light_sleeper"]),
		"remaining_points": 0,
	}, content_source)
	assert_true(state != null, "Injected content source should produce a valid run state.")
	assert_true(state.has_method("get_hunger_stage"), "RunState should expose a hunger stage helper.")
	assert_true(state.has_method("get_thirst_stage"), "RunState should expose a thirst stage helper.")
	assert_true(state.has_method("get_health_stage"), "RunState should expose a health stage helper.")
	assert_true(state.has_method("get_fatigue_stage"), "RunState should expose a fatigue stage helper.")

	assert_eq(state.clock.day_index, 1, "RunState should start on day one.")
	assert_eq(state.clock.minute_of_day, 480, "RunState should start at 08:00.")
	assert_eq(state.clock.get_clock_label(), "1일차 08:00", "RunState clock label should be readable.")
	assert_eq(int(state.move_speed), 230, "Job and trait modifiers should increase move speed.")
	assert_eq(state.fatigue_model.get_band(state.fatigue), "양호", "Fresh runs should start in the light fatigue band.")
	assert_eq(state.get_hunger_stage(), "든든함", "Fresh runs should start well-fed.")
	assert_eq(state.get_thirst_stage(), "수분 충분", "Fresh runs should start hydrated.")
	assert_eq(state.get_health_stage(), "안정", "Fresh runs should start healthy.")
	assert_eq(state.get_fatigue_stage(), "양호", "Fatigue stage helper should mirror the fatigue model band.")
	assert_eq(state.inventory.carry_limit, 8, "This build should keep the default carry limit.")

	var before_hunger_after_spawn: float = state.hunger
	var before_thirst_after_spawn: float = state.thirst
	state.advance_minutes(180)

	assert_eq(state.clock.day_index, 1, "Three hours should stay on day one.")
	assert_eq(state.clock.minute_of_day, 660, "Clock should advance from 08:00 to 11:00.")
	assert_eq(state.clock.get_clock_label(), "1일차 11:00", "RunState clock label should reflect elapsed time.")
	assert_true(state.hunger < before_hunger_after_spawn, "Active time should reduce hunger reserves.")
	assert_true(state.thirst < before_thirst_after_spawn, "Active time should reduce thirst reserves.")

	var before_day_index: int = state.clock.day_index
	var before_minute_of_day: int = state.clock.minute_of_day
	var before_fatigue: float = state.fatigue
	var before_hunger: float = state.hunger
	var before_thirst: float = state.thirst

	state.advance_minutes(-15)
	assert_eq(state.clock.day_index, before_day_index, "Negative active-run time should not rewind the day.")
	assert_eq(state.clock.minute_of_day, before_minute_of_day, "Negative active-run time should not rewind the clock.")
	assert_eq(state.fatigue, before_fatigue, "Negative active-run time should not reduce fatigue.")
	assert_eq(state.hunger, before_hunger, "Negative active-run time should not change hunger.")
	assert_eq(state.thirst, before_thirst, "Negative active-run time should not change thirst.")

	state.advance_sleep_time(-20)
	assert_eq(state.clock.day_index, before_day_index, "Negative sleep time should not rewind the day.")
	assert_eq(state.clock.minute_of_day, before_minute_of_day, "Negative sleep time should not rewind the clock.")
	assert_eq(state.fatigue, before_fatigue, "Negative sleep time should not reduce fatigue.")
	assert_eq(state.hunger, before_hunger, "Negative sleep time should not change hunger.")
	assert_eq(state.thirst, before_thirst, "Negative sleep time should not change thirst.")

	var indoor_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_source)
	var outdoor_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_source)
	assert_true(indoor_state != null and outdoor_state != null, "Comparison run states should build for indoor/outdoor survival checks.")
	indoor_state.advance_minutes(60, "indoor")
	outdoor_state.advance_minutes(60, "outdoor")
	assert_true(outdoor_state.thirst < indoor_state.thirst, "Outdoor time should drain thirst faster than indoor time.")
	assert_true(outdoor_state.hunger < indoor_state.hunger, "Outdoor time should drain hunger faster than indoor time.")
	assert_true(outdoor_state.fatigue > indoor_state.fatigue, "Outdoor time should build fatigue faster than indoor time.")

	var starvation_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_source)
	assert_true(starvation_state != null, "RunState should build for zero-state damage checks.")
	starvation_state.hunger = 0.0
	starvation_state.thirst = 50.0
	starvation_state.health = 100.0
	starvation_state.advance_minutes(30, "indoor")
	assert_true(starvation_state.health < 100.0, "Zero hunger should cause ongoing health loss over time.")

	var dehydration_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_source)
	assert_true(dehydration_state != null, "RunState should build for thirst damage checks.")
	dehydration_state.hunger = 50.0
	dehydration_state.thirst = 0.0
	dehydration_state.health = 100.0
	dehydration_state.advance_minutes(30, "indoor")
	assert_true(dehydration_state.health < starvation_state.health, "Zero thirst should damage health more harshly than zero hunger.")

	state.fatigue = 52.0
	var sleep_preview: Dictionary = state.get_sleep_preview()
	assert_eq(sleep_preview["sleep_minutes"], 420, "Fatigue preview should map to seven hours of sleep.")
	assert_eq(sleep_preview["band"], "피곤", "Sleep preview should preserve the current fatigue band.")

	var canned_beans := {"id": "canned_beans", "bulk": 1}
	assert_true(state.inventory.can_add(canned_beans), "Inventory should accept a small loot item.")

	var added: bool = state.inventory.add_item(canned_beans)
	assert_true(added, "Inventory should accept a small loot item.")
	assert_eq(state.inventory.total_bulk(), 1, "Inventory bulk should reflect the added item.")
	assert_true(state.inventory.remove_first_item_by_id("canned_beans"), "Inventory should let the caller remove an item by id.")
	assert_eq(state.inventory.total_bulk(), 0, "Removing an item should reduce the carried bulk.")
	assert_true(not state.inventory.remove_first_item_by_id("missing_item"), "Removing a missing item id should fail cleanly.")

	assert_true(state.inventory.add_item({"id": "running_shoes", "name": "운동화", "bulk": 1}), "Inventory should hold an equippable speed item.")
	var equipped_shoes: Dictionary = state.equip_inventory_item("running_shoes", {
		"id": "running_shoes",
		"name": "운동화",
		"equip_slot": "feet",
		"move_speed_bonus": 24
	})
	assert_true(bool(equipped_shoes.get("ok", false)), "RunState should allow equipping movement gear.")
	assert_eq(int(state.move_speed), 254, "Equipping shoes should increase move speed.")

	assert_true(state.inventory.add_item({"id": "small_backpack", "name": "작은 배낭", "bulk": 2}), "Inventory should hold an equippable backpack.")
	var equipped_backpack: Dictionary = state.equip_inventory_item("small_backpack", {
		"id": "small_backpack",
		"name": "작은 배낭",
		"equip_slot": "back",
		"carry_limit_bonus": 4
	})
	assert_true(bool(equipped_backpack.get("ok", false)), "RunState should allow equipping a backpack.")
	assert_eq(state.inventory.carry_limit, 12, "Equipping a backpack should increase the soft carry limit.")

	assert_true(state.inventory.add_item({"id": "utility_vest", "name": "작업 조끼", "bulk": 2}), "Inventory should hold an equippable torso item.")
	var equipped_vest: Dictionary = state.equip_inventory_item("utility_vest", {
		"id": "utility_vest",
		"name": "작업 조끼",
		"equip_slot": "body",
		"carry_limit_bonus": 2
	})
	assert_true(bool(equipped_vest.get("ok", false)), "RunState should allow equipping torso gear.")
	assert_eq(state.inventory.carry_limit, 14, "Equipping torso storage gear should stack with the backpack carry bonus.")

	for index in range(15):
		assert_true(state.inventory.add_item({"id": "weight_%d" % index, "bulk": 1}), "Inventory should allow a few items beyond the soft limit for overload testing.")

	assert_true(state.inventory.total_bulk() > state.inventory.carry_limit, "Overflow test should exceed the soft carry limit.")
	assert_true(state.get_outdoor_move_speed() < state.move_speed, "Exceeding the soft carry limit should reduce outdoor move speed.")

	var bad_trait_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete", "missing_trait"]),
		"remaining_points": 0,
	}, content_source, false)
	assert_true(bad_trait_state == null, "Unknown trait ids should fail construction cleanly.")

	var invalid_job_state = run_state_script.from_survivor_config({
		"job_id": "missing_job",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_source, false)
	assert_true(invalid_job_state == null, "Unknown job ids should fail construction cleanly.")

	var missing_method_source := RefCounted.new()
	var missing_method_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, missing_method_source, false)
	assert_true(missing_method_state == null, "Missing content source methods should fail construction cleanly.")

	pass_test("RUN_MODELS_OK")


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
