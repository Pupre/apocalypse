extends "res://tests/support/test_case.gd"

const BOOTSTRAP_SCENE_PATH := "res://scenes/bootstrap/main.tscn"

var _confirmed_job_id := ""
var _confirmed_trait_ids: Array[String] = []
var _transition_completed_modes: Array[String] = []


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	assert_eq(
		int(ProjectSettings.get_setting("display/window/size/viewport_width")),
		720,
		"Project should use a 720px viewport width for the portrait baseline."
	)
	assert_eq(
		int(ProjectSettings.get_setting("display/window/size/viewport_height")),
		1280,
		"Project should use a 1280px viewport height for the portrait baseline."
	)
	assert_eq(
		String(ProjectSettings.get_setting("display/window/stretch/mode", "")),
		"canvas_items",
		"Project should keep canvas_items stretch for the portrait UI shell."
	)
	assert_eq(
		String(ProjectSettings.get_setting("display/window/stretch/aspect", "")),
		"expand",
		"Project should expand the portrait shell instead of hard-locking a boxed keep aspect."
	)

	var bootstrap_scene := load(BOOTSTRAP_SCENE_PATH) as PackedScene
	if not assert_true(bootstrap_scene != null, "Missing bootstrap scene: %s" % BOOTSTRAP_SCENE_PATH):
		return

	var bootstrap = bootstrap_scene.instantiate()
	if not assert_true(bootstrap != null, "Failed to instantiate bootstrap scene."):
		return

	root.add_child(bootstrap)

	var active_screen: Node = bootstrap.get_active_screen()
	if not assert_true(active_screen != null, "Bootstrap should show an active screen."):
		bootstrap.free()
		return
	assert_eq(active_screen.name, "TitleMenu", "Bootstrap should start on the title menu.")

	var start_button := active_screen.get_node_or_null("Center/Panel/VBox/StartButton") as Button
	if not assert_true(start_button != null, "Title menu start button is missing."):
		bootstrap.free()
		return

	start_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_active_screen_name_is").bind(bootstrap, "SurvivorCreator"),
		"Timed out waiting for the survivor creator screen."
	):
		bootstrap.free()
		return

	active_screen = bootstrap.get_active_screen()
	if not assert_true(active_screen != null, "Bootstrap should show the survivor creator after start."):
		bootstrap.free()
		return
	assert_eq(active_screen.name, "SurvivorCreator", "Start should swap to the survivor creator.")

	var survivor_creator: Node = active_screen
	if not assert_true(survivor_creator.has_signal("survivor_confirmed"), "Survivor creator should emit survivor_confirmed."):
		bootstrap.free()
		return

	survivor_creator.survivor_confirmed.connect(Callable(self, "_on_survivor_confirmed"))

	var courier_button := survivor_creator.get_node_or_null("Center/Panel/VBox/JobButtons/CourierButton") as Button
	var easy_button := survivor_creator.get_node_or_null("Center/Panel/VBox/DifficultyButtons/EasyButton") as Button
	var hard_button := survivor_creator.get_node_or_null("Center/Panel/VBox/DifficultyButtons/HardButton") as Button
	var difficulty_status_label := survivor_creator.get_node_or_null("Center/Panel/VBox/DifficultyStatusLabel") as Label
	var athlete_button := survivor_creator.get_node_or_null("Center/Panel/VBox/TraitButtons/AthleteButton") as CheckButton
	var unlucky_button := survivor_creator.get_node_or_null("Center/Panel/VBox/TraitButtons/UnluckyButton") as CheckButton
	var creator_summary_label := survivor_creator.get_node_or_null("Center/Panel/VBox/SummaryLabel") as Label
	var confirm_button := survivor_creator.get_node_or_null("Center/Panel/VBox/ConfirmButton") as Button

	if not assert_true(courier_button != null, "Courier button is missing."):
		bootstrap.free()
		return
	if not assert_true(easy_button != null and hard_button != null and difficulty_status_label != null, "Difficulty controls are missing."):
		bootstrap.free()
		return
	if not assert_true(athlete_button != null, "Athlete trait button is missing."):
		bootstrap.free()
		return
	if not assert_true(unlucky_button != null, "Unlucky trait button is missing."):
		bootstrap.free()
		return
	if not assert_true(creator_summary_label != null and confirm_button != null, "Summary or confirm button is missing."):
		bootstrap.free()
		return

	assert_true(easy_button.disabled, "Easy should be the default selected difficulty.")
	assert_true(not hard_button.disabled, "Hard should start available.")
	assert_true(difficulty_status_label.text.find("이지") != -1, "The creator should surface the default easy difficulty.")
	assert_true(creator_summary_label.text.find("출발 준비 중") != -1, "The creator should surface an early loadout readiness summary.")

	courier_button.emit_signal("pressed")
	athlete_button.button_pressed = true
	unlucky_button.button_pressed = true

	var survivor_config: Dictionary = survivor_creator.get_survivor_config()
	assert_eq(String(survivor_config.get("job_id", "")), "courier", "The creator should build the selected job payload.")
	assert_eq(Array(survivor_config.get("trait_ids", [])), ["athlete", "unlucky"], "The creator should preserve the selected trait order.")
	assert_eq(int(survivor_config.get("remaining_points", -1)), 0, "The creator payload should spend all available points.")
	assert_eq(String(survivor_config.get("difficulty", "")), "easy", "The creator payload should default new runs to easy difficulty.")
	assert_true(not confirm_button.disabled, "The creator confirm button should be enabled before confirmation.")
	assert_true(creator_summary_label.text.find("출발 가능") != -1, "The creator should update the summary once the loadout is valid.")

	confirm_button.emit_signal("pressed")
	assert_eq(_confirmed_job_id, "courier", "Confirm should emit the selected job id.")
	assert_eq(_confirmed_trait_ids, ["athlete", "unlucky"], "Confirm should emit the selected trait order.")
	if not await _wait_until(
		Callable(self, "_active_screen_name_is").bind(bootstrap, "RunShell"),
		"Timed out waiting for the run shell screen."
	):
		bootstrap.free()
		return

	var run_shell: Node = bootstrap.get_node_or_null("RunShell")
	if not assert_true(run_shell != null, "Bootstrap should swap to the run shell after confirmation."):
		bootstrap.free()
		return

	if not assert_true(run_shell.has_method("get_current_mode_name"), "RunController should expose get_current_mode_name() for smoke verification."):
		bootstrap.free()
		return
	if not assert_true(run_shell.has_signal("transition_completed"), "RunController should expose transition_completed for smoke verification."):
		bootstrap.free()
		return
	if not assert_true(
		run_shell.has_method("is_transition_in_progress"),
		"RunController should expose is_transition_in_progress() for smoke verification."
	):
		bootstrap.free()
		return

	assert_eq(run_shell.get_current_mode_name(), "outdoor", "The run should begin in outdoor mode.")
	assert_true(
		not run_shell.is_transition_in_progress(),
		"The run should start without a mode transition in progress."
	)

	var hud := run_shell.get_node_or_null("HUD") as CanvasLayer
	var toast_presenter := run_shell.get_node_or_null("ToastPresenter") as CanvasLayer
	var shared_survival_sheet := run_shell.get_node_or_null("SurvivalSheet") as CanvasLayer
	var transition_layer: Node = run_shell.get_node_or_null("TransitionLayer")
	if not assert_true(hud != null, "Run shell should include a HUD."):
		bootstrap.free()
		return
	if not assert_true(toast_presenter != null, "The playable loop should mount the shared toast presenter."):
		bootstrap.free()
		return
	if not assert_true(shared_survival_sheet != null, "Run shell should mount the shared SurvivalSheet for outdoor bag flow."):
		bootstrap.free()
		return
	var top_ribbon := hud.get_node_or_null("TopRibbon") as PanelContainer
	if not assert_true(top_ribbon != null, "HUD should mount the portrait top ribbon after boot."):
		bootstrap.free()
		return
	var outdoor_bag_button := hud.get_node_or_null("TopRibbon/Margin/Stack/HeaderShell/HeaderMargin/HeaderRow/BagButton") as Button
	var outdoor_map_button := hud.get_node_or_null("TopRibbon/Margin/Stack/HeaderShell/HeaderMargin/HeaderRow/MapButton") as Button
	if not assert_true(outdoor_bag_button != null and outdoor_map_button != null, "Outdoor HUD should expose bag and map buttons in smoke coverage."):
		bootstrap.free()
		return
	assert_eq(top_ribbon.anchor_left, 0.0, "HUD TopRibbon should stretch from the left edge.")
	assert_eq(top_ribbon.anchor_right, 1.0, "HUD TopRibbon should stretch to the right edge.")
	if not assert_true(transition_layer != null, "Run shell should include a transition layer."):
		bootstrap.free()
		return
	if not assert_true(
		transition_layer.has_method("set_duration_for_tests"),
		"Transition layer should expose set_duration_for_tests()."
	):
		bootstrap.free()
		return

	transition_layer.set_duration_for_tests(0.0)

	var hud_clock_label := hud.get_node_or_null("TopRibbon/Margin/Stack/HeaderShell/HeaderMargin/HeaderRow/ClockLabel") as Label
	if not assert_true(hud_clock_label != null, "HUD clock label should be present."):
		bootstrap.free()
		return
	assert_eq(hud_clock_label.text, "1일차 08:00", "The run should start at 08:00.")

	var hud_title_label := hud.get_node_or_null("TopRibbon/Margin/Stack/HeaderShell/HeaderMargin/HeaderRow/TitleLabel") as Label
	if not assert_true(hud_title_label != null, "HUD title label should be present."):
		bootstrap.free()
		return
	assert_eq(hud_title_label.text, "외부 생존 정보", "Outdoor mode should use the outdoor HUD title.")
	assert_true(not shared_survival_sheet.visible, "Outdoor shared SurvivalSheet should stay hidden until the bag button is pressed.")
	outdoor_bag_button.emit_signal("pressed")
	await process_frame
	assert_true(shared_survival_sheet.visible, "Outdoor bag button should open the shared SurvivalSheet in smoke coverage.")
	outdoor_bag_button.emit_signal("pressed")
	await process_frame
	assert_true(not shared_survival_sheet.visible, "Outdoor bag button should close the shared SurvivalSheet on the second press.")

	var fade_rect := transition_layer.get_node_or_null("FadeRect") as ColorRect
	if not assert_true(fade_rect != null, "Transition layer should expose a FadeRect node."):
		bootstrap.free()
		return
	assert_eq(fade_rect.color.a, 0.0, "The transition layer should start transparent.")

	var outdoor_mode: Node = run_shell.get_node_or_null("ModeHost/OutdoorMode")
	var content_library := root.get_node_or_null("ContentLibrary")
	if not assert_true(outdoor_mode != null, "Run shell should launch the outdoor mode first."):
		bootstrap.free()
		return
	if not assert_true(outdoor_mode.has_method("get_world_bounds"), "Outdoor mode should expose get_world_bounds() for smoke verification."):
		bootstrap.free()
		return
	if not assert_true(outdoor_mode.has_method("get_active_block_coords"), "Outdoor mode should expose active block coordinates for smoke verification."):
		bootstrap.free()
		return
	await process_frame
	var hud_ribbon_rect := top_ribbon.get_global_rect()
	var outdoor_ribbon := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon") as Control
	if not assert_true(outdoor_ribbon != null, "Outdoor mode should expose its own compact status ribbon."):
		bootstrap.free()
		return
	var hint_label := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/HintLabel") as Label
	var threat_label := outdoor_mode.get_node_or_null("CanvasLayer/TopRibbon/Margin/VBox/ThreatLabel") as Label
	var frost_overlay := outdoor_mode.get_node_or_null("CanvasLayer/FrostOverlay") as ColorRect
	var frost_crystals := outdoor_mode.get_node_or_null("CanvasLayer/FrostCrystals") as TextureRect
	var map_overlay := outdoor_mode.get_node_or_null("MapOverlay") as CanvasLayer
	var full_map_view := outdoor_mode.get_node_or_null("MapOverlay/Panel/VBox/Margin/MapView") as Control
	var map_overlay_panel := outdoor_mode.get_node_or_null("MapOverlay/Panel") as PanelContainer
	if not assert_true(hint_label != null, "Outdoor mode should expose a hint label in smoke coverage."):
		bootstrap.free()
		return
	if not assert_true(threat_label != null, "Outdoor mode should expose a threat label in smoke coverage."):
		bootstrap.free()
		return
	if not assert_true(frost_overlay != null, "Outdoor mode should mount a frost overlay in smoke coverage."):
		bootstrap.free()
		return
	if not assert_true(frost_crystals != null and frost_crystals.texture != null, "Outdoor smoke coverage should mount the generated frost crystal texture."):
		bootstrap.free()
		return
	if not assert_true(map_overlay != null, "Outdoor smoke coverage should include the full-screen map overlay."):
		bootstrap.free()
		return
	if not assert_true(full_map_view != null, "Outdoor smoke coverage should include the full-screen spatial map view."):
		bootstrap.free()
		return
	var map_overlay_style := map_overlay_panel.get_theme_stylebox("panel") as StyleBoxTexture
	if not assert_true(map_overlay_style != null and map_overlay_style.texture != null, "Outdoor smoke coverage should skin the full-screen map overlay with a compact texture-backed panel."):
		bootstrap.free()
		return
	assert_eq(map_overlay_style.texture.get_width(), 680, "Outdoor full-screen map should use the master overlay map panel asset.")
	assert_eq(map_overlay_style.texture.get_height(), 1140, "Outdoor full-screen map should use the master overlay map panel height.")
	assert_true(threat_label.text.length() > 0, "Outdoor mode should show a readable threat line at boot.")
	assert_true(not map_overlay.visible, "Outdoor map overlay should stay hidden until the player opens it.")
	assert_true(outdoor_mode.has_method("show_map_overlay"), "Outdoor mode should expose show_map_overlay() in smoke coverage.")
	assert_true(outdoor_mode.has_method("hide_map_overlay"), "Outdoor mode should expose hide_map_overlay() in smoke coverage.")
	assert_eq(String(full_map_view.get_script().resource_path), "res://scripts/outdoor/outdoor_map_view.gd", "Outdoor smoke coverage should use the spatial full-map renderer.")
	var minute_before_map: int = run_shell.run_state.clock.minute_of_day
	outdoor_map_button.emit_signal("pressed")
	assert_true(map_overlay.visible, "Outdoor smoke coverage should be able to open the full-screen map.")
	outdoor_mode.simulate_seconds(60.0)
	assert_eq(run_shell.run_state.clock.minute_of_day, minute_before_map, "Smoke coverage should prove the full-screen map pauses outdoor simulation.")
	outdoor_map_button.emit_signal("pressed")
	assert_true(not map_overlay.visible, "Outdoor smoke coverage should be able to close the full-screen map.")
	var world_rect: Rect2 = outdoor_mode.get_world_bounds()
	assert_true(world_rect.size.x >= 7680.0, "Smoke coverage should prove the fixed-city outdoor world is mounted.")
	var active_blocks: Array = outdoor_mode.get_active_block_coords()
	assert_eq(active_blocks.size(), 9, "Outdoor smoke coverage should boot a 3x3 streamed block window.")
	var authored_coords := [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 2),
	]
	for block_coord in authored_coords:
		var block: Dictionary = content_library.get_outdoor_block(block_coord)
		assert_true(not block.is_empty(), "Smoke coverage expects authored outdoor block %s to exist." % [block_coord])
	assert_true(hint_label.text.length() > 0, "Outdoor status hint should be readable at run start.")
	if not assert_true(content_library != null, "ContentLibrary autoload should be present for outdoor building lookups."):
		bootstrap.free()
		return
	for building_id in ["convenience_01", "hardware_01", "gas_station_01", "laundry_01"]:
		assert_true(content_library.get_building(building_id).size() > 0, "Smoke coverage should prove '%s' is mounted in the expanded district." % building_id)

	var player_sprite := outdoor_mode.get_node_or_null("PlayerVisual") as Sprite2D
	var mart_data: Dictionary = content_library.get_building("mart_01")
	var mart_position_data: Dictionary = mart_data.get("outdoor_position", {})
	var mart_position := Vector2(
		float(mart_position_data.get("x", 640.0)),
		float(mart_position_data.get("y", 360.0))
	)
	if not assert_true(player_sprite != null, "Outdoor player visual should be present."):
		bootstrap.free()
		return

	var before_outdoor_minutes: int = run_shell.run_state.clock.minute_of_day
	outdoor_mode.simulate_seconds(120.0)
	assert_eq(run_shell.run_state.clock.minute_of_day, before_outdoor_minutes + 120, "Outdoor time should advance the shared clock.")
	assert_eq(hud_clock_label.text, "1일차 10:00", "HUD time should reflect outdoor time spent.")

	outdoor_mode.move_player(Vector2.RIGHT, 1.5)
	assert_true(player_sprite.position.distance_to(mart_position) <= 72.0, "The player should move into building entry range.")
	var pre_entry_player_position := player_sprite.position

	outdoor_mode.try_enter_building("mart_01")
	if not await _await_transition_completion(
		run_shell,
		hud,
		hud_title_label,
		fade_rect,
		"indoor",
		false,
		"",
		"IndoorMode",
		"Timed out waiting for the enter transition to settle on indoor mode."
	):
		bootstrap.free()
		return

	assert_eq(run_shell.get_current_mode_name(), "indoor", "Entering the building should swap the run shell to indoor mode.")
	assert_true(not hud.visible, "Indoor mode should hide the shared HUD.")
	assert_eq(fade_rect.color.a, 0.0, "The transition layer should end transparent after entering a building.")

	var indoor_mode: Node = run_shell.get_node_or_null("ModeHost/IndoorMode")
	if not assert_true(indoor_mode != null, "Run shell should contain the indoor mode after entry."):
		bootstrap.free()
		return

	var location_strip := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/LocationStrip") as Control
	if not assert_true(location_strip != null and location_strip.visible, "Indoor mode should expose a visible location strip."):
		bootstrap.free()
		return
	var location_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/LocationStrip/Padding/HBox/LocationValueLabel") as Label
	if not assert_true(location_label != null, "Indoor mode should expose the current zone inside the location strip."):
		bootstrap.free()
		return
	assert_eq(location_label.text, "정문 진입부", "Indoor mode should begin at the mart entrance zone.")

	var indoor_time_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/TimeLabel") as Label
	if not assert_true(indoor_time_label != null, "Indoor mode should expose a visible time label."):
		bootstrap.free()
		return
	assert_eq(indoor_time_label.text, "시각: 1일차 10:00", "Indoor mode should carry the shared clock into the indoor UI.")

	var summary_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/Padding/VBox/SummaryLabel") as Label
	if not assert_true(summary_label != null, "Indoor mode should expose a current-zone summary label."):
		bootstrap.free()
		return
	assert_true(summary_label.text.find("깨진 자동문과 쓰러진 장바구니가") != -1, "Indoor mode should describe the current entrance zone.")
	var zone_status_row := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/Padding/VBox/ZoneStatusRow") as HBoxContainer
	if not assert_true(zone_status_row != null and zone_status_row.visible, "Indoor mode should expose current-room status as readable chips."):
		bootstrap.free()
		return
	assert_true(summary_label.text.find("남아 있는 물건 0개") == -1, "Indoor mode should keep room status out of the prose summary.")
	assert_true(_section_labels(zone_status_row).has("남아 있는 물건 0개"), "Indoor mode should surface current-room loot status.")
	assert_true(_section_labels(zone_status_row).has("설치물 0개"), "Indoor mode should surface current-room deployment status.")
	var inline_minimap_card := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/MiniMapCard") as Control
	if not assert_true(inline_minimap_card != null and inline_minimap_card.visible, "Indoor mode should keep a small inline minimap visible."):
		bootstrap.free()
		return

	var clue_list := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ClueList") as VBoxContainer
	assert_true(clue_list == null, "Indoor mode should not expose a persistent clue list in the main layout.")

	var sleep_preview_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/SleepPreviewLabel") as Label
	assert_true(sleep_preview_label == null, "Indoor mode should not expose sleep preview in the main layout.")

	var action_buttons := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ActionScroll/ActionButtons") as VBoxContainer
	if not assert_true(action_buttons != null, "Indoor action buttons should be mounted in the UI tree."):
		bootstrap.free()
		return
	if not assert_true(_count_buttons(action_buttons) > 0, "The indoor UI should expose at least one action button."):
		bootstrap.free()
		return
	assert_true(_section_labels(action_buttons).has("다른 구역"), "Indoor actions should expose a movement section.")
	assert_true(_section_labels(action_buttons).has("여기서 할 일"), "Indoor actions should expose an interaction section.")
	assert_true(
		_buttons_include_text(action_buttons, "계산대로 이동한다 (30분)"),
		"The entrance zone should show move actions with their time cost."
	)
	assert_true(
		not _buttons_include_text(action_buttons, "한 시간 쉰다 (60분)"),
		"Indoor mode should not expose the removed flat rest action."
	)
	var move_section_header := _find_section_header_panel_by_text(action_buttons, "다른 구역")
	var exit_button := _find_descendant_by_name_and_type(move_section_header, "ExitShortcutButton", "Button") as Button
	if not assert_true(exit_button != null, "Indoor mode should expose the leave-building shortcut in the move section header."):
		bootstrap.free()
		return
	assert_eq(exit_button.tooltip_text, "건물 밖으로 나간다", "Indoor entrance should expose leaving the building through the move-section shortcut.")

	var map_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/MapButton") as Button
	var bag_button := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/BagButton") as Button
	var minimap_overlay := indoor_mode.get_node_or_null("MinimapOverlay") as Control
	var minimap_nodes := indoor_mode.get_node_or_null("MinimapOverlay/Padding/VBox/MapNodes") as Control
	var director := indoor_mode.get_node_or_null("Director") as Node
	if not assert_true(map_button != null and bag_button != null, "Indoor mode should expose map and bag buttons in the top bar."):
		bootstrap.free()
		return
	assert_true(indoor_mode.get_node_or_null("Panel/Layout/MainColumn/TopBar/HeaderRow/ExitButton") == null, "Indoor mode should remove the exit button from the top-right tool cluster.")
	if not assert_true(director != null and director.has_method("get_equipped_rows"), "Indoor mode should expose the indoor director for payload checks."):
		bootstrap.free()
		return
	if not assert_true(minimap_overlay != null, "Indoor mode should expose a minimap overlay."):
		bootstrap.free()
		return
	if not assert_true(minimap_nodes != null, "Indoor mode should expose a minimap node container."):
		bootstrap.free()
		return
	map_button.emit_signal("pressed")
	await process_frame
	assert_true(minimap_overlay.visible, "Indoor map button should open the minimap overlay.")
	assert_eq(_map_labels(minimap_nodes), ["?", "?", "정문 진입부"], "Indoor minimap should start with the current zone and adjacent unknown rooms only.")
	map_button.emit_signal("pressed")
	await process_frame
	assert_true(not minimap_overlay.visible, "Indoor map button should hide the minimap overlay on the second press.")

	var survival_sheet := indoor_mode.get_node_or_null("SurvivalSheet")
	if not assert_true(survival_sheet != null, "Indoor mode should expose the portrait SurvivalSheet."):
		bootstrap.free()
		return
	bag_button.emit_signal("pressed")
	await process_frame
	var inventory_items := survival_sheet.get_node_or_null("Sheet/VBox/InventoryPane/InventoryScroll/InventoryContent/InventoryItems") as VBoxContainer
	if not assert_true(inventory_items != null, "Indoor SurvivalSheet should expose an inventory item list."):
		bootstrap.free()
		return
	assert_true(survival_sheet.visible, "Indoor bag button should open the portrait SurvivalSheet.")
	bag_button.emit_signal("pressed")
	await process_frame
	assert_true(not survival_sheet.visible, "Indoor bag button should close the portrait SurvivalSheet when pressed again.")

	var move_checkout_button := _find_button_by_text(action_buttons, "계산대로 이동한다 (30분)")
	if not assert_true(move_checkout_button != null, "Indoor mode should expose a movement action into checkout."):
		bootstrap.free()
		return
	assert_true(not move_checkout_button.disabled, "The checkout movement action should be enabled before it is pressed.")

	var result_label := indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/Padding/VBox/ResultLabel") as Label
	if not assert_true(result_label != null, "Indoor result label should be present."):
		bootstrap.free()
		return

	move_checkout_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_label_text_is").bind(location_label, "계산대"),
		"Timed out waiting for the indoor location to change to checkout."
	):
		bootstrap.free()
		return
	assert_eq(indoor_time_label.text, "시각: 1일차 10:30", "Indoor mode should update the visible time after moving.")
	assert_true(summary_label.text.find("직원 통로") != -1, "Indoor mode should update the summary for the checkout zone.")

	assert_true(
		_buttons_include_text(action_buttons, "계산대를 탐색한다 (30분)"),
		"Checkout should expose its local search action."
	)
	map_button.emit_signal("pressed")
	await process_frame
	var checkout_map_labels := _map_labels(minimap_nodes)
	assert_true(checkout_map_labels.has("계산대"), "Indoor minimap should show the current checkout zone after moving.")
	assert_true(checkout_map_labels.has("정문 진입부"), "Indoor minimap should keep the visited entrance visible after moving.")
	map_button.emit_signal("pressed")
	await process_frame
	move_section_header = _find_section_header_panel_by_text(action_buttons, "다른 구역")
	exit_button = _find_descendant_by_name_and_type(move_section_header, "ExitShortcutButton", "Button") as Button
	assert_eq(exit_button.tooltip_text, "건물 밖으로 나간다 (10분)", "Leaving the building away from the entrance should update the move-section exit shortcut tooltip.")

	var checkout_search_button := _find_button_by_text(action_buttons, "계산대를 탐색한다 (30분)")
	if not assert_true(checkout_search_button != null, "Checkout search action should be selectable."):
		bootstrap.free()
		return

	checkout_search_button.emit_signal("pressed")
	if not await _wait_until(
			Callable(self, "_is_indoor_action_applied").bind(
				run_shell,
				indoor_time_label,
				result_label,
				action_buttons,
				"시각: 1일차 11:00",
				"발견했다.",
				-1
			),
			"Timed out waiting for the checkout search to apply."
	):
		bootstrap.free()
		return

	assert_eq(indoor_time_label.text, "시각: 1일차 11:00", "The checkout search should advance shared indoor time.")
	assert_true(result_label.text.find("30분 동안 탐색했다.") != -1, "Indoor feedback should describe the spent time.")
	assert_true(result_label.text.find("라이터") != -1, "Indoor feedback should mention a discovered item.")
	bag_button.emit_signal("pressed")
	await process_frame
	inventory_items = survival_sheet.get_node_or_null("Sheet/VBox/InventoryPane/InventoryScroll/InventoryContent/InventoryItems") as VBoxContainer
	assert_true(survival_sheet.visible, "Indoor bag flow should still open the SurvivalSheet after searching.")
	bag_button.emit_signal("pressed")
	await process_frame

	var take_lighter_button := _find_button_by_text(action_buttons, "라이터 챙긴다")
	if not assert_true(take_lighter_button != null, "Searching checkout should reveal a take action for the lighter."):
		bootstrap.free()
		return

	take_lighter_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_is_indoor_action_applied").bind(
			run_shell,
			indoor_time_label,
			result_label,
			action_buttons,
			"시각: 1일차 11:00",
			"라이터 챙겼다.",
			-1
		),
		"Timed out waiting for the take-loot action to apply."
	):
		bootstrap.free()
		return

	bag_button.emit_signal("pressed")
	await process_frame
	inventory_items = survival_sheet.get_node_or_null("Sheet/VBox/InventoryPane/InventoryScroll/InventoryContent/InventoryItems") as VBoxContainer
	assert_true(survival_sheet.visible, "Indoor bag flow should remain usable after taking discovered loot.")
	bag_button.emit_signal("pressed")
	await process_frame

	var move_entrance_button := _find_button_by_text(action_buttons, "정문 진입부로 이동한다 (10분)")
	if not assert_true(move_entrance_button != null, "Checkout should allow returning to the entrance zone."):
		bootstrap.free()
		return
	move_entrance_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_label_text_is").bind(location_label, "정문 진입부"),
		"Timed out waiting for the indoor location to return to the entrance."
	):
		bootstrap.free()
		return
	assert_eq(indoor_time_label.text, "시각: 1일차 11:10", "Indoor mode should keep the visible time in sync after returning to the entrance.")

	var move_food_aisle_button := _find_button_by_text(action_buttons, "식품 진열대로 이동한다 (30분)")
	if not assert_true(move_food_aisle_button != null, "Entrance should allow moving into the food aisle."):
		bootstrap.free()
		return
	move_food_aisle_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_label_text_is").bind(location_label, "식품 진열대"),
		"Timed out waiting for the indoor location to change to the food aisle."
	):
		bootstrap.free()
		return

	var move_household_goods_button := _find_button_by_text(action_buttons, "생활용품 코너로 이동한다 (30분)")
	if not assert_true(move_household_goods_button != null, "Food aisle should allow moving into household goods."):
		bootstrap.free()
		return
	move_household_goods_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_label_text_is").bind(location_label, "생활용품 코너"),
		"Timed out waiting for the indoor location to change to household goods."
	):
		bootstrap.free()
		return

	assert_true(director.apply_action("search_household_goods"), "Director should allow searching household goods.")
	var take_household_backpack_button := _find_button_by_prefix(action_buttons, "작은 배낭 챙긴다")
	if not assert_true(take_household_backpack_button != null, "Household goods should reveal a backpack to take."):
		bootstrap.free()
		return
	take_household_backpack_button.emit_signal("pressed")
	await process_frame
	assert_true(director.apply_action("inspect_inventory_small_backpack"), "Indoor mode should allow selecting the backpack for inspection.")
	assert_true(director.apply_action("equip_inventory_small_backpack"), "Indoor mode should allow equipping the backpack from the item sheet.")
	await process_frame

	var equipped_rows: Array[Dictionary] = director.get_equipped_rows()
	assert_eq(equipped_rows.size(), 1, "Equipping an item should surface one equipped row.")
	assert_eq(String(equipped_rows[0].get("slot_label", "")), "등", "Equipping a backpack should occupy the back slot.")
	assert_eq(String(equipped_rows[0].get("item_name", "")), "작은 배낭", "Equipped rows should report the backpack name.")

	var move_food_aisle_back_button := _find_button_by_text(action_buttons, "식품 진열대로 이동한다 (10분)")
	if not assert_true(move_food_aisle_back_button != null, "Household goods should allow moving back to the food aisle."):
		bootstrap.free()
		return
	move_food_aisle_back_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_label_text_is").bind(location_label, "식품 진열대"),
		"Timed out waiting for the indoor location to return to the food aisle."
	):
		bootstrap.free()
		return

	var move_entrance_back_button := _find_button_by_text(action_buttons, "정문 진입부로 이동한다 (10분)")
	if not assert_true(move_entrance_back_button != null, "Food aisle should allow returning to the entrance zone."):
		bootstrap.free()
		return
	move_entrance_back_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_label_text_is").bind(location_label, "정문 진입부"),
		"Timed out waiting for the indoor location to return to the entrance."
	):
		bootstrap.free()
		return
	assert_eq(indoor_time_label.text, "시각: 1일차 13:00", "Indoor mode should keep the visible time in sync after returning to the entrance.")
	move_section_header = _find_section_header_panel_by_text(action_buttons, "다른 구역")
	exit_button = _find_descendant_by_name_and_type(move_section_header, "ExitShortcutButton", "Button") as Button
	assert_eq(exit_button.tooltip_text, "건물 밖으로 나간다", "Returning to the entrance should restore the zero-cost move-section exit shortcut tooltip.")

	assert_true(run_shell.run_state.read_knowledge_item("improvised_heat_note_01"), "Smoke should unlock note-backed recipes.")
	assert_true(run_shell.run_state.knows_recipe("bottled_water__can_stove"), "Smoke should reveal the heated-water recipe after reading.")
	bag_button.emit_signal("pressed")
	await process_frame
	assert_true(survival_sheet.visible, "Indoor bag flow should open the SurvivalSheet before codex checks.")
	if not assert_true(survival_sheet.has_method("open_codex") and survival_sheet.has_method("get_active_tab_id"), "Indoor SurvivalSheet should expose codex helpers for smoke verification."):
		bootstrap.free()
		return
	survival_sheet.open_codex()
	await process_frame
	assert_eq(survival_sheet.get_active_tab_id(), "codex", "Indoor SurvivalSheet should open the codex tab directly.")
	assert_true(_find_label_containing(survival_sheet, "신문지 + 식용유 -> 고농축 땔감") != null, "Known dense-fuel recipes should appear in the indoor codex.")
	survival_sheet.close_sheet()
	await process_frame

	assert_true(run_shell.run_state.inventory.add_item(content_library.get_item("newspaper")), "Smoke test should seed crafting paper.")
	assert_true(run_shell.run_state.inventory.add_item(content_library.get_item("cooking_oil")), "Smoke test should seed crafting oil.")
	assert_true(run_shell.run_state.inventory.add_item(content_library.get_item("steel_food_can")), "Smoke test should seed a can stove shell.")
	assert_true(run_shell.run_state.inventory.add_item(content_library.get_item("bottled_water")), "Smoke test should seed water for heating.")
	assert_true(run_shell.run_state.inventory.add_item(content_library.get_item("tea_bag")), "Smoke test should seed tea for the warmth chain.")
	bag_button.emit_signal("pressed")
	await process_frame
	assert_true(survival_sheet.visible, "Indoor bag flow should reopen the SurvivalSheet for crafting.")
	assert_eq(survival_sheet.get_active_tab_id(), "inventory", "Indoor bag flow should land on inventory for portrait crafting.")
	survival_sheet.select_inventory_item("newspaper")
	survival_sheet.begin_craft_mode("newspaper")
	var craft_card := survival_sheet.get_node_or_null("CraftCard") as Control
	if not assert_true(craft_card != null and craft_card.visible, "Craft mode should expose the explicit craft card in the playable loop."):
		bootstrap.free()
		return
	var craft_confirm_button := survival_sheet.get_node_or_null("CraftCard/Padding/VBox/ActionsRow/CraftConfirmButton") as Button
	if not assert_true(craft_confirm_button != null, "The playable loop should expose the craft confirm button inside the craft card."):
		bootstrap.free()
		return
	assert_true(survival_sheet.get_highlighted_item_ids().has("cooking_oil"), "The dev starter kit should surface a compatible oil craft hint.")
	survival_sheet.select_inventory_item("steel_food_can")
	var invalid_craft_result: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(invalid_craft_result.get("result_type", "")), "invalid", "Indoor portrait crafting should allow a failed craft attempt.")
	assert_eq(survival_sheet.get_selected_item_id(), "steel_food_can", "Failed craft attempts should keep the currently inspected item selected.")
	survival_sheet.select_inventory_item("cooking_oil")
	var dense_fuel_result: Dictionary = survival_sheet.confirm_craft()
	assert_eq(String(dense_fuel_result.get("result_item_id", "")), "dense_fuel", "Indoor chain crafting should make dense fuel first.")
	assert_eq(survival_sheet.get_selected_item_id(), "dense_fuel", "The crafted dense fuel should remain selected for immediate inspection.")
	var can_stove_result: Dictionary = run_shell.run_state.attempt_craft("steel_food_can", "dense_fuel", "indoor")
	assert_eq(String(can_stove_result.get("result_item_id", "")), "can_stove", "Indoor chain crafting should make a can stove second.")
	var hot_water_result: Dictionary = run_shell.run_state.attempt_craft("bottled_water", "can_stove", "indoor")
	assert_eq(String(hot_water_result.get("result_item_id", "")), "hot_water", "Indoor chain crafting should heat water.")
	assert_eq(run_shell.run_state.get_tool_charges("lighter"), 4, "Heating water should spend one lighter charge in the live loop.")
	assert_true(run_shell.run_state.knows_recipe("bottled_water__can_stove"), "Successful heating should keep the hot-water recipe unlocked.")
	var warm_tea_result: Dictionary = run_shell.run_state.attempt_craft("hot_water", "tea_bag", "indoor")
	assert_eq(String(warm_tea_result.get("result_item_id", "")), "warm_tea", "Indoor chain crafting should finish with warm tea.")
	assert_eq(run_shell.run_state.inventory.count_item_by_id("can_stove"), 1, "Heating water should keep the can stove for later use.")
	assert_eq(run_shell.run_state.inventory.count_item_by_id("warm_tea"), 1, "Indoor chain crafting should leave warm tea in inventory.")
	survival_sheet.close_sheet()
	await process_frame

	assert_true(run_shell.run_state.inventory.add_item(content_library.get_item("window_cover_patch")), "Smoke test should seed a deployable insulation patch.")
	assert_true(run_shell.run_state.deploy_item_in_current_site("window_cover_patch"), "Indoor smoke loop should allow installing a patch in the current room.")
	assert_true(run_shell.run_state.inventory.add_item(content_library.get_item("newspaper")), "Smoke test should seed a dropped item for persistence checks.")
	assert_true(director.apply_action("drop_inventory_newspaper"), "Indoor smoke loop should allow dropping an item into the room memory.")
	indoor_mode.refresh_view()
	await process_frame
	assert_true(_section_labels(zone_status_row).has("남아 있는 물건 1개"), "Indoor status chips should show dropped room loot.")
	assert_true(_section_labels(zone_status_row).has("설치물 1개"), "Indoor status chips should show installed room deployments.")

	move_section_header = _find_section_header_panel_by_text(action_buttons, "다른 구역")
	exit_button = _find_descendant_by_name_and_type(move_section_header, "ExitShortcutButton", "Button") as Button
	if not assert_true(exit_button != null, "Indoor move section should continue exposing an exit shortcut after later view refreshes."):
		bootstrap.free()
		return
	exit_button.emit_signal("pressed")
	if not await _await_transition_completion(
		run_shell,
		hud,
		hud_title_label,
		fade_rect,
		"outdoor",
		true,
		"외부 생존 정보",
		"OutdoorMode",
		"Timed out waiting for the exit transition to settle on outdoor mode."
	):
		bootstrap.free()
		return

	assert_eq(run_shell.get_current_mode_name(), "outdoor", "Pressing the entrance leave action should return the run shell to outdoor mode.")
	assert_true(hud.visible, "Returning outside should restore the shared HUD.")
	assert_eq(hud_title_label.text, "외부 생존 정보", "Returning outside should restore the outdoor HUD presentation.")
	assert_eq(fade_rect.color.a, 0.0, "The transition layer should end transparent after leaving the building.")

	outdoor_mode = run_shell.get_node_or_null("ModeHost/OutdoorMode")
	if not assert_true(outdoor_mode != null, "Run shell should recreate the outdoor mode after exit."):
		bootstrap.free()
		return

	player_sprite = outdoor_mode.get_node_or_null("PlayerVisual") as Sprite2D
	if not assert_true(player_sprite != null, "Outdoor mode should restore the player visual after exit."):
		bootstrap.free()
		return
	assert_true(
		player_sprite.position.distance_to(pre_entry_player_position) <= 0.01,
		"Exiting the building should restore the previous outdoor player position."
	)

	var office_position: Vector2 = _building_position(content_library.get_building("office_01"))
	var to_office: Vector2 = office_position - outdoor_mode.get_player_position()
	var outdoor_speed: float = max(run_shell.run_state.get_outdoor_move_speed(), 1.0)
	outdoor_mode.move_player(to_office, (to_office.length() / outdoor_speed) + 0.1)
	assert_true(outdoor_mode.get_player_position().distance_to(office_position) <= 72.0, "Outdoor mode should be able to reach the office entry range.")
	outdoor_mode.try_enter_building("office_01")
	if not await _await_transition_completion(
		run_shell,
		hud,
		hud_title_label,
		fade_rect,
		"indoor",
		false,
		"",
		"IndoorMode",
		"Timed out waiting for the office enter transition."
	):
		bootstrap.free()
		return

	indoor_mode = run_shell.get_node_or_null("ModeHost/IndoorMode")
	location_label = indoor_mode.get_node_or_null("Panel/Layout/MainColumn/LocationStrip/Padding/HBox/LocationValueLabel") as Label
	action_buttons = indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ActionScroll/ActionButtons") as VBoxContainer
	if not assert_true(indoor_mode != null and location_label != null and action_buttons != null, "Office indoor mode should expose stable nodes after transition."):
		bootstrap.free()
		return
	assert_eq(location_label.text, "출입구", "Office should open at its entry zone.")

	move_section_header = _find_section_header_panel_by_text(action_buttons, "다른 구역")
	exit_button = _find_descendant_by_name_and_type(move_section_header, "ExitShortcutButton", "Button") as Button
	if not assert_true(exit_button != null, "Office entrance should expose the move-section leave-building button."):
		bootstrap.free()
		return
	assert_eq(exit_button.tooltip_text, "건물 밖으로 나간다", "Office entrance should also route exit through the move-section button.")
	exit_button.emit_signal("pressed")
	if not await _await_transition_completion(
		run_shell,
		hud,
		hud_title_label,
		fade_rect,
		"outdoor",
		true,
		"외부 생존 정보",
		"OutdoorMode",
		"Timed out waiting for the office exit transition."
	):
		bootstrap.free()
		return

	outdoor_mode = run_shell.get_node_or_null("ModeHost/OutdoorMode")
	player_sprite = outdoor_mode.get_node_or_null("PlayerVisual") as Sprite2D
	if not assert_true(outdoor_mode != null and player_sprite != null, "Outdoor mode should restore after leaving the office."):
		bootstrap.free()
		return

	var back_to_mart: Vector2 = mart_position - outdoor_mode.get_player_position()
	outdoor_speed = max(run_shell.run_state.get_outdoor_move_speed(), 1.0)
	outdoor_mode.move_player(back_to_mart, (back_to_mart.length() / outdoor_speed) + 0.1)
	assert_true(player_sprite.position.distance_to(mart_position) <= 72.0, "Outdoor mode should return to mart entry range for persistence checks.")
	outdoor_mode.try_enter_building("mart_01")
	if not await _await_transition_completion(
		run_shell,
		hud,
		hud_title_label,
		fade_rect,
		"indoor",
		false,
		"",
		"IndoorMode",
		"Timed out waiting for the mart re-entry transition."
	):
		bootstrap.free()
		return

	indoor_mode = run_shell.get_node_or_null("ModeHost/IndoorMode")
	location_label = indoor_mode.get_node_or_null("Panel/Layout/MainColumn/LocationStrip/Padding/HBox/LocationValueLabel") as Label
	summary_label = indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/Padding/VBox/SummaryLabel") as Label
	action_buttons = indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ActionScroll/ActionButtons") as VBoxContainer
	if not assert_true(indoor_mode != null and location_label != null and summary_label != null and action_buttons != null, "Mart re-entry should rebuild the indoor nodes."):
		bootstrap.free()
		return
	assert_eq(location_label.text, "정문 진입부", "Mart re-entry should still start from the entry zone.")
	zone_status_row = indoor_mode.get_node_or_null("Panel/Layout/MainColumn/ReadingCard/Padding/VBox/ZoneStatusRow") as HBoxContainer
	if not assert_true(zone_status_row != null and zone_status_row.visible, "Mart re-entry should rebuild the room status chip row."):
		bootstrap.free()
		return
	assert_true(_section_labels(zone_status_row).has("남아 있는 물건 1개"), "Mart re-entry should remember dropped room loot.")
	assert_true(_section_labels(zone_status_row).has("설치물 1개"), "Mart re-entry should remember installed room deployments.")
	assert_true(_buttons_include_text(action_buttons, "신문지 챙긴다"), "Mart re-entry should surface the dropped newspaper as floor loot.")

	move_checkout_button = _find_button_by_prefix(action_buttons, "계산대로 이동한다")
	if not assert_true(move_checkout_button != null, "Mart re-entry should still allow moving to checkout."):
		bootstrap.free()
		return
	move_checkout_button.emit_signal("pressed")
	if not await _wait_until(
		Callable(self, "_label_text_is").bind(location_label, "계산대"),
		"Timed out waiting for mart re-entry checkout movement."
	):
		bootstrap.free()
		return
	assert_true(not _buttons_include_text(action_buttons, "라이터 챙긴다"), "Already-looted checkout items should not respawn after leaving and coming back.")

	bootstrap.free()
	bootstrap = null
	bootstrap_scene = null

	pass_test("FIRST_PLAYABLE_LOOP_OK")


func _on_survivor_confirmed(job_id: String, trait_ids: Array[String]) -> void:
	_confirmed_job_id = job_id
	_confirmed_trait_ids = trait_ids.duplicate()


func _active_screen_name_is(bootstrap: Node, expected_name: String) -> bool:
	if bootstrap == null or not bootstrap.has_method("get_active_screen"):
		return false

	var active_screen: Node = bootstrap.get_active_screen()
	return active_screen != null and active_screen.name == expected_name


func _find_button_by_text(container: Node, text: String) -> Button:
	if container == null:
		return null

	for child in container.get_children():
		var button := child as Button
		if button != null and _button_label_text(button) == text:
			return button
		var nested := _find_button_by_text(child, text)
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


func _find_label_containing(container: Node, expected_fragment: String) -> Label:
	if container == null:
		return null

	for child in container.get_children():
		var label := child as Label
		if label != null and label.text.find(expected_fragment) != -1:
			return label
		var nested := _find_label_containing(child, expected_fragment)
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


func _buttons_include_text(container: Node, text: String) -> bool:
	return _find_button_by_text(container, text) != null


func _count_buttons(container: Node) -> int:
	if container == null:
		return 0

	var total := 0
	for child in container.get_children():
		if child is Button:
			total += 1
		total += _count_buttons(child)
	return total


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
			var nested_label := _find_first_label(panel)
			if nested_label != null and nested_label.text.strip_edges() == expected_text:
				return panel
		var nested := _find_section_header_panel_by_text(child, expected_text)
		if nested != null:
			return nested
	return null


func _label_text_is(label: Label, expected_text: String) -> bool:
	return label != null and label.text == expected_text


func _building_position(building_data: Dictionary) -> Vector2:
	var outdoor_position: Dictionary = building_data.get("outdoor_position", {})
	return Vector2(
		float(outdoor_position.get("x", 0.0)),
		float(outdoor_position.get("y", 0.0))
	)


func _await_transition_completion(
	run_shell: Node,
	hud: CanvasLayer,
	hud_title_label: Label,
	fade_rect: ColorRect,
	expected_mode_name: String,
	expected_hud_visible: bool,
	expected_hud_title: String,
	expected_mode_node_name: String,
	failure_message: String,
	max_frames: int = 30
) -> bool:
	_transition_completed_modes.clear()
	run_shell.transition_completed.connect(Callable(self, "_on_transition_completed"))
	var predicate := Callable(self, "_is_transition_settled").bind(
		run_shell,
		hud,
		hud_title_label,
		fade_rect,
		expected_mode_name,
		expected_hud_visible,
		expected_hud_title,
		expected_mode_node_name
	)
	var result := await _wait_until(predicate, failure_message, max_frames)
	if run_shell.transition_completed.is_connected(Callable(self, "_on_transition_completed")):
		run_shell.transition_completed.disconnect(Callable(self, "_on_transition_completed"))
	return result


func _wait_until(predicate: Callable, failure_message: String, max_frames: int = 30) -> bool:
	for _i in range(max_frames):
		if predicate.call():
			return true
		await process_frame

	return assert_true(predicate.call(), failure_message)


func _is_indoor_action_applied(
	run_shell: Node,
	clock_label: Label,
	result_label: Label,
	action_buttons: VBoxContainer,
	expected_clock_text: String,
	expected_feedback_substring: String,
	expected_action_count: int
) -> bool:
	if run_shell == null or clock_label == null or result_label == null or action_buttons == null:
		return false

	return (
		clock_label.text == expected_clock_text
		and result_label.text.find(expected_feedback_substring) != -1
		and (expected_action_count < 0 or _count_buttons(action_buttons) == expected_action_count)
	)


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


func _is_transition_settled(
	run_shell: Node,
	hud: CanvasLayer,
	hud_title_label: Label,
	fade_rect: ColorRect,
	expected_mode_name: String,
	expected_hud_visible: bool,
	expected_hud_title: String,
	expected_mode_node_name: String
) -> bool:
	if run_shell == null or hud == null or hud_title_label == null or fade_rect == null:
		return false
	if not run_shell.has_method("get_current_mode_name"):
		return false
	if not run_shell.has_method("is_transition_in_progress"):
		return false

	var mode_host := run_shell.get_node_or_null("ModeHost")
	if mode_host == null:
		return false

	return (
		_transition_completed_modes.has(expected_mode_name)
		and run_shell.get_current_mode_name() == expected_mode_name
		and not run_shell.is_transition_in_progress()
		and hud.visible == expected_hud_visible
		and (not expected_hud_visible or hud_title_label.text == expected_hud_title)
		and is_equal_approx(fade_rect.color.a, 0.0)
		and mode_host.get_node_or_null(expected_mode_node_name) != null
	)


func _on_transition_completed(mode_name: String) -> void:
	if not _transition_completed_modes.has(mode_name):
		_transition_completed_modes.append(mode_name)
