extends RefCounted
class_name FatigueModel


func get_band(value: float) -> String:
	if value < 15.0:
		return "양호"
	if value < 35.0:
		return "안정"
	if value < 55.0:
		return "피곤"
	if value < 75.0:
		return "지침"
	return "한계"


func get_sleep_preview(fatigue_value: float, sleep_hours_adjustment: int) -> Dictionary:
	var base_hours := 6 + int(floor(fatigue_value / 20.0))
	var total_hours := clampi(base_hours + sleep_hours_adjustment, 4, 12)
	return {
		"sleep_minutes": total_hours * 60,
		"band": get_band(fatigue_value),
	}


func outdoor_efficiency_multiplier(fatigue_value: float) -> float:
	return clamp(1.0 - (fatigue_value / 160.0), 0.55, 1.0)
