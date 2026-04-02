extends "res://tests/support/test_case.gd"

const RUN_STATE_SCRIPT_PATH := "res://scripts/run/run_state.gd"
const INDOOR_MODE_SCENE_PATH := "res://scenes/indoor/indoor_mode.tscn"

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

var _exit_requested_count := 0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var run_state_script := load(RUN_STATE_SCRIPT_PATH) as Script
	var indoor_scene := load(INDOOR_MODE_SCENE_PATH) as PackedScene
	if not assert_true(indoor_scene != null, "Missing indoor mode scene: %s" % INDOOR_MODE_SCENE_PATH):
		return
	if not assert_true(run_state_script != null, "Missing run state script: %s" % RUN_STATE_SCRIPT_PATH):
		return

	var run_state = run_state_script.from_survivor_config({
		"job_id": "courier",
		"trait_ids": PackedStringArray(["athlete"]),
		"remaining_points": 0,
	}, self)
	if not assert_true(run_state != null, "RunState should build for indoor mode tests."):
		return

	var indoor_mode = indoor_scene.instantiate()
	if not assert_true(indoor_mode != null, "Indoor mode should instantiate."):
		return

	root.add_child(indoor_mode)
	indoor_mode.configure(run_state, "mart_01")

	if not assert_true(indoor_mode.has_signal("exit_requested"), "Indoor mode should emit exit_requested."):
		indoor_mode.free()
		return

	indoor_mode.exit_requested.connect(Callable(self, "_on_exit_requested"))

	var exit_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/Header/ExitButton") as Button
	if not assert_true(exit_button == null, "Indoor mode should no longer expose a global ExitButton."):
		indoor_mode.free()
		return

	var location_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/Header/LocationLabel") as Label
	if not assert_true(location_label != null, "Indoor mode should expose a LocationLabel."):
		indoor_mode.free()
		return
	assert_eq(
		location_label.text,
		"위치: 정문 진입부",
		"Indoor mode should show the mart entry zone label after configure."
	)

	var time_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/Header/TimeLabel") as Label
	if not assert_true(time_label != null, "Indoor mode should expose a TimeLabel for the shared clock."):
		indoor_mode.free()
		return
	assert_eq(
		time_label.text,
		"시각: 1일차 08:00",
		"Indoor mode should show the shared run clock after configure."
	)

	var summary_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/SummaryLabel") as Label
	if not assert_true(summary_label != null, "Indoor mode should expose a current-zone SummaryLabel."):
		indoor_mode.free()
		return
	assert_eq(
		summary_label.text,
		"깨진 자동문과 쓰러진 장바구니가 보인다.",
		"Indoor mode should show the current zone summary instead of the building summary."
	)

	var sleep_preview_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/SleepPreviewLabel") as Label
	if not assert_true(sleep_preview_label == null, "Indoor mode should hide sleep preview from the main reading surface."):
		indoor_mode.free()
		return

	var clue_list := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ClueList") as VBoxContainer
	if not assert_true(clue_list == null, "Indoor mode should hide the persistent clue list from the main reading surface."):
		indoor_mode.free()
		return

	var backdrop := indoor_mode.get_node_or_null("Backdrop") as ColorRect
	if not assert_true(backdrop != null, "Indoor mode should expose a Backdrop node for the reading surface."):
		indoor_mode.free()
		return

	var result_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ResultLabel") as Label
	if not assert_true(result_label != null, "Indoor mode should expose a ResultLabel."):
		indoor_mode.free()
		return

	var action_buttons := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ActionButtons") as VBoxContainer
	if not assert_true(action_buttons != null, "Indoor mode should expose action buttons."):
		indoor_mode.free()
		return
	assert_true(
		_section_labels(action_buttons).has("이동"),
		"Indoor mode should group movement actions under a dedicated section."
	)
	assert_true(
		_section_labels(action_buttons).has("탐색 / 상호작용"),
		"Indoor mode should group local interactions under a dedicated section."
	)
	assert_true(
		_find_button_by_text(action_buttons, "계산대로 이동한다 (30분)") != null,
		"Indoor mode should show travel time in movement actions."
	)
	assert_true(
		_find_button_by_text(action_buttons, "계산대로 이동한다 (30분)").icon != null,
		"Indoor mode should attach an icon to movement actions."
	)
	assert_true(
		_find_button_by_text(action_buttons, "건물 밖으로 나간다") != null,
		"Indoor mode should expose leaving the building as a contextual action at the entrance."
	)
	assert_true(
		_find_button_by_text(action_buttons, "건물 밖으로 나간다").icon != null,
		"Indoor mode should attach an icon to contextual exit actions."
	)
	assert_true(
		_find_button_by_text(action_buttons, "한 시간 쉰다 (60분)") == null,
		"Indoor mode should not expose the removed flat rest action."
	)

	var minimap_nodes := indoor_mode.get_node_or_null("Panel/Layout/Sidebar/MinimapPanel/VBox/MapNodes") as Control
	if not assert_true(minimap_nodes != null, "Indoor mode should expose a minimap node container."):
		indoor_mode.free()
		return
	assert_eq(
		_map_labels(minimap_nodes),
		["?", "?", "정문 진입부"],
		"Indoor mode should only reveal the current zone and directly connected unknown zones on the minimap."
	)

	var inventory_items := indoor_mode.get_node_or_null("Panel/Layout/Sidebar/InventoryPanel/VBox/InventoryScroll/InventoryItems") as VBoxContainer
	if not assert_true(inventory_items != null, "Indoor mode should expose an inventory list container."):
		indoor_mode.free()
		return
	var inventory_scroll := indoor_mode.get_node_or_null("Panel/Layout/Sidebar/InventoryPanel/VBox/InventoryScroll") as ScrollContainer
	if not assert_true(inventory_scroll != null, "Indoor mode should mount the inventory list inside a ScrollContainer."):
		indoor_mode.free()
		return
	var inventory_title_label := indoor_mode.get_node_or_null("Panel/Layout/Sidebar/InventoryPanel/VBox/TitleLabel") as Label
	if not assert_true(inventory_title_label != null, "Indoor mode should expose an inventory title label."):
		indoor_mode.free()
		return
	var inventory_status_label := indoor_mode.get_node_or_null("Panel/Layout/Sidebar/InventoryPanel/VBox/StatusLabel") as Label
	if not assert_true(inventory_status_label != null, "Indoor mode should expose an inventory status label."):
		indoor_mode.free()
		return
	var equipped_items := indoor_mode.get_node_or_null("Panel/Layout/Sidebar/InventoryPanel/VBox/EquippedItems") as VBoxContainer
	if not assert_true(equipped_items != null, "Indoor mode should expose a mounted equipment list."):
		indoor_mode.free()
		return
	assert_eq(
		inventory_title_label.text,
		"소지품 (0/8)",
		"Indoor mode should show the current carry usage in the inventory title."
	)
	assert_eq(
		inventory_status_label.text,
		"여유 있음",
		"Indoor mode should show a calm carry-state message while the player is under the limit."
	)
	assert_eq(
		_inventory_labels(inventory_items),
		["소지품 없음"],
		"Indoor mode should show an empty inventory placeholder before the player loots anything."
	)
	assert_eq(
		_inventory_labels(equipped_items),
		["장착중인 장비 없음"],
		"Indoor mode should show an empty equipped-items placeholder before any equipment is worn."
	)
	var item_sheet := indoor_mode.get_node_or_null("ItemSheet") as Control
	if not assert_true(item_sheet != null, "Indoor mode should expose a bottom item sheet."):
		indoor_mode.free()
		return
	assert_true(not item_sheet.visible, "Indoor mode should keep the item sheet hidden until an inventory item is selected.")

	var director := indoor_mode.get_node_or_null("Director")
	if not assert_true(director != null and director.has_method("apply_action"), "Indoor mode should expose its Director node."):
		indoor_mode.free()
		return

	assert_true(
		director.apply_action("move_checkout"),
		"Director should allow moving to the checkout zone from the entry zone."
	)
	assert_eq(
		location_label.text,
		"위치: 계산대",
		"Indoor mode should refresh the location label after the director changes zone."
	)
	assert_eq(
		summary_label.text,
		"계산대 뒤쪽에는 직원 출입문이 있다.",
		"Indoor mode should update the summary for the current zone after moving."
	)
	assert_eq(
		time_label.text,
		"시각: 1일차 08:30",
		"Indoor mode should advance and display time after moving between zones."
	)
	assert_true(
		_find_button_by_text(action_buttons, "계산대를 탐색한다 (30분)") != null,
		"Indoor mode should show time cost on local zone actions."
	)
	assert_true(
		_find_button_by_text(action_buttons, "계산대를 탐색한다 (30분)").icon != null,
		"Indoor mode should attach an icon to interaction actions."
	)
	assert_eq(
		_map_labels(minimap_nodes),
		["?", "계산대", "정문 진입부"],
		"Indoor mode should keep visited zones visible and only reveal newly adjacent unknown zones."
	)
	assert_true(
		_find_button_by_text(action_buttons, "건물 밖으로 나간다") == null,
		"Indoor mode should hide the leave-building action away from the entrance."
	)

	assert_true(
		director.apply_action("search_checkout_counter"),
		"Director should resolve the checkout search within the checkout zone."
	)
	await process_frame
	assert_true(
		summary_label.text.find("계산대") != -1,
		"Indoor summary should stay tied to the current zone after searching."
	)
	assert_true(
		result_label.text.find("발견") != -1 and result_label.text.find("라이터") != -1,
		"Indoor result feedback should mention the items the player just found."
	)
	assert_eq(
		_inventory_labels(inventory_items),
		["소지품 없음"],
		"Searching should not add loot to inventory until the player picks an item."
	)
	assert_true(
		_find_button_by_text(action_buttons, "라이터 챙긴다") != null,
		"Searching should reveal follow-up actions for each discovered item."
	)
	assert_true(
		_find_button_by_text(action_buttons, "라이터 챙긴다").icon != null,
		"Indoor mode should attach an icon to discovered-loot actions."
	)
	assert_true(
		_section_labels(action_buttons).has("발견한 물건"),
		"Indoor mode should surface discovered loot in a dedicated section."
	)
	assert_true(
		director.apply_action("take_checkout_lighter_0"),
		"Director should allow picking up a discovered item with a separate action."
	)
	await process_frame
	var take_energy_bar_button := _find_button_by_text(action_buttons, "에너지바 챙긴다")
	if not assert_true(take_energy_bar_button != null, "Indoor mode should refresh take actions after picking the first discovered item."):
		indoor_mode.free()
		return
	take_energy_bar_button.emit_signal("pressed")
	await process_frame
	assert_eq(
		_inventory_labels(inventory_items),
		["라이터 x1", "에너지바 x1"],
		"Picking up discovered items should update the indoor inventory list."
	)
	assert_eq(
		inventory_title_label.text,
		"소지품 (2/8)",
		"Indoor mode should refresh the carry usage after looting items."
	)
	var energy_bar_button := _find_button_by_text(inventory_items, "에너지바 x1")
	if not assert_true(energy_bar_button != null, "Indoor inventory should expose carried items as selectable buttons."):
		indoor_mode.free()
		return
	energy_bar_button.emit_signal("pressed")
	await process_frame
	assert_true(item_sheet.visible, "Selecting an inventory item should open the bottom item sheet.")
	var item_sheet_title := indoor_mode.get_node_or_null("ItemSheet/VBox/ItemNameLabel") as Label
	var item_sheet_description := indoor_mode.get_node_or_null("ItemSheet/VBox/ItemDescriptionLabel") as Label
	var item_sheet_effect := indoor_mode.get_node_or_null("ItemSheet/VBox/ItemEffectLabel") as Label
	var item_sheet_actions := indoor_mode.get_node_or_null("ItemSheet/VBox/ActionButtons") as HBoxContainer
	if not assert_true(item_sheet_title != null and item_sheet_description != null and item_sheet_effect != null and item_sheet_actions != null, "Indoor item sheet should expose detail labels and action buttons."):
		indoor_mode.free()
		return
	assert_eq(item_sheet_title.text, "에너지바", "Indoor item sheet should show the selected item title.")
	assert_true(item_sheet_description.text.length() > 0, "Indoor item sheet should show an item description.")
	assert_true(item_sheet_effect.text.find("포만감") != -1, "Indoor item sheet should show food effect details.")
	assert_true(_find_button_in_container(item_sheet_actions, "먹는다") != null, "Food items should expose an eat action in the item sheet.")
	assert_true(_find_button_in_container(item_sheet_actions, "버린다") != null, "Item sheet should expose a drop action.")

	var eat_button := _find_button_in_container(item_sheet_actions, "먹는다")
	eat_button.emit_signal("pressed")
	await process_frame
	assert_eq(
		_inventory_labels(inventory_items),
		["라이터 x1"],
		"Eating a food item should remove it from the carried inventory list."
	)
	assert_eq(
		inventory_title_label.text,
		"소지품 (1/8)",
		"Eating an item should free carry space in the inventory title."
	)
	assert_true(
		result_label.text.find("먹었다") != -1,
		"Eating an item should leave readable feedback."
	)
	assert_true(not item_sheet.visible, "Resolving an item-sheet action should close the bottom sheet.")

	var move_entrance_button := _find_button_by_text(action_buttons, "정문 진입부로 이동한다 (10분)")
	if not assert_true(move_entrance_button != null, "Indoor mode should expose a return action back to the entrance."):
		indoor_mode.free()
		return
	move_entrance_button.emit_signal("pressed")
	await process_frame
	var move_food_aisle_button := _find_button_by_text(action_buttons, "식품 진열대로 이동한다 (30분)")
	if not assert_true(move_food_aisle_button != null, "Indoor mode should expose movement from the entrance into the food aisle."):
		indoor_mode.free()
		return
	move_food_aisle_button.emit_signal("pressed")
	await process_frame
	var move_household_goods_button := _find_button_by_text(action_buttons, "생활용품 코너로 이동한다 (30분)")
	if not assert_true(move_household_goods_button != null, "Indoor mode should expose movement from the food aisle into household goods."):
		indoor_mode.free()
		return
	move_household_goods_button.emit_signal("pressed")
	await process_frame
	assert_true(director.apply_action("search_household_goods"), "Director should allow searching household goods.")
	var take_household_backpack_button := _find_button_by_prefix(action_buttons, "작은 배낭 챙긴다")
	if not assert_true(take_household_backpack_button != null, "Household goods should reveal a backpack to take."):
		indoor_mode.free()
		return
	take_household_backpack_button.emit_signal("pressed")
	await process_frame
	assert_true(director.apply_action("inspect_inventory_small_backpack"), "Indoor mode should allow selecting the backpack for inspection.")
	assert_true(director.apply_action("equip_inventory_small_backpack"), "Indoor mode should allow equipping the backpack from the item sheet.")
	await process_frame
	assert_eq(
		_inventory_labels(equipped_items),
		["등: 작은 배낭"],
		"Equipping an item should surface it in the equipped-items list."
	)

	var lighter_button := _find_button_by_text(inventory_items, "라이터 x1")
	if not assert_true(lighter_button != null, "Remaining carried items should stay selectable after eating another item."):
		indoor_mode.free()
		return
	lighter_button.emit_signal("pressed")
	await process_frame
	var drop_button := _find_button_in_container(item_sheet_actions, "버린다")
	if not assert_true(drop_button != null, "Utility items should still expose a drop action from the item sheet."):
		indoor_mode.free()
		return
	drop_button.emit_signal("pressed")
	await process_frame
	assert_eq(
		_inventory_labels(inventory_items),
		["소지품 없음"],
		"Dropping the remaining utility item should empty the inventory list."
	)
	assert_eq(
		inventory_title_label.text,
		"소지품 (0/12)",
		"Dropping the remaining item should free all carry space."
	)
	assert_true(
		result_label.text.find("버렸다") != -1,
		"Dropping an item from the sheet should leave readable feedback."
	)

	assert_true(
		director.apply_action("move_food_aisle"),
		"Director should allow moving back into the food aisle from household goods."
	)
	assert_true(
		director.apply_action("move_mart_entrance"),
		"Director should allow moving back to the mart entrance from the food aisle."
	)
	assert_eq(
		time_label.text,
		"시각: 1일차 11:00",
		"Indoor mode should update the visible time after walking back through known zones."
	)
	assert_true(
		_find_button_by_text(action_buttons, "건물 밖으로 나간다") != null,
		"Indoor mode should restore the contextual leave-building action when back at the entrance."
	)

	var exit_action_button := _find_button_by_text(action_buttons, "건물 밖으로 나간다")
	if not assert_true(exit_action_button != null, "Indoor mode should surface a clickable leave-building action."):
		indoor_mode.free()
		return

	exit_action_button.emit_signal("pressed")
	assert_eq(_exit_requested_count, 1, "Pressing ExitButton should emit exit_requested exactly once.")

	indoor_mode.free()
	pass_test("INDOOR_MODE_OK")


func _on_exit_requested() -> void:
	_exit_requested_count += 1


func _find_button_by_text(container: Node, expected_text: String) -> Button:
	if container == null:
		return null

	for child in container.get_children():
		var button := child as Button
		if button != null and button.text == expected_text:
			return button
		var nested := _find_button_by_text(child, expected_text)
		if nested != null:
			return nested

	return null


func _find_button_by_prefix(container: Node, expected_prefix: String) -> Button:
	if container == null:
		return null

	for child in container.get_children():
		var button := child as Button
		if button != null and button.text.begins_with(expected_prefix):
			return button
		var nested := _find_button_by_prefix(child, expected_prefix)
		if nested != null:
			return nested

	return null


func _section_labels(container: Node) -> Array[String]:
	var labels: Array[String] = []
	if container == null:
		return labels

	for child in container.get_children():
		var label := child as Label
		if label != null:
			var text := label.text.strip_edges()
			if not text.is_empty():
				labels.append(text)
		labels.append_array(_section_labels(child))

	return labels


func _find_inventory_button_by_text(container: VBoxContainer, expected_text: String) -> Button:
	if container == null:
		return null

	for child in container.get_children():
		if child is Button:
			var direct_button := child as Button
			if direct_button != null and direct_button.text == expected_text:
				return direct_button
		if child is Container:
			for nested_child in child.get_children():
				var button := nested_child as Button
				if button != null and button.text == expected_text:
					return button

	return null


func _find_button_in_container(container: Container, expected_text: String) -> Button:
	if container == null:
		return null

	for child in container.get_children():
		var button := child as Button
		if button != null and button.text == expected_text:
			return button

	return null


func _map_labels(container: Control) -> Array[String]:
	var labels: Array[String] = []
	if container == null:
		return labels

	for child in container.get_children():
		var label := child as Label
		if label != null:
			labels.append(label.text)

	labels.sort()
	return labels


func _inventory_labels(container: VBoxContainer) -> Array[String]:
	var labels: Array[String] = []
	if container == null:
		return labels

	for child in container.get_children():
		var button := child as Button
		if button != null:
			labels.append(button.text)
			continue
		var label := child as Label
		if label != null:
			labels.append(label.text)
			continue
		if child is Container:
			for nested_child in child.get_children():
				var nested_button := nested_child as Button
				if nested_button != null:
					labels.append(nested_button.text)
					break
				var nested_label := nested_child as Label
				if nested_label != null:
					labels.append(nested_label.text)
					break

	return labels


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
