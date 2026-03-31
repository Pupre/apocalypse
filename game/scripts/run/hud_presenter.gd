extends Control

var run_state = null
var _clock_label: Label
var _fatigue_label: Label
var _hunger_label: Label
var _carry_label: Label


func set_run_state(state) -> void:
	run_state = state
	refresh()


func refresh() -> void:
	_cache_nodes()
	if run_state == null:
		_set_empty_state()
		return

	if _clock_label != null:
		_clock_label.text = run_state.clock.get_clock_label()

	if _fatigue_label != null:
		_fatigue_label.text = "Fatigue: %d (%s)" % [int(run_state.fatigue), run_state.fatigue_model.get_band(run_state.fatigue)]

	if _hunger_label != null:
		_hunger_label.text = "Hunger: %d" % int(run_state.hunger)

	if _carry_label != null:
		_carry_label.text = "Carry: %d/%d" % [run_state.inventory.total_bulk(), run_state.inventory.carry_limit]


func _cache_nodes() -> void:
	_clock_label = get_node_or_null("Panel/VBox/ClockLabel") as Label
	_fatigue_label = get_node_or_null("Panel/VBox/FatigueLabel") as Label
	_hunger_label = get_node_or_null("Panel/VBox/HungerLabel") as Label
	_carry_label = get_node_or_null("Panel/VBox/CarryLabel") as Label


func _set_empty_state() -> void:
	if _clock_label != null:
		_clock_label.text = "Clock: --"

	if _fatigue_label != null:
		_fatigue_label.text = "Fatigue: --"

	if _hunger_label != null:
		_hunger_label.text = "Hunger: --"

	if _carry_label != null:
		_carry_label.text = "Carry: --"
