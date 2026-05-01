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
	var live_content_library := root.get_node_or_null("ContentLibrary")

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
	assert_true(state.has_method("get_difficulty_id"), "RunState should expose a difficulty helper.")
	assert_true(state.has_method("is_easy_mode"), "RunState should expose easy-mode helper.")
	assert_true(state.has_method("is_hard_mode"), "RunState should expose hard-mode helper.")
	assert_eq(state.get_difficulty_id(), "easy", "Runs without an explicit difficulty should default to easy.")
	assert_true(state.is_easy_mode(), "Default difficulty should enable easy mode.")
	assert_true(not state.is_hard_mode(), "Default difficulty should not enable hard mode.")
	assert_eq(state.inventory.carry_limit, 8, "This build should keep the default carry limit.")
	assert_true(state.known_recipe_ids.is_empty(), "A fresh run should start with no known recipes.")
	assert_true(state.read_knowledge_item_ids.is_empty(), "A fresh run should start with no read knowledge items.")
	assert_true(state.has_method("mark_outdoor_block_visited"), "RunState should expose outdoor visited-block helpers.")
	assert_true(state.has_method("is_outdoor_block_visited"), "RunState should expose outdoor visited-block lookup.")
	assert_true(state.has_method("get_visited_outdoor_block_keys"), "RunState should expose a visited-block snapshot.")
	assert_true(state.get_visited_outdoor_block_keys().is_empty(), "Fresh runs should start with no revealed outdoor blocks.")
	state.mark_outdoor_block_visited(Vector2i(0, 0))
	state.mark_outdoor_block_visited(Vector2i(1, 0))
	assert_true(state.is_outdoor_block_visited(Vector2i(0, 0)), "Visited outdoor blocks should remain known for the current run.")
	assert_true(state.is_outdoor_block_visited(Vector2i(1, 0)), "Multiple visited outdoor blocks should accumulate.")
	assert_eq(state.get_visited_outdoor_block_keys().size(), 2, "Visited-block tracking should deduplicate repeated visits.")

	var hard_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
		"difficulty": "hard",
	}, content_source)
	assert_true(hard_state != null, "RunState should accept explicit hard difficulty.")
	assert_eq(hard_state.get_difficulty_id(), "hard", "RunState should preserve explicit hard difficulty.")
	assert_true(not hard_state.is_easy_mode(), "Hard difficulty should disable easy-mode helpers.")
	assert_true(hard_state.is_hard_mode(), "Hard difficulty should be queryable.")

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

	var before_warm_gear_multiplier: float = state.get_outdoor_exposure_drain_multiplier()
	assert_true(state.inventory.add_item({"id": "scarf", "name": "Scarf", "bulk": 1}), "Inventory should hold an equippable neck warmth item.")
	var equipped_scarf: Dictionary = state.equip_inventory_item("scarf", {
		"id": "scarf",
		"name": "Scarf",
		"equip_slot": "neck",
		"equip_effects": {
			"outdoor_exposure_drain_multiplier": 0.96,
		},
	})
	assert_true(bool(equipped_scarf.get("ok", false)), "RunState should allow equipping wearable warmth gear.")
	assert_true(state.equipped_items.has("neck"), "Warmth gear should occupy its authored equipment layer.")
	assert_true(state.get_outdoor_exposure_drain_multiplier() < before_warm_gear_multiplier, "Equipped warmth gear should reduce outdoor exposure drain.")

	var bare_ice_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	var prepared_ice_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	assert_true(bare_ice_state != null and prepared_ice_state != null, "RunState should build for outdoor hazard gear checks.")
	assert_true(prepared_ice_state.inventory.add_item(live_content_library.get_item("running_shoes")), "Hazard gear tests should add running shoes.")
	assert_true(bool(prepared_ice_state.equip_inventory_item("running_shoes", live_content_library.get_item("running_shoes")).get("ok", false)), "Running shoes should equip for hazard checks.")
	var black_ice_hazard := {
		"kind": "black_ice",
		"exposure_loss": 2.0,
		"fatigue_gain": 2.0,
		"health_loss": 1.0,
	}
	var bare_ice_health_before: float = bare_ice_state.health
	var bare_ice_fatigue_before: float = bare_ice_state.fatigue
	bare_ice_state.apply_outdoor_hazard_contact(black_ice_hazard)
	var prepared_ice_health_before: float = prepared_ice_state.health
	var prepared_ice_fatigue_before: float = prepared_ice_state.fatigue
	prepared_ice_state.apply_outdoor_hazard_contact(black_ice_hazard)
	assert_true(
		(prepared_ice_health_before - prepared_ice_state.health) < (bare_ice_health_before - bare_ice_state.health),
		"Equipped footwear should reduce black-ice injury risk."
	)
	assert_true(
		(prepared_ice_state.fatigue - prepared_ice_fatigue_before) < (bare_ice_state.fatigue - bare_ice_fatigue_before),
		"Equipped footwear should reduce black-ice fatigue pressure."
	)

	var bare_wind_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	var prepared_wind_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	assert_true(bare_wind_state != null and prepared_wind_state != null, "RunState should build for wind-gap gear checks.")
	assert_true(prepared_wind_state.inventory.add_item(live_content_library.get_item("scarf_mask")), "Wind gear tests should add a scarf mask.")
	assert_true(bool(prepared_wind_state.equip_inventory_item("scarf_mask", live_content_library.get_item("scarf_mask")).get("ok", false)), "Scarf mask should equip for wind checks.")
	var wind_gap_hazard := {
		"kind": "wind_gap",
		"exposure_loss": 3.0,
		"fatigue_gain": 1.0,
	}
	var bare_wind_exposure_before: float = bare_wind_state.exposure
	var bare_wind_fatigue_before: float = bare_wind_state.fatigue
	bare_wind_state.apply_outdoor_hazard_contact(wind_gap_hazard)
	var prepared_wind_exposure_before: float = prepared_wind_state.exposure
	var prepared_wind_fatigue_before: float = prepared_wind_state.fatigue
	prepared_wind_state.apply_outdoor_hazard_contact(wind_gap_hazard)
	assert_true(
		(prepared_wind_exposure_before - prepared_wind_state.exposure) < (bare_wind_exposure_before - bare_wind_state.exposure),
		"Face-cover gear should reduce wind-gap exposure loss."
	)
	assert_true(
		(prepared_wind_state.fatigue - prepared_wind_fatigue_before) < (bare_wind_state.fatigue - bare_wind_fatigue_before),
		"Face-cover gear should reduce wind-gap fatigue pressure."
	)

	for index in range(15):
		assert_true(state.inventory.add_item({"id": "weight_%d" % index, "bulk": 1}), "Inventory should allow a few items beyond the soft limit for overload testing.")

	assert_true(state.inventory.total_bulk() > state.inventory.carry_limit, "Overflow test should exceed the soft carry limit.")
	assert_true(state.get_outdoor_move_speed() < state.move_speed, "Exceeding the soft carry limit should reduce outdoor move speed.")

	var consume_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_source)
	assert_true(consume_state != null, "RunState should build for item consumption checks.")
	consume_state.hunger = 40.0
	consume_state.thirst = 25.0
	consume_state.health = 55.0
	consume_state.fatigue = 32.0
	assert_true(consume_state.inventory.add_item({"id": "energy_bar", "name": "에너지바", "bulk": 1}), "Inventory should hold a food item for consumption tests.")
	assert_true(consume_state.inventory.add_item({"id": "bottled_water", "name": "생수", "bulk": 1}), "Inventory should hold a drink item for consumption tests.")
	assert_true(consume_state.inventory.add_item({"id": "bandage", "name": "붕대", "bulk": 1}), "Inventory should hold a medicine item for consumption tests.")
	assert_true(consume_state.inventory.add_item({"id": "instant_coffee", "name": "인스턴트 커피", "bulk": 1}), "Inventory should hold a stimulant item for consumption tests.")
	assert_true(consume_state.consume_inventory_item("energy_bar", {"hunger_restore": 10.0}), "Food consumption should succeed when the item is present.")
	assert_eq(consume_state.hunger, 50.0, "Food consumption should restore hunger reserves.")
	assert_true(consume_state.consume_inventory_item("bottled_water", {"thirst_restore": 30.0}), "Drink consumption should succeed when the item is present.")
	assert_eq(consume_state.thirst, 55.0, "Drink consumption should restore thirst reserves.")
	assert_true(consume_state.consume_inventory_item("bandage", {"health_restore": 12.0}), "Medicine consumption should succeed when the item is present.")
	assert_eq(consume_state.health, 67.0, "Medicine consumption should restore health.")
	assert_true(consume_state.consume_inventory_item("instant_coffee", {"fatigue_restore": 8.0}), "Stimulant consumption should succeed when the item is present.")
	assert_eq(consume_state.fatigue, 24.0, "Stimulant consumption should reduce fatigue.")

	var crafting_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	assert_true(crafting_state != null, "RunState should build for crafting checks.")
	assert_true(crafting_state.has_method("attempt_craft"), "RunState should expose one shared crafting entry point.")

	assert_true(crafting_state.inventory.add_item({"id": "newspaper", "name": "신문지", "bulk": 1}), "Crafting test inventory should hold newspaper.")
	assert_true(crafting_state.inventory.add_item({"id": "cooking_oil", "name": "식용유", "bulk": 1}), "Crafting test inventory should hold cooking oil.")
	var outdoor_craft_result: Dictionary = crafting_state.attempt_craft("newspaper", "cooking_oil", "outdoor")
	assert_eq(String(outdoor_craft_result.get("result_type", "")), "success", "Outdoor crafting should resolve valid recipes.")
	assert_eq(String(outdoor_craft_result.get("result_item_id", "")), "dense_fuel", "Outdoor crafting should create the configured recipe output.")
	assert_eq(int(outdoor_craft_result.get("minutes_elapsed", -1)), 0, "Outdoor crafting should not add explicit minute costs.")
	assert_true(crafting_state.inventory.count_item_by_id("newspaper") == 0, "Successful crafting should consume the first ingredient.")
	assert_true(crafting_state.inventory.count_item_by_id("cooking_oil") == 0, "Successful crafting should consume the second ingredient.")
	assert_true(crafting_state.inventory.count_item_by_id("dense_fuel") == 1, "Successful crafting should add the result item to the inventory.")
	assert_true(crafting_state.known_recipe_ids.has("newspaper__cooking_oil"), "Successful crafting should unlock the recipe in the run-state codex.")

	var heating_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	assert_true(heating_state != null, "RunState should build for richer recipe checks.")
	assert_true(heating_state.inventory.add_item({"id": "bottled_water", "name": "생수", "bulk": 1}), "Heating tests should hold bottled water.")
	assert_true(heating_state.inventory.add_item({"id": "can_stove", "name": "깡통 화로", "bulk": 2}), "Heating tests should hold a reusable heat source.")
	var missing_heat_tool: Dictionary = heating_state.attempt_craft("bottled_water", "can_stove", "indoor")
	assert_true(not bool(missing_heat_tool.get("ok", false)), "Heating water should fail cleanly when the lighter tool is missing.")
	assert_eq(String(missing_heat_tool.get("reason", "")), "missing_tool", "Heating water should explain that the lighter tool is missing.")
	assert_true(heating_state.inventory.add_item({"id": "lighter", "name": "라이터", "bulk": 1, "charges_current": 5, "charges_max": 5}), "Heating tests should hold a lighter tool.")
	var hot_water_outcome: Dictionary = heating_state.attempt_craft("bottled_water", "can_stove", "indoor")
	assert_eq(String(hot_water_outcome.get("result_item_id", "")), "hot_water", "Heating water should produce hot_water.")
	assert_eq(heating_state.inventory.count_item_by_id("can_stove"), 1, "Heating water should keep the can stove.")
	assert_true(heating_state.known_recipe_ids.has("bottled_water__can_stove"), "Successful heating should unlock the hot-water recipe.")
	assert_eq(heating_state.get_tool_charges("lighter"), 4, "Heating water should spend one lighter charge.")

	var insulation_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	assert_true(insulation_state != null, "RunState should build for insulation recipe checks.")
	assert_true(insulation_state.inventory.add_item({"id": "bubble_wrap_roll", "name": "뽁뽁이 롤", "bulk": 1}), "Insulation tests should hold bubble wrap.")
	assert_true(insulation_state.inventory.add_item({"id": "duct_tape", "name": "덕트테이프", "bulk": 1}), "Insulation tests should hold duct tape.")
	var patch_outcome: Dictionary = insulation_state.attempt_craft("bubble_wrap_roll", "duct_tape", "indoor")
	assert_eq(String(patch_outcome.get("result_item_id", "")), "window_cover_patch", "Insulation recipes should produce patch items.")

	var indoor_craft_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	assert_true(indoor_craft_state != null, "RunState should build for indoor lighter-gated crafting checks.")
	assert_true(indoor_craft_state.inventory.add_item(live_content_library.get_item("newspaper")), "Indoor crafting tests should add newspaper.")
	assert_true(indoor_craft_state.inventory.add_item(live_content_library.get_item("cooking_oil")), "Indoor crafting tests should add cooking oil.")
	var before_indoor_craft_minute: int = indoor_craft_state.clock.minute_of_day
	var indoor_craft_result: Dictionary = indoor_craft_state.attempt_craft("newspaper", "cooking_oil", "indoor")
	assert_true(bool(indoor_craft_result.get("ok", false)), "Indoor dense-fuel crafting should succeed without a lighter tool.")
	assert_eq(String(indoor_craft_result.get("result_item_id", "")), "dense_fuel", "Indoor crafting should still produce dense_fuel.")
	assert_eq(indoor_craft_state.clock.minute_of_day, before_indoor_craft_minute + 15, "Indoor crafting should spend the configured explicit minute cost.")
	assert_true(indoor_craft_state.known_recipe_ids.has("newspaper__cooking_oil"), "Indoor crafting should unlock the dense-fuel recipe.")

	var knowledge_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	assert_true(knowledge_state != null, "RunState should build for knowledge-note checks.")
	assert_true(knowledge_state.read_knowledge_item("improvised_heat_note_01"), "Knowledge notes should be readable.")
	assert_true(knowledge_state.known_recipe_ids.has("newspaper__cooking_oil"), "Reading a heat note should unlock its mapped recipes.")
	assert_true(knowledge_state.read_knowledge_item_ids.has("improvised_heat_note_01"), "Reading should mark the note as already read.")
	assert_true(not knowledge_state.read_knowledge_item("improvised_heat_note_01"), "Reading the same note twice should not unlock anything new.")

	var blocked_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	assert_true(blocked_state != null, "RunState should build for context-restricted crafting checks.")
	assert_true(blocked_state.inventory.add_item({"id": "bottled_water", "name": "생수", "bulk": 1}), "Context tests should hold bottled water.")
	assert_true(blocked_state.inventory.add_item({"id": "can_stove", "name": "깡통 화로", "bulk": 2}), "Context tests should hold a heat source.")
	var blocked_outcome: Dictionary = blocked_state.attempt_craft("bottled_water", "can_stove", "outdoor")
	assert_eq(String(blocked_outcome.get("result_type", "")), "invalid", "Indoor-only heating recipes should be blocked outdoors.")

	var failure_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	assert_true(failure_state != null, "RunState should build for failure crafting checks.")
	assert_true(failure_state.inventory.add_item({"id": "newspaper", "name": "신문지", "bulk": 1}), "Failure crafting tests should hold newspaper.")
	assert_true(failure_state.inventory.add_item({"id": "bottled_water", "name": "생수", "bulk": 1}), "Failure crafting tests should hold water.")
	var before_failure_clock: int = failure_state.clock.minute_of_day
	var failure_result: Dictionary = failure_state.attempt_craft("newspaper", "bottled_water", "indoor")
	assert_eq(String(failure_result.get("result_type", "")), "failure", "Indoor crafting should expose configured failure outcomes.")
	assert_eq(String(failure_result.get("result_item_id", "")), "wet_newspaper", "Indoor crafting failure recipes should still produce their configured outputs.")
	assert_true(int(failure_result.get("minutes_elapsed", 0)) > 0, "Indoor crafting should spend time for configured recipes.")
	assert_true(failure_state.clock.minute_of_day > before_failure_clock, "Indoor crafting should advance the shared run clock.")
	assert_true(failure_state.inventory.count_item_by_id("wet_newspaper") == 1, "Failure crafting should add the failure result item.")

	var invalid_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	assert_true(invalid_state != null, "RunState should build for invalid crafting checks.")
	assert_true(invalid_state.inventory.add_item({"id": "bottled_water", "name": "생수", "bulk": 1}), "Invalid crafting tests should hold water.")
	assert_true(invalid_state.inventory.add_item({"id": "rubber_band", "name": "고무줄", "bulk": 1}), "Invalid crafting tests should hold rubber bands.")
	var before_invalid_clock: int = invalid_state.clock.minute_of_day
	var invalid_result: Dictionary = invalid_state.attempt_craft("bottled_water", "rubber_band", "indoor")
	assert_eq(String(invalid_result.get("result_type", "")), "invalid", "Unknown pairs should resolve as invalid attempts.")
	assert_true(int(invalid_result.get("minutes_elapsed", 0)) > 0, "Indoor invalid attempts should still spend a small amount of time.")
	assert_eq(invalid_state.inventory.count_item_by_id("bottled_water"), 1, "Invalid crafting should leave the first ingredient untouched.")
	assert_eq(invalid_state.inventory.count_item_by_id("rubber_band"), 1, "Invalid crafting should leave the second ingredient untouched.")
	assert_true(invalid_state.clock.minute_of_day > before_invalid_clock, "Indoor invalid attempts should still advance the clock.")

	var warmth_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, live_content_library)
	assert_true(warmth_state != null, "RunState should build for warmth-item checks.")
	warmth_state.exposure = 40.0
	assert_true(warmth_state.inventory.add_item(live_content_library.get_item("warm_tea")), "Warmth tests should add warm tea from content data.")
	var before_exposure: float = warmth_state.exposure
	assert_true(warmth_state.use_inventory_item("warm_tea"), "Warm drinks should be usable from inventory.")
	assert_true(warmth_state.exposure > before_exposure, "Warm drinks should restore exposure.")
	assert_true(warmth_state.active_warmth_effects.size() == 1, "Warm drinks should add a timed warmth effect.")

	warmth_state.enter_indoor_site("mart_01", "mart_entrance")
	assert_true(warmth_state.inventory.add_item(live_content_library.get_item("window_cover_patch")), "Deployment tests should add an indoor patch from content data.")
	assert_true(warmth_state.deploy_item_in_current_site("window_cover_patch"), "Indoor deploy items should be installable.")
	var indoor_modifiers: Dictionary = warmth_state.get_current_indoor_environment_modifiers()
	assert_true(float(indoor_modifiers.get("indoor_insulation_score", 0.0)) > 0.0, "Deployments should change indoor insulation.")

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
