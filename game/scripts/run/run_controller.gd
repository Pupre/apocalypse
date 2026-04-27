extends Node

signal transition_started(mode_name: String)
signal transition_completed(mode_name: String)

const OUTDOOR_MODE_SCENE := preload("res://scenes/outdoor/outdoor_mode.tscn")
const RUN_STATE_SCRIPT := preload("res://scripts/run/run_state.gd")
const INDOOR_MODE_SCENE := preload("res://scenes/indoor/indoor_mode.tscn")
const TEMP_DEV_STARTER_KIT_ITEM_IDS := [
	"newspaper",
	"cooking_oil",
	"steel_food_can",
	"bottled_water",
	"lighter",
	"tea_bag",
	"instant_soup_powder",
]

var run_state = null
var _hud_presenter: Node = null
var _toast_presenter: CanvasLayer = null
var _survival_sheet: CanvasLayer = null
var _transition_layer: Node = null
var _mode_host: Node = null
var _current_mode_name := ""
var _current_building_id := "mart_01"
var _return_outdoor_player_position = null
var _transition_in_progress := false
var _shared_survival_sheet_open := false
var _outdoor_inventory_feedback_message := ""


func start_run(survivor_config: Dictionary, building_id: String = "mart_01") -> void:
	run_state = RUN_STATE_SCRIPT.from_survivor_config(survivor_config)
	if run_state == null:
		push_error("RunController could not create a run state.")
		return

	_grant_temporary_dev_starter_kit()

	_hud_presenter = get_node_or_null("HUD")
	_toast_presenter = get_node_or_null("ToastPresenter") as CanvasLayer
	_survival_sheet = get_node_or_null("SurvivalSheet") as CanvasLayer
	_transition_layer = get_node_or_null("TransitionLayer")
	_mode_host = get_node_or_null("ModeHost")
	_current_building_id = building_id

	if _hud_presenter != null and _hud_presenter.has_method("set_run_state"):
		_hud_presenter.set_run_state(run_state)
	if _hud_presenter != null and _hud_presenter.has_method("set_mode_presentation"):
		_hud_presenter.set_mode_presentation("outdoor")
	if _hud_presenter != null and _hud_presenter.has_signal("bag_requested") and not _hud_presenter.bag_requested.is_connected(Callable(self, "_on_hud_bag_requested")):
		_hud_presenter.bag_requested.connect(Callable(self, "_on_hud_bag_requested"))
	if _hud_presenter != null and _hud_presenter.has_signal("map_requested") and not _hud_presenter.map_requested.is_connected(Callable(self, "_on_hud_map_requested")):
		_hud_presenter.map_requested.connect(Callable(self, "_on_hud_map_requested"))
	if _survival_sheet != null and _survival_sheet.has_method("bind_run_state"):
		_survival_sheet.bind_run_state(run_state)
		_survival_sheet.set_mode_name("outdoor")
	if _survival_sheet != null and _survival_sheet.has_signal("close_requested") and not _survival_sheet.close_requested.is_connected(Callable(self, "_on_survival_sheet_closed")):
		_survival_sheet.close_requested.connect(Callable(self, "_on_survival_sheet_closed"))
	if _survival_sheet != null and _survival_sheet.has_signal("inventory_action_requested") and not _survival_sheet.inventory_action_requested.is_connected(Callable(self, "_on_survival_sheet_action_requested")):
		_survival_sheet.inventory_action_requested.connect(Callable(self, "_on_survival_sheet_action_requested"))
	if _survival_sheet != null and _survival_sheet.has_signal("craft_applied") and not _survival_sheet.craft_applied.is_connected(Callable(self, "_on_crafting_applied")):
		_survival_sheet.craft_applied.connect(Callable(self, "_on_crafting_applied"))

	_show_outdoor_mode(building_id)
	_refresh_hud()


func _grant_temporary_dev_starter_kit() -> void:
	if run_state == null or ContentLibrary == null or not ContentLibrary.has_method("get_item"):
		return

	# Temporary dev helper so crafting/codex flows are testable from a fresh run.
	for item_id in TEMP_DEV_STARTER_KIT_ITEM_IDS:
		var item_data: Dictionary = ContentLibrary.get_item(item_id)
		if item_data.is_empty():
			continue
		if not run_state.inventory.add_item(item_data):
			push_warning("Failed to add temporary starter kit item: %s" % item_id)


func _show_indoor_mode(building_id: String) -> void:
	if _mode_host == null:
		push_error("RunController is missing the mode host.")
		return

	_current_building_id = building_id
	for child in _mode_host.get_children():
		child.queue_free()

	var indoor_mode := INDOOR_MODE_SCENE.instantiate()
	_mode_host.add_child(indoor_mode)

	if indoor_mode.has_signal("state_changed"):
		indoor_mode.state_changed.connect(Callable(self, "_on_indoor_state_changed"))
	if indoor_mode.has_signal("exit_requested"):
		indoor_mode.exit_requested.connect(Callable(self, "_on_indoor_exit_requested"))
	if indoor_mode.has_signal("toast_requested"):
		indoor_mode.toast_requested.connect(Callable(self, "_on_mode_toast_requested"))

	if indoor_mode.has_method("configure"):
		indoor_mode.configure(run_state, building_id)
	_current_mode_name = "indoor"


func _show_outdoor_mode(building_id: String, player_position = null) -> void:
	if _mode_host == null:
		push_error("RunController is missing the mode host.")
		return

	for child in _mode_host.get_children():
		child.queue_free()

	var outdoor_mode := OUTDOOR_MODE_SCENE.instantiate()
	_mode_host.add_child(outdoor_mode)

	if outdoor_mode.has_signal("state_changed"):
		outdoor_mode.state_changed.connect(Callable(self, "_on_mode_state_changed"))

	if outdoor_mode.has_signal("building_entered"):
		outdoor_mode.building_entered.connect(Callable(self, "_on_building_entered"))

	if outdoor_mode.has_method("bind_run_state"):
		outdoor_mode.bind_run_state(run_state, building_id, player_position)
	_return_outdoor_player_position = null
	_current_building_id = building_id
	_current_mode_name = "outdoor"


func _on_building_entered(building_id: String) -> void:
	_return_outdoor_player_position = _get_current_outdoor_player_position()
	await _transition_to_mode("indoor", building_id)


func _transition_to_mode(mode_name: String, building_id: String) -> void:
	if _transition_in_progress:
		return
	_transition_in_progress = true
	_close_shared_survival_sheet()
	_set_mode_host_processing_enabled(false)
	transition_started.emit(mode_name)

	if _transition_layer != null and _transition_layer.has_method("fade_out"):
		await _transition_layer.fade_out()

	if mode_name == "indoor":
		_show_indoor_mode(building_id)
	else:
		_show_outdoor_mode(building_id, _return_outdoor_player_position)

	if _hud_presenter != null and _hud_presenter.has_method("set_mode_presentation"):
		_hud_presenter.set_mode_presentation(mode_name)
	_refresh_hud()

	if _transition_layer != null and _transition_layer.has_method("fade_in"):
		await _transition_layer.fade_in()

	_transition_in_progress = false
	_set_mode_host_processing_enabled(true)
	transition_completed.emit(mode_name)


func _on_mode_state_changed() -> void:
	_refresh_hud()


func _on_indoor_state_changed() -> void:
	_refresh_hud()


func _on_indoor_exit_requested() -> void:
	await _transition_to_mode("outdoor", _current_building_id)


func _on_mode_toast_requested(toast_type: String, message: String, duration: float = 2.0, icon_item_id: String = "") -> void:
	_show_toast(toast_type, message, duration, icon_item_id)


func _get_current_outdoor_player_position():
	if _mode_host == null:
		return null

	var outdoor_mode := _mode_host.get_node_or_null("OutdoorMode")
	if outdoor_mode == null or not outdoor_mode.has_method("get_player_position"):
		return null

	return outdoor_mode.get_player_position()


func _refresh_hud() -> void:
	if _hud_presenter != null and _hud_presenter.has_method("refresh"):
		_hud_presenter.refresh()


func _on_crafting_applied(_outcome: Dictionary) -> void:
	_outdoor_inventory_feedback_message = _formatted_craft_feedback(_outcome)
	_show_toast(_craft_toast_type(_outcome), _outdoor_inventory_feedback_message, 2.0, _craft_toast_icon_item_id(_outcome))
	_refresh_hud()
	_refresh_current_mode_view()
	_refresh_outdoor_survival_sheet()


func _refresh_current_mode_view() -> void:
	if _mode_host == null or _mode_host.get_child_count() == 0:
		return

	var active_mode := _mode_host.get_child(0)
	if active_mode != null and active_mode.has_method("refresh_view"):
		active_mode.refresh_view()


func get_current_mode_name() -> String:
	return _current_mode_name


func is_transition_in_progress() -> bool:
	return _transition_in_progress


func _set_mode_host_processing_enabled(enabled: bool) -> void:
	if _mode_host == null:
		return

	var should_enable := enabled and not _shared_survival_sheet_open and not _transition_in_progress
	_mode_host.process_mode = Node.PROCESS_MODE_INHERIT if should_enable else Node.PROCESS_MODE_DISABLED


func _on_hud_bag_requested() -> void:
	if _transition_in_progress or _current_mode_name != "outdoor":
		return
	if _survival_sheet != null and _survival_sheet.visible:
		_survival_sheet.close_sheet()
		return
	_open_outdoor_survival_sheet("inventory")


func _on_hud_map_requested() -> void:
	if _transition_in_progress or _current_mode_name != "outdoor":
		return
	if _survival_sheet != null and _survival_sheet.visible:
		_survival_sheet.close_sheet()
	var outdoor_mode: Node = _current_outdoor_mode()
	if outdoor_mode == null:
		return
	if outdoor_mode.has_method("is_map_overlay_open") and outdoor_mode.is_map_overlay_open():
		outdoor_mode.hide_map_overlay()
	else:
		outdoor_mode.show_map_overlay()


func _open_outdoor_survival_sheet(tab_id: String = "inventory") -> void:
	if _survival_sheet == null or run_state == null:
		return
	_survival_sheet.bind_run_state(run_state)
	_survival_sheet.set_mode_name("outdoor")
	_refresh_outdoor_survival_sheet()
	if tab_id == "codex" and _survival_sheet.has_method("open_codex"):
		_survival_sheet.open_codex()
	else:
		_survival_sheet.open_inventory()
	_shared_survival_sheet_open = true
	_set_mode_host_processing_enabled(false)


func _close_shared_survival_sheet() -> void:
	if _survival_sheet != null and _survival_sheet.visible and _survival_sheet.has_method("close_sheet"):
		_survival_sheet.close_sheet()
	_shared_survival_sheet_open = false


func _on_survival_sheet_closed() -> void:
	_shared_survival_sheet_open = false
	if not _transition_in_progress:
		_set_mode_host_processing_enabled(true)


func _refresh_outdoor_survival_sheet() -> void:
	if _survival_sheet == null or _current_mode_name != "outdoor" or not _survival_sheet.has_method("set_inventory_payload"):
		return
	_survival_sheet.set_inventory_payload({
		"title": "가방",
		"status_text": "바깥에서 챙길 물건을 고른다.",
		"rows": [],
		"selected_sheet": {"visible": false},
		"feedback_message": _outdoor_inventory_feedback_message,
	})


func _on_survival_sheet_action_requested(action_id: String) -> void:
	if run_state == null or action_id.is_empty():
		return
	if action_id == "close_inventory_sheet":
		_close_shared_survival_sheet()
		return
	if action_id.begins_with("drop_inventory_"):
		var drop_item_id := action_id.trim_prefix("drop_inventory_")
		var dropped_item: Dictionary = run_state.inventory.take_first_item_by_id(drop_item_id)
		if dropped_item.is_empty():
			return
		_outdoor_inventory_feedback_message = "%s 버렸다." % _item_name(dropped_item, drop_item_id)
		_show_toast("info", _outdoor_inventory_feedback_message)
	elif action_id.begins_with("consume_inventory_"):
		var consume_item_id := action_id.trim_prefix("consume_inventory_")
		var consume_item_data: Dictionary = _item_definition(consume_item_id)
		if consume_item_data.is_empty():
			return
		var use_minutes := int(consume_item_data.get("use_minutes", 0))
		if use_minutes > 0:
			run_state.advance_minutes(use_minutes, "outdoor")
		var consumed := false
		if run_state.has_method("use_inventory_item"):
			consumed = bool(run_state.use_inventory_item(consume_item_id))
		elif run_state.has_method("consume_inventory_item"):
			consumed = bool(run_state.consume_inventory_item(consume_item_id, consume_item_data))
		if not consumed:
			return
		_outdoor_inventory_feedback_message = "%s %s." % [_item_name(consume_item_data, consume_item_id), _consume_feedback_verb(consume_item_data)]
		if use_minutes > 0:
			_outdoor_inventory_feedback_message += " %d분이 지났다." % use_minutes
		_show_toast("success", _outdoor_inventory_feedback_message)
	elif action_id.begins_with("read_inventory_"):
		var read_item_id := action_id.trim_prefix("read_inventory_")
		var read_item_data: Dictionary = _item_definition(read_item_id)
		if read_item_data.is_empty() or not bool(read_item_data.get("readable", false)) or not run_state.has_method("read_knowledge_item"):
			return
		var read_result := bool(run_state.read_knowledge_item(read_item_id))
		_outdoor_inventory_feedback_message = "%s에서 새로운 조합법을 익혔다." % _item_name(read_item_data, read_item_id) if read_result else "%s는 이미 아는 내용이다." % _item_name(read_item_data, read_item_id)
		_show_toast("success" if read_result else "info", _outdoor_inventory_feedback_message)
	elif action_id.begins_with("equip_inventory_"):
		var equip_item_id := action_id.trim_prefix("equip_inventory_")
		var equip_item_data: Dictionary = _item_definition(equip_item_id)
		if equip_item_data.is_empty() or not run_state.has_method("equip_inventory_item"):
			return
		var equip_result: Dictionary = run_state.equip_inventory_item(equip_item_id, equip_item_data)
		if not bool(equip_result.get("ok", false)):
			_outdoor_inventory_feedback_message = String(equip_result.get("message", "장착하지 못했다."))
			_show_toast("warning", _outdoor_inventory_feedback_message)
		else:
			var replaced_item: Dictionary = equip_result.get("replaced_item", {})
			_outdoor_inventory_feedback_message = "%s 장착했다." % _item_name(equip_item_data, equip_item_id) if replaced_item.is_empty() else "%s 장착했다. %s는 가방에 넣었다." % [_item_name(equip_item_data, equip_item_id), _item_name(replaced_item, String(replaced_item.get("id", "")))]
			_show_toast("success", _outdoor_inventory_feedback_message)
	else:
		return
	_refresh_hud()
	_refresh_current_mode_view()
	_refresh_outdoor_survival_sheet()


func _item_definition(item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}
	if run_state != null and run_state.inventory != null:
		var inventory_item: Dictionary = run_state.inventory.get_first_item_by_id(item_id)
		if not inventory_item.is_empty():
			var merged_item := inventory_item.duplicate(true)
			var content_item := ContentLibrary.get_item(item_id)
			if not content_item.is_empty():
				for key in merged_item.keys():
					content_item[key] = merged_item[key]
				return content_item
			return merged_item
	return ContentLibrary.get_item(item_id)


func _current_outdoor_mode() -> Node:
	if _mode_host == null or _mode_host.get_child_count() == 0:
		return null
	var active_mode := _mode_host.get_child(0)
	if active_mode == null or active_mode.name != "OutdoorMode":
		return null
	return active_mode


func _item_name(item_data: Dictionary, item_id: String) -> String:
	return String(item_data.get("name", item_id))


func _show_toast(toast_type: String, message: String, duration: float = 2.0, icon_item_id: String = "") -> void:
	if _toast_presenter != null and _toast_presenter.has_method("show_toast") and not message.is_empty():
		_toast_presenter.show_toast(toast_type, message, duration, icon_item_id)


func _craft_toast_type(outcome: Dictionary) -> String:
	match String(outcome.get("result_type", "invalid")):
		"success":
			return "success"
		"failure", "invalid":
			return "warning"
		_:
			return "info"


func _craft_toast_icon_item_id(outcome: Dictionary) -> String:
	return String(outcome.get("result_item_id", "")) if _craft_toast_type(outcome) == "success" else ""


func _consume_feedback_verb(item_data: Dictionary) -> String:
	var category := String(item_data.get("category", ""))
	if category == "drink":
		return "마셨다"
	if category == "medical" or category == "stimulant":
		return "사용했다"
	return "먹었다"


func _formatted_craft_feedback(outcome: Dictionary) -> String:
	var lines: Array[String] = []
	var result_item_data: Dictionary = outcome.get("result_item_data", {})
	var result_item_name := String(result_item_data.get("name", outcome.get("result_item_id", "")))
	if not result_item_name.is_empty():
		lines.append(result_item_name)
	var result_text := String(outcome.get("result_text", ""))
	if not result_text.is_empty():
		lines.append(result_text)
	var minutes_elapsed := int(outcome.get("minutes_elapsed", 0))
	if minutes_elapsed > 0:
		lines.append("%d분이 지났다." % minutes_elapsed)
	return "\n".join(lines)
