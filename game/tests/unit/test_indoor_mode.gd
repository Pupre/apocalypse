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

	var sidebar := indoor_mode.get_node_or_null("Panel/Layout/Sidebar")
	if not assert_true(sidebar == null, "Indoor mode should remove the permanent sidebar layout."):
		indoor_mode.free()
		return

	var top_bar := _find_descendant_by_name_and_type(indoor_mode, "TopBar", "Control") as Control
	if not assert_true(top_bar != null, "Indoor mode should expose a dedicated indoor top bar."):
		indoor_mode.free()
		return

	var map_button := _find_descendant_by_name_and_type(top_bar, "MapButton", "Button") as Button
	if not assert_true(map_button != null, "Indoor mode should expose a 구조도 button in the top bar."):
		indoor_mode.free()
		return

	var bag_button := _find_descendant_by_name_and_type(top_bar, "BagButton", "Button") as Button
	if not assert_true(bag_button != null, "Indoor mode should expose a 가방 button in the top bar."):
		indoor_mode.free()
		return

	var minimap_overlay := indoor_mode.get_node_or_null("MinimapOverlay") as Control
	if not assert_true(minimap_overlay != null, "Indoor mode should expose a minimap overlay."):
		indoor_mode.free()
		return
	assert_true(not minimap_overlay.visible, "Indoor mode should keep the minimap overlay hidden by default.")

	var bag_sheet := indoor_mode.get_node_or_null("BagSheet") as Control
	if not assert_true(bag_sheet != null, "Indoor mode should expose a bag bottom sheet."):
		indoor_mode.free()
		return
	assert_true(not bag_sheet.visible, "Indoor mode should keep the bag sheet hidden by default.")

	var exit_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/Header/ExitButton") as Button
	if not assert_true(exit_button == null, "Indoor mode should no longer expose a global ExitButton."):
		indoor_mode.free()
		return

	var location_label := _find_descendant_by_name_and_type(top_bar, "LocationLabel", "Label") as Label
	if not assert_true(location_label != null, "Indoor mode should expose a LocationLabel."):
		indoor_mode.free()
		return
	assert_eq(
		location_label.text,
		"위치: 정문 진입부",
		"Indoor mode should show the mart entry zone label after configure."
	)

	var time_label := _find_descendant_by_name_and_type(top_bar, "TimeLabel", "Label") as Label
	if not assert_true(time_label != null, "Indoor mode should expose a TimeLabel for the shared clock."):
		indoor_mode.free()
		return
	assert_eq(
		time_label.text,
		"시각: 1일차 08:00",
		"Indoor mode should show the shared run clock after configure."
	)

	var inline_minimap_card := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ContextRow/MiniMapCard") as Control
	if not assert_true(
		inline_minimap_card != null and inline_minimap_card.visible,
		"Indoor mode should keep a small minimap visible in the main reading screen."
	):
		indoor_mode.free()
		return

	var inline_minimap := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ContextRow/MiniMapCard/MapNodes") as Control
	if not assert_true(inline_minimap != null, "Indoor mode should mount an always-visible minimap node."):
		indoor_mode.free()
		return

	var stat_chip_row := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/StatusRow/StatChips") as HBoxContainer
	if not assert_true(
		stat_chip_row != null and stat_chip_row.get_child_count() == 4,
		"Indoor mode should show four survival chips."
	):
		indoor_mode.free()
		return

	var director := _find_descendant_by_name_and_type(indoor_mode, "Director")
	if not assert_true(director != null and director.has_method("get_survival_chip_rows") and director.has_method("get_survival_chip_detail"), "Indoor mode should expose chip data through its Director."):
		indoor_mode.free()
		return

	var chip_rows: Array[Dictionary] = director.get_survival_chip_rows()
	if not assert_true(chip_rows.size() == 4, "Indoor mode should expose four chip payload rows."):
		indoor_mode.free()
		return

	for chip_row_variant in chip_rows:
		if typeof(chip_row_variant) != TYPE_DICTIONARY:
			continue
		var chip_row := chip_row_variant as Dictionary
		var chip_id := String(chip_row.get("id", ""))
		var chip := _find_descendant_by_name_and_type(stat_chip_row, chip_id, "Button") as Button
		if not assert_true(chip != null, "Indoor mode should name each survival chip after its stat id."):
			indoor_mode.free()
			return
		assert_true(String(chip_row.get("icon_id", "")).is_empty() == false, "Indoor mode should expose an icon_id for each survival chip.")
		assert_eq(
			chip.text,
			String(chip_row.get("display_value_text", "")),
			"Indoor mode should render the director-provided chip display text."
		)
		assert_true(chip.icon != null, "Indoor mode should give each survival chip an icon from the director payload.")

	var target_chip_row: Dictionary = {}
	for chip_row_variant in chip_rows:
		if typeof(chip_row_variant) != TYPE_DICTIONARY:
			continue
		var chip_row := chip_row_variant as Dictionary
		if String(chip_row.get("id", "")) == "health":
			target_chip_row = chip_row
			break
	if not assert_true(not target_chip_row.is_empty(), "Indoor mode should expose a stable health chip payload."):
		indoor_mode.free()
		return

	var target_chip_button := _find_descendant_by_name_and_type(stat_chip_row, "health", "Button") as Button
	if not assert_true(target_chip_button != null, "Indoor mode should expose a health chip button by id."):
		indoor_mode.free()
		return

	var stat_detail_sheet := _find_descendant_by_name_and_type(indoor_mode, "StatDetailSheet", "Control") as Control
	if not assert_true(
		stat_detail_sheet != null and not stat_detail_sheet.visible,
		"Indoor mode should keep the stat detail sheet hidden by default."
	):
		indoor_mode.free()
		return
	target_chip_button = _find_descendant_by_name_and_type(stat_chip_row, "health", "Button") as Button
	if not assert_true(target_chip_button != null, "Indoor mode should keep the health chip button available after sheet toggles."):
		indoor_mode.free()
		return
	target_chip_button.emit_signal("pressed")
	await process_frame
	assert_true(stat_detail_sheet.visible, "Indoor mode should open the stat detail sheet when a chip is pressed.")
	var stat_detail_title := _find_descendant_by_name_and_type(stat_detail_sheet, "TitleLabel", "Label") as Label
	var stat_detail_value := _find_descendant_by_name_and_type(stat_detail_sheet, "ValueLabel", "Label") as Label
	var stat_detail_rule := _find_descendant_by_name_and_type(stat_detail_sheet, "RuleLabel", "Label") as Label
	var stat_detail_recovery := _find_descendant_by_name_and_type(stat_detail_sheet, "RecoveryLabel", "Label") as Label
	if not assert_true(
		stat_detail_title != null and stat_detail_value != null and stat_detail_rule != null and stat_detail_recovery != null,
		"Indoor mode should expose title/value/rule/recovery labels in the stat detail sheet."
	):
		indoor_mode.free()
		return
	assert_eq(stat_detail_title.text, String(target_chip_row.get("label", "")), "Indoor mode should show the selected stat title in the detail sheet.")
	assert_eq(
		stat_detail_value.text,
		String(target_chip_row.get("detail_value_text", "")),
		"Indoor mode should show the exact stat value text from the director payload."
	)
	assert_eq(
		stat_detail_rule.text,
		String(target_chip_row.get("rule_text", "")),
		"Indoor mode should show the selected stat rule text from the director payload."
	)
	assert_eq(
		stat_detail_recovery.text,
		String(target_chip_row.get("recovery_text", "")),
		"Indoor mode should show the selected stat recovery hint from the director payload."
	)

	bag_button.emit_signal("pressed")
	await process_frame
	assert_true(bag_sheet.visible, "Indoor mode should open the bag sheet from the top bar.")
	assert_true(not stat_detail_sheet.visible, "Opening the bag should close the stat detail sheet.")

	target_chip_button = _find_descendant_by_name_and_type(stat_chip_row, "health", "Button") as Button
	if not assert_true(target_chip_button != null, "Indoor mode should keep the health chip button available after closing the bag."):
		indoor_mode.free()
		return
	target_chip_button.emit_signal("pressed")
	await process_frame
	assert_true(not bag_sheet.visible, "Pressing a stat chip while the bag is open should close the bag sheet.")
	assert_true(stat_detail_sheet.visible, "Pressing a stat chip while the bag is open should reopen the stat detail sheet.")

	target_chip_button = _find_descendant_by_name_and_type(stat_chip_row, "health", "Button") as Button
	if not assert_true(target_chip_button != null, "Indoor mode should keep the health chip button available after reopening the detail sheet."):
		indoor_mode.free()
		return
	target_chip_button.emit_signal("pressed")
	await process_frame
	map_button.emit_signal("pressed")
	await process_frame
	assert_true(minimap_overlay.visible, "Indoor mode should open the minimap overlay when the top-bar map button is pressed.")
	assert_true(not stat_detail_sheet.visible, "Opening the minimap should close the stat detail sheet.")
	map_button.emit_signal("pressed")
	await process_frame
	assert_true(not minimap_overlay.visible, "Indoor mode should close the minimap overlay when the map button is pressed again.")

	var summary_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ContextRow/ReadingCard/VBox/SummaryLabel") as Label
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

	var result_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ContextRow/ReadingCard/VBox/ResultLabel") as Label
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

	var minimap_nodes := indoor_mode.get_node_or_null("MinimapOverlay/VBox/MapNodes") as Control
	if not assert_true(minimap_nodes != null, "Indoor mode should expose a minimap node container."):
		indoor_mode.free()
		return
	map_button.emit_signal("pressed")
	await process_frame
	assert_true(minimap_overlay.visible, "Indoor mode should open the minimap overlay when the top-bar map button is pressed.")
	assert_eq(
		_map_labels(minimap_nodes),
		["?", "?", "정문 진입부"],
		"Indoor mode should only reveal the current zone and directly connected unknown zones on the minimap."
	)
	map_button.emit_signal("pressed")
	await process_frame
	assert_true(not minimap_overlay.visible, "Indoor mode should hide the minimap overlay when the map button is pressed again.")

	var bag_title_label := _find_descendant_by_name_and_type(bag_sheet, "TitleLabel", "Label") as Label
	var bag_status_label := _find_descendant_by_name_and_type(bag_sheet, "StatusLabel", "Label") as Label
	var carried_tab_button := _find_descendant_by_name_and_type(bag_sheet, "CarriedTabButton", "Button") as Button
	var equipped_tab_button := _find_descendant_by_name_and_type(bag_sheet, "EquippedTabButton", "Button") as Button
	var inventory_scroll := _find_descendant_by_name_and_type(bag_sheet, "InventoryScroll", "ScrollContainer") as ScrollContainer
	var inventory_items := _find_descendant_by_name_and_type(inventory_scroll, "InventoryItems", "VBoxContainer") as VBoxContainer
	if not assert_true(inventory_items != null, "Indoor mode should expose an inventory list container."):
		indoor_mode.free()
		return
	if not assert_true(inventory_scroll != null, "Indoor mode should mount the inventory list inside a ScrollContainer."):
		indoor_mode.free()
		return
	if not assert_true(bag_title_label != null, "Indoor mode should expose a bag title label."):
		indoor_mode.free()
		return
	if not assert_true(bag_status_label != null, "Indoor mode should expose a bag status label."):
		indoor_mode.free()
		return
	if not assert_true(carried_tab_button != null and equipped_tab_button != null, "Indoor mode should expose carried/equipped bag tabs."):
		indoor_mode.free()
		return
	bag_button.emit_signal("pressed")
	await process_frame
	assert_true(bag_sheet.visible, "Indoor mode should open the bag sheet from the top bar.")
	assert_true(carried_tab_button.toggle_mode, "Carried tab should render as an explicit selectable tab.")
	assert_true(equipped_tab_button.toggle_mode, "Equipped tab should render as an explicit selectable tab.")
	assert_true(carried_tab_button.button_pressed, "Carried tab should be selected by default.")
	assert_true(not equipped_tab_button.button_pressed, "Equipped tab should be inactive by default.")
	assert_eq(
		bag_title_label.text,
		"소지품 (0/8)",
		"Indoor mode should show the current carry usage in the bag title."
	)
	assert_eq(
		bag_status_label.text,
		"여유 있음",
		"Indoor mode should show a calm carry-state message while the player is under the limit."
	)
	assert_eq(
		_inventory_labels(inventory_items),
		["소지품 없음"],
		"Indoor mode should show an empty inventory placeholder before the player loots anything."
	)
	equipped_tab_button.emit_signal("pressed")
	await process_frame
	assert_true(equipped_tab_button.button_pressed, "Equipped tab should become the selected state when tapped.")
	assert_true(not carried_tab_button.button_pressed, "Carried tab should leave the selected state when another tab is active.")
	assert_eq(_inventory_labels(inventory_items), ["장착중인 장비 없음"], "Indoor mode should show empty equipped gear in the bag sheet.")
	carried_tab_button.emit_signal("pressed")
	await process_frame
	var item_sheet := _find_descendant_by_name_and_type(indoor_mode, "ItemSheet", "Control") as Control
	if not assert_true(item_sheet != null, "Indoor mode should expose a bottom item sheet."):
		indoor_mode.free()
		return
	assert_true(not item_sheet.visible, "Indoor mode should keep the item sheet hidden until an inventory item is selected.")

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
		bag_title_label.text,
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
	var item_sheet_title := _find_descendant_by_name_and_type(item_sheet, "ItemNameLabel", "Label") as Label
	var item_sheet_description := _find_descendant_by_name_and_type(item_sheet, "ItemDescriptionLabel", "Label") as Label
	var item_sheet_effect := _find_descendant_by_name_and_type(item_sheet, "ItemEffectLabel", "Label") as Label
	var item_sheet_actions := _find_descendant_by_name_and_type(item_sheet, "ActionButtons", "HBoxContainer") as HBoxContainer
	if not assert_true(item_sheet_title != null and item_sheet_description != null and item_sheet_effect != null and item_sheet_actions != null, "Indoor item sheet should expose detail labels and action buttons."):
		indoor_mode.free()
		return
	assert_eq(item_sheet_title.text, "에너지바", "Indoor item sheet should show the selected item title.")
	assert_true(item_sheet_description.text.length() > 0, "Indoor item sheet should show an item description.")
	assert_true(item_sheet_effect.text.find("허기 +10") != -1, "Indoor item sheet should show exact hunger recovery values.")
	assert_true(item_sheet_effect.text.find("10분") != -1, "Indoor item sheet should show exact item use time where relevant.")
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
		bag_title_label.text,
		"소지품 (1/8)",
		"Eating an item should free carry space in the bag title."
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
	equipped_tab_button.emit_signal("pressed")
	await process_frame
	assert_eq(
		_inventory_labels(inventory_items),
		["등: 작은 배낭"],
		"Equipping an item should surface it in the equipped bag tab."
	)
	carried_tab_button.emit_signal("pressed")
	await process_frame

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
		bag_title_label.text,
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
		"시각: 1일차 11:10",
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


func _find_descendant_by_name_and_type(container: Node, expected_name: String, type_name: String = "") -> Node:
	if container == null:
		return null

	for child in container.get_children():
		if String(child.name) == expected_name and (type_name.is_empty() or child.is_class(type_name)):
			return child
		var nested := _find_descendant_by_name_and_type(child, expected_name, type_name)
		if nested != null:
			return nested

	return null


func get_job(job_id: String) -> Dictionary:
	return _test_jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return _test_traits.get(trait_id, {})
