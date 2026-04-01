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


func get_move_actions(event_data: Dictionary, event_state: Dictionary) -> Array[Dictionary]:
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

		var minute_cost := int(connected_zone.get("revisit_cost", 10)) if visited_zone_ids.has(connected_zone_id) else int(connected_zone.get("first_visit_cost", 30))
		actions.append({
			"id": "move_%s" % connected_zone_id,
			"type": "move",
			"label": "%s로 이동한다" % String(connected_zone.get("label", connected_zone_id)),
			"target_zone_id": connected_zone_id,
			"minute_cost": minute_cost,
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


func get_actions(event_data: Dictionary, event_state: Dictionary = {}) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if _has_zone_state(event_data, event_state):
		actions.append_array(get_move_actions(event_data, event_state))

	actions.append_array(_get_flat_actions(event_data, event_state))
	actions.append_array(_get_zone_actions(event_data, event_state))

	return actions


func get_sleep_preview(run_state) -> Dictionary:
	if run_state == null or not run_state.has_method("get_sleep_preview"):
		return {}

	return run_state.get_sleep_preview()


func apply_action(run_state, event_data: Dictionary, event_state: Dictionary, action_id: String) -> bool:
	var action := _get_action(event_data, event_state, action_id)
	if action.is_empty():
		var move_action := _get_move_action(event_data, event_state, action_id)
		if not move_action.is_empty():
			return _apply_move_action(run_state, event_data, event_state, move_action)

	if action.is_empty():
		return false

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

		var loot_messages: Array[String] = []
		for loot_variant in action.get("loot", []):
			if typeof(loot_variant) != TYPE_DICTIONARY or run_state == null:
				continue

			var loot := loot_variant as Dictionary
			if not run_state.inventory.add_item(loot):
				loot_messages.append("가방이 가득 차서 %s 챙기지 못했다." % _loot_label(loot))

		if not loot_messages.is_empty():
			var feedback_message := ""
			for message in loot_messages:
				if not feedback_message.is_empty():
					feedback_message += " "
				feedback_message += message
			event_state["last_feedback_message"] = feedback_message
		elif minute_cost > 0:
			event_state["last_feedback_message"] = "%d분 동안 수색했다." % minute_cost
		elif int(action.get("sleep_minutes", 0)) > 0:
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


func _get_zone_actions(event_data: Dictionary, event_state: Dictionary) -> Array[Dictionary]:
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
			if action.is_empty() or not _option_is_available(action, event_state):
				continue

			if _action_consumes_on_use(action) and _is_action_spent(event_state, action_id):
				continue

			actions.append(action)

	return actions


func _get_move_action(event_data: Dictionary, event_state: Dictionary, action_id: String) -> Dictionary:
	for action in get_move_actions(event_data, event_state):
		if String(action.get("id", "")) == action_id:
			return action

	return {}


func _apply_move_action(run_state, event_data: Dictionary, event_state: Dictionary, action: Dictionary) -> bool:
	var target_zone_id := String(action.get("target_zone_id", ""))
	var target_zone := get_zone(event_data, target_zone_id)
	if target_zone.is_empty():
		return false

	var minute_cost := int(action.get("minute_cost", 0))
	if minute_cost > 0 and run_state != null and run_state.has_method("advance_minutes"):
		run_state.advance_minutes(minute_cost)

	event_state["current_zone_id"] = target_zone_id
	var visited_zone_ids := _string_id_array(event_state.get("visited_zone_ids", []))
	if not visited_zone_ids.has(target_zone_id):
		visited_zone_ids.append(target_zone_id)
	event_state["visited_zone_ids"] = visited_zone_ids
	event_state["last_feedback_message"] = "%s로 이동했다." % String(target_zone.get("label", target_zone_id))
	return true


func _get_action(event_data: Dictionary, event_state: Dictionary, action_id: String) -> Dictionary:
	for action_variant in _get_flat_actions(event_data, event_state):
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue

		var action := action_variant as Dictionary
		if String(action.get("id", "")) == action_id:
			return action

	for action_variant in _get_zone_actions(event_data, event_state):
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
		if outcomes.has("reveal_clue_ids"):
			action["reveal_clue_ids"] = _string_id_array(outcomes.get("reveal_clue_ids", []))
		if outcomes.has("set_flags"):
			action["set_flags"] = _string_id_array(outcomes.get("set_flags", []))
		if outcomes.has("unlock_zone_ids"):
			action["unlock_zone_ids"] = _string_id_array(outcomes.get("unlock_zone_ids", []))
		if outcomes.has("consume_on_use"):
			action["consume_on_use"] = bool(outcomes.get("consume_on_use", false))

	return action


func _option_is_available(action: Dictionary, event_state: Dictionary) -> bool:
	var requirements: Dictionary = action.get("requirements", {})
	if typeof(requirements) != TYPE_DICTIONARY or requirements.is_empty():
		return true

	if not _requirements_contain_ids(requirements.get("required_flag_ids", []), event_state.get("zone_flags", {})):
		return false

	if not _requirements_contain_ids(requirements.get("required_clue_ids", []), event_state.get("revealed_clue_ids", [])):
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


func _string_id_array(values) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result


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
