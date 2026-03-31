extends RefCounted
class_name TimeClock

const MINUTES_PER_DAY := 1440
const START_DAY_INDEX := 1
const START_MINUTE_OF_DAY := 480

var day_index: int = START_DAY_INDEX
var minute_of_day: int = START_MINUTE_OF_DAY


func advance_minutes(amount: int) -> void:
	minute_of_day += amount
	while minute_of_day >= MINUTES_PER_DAY:
		minute_of_day -= MINUTES_PER_DAY
		day_index += 1
	while minute_of_day < 0:
		minute_of_day += MINUTES_PER_DAY
		day_index -= 1


func get_clock_label() -> String:
	var hours := minute_of_day / 60
	var minutes := minute_of_day % 60
	return "Day %d %02d:%02d" % [day_index, hours, minutes]
