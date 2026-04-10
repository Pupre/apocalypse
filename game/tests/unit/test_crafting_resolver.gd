extends "res://tests/support/test_case.gd"

const CRAFTING_RESOLVER_SCRIPT_PATH := "res://scripts/crafting/crafting_resolver.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var content_library = root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary autoload should be available for crafting resolution tests."):
		return

	var resolver_script := load(CRAFTING_RESOLVER_SCRIPT_PATH) as Script
	if not assert_true(resolver_script != null, "CraftingResolver script should exist at %s." % CRAFTING_RESOLVER_SCRIPT_PATH):
		return

	var resolver = resolver_script.new()
	if not assert_true(resolver != null, "CraftingResolver should instantiate."):
		return

	assert_true(resolver.has_method("resolve"), "CraftingResolver should expose resolve(...).")
	assert_true(resolver.has_method("resolve_attempt"), "CraftingResolver should keep resolve_attempt(...) as a compatibility alias.")

	var success_result: Dictionary = resolver.resolve("newspaper", "cooking_oil", "indoor", content_library)
	assert_eq(String(success_result.get("result_type", "")), "success", "Known success pairs should resolve as success.")
	assert_eq(String(success_result.get("result_item_id", "")), "dense_fuel", "Known success pairs should expose the configured result item.")
	var required_tool_ids: Array = success_result.get("required_tool_ids", [])
	assert_true(not required_tool_ids.has("lighter"), "The dense fuel seed recipe should remain an assembly recipe without a lighter tool.")
	var tool_charge_costs: Dictionary = success_result.get("tool_charge_costs", {})
	assert_eq(int(tool_charge_costs.get("lighter", 0)), 0, "The dense fuel seed recipe should not spend lighter charges.")
	assert_eq(int(success_result.get("minutes_elapsed", -1)), 15, "Indoor resolution should preserve the configured indoor craft time.")

	var hot_water_result: Dictionary = resolver.resolve("bottled_water", "can_stove", "indoor", content_library)
	assert_eq(String(hot_water_result.get("result_type", "")), "success", "Heating recipes should still resolve as success.")
	assert_eq(String(hot_water_result.get("result_item_id", "")), "hot_water", "Heating recipes should expose the configured hot_water output.")
	required_tool_ids = hot_water_result.get("required_tool_ids", [])
	assert_true(required_tool_ids.has("lighter"), "Heating water should require a lighter tool.")
	tool_charge_costs = hot_water_result.get("tool_charge_costs", {})
	assert_eq(int(tool_charge_costs.get("lighter", 0)), 1, "Heating water should spend one lighter charge.")

	var failure_result: Dictionary = resolver.resolve("newspaper", "bottled_water", "indoor", content_library)
	assert_eq(String(failure_result.get("result_type", "")), "failure", "Configured bad pairs should still resolve into a failure result.")
	assert_eq(String(failure_result.get("result_item_id", "")), "wet_newspaper", "Failure pairs should expose their failure result item.")

	var invalid_result: Dictionary = resolver.resolve("bottled_water", "rubber_band", "indoor", content_library)
	assert_eq(String(invalid_result.get("result_type", "")), "invalid", "Unknown pairs should resolve as invalid attempts.")
	assert_true(bool(invalid_result.get("returns_inputs", false)), "Invalid pairs should explicitly keep both input items.")
	pass_test("CRAFTING_RESOLVER_OK")
