extends Node

signal state_changed

const ACTION_RESOLVER_SCRIPT := preload("res://scripts/indoor/indoor_action_resolver.gd")

var _resolver := ACTION_RESOLVER_SCRIPT.new()
var _run_state = null
var _building_data: Dictionary = {}
var _event_data: Dictionary = {}
var _event_state: Dictionary = _create_initial_event_state()


func configure(run_state, building_id: String) -> void:
	_run_state = run_state
	_building_data = _get_building_data(building_id)
	if _building_data.is_empty():
		_event_data = {}
		_event_state = _create_initial_event_state()
		state_changed.emit()
		return

	_event_data = _resolver.load_event(String(_building_data.get("indoor_event_path", "")))
	_event_state = _create_initial_event_state(_resolver.get_entry_zone_id(_event_data))
	state_changed.emit()


func get_event_title() -> String:
	if not _event_data.is_empty():
		return String(_event_data.get("name", _building_data.get("name", "Indoor")))

	return String(_building_data.get("name", "Indoor"))


func get_event_summary() -> String:
	return String(_event_data.get("summary", ""))


func get_current_zone_id() -> String:
	return String(_event_state.get("current_zone_id", ""))


func get_current_zone_label() -> String:
	var current_zone_id := get_current_zone_id()
	if current_zone_id.is_empty() or _event_data.is_empty():
		return ""

	var current_zone := _resolver.get_zone(_event_data, current_zone_id)
	if current_zone.is_empty():
		return current_zone_id

	var zone_label := String(current_zone.get("label", ""))
	if not zone_label.is_empty():
		return zone_label

	return current_zone_id


func get_current_zone_summary() -> String:
	var current_zone_id := get_current_zone_id()
	if current_zone_id.is_empty() or _event_data.is_empty():
		return get_event_summary()

	var current_zone := _resolver.get_zone(_event_data, current_zone_id)
	if current_zone.is_empty():
		return get_event_summary()

	var zone_summary := String(current_zone.get("summary", ""))
	if not zone_summary.is_empty():
		return zone_summary

	return get_event_summary()


func get_actions() -> Array[Dictionary]:
	var actions := _format_action_labels(_resolver.get_actions(_event_data, _event_state, _run_state))
	if _is_at_entry_zone():
		actions.append({
			"id": "exit_building",
			"label": "건물 밖으로 나간다",
			"type": "exit",
		})

	return actions


func get_clock_label() -> String:
	if _run_state == null or _run_state.clock == null or not _run_state.clock.has_method("get_clock_label"):
		return ""

	return String(_run_state.clock.get_clock_label())


func get_sleep_preview() -> Dictionary:
	return _resolver.get_sleep_preview(_run_state)


func get_feedback_message() -> String:
	return String(_event_state.get("last_feedback_message", ""))


func get_inventory_entries() -> Array[String]:
	if _run_state == null or _run_state.inventory == null:
		return ["소지품 없음"]

	var counts := {}
	var order: Array[String] = []
	for item_variant in _run_state.inventory.items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue

		var item := item_variant as Dictionary
		var label := String(item.get("name", item.get("id", "아이템")))
		if not counts.has(label):
			counts[label] = 0
			order.append(label)
		counts[label] = int(counts[label]) + 1

	if order.is_empty():
		return ["소지품 없음"]

	var entries: Array[String] = []
	for label in order:
		entries.append("%s x%d" % [label, int(counts[label])])
	return entries


func get_inventory_title() -> String:
	if _run_state == null or _run_state.inventory == null:
		return "소지품 (0/0)"

	return "소지품 (%d/%d)" % [_run_state.inventory.total_bulk(), _run_state.inventory.carry_limit]


func get_inventory_rows() -> Array[Dictionary]:
	if _run_state == null or _run_state.inventory == null:
		return [{"label": "소지품 없음", "drop_action_id": ""}]

	var rows: Array[Dictionary] = []
	var counts := {}
	var names := {}
	var order: Array[String] = []
	for item_variant in _run_state.inventory.items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue

		var item := item_variant as Dictionary
		var item_id := String(item.get("id", ""))
		if item_id.is_empty():
			continue
		if not counts.has(item_id):
			counts[item_id] = 0
			names[item_id] = String(item.get("name", item_id))
			order.append(item_id)
		counts[item_id] = int(counts[item_id]) + 1

	if order.is_empty():
		return [{"label": "소지품 없음", "drop_action_id": ""}]

	for item_id in order:
		rows.append({
			"label": "%s x%d" % [String(names.get(item_id, item_id)), int(counts[item_id])],
			"drop_action_id": "drop_%s" % item_id,
		})

	return rows


func get_map_snapshot() -> Dictionary:
	var current_zone_id := get_current_zone_id()
	if current_zone_id.is_empty() or _event_data.is_empty():
		return {"nodes": [], "edges": []}

	var visible_zone_ids: Array[String] = []
	var visited_zone_ids := _string_ids(_event_state.get("visited_zone_ids", []))
	for visited_zone_id in visited_zone_ids:
		_append_unique(visible_zone_ids, visited_zone_id)

	_append_unique(visible_zone_ids, current_zone_id)

	var current_zone := _resolver.get_zone(_event_data, current_zone_id)
	for connected_zone_id_variant in current_zone.get("connected_zone_ids", []):
		_append_unique(visible_zone_ids, String(connected_zone_id_variant))

	var nodes: Array[Dictionary] = []
	var current_floor_id := String(current_zone.get("floor_id", ""))
	for zone_id in visible_zone_ids:
		var zone := _resolver.get_zone(_event_data, zone_id)
		if zone.is_empty():
			continue

		var state := "visited"
		if zone_id == current_zone_id:
			state = "current"
		elif not visited_zone_ids.has(zone_id):
			state = "adjacent_unknown" if _resolver.is_zone_accessible(_event_data, _event_state, zone_id, _run_state) else "locked"

		nodes.append({
			"id": zone_id,
			"label": _map_label_for_zone(zone, state),
			"state": state,
			"floor_id": String(zone.get("floor_id", "")),
			"map_position": zone.get("map_position", [0, 0]),
		})

	var visibility_lookup := {}
	for zone_id in visible_zone_ids:
		visibility_lookup[zone_id] = true

	var seen_edges := {}
	var edges: Array[Dictionary] = []
	for traversed_edge_id in _string_ids(_event_state.get("traversed_edge_ids", [])):
		var edge_parts := traversed_edge_id.split("|")
		if edge_parts.size() != 2:
			continue

		var from_id := String(edge_parts[0])
		var to_id := String(edge_parts[1])
		if not visibility_lookup.has(from_id) or not visibility_lookup.has(to_id):
			continue
		if seen_edges.has(traversed_edge_id):
			continue
		seen_edges[traversed_edge_id] = true
		edges.append({
			"from": from_id,
			"to": to_id,
			"locked": false,
		})

	var current_zone_connections: Array = current_zone.get("connected_zone_ids", [])
	for connected_zone_id_variant in current_zone_connections:
		var connected_zone_id := String(connected_zone_id_variant)
		if not visibility_lookup.has(connected_zone_id):
			continue

		var edge_key := _sorted_edge_id(current_zone_id, connected_zone_id)
		if seen_edges.has(edge_key):
			continue
		seen_edges[edge_key] = true
		edges.append({
			"from": current_zone_id,
			"to": connected_zone_id,
			"locked": not _resolver.is_zone_accessible(_event_data, _event_state, connected_zone_id, _run_state),
		})

	return {
		"current_zone_id": current_zone_id,
		"current_floor_id": current_floor_id,
		"nodes": nodes,
		"edges": edges,
	}


func apply_action(action_id: String) -> bool:
	if action_id.begins_with("drop_"):
		var item_id := action_id.trim_prefix("drop_")
		if _run_state == null or _run_state.inventory == null:
			return false
		if not _run_state.inventory.remove_first_item_by_id(item_id):
			return false
		_event_state["last_feedback_message"] = "%s 버렸다." % _inventory_item_name(item_id)
		state_changed.emit()
		return true

	if action_id == "exit_building":
		return true

	if not _resolver.apply_action(_run_state, _event_data, _event_state, action_id):
		return false

	state_changed.emit()
	return true


func _get_building_data(building_id: String) -> Dictionary:
	if not ContentLibrary.has_method("get_building"):
		push_error("ContentLibrary autoload is missing get_building(building_id).")
		return {}

	return ContentLibrary.get_building(building_id)


func _create_initial_event_state(current_zone_id: String = "") -> Dictionary:
	var visited_zone_ids := PackedStringArray()
	if not current_zone_id.is_empty():
		visited_zone_ids.append(current_zone_id)

	return {
		"current_zone_id": current_zone_id,
		"visited_zone_ids": visited_zone_ids,
		"traversed_edge_ids": PackedStringArray(),
		"zone_found_loot": {},
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"zone_flags": {},
		"noise": 0,
	}


func _is_at_entry_zone() -> bool:
	return get_current_zone_id() == _resolver.get_entry_zone_id(_event_data)


func _format_action_labels(actions: Array[Dictionary]) -> Array[Dictionary]:
	var formatted_actions: Array[Dictionary] = []
	for action in actions:
		var formatted := action.duplicate(true)
		formatted["label"] = _format_action_label(formatted)
		formatted_actions.append(formatted)
	return formatted_actions


func _format_action_label(action: Dictionary) -> String:
	var base_label := String(action.get("label", action.get("id", "")))
	if bool(action.get("locked", false)):
		return "%s (잠김)" % base_label

	var time_cost_minutes := int(action.get("minute_cost", action.get("sleep_minutes", 0)))
	if time_cost_minutes <= 0:
		return base_label

	return "%s (%d분)" % [base_label, time_cost_minutes]


func _append_unique(target: Array[String], value: String) -> void:
	if value.is_empty() or target.has(value):
		return
	target.append(value)


func _string_ids(values) -> Array[String]:
	var ids: Array[String] = []
	for value in values:
		ids.append(String(value))
	return ids


func _inventory_item_name(item_id: String) -> String:
	if _run_state == null or _run_state.inventory == null:
		return item_id

	for item_variant in _run_state.inventory.items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item := item_variant as Dictionary
		if String(item.get("id", "")) == item_id:
			return String(item.get("name", item_id))

	return item_id


func _sorted_edge_id(from_zone_id: String, to_zone_id: String) -> String:
	if from_zone_id.is_empty() or to_zone_id.is_empty():
		return ""
	return "%s|%s" % [from_zone_id, to_zone_id] if from_zone_id < to_zone_id else "%s|%s" % [to_zone_id, from_zone_id]


func _map_label_for_zone(zone: Dictionary, state: String) -> String:
	match state:
		"current", "visited":
			return String(zone.get("label", zone.get("id", "?")))
		"locked":
			return "잠김"
		_:
			return "?"
