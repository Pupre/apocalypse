extends Node

signal state_changed

const ACTION_RESOLVER_SCRIPT := preload("res://scripts/indoor/indoor_action_resolver.gd")
var _resolver := ACTION_RESOLVER_SCRIPT.new()
var _run_state = null
var _building_data: Dictionary = {}
var _event_data: Dictionary = {}
var _event_state: Dictionary = _create_initial_event_state()
var _selected_inventory_item_id := ""


func configure(run_state, building_id: String) -> void:
	_run_state = run_state
	_building_data = _get_building_data(building_id)
	_selected_inventory_item_id = ""
	if _building_data.is_empty():
		_event_data = {}
		_event_state = _create_initial_event_state()
		state_changed.emit()
		return

	_event_data = _resolver.load_event(String(_building_data.get("indoor_event_path", "")))
	var entry_zone_id := _resolver.get_entry_zone_id(_event_data)
	if _run_state != null and _run_state.has_method("get_or_create_site_memory"):
		_run_state.enter_indoor_site(building_id, entry_zone_id)
		var site_memory: Dictionary = _run_state.get_or_create_site_memory(building_id, entry_zone_id)
		_event_state = site_memory
		_event_state["current_zone_id"] = entry_zone_id
	else:
		_event_state = _create_initial_event_state(entry_zone_id)
	_event_state.erase("last_illustration_asset")
	_event_state.erase("pending_story_cutscene")
	state_changed.emit()


func get_event_title() -> String:
	if not _event_data.is_empty():
		return String(_event_data.get("name", _building_data.get("name", "Indoor")))

	return String(_building_data.get("name", "Indoor"))


func get_event_summary() -> String:
	return String(_event_data.get("summary", ""))


func get_event_illustration_asset() -> String:
	var result_asset := String(_event_state.get("last_illustration_asset", ""))
	if not result_asset.is_empty():
		return result_asset

	var event_asset := String(_event_data.get("illustration_asset", ""))
	if not event_asset.is_empty():
		return event_asset

	var building_asset := String(_building_data.get("illustration_asset", ""))
	if not building_asset.is_empty():
		return building_asset

	var building_id := String(_building_data.get("id", ""))
	match building_id:
		"clinic_01", "pharmacy_01":
			return "indoor/indoor_event_medical_clinic.png"
		"apartment_01", "residence_01", "hostel_01", "row_house_01":
			return "indoor/indoor_event_residential_stairwell.png"
		"hardware_01", "warehouse_01", "storage_depot_01", "garage_01", "repair_shop_01", "gas_station_01":
			return "indoor/indoor_event_industrial_garage.png"
		"office_01":
			return "indoor/indoor_event_office_records.png"
		"police_box_01", "school_gate_01":
			return "indoor/indoor_event_security_station.png"
		"bookstore_01":
			return "indoor/indoor_event_bookstore_frozen.png"
		"church_01", "chapel_01":
			return "indoor/indoor_event_civic_shelter.png"

	match String(_building_data.get("category", "")):
		"medical":
			return "indoor/indoor_event_medical_clinic.png"
		"residential":
			return "indoor/indoor_event_residential_stairwell.png"
		"industrial":
			return "indoor/indoor_event_industrial_garage.png"
		"food_service":
			return "indoor/indoor_event_food_kitchen.png"
		"security":
			return "indoor/indoor_event_security_station.png"
		"office":
			return "indoor/indoor_event_office_records.png"
		_:
			return "indoor/indoor_event_convenience_frozen.png"


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


func get_current_zone_status_rows() -> Array[String]:
	var rows: Array[String] = []
	var zone_id := get_current_zone_id()
	if zone_id.is_empty():
		return rows

	var memory := _current_site_memory()
	var zone_loot := _zone_loot_for_zone(memory, zone_id)
	rows.append("남아 있는 물건 %d개" % zone_loot.size())
	var deployments := _deployments_for_zone(memory, zone_id)
	rows.append("설치물 %d개" % deployments.size())
	var noise := int(_event_state.get("noise", memory.get("noise", 0)))
	if noise > 0:
		rows.append("소란 %d" % noise)
	if _run_state != null and _run_state.has_method("get_current_heat_recovery_context"):
		var heat_context: Dictionary = _run_state.get_current_heat_recovery_context()
		rows.append(String(heat_context.get("status_text", "")))
	if _zone_search_completed(zone_id):
		rows.append("수색 완료")
	return rows


func get_actions() -> Array[Dictionary]:
	var actions := _resolver.get_actions(_event_data, _event_state, _run_state)
	var exit_action := _exit_building_action()
	if not exit_action.is_empty():
		actions.append(exit_action)

	return _format_action_labels(actions)


func get_exit_action() -> Dictionary:
	var exit_action := _exit_building_action()
	if exit_action.is_empty():
		return {}
	var formatted := exit_action.duplicate(true)
	formatted["label"] = _format_action_label(formatted)
	return formatted


func get_supply_picker_payload(action_id: String) -> Dictionary:
	if action_id.is_empty():
		return {"visible": false}

	for action in _resolver.get_actions(_event_data, _event_state, _run_state):
		if String(action.get("id", "")) != action_id:
			continue
		if String(action.get("type", "")) != "take_supply_detail":
			continue
		var max_quantity := int(action.get("max_quantity", 0))
		return {
			"visible": true,
			"action_id": action_id,
			"zone_id": String(action.get("zone_id", "")),
			"source_id": String(action.get("source_id", "")),
			"item_id": String(action.get("item_id", "")),
			"item_name": String(action.get("item_name", "")),
			"quantity_remaining": int(action.get("quantity_remaining", 0)),
			"max_quantity": max_quantity,
			"selected_quantity": 1 if max_quantity > 0 else 0,
		}

	return {"visible": false}


func apply_supply_pickup(zone_id: String, source_id: String, quantity: int) -> bool:
	if _run_state == null:
		return false
	if not _resolver.apply_supply_pickup(_run_state, _event_state, zone_id, source_id, quantity):
		return false
	state_changed.emit()
	return true


func get_clock_label() -> String:
	if _run_state == null or _run_state.clock == null or not _run_state.clock.has_method("get_clock_label"):
		return ""

	return String(_run_state.clock.get_clock_label())


func get_sleep_preview() -> Dictionary:
	return _resolver.get_sleep_preview(_run_state)


func get_feedback_message() -> String:
	return String(_event_state.get("last_feedback_message", ""))


func consume_story_cutscene_payload() -> Dictionary:
	var payload_variant: Variant = _event_state.get("pending_story_cutscene", {})
	if typeof(payload_variant) != TYPE_DICTIONARY:
		return {}

	var payload := (payload_variant as Dictionary).duplicate(true)
	_event_state.erase("pending_story_cutscene")
	return payload


func get_inventory_entries() -> Array[String]:
	var entries: Array[String] = []
	for row in get_inventory_rows():
		entries.append(String(row.get("label", "")))
	return entries


func get_inventory_title() -> String:
	if _run_state == null or _run_state.inventory == null:
		return "소지품 (0.0/0.0kg)"

	var summary: Dictionary = _run_state.get_carry_weight_summary() if _run_state.has_method("get_carry_weight_summary") else {}
	return "소지품 (%.1f/%.1fkg)" % [
		float(summary.get("total_weight", 0.0)),
		float(summary.get("carry_capacity", 0.0))
	]


func get_inventory_status_text() -> String:
	if _run_state == null or _run_state.inventory == null:
		return ""

	var state_label: String = _run_state.get_carry_state_label() if _run_state.has_method("get_carry_state_label") else "적정"
	var summary: Dictionary = _run_state.get_carry_weight_summary() if _run_state.has_method("get_carry_weight_summary") else {}
	var weight_text := "%.1f/%.1fkg" % [
		float(summary.get("total_weight", 0.0)),
		float(summary.get("carry_capacity", 0.0))
	]
	if not _run_state.has_method("get_outdoor_move_speed") or _run_state.move_speed <= 0.0:
		return "가방 %s · %s" % [state_label, weight_text]

	var speed_ratio := float(_run_state.get_outdoor_move_speed()) / float(_run_state.move_speed)
	return "가방 %s · %s · 야외 속도 %d%%" % [state_label, weight_text, int(round(speed_ratio * 100.0))]


func get_inventory_rows() -> Array[Dictionary]:
	if _run_state == null or _run_state.inventory == null:
		return []

	var rows: Array[Dictionary] = []
	var counts := {}
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
			order.append(item_id)
		counts[item_id] = int(counts[item_id]) + 1

	if order.is_empty():
		return []

	for item_id in order:
		var item_data := _item_definition(item_id)
		var item_weight := float(item_data.get("carry_weight", item_data.get("bulk", 1)))
		var total_weight := item_weight * float(counts[item_id])
		rows.append({
			"kind": "carried",
			"item_id": item_id,
			"count": int(counts[item_id]),
			"label": "%s x%d · %.1fkg" % [_item_name(item_data, item_id), int(counts[item_id]), total_weight],
			"tag_texts": _item_tags(item_data),
			"charges_text": _item_charges_text(item_id, item_data),
			"action_id": "inspect_inventory_%s" % item_id,
			"detail_text": "",
		})

	return rows


func get_equipped_rows() -> Array[Dictionary]:
	if _run_state == null:
		var empty_rows: Array[Dictionary] = [{
			"kind": "empty",
			"summary_text": "장착 장비 없음",
			"state_text": "",
			"detail_text": "",
		}]
		return empty_rows

	var slot_order := ["back", "body", "neck", "face", "feet", "feet_layer", "hands", "hands_layer"]
	var rows: Array[Dictionary] = []
	for slot_id in slot_order:
		var equipped_item: Dictionary = _run_state.equipped_items.get(slot_id, {})
		if equipped_item.is_empty():
			continue
		rows.append({
			"kind": "equipped",
			"item_id": String(equipped_item.get("id", "")),
			"slot_id": slot_id,
			"slot_label": _slot_label(slot_id),
			"item_name": _item_name(equipped_item, slot_id),
			"summary_text": _slot_label(slot_id),
			"state_text": "",
			"detail_text": _item_effect_text(equipped_item),
		})

	if rows.is_empty():
		var fallback_rows: Array[Dictionary] = [{
			"kind": "empty",
			"summary_text": "장착 장비 없음",
			"state_text": "",
			"detail_text": "",
		}]
		return fallback_rows
	return rows


func get_selected_inventory_sheet() -> Dictionary:
	if _selected_inventory_item_id.is_empty() or not _inventory_has_item(_selected_inventory_item_id):
		return {"visible": false}

	var item_data := _item_definition(_selected_inventory_item_id)
	if item_data.is_empty():
		return {"visible": false}

	return {
		"visible": true,
		"title": _item_name(item_data, _selected_inventory_item_id),
		"description": String(item_data.get("description", "")),
		"usage_hint": String(item_data.get("usage_hint", "")),
		"cold_hint": String(item_data.get("cold_hint", "")),
		"item_tags": item_data.get("item_tags", []),
		"effect_text": _item_sheet_effect_text(item_data),
		"actions": _inventory_sheet_actions(item_data, _selected_inventory_item_id),
	}


func set_feedback_message(message: String) -> void:
	_event_state["last_feedback_message"] = message
	state_changed.emit()


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
	if action_id.begins_with("inspect_inventory_"):
		var inspect_item_id := action_id.trim_prefix("inspect_inventory_")
		if not _inventory_has_item(inspect_item_id):
			return false
		_selected_inventory_item_id = inspect_item_id
		state_changed.emit()
		return true

	if action_id == "close_inventory_sheet":
		_selected_inventory_item_id = ""
		state_changed.emit()
		return true

	if action_id.begins_with("drop_inventory_"):
		var drop_item_id := action_id.trim_prefix("drop_inventory_")
		if _run_state == null or _run_state.inventory == null:
			return false
		var dropped_item: Dictionary = _run_state.inventory.take_first_item_by_id(drop_item_id)
		if dropped_item.is_empty():
			return false
		if _run_state.has_method("drop_item_in_current_zone_data"):
			_run_state.drop_item_in_current_zone_data(dropped_item)
		_selected_inventory_item_id = ""
		_event_state["last_feedback_message"] = "%s 내려놓았다." % _item_name(dropped_item, drop_item_id)
		state_changed.emit()
		return true

	if action_id.begins_with("consume_inventory_"):
		var consume_item_id := action_id.trim_prefix("consume_inventory_")
		var consume_item_data: Dictionary = _item_definition(consume_item_id)
		if consume_item_data.is_empty() or _run_state == null:
			return false
		var use_minutes := int(consume_item_data.get("use_minutes", 0))
		if use_minutes > 0 and _run_state.has_method("get_indoor_action_minutes"):
			use_minutes = int(_run_state.get_indoor_action_minutes(use_minutes))
		if use_minutes > 0 and _run_state.has_method("advance_minutes"):
			_run_state.advance_minutes(use_minutes)
		var consumed := false
		if _run_state.has_method("use_inventory_item"):
			consumed = bool(_run_state.use_inventory_item(consume_item_id))
		elif _run_state.has_method("consume_inventory_item"):
			consumed = bool(_run_state.consume_inventory_item(consume_item_id, consume_item_data))
		if not consumed:
			return false
		_selected_inventory_item_id = ""
		_event_state["last_feedback_message"] = "%s %s." % [
			_item_name(consume_item_data, consume_item_id),
			_consume_feedback_verb(consume_item_data),
		]
		if use_minutes > 0:
			_event_state["last_feedback_message"] += " %d분이 지났다." % use_minutes
		state_changed.emit()
		return true

	if action_id.begins_with("read_inventory_"):
		var read_item_id := action_id.trim_prefix("read_inventory_")
		var read_item_data: Dictionary = _item_definition(read_item_id)
		if read_item_data.is_empty() or not bool(read_item_data.get("readable", false)) or _run_state == null or not _run_state.has_method("read_knowledge_item"):
			return false
		var read_result := bool(_run_state.read_knowledge_item(read_item_id))
		_event_state["last_feedback_message"] = "%s에서 새로운 조합법을 익혔다." % _item_name(read_item_data, read_item_id) if read_result else "%s는 이미 아는 내용이다." % _item_name(read_item_data, read_item_id)
		state_changed.emit()
		return true

	if action_id.begins_with("equip_inventory_"):
		var equip_item_id := action_id.trim_prefix("equip_inventory_")
		var equip_item_data: Dictionary = _item_definition(equip_item_id)
		if equip_item_data.is_empty() or _run_state == null or not _run_state.has_method("equip_inventory_item"):
			return false
		var equip_result: Dictionary = _run_state.equip_inventory_item(equip_item_id, equip_item_data)
		if not bool(equip_result.get("ok", false)):
			_event_state["last_feedback_message"] = String(equip_result.get("message", "장착하지 못했다."))
			state_changed.emit()
			return true
		_selected_inventory_item_id = ""
		var replaced_item: Dictionary = equip_result.get("replaced_item", {})
		if replaced_item.is_empty():
			_event_state["last_feedback_message"] = "%s 장착했다." % _item_name(equip_item_data, equip_item_id)
		else:
			_event_state["last_feedback_message"] = "%s 장착했다. %s는 가방에 넣었다." % [
				_item_name(equip_item_data, equip_item_id),
				_item_name(replaced_item, String(replaced_item.get("id", "")))
			]
		state_changed.emit()
		return true

	if action_id == "exit_building":
		var exit_action := _exit_building_action()
		var minute_cost := int(exit_action.get("minute_cost", 0))
		if minute_cost > 0 and _run_state != null and _run_state.has_method("advance_minutes"):
			_run_state.advance_minutes(minute_cost)
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
		"zone_loot_entries": {},
		"zone_supply_sources": {},
		"next_loot_uid": 0,
		"revealed_clue_ids": PackedStringArray(),
		"spent_action_ids": PackedStringArray(),
		"spent_pressure_ids": PackedStringArray(),
		"resolved_noise_threshold_ids": PackedStringArray(),
		"zone_flags": {},
		"last_pressure_message": "",
		"last_noise_message": "",
		"last_illustration_asset": "",
		"pending_story_cutscene": {},
		"noise": 0,
	}


func _is_at_entry_zone() -> bool:
	return get_current_zone_id() == _resolver.get_entry_zone_id(_event_data)


func _format_action_labels(actions: Array[Dictionary]) -> Array[Dictionary]:
	var formatted_actions: Array[Dictionary] = []
	for action in actions:
		var formatted := action.duplicate(true)
		formatted["label"] = _format_action_label(formatted)
		var detail_label := _format_action_detail_label(action)
		if not detail_label.is_empty():
			formatted["detail_label"] = detail_label
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


func _format_action_detail_label(action: Dictionary) -> String:
	var parts: Array[String] = []

	var requirements: Dictionary = {}
	var requirements_variant: Variant = action.get("requirements", {})
	if typeof(requirements_variant) == TYPE_DICTIONARY:
		requirements = requirements_variant as Dictionary

	var required_item_ids := _string_ids(requirements.get("required_item_ids", []))
	if not required_item_ids.is_empty():
		parts.append("필요: %s" % _item_names(required_item_ids))

	var consume_item_ids := _string_ids(action.get("consume_item_ids", []))
	if not consume_item_ids.is_empty():
		parts.append("소모: %s" % _item_names(consume_item_ids))

	var pressure: Dictionary = {}
	var pressure_variant: Variant = action.get("pressure", {})
	if typeof(pressure_variant) == TYPE_DICTIONARY:
		pressure = pressure_variant as Dictionary

	var total_noise := int(action.get("noise_cost", 0)) + int(pressure.get("noise", 0))
	if total_noise > 0:
		parts.append("소란 +%d" % total_noise)

	var health_loss := float(pressure.get("health_loss", 0.0))
	if health_loss > 0.0:
		parts.append("체력 -%s" % _compact_number(health_loss))

	var exposure_loss := float(pressure.get("exposure_loss", 0.0))
	if exposure_loss > 0.0:
		parts.append("체온 손실 %s" % _compact_number(exposure_loss))

	var fatigue_gain := float(pressure.get("fatigue_gain", 0.0))
	if fatigue_gain > 0.0:
		parts.append("피로 +%s" % _compact_number(fatigue_gain))

	return " · ".join(parts)


func _item_names(item_ids: Array[String]) -> String:
	var names: Array[String] = []
	for item_id in item_ids:
		names.append(_inventory_item_name(item_id))
	return ", ".join(names)


func _compact_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.1f" % value


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
	return _item_name(_item_definition(item_id), item_id)


func _inventory_has_item(item_id: String) -> bool:
	if _run_state == null or _run_state.inventory == null:
		return false

	for item_variant in _run_state.inventory.items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		if String((item_variant as Dictionary).get("id", "")) == item_id:
			return true
	return false


func _exit_building_action() -> Dictionary:
	if _event_data.is_empty():
		return {}
	var entry_zone_id := _resolver.get_entry_zone_id(_event_data)
	if entry_zone_id.is_empty():
		return {}

	var minute_cost := _shortest_exit_minutes(get_current_zone_id(), entry_zone_id)
	if minute_cost < 0:
		return {}

	var action := {
		"id": "exit_building",
		"label": "건물 밖으로 나간다",
		"type": "exit",
	}
	if minute_cost > 0:
		action["minute_cost"] = minute_cost
	return action


func _shortest_exit_minutes(start_zone_id: String, target_zone_id: String) -> int:
	if start_zone_id.is_empty() or target_zone_id.is_empty():
		return -1
	if start_zone_id == target_zone_id:
		return 0

	var visited_zone_ids := _string_ids(_event_state.get("visited_zone_ids", []))
	var distances := {start_zone_id: 0}
	var frontier: Array[Dictionary] = [{"zone_id": start_zone_id, "cost": 0}]
	var settled := {}

	while not frontier.is_empty():
		var best_index := 0
		var best_cost := int(frontier[0].get("cost", 0))
		for index in range(1, frontier.size()):
			var candidate_cost := int(frontier[index].get("cost", 0))
			if candidate_cost < best_cost:
				best_index = index
				best_cost = candidate_cost
		var current := frontier[best_index]
		frontier.remove_at(best_index)

		var zone_id := String(current.get("zone_id", ""))
		if zone_id.is_empty() or settled.has(zone_id):
			continue
		settled[zone_id] = true
		if zone_id == target_zone_id:
			return best_cost

		var zone := _resolver.get_zone(_event_data, zone_id)
		if zone.is_empty():
			continue

		for neighbor_variant in zone.get("connected_zone_ids", []):
			var neighbor_zone_id := String(neighbor_variant)
			if neighbor_zone_id.is_empty():
				continue
			if not visited_zone_ids.has(neighbor_zone_id) and neighbor_zone_id != target_zone_id:
				continue
			if not _resolver.is_zone_accessible(_event_data, _event_state, neighbor_zone_id, _run_state):
				continue

			var step_cost := _move_minutes_to_zone(neighbor_zone_id, visited_zone_ids)
			var total_cost := best_cost + step_cost
			if total_cost < int(distances.get(neighbor_zone_id, 1_000_000)):
				distances[neighbor_zone_id] = total_cost
				frontier.append({
					"zone_id": neighbor_zone_id,
					"cost": total_cost,
				})

	return -1


func _move_minutes_to_zone(target_zone_id: String, visited_zone_ids: Array[String]) -> int:
	var target_zone := _resolver.get_zone(_event_data, target_zone_id)
	if target_zone.is_empty():
		return 0
	var minute_cost := int(target_zone.get("revisit_cost", 10)) if visited_zone_ids.has(target_zone_id) else int(target_zone.get("first_visit_cost", 30))
	if _run_state != null and _run_state.has_method("get_indoor_action_minutes"):
		minute_cost = int(_run_state.get_indoor_action_minutes(minute_cost))
	return minute_cost


func _current_site_memory() -> Dictionary:
	if _building_data.is_empty():
		return _event_state
	if _run_state != null and _run_state.has_method("get_or_create_site_memory"):
		return _run_state.get_or_create_site_memory(String(_building_data.get("id", "")), _resolver.get_entry_zone_id(_event_data))
	return _event_state


func _zone_loot_for_zone(memory: Dictionary, zone_id: String) -> Array[Dictionary]:
	if zone_id.is_empty():
		return []
	var zone_loot_variant: Variant = memory.get("zone_loot_entries", {})
	if typeof(zone_loot_variant) != TYPE_DICTIONARY:
		return []
	return _dictionary_loot_array((zone_loot_variant as Dictionary).get(zone_id, []))


func _deployments_for_zone(memory: Dictionary, zone_id: String) -> Array[Dictionary]:
	var deployments_variant: Variant = memory.get("installed_deployments", [])
	if typeof(deployments_variant) != TYPE_ARRAY:
		return []
	var deployments: Array[Dictionary] = []
	for deployment_variant in deployments_variant:
		if typeof(deployment_variant) != TYPE_DICTIONARY:
			continue
		var deployment := deployment_variant as Dictionary
		if String(deployment.get("zone_id", "")) != zone_id:
			continue
		deployments.append(deployment.duplicate(true))
	return deployments


func _zone_search_completed(zone_id: String) -> bool:
	if zone_id.is_empty():
		return false
	var spent_action_ids := _string_ids(_event_state.get("spent_action_ids", []))
	for event_variant in _event_data.get("events", []):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event := event_variant as Dictionary
		if String(event.get("zone_id", "")) != zone_id:
			continue
		for option_variant in event.get("options", []):
			if typeof(option_variant) != TYPE_DICTIONARY:
				continue
			var option := option_variant as Dictionary
			var action_id := String(option.get("id", ""))
			if action_id.begins_with("search_") and spent_action_ids.has(action_id):
				return true
	return false


func _dictionary_loot_array(values) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		if typeof(value) == TYPE_DICTIONARY:
			result.append((value as Dictionary).duplicate(true))
	return result


func _item_definition(item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}

	if _run_state != null and _run_state.inventory != null:
		for item_variant in _run_state.inventory.items:
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			var item := item_variant as Dictionary
			if String(item.get("id", "")) == item_id:
				var merged_item := item.duplicate(true)
				if ContentLibrary != null and ContentLibrary.has_method("get_item"):
					var item_data: Variant = ContentLibrary.get_item(item_id)
					if typeof(item_data) == TYPE_DICTIONARY and not (item_data as Dictionary).is_empty():
						var content_item := (item_data as Dictionary).duplicate(true)
						for key in merged_item.keys():
							content_item[key] = merged_item[key]
						return content_item
				return merged_item

	if ContentLibrary != null and ContentLibrary.has_method("get_item"):
		var fallback_item_data: Variant = ContentLibrary.get_item(item_id)
		if typeof(fallback_item_data) == TYPE_DICTIONARY and not (fallback_item_data as Dictionary).is_empty():
			return fallback_item_data

	return {}


func _item_name(item_data: Dictionary, fallback_id: String) -> String:
	return String(item_data.get("name", fallback_id if not fallback_id.is_empty() else "아이템"))


func _item_effect_text(item_data: Dictionary) -> String:
	var parts: Array[String] = []
	var hunger_restore := int(item_data.get("hunger_restore", 0))
	if hunger_restore > 0:
		parts.append("허기 +%d" % hunger_restore)
	var thirst_restore := int(item_data.get("thirst_restore", 0))
	if thirst_restore != 0:
		parts.append("갈증 %s%d" % [_signed_prefix(thirst_restore), abs(thirst_restore)])
	var health_restore := int(item_data.get("health_restore", 0))
	if health_restore > 0:
		parts.append("체력 +%d" % health_restore)
	var fatigue_restore := int(item_data.get("fatigue_restore", 0))
	if fatigue_restore > 0:
		parts.append("피로 -%d" % fatigue_restore)
	var carry_weight := float(item_data.get("carry_weight", item_data.get("bulk", 0)))
	if carry_weight > 0.0:
		parts.append("무게 %.1fkg" % carry_weight)
	var carry_capacity_bonus := float(item_data.get("carry_capacity_bonus", item_data.get("carry_limit_bonus", 0)))
	if carry_capacity_bonus > 0.0:
		parts.append("운반 한계 +%.1fkg" % carry_capacity_bonus)
	var move_speed_bonus := int(item_data.get("move_speed_bonus", 0))
	if move_speed_bonus > 0:
		parts.append("이동속도 +%d" % move_speed_bonus)
	var fatigue_gain_bonus := float(item_data.get("fatigue_gain_bonus", 0.0))
	if fatigue_gain_bonus < 0.0:
		parts.append("피로 누적 -%d%%" % int(round(abs(fatigue_gain_bonus) * 100.0)))
	var equip_effects_variant: Variant = item_data.get("equip_effects", {})
	if typeof(equip_effects_variant) == TYPE_DICTIONARY:
		var equip_effects := equip_effects_variant as Dictionary
		var outdoor_exposure_multiplier := float(equip_effects.get("outdoor_exposure_drain_multiplier", 1.0))
		if outdoor_exposure_multiplier > 0.0 and outdoor_exposure_multiplier < 1.0:
			parts.append("야외 냉기 -%d%%" % int(round((1.0 - outdoor_exposure_multiplier) * 100.0)))
	var equip_slot := String(item_data.get("equip_slot", ""))
	if not equip_slot.is_empty():
		parts.append("장착 슬롯: %s" % _slot_label(equip_slot))
	var use_minutes := int(item_data.get("use_minutes", 0))
	if use_minutes > 0:
		parts.append("소요 시간 %d분" % use_minutes)
	var charges_max := int(item_data.get("charges_max", item_data.get("max_charges", 0)))
	var charges_current := int(item_data.get("charges_current", item_data.get("charges", charges_max)))
	if charges_max > 0:
		var charge_label := String(item_data.get("charge_label", "잔량"))
		parts.append("%s %d/%d" % [charge_label, charges_current, charges_max])

	return "효과 없음" if parts.is_empty() else " / ".join(parts)


func _item_sheet_effect_text(item_data: Dictionary) -> String:
	var lines: Array[String] = []
	var tag_texts := _item_tags(item_data)
	if not tag_texts.is_empty():
		lines.append(" ".join(tag_texts))
	lines.append(_item_effect_text(item_data))
	return "\n".join(lines)


func _item_tags(item_data: Dictionary) -> Array[String]:
	var tags: Array[String] = []
	var item_tags_variant: Variant = item_data.get("item_tags", [])
	if typeof(item_tags_variant) != TYPE_ARRAY:
		return tags
	for tag_variant in item_tags_variant:
		var tag_text := String(tag_variant)
		if tag_text.is_empty():
			continue
		tags.append("#%s" % tag_text)
	return tags


func _item_charges_text(item_id: String, item_data: Dictionary) -> String:
	if _run_state == null or not _run_state.has_method("get_tool_charges"):
		return ""
	var max_charges := int(item_data.get("charges_max", item_data.get("max_charges", 0)))
	if max_charges <= 0:
		return ""
	var charge_label := String(item_data.get("charge_label", "잔량"))
	return "%s %d / %d" % [charge_label, _run_state.get_tool_charges(item_id), max_charges]


func _inventory_sheet_actions(item_data: Dictionary, item_id: String) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if bool(item_data.get("readable", false)):
		actions.append({
			"id": "read_inventory_%s" % item_id,
			"label": "읽는다",
		})
	if _is_consumable(item_data):
		actions.append({
			"id": "consume_inventory_%s" % item_id,
			"label": _consume_action_label(item_data),
		})
	if not String(item_data.get("equip_slot", "")).is_empty():
		actions.append({
			"id": "equip_inventory_%s" % item_id,
			"label": "장착한다",
		})
	actions.append({
		"id": "drop_inventory_%s" % item_id,
		"label": "버린다",
	})
	actions.append({
		"id": "close_inventory_sheet",
		"label": "닫기",
	})
	return actions


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


func _slot_label(slot_id: String) -> String:
	match slot_id:
		"back":
			return "등"
		"feet":
			return "발"
		"feet_layer":
			return "양말"
		"hands":
			return "손"
		"hands_layer":
			return "장갑 안감"
		"neck":
			return "목"
		"face":
			return "얼굴"
		"body":
			return "몸"
		_:
			return slot_id


func _consume_action_label(item_data: Dictionary) -> String:
	var category := String(item_data.get("category", ""))
	if category == "drink":
		return "마신다"
	if category == "medical" or category == "stimulant":
		return "사용한다"
	return "먹는다"


func _consume_feedback_verb(item_data: Dictionary) -> String:
	var category := String(item_data.get("category", ""))
	if category == "drink":
		return "마셨다"
	if category == "medical" or category == "stimulant":
		return "사용했다"
	return "먹었다"


func _is_consumable(item_data: Dictionary) -> bool:
	return int(item_data.get("hunger_restore", 0)) > 0 \
		or int(item_data.get("thirst_restore", 0)) != 0 \
		or int(item_data.get("health_restore", 0)) > 0 \
		or int(item_data.get("fatigue_restore", 0)) > 0


func _signed_prefix(value: int) -> String:
	return "+" if value >= 0 else "-"
