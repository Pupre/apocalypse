extends RefCounted
class_name WarmthModel


func apply_use_effects(exposure: float, thirst: float, fatigue: float, use_effects: Dictionary) -> Dictionary:
	var next_exposure: float = exposure + float(use_effects.get("exposure_restore", 0.0))
	var next_thirst: float = thirst + float(use_effects.get("thirst_restore", 0.0))
	var next_fatigue: float = max(0.0, fatigue - float(use_effects.get("fatigue_restore", 0.0)))
	var warmth_effect: Dictionary = {}
	if int(use_effects.get("warmth_minutes", 0)) > 0:
		warmth_effect = {
			"id": String(use_effects.get("effect_id", "warmth_effect")),
			"remaining_minutes": int(use_effects.get("warmth_minutes", 0)),
			"outdoor_exposure_drain_multiplier": float(use_effects.get("outdoor_exposure_drain_multiplier", 1.0)),
		}
	return {
		"exposure": next_exposure,
		"thirst": next_thirst,
		"fatigue": next_fatigue,
		"warmth_effect": warmth_effect,
	}


func tick_active_effects(effects: Array[Dictionary], elapsed_minutes: int) -> Array[Dictionary]:
	var next_effects: Array[Dictionary] = []
	for effect in effects:
		var remaining: int = max(0, int(effect.get("remaining_minutes", 0)) - elapsed_minutes)
		if remaining <= 0:
			continue
		var next_effect := effect.duplicate(true)
		next_effect["remaining_minutes"] = remaining
		next_effects.append(next_effect)
	return next_effects


func get_outdoor_exposure_drain_multiplier(active_effects: Array[Dictionary], equipped_items: Array[Dictionary]) -> float:
	var multiplier := 1.0
	for effect in active_effects:
		multiplier *= float(effect.get("outdoor_exposure_drain_multiplier", 1.0))
	for item in equipped_items:
		var equip_effects: Dictionary = item.get("equip_effects", {})
		multiplier *= float(equip_effects.get("outdoor_exposure_drain_multiplier", 1.0))
	return multiplier
