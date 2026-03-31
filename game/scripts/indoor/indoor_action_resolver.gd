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
	var spent_action_ids := _string_id_array(event_state.get("spent_action_ids", []))

	for action_variant in event_data.get("actions", []):
		if typeof(action_variant) == TYPE_DICTIONARY:
			var action := action_variant as Dictionary
			var action_id := String(action.get("id", ""))
			if not _action_consumes_on_use(action) or not spent_action_ids.has(action_id):
				actions.append(action)

	return actions


func get_sleep_preview(run_state) -> Dictionary:
	if run_state == null or not run_state.has_method("get_sleep_preview"):
		return {}

	return run_state.get_sleep_preview()


func apply_action(run_state, event_data: Dictionary, event_state: Dictionary, action_id: String) -> bool:
	var action := _get_action(event_data, action_id)
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
				loot_messages.append("Left %s behind because inventory is full." % _loot_label(loot))

		if not loot_messages.is_empty():
			var feedback_message := ""
			for message in loot_messages:
				if not feedback_message.is_empty():
					feedback_message += " "
				feedback_message += message
			event_state["last_feedback_message"] = feedback_message
		elif minute_cost > 0:
			event_state["last_feedback_message"] = "Spent %d minutes searching." % minute_cost
		elif int(action.get("sleep_minutes", 0)) > 0:
			event_state["last_feedback_message"] = "Rested for %d minutes." % int(action.get("sleep_minutes", 0))

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


func _get_action(event_data: Dictionary, action_id: String) -> Dictionary:
	for action_variant in event_data.get("actions", []):
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue

		var action := action_variant as Dictionary
		if String(action.get("id", "")) == action_id:
			return action

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
