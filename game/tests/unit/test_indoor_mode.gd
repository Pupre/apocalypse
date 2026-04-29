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
	assert_eq(indoor_mode._craft_toast_type({"result_type": "success"}), "success", "Indoor crafting success should map to a success toast.")
	assert_eq(indoor_mode._craft_toast_type({"result_type": "invalid"}), "warning", "Indoor invalid crafting should map to a warning toast.")
	assert_eq(indoor_mode._craft_toast_icon_item_id({"result_type": "success", "result_item_id": "bottled_water"}), "bottled_water", "Indoor success crafting should expose the crafted item icon.")
	assert_eq(indoor_mode._craft_toast_icon_item_id({"result_type": "failure", "result_item_id": "wet_newspaper"}), "", "Indoor failed crafting should not expose a result item icon.")

	if not assert_true(indoor_mode.has_signal("exit_requested"), "Indoor mode should emit exit_requested."):
		indoor_mode.free()
		return

	indoor_mode.exit_requested.connect(Callable(self, "_on_exit_requested"))
	var seen_toasts: Array[Dictionary] = []
	if not assert_true(indoor_mode.has_signal("toast_requested"), "Indoor mode should expose a toast_requested signal for the shared toast layer."):
		indoor_mode.free()
		return
	indoor_mode.toast_requested.connect(func(toast_type: String, message: String, duration: float, icon_item_id: String) -> void:
		seen_toasts.append({
			"type": toast_type,
			"message": message,
			"duration": duration,
			"icon_item_id": icon_item_id,
		})
	)

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

	if not assert_true(_find_descendant_by_name_and_type(top_bar, "ExitButton", "Button") == null, "Indoor mode should remove the exit button from the top-right tool cluster."):
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

	var legacy_exit_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/Header/ExitButton") as Button
	if not assert_true(legacy_exit_button == null, "Indoor mode should no longer expose a global ExitButton inside the main column."):
		indoor_mode.free()
		return

	var time_label := _find_descendant_by_name_and_type(top_bar, "TimeLabel", "Label") as Label
	if not assert_true(time_label != null, "Indoor mode should expose a TimeLabel for the shared clock."):
		indoor_mode.free()
		return
	await process_frame
	assert_true(map_button.global_position.x > time_label.global_position.x, "Indoor mode should keep the structure button anchored to the right of the header info.")
	assert_true(bag_button.global_position.x > map_button.global_position.x, "Indoor mode should keep the bag button in the same top-right tool cluster as outdoor mode.")
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
	var location_caption := _find_descendant_by_name_and_type(location_strip, "LocationCaptionLabel", "Label") as Label
	if not assert_true(location_value != null, "Indoor mode should render the current zone inside the location strip."):
		indoor_mode.free()
		return
	assert_eq(
		location_value.text,
		"정문 진입부",
		"Indoor mode should show the current zone label without the old header-row prefix."
	)
	var location_style := (location_strip as PanelContainer).get_theme_stylebox("panel") as StyleBoxTexture
	if not assert_true(location_style != null and location_style.texture != null, "Indoor mode should skin the location strip with a compact texture-backed panel."):
		indoor_mode.free()
		return
	assert_eq(location_style.texture.get_width(), 336, "Indoor location strip should use the master indoor location strip asset.")
	assert_eq(location_style.texture.get_height(), 44, "Indoor location strip should use the master indoor location strip height.")
	assert_true(location_caption != null, "Indoor mode should keep a location caption label.")
	assert_eq(location_caption.get_theme_font_size("font_size"), 13, "Indoor location caption should use the larger secondary compact font size.")
	assert_eq(location_value.get_theme_font_size("font_size"), 15, "Indoor location value should use the stronger primary card label font size.")

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
	var reading_style := (reading_card as PanelContainer).get_theme_stylebox("panel") as StyleBoxTexture
	if not assert_true(reading_style != null and reading_style.texture != null, "Indoor mode should skin the reading card with a compact texture-backed panel."):
		indoor_mode.free()
		return
	assert_eq(reading_style.texture.get_width(), 336, "Indoor reading card should use the master indoor reading panel asset.")
	assert_eq(reading_style.texture.get_height(), 168, "Indoor reading card should use the master indoor reading panel height.")

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
	var minimap_style := (inline_minimap_card as PanelContainer).get_theme_stylebox("panel") as StyleBoxTexture
	if not assert_true(minimap_style != null and minimap_style.texture != null, "Indoor mode should skin the inline minimap card with a compact texture-backed panel."):
		indoor_mode.free()
		return
	assert_eq(minimap_style.texture.get_width(), 336, "Indoor minimap card should use the master indoor minimap frame asset.")
	assert_eq(minimap_style.texture.get_height(), 184, "Indoor minimap card should use the master indoor minimap frame height.")

	var inline_minimap := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/MiniMapCard/Padding/MapNodes") as Control
	if not assert_true(inline_minimap != null, "Indoor mode should mount an always-visible minimap node."):
		indoor_mode.free()
		return

	var supply_picker_overlay := indoor_mode.get_node_or_null("SupplyPickerOverlay") as Control
	var supply_picker_title := indoor_mode.get_node_or_null("SupplyPickerOverlay/Padding/VBox/TitleLabel") as Label
	var supply_picker_quantity := indoor_mode.get_node_or_null("SupplyPickerOverlay/Padding/VBox/QuantityRow/QuantityValueLabel") as Label
	if not assert_true(supply_picker_overlay != null and supply_picker_title != null and supply_picker_quantity != null, "Indoor mode should expose a supply quantity picker overlay."):
		indoor_mode.free()
		return
	assert_true(not supply_picker_overlay.visible, "Indoor mode should keep the supply quantity picker hidden by default.")

	var gauge_row := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/GaugeRow")
	var health_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/GaugeRow/HealthGauge/StageLabel") as Label
	var hunger_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/GaugeRow/HungerGauge/StageLabel") as Label
	var thirst_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/GaugeRow/ThirstGauge/StageLabel") as Label
	var fatigue_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/GaugeRow/FatigueGauge/StageLabel") as Label
	var cold_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/GaugeRow/ColdGauge/StageLabel") as Label
	if not assert_true(
		gauge_row != null and health_label != null and hunger_label != null and thirst_label != null and fatigue_label != null and cold_label != null,
		"Indoor mode should replace the old stat chips with the shared survival gauge strip."
	):
		indoor_mode.free()
		return
	assert_true(health_label.visible, "Indoor mode should keep the health gauge name visible.")
	assert_true(hunger_label.visible, "Indoor mode should keep the hunger gauge name visible.")
	assert_true(thirst_label.visible, "Indoor mode should keep the thirst gauge name visible.")
	assert_true(fatigue_label.visible, "Indoor mode should keep the fatigue gauge name visible.")
	assert_true(cold_label.visible, "Indoor mode should keep the cold gauge name visible.")
	assert_eq(health_label.text, "체력", "Indoor mode should show only the health gauge name.")
	assert_eq(hunger_label.text, "허기", "Indoor mode should show only the hunger gauge name.")
	assert_eq(thirst_label.text, "갈증", "Indoor mode should show only the thirst gauge name.")
	assert_eq(fatigue_label.text, "피로", "Indoor mode should show only the fatigue gauge name.")
	assert_eq(cold_label.text, "추위", "Indoor mode should show only the cold gauge name.")

	var director := _find_descendant_by_name_and_type(indoor_mode, "Director")
	if not assert_true(director != null and director.has_method("apply_action"), "Indoor mode should expose its Director node."):
		indoor_mode.free()
		return

	bag_button.emit_signal("pressed")
	await process_frame
	assert_true(survival_sheet.visible, "Indoor mode should open the SurvivalSheet from the top bar.")

	map_button.emit_signal("pressed")
	await process_frame
	assert_true(minimap_overlay.visible, "Indoor mode should open the minimap overlay when the top-bar map button is pressed.")
	map_button.emit_signal("pressed")
	await process_frame
	assert_true(not minimap_overlay.visible, "Indoor mode should close the minimap overlay when the map button is pressed again.")

	var summary_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/Padding/VBox/SummaryLabel") as Label
	if not assert_true(summary_label != null, "Indoor mode should expose a current-zone SummaryLabel."):
		indoor_mode.free()
		return
	assert_true(
		summary_label.text.find("깨진 자동문과 쓰러진 장바구니가 입구를 막고 있다.") != -1,
		"Indoor mode should show the current zone summary instead of the building summary."
	)
	assert_true(
		summary_label.text.find("앞 매대만 보고 끝날 곳이 아니다.") == -1,
		"Indoor mode should not fall back to the building-level summary when a current zone summary exists."
	)
	assert_true(
		summary_label.text.find("남아 있는 물건 0개") != -1,
		"Indoor mode should append room status rows to the reading summary."
	)
	assert_eq(summary_label.get_theme_font_size("font_size"), 15, "Indoor reading summary should use the larger compact body font size.")

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

	var result_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/Padding/VBox/ResultLabel") as Label
	if not assert_true(result_label != null, "Indoor mode should expose a ResultLabel."):
		indoor_mode.free()
		return
	assert_eq(result_label.get_theme_font_size("font_size"), 14, "Indoor result text should use the larger secondary compact font size.")

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
	var move_section_header := _find_section_header_panel_by_text(action_buttons, "이동")
	if not assert_true(move_section_header != null, "Indoor mode should render section titles inside a dedicated compact header strip."):
		indoor_mode.free()
		return
	var move_section_header_style := move_section_header.get_theme_stylebox("panel") as StyleBoxTexture
	if not assert_true(move_section_header_style != null and move_section_header_style.texture != null, "Indoor action section headers should use a texture-backed compact strip style."):
		indoor_mode.free()
		return
	assert_eq(move_section_header_style.texture.get_width(), 384, "Indoor action section headers should use the plain compact strip asset.")
	assert_eq(move_section_header_style.texture.get_height(), 40, "Indoor action section headers should use the plain compact strip height.")
	var exit_button := _find_descendant_by_name_and_type(move_section_header, "ExitShortcutButton", "Button") as Button
	if not assert_true(exit_button != null, "Indoor mode should expose the exit shortcut inside the move section header."):
		indoor_mode.free()
		return
	assert_true(
		_find_button_by_text(action_buttons, "계산대로 이동한다 (30분)") != null,
		"Indoor mode should show travel time in movement actions."
	)
	assert_true(
		_button_has_icon(_find_button_by_text(action_buttons, "계산대로 이동한다 (30분)")),
		"Indoor mode should attach an icon to movement actions."
	)
	assert_eq(
		_find_button_by_text(action_buttons, "계산대로 이동한다 (30분)").modulate,
		Color(1, 1, 1, 1),
		"Indoor action rows should not tint the compact row skin with extra section colors."
	)
	var move_button_style := _find_button_by_text(action_buttons, "계산대로 이동한다 (30분)").get_theme_stylebox("normal") as StyleBoxTexture
	if not assert_true(move_button_style != null and move_button_style.texture != null, "Indoor action rows should use a compact texture-backed button style."):
		indoor_mode.free()
		return
	assert_eq(move_button_style.texture.get_width(), 620, "Indoor action rows should use the compact v2 action-row asset.")
	assert_eq(move_button_style.texture.get_height(), 50, "Indoor action rows should use the compact v2 action-row height.")
	assert_eq(exit_button.tooltip_text, "건물 밖으로 나간다", "Indoor mode should route the entrance exit affordance into the move-section exit shortcut.")
	assert_true(
		_find_button_by_text(action_buttons, "한 시간 쉰다 (60분)") == null,
		"Indoor mode should not expose the removed flat rest action."
	)

	var minimap_nodes := indoor_mode.get_node_or_null("MinimapOverlay/Padding/VBox/MapNodes") as Control
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
		summary_label.text.find("계산대 안쪽에 직원 통로로 이어지는 잠긴 문이 보인다.") != -1,
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
		_button_has_icon(_find_button_by_text(action_buttons, "계산대를 탐색한다 (30분)")),
		"Indoor mode should attach an icon to interaction actions."
	)
	assert_eq(
		_map_labels(minimap_nodes),
		["?", "?", "계산대", "정문 진입부"],
		"Indoor mode should keep visited zones visible and only reveal newly adjacent unknown zones."
	)
	move_section_header = _find_section_header_panel_by_text(action_buttons, "이동")
	exit_button = _find_descendant_by_name_and_type(move_section_header, "ExitShortcutButton", "Button") as Button
	assert_eq(exit_button.tooltip_text, "건물 밖으로 나간다 (10분)", "Indoor mode should move the shortest-route leave-building shortcut into the move-section header button.")

	assert_true(
		director.apply_action("search_checkout_drawer"),
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
	assert_true(not seen_toasts.is_empty(), "Indoor interactions should emit a toast alongside the existing result text.")
	assert_true(String(seen_toasts.back().get("message", "")).length() > 0, "Indoor toast messages should carry the same short feedback text.")
	assert_true(
		_find_button_by_text(action_buttons, "라이터 챙긴다") != null,
		"Searching should reveal follow-up actions for each discovered item."
	)
	assert_true(
		_button_has_icon(_find_button_by_text(action_buttons, "라이터 챙긴다")),
		"Indoor mode should attach an icon to discovered-loot actions."
	)
	assert_true(
		_button_has_icon(_find_button_by_text(action_buttons, "라이터 챙긴다")),
		"Discovered-loot actions should prefer the actual item icon over the generic loot basket."
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
	var remaining_take_button := _find_button_by_suffix_excluding(
		action_buttons,
		"챙긴다",
		PackedStringArray(["라이터 챙긴다"])
	)
	if not assert_true(remaining_take_button != null, "Indoor mode should refresh take actions after picking the first discovered item."):
		indoor_mode.free()
		return
	remaining_take_button.emit_signal("pressed")
	await process_frame
	assert_eq(
		director.get_inventory_rows().size(),
		2,
		"Picking up discovered items should update the indoor inventory payload."
	)

	assert_true(
		run_state.inventory.add_item(content_library.get_item("energy_bar")),
		"Indoor mode test should be able to seed a stable consumable inventory item for inspect/consume flow coverage."
	)
	await process_frame

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
		2,
		"Eating a seeded consumable should remove only that item from the carried inventory payload."
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
	assert_true(director.apply_action("search_food_aisle"), "Indoor mode should allow searching the food aisle for supply picker coverage.")
	indoor_mode._on_action_pressed("take_supply_food_aisle_water_shelf_detail")
	await process_frame
	assert_true(supply_picker_overlay.visible, "Indoor mode should open the supply picker when the detail supply action is pressed.")
	assert_true(supply_picker_title.text.find("생수") >= 0, "Supply picker should name the selected supply source item.")
	assert_eq(supply_picker_quantity.text, "1", "Supply picker should start at one item.")
	indoor_mode._on_supply_picker_cancel_pressed()
	await process_frame
	assert_true(not supply_picker_overlay.visible, "Indoor mode should hide the supply picker when cancel is pressed.")
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
	assert_eq(String(equipped_rows[0].get("item_id", "")), "small_backpack", "Equipped rows should carry the equipped item id so future UI can attach item art.")

	assert_true(director.apply_action("inspect_inventory_lighter"), "Indoor mode should allow selecting the lighter for inspection.")
	selected_item_sheet = director.get_selected_inventory_sheet()
	assert_true(String(selected_item_sheet.get("effect_text", "")).find("잔량 5/5") != -1, "Lighter detail should show current remaining charges.")
	assert_true(String(selected_item_sheet.get("effect_text", "")).find("#ignition_tool") != -1, "Lighter detail should expose ignition tool tags.")
	assert_true(director.apply_action("drop_inventory_lighter"), "Indoor mode should still allow dropping the remaining utility item.")
	await process_frame
	assert_eq(
		director.get_inventory_rows().size(),
		1,
		"Dropping the lighter should leave any other carried loot intact."
	)
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
		"시각: 1일차 12:00",
		"Indoor mode should include the supply search and portrait craft time before walking back through known zones."
	)
	move_section_header = _find_section_header_panel_by_text(action_buttons, "이동")
	exit_button = _find_descendant_by_name_and_type(move_section_header, "ExitShortcutButton", "Button") as Button
	assert_eq(exit_button.tooltip_text, "건물 밖으로 나간다", "Indoor mode should reset the move-section exit button once back at the entrance.")
	exit_button.emit_signal("pressed")
	assert_eq(_exit_requested_count, 1, "Pressing the move-section exit shortcut should emit exit_requested exactly once.")

	indoor_mode.free()
	pass_test("INDOOR_MODE_OK")


func _on_exit_requested() -> void:
	_exit_requested_count += 1


func _find_button_by_text(container: Node, expected_text: String) -> Button:
	if container == null:
		return null

	for child in container.get_children():
		var button := child as Button
		if button != null and _button_label_text(button) == expected_text:
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
		if button != null and _button_label_text(button).begins_with(expected_prefix):
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


func _find_section_header_panel_by_text(container: Node, expected_text: String) -> PanelContainer:
	if container == null:
		return null

	for child in container.get_children():
		var panel := child as PanelContainer
		if panel != null:
			for nested_child in panel.get_children():
				var label := nested_child as Label
				if label != null and label.text.strip_edges() == expected_text:
					return panel
				var nested_label := _find_first_label(nested_child)
				if nested_label != null and nested_label.text.strip_edges() == expected_text:
					return panel
		var nested := _find_section_header_panel_by_text(child, expected_text)
		if nested != null:
			return nested

	return null


func _find_button_by_suffix_excluding(container: Node, expected_suffix: String, excluded_texts: PackedStringArray = PackedStringArray()) -> Button:
	if container == null:
		return null

	for child in container.get_children():
		var button := child as Button
		var button_text := _button_label_text(button)
		if button != null \
				and button_text.ends_with(expected_suffix) \
				and not excluded_texts.has(button_text):
			return button
		var nested := _find_button_by_suffix_excluding(child, expected_suffix, excluded_texts)
		if nested != null:
			return nested

	return null


func _find_first_label(container: Node) -> Label:
	if container == null:
		return null

	for child in container.get_children():
		var label := child as Label
		if label != null:
			return label
		var nested := _find_first_label(child)
		if nested != null:
			return nested

	return null


func _button_label_text(button: Button) -> String:
	if button == null:
		return ""
	if not button.text.strip_edges().is_empty():
		return button.text
	var nested_label := _find_first_label(button)
	return nested_label.text.strip_edges() if nested_label != null else ""


func _button_has_icon(button: Button) -> bool:
	if button == null:
		return false
	if button.icon != null:
		return true
	return _find_descendant_icon(button) != null


func _find_descendant_icon(container: Node) -> TextureRect:
	if container == null:
		return null
	for child in container.get_children():
		var rect := child as TextureRect
		if rect != null and rect.texture != null:
			return rect
		var nested := _find_descendant_icon(child)
		if nested != null:
			return nested
	return null


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
