extends Control

signal start_requested

const UiKitResolver = preload("res://scripts/ui/ui_kit_resolver.gd")
const TEXT_PRIMARY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const TEXT_SECONDARY_COLOR := Color(0.92, 0.96, 1.0, 0.98)
const TEXT_OUTLINE_COLOR := Color(0.0, 0.02, 0.04, 1.0)

@onready var _start_button: Button = get_node_or_null("Center/Panel/VBox/StartButton") as Button
@onready var _panel: PanelContainer = get_node_or_null("Center/Panel") as PanelContainer
@onready var _title_label: Label = get_node_or_null("Center/Panel/VBox/TitleLabel") as Label
@onready var _subtitle_label: Label = get_node_or_null("Center/Panel/VBox/SubtitleLabel") as Label
@onready var _note_label: Label = get_node_or_null("Center/Panel/VBox/NoteLabel") as Label

var _ui_kit_resolver := UiKitResolver.new()


func _ready() -> void:
	_apply_ui_skin()
	_bind_events()


func _bind_events() -> void:
	if _start_button == null:
		push_error("Title menu start button is missing.")
		return

	_start_button.pressed.connect(Callable(self, "_on_start_pressed"))


func _on_start_pressed() -> void:
	start_requested.emit()


func _apply_ui_skin() -> void:
	_ui_kit_resolver.apply_panel(_panel, "sheet/sheet_bg_compact.png")
	if _start_button != null:
		_start_button.custom_minimum_size = Vector2(0, 56)
		_start_button.focus_mode = Control.FOCUS_NONE
		_ui_kit_resolver.apply_button(
			_start_button,
			"sheet/sheet_button_primary_normal.png",
			"sheet/sheet_button_primary_pressed.png",
			"sheet/sheet_button_primary_pressed.png",
			"sheet/sheet_button_secondary_normal.png"
		)
		_start_button.add_theme_font_size_override("font_size", 18)
		_start_button.add_theme_color_override("font_color", TEXT_PRIMARY_COLOR)
		_start_button.add_theme_color_override("font_outline_color", TEXT_OUTLINE_COLOR)
		_start_button.add_theme_constant_override("outline_size", 3)
	_apply_label_style(_title_label, 34, TEXT_PRIMARY_COLOR, 5)
	_apply_label_style(_subtitle_label, 17, TEXT_SECONDARY_COLOR, 3)
	_apply_label_style(_note_label, 14, TEXT_SECONDARY_COLOR, 2)


func _apply_label_style(label: Label, font_size: int, font_color: Color, outline_size: int) -> void:
	if label == null:
		return
	label.modulate = font_color
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", TEXT_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", outline_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
