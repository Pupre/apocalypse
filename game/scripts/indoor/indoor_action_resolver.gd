extends RefCounted


func load_event(path: String) -> Dictionary:
	if path.is_empty():
		push_error("Indoor event path is empty.")
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open indoor event file: %s" % path)
		return {}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		push_error("%s: invalid JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("%s: expected a top-level object." % path)
		return {}

	return json.data


func get_entry_zone_id(event_data: Dictionary) -> String:
	return String(event_data.get("entry_zone_id", ""))


func get_zone(event_data: Dictionary, zone_id: String) -> Dictionary:
	for zone_variant in event_data.get("zones", []):
		if typeof(zone_variant) != TYPE_DICTIONARY:
			continue

		var zone := zone_variant as Dictionary
		if String(zone.get("id", "")) == zone_id:
			return zone

	return {}


func is_zone_accessible(event_data: Dictionary, event_state: Dictionary, zone_id: String, run_state = null) -> bool:
	var zone := get_zone(event_data, zone_id)
	if zone.is_empty():
		return false

	return _zone_is_accessible(zone, event_state, run_state)


func get_move_actions(event_data: Dictionary, event_state: Dictionary, run_state = null) -> Array[Dictionary]:
	var zone := get_zone(event_data, String(event_state.get("current_zone_id", "")))
	if zone.is_empty():
		return []

	var visited_zone_ids := _string_id_array(event_state.get("visited_zone_ids", []))
	var actions: Array[Dictionary] = []
	for connected_zone_id_variant in zone.get("connected_zone_ids", []):
		var connected_zone_id := String(connected_zone_id_variant)
		var connected_zone := get_zone(event_data, connected_zone_id)
		if connected_zone.is_empty():
			continue
		var is_accessible := _zone_is_accessible(connected_zone, event_state, run_state)
		var move_label := _resolve_move_label(zone, connected_zone)

		var minute_cost := int(connected_zone.get("revisit_cost", 10)) if visited_zone_ids.has(connected_zone_id) else int(connected_zone.get("first_visit_cost", 30))
		actions.append({
			"id": "move_%s" % connected_zone_id,
			"type": "move",
			"label": move_label,
			"target_zone_id": connected_zone_id,
			"minute_cost": minute_cost,
			"locked": not is_accessible,
			"blocked_feedback": String(connected_zone.get("blocked_feedback", "")),
		})

	return actions


func get_visible_clues(event_data: Dictionary, event_state: Dictionary) -> Array[Dictionary]:
	var revealed_clue_ids := _string_id_array(event_state.get("revealed_clue_ids", []))
	var visible_clues: Array[Dictionary] = []

	for clue_variant in event_data.get("clues", []):
		if typeof(clue_variant) != TYPE_DICTIONARY:
			continue

		var clue := clue_variant as Dictionary
		var clue_id := String(clue.get("id", ""))
		if bool(clue.get("visible", false)) or revealed_clue_ids.has(clue_id):
			visible_clues.append(clue)

	return visible_clues


func get_actions(event_data: Dictionary, event_state: Dictionary = {}, run_state = null) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if _has_zone_state(event_data, event_state):
		actions.append_array(_get_take_loot_actions(event_state, run_state))

	actions.append_array(_get_flat_actions(event_data, event_state))
	actions.append_array(_get_zone_actions(event_data, event_state, run_state))
	if _has_zone_state(event_data, event_state):
		actions.append_array(get_move_actions(event_data, event_state, run_state))

	return actions


func get_sleep_preview(run_state) -> Dictionary:
	if run_state == null or not run_state.has_method("get_sleep_preview"):
		return {}

	return run_state.get_sleep_preview()


func apply_action(run_state, event_data: Dictionary, event_state: Dictionary, action_id: String) -> bool:
	var take_action := _get_take_loot_action(event_state, action_id, run_state)
	if not take_action.is_empty():
		return _apply_take_loot_action(run_state, event_state, take_action)

	var action := _get_action(event_data, event_state, action_id, run_state)
	if action.is_empty():
		var move_action := _get_move_action(event_data, event_state, action_id)
		if not move_action.is_empty():
			return _apply_move_action(run_state, event_data, event_state, move_action)

	if action.is_empty():
		return false
	if bool(action.get("locked", false)):
		var blocked_feedback := String(action.get("blocked_feedback", ""))
		event_state["last_feedback_message"] = blocked_feedback if not blocked_feedback.is_empty() else "지금은 그 행동을 할 수 없다."
		return true

	if _action_consumes_on_use(action) and _is_action_spent(event_state, action_id):
		return false

	if run_state != null:
		var minute_cost := int(action.get("minute_cost", 0))
		if minute_cost > 0 and run_state.has_method("advance_minutes"):
			run_state.advance_minutes(minute_cost)
		else:
			var sleep_minutes := int(action.get("sleep_minutes", 0))
			if sleep_minutes > 0 and run_state.has_method("advance_sleep_time"):
				run_state.advance_sleep_time(sleep_minutes)

		if action.has("discover_loot"):
			var discovered_loot := _dictionary_loot_array(action.get("discover_loot", []))
			_append_zone_found_loot(event_state, String(event_state.get("current_zone_id", "")), discovered_loot)
			var discovered_labels := _loot_labels(discovered_loot)
			if not discovered_labels.is_empty():
				var discovered_message := "%s 발견했다." % ", ".join(discovered_labels)
				if minute_cost > 0:
					discovered_message += " %d분 동안 탐색했다." % minute_cost
				event_state["last_feedback_message"] = discovered_message
			elif minute_cost > 0:
				event_state["last_feedback_message"] = "%d분 동안 탐색했지만 챙길 만한 건 없었다." % minute_cost
		else:
			var loot_messages: Array[String] = []
			var collected_loot_labels: Array[String] = []
			for loot_variant in action.get("loot", []):
				if typeof(loot_variant) != TYPE_DICTIONARY or run_state == null:
					continue

				var loot := loot_variant as Dictionary
				if run_state.inventory.add_item(loot):
					collected_loot_labels.append(_loot_label(loot))
				else:
					loot_messages.append("가방이 가득 차서 %s 챙기지 못했다." % _loot_label(loot))

			if not loot_messages.is_empty():
				var feedback_message := ""
				for message in loot_messages:
					if not feedback_message.is_empty():
						feedback_message += " "
					feedback_message += message
				event_state["last_feedback_message"] = feedback_message
			elif not collected_loot_labels.is_empty():
				var collected_message := "%s 챙겼다." % ", ".join(collected_loot_labels)
				if minute_cost > 0:
					collected_message += " %d분 동안 수색했다." % minute_cost
				event_state["last_feedback_message"] = collected_message
			elif minute_cost > 0:
				event_state["last_feedback_message"] = "%d분 동안 수색했다." % minute_cost
		if int(action.get("sleep_minutes", 0)) > 0 and not action.has("discover_loot"):
			event_state["last_feedback_message"] = "%d분 동안 휴식했다." % int(action.get("sleep_minutes", 0))

	_apply_action_outcomes(event_state, action)

	if _action_consumes_on_use(action):
		var spent_action_ids := _string_id_array(event_state.get("spent_action_ids", []))
		if not spent_action_ids.has(action_id):
			spent_action_ids.append(action_id)
		event_state["spent_action_ids"] = spent_action_ids
	var revealed_clue_ids := _string_id_array(event_state.get("revealed_clue_ids", []))
	for clue_id_variant in action.get("reveal_clue_ids", []):
		var clue_id := String(clue_id_variant)
		if not revealed_clue_ids.has(clue_id):
			revealed_clue_ids.append(clue_id)

	event_state["revealed_clue_ids"] = revealed_clue_ids
	return true


func _get_flat_actions(event_data: Dictionary, event_state: Dictionary) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var spent_action_ids := _string_id_array(event_state.get("spent_action_ids", []))

	for action_variant in event_data.get("actions", []):
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue

		var action := action_variant as Dictionary
		var action_id := String(action.get("id", ""))
		if not _action_consumes_on_use(action) or not spent_action_ids.has(action_id):
			actions.append(action)

	return actions


func _get_zone_actions(event_data: Dictionary, event_state: Dictionary, run_state = null) -> Array[Dictionary]:
	var current_zone_id := String(event_state.get("current_zone_id", ""))
	if current_zone_id.is_empty():
		return []

	var actions: Array[Dictionary] = []
	for event in _get_zone_events(event_data, current_zone_id):
		for option_variant in event.get("options", []):
			if typeof(option_variant) != TYPE_DICTIONARY:
				continue

			var option := option_variant as Dictionary
			var action := _normalize_zone_option(event, option)
			var action_id := String(action.get("id", ""))
			if action.is_empty():
				continue
			var is_available := _option_is_available(action, event_state, run_state)
			if not is_available and not bool(action.get("show_when_locked", true)):
				continue

			if _action_consumes_on_use(action) and _is_action_spent(event_state, action_id):
				continue

			action["locked"] = not is_available
			actions.append(action)

	return actions


func _get_move_action(event_data: Dictionary, event_state: Dictionary, action_id: String) -> Dictionary:
	for action in get_move_actions(event_data, event_state):
		if String(action.get("id", "")) == action_id:
			return action

	return {}


func _apply_move_action(run_state, event_data: Dictionary, event_state: Dictionary, action: Dictionary) -> bool:
	var origin_zone_id := String(event_state.get("current_zone_id", ""))
	var target_zone_id := String(action.get("target_zone_id", ""))
	var target_zone := get_zone(event_data, target_zone_id)
	if target_zone.is_empty():
		return false
	if bool(action.get("locked", false)):
		var blocked_feedback := String(action.get("blocked_feedback", ""))
		event_state["last_feedback_message"] = blocked_feedback if not blocked_feedback.is_empty() else "%s 쪽으로 가는 길이 잠겨 있어 열리지 않는다." % String(target_zone.get("label", target_zone_id))
		return true

	var minute_cost := int(action.get("minute_cost", 0))
	if minute_cost > 0 and run_state != null and run_state.has_method("advance_minutes"):
		run_state.advance_minutes(minute_cost)

	var traversed_edge_ids := _string_id_array(event_state.get("traversed_edge_ids", []))
	var traversed_edge_id := _sorted_edge_id(origin_zone_id, target_zone_id)
	if not traversed_edge_id.is_empty() and not traversed_edge_ids.has(traversed_edge_id):
		traversed_edge_ids.append(traversed_edge_id)
	event_state["traversed_edge_ids"] = traversed_edge_ids

	event_state["current_zone_id"] = target_zone_id
	var visited_zone_ids := _string_id_array(event_state.get("visited_zone_ids", []))
	if not visited_zone_ids.has(target_zone_id):
		visited_zone_ids.append(target_zone_id)
	event_state["visited_zone_ids"] = visited_zone_ids
	event_state["last_feedback_message"] = "%s로 이동했다." % String(target_zone.get("label", target_zone_id))
	return true


func _get_action(event_data: Dictionary, event_state: Dictionary, action_id: String, run_state = null) -> Dictionary:
	for action_variant in _get_flat_actions(event_data, event_state):
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue

		var action := action_variant as Dictionary
		if String(action.get("id", "")) == action_id:
			return action

	for action_variant in _get_zone_actions(event_data, event_state, run_state):
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue

		var action := action_variant as Dictionary
		if String(action.get("id", "")) == action_id:
			return action

	return {}


func _has_zone_state(event_data: Dictionary, event_state: Dictionary) -> bool:
	var current_zone_id := String(event_state.get("current_zone_id", ""))
	if current_zone_id.is_empty():
		return false

	return not get_zone(event_data, current_zone_id).is_empty()


func _get_zone_events(event_data: Dictionary, zone_id: String) -> Array[Dictionary]:
	var zone := get_zone(event_data, zone_id)
	if zone.is_empty():
		return []

	var zone_event_ids := _string_id_array(zone.get("event_ids", []))
	var events: Array[Dictionary] = []
	for event_variant in event_data.get("events", []):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue

		var event := event_variant as Dictionary
		var event_id := String(event.get("id", ""))
		if event_id.is_empty():
			continue

		if zone_event_ids.has(event_id) or String(event.get("zone_id", "")) == zone_id:
			events.append(event)

	return events


func _normalize_zone_option(event: Dictionary, option: Dictionary) -> Dictionary:
	var action := option.duplicate(true)
	action["zone_id"] = String(event.get("zone_id", ""))
	action["event_id"] = String(event.get("id", ""))
	action["blocked_feedback"] = String(option.get("blocked_feedback", ""))
	action["show_when_locked"] = bool(option.get("show_when_locked", true))

	var costs: Dictionary = option.get("costs", {})
	if typeof(costs) == TYPE_DICTIONARY:
		action["minute_cost"] = int(costs.get("minutes", action.get("minute_cost", 0)))
		action["noise_cost"] = int(costs.get("noise", action.get("noise_cost", 0)))
		if costs.has("sleep_minutes"):
			action["sleep_minutes"] = int(costs.get("sleep_minutes", 0))

	var outcomes: Dictionary = option.get("outcomes", {})
	if typeof(outcomes) == TYPE_DICTIONARY:
		if outcomes.has("loot"):
			action["loot"] = outcomes.get("loot", [])
		if outcomes.has("discover_loot"):
			action["discover_loot"] = outcomes.get("discover_loot", [])
		if outcomes.has("reveal_clue_ids"):
			action["reveal_clue_ids"] = _string_id_array(outcomes.get("reveal_clue_ids", []))
		if outcomes.has("set_flags"):
			action["set_flags"] = _string_id_array(outcomes.get("set_flags", []))
		if outcomes.has("unlock_zone_ids"):
			action["unlock_zone_ids"] = _string_id_array(outcomes.get("unlock_zone_ids", []))
		if outcomes.has("consume_on_use"):
			action["consume_on_use"] = bool(outcomes.get("consume_on_use", false))

	return action


func _option_is_available(action: Dictionary, event_state: Dictionary, run_state = null) -> bool:
	var requirements: Dictionary = action.get("requirements", {})
	if typeof(requirements) != TYPE_DICTIONARY or requirements.is_empty():
		return true

	return _requirements_are_met(requirements, event_state, run_state)


func _zone_is_accessible(zone: Dictionary, event_state: Dictionary, run_state = null) -> bool:
	var requirements: Dictionary = zone.get("access_requirements", {})
	if typeof(requirements) != TYPE_DICTIONARY or requirements.is_empty():
		return true

	return _requirements_are_met(requirements, event_state, run_state)


func _requirements_are_met(requirements: Dictionary, event_state: Dictionary, run_state = null) -> bool:
	if not _requirements_contain_ids(requirements.get("required_flag_ids", []), event_state.get("zone_flags", {})):
		return false

	if not _requirements_contain_ids(requirements.get("required_clue_ids", []), event_state.get("revealed_clue_ids", [])):
		return false

	if not _requirements_contain_ids(requirements.get("required_unlocked_zone_ids", []), event_state.get("unlocked_zone_ids", [])):
		return false

	if not _inventory_contains_ids(run_state, requirements.get("required_item_ids", [])):
		return false

	return true


func _requirements_contain_ids(required_ids, source_values) -> bool:
	var required := _string_id_array(required_ids)
	if required.is_empty():
		return true

	var source_lookup := {}
	for value in source_values:
		source_lookup[String(value)] = true

	for required_id in required:
		if not source_lookup.has(required_id):
			return false

	return true


func _inventory_contains_ids(run_state, required_item_ids) -> bool:
	var required := _string_id_array(required_item_ids)
	if required.is_empty():
		return true
	if run_state == null or run_state.inventory == null:
		return false

	var inventory_lookup := {}
	for item_variant in run_state.inventory.items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item := item_variant as Dictionary
		inventory_lookup[String(item.get("id", ""))] = true

	for required_id in required:
		if not inventory_lookup.has(required_id):
			return false
	return true


func _apply_action_outcomes(event_state: Dictionary, action: Dictionary) -> void:
	var noise_cost := int(action.get("noise_cost", 0))
	if noise_cost != 0:
		event_state["noise"] = int(event_state.get("noise", 0)) + noise_cost

	var zone_flags := _zone_flags(event_state)
	var set_flag_ids := _string_id_array(action.get("set_flags", []))
	for flag_id in set_flag_ids:
		zone_flags[flag_id] = true
	if not set_flag_ids.is_empty():
		event_state["zone_flags"] = zone_flags

	var unlocked_zone_ids := _string_id_array(event_state.get("unlocked_zone_ids", []))
	var added_unlocks := false
	for zone_id in _string_id_array(action.get("unlock_zone_ids", [])):
		if not unlocked_zone_ids.has(zone_id):
			unlocked_zone_ids.append(zone_id)
			added_unlocks = true
	if added_unlocks:
		event_state["unlocked_zone_ids"] = unlocked_zone_ids


func _zone_flags(event_state: Dictionary) -> Dictionary:
	var zone_flags: Dictionary = event_state.get("zone_flags", {})
	if typeof(zone_flags) == TYPE_DICTIONARY:
		return zone_flags

	return {}


func _get_take_loot_actions(event_state: Dictionary, run_state = null) -> Array[Dictionary]:
	var current_zone_id := String(event_state.get("current_zone_id", ""))
	if current_zone_id.is_empty():
		return []

	var found_loot := _get_zone_found_loot(event_state, current_zone_id)
	var actions: Array[Dictionary] = []
	for loot_index in range(found_loot.size()):
		var loot := found_loot[loot_index]
		var loot_id := String(loot.get("id", "loot"))
		var loot_uid := int(loot.get("loot_uid", loot_index))
		var loot_label := _loot_label(loot)
		var can_add: bool = run_state != null and run_state.inventory != null and run_state.inventory.can_add(loot)
		actions.append({
			"id": "take_%s_%s_%d" % [current_zone_id, loot_id, loot_uid],
			"type": "take_loot",
			"label": "%s 챙긴다" % loot_label,
			"zone_id": current_zone_id,
			"loot_index": loot_index,
			"loot": loot,
			"locked": not can_add,
			"blocked_feedback": "가방이 가득 차서 %s 챙기지 못한다." % loot_label,
		})

	return actions


func _get_take_loot_action(event_state: Dictionary, action_id: String, run_state = null) -> Dictionary:
	for action in _get_take_loot_actions(event_state, run_state):
		if String(action.get("id", "")) == action_id:
			return action
	return {}


func _apply_take_loot_action(run_state, event_state: Dictionary, action: Dictionary) -> bool:
	if run_state == null or run_state.inventory == null:
		return false
	if bool(action.get("locked", false)):
		event_state["last_feedback_message"] = String(action.get("blocked_feedback", "가방이 가득 차서 더 챙길 수 없다."))
		return true

	var zone_id := String(action.get("zone_id", ""))
	var loot_index := int(action.get("loot_index", -1))
	var found_loot := _get_zone_found_loot(event_state, zone_id)
	if loot_index < 0 or loot_index >= found_loot.size():
		return false

	var loot := found_loot[loot_index]
	if not run_state.inventory.add_item(loot):
		event_state["last_feedback_message"] = "가방이 가득 차서 %s 챙기지 못한다." % _loot_label(loot)
		return true

	found_loot.remove_at(loot_index)
	_set_zone_found_loot(event_state, zone_id, found_loot)
	event_state["last_feedback_message"] = "%s 챙겼다." % _loot_label(loot)
	return true


func _get_zone_found_loot(event_state: Dictionary, zone_id: String) -> Array[Dictionary]:
	var all_found_loot: Dictionary = event_state.get("zone_found_loot", {})
	if typeof(all_found_loot) != TYPE_DICTIONARY:
		return []
	return _dictionary_loot_array(all_found_loot.get(zone_id, []))


func _append_zone_found_loot(event_state: Dictionary, zone_id: String, discovered_loot: Array[Dictionary]) -> void:
	if zone_id.is_empty():
		return

	var all_found_loot: Dictionary = event_state.get("zone_found_loot", {})
	if typeof(all_found_loot) != TYPE_DICTIONARY:
		all_found_loot = {}

	var existing_loot := _dictionary_loot_array(all_found_loot.get(zone_id, []))
	for loot in discovered_loot:
		var loot_entry := loot.duplicate(true)
		if int(loot_entry.get("loot_uid", -1)) < 0:
			loot_entry["loot_uid"] = _consume_loot_uid(event_state)
		existing_loot.append(loot_entry)
	all_found_loot[zone_id] = existing_loot
	event_state["zone_found_loot"] = all_found_loot


func _set_zone_found_loot(event_state: Dictionary, zone_id: String, found_loot: Array[Dictionary]) -> void:
	var all_found_loot: Dictionary = event_state.get("zone_found_loot", {})
	if typeof(all_found_loot) != TYPE_DICTIONARY:
		all_found_loot = {}
	all_found_loot[zone_id] = found_loot
	event_state["zone_found_loot"] = all_found_loot


func _consume_loot_uid(event_state: Dictionary) -> int:
	var next_loot_uid := int(event_state.get("next_loot_uid", 0))
	event_state["next_loot_uid"] = next_loot_uid + 1
	return next_loot_uid


func _string_id_array(values) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result


func _dictionary_loot_array(values) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		if typeof(value) == TYPE_DICTIONARY:
			result.append((value as Dictionary).duplicate(true))
	return result


func _loot_labels(loots: Array[Dictionary]) -> Array[String]:
	var labels: Array[String] = []
	for loot in loots:
		labels.append(_loot_label(loot))
	return labels


func _sorted_edge_id(from_zone_id: String, to_zone_id: String) -> String:
	if from_zone_id.is_empty() or to_zone_id.is_empty():
		return ""
	return "%s|%s" % [from_zone_id, to_zone_id] if from_zone_id < to_zone_id else "%s|%s" % [to_zone_id, from_zone_id]


func _resolve_move_label(current_zone: Dictionary, target_zone: Dictionary) -> String:
	var default_label := "%s로 이동한다" % String(target_zone.get("label", target_zone.get("id", "")))
	var preferred_label := String(target_zone.get("move_label", ""))
	if preferred_label.is_empty():
		return default_label

	var current_floor_index := _floor_index(String(current_zone.get("floor_id", "")))
	var target_floor_index := _floor_index(String(target_zone.get("floor_id", "")))
	if target_floor_index > current_floor_index:
		return preferred_label

	return default_label


func _floor_index(floor_id: String) -> int:
	var parts := floor_id.split("_")
	if parts.size() >= 2 and String(parts[1]).is_valid_int():
		return int(parts[1])
	return 0


func _loot_label(loot: Dictionary) -> String:
	var name := String(loot.get("name", ""))
	if not name.is_empty():
		return name

	return String(loot.get("id", "item"))


func _is_action_spent(event_state: Dictionary, action_id: String) -> bool:
	var spent_action_ids := _string_id_array(event_state.get("spent_action_ids", []))
	return spent_action_ids.has(action_id)


func _action_consumes_on_use(action: Dictionary) -> bool:
	return bool(action.get("consume_on_use", false))
