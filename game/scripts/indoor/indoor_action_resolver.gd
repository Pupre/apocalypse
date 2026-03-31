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


func get_actions(event_data: Dictionary) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []

	for action_variant in event_data.get("actions", []):
		if typeof(action_variant) == TYPE_DICTIONARY:
			actions.append(action_variant)

	return actions


func get_sleep_preview(run_state) -> Dictionary:
	if run_state == null or not run_state.has_method("get_sleep_preview"):
		return {}

	return run_state.get_sleep_preview()


func apply_action(run_state, event_data: Dictionary, event_state: Dictionary, action_id: String) -> bool:
	var action := _get_action(event_data, action_id)
	if action.is_empty():
		return false

	if run_state != null:
		var sleep_minutes := int(action.get("sleep_minutes", 0))
		if sleep_minutes > 0 and run_state.has_method("advance_sleep_time"):
			run_state.advance_sleep_time(sleep_minutes)

		for loot_variant in action.get("loot", []):
			if typeof(loot_variant) == TYPE_DICTIONARY and run_state != null:
				run_state.inventory.add_item(loot_variant)

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
