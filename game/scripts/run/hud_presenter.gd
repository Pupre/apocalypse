extends CanvasLayer

const UiKitResolver = preload("res://scripts/ui/ui_kit_resolver.gd")
const TEXT_PRIMARY_COLOR := Color(0.96, 0.98, 1.0, 0.98)
const TEXT_SECONDARY_COLOR := Color(0.9, 0.94, 0.98, 0.96)
const TEXT_OUTLINE_COLOR := Color(0.04, 0.06, 0.09, 0.94)

signal bag_requested
signal map_requested

const OUTDOOR_TITLE := "외부 생존 정보"
const INDOOR_TITLE := "실내 생존 정보"

var run_state = null
var _top_ribbon: PanelContainer
var _header_shell: PanelContainer
var _gauge_shell: PanelContainer
var _title_label: Label
var _clock_label: Label
var _map_button: Button
var _bag_button: Button
var _gauge_row = null
var _ui_kit_resolver = UiKitResolver.new()
var _skin_applied := false


func set_run_state(state) -> void:
	run_state = state
	refresh()


func set_mode_presentation(mode_name: String) -> void:
	_cache_nodes()
	if _top_ribbon == null or _title_label == null:
		return

	if mode_name == "indoor":
		visible = false
		return

	visible = true
	_top_ribbon.anchor_left = 0.0
	_top_ribbon.anchor_top = 0.0
	_top_ribbon.anchor_right = 1.0
	_top_ribbon.anchor_bottom = 0.0
	_top_ribbon.offset_left = 12.0
	_top_ribbon.offset_top = 12.0
	_top_ribbon.offset_right = -8.0
	_top_ribbon.offset_bottom = 94.0
	_top_ribbon.modulate = Color(1, 1, 1, 1.0)
	_title_label.text = OUTDOOR_TITLE


func refresh() -> void:
	_cache_nodes()
	if run_state == null:
		_set_empty_state()
		return

	if _clock_label != null:
		_clock_label.text = run_state.clock.get_clock_label()
	if _gauge_row != null and _gauge_row.has_method("set_run_state"):
		_gauge_row.set_run_state(run_state)


func _cache_nodes() -> void:
	_top_ribbon = get_node_or_null("TopRibbon") as PanelContainer
	_header_shell = get_node_or_null("TopRibbon/Margin/Stack/HeaderShell") as PanelContainer
	_gauge_shell = get_node_or_null("TopRibbon/Margin/Stack/GaugeShell") as PanelContainer
	_title_label = get_node_or_null("TopRibbon/Margin/Stack/HeaderShell/HeaderMargin/HeaderRow/TitleLabel") as Label
	_clock_label = get_node_or_null("TopRibbon/Margin/Stack/HeaderShell/HeaderMargin/HeaderRow/ClockLabel") as Label
	_map_button = get_node_or_null("TopRibbon/Margin/Stack/HeaderShell/HeaderMargin/HeaderRow/MapButton") as Button
	_bag_button = get_node_or_null("TopRibbon/Margin/Stack/HeaderShell/HeaderMargin/HeaderRow/BagButton") as Button
	_gauge_row = get_node_or_null("TopRibbon/Margin/Stack/GaugeShell/GaugePadding/GaugeRow")
	_apply_ui_skin()
	if _map_button != null and not _map_button.pressed.is_connected(Callable(self, "_on_map_button_pressed")):
		_map_button.pressed.connect(Callable(self, "_on_map_button_pressed"))
	if _bag_button != null and not _bag_button.pressed.is_connected(Callable(self, "_on_bag_button_pressed")):
		_bag_button.pressed.connect(Callable(self, "_on_bag_button_pressed"))


func _apply_ui_skin() -> void:
	if _skin_applied:
		return
	if _top_ribbon == null:
		return
	_skin_applied = true
	_ui_kit_resolver.apply_panel(_header_shell, "hud/hud_header_chip_compact.png")
	_ui_kit_resolver.apply_panel(_gauge_shell, "hud/hud_gauge_strip_compact.png")
	_ui_kit_resolver.apply_button(
		_map_button,
		"hud/hud_icon_button_compact_normal.png",
		"hud/hud_icon_button_compact_pressed.png",
		"hud/hud_icon_button_compact_normal.png",
		"hud/hud_icon_button_compact_disabled.png"
	)
	_ui_kit_resolver.apply_button(
		_bag_button,
		"hud/hud_icon_button_compact_normal.png",
		"hud/hud_icon_button_compact_pressed.png",
		"hud/hud_icon_button_compact_normal.png",
		"hud/hud_icon_button_compact_disabled.png"
	)
	if _title_label != null:
		_apply_label_style(_title_label, 14, TEXT_PRIMARY_COLOR, 2)
	if _clock_label != null:
		_apply_label_style(_clock_label, 14, TEXT_SECONDARY_COLOR, 2)
	if _map_button != null:
		_map_button.text = ""
		_map_button.tooltip_text = "지도"
		_map_button.custom_minimum_size = Vector2(36, 36)
		_map_button.icon = _ui_kit_resolver.get_texture("icons/light_24/map.png")
		_map_button.expand_icon = false
		_map_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _bag_button != null:
		_bag_button.text = ""
		_bag_button.tooltip_text = "가방"
		_bag_button.custom_minimum_size = Vector2(36, 36)
		_bag_button.icon = _ui_kit_resolver.get_texture("icons/light_24/bag.png")
		_bag_button.expand_icon = false
		_bag_button.alignment = HORIZONTAL_ALIGNMENT_CENTER


func _set_empty_state() -> void:
	if _clock_label != null:
		_clock_label.text = "시각: --"
	if _gauge_row != null and _gauge_row.has_method("set_run_state"):
		_gauge_row.set_run_state(null)


func _on_map_button_pressed() -> void:
	map_requested.emit()


func _on_bag_button_pressed() -> void:
	bag_requested.emit()


func _apply_label_style(label: Label, font_size: int, font_color: Color, outline_size: int = 1) -> void:
	if label == null:
		return
	label.modulate = font_color
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", TEXT_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", outline_size)
