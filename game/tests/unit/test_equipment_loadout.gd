extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	if not assert_true(run_state_script != null, "RunState script should load for equipment loadout tests."):
		return

	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary should be available for equipment loadout tests."):
		return

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
		"difficulty": "easy",
	}, content_library)
	if not assert_true(run_state != null, "RunState should build for equipment loadout tests."):
		return

	var base_carry_capacity := float(run_state.inventory.carry_capacity)
	var small_backpack: Dictionary = content_library.get_item("small_backpack")
	assert_true(not small_backpack.is_empty(), "Small backpack should exist as the baseline back-slot item.")
	assert_true(run_state.inventory.add_item(small_backpack), "Backpack should be addable before equip.")

	var equip_result: Dictionary = run_state.equip_inventory_item("small_backpack", small_backpack)
	assert_true(bool(equip_result.get("ok", false)), "Equipping a carried backpack should succeed.")
	assert_eq(run_state.inventory.count_item_by_id("small_backpack"), 0, "Equipped gear should leave the carried bag.")
	assert_eq(String(run_state.equipped_items.get("back", {}).get("id", "")), "small_backpack", "Back slot should hold the equipped backpack.")
	assert_true(float(run_state.inventory.carry_capacity) > base_carry_capacity, "Equipped backpacks should increase carrying capacity.")

	var larger_pack := {
		"id": "test_larger_pack",
		"name": "테스트 대형 배낭",
		"category": "equipment",
		"equip_slot": "back",
		"carry_weight": 1.0,
		"carry_capacity_bonus": 6.0,
	}
	assert_true(run_state.inventory.add_item(larger_pack), "Replacement pack should fit in the carried bag.")
	var replace_result: Dictionary = run_state.equip_inventory_item("test_larger_pack", larger_pack)
	assert_true(bool(replace_result.get("ok", false)), "Equipping a second back-slot item should replace the first.")
	assert_eq(String(replace_result.get("replaced_item", {}).get("id", "")), "small_backpack", "Replacement result should expose the previous equipped item.")
	assert_eq(String(run_state.equipped_items.get("back", {}).get("id", "")), "test_larger_pack", "Back slot should hold the replacement item.")
	assert_eq(run_state.inventory.count_item_by_id("small_backpack"), 1, "Replaced equipment should return to the bag.")

	var unequip_result: Dictionary = run_state.unequip_slot("back")
	assert_true(bool(unequip_result.get("ok", false)), "Unequipping an occupied slot should succeed.")
	assert_eq(String(unequip_result.get("item", {}).get("id", "")), "test_larger_pack", "Unequip result should expose the removed item.")
	assert_true(not run_state.equipped_items.has("back"), "Unequipped slot should be empty.")
	assert_eq(run_state.inventory.count_item_by_id("test_larger_pack"), 1, "Unequipped gear should return to the bag.")
	assert_eq(snapped(float(run_state.inventory.carry_capacity), 0.01), snapped(base_carry_capacity, 0.01), "Removing the back-slot gear should recalculate carry capacity.")

	var empty_unequip_result: Dictionary = run_state.unequip_slot("back")
	assert_true(not bool(empty_unequip_result.get("ok", false)), "Unequipping an empty slot should report failure.")
	assert_true(not String(empty_unequip_result.get("message", "")).is_empty(), "Failed unequip should explain why it failed.")

	var plastic_bag: Dictionary = content_library.get_item("plastic_bag")
	assert_true(not plastic_bag.is_empty(), "Plastic bag should exist as a lightweight hand-carry container.")
	assert_eq(String(plastic_bag.get("equip_slot", "")), "hand_carry", "Plastic bag should use the hand-carry equipment slot.")
	var hand_carry_base_capacity := float(run_state.inventory.carry_capacity)
	assert_true(run_state.inventory.add_item(plastic_bag), "Plastic bag should be addable before equip.")
	var hand_carry_result: Dictionary = run_state.equip_inventory_item("plastic_bag", plastic_bag)
	assert_true(bool(hand_carry_result.get("ok", false)), "Equipping a plastic bag should succeed.")
	assert_eq(run_state.inventory.count_item_by_id("plastic_bag"), 0, "Equipped plastic bag should leave the carried inventory.")
	assert_eq(String(run_state.equipped_items.get("hand_carry", {}).get("id", "")), "plastic_bag", "Hand-carry slot should hold the equipped plastic bag.")
	assert_true(float(run_state.inventory.carry_capacity) > hand_carry_base_capacity, "Equipped plastic bags should improve carrying capacity.")

	var hand_carry_unequip_result: Dictionary = run_state.unequip_slot("hand_carry")
	assert_true(bool(hand_carry_unequip_result.get("ok", false)), "Unequipping a hand-carry container should succeed.")
	assert_eq(String(hand_carry_unequip_result.get("item", {}).get("id", "")), "plastic_bag", "Hand-carry unequip should return the plastic bag.")
	assert_true(not run_state.equipped_items.has("hand_carry"), "Hand-carry slot should be empty after unequip.")
	assert_eq(run_state.inventory.count_item_by_id("plastic_bag"), 1, "Unequipped plastic bag should return to inventory.")

	pass_test("EQUIPMENT_LOADOUT_OK")
