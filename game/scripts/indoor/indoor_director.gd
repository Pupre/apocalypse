extends Node

signal state_changed

const ACTION_RESOLVER_SCRIPT := preload("res://scripts/indoor/indoor_action_resolver.gd")
const SURVIVAL_CHIP_ICON_PATHS := {
	"hunger": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/question.png",
	"thirst": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/basket.png",
	"health": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/home.png",
	"fatigue": "res://assets/ui/third_party/kenney/game-icons/PNG/White/1x/locked.png",
}
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


func get_survival_chip_rows() -> Array[Dictionary]:
	if _run_state == null:
		return []

	return [
		_create_survival_chip_row(
			"hunger",
			"허기",
			_run_state.get_hunger_stage(),
			float(_run_state.hunger),
			"0이 되면 체력이 계속 감소한다",
			"음식으로 회복",
			"hunger",
			"%s / %s · %s" % [str(_run_state.hunger), str(_run_state.MAX_SURVIVAL_VALUE), _run_state.get_hunger_stage()]
		),
		_create_survival_chip_row(
			"thirst",
			"갈증",
			_run_state.get_thirst_stage(),
			float(_run_state.thirst),
			"허기보다 더 빠르게 바닥난다",
			"물과 음료로 회복",
			"thirst",
			"%s / %s · %s" % [str(_run_state.thirst), str(_run_state.MAX_SURVIVAL_VALUE), _run_state.get_thirst_stage()]
		),
		_create_survival_chip_row(
			"health",
			"체력",
			_run_state.get_health_stage(),
			float(_run_state.health),
			"부상과 위기로 줄어든다",
			"의약품으로 회복",
			"health",
			"%s / %s · %s" % [str(_run_state.health), str(_run_state.MAX_SURVIVAL_VALUE), _run_state.get_health_stage()]
		),
		_create_survival_chip_row(
			"fatigue",
			"피로",
			_run_state.get_fatigue_stage(),
			float(_run_state.fatigue),
			"시간과 행동으로 쌓인다",
			"휴식과 취침으로 회복",
			"fatigue",
			"%s · %s" % [str(_run_state.fatigue), _run_state.get_fatigue_stage()]
		),
	]


func get_survival_chip_detail(chip_id: String) -> Dictionary:
	for chip in get_survival_chip_rows():
		if String(chip.get("id", "")) == chip_id:
			return chip

	return {}


func get_survival_chip_icon_path(chip_id: String) -> String:
	return String(SURVIVAL_CHIP_ICON_PATHS.get(chip_id, ""))


func _create_survival_chip_row(
	chip_id: String,
	label: String,
	stage: String,
	value: float,
	rule_text: String,
	recovery_text: String,
	icon_id: String,
	detail_value_text: String
) -> Dictionary:
	return {
		"id": chip_id,
		"label": label,
		"stage": stage,
		"value": value,
		"display_value_text": stage,
		"detail_value_text": detail_value_text,
		"icon_id": icon_id,
		"rule_text": rule_text,
		"recovery_text": recovery_text,
	}


func get_sleep_preview() -> Dictionary:
	return _resolver.get_sleep_preview(_run_state)


func get_feedback_message() -> String:
	return String(_event_state.get("last_feedback_message", ""))


func get_inventory_entries() -> Array[String]:
	var entries: Array[String] = []
	for row in get_inventory_rows():
		entries.append(String(row.get("label", "")))
	return entries


func get_inventory_title() -> String:
	if _run_state == null or _run_state.inventory == null:
		return "소지품 (0/0)"

	return "소지품 (%d/%d)" % [_run_state.inventory.total_bulk(), _run_state.inventory.carry_limit]


func get_inventory_status_text() -> String:
	if _run_state == null or _run_state.inventory == null:
		return ""

	var total_bulk: int = _run_state.inventory.total_bulk()
	var carry_limit: int = _run_state.inventory.carry_limit
	if total_bulk < carry_limit:
		return "여유 있음"
	if total_bulk == carry_limit:
		return "가방이 가득 찼다"
	if not _run_state.has_method("get_outdoor_move_speed") or _run_state.move_speed <= 0.0:
		return "과적"

	var speed_ratio := float(_run_state.get_outdoor_move_speed()) / float(_run_state.move_speed)
	return "과적: 실외 이동속도 %d%%" % int(round(speed_ratio * 100.0))


func get_inventory_rows() -> Array[Dictionary]:
	if _run_state == null or _run_state.inventory == null:
		return [{"label": "소지품 없음", "action_id": ""}]

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
		return [{"label": "소지품 없음", "action_id": ""}]

	for item_id in order:
		var item_data := _item_definition(item_id)
		rows.append({
			"label": "%s x%d" % [_item_name(item_data, item_id), int(counts[item_id])],
			"action_id": "inspect_inventory_%s" % item_id,
		})

	return rows


func get_equipped_rows() -> Array[String]:
	if _run_state == null:
		var empty_rows: Array[String] = ["장착중인 장비 없음"]
		return empty_rows

	var slot_order := ["back", "body", "feet", "hands"]
	var rows: Array[String] = []
	for slot_id in slot_order:
		var equipped_item: Dictionary = _run_state.equipped_items.get(slot_id, {})
		if equipped_item.is_empty():
			continue
		rows.append("%s: %s" % [_slot_label(slot_id), _item_name(equipped_item, slot_id)])

	if rows.is_empty():
		var fallback_rows: Array[String] = ["장착중인 장비 없음"]
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
		"effect_text": _item_effect_text(item_data),
		"actions": _inventory_sheet_actions(item_data, _selected_inventory_item_id),
	}


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
		_selected_inventory_item_id = ""
		_event_state["last_feedback_message"] = "%s 버렸다." % _item_name(dropped_item, drop_item_id)
		state_changed.emit()
		return true

	if action_id.begins_with("consume_inventory_"):
		var consume_item_id := action_id.trim_prefix("consume_inventory_")
		var consume_item_data: Dictionary = _item_definition(consume_item_id)
		if consume_item_data.is_empty() or _run_state == null or not _run_state.has_method("consume_inventory_item"):
			return false
		var use_minutes := int(consume_item_data.get("use_minutes", 0))
		if use_minutes > 0 and _run_state.has_method("get_indoor_action_minutes"):
			use_minutes = int(_run_state.get_indoor_action_minutes(use_minutes))
		if use_minutes > 0 and _run_state.has_method("advance_minutes"):
			_run_state.advance_minutes(use_minutes)
		if not _run_state.consume_inventory_item(consume_item_id, consume_item_data):
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
		"next_loot_uid": 0,
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


func _item_definition(item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}

	if ContentLibrary != null and ContentLibrary.has_method("get_item"):
		var item_data: Variant = ContentLibrary.get_item(item_id)
		if typeof(item_data) == TYPE_DICTIONARY and not (item_data as Dictionary).is_empty():
			return item_data

	if _run_state != null and _run_state.inventory != null:
		for item_variant in _run_state.inventory.items:
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue
			var item := item_variant as Dictionary
			if String(item.get("id", "")) == item_id:
				return item

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
	var carry_limit_bonus := int(item_data.get("carry_limit_bonus", 0))
	if carry_limit_bonus > 0:
		parts.append("소지 한도 +%d" % carry_limit_bonus)
	var move_speed_bonus := int(item_data.get("move_speed_bonus", 0))
	if move_speed_bonus > 0:
		parts.append("이동속도 +%d" % move_speed_bonus)
	var fatigue_gain_bonus := float(item_data.get("fatigue_gain_bonus", 0.0))
	if fatigue_gain_bonus < 0.0:
		parts.append("피로 누적 -%d%%" % int(round(abs(fatigue_gain_bonus) * 100.0)))
	var equip_slot := String(item_data.get("equip_slot", ""))
	if not equip_slot.is_empty():
		parts.append("장착 슬롯: %s" % _slot_label(equip_slot))
	var use_minutes := int(item_data.get("use_minutes", 0))
	if use_minutes > 0:
		parts.append("소요 시간 %d분" % use_minutes)

	return "효과 없음" if parts.is_empty() else " / ".join(parts)


func _inventory_sheet_actions(item_data: Dictionary, item_id: String) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
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
		"hands":
			return "손"
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
