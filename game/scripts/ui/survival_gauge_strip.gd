extends HBoxContainer

const UiKitResolver = preload("res://scripts/ui/ui_kit_resolver.gd")
const LABEL_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const LABEL_OUTLINE_COLOR := Color(0.0, 0.02, 0.04, 1.0)

var run_state = null

var _health_stage_label: Label = null
var _health_bar: ProgressBar = null
var _hunger_stage_label: Label = null
var _hunger_bar: ProgressBar = null
var _thirst_stage_label: Label = null
var _thirst_bar: ProgressBar = null
var _fatigue_stage_label: Label = null
var _fatigue_bar: ProgressBar = null
var _cold_stage_label: Label = null
var _cold_bar: ProgressBar = null
var _ui_kit_resolver = UiKitResolver.new()
var _skin_applied := false


func _ready() -> void:
	_cache_nodes()
	_apply_ui_skin()
	refresh()


func set_run_state(state) -> void:
	run_state = state
	refresh()


func refresh() -> void:
	_cache_nodes()
	if run_state == null:
		_set_empty_state()
		return

	_set_gauge(_health_stage_label, _health_bar, "체력", String(run_state.get_health_stage()), float(run_state.health))
	_set_gauge(_hunger_stage_label, _hunger_bar, "허기", String(run_state.get_hunger_stage()), float(run_state.hunger))
	_set_gauge(_thirst_stage_label, _thirst_bar, "갈증", String(run_state.get_thirst_stage()), float(run_state.thirst))
	_set_gauge(_fatigue_stage_label, _fatigue_bar, "피로", String(run_state.get_fatigue_stage()), 100.0 - float(run_state.fatigue))
	_set_gauge(_cold_stage_label, _cold_bar, "추위", String(run_state.get_temperature_stage()), float(run_state.exposure))


func _cache_nodes() -> void:
	_health_stage_label = get_node_or_null("HealthGauge/StageLabel") as Label
	_health_bar = get_node_or_null("HealthGauge/Bar") as ProgressBar
	_hunger_stage_label = get_node_or_null("HungerGauge/StageLabel") as Label
	_hunger_bar = get_node_or_null("HungerGauge/Bar") as ProgressBar
	_thirst_stage_label = get_node_or_null("ThirstGauge/StageLabel") as Label
	_thirst_bar = get_node_or_null("ThirstGauge/Bar") as ProgressBar
	_fatigue_stage_label = get_node_or_null("FatigueGauge/StageLabel") as Label
	_fatigue_bar = get_node_or_null("FatigueGauge/Bar") as ProgressBar
	_cold_stage_label = get_node_or_null("ColdGauge/StageLabel") as Label
	_cold_bar = get_node_or_null("ColdGauge/Bar") as ProgressBar


func _apply_ui_skin() -> void:
	if _skin_applied:
		return
	_skin_applied = true
	_apply_gauge_skin(_health_stage_label, _health_bar, "hud/gauge_fill_health.png")
	_apply_gauge_skin(_hunger_stage_label, _hunger_bar, "hud/gauge_fill_hunger.png")
	_apply_gauge_skin(_thirst_stage_label, _thirst_bar, "hud/gauge_fill_thirst.png")
	_apply_gauge_skin(_fatigue_stage_label, _fatigue_bar, "hud/gauge_fill_fatigue.png")
	_apply_gauge_skin(_cold_stage_label, _cold_bar, "hud/gauge_fill_cold.png")


func _apply_gauge_skin(label_node: Label, bar_node: ProgressBar, fill_path: String) -> void:
	if label_node != null:
		_apply_label_style(label_node, 14, LABEL_COLOR, 3)
		label_node.add_theme_font_size_override("font_size", 14)
		label_node.visible = true
	if bar_node != null:
		bar_node.custom_minimum_size = Vector2(0, 14)
		_ui_kit_resolver.apply_progress_bar(bar_node, "hud/gauge_frame_short_compact.png", fill_path)


func _set_empty_state() -> void:
	_set_gauge(_health_stage_label, _health_bar, "체력", "--", 0.0)
	_set_gauge(_hunger_stage_label, _hunger_bar, "허기", "--", 0.0)
	_set_gauge(_thirst_stage_label, _thirst_bar, "갈증", "--", 0.0)
	_set_gauge(_fatigue_stage_label, _fatigue_bar, "피로", "--", 0.0)
	_set_gauge(_cold_stage_label, _cold_bar, "추위", "--", 0.0)


func _set_gauge(label_node: Label, bar_node: ProgressBar, title: String, stage: String, value: float) -> void:
	var status_text := "%s %s" % [title, stage]
	if label_node != null:
		label_node.text = title
	if bar_node != null:
		bar_node.min_value = 0.0
		bar_node.max_value = 100.0
		bar_node.value = clampf(value, 0.0, 100.0)
		bar_node.tooltip_text = status_text


func _apply_label_style(label_node: Label, font_size: int, font_color: Color, outline_size: int = 1) -> void:
	if label_node == null:
		return
	label_node.modulate = font_color
	label_node.add_theme_font_size_override("font_size", font_size)
	label_node.add_theme_color_override("font_color", font_color)
	label_node.add_theme_color_override("font_outline_color", LABEL_OUTLINE_COLOR)
	label_node.add_theme_constant_override("outline_size", outline_size)
