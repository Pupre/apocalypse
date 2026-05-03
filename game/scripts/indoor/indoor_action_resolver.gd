extends RefCounted

const NOISE_ESCALATION_STEPS := [
	{
		"id": "noise_attention_3",
		"threshold": 3,
		"message": "소란이 커지자 문밖의 발소리가 멎었다. 숨을 죽이느라 시간이 흘렀다.",
		"fatigue_gain": 1.0,
		"minutes": 5,
	},
	{
		"id": "noise_attention_6",
		"threshold": 6,
		"message": "건물 앞에서 정체 모를 움직임이 멈췄다. 기다리는 사이 한기가 스며든다.",
		"exposure_loss": 3.0,
		"fatigue_gain": 2.0,
		"minutes": 7,
	},
	{
		"id": "noise_attention_9",
		"threshold": 9,
		"message": "큰 소리에 먼지와 유리 조각이 떨어져 팔을 긁었다. 더는 소란을 키우기 어렵다.",
		"exposure_loss": 2.0,
		"fatigue_gain": 3.0,
		"health_loss": 2.0,
		"minutes": 8,
	},
]


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
		if run_state != null and run_state.has_method("get_indoor_action_minutes"):
			minute_cost = int(run_state.get_indoor_action_minutes(minute_cost))
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
		actions.append_array(_get_take_supply_actions(event_state, run_state))

	actions.append_array(_get_flat_actions(event_data, event_state))
	actions.append_array(_get_zone_actions(event_data, event_state, run_state))
	actions.append_array(_get_safe_zone_actions(event_data, event_state, run_state))
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

	var take_supply_action := _get_take_supply_action(event_state, action_id, run_state)
	if not take_supply_action.is_empty():
		return _apply_take_supply_action(run_state, event_state, take_supply_action)

	var action := _get_action(event_data, event_state, action_id, run_state)
	if action.is_empty():
		var move_action := _get_move_action(event_data, event_state, action_id, run_state)
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

	if not _consume_action_items(run_state, action):
		return false

	if run_state != null:
		var rest_minutes := int(action.get("rest_minutes", 0))
		var minute_cost := int(action.get("minute_cost", 0))
		if rest_minutes > 0 and run_state.has_method("advance_rest_time"):
			run_state.advance_rest_time(rest_minutes)
		elif minute_cost > 0 and run_state.has_method("advance_minutes"):
			run_state.advance_minutes(minute_cost)
		else:
			var sleep_minutes := int(action.get("sleep_minutes", 0))
			if sleep_minutes > 0 and run_state.has_method("advance_sleep_time"):
				run_state.advance_sleep_time(sleep_minutes)

		if action.has("discover_loot") or action.has("loot_table") or action.has("supply_sources"):
			var discovered_loot := _resolve_discovered_loot(event_data, event_state, action, run_state)
			_append_zone_found_loot(event_state, String(event_state.get("current_zone_id", "")), discovered_loot)
			var discovered_supply_sources := _normalize_supply_sources_array(action.get("supply_sources", []))
			_append_zone_supply_sources(event_state, String(event_state.get("current_zone_id", "")), discovered_supply_sources)
			var discovered_labels := _loot_labels(discovered_loot)
			if not discovered_labels.is_empty():
				var discovered_message := "%s 발견했다." % ", ".join(discovered_labels)
				if minute_cost > 0:
					discovered_message += " %d분 동안 탐색했다." % minute_cost
				event_state["last_feedback_message"] = discovered_message
			elif minute_cost > 0:
				if not discovered_supply_sources.is_empty():
					event_state["last_feedback_message"] = "%d분 동안 탐색해 남은 재고를 확인했다." % minute_cost
				else:
					event_state["last_feedback_message"] = "%d분 동안 탐색했지만 챙길 만한 건 없었다." % minute_cost
		else:
			var loot_messages: Array[String] = []
			var collected_loot_labels: Array[String] = []
			var inventory = _run_inventory(run_state)
			for loot_variant in action.get("loot", []):
				if typeof(loot_variant) != TYPE_DICTIONARY or inventory == null:
					continue

				var loot := loot_variant as Dictionary
				if inventory.add_item(loot):
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
		if int(action.get("rest_minutes", 0)) > 0 and not action.has("discover_loot"):
			event_state["last_feedback_message"] = "%d분 동안 숨을 골랐다." % int(action.get("rest_minutes", 0))
		elif int(action.get("sleep_minutes", 0)) > 0 and not action.has("discover_loot"):
			event_state["last_feedback_message"] = "%d분 동안 잠을 청했다." % int(action.get("sleep_minutes", 0))

	_apply_action_outcomes(event_state, action)
	_apply_action_pressure(run_state, event_state, action)
	_apply_noise_escalation(run_state, event_state)

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
			if int(action.get("minute_cost", 0)) > 0 and run_state != null and run_state.has_method("get_indoor_action_minutes"):
				action["minute_cost"] = int(run_state.get_indoor_action_minutes(int(action.get("minute_cost", 0))))
			var is_available := _option_is_available(action, event_state, run_state)
			if not is_available and (_option_is_forbidden_by_state(action, event_state) or not bool(action.get("show_when_locked", true))):
				continue

			if _action_consumes_on_use(action) and _is_action_spent(event_state, action_id):
				continue

			action["locked"] = not is_available
			actions.append(action)

	return actions


func _get_safe_zone_actions(event_data: Dictionary, event_state: Dictionary, run_state = null) -> Array[Dictionary]:
	var current_zone_id := String(event_state.get("current_zone_id", ""))
	if current_zone_id.is_empty():
		return []

	var current_zone := get_zone(event_data, current_zone_id)
	if current_zone.is_empty():
		return []

	var actions: Array[Dictionary] = []
	var rest_minutes := int(current_zone.get("rest_minutes", 0))
	if rest_minutes > 0:
		actions.append({
			"id": "rest_in_safe_zone",
			"type": "interaction",
			"label": "짧게 숨을 고른다",
			"rest_minutes": rest_minutes,
			"minute_cost": rest_minutes,
		})

	if bool(current_zone.get("sleep_allowed", false)) and run_state != null and run_state.has_method("get_sleep_preview"):
		var preview: Dictionary = run_state.get_sleep_preview()
		var sleep_minutes := int(preview.get("sleep_minutes", 0))
		if sleep_minutes > 0:
			actions.append({
				"id": "sleep_in_safe_zone",
				"type": "interaction",
				"label": "잠을 청한다",
				"sleep_minutes": sleep_minutes,
			})

	return actions


func _get_move_action(event_data: Dictionary, event_state: Dictionary, action_id: String, run_state = null) -> Dictionary:
	for action in get_move_actions(event_data, event_state, run_state):
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
	event_state.erase("last_illustration_asset")
	if run_state != null and run_state.has_method("update_current_indoor_zone"):
		run_state.update_current_indoor_zone(target_zone_id)
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

	for action_variant in _get_safe_zone_actions(event_data, event_state, run_state):
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
		if outcomes.has("loot_table"):
			action["loot_table"] = outcomes.get("loot_table", {})
		if outcomes.has("supply_sources"):
			action["supply_sources"] = outcomes.get("supply_sources", [])
		if outcomes.has("reveal_clue_ids"):
			action["reveal_clue_ids"] = _string_id_array(outcomes.get("reveal_clue_ids", []))
		if outcomes.has("set_flags"):
			action["set_flags"] = _string_id_array(outcomes.get("set_flags", []))
		if outcomes.has("unlock_zone_ids"):
			action["unlock_zone_ids"] = _string_id_array(outcomes.get("unlock_zone_ids", []))
		if outcomes.has("consume_item_ids"):
			action["consume_item_ids"] = _string_id_array(outcomes.get("consume_item_ids", []))
		if outcomes.has("pressure"):
			action["pressure"] = outcomes.get("pressure", {})
		if outcomes.has("result_illustration_asset"):
			action["result_illustration_asset"] = String(outcomes.get("result_illustration_asset", ""))
		if outcomes.has("story_cutscene"):
			action["story_cutscene"] = outcomes.get("story_cutscene", {})
		if outcomes.has("consume_on_use"):
			action["consume_on_use"] = bool(outcomes.get("consume_on_use", false))

	return action


func _option_is_available(action: Dictionary, event_state: Dictionary, run_state = null) -> bool:
	var requirements: Dictionary = action.get("requirements", {})
	if typeof(requirements) != TYPE_DICTIONARY or requirements.is_empty():
		return true

	return _requirements_are_met(requirements, event_state, run_state)


func _option_is_forbidden_by_state(action: Dictionary, event_state: Dictionary) -> bool:
	var requirements: Dictionary = action.get("requirements", {})
	if typeof(requirements) != TYPE_DICTIONARY or requirements.is_empty():
		return false
	return _requirements_contain_any_ids(requirements.get("forbidden_flag_ids", []), event_state.get("zone_flags", {}))


func _zone_is_accessible(zone: Dictionary, event_state: Dictionary, run_state = null) -> bool:
	var requirements: Dictionary = zone.get("access_requirements", {})
	if typeof(requirements) != TYPE_DICTIONARY or requirements.is_empty():
		return true

	return _requirements_are_met(requirements, event_state, run_state)


func _requirements_are_met(requirements: Dictionary, event_state: Dictionary, run_state = null) -> bool:
	if _requirements_contain_any_ids(requirements.get("forbidden_flag_ids", []), event_state.get("zone_flags", {})):
		return false

	if not _requirements_contain_ids(requirements.get("required_flag_ids", []), event_state.get("zone_flags", {})):
		return false

	if not _requirements_contain_ids(requirements.get("required_clue_ids", []), event_state.get("revealed_clue_ids", [])):
		return false

	if not _requirements_contain_ids(requirements.get("required_unlocked_zone_ids", []), event_state.get("unlocked_zone_ids", [])):
		return false

	if not _inventory_contains_ids(run_state, requirements.get("required_item_ids", [])):
		return false

	if not _any_requirement_block_is_met(requirements.get("any_of", []), event_state, run_state):
		return false

	return true


func _any_requirement_block_is_met(requirement_blocks, event_state: Dictionary, run_state = null) -> bool:
	if typeof(requirement_blocks) != TYPE_ARRAY:
		return true
	if requirement_blocks.is_empty():
		return true

	for block_variant in requirement_blocks:
		if typeof(block_variant) != TYPE_DICTIONARY:
			continue
		var block := block_variant as Dictionary
		if _requirements_are_met(block, event_state, run_state):
			return true

	return false


func _requirements_contain_any_ids(blocked_ids, source_values) -> bool:
	var blocked := _string_id_array(blocked_ids)
	if blocked.is_empty():
		return false

	var source_lookup := {}
	for value in source_values:
		source_lookup[String(value)] = true

	for blocked_id in blocked:
		if source_lookup.has(blocked_id):
			return true
	return false


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
	var inventory = _run_inventory(run_state)
	if inventory == null:
		return false

	var inventory_lookup := {}
	for item_variant in inventory.items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item := item_variant as Dictionary
		inventory_lookup[String(item.get("id", ""))] = true

	for required_id in required:
		if not inventory_lookup.has(required_id):
			return false
	return true


func _consume_action_items(run_state, action: Dictionary) -> bool:
	var consume_item_ids := _string_id_array(action.get("consume_item_ids", []))
	if consume_item_ids.is_empty():
		return true
	var inventory = _run_inventory(run_state)
	if inventory == null:
		return false

	var removed_items: Array[Dictionary] = []
	for item_id in consume_item_ids:
		var removed_item: Dictionary = inventory.take_first_item_by_id(item_id)
		if removed_item.is_empty():
			if inventory.has_method("restore_items"):
				inventory.restore_items(removed_items)
			return false
		removed_items.append(removed_item)
	return true


func _run_inventory(run_state):
	if run_state == null:
		return null
	if not (run_state is Object):
		return null
	return run_state.get("inventory")


func _apply_action_outcomes(event_state: Dictionary, action: Dictionary) -> void:
	var result_illustration_asset := String(action.get("result_illustration_asset", ""))
	if not result_illustration_asset.is_empty():
		event_state["last_illustration_asset"] = result_illustration_asset

	var story_cutscene_variant: Variant = action.get("story_cutscene", {})
	if typeof(story_cutscene_variant) == TYPE_DICTIONARY:
		var story_cutscene := story_cutscene_variant as Dictionary
		var story_cutscene_asset := String(story_cutscene.get("asset", ""))
		if not story_cutscene_asset.is_empty():
			event_state["pending_story_cutscene"] = {
				"asset": story_cutscene_asset,
				"title": String(story_cutscene.get("title", action.get("label", ""))),
				"text": String(story_cutscene.get("text", event_state.get("last_feedback_message", ""))),
				"button": String(story_cutscene.get("button", "계속")),
			}

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


func _apply_action_pressure(run_state, event_state: Dictionary, action: Dictionary) -> void:
	var pressure_variant: Variant = action.get("pressure", {})
	if typeof(pressure_variant) != TYPE_DICTIONARY:
		return

	var pressure := (pressure_variant as Dictionary).duplicate(true)
	if pressure.is_empty():
		return

	var pressure_id := String(pressure.get("id", ""))
	var repeatable := bool(pressure.get("repeatable", false))
	var spent_pressure_ids := _string_id_array(event_state.get("spent_pressure_ids", []))
	if not repeatable and not pressure_id.is_empty() and spent_pressure_ids.has(pressure_id):
		return

	var extra_noise := int(pressure.get("noise", 0))
	if extra_noise != 0:
		event_state["noise"] = int(event_state.get("noise", 0)) + extra_noise

	if run_state != null and run_state.has_method("apply_indoor_pressure"):
		run_state.apply_indoor_pressure(pressure)

	if not repeatable and not pressure_id.is_empty():
		spent_pressure_ids.append(pressure_id)
		event_state["spent_pressure_ids"] = spent_pressure_ids

	var message := String(pressure.get("message", ""))
	if message.is_empty():
		return

	event_state["last_pressure_message"] = message
	_append_feedback_message(event_state, message)


func _apply_noise_escalation(run_state, event_state: Dictionary) -> void:
	var noise := int(event_state.get("noise", 0))
	if noise <= 0:
		return

	var resolved_threshold_ids := _string_id_array(event_state.get("resolved_noise_threshold_ids", []))
	for step_variant in NOISE_ESCALATION_STEPS:
		var step := step_variant as Dictionary
		var threshold_id := String(step.get("id", ""))
		if threshold_id.is_empty() or resolved_threshold_ids.has(threshold_id):
			continue
		if noise < int(step.get("threshold", 0)):
			continue

		if run_state != null and run_state.has_method("apply_indoor_pressure"):
			run_state.apply_indoor_pressure(step)
		resolved_threshold_ids.append(threshold_id)
		event_state["resolved_noise_threshold_ids"] = resolved_threshold_ids
		var message := String(step.get("message", ""))
		event_state["last_noise_message"] = message
		_append_feedback_message(event_state, message)
		return


func _append_feedback_message(event_state: Dictionary, message: String) -> void:
	if message.is_empty():
		return
	var feedback_message := String(event_state.get("last_feedback_message", ""))
	event_state["last_feedback_message"] = message if feedback_message.is_empty() else "%s %s" % [feedback_message, message]


func _resolve_discovered_loot(event_data: Dictionary, event_state: Dictionary, action: Dictionary, run_state = null) -> Array[Dictionary]:
	var discovered_loot := _normalized_loot_array(action.get("discover_loot", []))
	var loot_table_variant: Variant = action.get("loot_table", {})
	if typeof(loot_table_variant) != TYPE_DICTIONARY:
		return discovered_loot

	discovered_loot.append_array(_roll_loot_table(event_data, event_state, action, loot_table_variant as Dictionary, run_state))
	return discovered_loot


func _roll_loot_table(event_data: Dictionary, event_state: Dictionary, action: Dictionary, loot_table: Dictionary, run_state = null) -> Array[Dictionary]:
	var entries_variant: Variant = loot_table.get("entries", [])
	if typeof(entries_variant) != TYPE_ARRAY:
		return []

	var available_entries: Array[Dictionary] = []
	for entry_variant in entries_variant:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry := entry_variant as Dictionary
		if String(entry.get("id", "")).is_empty():
			continue
		available_entries.append(entry.duplicate(true))
	available_entries.append_array(_contextual_loot_profile_entries(event_data, loot_table))

	if available_entries.is_empty():
		return []

	var roll_count: int = max(0, int(loot_table.get("rolls", 0)))
	if roll_count <= 0:
		return []

	var rng := RandomNumberGenerator.new()
	rng.seed = _loot_roll_seed(event_data, event_state, action, run_state)
	var allow_duplicates := bool(loot_table.get("allow_duplicates", false))
	var rolled_loot: Array[Dictionary] = []
	for _roll_index in range(roll_count):
		if available_entries.is_empty():
			break
		var picked_index := _pick_weighted_entry_index(rng, available_entries)
		if picked_index < 0 or picked_index >= available_entries.size():
			break

		var picked_entry: Dictionary = available_entries[picked_index]
		var picked_count: int = max(1, int(picked_entry.get("count", 1)))
		for _count_index in range(picked_count):
			var loot_entry := _loot_entry_from_table(picked_entry)
			if not loot_entry.is_empty():
				rolled_loot.append(loot_entry)

		if not allow_duplicates:
			available_entries.remove_at(picked_index)

	return rolled_loot


func _contextual_loot_profile_entries(event_data: Dictionary, loot_table: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if not bool(loot_table.get("include_contextual_profile", true)):
		return rows
	if ContentLibrary == null or not ContentLibrary.has_method("get_loot_profile_entries"):
		return rows
	var contextual_weight_scale := maxf(0.0, float(loot_table.get("contextual_profile_weight_scale", 0.025)))
	if contextual_weight_scale <= 0.0:
		return rows

	var existing_ids := {}
	var entries_variant: Variant = loot_table.get("entries", [])
	if typeof(entries_variant) == TYPE_ARRAY:
		for entry_variant in entries_variant:
			if typeof(entry_variant) != TYPE_DICTIONARY:
				continue
			var entry_id := String((entry_variant as Dictionary).get("id", ""))
			if not entry_id.is_empty():
				existing_ids[entry_id] = true

	for profile_entry in ContentLibrary.get_loot_profile_entries(String(event_data.get("id", ""))):
		var item_id := String(profile_entry.get("id", ""))
		if item_id.is_empty() or existing_ids.has(item_id):
			continue
		existing_ids[item_id] = true
		var row := profile_entry.duplicate(true)
		row["weight"] = maxf(0.0, float(row.get("weight", 1.0))) * contextual_weight_scale
		if float(row["weight"]) > 0.0:
			rows.append(row)
	return rows


func _loot_roll_seed(event_data: Dictionary, event_state: Dictionary, action: Dictionary, run_state = null) -> int:
	var site_id := String(event_data.get("id", "indoor_site"))
	var zone_id := String(action.get("zone_id", event_state.get("current_zone_id", "")))
	var action_id := String(action.get("id", "indoor_action"))
	if run_state != null and run_state.has_method("get_loot_roll_seed"):
		return int(run_state.get_loot_roll_seed(site_id, zone_id, action_id))
	return abs(hash("%s|%s|%s" % [site_id, zone_id, action_id]))


func _pick_weighted_entry_index(rng: RandomNumberGenerator, entries: Array[Dictionary]) -> int:
	var total_weight := 0.0
	for entry in entries:
		total_weight += max(0.0, float(entry.get("weight", 1.0)))
	if total_weight <= 0.0:
		return -1

	var roll := rng.randf() * total_weight
	var running := 0.0
	for index in range(entries.size()):
		running += max(0.0, float(entries[index].get("weight", 1.0)))
		if roll <= running:
			return index
	return entries.size() - 1


func _loot_entry_from_table(entry: Dictionary) -> Dictionary:
	var item_id := String(entry.get("id", ""))
	if item_id.is_empty():
		return {}

	var base_item: Dictionary = {}
	if ContentLibrary != null and ContentLibrary.has_method("get_item"):
		base_item = ContentLibrary.get_item(item_id)

	var loot := base_item.duplicate(true)
	for key_variant in entry.keys():
		var key := String(key_variant)
		if key == "weight" or key == "count":
			continue
		loot[key] = entry.get(key_variant)

	loot["id"] = item_id
	if String(loot.get("name", "")).is_empty():
		loot["name"] = item_id
	if int(loot.get("bulk", 0)) <= 0:
		loot["bulk"] = 1
	return loot


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
	var inventory = _run_inventory(run_state)
	var actions: Array[Dictionary] = []
	for loot_index in range(found_loot.size()):
		var loot := found_loot[loot_index]
		var loot_id := String(loot.get("id", "loot"))
		var loot_uid := int(loot.get("loot_uid", loot_index))
		var loot_label := _loot_label(loot)
		var can_add: bool = inventory != null and inventory.can_add(loot)
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
	var inventory = _run_inventory(run_state)
	if inventory == null:
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
	if not inventory.add_item(loot):
		event_state["last_feedback_message"] = "가방이 가득 차서 %s 챙기지 못한다." % _loot_label(loot)
		return true

	found_loot.remove_at(loot_index)
	_set_zone_found_loot(event_state, zone_id, found_loot)
	event_state["last_feedback_message"] = "%s 챙겼다." % _loot_label(loot)
	return true


func _get_take_supply_actions(event_state: Dictionary, run_state = null) -> Array[Dictionary]:
	var current_zone_id := String(event_state.get("current_zone_id", ""))
	if current_zone_id.is_empty():
		return []
	var inventory = _run_inventory(run_state)
	if inventory == null:
		return []

	var sources := _get_zone_supply_sources(event_state, current_zone_id)
	var actions: Array[Dictionary] = []
	for source in sources:
		var quantity_remaining := int(source.get("quantity_remaining", 0))
		if quantity_remaining <= 0:
			continue
		var item := _supply_item_entry(source)
		if item.is_empty():
			continue
		var legal_max := _max_pickup_quantity_for_supply(run_state, item, quantity_remaining)
		var source_id := String(source.get("id", "source"))
		var item_label := _loot_label(item)
		var common_fields := {
			"type": "take_supply",
			"zone_id": current_zone_id,
			"source_id": source_id,
			"item_id": String(item.get("id", "")),
			"item_name": item_label,
			"quantity_remaining": quantity_remaining,
			"max_quantity": legal_max,
			"locked": legal_max <= 0,
			"blocked_feedback": "더는 %s 챙길 여유가 없다." % item_label,
		}
		for requested_quantity in [1, 3]:
			if requested_quantity > quantity_remaining:
				continue
			var action := common_fields.duplicate(true)
			action.merge({
				"id": "take_supply_%s_%s_%d" % [current_zone_id, source_id, requested_quantity],
				"label": "%s %d개 챙긴다" % [item_label, requested_quantity],
				"requested_quantity": requested_quantity,
			}, true)
			actions.append(action)
		var max_action := common_fields.duplicate(true)
		max_action.merge({
			"id": "take_supply_%s_%s_max" % [current_zone_id, source_id],
			"label": "%s 최대한 챙긴다" % item_label,
			"requested_quantity": -1,
		}, true)
		actions.append(max_action)
		var detail_action := common_fields.duplicate(true)
		detail_action.merge({
			"id": "take_supply_%s_%s_detail" % [current_zone_id, source_id],
			"type": "take_supply_detail",
			"label": "%s 수량을 정한다" % item_label,
			"requested_quantity": 1,
		}, true)
		actions.append(detail_action)

	return actions


func _get_take_supply_action(event_state: Dictionary, action_id: String, run_state = null) -> Dictionary:
	for action in _get_take_supply_actions(event_state, run_state):
		if String(action.get("id", "")) == action_id:
			return action
	return {}


func _apply_take_supply_action(run_state, event_state: Dictionary, action: Dictionary) -> bool:
	var inventory = _run_inventory(run_state)
	if inventory == null:
		return false
	if bool(action.get("locked", false)):
		event_state["last_feedback_message"] = String(action.get("blocked_feedback", "더는 챙길 여유가 없다."))
		return true

	var zone_id := String(action.get("zone_id", ""))
	var source_id := String(action.get("source_id", ""))
	var sources := _get_zone_supply_sources(event_state, zone_id)
	var source_index := _find_supply_source_index(sources, source_id)
	if source_index < 0:
		return false

	var source := sources[source_index]
	var item := _supply_item_entry(source)
	if item.is_empty():
		return false

	var quantity_remaining := int(source.get("quantity_remaining", 0))
	var legal_max := _max_pickup_quantity_for_supply(run_state, item, quantity_remaining)
	if legal_max <= 0:
		event_state["last_feedback_message"] = "더는 %s 챙길 여유가 없다." % _loot_label(item)
		return true

	var requested_quantity := int(action.get("requested_quantity", 1))
	var quantity_to_take: int = legal_max if requested_quantity < 0 else min(requested_quantity, legal_max, quantity_remaining)
	if quantity_to_take <= 0:
		event_state["last_feedback_message"] = "더는 %s 챙길 여유가 없다." % _loot_label(item)
		return true

	for _index in range(quantity_to_take):
		if not inventory.add_item(item):
			break

	source["quantity_remaining"] = quantity_remaining - quantity_to_take
	sources[source_index] = source
	_set_zone_supply_sources(event_state, zone_id, sources)
	event_state["last_feedback_message"] = "%s %d개 챙겼다." % [_loot_label(item), quantity_to_take]
	return true


func apply_supply_pickup(run_state, event_state: Dictionary, zone_id: String, source_id: String, quantity: int) -> bool:
	if quantity <= 0:
		return false
	return _apply_take_supply_action(run_state, event_state, {
		"zone_id": zone_id,
		"source_id": source_id,
		"requested_quantity": quantity,
		"locked": false,
	})


func _get_zone_found_loot(event_state: Dictionary, zone_id: String) -> Array[Dictionary]:
	var all_found_loot: Dictionary = event_state.get("zone_loot_entries", {})
	if typeof(all_found_loot) != TYPE_DICTIONARY:
		return []
	return _dictionary_loot_array(all_found_loot.get(zone_id, []))


func _append_zone_found_loot(event_state: Dictionary, zone_id: String, discovered_loot: Array[Dictionary]) -> void:
	if zone_id.is_empty():
		return

	var all_found_loot: Dictionary = event_state.get("zone_loot_entries", {})
	if typeof(all_found_loot) != TYPE_DICTIONARY:
		all_found_loot = {}

	var existing_loot := _dictionary_loot_array(all_found_loot.get(zone_id, []))
	for loot in discovered_loot:
		var loot_entry := loot.duplicate(true)
		if int(loot_entry.get("loot_uid", -1)) < 0:
			loot_entry["loot_uid"] = _consume_loot_uid(event_state)
		existing_loot.append(loot_entry)
	all_found_loot[zone_id] = existing_loot
	event_state["zone_loot_entries"] = all_found_loot


func _set_zone_found_loot(event_state: Dictionary, zone_id: String, found_loot: Array[Dictionary]) -> void:
	var all_found_loot: Dictionary = event_state.get("zone_loot_entries", {})
	if typeof(all_found_loot) != TYPE_DICTIONARY:
		all_found_loot = {}
	all_found_loot[zone_id] = found_loot
	event_state["zone_loot_entries"] = all_found_loot


func _get_zone_supply_sources(event_state: Dictionary, zone_id: String) -> Array[Dictionary]:
	var all_supply_sources: Dictionary = event_state.get("zone_supply_sources", {})
	if typeof(all_supply_sources) != TYPE_DICTIONARY:
		return []
	return _dictionary_loot_array(all_supply_sources.get(zone_id, []))


func _append_zone_supply_sources(event_state: Dictionary, zone_id: String, discovered_supply_sources: Array[Dictionary]) -> void:
	if zone_id.is_empty() or discovered_supply_sources.is_empty():
		return

	var all_supply_sources: Dictionary = event_state.get("zone_supply_sources", {})
	if typeof(all_supply_sources) != TYPE_DICTIONARY:
		all_supply_sources = {}

	var existing_sources := _dictionary_loot_array(all_supply_sources.get(zone_id, []))
	for source in discovered_supply_sources:
		var source_id := String(source.get("id", ""))
		if source_id.is_empty():
			continue
		if _find_supply_source_index(existing_sources, source_id) >= 0:
			continue
		existing_sources.append(source.duplicate(true))
	all_supply_sources[zone_id] = existing_sources
	event_state["zone_supply_sources"] = all_supply_sources


func _set_zone_supply_sources(event_state: Dictionary, zone_id: String, supply_sources: Array[Dictionary]) -> void:
	var all_supply_sources: Dictionary = event_state.get("zone_supply_sources", {})
	if typeof(all_supply_sources) != TYPE_DICTIONARY:
		all_supply_sources = {}
	all_supply_sources[zone_id] = supply_sources
	event_state["zone_supply_sources"] = all_supply_sources


func _find_supply_source_index(sources: Array[Dictionary], source_id: String) -> int:
	for source_index in range(sources.size()):
		if String(sources[source_index].get("id", "")) == source_id:
			return source_index
	return -1


func _supply_item_entry(source: Dictionary) -> Dictionary:
	var item_id := String(source.get("item_id", source.get("id", "")))
	if item_id.is_empty():
		return {}

	var item := _loot_entry_from_table({"id": item_id})
	if item.is_empty():
		item = {"id": item_id, "name": item_id, "bulk": 1, "carry_weight": 1.0}
	return item


func _max_pickup_quantity_for_supply(run_state, item: Dictionary, quantity_remaining: int) -> int:
	var inventory = _run_inventory(run_state)
	if inventory == null:
		return 0
	if quantity_remaining <= 0:
		return 0

	var legal_quantity := 0
	for _index in range(quantity_remaining):
		if not inventory.can_add(item):
			break
		inventory.items.append(item.duplicate(true))
		legal_quantity += 1
	for _index in range(legal_quantity):
		inventory.items.remove_at(inventory.items.size() - 1)
	return legal_quantity


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


func _normalized_loot_array(values) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var loot := value as Dictionary
		var item_id := String(loot.get("id", ""))
		if item_id.is_empty():
			result.append(loot.duplicate(true))
			continue
		result.append(_loot_entry_from_table(loot))
	return result


func _normalize_supply_sources_array(values) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var source := (value as Dictionary).duplicate(true)
		var source_id := String(source.get("id", ""))
		var item_id := String(source.get("item_id", source_id))
		var quantity: int = max(0, int(source.get("quantity_remaining", source.get("quantity", 0))))
		if source_id.is_empty() or item_id.is_empty() or quantity <= 0:
			continue
		source["id"] = source_id
		source["item_id"] = item_id
		source["quantity"] = quantity
		source["quantity_remaining"] = quantity
		result.append(source)
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
