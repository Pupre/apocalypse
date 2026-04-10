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

	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(content_library != null, "ContentLibrary should be available for indoor mode tests."):
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

	var craft_button := _find_descendant_by_name_and_type(top_bar, "CraftButton", "Button") as Button
	if not assert_true(craft_button == null, "Indoor mode should remove the dedicated craft button in portrait mode."):
		indoor_mode.free()
		return

	var codex_button := _find_descendant_by_name_and_type(top_bar, "CodexButton", "Button") as Button
	if not assert_true(codex_button == null, "Indoor mode should remove the dedicated codex button in portrait mode."):
		indoor_mode.free()
		return

	var minimap_overlay := indoor_mode.get_node_or_null("MinimapOverlay") as Control
	if not assert_true(minimap_overlay != null, "Indoor mode should expose a minimap overlay."):
		indoor_mode.free()
		return
	assert_true(not minimap_overlay.visible, "Indoor mode should keep the minimap overlay hidden by default.")

	var survival_sheet := indoor_mode.get_node_or_null("SurvivalSheet") as CanvasLayer
	if not assert_true(survival_sheet != null, "Indoor mode should mount the new SurvivalSheet."):
		indoor_mode.free()
		return
	assert_true(not survival_sheet.visible, "Indoor mode should keep the SurvivalSheet hidden by default.")

	var legacy_bag_sheet := indoor_mode.get_node_or_null("BagSheet") as Control
	if not assert_true(legacy_bag_sheet == null, "Indoor mode should remove the legacy BagSheet tree once SurvivalSheet is the only inventory surface."):
		indoor_mode.free()
		return

	var exit_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/Header/ExitButton") as Button
	if not assert_true(exit_button == null, "Indoor mode should no longer expose a global ExitButton."):
		indoor_mode.free()
		return

	var time_label := _find_descendant_by_name_and_type(top_bar, "TimeLabel", "Label") as Label
	if not assert_true(time_label != null, "Indoor mode should expose a TimeLabel for the shared clock."):
		indoor_mode.free()
		return
	assert_eq(
		time_label.text,
		"시각: 1일차 08:00",
		"Indoor mode should show the shared run clock after configure."
	)

	var location_strip := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/LocationStrip") as Control
	if not assert_true(
		location_strip != null and location_strip.visible,
		"Indoor mode should expose a dedicated location strip below the top bar."
	):
		indoor_mode.free()
		return

	var location_value := _find_descendant_by_name_and_type(location_strip, "LocationValueLabel", "Label") as Label
	if not assert_true(location_value != null, "Indoor mode should render the current zone inside the location strip."):
		indoor_mode.free()
		return
	assert_eq(
		location_value.text,
		"정문 진입부",
		"Indoor mode should show the current zone label without the old header-row prefix."
	)

	var context_row := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ContextRow") as Control
	if not assert_true(context_row == null, "Indoor mode should remove the old ContextRow wrapper in portrait mode."):
		indoor_mode.free()
		return

	var reading_card := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard") as Control
	if not assert_true(reading_card != null, "Indoor mode should mount ReadingCard directly under MainColumn."):
		indoor_mode.free()
		return
	assert_true(
		reading_card.size_flags_vertical != Control.SIZE_EXPAND_FILL,
		"Indoor mode should let the reading card hug its content so the action list keeps most portrait height."
	)

	var inline_minimap_card := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/MiniMapCard") as Control
	if not assert_true(
		inline_minimap_card != null and inline_minimap_card.visible,
		"Indoor mode should keep a small minimap visible in the main reading screen."
	):
		indoor_mode.free()
		return
	assert_true(
		inline_minimap_card.custom_minimum_size.y <= 104.0,
		"Indoor mode should keep the inline minimap shallow enough to preserve vertical space for actions."
	)

	var inline_minimap := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/MiniMapCard/MapNodes") as Control
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
	var stat_detail_close := _find_descendant_by_name_and_type(stat_detail_sheet, "CloseButton", "Button") as Button
	if not assert_true(
		stat_detail_title != null and stat_detail_value != null and stat_detail_rule != null and stat_detail_recovery != null and stat_detail_close != null,
		"Indoor mode should expose title/value/rule/recovery labels and a close button in the stat detail sheet."
	):
		indoor_mode.free()
		return
	assert_eq(stat_detail_title.text, String(target_chip_row.get("label", "")), "Indoor mode should show the selected stat title in the detail sheet.")
	assert_eq(
		stat_detail_value.text,
		"100 / 100 · 안정",
		"Indoor mode should render exact stat values without decimals."
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
	target_chip_button.emit_signal("pressed")
	await process_frame
	assert_true(
		not stat_detail_sheet.visible,
		"Indoor mode should toggle the stat detail sheet closed when the same chip is pressed again."
	)
	target_chip_button.emit_signal("pressed")
	await process_frame
	assert_true(
		stat_detail_sheet.visible,
		"Indoor mode should reopen the stat detail sheet when the chip is pressed again after toggling closed."
	)
	stat_detail_close.emit_signal("pressed")
	await process_frame
	assert_true(not stat_detail_sheet.visible, "Indoor mode should close the stat detail sheet when the close button is pressed.")

	bag_button.emit_signal("pressed")
	await process_frame
	assert_true(survival_sheet.visible, "Indoor mode should open the SurvivalSheet from the top bar.")
	assert_true(not stat_detail_sheet.visible, "Opening the SurvivalSheet should close the stat detail sheet.")

	map_button.emit_signal("pressed")
	await process_frame
	assert_true(minimap_overlay.visible, "Indoor mode should open the minimap overlay when the top-bar map button is pressed.")
	assert_true(not stat_detail_sheet.visible, "Opening the minimap should close the stat detail sheet.")
	map_button.emit_signal("pressed")
	await process_frame
	assert_true(not minimap_overlay.visible, "Indoor mode should close the minimap overlay when the map button is pressed again.")

	var summary_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/VBox/SummaryLabel") as Label
	if not assert_true(summary_label != null, "Indoor mode should expose a current-zone SummaryLabel."):
		indoor_mode.free()
		return
	assert_true(
		summary_label.text.find("깨진 자동문과 쓰러진 장바구니가 보인다.") != -1,
		"Indoor mode should show the current zone summary instead of the building summary."
	)
	assert_true(
		summary_label.text.find("남아 있는 물건 0개") != -1,
		"Indoor mode should append room status rows to the reading summary."
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

	var result_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/VBox/ResultLabel") as Label
	if not assert_true(result_label != null, "Indoor mode should expose a ResultLabel."):
		indoor_mode.free()
		return

	var action_scroll := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ActionScroll") as ScrollContainer
	if not assert_true(action_scroll != null, "Indoor mode should expose a scrollable action list container."):
		indoor_mode.free()
		return
	assert_true(
		action_scroll.custom_minimum_size.y >= 320.0,
		"Indoor mode should reserve a larger portrait baseline for the main action list."
	)
	var action_buttons := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ActionScroll/ActionButtons") as VBoxContainer
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

	if not assert_true(director != null and director.has_method("apply_action"), "Indoor mode should expose its Director node."):
		indoor_mode.free()
		return

	assert_true(
		director.apply_action("move_checkout"),
		"Director should allow moving to the checkout zone from the entry zone."
	)
	await process_frame
	assert_eq(
		location_value.text,
		"계산대",
		"Indoor mode should refresh the location strip after the director changes zone."
	)
	assert_true(
		summary_label.text.find("계산대 뒤쪽에는 직원 출입문이 있다.") != -1,
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
		director.get_inventory_rows().size(),
		2,
		"Picking up discovered items should update the indoor inventory payload."
	)

	assert_true(director.apply_action("inspect_inventory_energy_bar"), "Indoor mode should allow selecting a carried food item for inspection.")
	var selected_item_sheet: Dictionary = director.get_selected_inventory_sheet()
	assert_true(bool(selected_item_sheet.get("visible", false)), "Inspecting an item should expose selected sheet data.")
	assert_eq(String(selected_item_sheet.get("title", "")), "에너지바", "Selected sheet data should surface the chosen item title.")
	assert_true(String(selected_item_sheet.get("usage_hint", "")).length() > 0, "Selected item sheets should expose usage_hint.")
	assert_true(String(selected_item_sheet.get("cold_hint", "")).length() > 0, "Selected item sheets should expose cold_hint.")
	assert_true(Array(selected_item_sheet.get("item_tags", [])).size() > 0, "Selected item sheets should expose item_tags.")
	assert_true(director.apply_action("consume_inventory_energy_bar"), "Indoor mode should still allow consuming an item through director actions.")
	await process_frame
	assert_eq(
		director.get_inventory_rows().size(),
		1,
		"Eating a food item should remove it from the carried inventory payload."
	)
	assert_true(
		result_label.text.find("먹었다") != -1,
		"Eating an item should leave readable feedback."
	)

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
	assert_true(director.apply_action("equip_inventory_small_backpack"), "Indoor mode should allow equipping the backpack from the inventory flow.")
	await process_frame
	var equipped_rows: Array[Dictionary] = director.get_equipped_rows()
	assert_eq(equipped_rows.size(), 1, "Equipping an item should surface one equipped state row.")
	assert_eq(String(equipped_rows[0].get("slot_label", "")), "등", "The backpack should occupy the back slot.")

	assert_true(director.apply_action("inspect_inventory_lighter"), "Indoor mode should allow selecting the lighter for inspection.")
	selected_item_sheet = director.get_selected_inventory_sheet()
	assert_true(String(selected_item_sheet.get("effect_text", "")).find("잔량 5/5") != -1, "Lighter detail should show current remaining charges.")
	assert_true(String(selected_item_sheet.get("effect_text", "")).find("#ignition_tool") != -1, "Lighter detail should expose ignition tool tags.")
	assert_true(director.apply_action("drop_inventory_lighter"), "Indoor mode should still allow dropping the remaining utility item.")
	await process_frame
	assert_eq(director.get_inventory_rows().size(), 0, "Dropping the remaining item should restore the empty carried payload.")
	assert_true(
		result_label.text.find("버렸다") != -1 or result_label.text.find("내려놓았다") != -1,
		"Dropping an item from the inventory flow should leave readable feedback."
	)

	assert_true(run_state.inventory.add_item(content_library.get_item("newspaper")), "Indoor portrait test should add a newspaper crafting input.")
	assert_true(run_state.inventory.add_item(content_library.get_item("cooking_oil")), "Indoor portrait test should add cooking oil crafting input.")
	assert_true(run_state.inventory.add_item(content_library.get_item("steel_food_can")), "Indoor portrait test should add an invalid-on-purpose second ingredient that is still actually in the bag.")
	indoor_mode.refresh_view()
	bag_button.emit_signal("pressed")
	await process_frame
	assert_true(survival_sheet.visible, "Indoor mode should open the SurvivalSheet from the top bar.")
	assert_eq(survival_sheet.get_active_tab_id(), "inventory", "Opening from the top bar should land on inventory.")
	survival_sheet.select_inventory_item("newspaper")
	survival_sheet.begin_craft_mode("newspaper")
	assert_true(survival_sheet.get_highlighted_item_ids().has("cooking_oil"), "Indoor SurvivalSheet should surface easy-mode craft hints.")

	survival_sheet.select_inventory_item("steel_food_can")
	var failed_outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(failed_outcome.get("result_type", "")), "invalid", "Indoor craft flow should allow failed attempts.")
	assert_true(survival_sheet.visible, "A failed craft attempt should not close the survival sheet.")
	assert_eq(survival_sheet.get_selected_item_id(), "steel_food_can", "Indoor failed attempts should keep the currently inspected item selected.")

	survival_sheet.select_inventory_item("cooking_oil")
	var success_outcome: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(success_outcome.get("result_item_id", "")), "dense_fuel", "Indoor craft flow should still produce dense fuel.")
	assert_eq(survival_sheet.get_selected_item_id(), "dense_fuel", "Indoor craft success should jump directly to the result detail.")
	assert_true(
		result_label.text.find("고농축 땔감") != -1,
		"Indoor craft flow should push crafted item feedback back into the main reading result."
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
		"시각: 1일차 11:30",
		"Indoor mode should include the portrait craft time before walking back through known zones."
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


func _find_row_by_name(container: Node, expected_name: String) -> Control:
	if container == null:
		return null

	for child in container.get_children():
		var control := child as Control
		if control != null and String(control.name) == expected_name:
			return control
		var nested := _find_row_by_name(child, expected_name)
		if nested != null:
			return nested

	return null


func _row_text(row: Node, child_name: String) -> String:
	var child := _find_descendant_by_name_and_type(row, child_name)
	if child == null:
		return ""
	if child is Label:
		return (child as Label).text
	if child is Button:
		return (child as Button).text
	return ""


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
