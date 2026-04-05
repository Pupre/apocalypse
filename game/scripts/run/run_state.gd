extends RefCounted
class_name RunState

const TIME_CLOCK_SCRIPT := preload("res://scripts/run/time_clock.gd")
const FATIGUE_MODEL_SCRIPT := preload("res://scripts/run/fatigue_model.gd")
const INVENTORY_MODEL_SCRIPT := preload("res://scripts/run/inventory_model.gd")
const CRAFTING_RESOLVER_SCRIPT := preload("res://scripts/crafting/crafting_resolver.gd")
const WARMTH_MODEL_SCRIPT := preload("res://scripts/run/warmth_model.gd")

const BASE_MOVE_SPEED := 160.0
const BASE_FATIGUE_GAIN_MULTIPLIER := 1.0
const FATIGUE_GAIN_PER_MINUTE := 1.0 / 30.0
const HUNGER_DECAY_PER_MINUTE := 1.0 / 60.0
const THIRST_DECAY_PER_MINUTE := 1.0 / 40.0
const OUTDOOR_HUNGER_MULTIPLIER := 1.2
const OUTDOOR_THIRST_MULTIPLIER := 1.75
const OUTDOOR_FATIGUE_MULTIPLIER := 1.35
const SLEEP_HUNGER_MULTIPLIER := 0.45
const SLEEP_THIRST_MULTIPLIER := 0.55
const REST_HUNGER_MULTIPLIER := 0.75
const REST_THIRST_MULTIPLIER := 0.8
const STARVATION_HEALTH_LOSS_PER_MINUTE := 1.0 / 30.0
const DEHYDRATION_HEALTH_LOSS_PER_MINUTE := 1.0 / 15.0
const REST_FATIGUE_RECOVERY_PER_MINUTE := 1.0 / 10.0
const SLEEP_FATIGUE_RECOVERY_PER_MINUTE := 1.0 / 4.5
const MAX_SURVIVAL_VALUE := 100.0
const BASE_CARRY_LIMIT := 8
const MIN_OVERLOADED_MOVE_MULTIPLIER := 0.45
const OVERFLOW_MOVE_PENALTY_PER_BULK := 0.12

var clock = TIME_CLOCK_SCRIPT.new()
var fatigue_model = FATIGUE_MODEL_SCRIPT.new()
var inventory = INVENTORY_MODEL_SCRIPT.new()
var crafting_resolver = CRAFTING_RESOLVER_SCRIPT.new()
var warmth_model = WARMTH_MODEL_SCRIPT.new()
var survivor_config: Dictionary = {}
var equipped_items: Dictionary = {}
var active_warmth_effects: Array[Dictionary] = []
var indoor_site_memories: Dictionary = {}
var current_indoor_building_id := ""
var current_indoor_zone_id := ""
var world_seed: int = 0
var fatigue: float = 0.0
var hunger: float = MAX_SURVIVAL_VALUE
var thirst: float = MAX_SURVIVAL_VALUE
var health: float = 100.0
var exposure: float = 100.0
var move_speed: float = BASE_MOVE_SPEED
var fatigue_gain_multiplier: float = BASE_FATIGUE_GAIN_MULTIPLIER
var base_carry_limit: int = BASE_CARRY_LIMIT
var _base_move_speed: float = BASE_MOVE_SPEED
var _base_fatigue_gain_multiplier: float = BASE_FATIGUE_GAIN_MULTIPLIER
var _content_source = null
var _report_validation_errors := true


static func from_survivor_config(config: Dictionary, content_source = null, report_validation_errors: bool = true):
	var state = new()
	state.set_content_source(content_source)
	state.set_validation_reporting(report_validation_errors)
	if not state._validate_survivor_config(config):
		return null

	state._apply_survivor_config(config)
	return state


func advance_minutes(amount: int, context: String = "indoor") -> void:
	if amount < 0:
		return

	clock.advance_minutes(amount)
	_tick_warmth_effects(amount)
	var fatigue_multiplier := 1.0
	var hunger_multiplier := 1.0
	var thirst_multiplier := 1.0
	if context == "outdoor":
		fatigue_multiplier = OUTDOOR_FATIGUE_MULTIPLIER
		hunger_multiplier = OUTDOOR_HUNGER_MULTIPLIER
		thirst_multiplier = OUTDOOR_THIRST_MULTIPLIER

	fatigue += float(amount) * FATIGUE_GAIN_PER_MINUTE * fatigue_gain_multiplier * fatigue_multiplier
	hunger = max(0.0, hunger - (float(amount) * HUNGER_DECAY_PER_MINUTE * hunger_multiplier))
	thirst = max(0.0, thirst - (float(amount) * THIRST_DECAY_PER_MINUTE * thirst_multiplier))
	_apply_survival_damage(amount)


func advance_sleep_time(minutes: int) -> void:
	if minutes < 0:
		return

	clock.advance_minutes(minutes)
	_tick_warmth_effects(minutes)
	hunger = max(0.0, hunger - (float(minutes) * HUNGER_DECAY_PER_MINUTE * SLEEP_HUNGER_MULTIPLIER))
	thirst = max(0.0, thirst - (float(minutes) * THIRST_DECAY_PER_MINUTE * SLEEP_THIRST_MULTIPLIER))
	fatigue = max(0.0, fatigue - (float(minutes) * SLEEP_FATIGUE_RECOVERY_PER_MINUTE))
	_apply_survival_damage(minutes)


func advance_rest_time(minutes: int) -> void:
	if minutes < 0:
		return

	clock.advance_minutes(minutes)
	_tick_warmth_effects(minutes)
	hunger = max(0.0, hunger - (float(minutes) * HUNGER_DECAY_PER_MINUTE * REST_HUNGER_MULTIPLIER))
	thirst = max(0.0, thirst - (float(minutes) * THIRST_DECAY_PER_MINUTE * REST_THIRST_MULTIPLIER))
	fatigue = max(0.0, fatigue - (float(minutes) * REST_FATIGUE_RECOVERY_PER_MINUTE))
	_apply_survival_damage(minutes)


func get_sleep_preview() -> Dictionary:
	return fatigue_model.get_sleep_preview(fatigue, _sleep_hours_adjustment())


func is_dead() -> bool:
	return health <= 0.0 or exposure <= 0.0


func get_hunger_stage() -> String:
	if hunger <= 0.0:
		return "기아"
	if hunger <= 25.0:
		return "굶주림"
	if hunger <= 50.0:
		return "허기짐"
	if hunger <= 75.0:
		return "보통"
	return "든든함"


func get_thirst_stage() -> String:
	if thirst <= 0.0:
		return "탈수"
	if thirst <= 25.0:
		return "탈수 직전"
	if thirst <= 50.0:
		return "목마름"
	if thirst <= 75.0:
		return "보통"
	return "수분 충분"


func get_health_stage() -> String:
	if health <= 0.0:
		return "사망"
	if health <= 35.0:
		return "위독"
	if health <= 70.0:
		return "부상"
	return "안정"


func get_fatigue_stage() -> String:
	return fatigue_model.get_band(fatigue)


func get_indoor_action_minutes(base_minutes: int) -> int:
	if base_minutes <= 0:
		return 0

	var multiplier := 1.0
	if fatigue >= 75.0:
		multiplier = 1.5
	elif fatigue >= 55.0:
		multiplier = 1.3
	elif fatigue >= 35.0:
		multiplier = 1.15
	return int(ceili(float(base_minutes) * multiplier))


func _apply_survivor_config(config: Dictionary) -> void:
	survivor_config = config.duplicate(true)
	equipped_items = {}
	move_speed = BASE_MOVE_SPEED
	fatigue_gain_multiplier = BASE_FATIGUE_GAIN_MULTIPLIER
	world_seed = int(survivor_config.get("world_seed", 0))
	if world_seed == 0:
		world_seed = int(Time.get_unix_time_from_system())

	var carry_limit_bonus := 0
	carry_limit_bonus += _apply_job_modifiers(String(survivor_config.get("job_id", "")))

	for trait_id_variant in survivor_config.get("trait_ids", []):
		carry_limit_bonus += _apply_trait_modifiers(String(trait_id_variant))

	_base_move_speed = move_speed
	_base_fatigue_gain_multiplier = fatigue_gain_multiplier
	base_carry_limit = BASE_CARRY_LIMIT + carry_limit_bonus
	_recalculate_derived_stats()


func consume_inventory_item(item_id: String, item_data: Dictionary) -> bool:
	if item_id.is_empty():
		return false

	var removed_item := inventory.take_first_item_by_id(item_id)
	if removed_item.is_empty():
		return false

	hunger = min(MAX_SURVIVAL_VALUE, hunger + float(item_data.get("hunger_restore", 0.0)))
	thirst = min(MAX_SURVIVAL_VALUE, thirst + float(item_data.get("thirst_restore", 0.0)))
	health = min(MAX_SURVIVAL_VALUE, health + float(item_data.get("health_restore", 0.0)))
	fatigue = max(0.0, fatigue - float(item_data.get("fatigue_restore", 0.0)))
	return true


func use_inventory_item(item_id: String) -> bool:
	if item_id.is_empty():
		return false

	var item_data: Dictionary = _lookup_item_data(item_id)
	if item_data.is_empty():
		return false

	var combined_use_effects := _combined_use_effects(item_data)
	if not _has_any_use_effect(combined_use_effects):
		return false

	var removed_item := inventory.take_first_item_by_id(item_id)
	if removed_item.is_empty():
		return false

	hunger = min(MAX_SURVIVAL_VALUE, hunger + float(combined_use_effects.get("hunger_restore", 0.0)))
	health = min(MAX_SURVIVAL_VALUE, health + float(combined_use_effects.get("health_restore", 0.0)))
	var applied := warmth_model.apply_use_effects(exposure, thirst, fatigue, combined_use_effects)
	exposure = min(MAX_SURVIVAL_VALUE, float(applied.get("exposure", exposure)))
	thirst = min(MAX_SURVIVAL_VALUE, float(applied.get("thirst", thirst)))
	fatigue = max(0.0, float(applied.get("fatigue", fatigue)))
	var warmth_effect_variant: Variant = applied.get("warmth_effect", {})
	if typeof(warmth_effect_variant) == TYPE_DICTIONARY and not (warmth_effect_variant as Dictionary).is_empty():
		active_warmth_effects.append((warmth_effect_variant as Dictionary).duplicate(true))
	return true


func attempt_craft(primary_item_id: String, secondary_item_id: String, context: String = "indoor") -> Dictionary:
	var outcome: Dictionary = crafting_resolver.resolve(primary_item_id, secondary_item_id, context, _get_content_source())
	if String(outcome.get("result_type", "")) == "invalid":
		_apply_crafting_minutes(outcome, context)
		return outcome

	if not inventory.has_items_for_pair(primary_item_id, secondary_item_id):
		return {
			"ok": false,
			"result_type": "invalid",
			"result_item_id": "",
			"result_item_data": {},
			"result_text": "필요한 재료가 부족하다.",
			"minutes_elapsed": 0,
		}

	var ingredient_rules: Dictionary = outcome.get("ingredient_rules", {})
	var expected_removed_count := _expected_removed_item_count(primary_item_id, secondary_item_id, ingredient_rules)
	var removed_items := inventory.remove_items_by_rules(primary_item_id, secondary_item_id, ingredient_rules)
	if removed_items.size() != expected_removed_count:
		inventory.restore_items(removed_items)
		return {
			"ok": false,
			"result_type": "invalid",
			"result_item_id": "",
			"result_item_data": {},
			"result_text": "재료를 꺼내는 중 문제가 생겼다.",
			"minutes_elapsed": 0,
		}

	var result_items: Array = outcome.get("result_items", [])
	var added_result_item_ids: Array[String] = []
	for result_item_variant in result_items:
		if typeof(result_item_variant) != TYPE_DICTIONARY:
			continue
		var result_item := result_item_variant as Dictionary
		var result_item_id := String(result_item.get("id", ""))
		var result_count: int = max(1, int(result_item.get("count", 1)))
		var item_data: Dictionary = _get_content_source().get_item(result_item_id)
		var merged_item: Dictionary = _merge_item_data(item_data, {"id": result_item_id, "bulk": int(item_data.get("bulk", 1))})
		for _index in range(result_count):
			if not inventory.add_item(merged_item):
				_remove_crafted_result_items(added_result_item_ids)
				inventory.restore_items(removed_items)
				return {
					"ok": false,
					"result_type": "invalid",
					"result_item_id": "",
					"result_item_data": {},
					"result_text": "결과물을 담을 공간이 부족하다.",
					"minutes_elapsed": 0,
				}
			added_result_item_ids.append(result_item_id)

	_apply_crafting_minutes(outcome, context)
	return outcome


func equip_inventory_item(item_id: String, item_data: Dictionary) -> Dictionary:
	var result := {
		"ok": false,
		"message": "",
		"replaced_item": {},
	}

	var equip_slot := String(item_data.get("equip_slot", ""))
	if equip_slot.is_empty():
		result["message"] = "지금은 장착할 수 없는 아이템이다."
		return result

	var removed_item := inventory.take_first_item_by_id(item_id)
	if removed_item.is_empty():
		result["message"] = "장착할 아이템을 찾지 못했다."
		return result

	var replaced_item: Dictionary = equipped_items.get(equip_slot, {})
	if not replaced_item.is_empty() and not inventory.add_item(replaced_item):
		inventory.add_item(removed_item)
		result["message"] = "기존 장비를 둘 공간이 없어 교체할 수 없다."
		return result

	equipped_items[equip_slot] = _merge_item_data(item_data, removed_item)
	_recalculate_derived_stats()
	result["ok"] = true
	result["replaced_item"] = replaced_item
	return result


func get_outdoor_move_speed() -> float:
	var overflow_bulk: int = inventory.overflow_bulk()
	var fatigue_multiplier := fatigue_model.outdoor_efficiency_multiplier(fatigue)
	if overflow_bulk <= 0:
		return move_speed * fatigue_multiplier

	var multiplier := float(max(
		MIN_OVERLOADED_MOVE_MULTIPLIER,
		1.0 - (float(overflow_bulk) * OVERFLOW_MOVE_PENALTY_PER_BULK)
	))
	return move_speed * multiplier * fatigue_multiplier


func deploy_item_in_current_site(item_id: String) -> bool:
	if current_indoor_building_id.is_empty() or current_indoor_zone_id.is_empty():
		return false

	var item_data: Dictionary = _lookup_item_data(item_id)
	if item_data.is_empty():
		return false

	var deploy_effects_variant: Variant = item_data.get("deploy_effects", {})
	if typeof(deploy_effects_variant) != TYPE_DICTIONARY or (deploy_effects_variant as Dictionary).is_empty():
		return false

	var removed_item := inventory.take_first_item_by_id(item_id)
	if removed_item.is_empty():
		return false

	var memory := get_or_create_site_memory(current_indoor_building_id)
	var deployments_variant: Variant = memory.get("installed_deployments", [])
	var deployments: Array = []
	if typeof(deployments_variant) == TYPE_ARRAY:
		deployments = (deployments_variant as Array).duplicate(true)

	var deployment_uid := int(memory.get("next_loot_uid", 0))
	memory["next_loot_uid"] = deployment_uid + 1
	deployments.append({
		"deployment_id": "%s_%d" % [item_id, deployment_uid],
		"item_id": item_id,
		"zone_id": current_indoor_zone_id,
		"installed_at_minute": clock.minute_of_day,
		"deploy_effects": (deploy_effects_variant as Dictionary).duplicate(true),
	})
	memory["installed_deployments"] = deployments
	return true


func get_current_indoor_environment_modifiers() -> Dictionary:
	var modifiers := {
		"indoor_heat_score": 0.0,
		"indoor_light_score": 0.0,
		"indoor_insulation_score": 0.0,
		"rest_recovery_multiplier": 1.0,
		"sleep_recovery_multiplier": 1.0,
		"indoor_action_minutes_multiplier": 1.0,
	}
	if current_indoor_building_id.is_empty():
		return modifiers

	var memory := get_or_create_site_memory(current_indoor_building_id)
	var deployments_variant: Variant = memory.get("installed_deployments", [])
	if typeof(deployments_variant) != TYPE_ARRAY:
		return modifiers

	for deployment_variant in deployments_variant:
		if typeof(deployment_variant) != TYPE_DICTIONARY:
			continue
		var deployment := deployment_variant as Dictionary
		var deploy_effects_variant: Variant = deployment.get("deploy_effects", {})
		if typeof(deploy_effects_variant) != TYPE_DICTIONARY:
			continue
		var deploy_effects := deploy_effects_variant as Dictionary
		for key_variant in deploy_effects.keys():
			var key := String(key_variant)
			var value := float(deploy_effects.get(key_variant, 0.0))
			if not modifiers.has(key):
				modifiers[key] = value
				continue
			if key.ends_with("_multiplier"):
				modifiers[key] = float(modifiers.get(key, 1.0)) * value
			else:
				modifiers[key] = float(modifiers.get(key, 0.0)) + value
	return modifiers


func get_or_create_site_memory(building_id: String, entry_zone_id: String = "") -> Dictionary:
	if building_id.is_empty():
		return {}

	if not indoor_site_memories.has(building_id):
		var visited_zone_ids := PackedStringArray()
		if not entry_zone_id.is_empty():
			visited_zone_ids.append(entry_zone_id)
		indoor_site_memories[building_id] = {
			"entry_zone_id": entry_zone_id,
			"current_zone_id": entry_zone_id,
			"last_known_zone_id": entry_zone_id,
			"visited_zone_ids": visited_zone_ids,
			"traversed_edge_ids": PackedStringArray(),
			"revealed_clue_ids": PackedStringArray(),
			"spent_action_ids": PackedStringArray(),
			"zone_flags": {},
			"zone_loot_entries": {},
			"installed_deployments": [],
			"next_loot_uid": 0,
			"last_site_tick": clock.minute_of_day,
			"noise": 0,
		}
	else:
		var existing_memory := indoor_site_memories[building_id] as Dictionary
		if String(existing_memory.get("entry_zone_id", "")).is_empty() and not entry_zone_id.is_empty():
			existing_memory["entry_zone_id"] = entry_zone_id
			existing_memory["current_zone_id"] = entry_zone_id
			existing_memory["last_known_zone_id"] = entry_zone_id

	return indoor_site_memories[building_id]


func enter_indoor_site(building_id: String, entry_zone_id: String) -> void:
	current_indoor_building_id = building_id
	current_indoor_zone_id = entry_zone_id
	var memory := get_or_create_site_memory(building_id, entry_zone_id)
	memory["current_zone_id"] = entry_zone_id
	memory["last_known_zone_id"] = entry_zone_id
	var visited_zone_ids: PackedStringArray = memory.get("visited_zone_ids", PackedStringArray())
	if not entry_zone_id.is_empty() and not visited_zone_ids.has(entry_zone_id):
		visited_zone_ids.append(entry_zone_id)
	memory["visited_zone_ids"] = visited_zone_ids


func update_current_indoor_zone(zone_id: String) -> void:
	current_indoor_zone_id = zone_id
	if current_indoor_building_id.is_empty():
		return
	var memory := get_or_create_site_memory(current_indoor_building_id)
	memory["current_zone_id"] = zone_id
	memory["last_known_zone_id"] = zone_id
	var visited_zone_ids: PackedStringArray = memory.get("visited_zone_ids", PackedStringArray())
	if not zone_id.is_empty() and not visited_zone_ids.has(zone_id):
		visited_zone_ids.append(zone_id)
	memory["visited_zone_ids"] = visited_zone_ids


func drop_item_in_current_zone_data(item_data: Dictionary) -> void:
	if current_indoor_building_id.is_empty() or current_indoor_zone_id.is_empty():
		return

	var memory := get_or_create_site_memory(current_indoor_building_id)
	var zone_loot_entries_variant: Variant = memory.get("zone_loot_entries", {})
	var zone_loot_entries: Dictionary = {}
	if typeof(zone_loot_entries_variant) == TYPE_DICTIONARY:
		zone_loot_entries = (zone_loot_entries_variant as Dictionary).duplicate(true)

	var zone_loot_variant: Variant = zone_loot_entries.get(current_indoor_zone_id, [])
	var zone_loot: Array = []
	if typeof(zone_loot_variant) == TYPE_ARRAY:
		zone_loot = (zone_loot_variant as Array).duplicate(true)

	var entry := item_data.duplicate(true)
	entry["loot_uid"] = int(memory.get("next_loot_uid", 0))
	memory["next_loot_uid"] = int(memory.get("next_loot_uid", 0)) + 1
	zone_loot.append(entry)
	zone_loot_entries[current_indoor_zone_id] = zone_loot
	memory["zone_loot_entries"] = zone_loot_entries


func get_loot_roll_seed(site_id: String, zone_id: String, action_id: String) -> int:
	return abs(hash("%d|%s|%s|%s" % [world_seed, site_id, zone_id, action_id]))


func _apply_job_modifiers(job_id: String) -> int:
	var job := _require_job_data(job_id)
	_apply_modifiers(job.get("modifiers", {}))
	return int(job.get("modifiers", {}).get("carry_limit", 0))


func _apply_trait_modifiers(trait_id: String) -> int:
	var trait_data := _require_trait_data(trait_id)
	_apply_modifiers(trait_data.get("modifiers", {}))
	return int(trait_data.get("modifiers", {}).get("carry_limit", 0))


func _apply_modifiers(modifiers: Dictionary) -> void:
	move_speed += float(modifiers.get("move_speed", 0.0))
	fatigue_gain_multiplier += float(modifiers.get("fatigue_gain", 0.0))


func _sleep_hours_adjustment() -> int:
	var adjustment := 0
	for trait_id_variant in survivor_config.get("trait_ids", []):
		var trait_data := _require_trait_data(String(trait_id_variant))
		adjustment += int(trait_data.get("modifiers", {}).get("sleep_hours_adjustment", 0))
	return adjustment


func set_content_source(content_source) -> void:
	_content_source = content_source


func set_validation_reporting(enabled: bool) -> void:
	_report_validation_errors = enabled


func _get_content_source():
	return ContentLibrary if _content_source == null else _content_source


func _validate_survivor_config(config: Dictionary) -> bool:
	var job_id := String(config.get("job_id", ""))
	if job_id.is_empty():
		_report_validation_error("RunState requires a non-empty job id.")
		return false

	if _lookup_job_data(job_id) == null:
		return false

	for trait_id_variant in config.get("trait_ids", []):
		if _lookup_trait_data(String(trait_id_variant)) == null:
			return false

	return true


func _require_job_data(job_id: String) -> Dictionary:
	var job_data: Variant = _lookup_job_data(job_id)
	if job_data == null:
		return {}

	return job_data


func _lookup_job_data(job_id: String) -> Variant:
	var content_source = _get_content_source()
	if content_source == null or not content_source.has_method("get_job"):
		_report_validation_error("RunState content source must expose get_job(job_id).")
		return null

	var job_data: Variant = content_source.get_job(job_id)
	if typeof(job_data) != TYPE_DICTIONARY or (job_data as Dictionary).is_empty():
		_report_validation_error("Unknown job id '%s'." % job_id)
		return null

	return job_data


func _require_trait_data(trait_id: String) -> Dictionary:
	var trait_data: Variant = _lookup_trait_data(trait_id)
	if trait_data == null:
		return {}

	return trait_data


func _lookup_trait_data(trait_id: String) -> Variant:
	var content_source = _get_content_source()
	if content_source == null or not content_source.has_method("get_trait"):
		_report_validation_error("RunState content source must expose get_trait(trait_id).")
		return null

	var trait_data: Variant = content_source.get_trait(trait_id)
	if typeof(trait_data) != TYPE_DICTIONARY or (trait_data as Dictionary).is_empty():
		_report_validation_error("Unknown trait id '%s'." % trait_id)
		return null

	return trait_data


func _report_validation_error(message: String) -> void:
	if _report_validation_errors:
		push_error(message)


func _recalculate_derived_stats() -> void:
	var carry_bonus := 0
	var move_speed_bonus := 0.0
	var fatigue_gain_bonus := 0.0
	for item_variant in equipped_items.values():
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item := item_variant as Dictionary
		carry_bonus += int(item.get("carry_limit_bonus", 0))
		move_speed_bonus += float(item.get("move_speed_bonus", 0.0))
		fatigue_gain_bonus += float(item.get("fatigue_gain_bonus", 0.0))

	inventory.carry_limit = base_carry_limit + carry_bonus
	move_speed = _base_move_speed + move_speed_bonus
	fatigue_gain_multiplier = _base_fatigue_gain_multiplier + fatigue_gain_bonus


func _merge_item_data(primary: Dictionary, fallback: Dictionary) -> Dictionary:
	var merged := fallback.duplicate(true)
	for key in primary.keys():
		merged[key] = primary[key]
	return merged


func _apply_survival_damage(minutes: int) -> void:
	if minutes <= 0:
		return

	var health_loss := 0.0
	if hunger <= 0.0:
		health_loss += float(minutes) * STARVATION_HEALTH_LOSS_PER_MINUTE
	if thirst <= 0.0:
		health_loss += float(minutes) * DEHYDRATION_HEALTH_LOSS_PER_MINUTE

	if health_loss > 0.0:
		health = max(0.0, health - health_loss)


func _apply_crafting_minutes(outcome: Dictionary, context: String) -> void:
	if context != "indoor":
		outcome["minutes_elapsed"] = 0
		return

	var minutes := int(outcome.get("minutes_elapsed", 0))
	if minutes <= 0:
		return

	var adjusted_minutes := get_indoor_action_minutes(minutes)
	advance_minutes(adjusted_minutes, "indoor")
	outcome["minutes_elapsed"] = adjusted_minutes


func _tick_warmth_effects(minutes: int) -> void:
	if minutes <= 0:
		return
	active_warmth_effects = warmth_model.tick_active_effects(active_warmth_effects, minutes)


func _expected_removed_item_count(primary_item_id: String, secondary_item_id: String, ingredient_rules: Dictionary) -> int:
	var removed_count := 0
	if String(ingredient_rules.get(primary_item_id, "consume")) == "consume":
		removed_count += 1
	if String(ingredient_rules.get(secondary_item_id, "consume")) == "consume":
		removed_count += 1
	return removed_count


func _remove_crafted_result_items(result_item_ids: Array[String]) -> void:
	for result_item_id in result_item_ids:
		inventory.remove_first_item_by_id(result_item_id)


func _combined_use_effects(item_data: Dictionary) -> Dictionary:
	var combined: Dictionary = {}
	var use_effects_variant: Variant = item_data.get("use_effects", {})
	if typeof(use_effects_variant) == TYPE_DICTIONARY:
		combined = (use_effects_variant as Dictionary).duplicate(true)

	for key in ["hunger_restore", "thirst_restore", "health_restore", "fatigue_restore"]:
		if not combined.has(key):
			combined[key] = float(item_data.get(key, 0.0))

	if not combined.has("exposure_restore"):
		combined["exposure_restore"] = 0.0
	if not combined.has("warmth_minutes"):
		combined["warmth_minutes"] = 0
	if not combined.has("outdoor_exposure_drain_multiplier"):
		combined["outdoor_exposure_drain_multiplier"] = 1.0
	combined["effect_id"] = String(item_data.get("id", combined.get("effect_id", "warmth_effect")))
	return combined


func _has_any_use_effect(use_effects: Dictionary) -> bool:
	return float(use_effects.get("hunger_restore", 0.0)) != 0.0 \
		or float(use_effects.get("thirst_restore", 0.0)) != 0.0 \
		or float(use_effects.get("health_restore", 0.0)) != 0.0 \
		or float(use_effects.get("fatigue_restore", 0.0)) != 0.0 \
		or float(use_effects.get("exposure_restore", 0.0)) != 0.0 \
		or int(use_effects.get("warmth_minutes", 0)) > 0


func _lookup_item_data(item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}

	var content_source = _get_content_source()
	if content_source != null and content_source.has_method("get_item"):
		var content_item: Variant = content_source.get_item(item_id)
		if typeof(content_item) == TYPE_DICTIONARY and not (content_item as Dictionary).is_empty():
			return content_item

	if ContentLibrary != null and ContentLibrary.has_method("get_item"):
		var library_item: Variant = ContentLibrary.get_item(item_id)
		if typeof(library_item) == TYPE_DICTIONARY and not (library_item as Dictionary).is_empty():
			return library_item

	for item_variant in inventory.items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var inventory_item := item_variant as Dictionary
		if String(inventory_item.get("id", "")) == item_id:
			return inventory_item

	return {}
