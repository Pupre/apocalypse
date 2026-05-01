extends RefCounted
class_name ExposureModel

const BASE_DRAIN_RATE := 0.42
const FATIGUE_PRESSURE_DIVISOR := 360.0
const MAX_FATIGUE_PRESSURE := 0.35


func drain(current_value: float, minutes_elapsed: float, fatigue_value: float, pressure_multiplier: float = 1.0) -> float:
	if minutes_elapsed <= 0.0:
		return current_value

	var fatigue_penalty := clampf(fatigue_value / FATIGUE_PRESSURE_DIVISOR, 0.0, MAX_FATIGUE_PRESSURE)
	var drain_rate := BASE_DRAIN_RATE * maxf(0.0, pressure_multiplier) * (1.0 + fatigue_penalty)
	return maxf(0.0, current_value - (minutes_elapsed * drain_rate))
