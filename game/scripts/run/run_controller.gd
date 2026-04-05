extends Node

signal transition_started(mode_name: String)
signal transition_completed(mode_name: String)

const OUTDOOR_MODE_SCENE := preload("res://scenes/outdoor/outdoor_mode.tscn")
const RUN_STATE_SCRIPT := preload("res://scripts/run/run_state.gd")
const INDOOR_MODE_SCENE := preload("res://scenes/indoor/indoor_mode.tscn")

var run_state = null
var _hud_presenter: Node = null
var _crafting_sheet: Node = null
var _transition_layer: Node = null
var _mode_host: Node = null
var _current_mode_name := ""
var _current_building_id := "mart_01"
var _return_outdoor_player_position = null
var _transition_in_progress := false
var _crafting_sheet_open := false
var _pending_crafting_open := false


func start_run(survivor_config: Dictionary, building_id: String = "mart_01") -> void:
	run_state = RUN_STATE_SCRIPT.from_survivor_config(survivor_config)
	if run_state == null:
		push_error("RunController could not create a run state.")
		return

	_hud_presenter = get_node_or_null("HUD")
	_crafting_sheet = get_node_or_null("CraftingSheet")
	_transition_layer = get_node_or_null("TransitionLayer")
	_mode_host = get_node_or_null("ModeHost")
	_current_building_id = building_id

	if _hud_presenter != null and _hud_presenter.has_method("set_run_state"):
		_hud_presenter.set_run_state(run_state)
	if _hud_presenter != null and _hud_presenter.has_method("set_mode_presentation"):
		_hud_presenter.set_mode_presentation("outdoor")
	if _crafting_sheet != null and _crafting_sheet.has_method("bind_run_state"):
		_crafting_sheet.bind_run_state(run_state)
	if _crafting_sheet != null and _crafting_sheet.has_signal("closed") and not _crafting_sheet.closed.is_connected(Callable(self, "_on_crafting_sheet_closed")):
		_crafting_sheet.closed.connect(Callable(self, "_on_crafting_sheet_closed"))
	if _crafting_sheet != null and _crafting_sheet.has_signal("craft_applied") and not _crafting_sheet.craft_applied.is_connected(Callable(self, "_on_crafting_applied")):
		_crafting_sheet.craft_applied.connect(Callable(self, "_on_crafting_applied"))

	_show_outdoor_mode(building_id)
	_refresh_hud()


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
	if indoor_mode.has_signal("craft_requested"):
		indoor_mode.craft_requested.connect(Callable(self, "_on_craft_requested"))

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
	if outdoor_mode.has_signal("craft_requested"):
		outdoor_mode.craft_requested.connect(Callable(self, "_on_craft_requested"))

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
	_close_crafting_sheet()
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
	if _pending_crafting_open:
		_pending_crafting_open = false
		_open_crafting_sheet()
	else:
		_set_mode_host_processing_enabled(true)
	transition_completed.emit(mode_name)


func _on_mode_state_changed() -> void:
	_refresh_hud()


func _on_indoor_state_changed() -> void:
	_refresh_hud()


func _on_indoor_exit_requested() -> void:
	await _transition_to_mode("outdoor", _current_building_id)


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


func _on_craft_requested() -> void:
	if _crafting_sheet == null or not _crafting_sheet.has_method("open_for_mode"):
		return
	if _transition_in_progress:
		_pending_crafting_open = true
		return

	_open_crafting_sheet()


func _on_crafting_sheet_closed() -> void:
	_crafting_sheet_open = false
	_pending_crafting_open = false
	if not _transition_in_progress:
		_set_mode_host_processing_enabled(true)


func _on_crafting_applied(_outcome: Dictionary) -> void:
	_refresh_hud()
	_refresh_current_mode_view()


func _close_crafting_sheet() -> void:
	if _crafting_sheet != null and bool(_crafting_sheet.visible) and _crafting_sheet.has_method("close_sheet"):
		_crafting_sheet.close_sheet()


func _refresh_current_mode_view() -> void:
	if _mode_host == null or _mode_host.get_child_count() == 0:
		return

	var active_mode := _mode_host.get_child(0)
	if active_mode != null and active_mode.has_method("refresh_view"):
		active_mode.refresh_view()


func _open_crafting_sheet() -> void:
	if _crafting_sheet == null or not _crafting_sheet.has_method("open_for_mode"):
		return

	_crafting_sheet_open = true
	_crafting_sheet.open_for_mode(_current_mode_name)
	_set_mode_host_processing_enabled(false)


func get_current_mode_name() -> String:
	return _current_mode_name


func is_transition_in_progress() -> bool:
	return _transition_in_progress


func _set_mode_host_processing_enabled(enabled: bool) -> void:
	if _mode_host == null:
		return

	var should_enable := enabled and not _crafting_sheet_open and not _transition_in_progress
	_mode_host.process_mode = Node.PROCESS_MODE_INHERIT if should_enable else Node.PROCESS_MODE_DISABLED
