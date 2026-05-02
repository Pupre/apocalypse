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

	var pressure_bandage_result: Dictionary = resolver.resolve("medical_tape", "sterile_gauze_roll", "indoor", content_library)
	assert_eq(String(pressure_bandage_result.get("result_type", "")), "success", "Medical tape and sterile gauze should make a practical pressure bandage.")
	assert_eq(String(pressure_bandage_result.get("result_item_id", "")), "pressure_bandage", "Medical dressing recipe should expose the pressure bandage output.")
	assert_eq(int(pressure_bandage_result.get("minutes_elapsed", -1)), 4, "Fast medical assembly should keep a short indoor craft time.")

	var draft_blocker_result: Dictionary = resolver.resolve("shop_towel_bundle", "duct_tape", "indoor", content_library)
	assert_eq(String(draft_blocker_result.get("result_type", "")), "success", "Work towels and tape should make a believable draft blocker.")
	assert_eq(String(draft_blocker_result.get("result_item_id", "")), "draft_blocker", "Logistics textiles should feed indoor insulation crafting.")

	var tarp_patch_result: Dictionary = resolver.resolve("tarp_sheet", "duct_tape", "indoor", content_library)
	assert_eq(String(tarp_patch_result.get("result_type", "")), "success", "Tarp and tape should patch a broken opening indoors.")
	assert_eq(String(tarp_patch_result.get("result_item_id", "")), "window_cover_patch", "Tarp patch recipe should output the existing window-cover deployable.")

	var hand_warmer_wrap_result: Dictionary = resolver.resolve("hand_warmer_pack", "scarf", "outdoor", content_library)
	assert_eq(String(hand_warmer_wrap_result.get("result_type", "")), "success", "A scarf should turn a loose heat pack into a useful carry-warmth bundle.")
	assert_eq(String(hand_warmer_wrap_result.get("result_item_id", "")), "hand_warmer_wrap", "Wrapped heat-pack recipe should reuse the carry-warmth output.")
	assert_eq(int(hand_warmer_wrap_result.get("minutes_elapsed", -1)), 0, "Outdoor crafting should not spend indoor action minutes.")

	var warm_cocoa_result: Dictionary = resolver.resolve("hot_water", "instant_cocoa_mix", "indoor", content_library)
	assert_eq(String(warm_cocoa_result.get("result_type", "")), "success", "Bakery cocoa mix should connect to the warm-drink crafting loop.")
	assert_eq(String(warm_cocoa_result.get("result_item_id", "")), "warm_cocoa", "Hot water and cocoa mix should output warm cocoa.")

	var sealed_cocoa_result: Dictionary = resolver.resolve("thermos", "warm_cocoa", "indoor", content_library)
	assert_eq(String(sealed_cocoa_result.get("result_type", "")), "success", "Warm cocoa should be portable in a thermos like the other warm drinks.")
	assert_eq(String(sealed_cocoa_result.get("result_item_id", "")), "sealed_warm_cocoa", "Thermos cocoa should output a sealed warm cocoa drink.")

	var solvent_wipes_result: Dictionary = resolver.resolve("disinfectant_bottle", "shop_towel_bundle", "indoor", content_library)
	assert_eq(String(solvent_wipes_result.get("result_type", "")), "success", "Disinfectant and work towels should make useful cleaning wipes.")
	assert_eq(String(solvent_wipes_result.get("result_item_id", "")), "solvent_wipes", "Disinfectant towel recipe should output solvent wipes.")

	var failure_result: Dictionary = resolver.resolve("newspaper", "bottled_water", "indoor", content_library)
	assert_eq(String(failure_result.get("result_type", "")), "failure", "Configured bad pairs should still resolve into a failure result.")
	assert_eq(String(failure_result.get("result_item_id", "")), "wet_newspaper", "Failure pairs should expose their failure result item.")

	var invalid_result: Dictionary = resolver.resolve("bottled_water", "rubber_band", "indoor", content_library)
	assert_eq(String(invalid_result.get("result_type", "")), "invalid", "Unknown pairs should resolve as invalid attempts.")
	assert_true(bool(invalid_result.get("returns_inputs", false)), "Invalid pairs should explicitly keep both input items.")
	pass_test("CRAFTING_RESOLVER_OK")
