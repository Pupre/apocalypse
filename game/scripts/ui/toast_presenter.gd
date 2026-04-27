extends CanvasLayer

const ItemIconResolver = preload("res://scripts/ui/item_icon_resolver.gd")
const UiKitResolver = preload("res://scripts/ui/ui_kit_resolver.gd")
const TEXT_COLOR := Color(0.96, 0.98, 1.0, 0.98)
const OUTLINE_COLOR := Color(0.04, 0.06, 0.09, 0.94)
const DEFAULT_DURATION := 2.0

var _ui_kit_resolver = UiKitResolver.new()
var _item_icon_resolver = ItemIconResolver.new()
var _toast_shell: PanelContainer = null
var _message_label: Label = null
var _icon_slot: PanelContainer = null
var _icon_rect: TextureRect = null
var _fallback_glyph: Label = null
var _message := ""
var _type := "info"
var _remaining := 0.0
var _icon_item_id := ""


func _ready() -> void:
	_toast_shell = get_node_or_null("ToastShell") as PanelContainer
	_message_label = get_node_or_null("ToastShell/Margin/Row/MessageLabel") as Label
	_icon_slot = get_node_or_null("ToastShell/Margin/Row/IconSlot") as PanelContainer
	_icon_rect = get_node_or_null("ToastShell/Margin/Row/IconSlot/IconCenter/IconRect") as TextureRect
	_fallback_glyph = get_node_or_null("ToastShell/Margin/Row/IconSlot/IconCenter/FallbackGlyph") as Label
	_apply_text_style()
	_apply_shell_skin()
	_hide_toast()


func show_toast(toast_type: String, message: String, duration: float = DEFAULT_DURATION, icon_item_id: String = "") -> void:
	if _toast_shell == null or _message_label == null or message.is_empty():
		return
	_type = toast_type if toast_type in ["info", "success", "warning"] else "info"
	_message = message
	_remaining = max(0.1, duration)
	_icon_item_id = icon_item_id
	_message_label.text = _message
	_apply_shell_skin()
	_apply_icon()
	_toast_shell.visible = true


func _process(delta: float) -> void:
	if _remaining <= 0.0:
		return
	_remaining = max(0.0, _remaining - delta)
	if _remaining <= 0.0:
		_hide_toast()


func _apply_shell_skin() -> void:
	if _toast_shell == null:
		return
	_ui_kit_resolver.apply_panel(_toast_shell, "sheet/detail_panel_compact.png")
	if _icon_slot != null:
		_ui_kit_resolver.apply_panel(_icon_slot, "sheet/inventory_icon_slot.png")


func _apply_text_style() -> void:
	if _message_label == null:
		return
	_message_label.add_theme_color_override("font_color", TEXT_COLOR)
	_message_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	_message_label.add_theme_constant_override("outline_size", 2)
	_message_label.add_theme_font_size_override("font_size", 14)
	if _fallback_glyph != null:
		_fallback_glyph.add_theme_color_override("font_color", TEXT_COLOR)
		_fallback_glyph.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
		_fallback_glyph.add_theme_constant_override("outline_size", 2)
		_fallback_glyph.add_theme_font_size_override("font_size", 14)


func _apply_icon() -> void:
	if _icon_rect == null or _fallback_glyph == null:
		return
	var item_icon := _item_icon_resolver.get_item_icon(_icon_item_id) if not _icon_item_id.is_empty() else null
	_icon_rect.texture = item_icon
	_icon_rect.visible = item_icon != null
	_fallback_glyph.visible = item_icon == null
	match _type:
		"success":
			_fallback_glyph.text = "✓"
		"warning":
			_fallback_glyph.text = "X"
		_:
			_fallback_glyph.text = "i"


func _hide_toast() -> void:
	_remaining = 0.0
	if _toast_shell != null:
		_toast_shell.visible = false
