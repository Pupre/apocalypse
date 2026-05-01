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
const REST_HEAT_RECOVERY_PER_MINUTE := 0.18
const SLEEP_HEAT_RECOVERY_PER_MINUTE := 0.3
const MAX_SURVIVAL_VALUE := 100.0
const BASE_IDEAL_CARRY_CAPACITY := 8.0
const BASE_CARRY_CAPACITY := 10.0
const BASE_OVERPACK_CAPACITY := 12.0
const MIN_OVERPACKED_MOVE_MULTIPLIER := 0.45
const OUTDOOR_OVERLOADED_EXPOSURE_MULTIPLIER_MIN := 1.12
const OUTDOOR_OVERLOADED_EXPOSURE_MULTIPLIER_MAX := 1.3
const OUTDOOR_OVERPACKED_EXPOSURE_MULTIPLIER_MIN := 1.45
const OUTDOOR_OVERPACKED_EXPOSURE_MULTIPLIER_MAX := 1.75
const OUTDOOR_OVERLOADED_FATIGUE_MULTIPLIER_MIN := 1.12
const OUTDOOR_OVERLOADED_FATIGUE_MULTIPLIER_MAX := 1.3
const OUTDOOR_OVERPACKED_FATIGUE_MULTIPLIER_MIN := 1.45
const OUTDOOR_OVERPACKED_FATIGUE_MULTIPLIER_MAX := 1.85
const DEFAULT_DIFFICULTY := "easy"
const VALID_DIFFICULTY_IDS := {
	"easy": true,
	"hard": true,
}

var clock = TIME_CLOCK_SCRIPT.new()
var fatigue_model = FATIGUE_MODEL_SCRIPT.new()
var inventory = INVENTORY_MODEL_SCRIPT.new()
var crafting_resolver = CRAFTING_RESOLVER_SCRIPT.new()
var warmth_model = WARMTH_MODEL_SCRIPT.new()
var survivor_config: Dictionary = {}
var equipped_items: Dictionary = {}
var known_recipe_ids: Dictionary = {}
var read_knowledge_item_ids: Dictionary = {}
var visited_outdoor_block_ids: Dictionary = {}
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
var base_carry_limit: int = int(BASE_IDEAL_CARRY_CAPACITY)
var base_ideal_carry_capacity: float = BASE_IDEAL_CARRY_CAPACITY
var base_carry_capacity: float = BASE_CARRY_CAPACITY
var base_overpack_capacity: float = BASE_OVERPACK_CAPACITY
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
		fatigue_multiplier = OUTDOOR_FATIGUE_MULTIPLIER * get_outdoor_fatigue_gain_multiplier()
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
	_apply_indoor_heat_recovery(minutes, "sleep")
	_apply_survival_damage(minutes)


func advance_rest_time(minutes: int) -> void:
	if minutes < 0:
		return

	clock.advance_minutes(minutes)
	_tick_warmth_effects(minutes)
	hunger = max(0.0, hunger - (float(minutes) * HUNGER_DECAY_PER_MINUTE * REST_HUNGER_MULTIPLIER))
	thirst = max(0.0, thirst - (float(minutes) * THIRST_DECAY_PER_MINUTE * REST_THIRST_MULTIPLIER))
	fatigue = max(0.0, fatigue - (float(minutes) * REST_FATIGUE_RECOVERY_PER_MINUTE))
	_apply_indoor_heat_recovery(minutes, "rest")
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


func get_temperature_stage() -> String:
	if exposure <= 15.0:
		return "위독"
	if exposure <= 30.0:
		return "위험"
	if exposure <= 55.0:
		return "한기"
	if exposure <= 80.0:
		return "서늘"
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


func get_difficulty_id() -> String:
	return String(survivor_config.get("difficulty", DEFAULT_DIFFICULTY))


func is_easy_mode() -> bool:
	return get_difficulty_id() == "easy"


func is_hard_mode() -> bool:
	return get_difficulty_id() == "hard"


func mark_outdoor_block_visited(block_coord: Vector2i) -> void:
	visited_outdoor_block_ids[_outdoor_block_key(block_coord)] = true


func is_outdoor_block_visited(block_coord: Vector2i) -> bool:
	return bool(visited_outdoor_block_ids.get(_outdoor_block_key(block_coord), false))


func get_visited_outdoor_block_keys() -> Array[String]:
	var keys: Array[String] = []
	for key_variant in visited_outdoor_block_ids.keys():
		keys.append(String(key_variant))
	keys.sort()
	return keys


func has_entered_indoor_site(building_id: String) -> bool:
	if building_id.is_empty():
		return false
	return indoor_site_memories.has(building_id)


func get_site_memory(building_id: String) -> Dictionary:
	if building_id.is_empty():
		return {}
	if not indoor_site_memories.has(building_id):
		return {}
	var memory_variant: Variant = indoor_site_memories.get(building_id, {})
	if typeof(memory_variant) != TYPE_DICTIONARY:
		return {}
	return (memory_variant as Dictionary).duplicate(true)


func _apply_survivor_config(config: Dictionary) -> void:
	survivor_config = _normalized_survivor_config(config)
	equipped_items = {}
	known_recipe_ids = {}
	read_knowledge_item_ids = {}
	visited_outdoor_block_ids = {}
	move_speed = BASE_MOVE_SPEED
	fatigue_gain_multiplier = BASE_FATIGUE_GAIN_MULTIPLIER
	world_seed = int(survivor_config.get("world_seed", 0))
	if world_seed == 0:
		world_seed = int(Time.get_unix_time_from_system())

	var carry_capacity_bonus := 0.0
	carry_capacity_bonus += _apply_job_modifiers(String(survivor_config.get("job_id", "")))

	for trait_id_variant in survivor_config.get("trait_ids", []):
		carry_capacity_bonus += _apply_trait_modifiers(String(trait_id_variant))

	_base_move_speed = move_speed
	_base_fatigue_gain_multiplier = fatigue_gain_multiplier
	base_ideal_carry_capacity = BASE_IDEAL_CARRY_CAPACITY + carry_capacity_bonus
	base_carry_capacity = BASE_CARRY_CAPACITY + carry_capacity_bonus
	base_overpack_capacity = BASE_OVERPACK_CAPACITY + carry_capacity_bonus
	base_carry_limit = int(round(base_ideal_carry_capacity))
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
	var outcome: Dictionary = crafting_resolver.resolve(primary_item_id, secondary_item_id, context, _crafting_content_source())
	if String(outcome.get("result_type", "")) == "invalid":
		_apply_crafting_minutes(outcome, context)
		_record_crafting_attempt(primary_item_id, secondary_item_id, outcome)
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

	var tool_validation := _validate_crafting_tools(outcome)
	if not bool(tool_validation.get("ok", false)):
		return {
			"ok": false,
			"reason": String(tool_validation.get("reason", "")),
			"tool_item_id": String(tool_validation.get("tool_item_id", "")),
			"result_type": "invalid",
			"result_item_id": "",
			"result_item_data": {},
			"result_text": _crafting_tool_failure_text(String(tool_validation.get("reason", "")), String(tool_validation.get("tool_item_id", ""))),
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
		var item_data: Dictionary = _item_content_source().get_item(result_item_id)
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

	var tool_spend_result := _spend_crafting_tool_costs(outcome)
	if not bool(tool_spend_result.get("ok", false)):
		_remove_crafted_result_items(added_result_item_ids)
		inventory.restore_items(removed_items)
		return {
			"ok": false,
			"reason": String(tool_spend_result.get("reason", "")),
			"tool_item_id": String(tool_spend_result.get("tool_item_id", "")),
			"result_type": "invalid",
			"result_item_id": "",
			"result_item_data": {},
			"result_text": _crafting_tool_failure_text(String(tool_spend_result.get("reason", "")), String(tool_spend_result.get("tool_item_id", ""))),
			"minutes_elapsed": 0,
			}

	if String(outcome.get("result_type", "")) == "success":
		unlock_recipe(String(outcome.get("recipe_id", "")))

	_apply_crafting_minutes(outcome, context)
	_record_crafting_attempt(primary_item_id, secondary_item_id, outcome)
	return outcome


func knows_recipe(recipe_id: String) -> bool:
	return known_recipe_ids.has(recipe_id)


func unlock_recipe(recipe_id: String) -> void:
	if recipe_id.is_empty():
		return
	known_recipe_ids[recipe_id] = true


func get_tool_charges(item_id: String) -> int:
	var tool_item := inventory.get_first_item_by_id(item_id)
	if tool_item.is_empty():
		return 0
	return int(tool_item.get("charges", tool_item.get("charges_current", tool_item.get("initial_charges", tool_item.get("max_charges", tool_item.get("charges_max", 0))))))


func read_knowledge_item(item_id: String) -> bool:
	if item_id.is_empty() or read_knowledge_item_ids.has(item_id):
		return false

	var item_data := _lookup_item_data(item_id)
	if item_data.is_empty() or not bool(item_data.get("readable", false)):
		return false

	var knowledge_recipe_ids_variant: Variant = item_data.get("knowledge_recipe_ids", [])
	if typeof(knowledge_recipe_ids_variant) != TYPE_ARRAY:
		return false

	var added_knowledge := false
	for recipe_id_variant in knowledge_recipe_ids_variant:
		var recipe_id := String(recipe_id_variant)
		if recipe_id.is_empty() or knows_recipe(recipe_id):
			continue
		unlock_recipe(recipe_id)
		added_knowledge = true

	read_knowledge_item_ids[item_id] = true
	return added_knowledge


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


func get_carry_state_id() -> String:
	if inventory == null or not inventory.has_method("get_carry_state_id"):
		return "normal"
	return String(inventory.get_carry_state_id())


func get_carry_state_label() -> String:
	match get_carry_state_id():
		"overloaded":
			return "과중"
		"overpacked":
			return "과적"
		_:
			return "적정"


func get_carry_weight_summary() -> Dictionary:
	if inventory == null:
		return {
			"total_weight": 0.0,
			"ideal_capacity": 0.0,
			"carry_capacity": 0.0,
			"overpack_capacity": 0.0,
			"state_id": "normal",
			"state_label": "적정",
		}

	return {
		"total_weight": float(inventory.total_carry_weight()),
		"ideal_capacity": float(inventory.ideal_carry_capacity),
		"carry_capacity": float(inventory.carry_capacity),
		"overpack_capacity": float(inventory.overpack_capacity),
		"state_id": get_carry_state_id(),
		"state_label": get_carry_state_label(),
	}


func get_outdoor_move_speed() -> float:
	var fatigue_multiplier := fatigue_model.outdoor_efficiency_multiplier(fatigue)
	var total_weight: float = float(inventory.total_carry_weight())
	var ideal_capacity: float = float(inventory.ideal_carry_capacity)
	var carry_capacity: float = float(inventory.carry_capacity)
	var overpack_capacity: float = float(inventory.overpack_capacity)
	var multiplier: float = 1.0

	match get_carry_state_id():
		"overloaded":
			var overloaded_range: float = max(0.01, carry_capacity - ideal_capacity)
			var overloaded_ratio: float = clamp((total_weight - ideal_capacity) / overloaded_range, 0.0, 1.0)
			multiplier = lerpf(1.0, 0.78, overloaded_ratio)
		"overpacked":
			var overpacked_range: float = max(0.01, overpack_capacity - carry_capacity)
			var overpacked_ratio: float = clamp((total_weight - carry_capacity) / overpacked_range, 0.0, 1.0)
			multiplier = lerpf(0.72, MIN_OVERPACKED_MOVE_MULTIPLIER, overpacked_ratio)
		_:
			multiplier = 1.0

	return move_speed * multiplier * fatigue_multiplier


func get_outdoor_fatigue_gain_multiplier() -> float:
	return _get_outdoor_carry_fatigue_multiplier()


func get_outdoor_exposure_drain_multiplier() -> float:
	var equipped_item_rows: Array[Dictionary] = []
	for item_variant in equipped_items.values():
		if typeof(item_variant) == TYPE_DICTIONARY:
			equipped_item_rows.append((item_variant as Dictionary))

	var warmth_multiplier := warmth_model.get_outdoor_exposure_drain_multiplier(active_warmth_effects, equipped_item_rows)
	return maxf(0.2, warmth_multiplier * _get_outdoor_carry_exposure_multiplier())


func apply_outdoor_threat_contact() -> Dictionary:
	exposure = max(0.0, exposure - 18.0)
	fatigue = min(MAX_SURVIVAL_VALUE, fatigue + 8.0)
	clock.advance_minutes(3)
	return {
		"exposure": exposure,
		"fatigue": fatigue,
		"minute_of_day": clock.minute_of_day,
	}


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
		"indoor_heat_score": _get_current_fixed_heat_score(),
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


func get_current_heat_recovery_context() -> Dictionary:
	var fixed_heat_score := _get_current_fixed_heat_score()
	var portable_heat_score := _get_current_portable_heat_score()
	var has_setup_base := portable_heat_score > 0.0
	var has_ignition := _inventory_has_any_item_tag(["ignition_tool", "ignition"])
	var has_fuel := _inventory_has_any_item_tag(["fuel", "fuel_component"])
	var portable_heat_active := has_setup_base and has_ignition and has_fuel
	var can_recover := fixed_heat_score > 0.0 or portable_heat_active
	var recovery_note := "실내라 추위 하락은 멈췄다. 회복하려면 열원이 필요하다."
	if fixed_heat_score > 0.0:
		recovery_note = "고정 열원으로 몸을 덥힐 수 있다."
	elif has_setup_base and not portable_heat_active:
		recovery_note = "열원 장비는 있지만 점화 도구와 연료가 더 필요하다."
	elif portable_heat_active:
		recovery_note = "설치한 열원으로 몸을 덥힐 수 있다."
	return {
		"fixed_heat_score": fixed_heat_score,
		"portable_heat_score": portable_heat_score,
		"has_setup_base": has_setup_base,
		"has_ignition": has_ignition,
		"has_fuel": has_fuel,
		"can_recover": can_recover,
		"effective_heat_score": fixed_heat_score + (portable_heat_score if portable_heat_active else 0.0),
		"status_text": recovery_note,
	}


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
			"zone_supply_sources": {},
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


func _apply_indoor_heat_recovery(minutes: int, recovery_mode: String) -> void:
	if minutes <= 0 or current_indoor_building_id.is_empty() or current_indoor_zone_id.is_empty():
		return
	var heat_context := get_current_heat_recovery_context()
	if not bool(heat_context.get("can_recover", false)):
		return
	var heat_score := float(heat_context.get("effective_heat_score", 0.0))
	if heat_score <= 0.0:
		return
	var recovery_rate := REST_HEAT_RECOVERY_PER_MINUTE
	if recovery_mode == "sleep":
		recovery_rate = SLEEP_HEAT_RECOVERY_PER_MINUTE
	exposure = min(MAX_SURVIVAL_VALUE, exposure + (float(minutes) * recovery_rate * heat_score))


func _get_current_fixed_heat_score() -> float:
	if current_indoor_building_id.is_empty() or current_indoor_zone_id.is_empty():
		return 0.0
	if not is_instance_valid(ContentLibrary) or not ContentLibrary.has_method("get_building"):
		return 0.0
	var building := ContentLibrary.get_building(current_indoor_building_id)
	if building.is_empty():
		return 0.0
	var fixed_sources_variant: Variant = building.get("fixed_heat_sources", [])
	if typeof(fixed_sources_variant) != TYPE_ARRAY:
		return 0.0
	var total_score := 0.0
	for source_variant in fixed_sources_variant:
		if typeof(source_variant) != TYPE_DICTIONARY:
			continue
		var source := source_variant as Dictionary
		if String(source.get("zone_id", "")) != current_indoor_zone_id:
			continue
		total_score += float(source.get("heat_score", 0.0))
	return total_score


func _get_current_portable_heat_score() -> float:
	if current_indoor_building_id.is_empty() or current_indoor_zone_id.is_empty():
		return 0.0
	var memory := get_or_create_site_memory(current_indoor_building_id)
	var deployments_variant: Variant = memory.get("installed_deployments", [])
	if typeof(deployments_variant) != TYPE_ARRAY:
		return 0.0
	var total_score := 0.0
	for deployment_variant in deployments_variant:
		if typeof(deployment_variant) != TYPE_DICTIONARY:
			continue
		var deployment := deployment_variant as Dictionary
		if String(deployment.get("zone_id", "")) != current_indoor_zone_id:
			continue
		var deploy_effects_variant: Variant = deployment.get("deploy_effects", {})
		if typeof(deploy_effects_variant) != TYPE_DICTIONARY:
			continue
		total_score += float((deploy_effects_variant as Dictionary).get("indoor_heat_score", 0.0))
	return total_score


func _inventory_has_any_item_tag(tag_ids: Array[String]) -> bool:
	if _content_source == null or not _content_source.has_method("get_item") or inventory == null:
		return false
	for carried_variant in inventory.items:
		if typeof(carried_variant) != TYPE_DICTIONARY:
			continue
		var carried_item := carried_variant as Dictionary
		var item_id := String(carried_item.get("id", ""))
		if item_id.is_empty():
			continue
		var item_data: Dictionary = _content_source.get_item(item_id)
		if item_data.is_empty():
			continue
		var item_tags_variant: Variant = item_data.get("item_tags", [])
		if typeof(item_tags_variant) != TYPE_ARRAY:
			continue
		for item_tag_variant in item_tags_variant:
			if tag_ids.has(String(item_tag_variant)):
				return true
	return false


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


func _apply_job_modifiers(job_id: String) -> float:
	var job := _require_job_data(job_id)
	_apply_modifiers(job.get("modifiers", {}))
	var modifiers: Dictionary = job.get("modifiers", {})
	return float(modifiers.get("carry_capacity_bonus", modifiers.get("carry_limit", 0)))


func _apply_trait_modifiers(trait_id: String) -> float:
	var trait_data := _require_trait_data(trait_id)
	_apply_modifiers(trait_data.get("modifiers", {}))
	var modifiers: Dictionary = trait_data.get("modifiers", {})
	return float(modifiers.get("carry_capacity_bonus", modifiers.get("carry_limit", 0)))


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


func _crafting_content_source():
	if _content_source != null and _content_source.has_method("get_crafting_combination") and _content_source.has_method("get_item"):
		return _content_source
	return ContentLibrary


func _item_content_source():
	if _content_source != null and _content_source.has_method("get_item"):
		return _content_source
	return ContentLibrary


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


func _normalized_survivor_config(config: Dictionary) -> Dictionary:
	var normalized := config.duplicate(true)
	var requested_difficulty := String(normalized.get("difficulty", DEFAULT_DIFFICULTY)).to_lower()
	if not VALID_DIFFICULTY_IDS.has(requested_difficulty):
		requested_difficulty = DEFAULT_DIFFICULTY
	normalized["difficulty"] = requested_difficulty
	return normalized


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
	var carry_bonus := 0.0
	var ideal_carry_bonus := 0.0
	var move_speed_bonus := 0.0
	var fatigue_gain_bonus := 0.0
	for item_variant in equipped_items.values():
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item := item_variant as Dictionary
		carry_bonus += float(item.get("carry_capacity_bonus", item.get("carry_limit_bonus", 0)))
		ideal_carry_bonus += float(item.get("ideal_carry_bonus", item.get("carry_capacity_bonus", item.get("carry_limit_bonus", 0))))
		move_speed_bonus += float(item.get("move_speed_bonus", 0.0))
		fatigue_gain_bonus += float(item.get("fatigue_gain_bonus", 0.0))

	inventory.configure_thresholds(
		base_ideal_carry_capacity + ideal_carry_bonus,
		base_carry_capacity + carry_bonus,
		base_overpack_capacity + carry_bonus
	)
	move_speed = _base_move_speed + move_speed_bonus
	fatigue_gain_multiplier = _base_fatigue_gain_multiplier + fatigue_gain_bonus


func _get_outdoor_carry_exposure_multiplier() -> float:
	match get_carry_state_id():
		"overloaded":
			return lerpf(
				OUTDOOR_OVERLOADED_EXPOSURE_MULTIPLIER_MIN,
				OUTDOOR_OVERLOADED_EXPOSURE_MULTIPLIER_MAX,
				_carry_band_ratio(float(inventory.ideal_carry_capacity), float(inventory.carry_capacity))
			)
		"overpacked":
			return lerpf(
				OUTDOOR_OVERPACKED_EXPOSURE_MULTIPLIER_MIN,
				OUTDOOR_OVERPACKED_EXPOSURE_MULTIPLIER_MAX,
				_carry_band_ratio(float(inventory.carry_capacity), float(inventory.overpack_capacity))
			)
		_:
			return 1.0


func _get_outdoor_carry_fatigue_multiplier() -> float:
	match get_carry_state_id():
		"overloaded":
			return lerpf(
				OUTDOOR_OVERLOADED_FATIGUE_MULTIPLIER_MIN,
				OUTDOOR_OVERLOADED_FATIGUE_MULTIPLIER_MAX,
				_carry_band_ratio(float(inventory.ideal_carry_capacity), float(inventory.carry_capacity))
			)
		"overpacked":
			return lerpf(
				OUTDOOR_OVERPACKED_FATIGUE_MULTIPLIER_MIN,
				OUTDOOR_OVERPACKED_FATIGUE_MULTIPLIER_MAX,
				_carry_band_ratio(float(inventory.carry_capacity), float(inventory.overpack_capacity))
			)
		_:
			return 1.0


func _carry_band_ratio(start_capacity: float, end_capacity: float) -> float:
	if inventory == null:
		return 0.0
	var capacity_range := maxf(0.01, end_capacity - start_capacity)
	return clampf((float(inventory.total_carry_weight()) - start_capacity) / capacity_range, 0.0, 1.0)


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


func _outdoor_block_key(block_coord: Vector2i) -> String:
	return "%d_%d" % [block_coord.x, block_coord.y]


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


func _validate_crafting_tools(outcome: Dictionary) -> Dictionary:
	var required_tool_ids_variant: Variant = outcome.get("required_tool_ids", [])
	if typeof(required_tool_ids_variant) == TYPE_ARRAY:
		for tool_item_id_variant in required_tool_ids_variant:
			var tool_item_id := String(tool_item_id_variant)
			if tool_item_id.is_empty():
				continue
			if inventory.count_item_by_id(tool_item_id) < 1:
				return {"ok": false, "reason": "missing_tool", "tool_item_id": tool_item_id}

	var tool_charge_costs_variant: Variant = outcome.get("tool_charge_costs", {})
	if typeof(tool_charge_costs_variant) != TYPE_DICTIONARY:
		return {"ok": true}

	var tool_charge_costs := tool_charge_costs_variant as Dictionary
	for tool_item_id_variant in tool_charge_costs.keys():
		var tool_item_id := String(tool_item_id_variant)
		var charge_cost := int(tool_charge_costs.get(tool_item_id_variant, 0))
		if tool_item_id.is_empty():
			continue
		if inventory.count_item_by_id(tool_item_id) < 1:
			return {"ok": false, "reason": "missing_tool", "tool_item_id": tool_item_id}
		var available_charges := get_tool_charges(tool_item_id)
		if charge_cost > 0 and available_charges < charge_cost:
			return {"ok": false, "reason": "depleted_tool", "tool_item_id": tool_item_id}

	return {"ok": true}


func _spend_crafting_tool_costs(outcome: Dictionary) -> Dictionary:
	var tool_charge_costs_variant: Variant = outcome.get("tool_charge_costs", {})
	if typeof(tool_charge_costs_variant) != TYPE_DICTIONARY:
		return {"ok": true}

	var tool_charge_costs := tool_charge_costs_variant as Dictionary
	for tool_item_id_variant in tool_charge_costs.keys():
		var tool_item_id := String(tool_item_id_variant)
		var charge_cost := int(tool_charge_costs.get(tool_item_id_variant, 0))
		if tool_item_id.is_empty() or charge_cost <= 0:
			continue

		var spend_result := inventory.spend_item_charges(tool_item_id, charge_cost)
		if not bool(spend_result.get("ok", false)):
			return {"ok": false, "reason": String(spend_result.get("reason", "depleted_tool")), "tool_item_id": tool_item_id}

	return {"ok": true}


func _crafting_tool_failure_text(reason: String, tool_item_id: String) -> String:
	var tool_name := _item_display_name(tool_item_id)
	match reason:
		"missing_tool":
			return "%s이(가) 필요하다." % tool_name
		"depleted_tool", "insufficient_charges":
			return "%s 잔량이 부족하다." % tool_name
		_:
			return "필요한 도구를 준비하지 못했다."


func _record_crafting_attempt(primary_item_id: String, secondary_item_id: String, outcome: Dictionary) -> void:
	if primary_item_id.is_empty() or secondary_item_id.is_empty():
		return

	var knowledge_codex = _get_knowledge_codex()
	if knowledge_codex == null or not knowledge_codex.has_method("record_attempt"):
		return

	var payload := {
		"result_type": String(outcome.get("result_type", "invalid")),
		"result_item_id": String(outcome.get("result_item_id", "")),
		"result_label": String(outcome.get("result_item_data", {}).get("name", outcome.get("result_item_id", ""))),
	}
	knowledge_codex.record_attempt(primary_item_id, secondary_item_id, payload)


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


func _item_display_name(item_id: String) -> String:
	var item_data := _lookup_item_data(item_id)
	if not item_data.is_empty():
		return String(item_data.get("name", item_id))
	return item_id


func _get_knowledge_codex():
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("KnowledgeCodex")
