extends RefCounted
class_name RunState

const TIME_CLOCK_SCRIPT := preload("res://scripts/run/time_clock.gd")
const FATIGUE_MODEL_SCRIPT := preload("res://scripts/run/fatigue_model.gd")
const INVENTORY_MODEL_SCRIPT := preload("res://scripts/run/inventory_model.gd")

const BASE_MOVE_SPEED := 160.0
const BASE_FATIGUE_GAIN_MULTIPLIER := 1.0
const FATIGUE_GAIN_PER_MINUTE := 1.0 / 30.0
const HUNGER_GAIN_PER_MINUTE := 1.0 / 60.0
const BASE_CARRY_LIMIT := 8

var clock = TIME_CLOCK_SCRIPT.new()
var fatigue_model = FATIGUE_MODEL_SCRIPT.new()
var inventory = INVENTORY_MODEL_SCRIPT.new()
var survivor_config: Dictionary = {}
var fatigue: float = 0.0
var hunger: float = 0.0
var health: float = 100.0
var exposure: float = 100.0
var move_speed: float = BASE_MOVE_SPEED
var fatigue_gain_multiplier: float = BASE_FATIGUE_GAIN_MULTIPLIER


static func from_survivor_config(config: Dictionary):
	var state = new()
	state._apply_survivor_config(config)
	return state


func advance_minutes(amount: int) -> void:
	clock.advance_minutes(amount)
	fatigue += float(amount) * FATIGUE_GAIN_PER_MINUTE * fatigue_gain_multiplier
	hunger += float(amount) * HUNGER_GAIN_PER_MINUTE


func advance_sleep(minutes: int) -> void:
	clock.advance_minutes(minutes)
	hunger += float(minutes) * HUNGER_GAIN_PER_MINUTE


func get_sleep_preview() -> Dictionary:
	return fatigue_model.get_sleep_preview(fatigue, _sleep_hours_adjustment())


func is_dead() -> bool:
	return health <= 0.0 or exposure <= 0.0


func _apply_survivor_config(config: Dictionary) -> void:
	survivor_config = config.duplicate(true)

	var carry_limit_bonus := 0
	carry_limit_bonus += _apply_job_modifiers(String(survivor_config.get("job_id", "")))

	for trait_id_variant in survivor_config.get("trait_ids", []):
		carry_limit_bonus += _apply_trait_modifiers(String(trait_id_variant))

	inventory.carry_limit = BASE_CARRY_LIMIT + carry_limit_bonus


func _apply_job_modifiers(job_id: String) -> int:
	var job := ContentLibrary.get_job(job_id)
	_apply_modifiers(job.get("modifiers", {}))
	return int(job.get("modifiers", {}).get("carry_limit", 0))


func _apply_trait_modifiers(trait_id: String) -> int:
	var trait_data := ContentLibrary.get_trait(trait_id)
	_apply_modifiers(trait_data.get("modifiers", {}))
	return int(trait_data.get("modifiers", {}).get("carry_limit", 0))


func _apply_modifiers(modifiers: Dictionary) -> void:
	move_speed += float(modifiers.get("move_speed", 0.0))
	fatigue_gain_multiplier += float(modifiers.get("fatigue_gain", 0.0))


func _sleep_hours_adjustment() -> int:
	var adjustment := 0
	for trait_id_variant in survivor_config.get("trait_ids", []):
		var trait_data := ContentLibrary.get_trait(String(trait_id_variant))
		adjustment += int(trait_data.get("modifiers", {}).get("sleep_hours_adjustment", 0))
	return adjustment
