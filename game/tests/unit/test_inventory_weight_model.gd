extends "res://tests/support/test_case.gd"

const INVENTORY_MODEL_SCRIPT_PATH := "res://scripts/run/inventory_model.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var inventory_model_script := load(INVENTORY_MODEL_SCRIPT_PATH) as Script
	if not assert_true(inventory_model_script != null, "InventoryModel script should load for carry-weight tests."):
		return

	var inventory = inventory_model_script.new()
	if not assert_true(inventory != null, "InventoryModel should instantiate for carry-weight tests."):
		return

	if not assert_true(inventory.has_method("total_carry_weight"), "InventoryModel should expose total_carry_weight() for weight-based hauling."):
		return
	if not assert_true(inventory.has_method("get_carry_state_id"), "InventoryModel should expose get_carry_state_id() for carry-band evaluation."):
		return

	inventory.carry_capacity = 10.0
	inventory.ideal_carry_capacity = 8.0
	inventory.overpack_capacity = 12.0

	assert_eq(inventory.total_carry_weight(), 0.0, "Empty inventory should start at 0 carry weight.")
	assert_true(inventory.add_item({"id": "bottled_water", "carry_weight": 3.0}), "A 3.0kg item should fit under ideal carry.")
	assert_true(inventory.add_item({"id": "energy_bar", "carry_weight": 5.5}), "A second item should still fit while moving into overload.")
	assert_eq(snapped(float(inventory.total_carry_weight()), 0.01), 8.5, "Carry weight should sum from item carry_weight values.")
	assert_eq(String(inventory.get_carry_state_id()), "overloaded", "Crossing ideal carry should move the inventory into overloaded state.")

	assert_true(inventory.add_item({"id": "canteen", "carry_weight": 3.0}), "Inventory should still allow pickup up to the overpack ceiling.")
	assert_eq(String(inventory.get_carry_state_id()), "overpacked", "Crossing carry capacity should enter overpacked state.")
	assert_true(not inventory.can_add({"id": "extra_can", "carry_weight": 0.6}), "Overpacked inventory should reject further pickups.")

	pass_test("INVENTORY_WEIGHT_MODEL_OK")
