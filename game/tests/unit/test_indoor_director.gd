extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const INDOOR_DIRECTOR_SCRIPT_PATH := "res://scripts/indoor/indoor_director.gd"

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
	var indoor_director_script := load(INDOOR_DIRECTOR_SCRIPT_PATH) as Script
	if not assert_true(run_state_script != null, "Missing run state script: %s" % RUN_STATE_SCRIPT_PATH):
		return
	if not assert_true(indoor_director_script != null, "Missing indoor director script: %s" % INDOOR_DIRECTOR_SCRIPT_PATH):
		return

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(run_state != null, "RunState should build for indoor director tests."):
		return

	var director = indoor_director_script.new()
	root.add_child(director)
	director.configure(run_state, "mart_01")

	assert_eq(director.get_current_zone_id(), "mart_entrance", "Director should initialize at the mart entry zone.")
	assert_eq(
		director.get_current_zone_label(),
		"정문 진입부",
		"Director should expose the readable label for the current zone."
	)
	assert_eq(
		_edge_ids(director.get_map_snapshot()),
		["checkout|mart_entrance", "food_aisle|mart_entrance"],
		"At the entrance, the minimap should only show routes that leave the current zone."
	)

	var event_state: Dictionary = director._event_state
	assert_eq(String(event_state.get("current_zone_id", "")), "mart_entrance", "Event state should track the entry zone.")
	assert_true(
		_string_values(event_state.get("visited_zone_ids", [])).has("mart_entrance"),
		"Event state should mark the entry zone as visited."
	)
	assert_true(event_state.has("revealed_clue_ids"), "Event state should keep revealed clue ids.")
	assert_true(event_state.has("spent_action_ids"), "Event state should keep spent action ids.")
	assert_true(event_state.has("zone_flags"), "Event state should keep zone flags.")
	assert_true(event_state.has("traversed_edge_ids"), "Event state should keep traversed indoor edge ids.")
	assert_eq(int(event_state.get("noise", -1)), 0, "Event state should start with zero noise.")

	assert_true(director.apply_action("move_food_aisle"), "Director should allow moving into the food aisle.")
	assert_eq(
		_edge_ids(director.get_map_snapshot()),
		["food_aisle|freezer_row", "food_aisle|household_goods", "food_aisle|mart_entrance"],
		"After moving through the food aisle, the minimap should preserve the traveled path and expose the newly adjacent aisles."
	)

	assert_true(director.apply_action("move_household_goods"), "Director should allow moving into the household goods zone.")
	assert_eq(
		_edge_ids(director.get_map_snapshot()),
		["back_hall|household_goods", "food_aisle|household_goods", "food_aisle|mart_entrance", "household_goods|snack_aisle"],
		"The household goods zone should expose both the back area and the side snack aisle."
	)
	assert_true(director.apply_action("search_household_goods"), "Director should allow searching the household goods zone.")
	assert_true(director.apply_action("take_household_goods_small_backpack_0"), "Director should allow taking the backpack as discovered loot.")
	assert_true(director.apply_action("inspect_inventory_small_backpack"), "Director should allow selecting an inventory item for inspection.")
	var selected_item_sheet: Dictionary = director.get_selected_inventory_sheet()
	assert_eq(String(selected_item_sheet.get("title", "")), "작은 배낭", "Director should expose the selected item title for the bottom sheet.")
	assert_true(
		_action_ids(selected_item_sheet.get("actions", [])).has("equip_inventory_small_backpack"),
		"Equippable inventory items should expose an equip action in the item sheet."
	)
	assert_true(director.apply_action("equip_inventory_small_backpack"), "Director should allow equipping the selected backpack.")
	assert_eq(director.get_inventory_title(), "소지품 (0/12)", "Equipping the backpack should increase the carry limit in the inventory title.")
	assert_eq(director.get_inventory_status_text(), "여유 있음", "Director should report a calm carry state before the player goes overweight.")

	assert_true(director.apply_action("move_back_hall"), "Director should allow moving from household goods into the back area.")
	assert_true(director.apply_action("move_staff_corridor_gate"), "Director should allow moving to the staff door from the back area.")
	assert_eq(
		_edge_ids(director.get_map_snapshot()),
		["back_hall|household_goods", "back_hall|staff_corridor_gate", "checkout|staff_corridor_gate", "food_aisle|household_goods", "food_aisle|mart_entrance", "staff_corridor_gate|stair_landing"],
		"At the staff door, the minimap should only add routes that can be seen directly from the current position."
	)

	director.configure(run_state, "mart_01")
	assert_true(director.apply_action("move_checkout"), "Director should allow moving to checkout.")
	var checkout_exit_action := _action_by_id(director.get_actions(), "exit_building")
	if not assert_true(checkout_exit_action.has("id"), "Director should expose a leave-building shortcut away from the entrance."):
		director.free()
		return
	assert_eq(
		String(checkout_exit_action.get("label", "")),
		"건물 밖으로 나간다 (10분)",
		"Director should price the leave-building shortcut as the shortest route back to the exit."
	)
	var minute_before_exit := int(run_state.clock.minute_of_day)
	assert_true(director.apply_action("exit_building"), "Director should allow resolving the leave-building shortcut from inside the building.")
	assert_eq(
		int(run_state.clock.minute_of_day),
		minute_before_exit + 10,
		"Director should advance time by the shortest-route leave-building shortcut cost."
	)

	director.configure(run_state, "mart_01")
	assert_true(director.apply_action("move_checkout"), "Director should allow moving to checkout.")
	assert_true(director.apply_action("search_checkout_drawer"), "Director should allow searching checkout.")
	var lighter_take_id := _action_id_by_label_prefix(director.get_actions(), "라이터 챙긴다")
	assert_true(not lighter_take_id.is_empty(), "Checkout search should surface the lighter loot action.")
	assert_true(director.apply_action(lighter_take_id), "Director should allow taking the lighter.")
	assert_eq(run_state.inventory.count_item_by_id("lighter"), 1, "Loot should enter the inventory once.")

	director.configure(run_state, "office_01")
	director.configure(run_state, "mart_01")
	assert_true(_action_id_by_label_prefix(director.get_actions(), "라이터 챙긴다").is_empty(), "Re-entering a searched room should not respawn already-looted items.")

	assert_true(run_state.inventory.add_item({"id": "newspaper", "name": "신문지", "bulk": 1}), "Inventory should accept a newspaper for drop persistence checks.")
	assert_true(director.apply_action("drop_inventory_newspaper"), "Dropping an inventory item should succeed.")
	assert_true(not _action_id_by_label_prefix(director.get_actions(), "신문지 챙긴다").is_empty(), "Dropped items should appear in the room loot list.")

	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "Indoor director tests should have access to the ContentLibrary autoload."):
		director.free()
		return
	assert_true(run_state.inventory.add_item(content_library.get_item("improvised_heat_note_01")), "Inventory should accept a readable knowledge note.")
	assert_true(director.apply_action("inspect_inventory_improvised_heat_note_01"), "Director should allow selecting a knowledge note.")
	selected_item_sheet = director.get_selected_inventory_sheet()
	var selected_action_ids := _action_ids(selected_item_sheet.get("actions", []))
	assert_true(selected_action_ids.has("read_inventory_improvised_heat_note_01"), "Knowledge notes should expose a read action.")
	assert_true(selected_action_ids.has("drop_inventory_improvised_heat_note_01"), "Knowledge notes should keep a drop action.")
	assert_true(selected_action_ids.has("close_inventory_sheet"), "Knowledge notes should keep a close action.")
	assert_true(director.apply_action("read_inventory_improvised_heat_note_01"), "Director should allow reading the knowledge note.")
	assert_true(run_state.known_recipe_ids.has("newspaper__cooking_oil"), "Reading should unlock mapped recipes.")
	assert_eq(run_state.inventory.count_item_by_id("improvised_heat_note_01"), 1, "Reading a note should not consume the item.")
	assert_true(director.apply_action("read_inventory_improvised_heat_note_01"), "Repeat reading should still resolve as an action.")
	assert_true(director.get_feedback_message().find("이미") != -1, "Repeat reading should surface an already-known message.")

	director.configure(run_state, "apartment_01")
	assert_eq(director.get_current_zone_id(), "shared_entrance", "Director should initialize at the apartment entry zone.")
	assert_eq(director.get_current_zone_label(), "공동 현관", "Director should expose the readable apartment entry label.")
	assert_true(
		_action_ids(director.get_actions()).has("move_mailbox_hall"),
		"Apartment entry should expose an initial mailbox-hall route."
	)
	assert_true(director.apply_action("move_mailbox_hall"), "Apartment should allow moving into the mailbox hall.")
	assert_true(director.apply_action("search_mailbox_hall"), "Apartment should allow searching the mailbox hall.")
	var take_101_key_action_id := _action_id_by_label_prefix(director.get_actions(), "101호 열쇠 챙긴다")
	assert_true(not take_101_key_action_id.is_empty(), "Apartment mailbox search should surface the 101 key.")
	assert_true(director.apply_action(take_101_key_action_id), "Apartment should allow taking the 101 key.")
	assert_true(director.apply_action("move_shared_entrance"), "Apartment should allow returning to the shared entrance.")
	assert_true(director.apply_action("move_first_floor_hall"), "Apartment should allow moving into the first-floor hall.")
	assert_true(
		_action_ids(director.get_actions()).has("move_stairwell"),
		"Apartment first-floor hall should expose the stairwell route."
	)
	assert_true(director.apply_action("move_unit_101_door"), "Apartment should allow moving to the 101 doorway.")
	var room_101_move := _action_by_id(director.get_actions(), "move_unit_101_room")
	assert_true(not room_101_move.is_empty(), "Apartment should expose the 101 room move at the doorway.")
	assert_true(not bool(room_101_move.get("locked", true)), "Taking the 101 key should unlock room 101.")
	assert_true(director.apply_action("move_unit_101_room"), "Apartment should allow entering room 101.")
	assert_true(director.apply_action("search_unit_101_room"), "Apartment should allow searching room 101.")
	assert_true(director.apply_action("move_unit_101_door"), "Apartment should allow stepping back to the 101 doorway.")
	assert_true(director.apply_action("move_first_floor_hall"), "Apartment should allow returning to the first-floor hall.")
	assert_true(director.apply_action("move_stairwell"), "Apartment should allow entering the stairwell.")
	assert_true(director.apply_action("move_second_floor_hall"), "Apartment should allow reaching the second-floor hall.")
	assert_true(director.apply_action("move_laundry_room"), "Apartment second-floor hall should allow entering the laundry room.")
	assert_true(director.apply_action("search_laundry_room"), "Apartment should allow searching the laundry room.")
	var take_201_key_action_id := _action_id_by_label_prefix(director.get_actions(), "201호 열쇠 챙긴다")
	assert_true(not take_201_key_action_id.is_empty(), "Apartment laundry room should surface the 201 key.")
	assert_true(director.apply_action(take_201_key_action_id), "Apartment should allow taking the 201 key.")
	assert_true(director.apply_action("move_second_floor_hall"), "Apartment should allow returning from the laundry room to the second-floor hall.")
	assert_true(
		_action_ids(director.get_actions()).has("move_unit_201_door"),
		"Apartment second-floor hall should expose the 201 doorway."
	)
	assert_true(director.apply_action("move_unit_201_door"), "Apartment should allow moving to the 201 doorway.")
	var room_201_move := _action_by_id(director.get_actions(), "move_unit_201_room")
	assert_true(not room_201_move.is_empty(), "Apartment should expose the 201 room move at the doorway.")
	assert_true(not bool(room_201_move.get("locked", true)), "Taking the 201 key should unlock room 201.")

	director.configure(run_state, "clinic_01")
	assert_eq(director.get_current_zone_id(), "clinic_lobby", "Director should initialize at the clinic entry zone.")
	assert_true(director.apply_action("move_treatment_room"), "Clinic should allow moving into the treatment room.")
	assert_true(
		_action_ids(director.get_actions()).has("move_nurse_station"),
		"Clinic treatment room should expose the nurse station route."
	)
	assert_true(
		_action_ids(director.get_actions()).has("move_staff_break_room"),
		"Clinic treatment room should expose a staff break room side route."
	)

	director.configure(run_state, "office_01")
	assert_eq(director.get_current_zone_id(), "office_lobby", "Director should initialize at the office entry zone.")
	assert_true(director.apply_action("move_open_office"), "Office should allow moving into the open workspace.")
	assert_true(
		_action_ids(director.get_actions()).has("move_meeting_room"),
		"Office workspace should expose a meeting-room route."
	)
	assert_true(
		_action_ids(director.get_actions()).has("move_records_room"),
		"Office workspace should still expose the records-room move."
	)

	director.free()
	pass_test("INDOOR_DIRECTOR_OK")


func _string_values(values) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result


func _edge_ids(snapshot: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for edge_variant in snapshot.get("edges", []):
		if typeof(edge_variant) != TYPE_DICTIONARY:
			continue
		var edge := edge_variant as Dictionary
		var from_id := String(edge.get("from", ""))
		var to_id := String(edge.get("to", ""))
		var edge_id := "%s|%s" % [from_id, to_id] if from_id < to_id else "%s|%s" % [to_id, from_id]
		if not ids.has(edge_id):
			ids.append(edge_id)
	ids.sort()
	return ids


func _action_ids(actions) -> Array[String]:
	var ids: Array[String] = []
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		ids.append(String((action_variant as Dictionary).get("id", "")))
	return ids


func _action_by_id(actions, expected_id: String) -> Dictionary:
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action := action_variant as Dictionary
		if String(action.get("id", "")) == expected_id:
			return action
	return {}


func _action_id_by_label_prefix(actions, expected_prefix: String) -> String:
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action := action_variant as Dictionary
		var label := String(action.get("label", ""))
		if label.begins_with(expected_prefix):
			return String(action.get("id", ""))
	return ""
func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
