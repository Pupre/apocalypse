extends RefCounted
class_name ExposureModel


func drain(current_value: float, minutes_elapsed: float, fatigue_value: float) -> float:
	if minutes_elapsed <= 0.0:
		return current_value

	var fatigue_penalty := clampf(fatigue_value / 400.0, 0.0, 0.25)
	var drain_rate := 0.35 * (1.0 + fatigue_penalty)
	return maxf(0.0, current_value - (minutes_elapsed * drain_rate))
