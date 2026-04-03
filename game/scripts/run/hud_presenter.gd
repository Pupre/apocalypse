extends Control

const OUTDOOR_TITLE := "외부 생존 정보"
const INDOOR_TITLE := "실내 생존 정보"

var run_state = null
var _panel: PanelContainer
var _title_label: Label
var _clock_label: Label
var _fatigue_label: Label
var _hunger_label: Label
var _thirst_label: Label
var _health_label: Label
var _carry_label: Label


func set_run_state(state) -> void:
	run_state = state
	refresh()


func set_mode_presentation(mode_name: String) -> void:
	_cache_nodes()
	if _panel == null or _title_label == null:
		return

	if mode_name == "indoor":
		visible = false
		return

	visible = true
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.offset_left = -336.0
	_panel.offset_top = 16.0
	_panel.offset_right = -16.0
	_panel.offset_bottom = 228.0
	_panel.modulate = Color(1, 1, 1, 1.0)
	_title_label.text = OUTDOOR_TITLE


func refresh() -> void:
	_cache_nodes()
	if run_state == null:
		_set_empty_state()
		return

	if _clock_label != null:
		_clock_label.text = run_state.clock.get_clock_label()

	if _fatigue_label != null:
		_fatigue_label.text = "피로: %s" % run_state.get_fatigue_stage()

	if _hunger_label != null:
		_hunger_label.text = "허기: %s" % run_state.get_hunger_stage()

	if _thirst_label != null:
		_thirst_label.text = "갈증: %s" % run_state.get_thirst_stage()

	if _health_label != null:
		_health_label.text = "체력: %s" % run_state.get_health_stage()

	if _carry_label != null:
		_carry_label.text = "소지량: %d/%d" % [run_state.inventory.total_bulk(), run_state.inventory.carry_limit]


func _cache_nodes() -> void:
	_panel = get_node_or_null("Panel") as PanelContainer
	_title_label = get_node_or_null("Panel/VBox/TitleLabel") as Label
	_clock_label = get_node_or_null("Panel/VBox/ClockLabel") as Label
	_fatigue_label = get_node_or_null("Panel/VBox/FatigueLabel") as Label
	_hunger_label = get_node_or_null("Panel/VBox/HungerLabel") as Label
	_thirst_label = get_node_or_null("Panel/VBox/ThirstLabel") as Label
	_health_label = get_node_or_null("Panel/VBox/HealthLabel") as Label
	_carry_label = get_node_or_null("Panel/VBox/CarryLabel") as Label


func _set_empty_state() -> void:
	if _clock_label != null:
		_clock_label.text = "시각: --"

	if _fatigue_label != null:
		_fatigue_label.text = "피로: --"

	if _hunger_label != null:
		_hunger_label.text = "허기: --"

	if _thirst_label != null:
		_thirst_label.text = "갈증: --"

	if _health_label != null:
		_health_label.text = "체력: --"

	if _carry_label != null:
		_carry_label.text = "소지량: --"
