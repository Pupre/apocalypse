extends "res://tests/support/test_case.gd"


const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const NOTE_ITEM_ID := "improvised_heat_note_01"
const HEAT_RECIPE_ID := "bottled_water__can_stove"
const DENSE_FUEL_RECIPE_ID := "newspaper__cooking_oil"

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
	var content_library: Node = root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary should be present for crafting codex tests."):
		return

	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	if not assert_true(run_state_script != null, "RunState script should exist for crafting codex tests."):
		return

	var lighter: Dictionary = content_library.get_item("lighter")
	assert_true(not lighter.is_empty(), "Lighter should still exist.")
	assert_eq(int(lighter.get("charges_max", 0)), 5, "Lighter should expose charges_max for tool gating.")

	var note_item: Dictionary = content_library.get_item(NOTE_ITEM_ID)
	assert_true(bool(note_item.get("readable", false)), "Knowledge items should be readable.")
	assert_true(Array(note_item.get("knowledge_recipe_ids", [])).size() > 0, "Knowledge items should unlock recipes.")

	var heat_recipe: Dictionary = content_library.get_crafting_combination("bottled_water", "can_stove")
	assert_true(not heat_recipe.is_empty(), "The heated-water recipe should exist.")
	assert_true(not String(heat_recipe.get("codex_category", "")).is_empty(), "Heat recipes should expose codex_category.")
	assert_eq(Array(heat_recipe.get("required_tool_ids", [])), ["lighter"], "Heating water should require a lighter.")
	assert_eq(int(Dictionary(heat_recipe.get("tool_charge_costs", {})).get("lighter", 0)), 1, "Heating water should cost one lighter charge.")

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_library)
	if not assert_true(run_state != null, "RunState should build for crafting codex tests."):
		return

	if not assert_true(run_state.has_method("get_tool_charges"), "RunState should expose get_tool_charges(item_id)."):
		return
	if not assert_true(run_state.has_method("read_knowledge_item"), "RunState should expose read_knowledge_item(item_id)."):
		return
	var known_recipe_ids_variant: Variant = run_state.get("known_recipe_ids")
	var read_knowledge_item_ids_variant: Variant = run_state.get("read_knowledge_item_ids")
	if not assert_true(typeof(known_recipe_ids_variant) == TYPE_DICTIONARY, "RunState should expose known_recipe_ids."):
		return
	if not assert_true(typeof(read_knowledge_item_ids_variant) == TYPE_DICTIONARY, "RunState should expose read_knowledge_item_ids."):
		return
	var known_recipe_ids := known_recipe_ids_variant as Dictionary
	var read_knowledge_item_ids := read_knowledge_item_ids_variant as Dictionary
	assert_true(known_recipe_ids.is_empty(), "A fresh run should start with no known recipes.")
	assert_true(read_knowledge_item_ids.is_empty(), "A fresh run should start with no read knowledge items.")
	assert_eq(int(run_state.get_tool_charges("lighter")), 0, "A fresh run should not report lighter charges before one is carried.")

	assert_true(run_state.inventory.add_item(content_library.get_item("lighter")), "Runtime tests should hold a lighter.")
	assert_true(run_state.inventory.add_item(content_library.get_item("bottled_water")), "Runtime tests should hold bottled water.")
	assert_true(run_state.inventory.add_item(content_library.get_item("can_stove")), "Runtime tests should hold a can stove.")
	var heat_result: Dictionary = run_state.attempt_craft("bottled_water", "can_stove", "indoor")
	assert_true(bool(heat_result.get("ok", false)), "Heating water should succeed once the lighter is present.")
	assert_eq(String(heat_result.get("result_item_id", "")), "hot_water", "Heating water should resolve to hot_water.")
	assert_true((run_state.get("known_recipe_ids") as Dictionary).has(HEAT_RECIPE_ID), "Successful crafting should unlock the recipe in the codex.")
	assert_eq(run_state.get_tool_charges("lighter"), 4, "Heating water should spend one lighter charge.")

	var second_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, content_library)
	if not assert_true(second_state != null, "RunState should build for knowledge-note codex tests."):
		return

	assert_true(second_state.read_knowledge_item(NOTE_ITEM_ID), "Knowledge notes should be readable.")
	assert_true((second_state.get("known_recipe_ids") as Dictionary).has(DENSE_FUEL_RECIPE_ID), "Reading a heat note should unlock its mapped recipes.")
	assert_true((second_state.get("read_knowledge_item_ids") as Dictionary).has(NOTE_ITEM_ID), "Reading should mark the note as already read.")
	assert_true(not second_state.read_knowledge_item(NOTE_ITEM_ID), "Reading the same note twice should not unlock anything new.")

	pass_test("CRAFTING_CODEX_OK")


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
