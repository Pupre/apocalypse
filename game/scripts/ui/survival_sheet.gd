extends CanvasLayer

const ItemIconResolver = preload("res://scripts/ui/item_icon_resolver.gd")
const UiKitResolver = preload("res://scripts/ui/ui_kit_resolver.gd")

signal close_requested
signal inventory_action_requested(action_id: String)
signal craft_applied(outcome: Dictionary)

const STATE_HIDDEN := "hidden"
const STATE_INVENTORY_BROWSE := "inventory_browse"
const STATE_INVENTORY_CRAFT_SELECT := "inventory_craft_select"
const STATE_CODEX_BROWSE := "codex_browse"

const CODEX_CATEGORY_ORDER := ["fire_heat", "food_drink", "hygiene_medical", "repair_fortify"]
const CODEX_CATEGORY_LABELS := {
	"fire_heat": "불 / 열",
	"food_drink": "음식 / 음료",
	"hygiene_medical": "위생 / 의료",
	"repair_fortify": "수리 / 보강",
}

const INVENTORY_SCROLL_MIN_HEIGHT_BROWSE := 420.0
const DETAIL_LIST_INSET_HEIGHT := 300.0
const CRAFT_BAR_GAP := 10.0
const CRAFT_BAR_HEIGHT := 154.0
const INVENTORY_ICON_SLOT_STYLE := {
	"bg": Color(0.16, 0.18, 0.22, 0.96),
	"border": Color(0.34, 0.38, 0.44, 0.92),
}
const TEXT_PRIMARY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const TEXT_SECONDARY_COLOR := Color(0.94, 0.97, 1.0, 0.98)
const TEXT_MUTED_COLOR := Color(0.90, 0.94, 0.98, 0.98)
const TEXT_OUTLINE_COLOR := Color(0.0, 0.02, 0.04, 1.0)

var run_state = null
var _mode_name := "indoor"
var _active_tab := "inventory"
var _sheet_state := STATE_HIDDEN
var _selected_item_id := ""
var _craft_base_item_id := ""
var _last_craft_feedback_text := ""
var _highlighted_item_ids: Array[String] = []
var _item_badges: Dictionary = {}
var _inventory_payload := {
	"title": "가방",
	"status_text": "",
	"rows": [],
	"selected_sheet": {"visible": false},
	"feedback_message": "",
}
var _item_buttons: Dictionary = {}
var _item_row_panels: Dictionary = {}
var _title_label: Label = null
var _status_label: Label = null
var _inventory_tab_button: Button = null
var _codex_tab_button: Button = null
var _close_button: Button = null
var _craft_card: Control = null
var _material_one_icon_rect: TextureRect = null
var _material_one_value_label: Label = null
var _material_two_icon_rect: TextureRect = null
var _material_two_value_label: Label = null
var _craft_result_icon_rect: TextureRect = null
var _craft_result_value_label: Label = null
var _craft_result_hint_label: Label = null
var _craft_confirm_button: Button = null
var _craft_cancel_button: Button = null
var _craft_actions_row: HBoxContainer = null
var _inventory_pane: Control = null
var _inventory_scroll: ScrollContainer = null
var _detail_inset: Control = null
var _inventory_items: VBoxContainer = null
var _browse_hint_label: Label = null
var _equipment_rows: HBoxContainer = null
var _item_detail_sheet: Control = null
var _detail_close_button: Button = null
var _item_name_label: Label = null
var _item_description_label: Label = null
var _item_effect_label: Label = null
var _mode_message_label: Label = null
var _primary_actions: VBoxContainer = null
var _secondary_actions: VBoxContainer = null
var _codex_pane: Control = null
var _codex_rows: VBoxContainer = null
var _item_icon_rect: TextureRect = null
var _item_icon_resolver = ItemIconResolver.new()
var _ui_kit_resolver = UiKitResolver.new()
var _skin_applied := false
var _highlight_pulse_time := 0.0


func _ready() -> void:
	_cache_nodes()
	_bind_buttons()
	_apply_ui_skin()
	visible = false
	_render()


func _process(delta: float) -> void:
	_highlight_pulse_time += delta
	var pulse_alpha := 0.72 + (sin(_highlight_pulse_time * 4.2) + 1.0) * 0.14
	var row_lift := 1.10 + (sin(_highlight_pulse_time * 4.2) + 1.0) * 0.10
	for item_id_variant in _item_row_panels.keys():
		var item_id := String(item_id_variant)
		var row_panel := _item_row_panels.get(item_id) as Control
		if row_panel == null:
			continue
		if _highlighted_item_ids.has(item_id) and item_id != _craft_base_item_id:
			row_panel.modulate = Color(1.05, row_lift + 0.10, row_lift + 0.18, 1.0)
		elif item_id == _selected_item_id or (_sheet_state == STATE_INVENTORY_CRAFT_SELECT and item_id == _craft_base_item_id):
			row_panel.modulate = Color(1.08, 1.18, 1.28, 1.0)
		else:
			row_panel.modulate = Color(1, 1, 1, 1)
	for badge_variant in _item_badges.values():
		var badge := badge_variant as Control
		if badge == null or not badge.visible:
			continue
		badge.modulate = Color(1, 1, 1, pulse_alpha)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_sheet()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and not _is_pointer_inside_active_surface(mouse_event.position):
			close_sheet()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed and not _is_pointer_inside_active_surface(touch_event.position):
			close_sheet()
			get_viewport().set_input_as_handled()


func _is_pointer_inside_active_surface(position: Vector2) -> bool:
	if _rect_contains_point(_sheet_rect(), position):
		return true
	if _craft_card != null and _craft_card.visible and _rect_contains_point(_craft_card.get_global_rect(), position):
		return true
	if _item_detail_sheet != null and _item_detail_sheet.visible and _rect_contains_point(_item_detail_sheet.get_global_rect(), position):
		return true
	return false


func _sheet_rect() -> Rect2:
	var sheet := get_node_or_null("Sheet") as Control
	return sheet.get_global_rect() if sheet != null else Rect2()


func _rect_contains_point(rect: Rect2, position: Vector2) -> bool:
	return rect.size.x > 0.0 and rect.size.y > 0.0 and rect.has_point(position)


func bind_run_state(value) -> void:
	run_state = value
	_ensure_selected_item_is_valid()
	_refresh_highlights()
	_render()


func set_mode_name(value: String) -> void:
	_mode_name = value if not value.is_empty() else "indoor"


func open_inventory() -> void:
	visible = true
	_active_tab = "inventory"
	_sheet_state = STATE_INVENTORY_BROWSE
	_selected_item_id = ""
	_last_craft_feedback_text = ""
	_refresh_highlights()
	_render()


func open_codex() -> void:
	visible = true
	_active_tab = "codex"
	_sheet_state = STATE_CODEX_BROWSE
	_selected_item_id = ""
	_last_craft_feedback_text = ""
	_render()


func close_sheet() -> void:
	visible = false
	_active_tab = "inventory"
	_sheet_state = STATE_HIDDEN
	_selected_item_id = ""
	_craft_base_item_id = ""
	_last_craft_feedback_text = ""
	_highlighted_item_ids.clear()
	_render()
	close_requested.emit()


func set_inventory_payload(payload: Dictionary) -> void:
	_inventory_payload = payload.duplicate(true)
	_ensure_selected_item_is_valid()
	_refresh_highlights()
	_render()


func get_active_tab_id() -> String:
	return _active_tab


func get_sheet_state_id() -> String:
	return _sheet_state


func get_selected_item_id() -> String:
	return _selected_item_id


func get_craft_anchor_item_id() -> String:
	return _craft_base_item_id


func get_highlighted_item_ids() -> Array[String]:
	return _highlighted_item_ids.duplicate()


func is_detail_open() -> bool:
	return _item_detail_sheet != null and _item_detail_sheet.visible


func select_inventory_item(item_id: String) -> void:
	if _sheet_state == STATE_INVENTORY_CRAFT_SELECT and item_id != _selected_item_id:
		_last_craft_feedback_text = ""
	_selected_item_id = item_id
	_render_inventory()


func begin_craft_mode(item_id: String) -> void:
	if item_id.is_empty():
		return
	visible = true
	_active_tab = "inventory"
	_selected_item_id = ""
	_craft_base_item_id = item_id
	_last_craft_feedback_text = ""
	_sheet_state = STATE_INVENTORY_CRAFT_SELECT
	_refresh_highlights()
	_render()


func can_attempt_craft() -> bool:
	if run_state == null:
		return false
	if _sheet_state != STATE_INVENTORY_CRAFT_SELECT:
		return false
	if _craft_base_item_id.is_empty() or _selected_item_id.is_empty():
		return false
	if _selected_item_id == _craft_base_item_id and run_state.inventory.count_item_by_id(_selected_item_id) < 2:
		return false
	return true


func can_confirm_craft() -> bool:
	return can_attempt_craft()


func confirm_craft() -> Dictionary:
	if run_state == null:
		return {
			"ok": false,
			"result_type": "invalid",
			"result_item_id": "",
			"result_item_data": {},
			"result_text": "런 상태를 찾지 못했다.",
			"minutes_elapsed": 0,
		}

	if not can_attempt_craft():
		return {
			"ok": false,
			"result_type": "invalid",
			"result_item_id": "",
			"result_item_data": {},
			"result_text": "재료를 두 개 고른 뒤 조합을 시도한다.",
			"minutes_elapsed": 0,
		}

	var outcome: Dictionary = run_state.attempt_craft(_craft_base_item_id, _selected_item_id, _mode_name)
	_last_craft_feedback_text = String(outcome.get("result_text", ""))
	var crafted_item_id := String(outcome.get("result_item_id", ""))
	if bool(outcome.get("ok", false)) and not crafted_item_id.is_empty() and String(outcome.get("result_type", "")) != "invalid":
		_selected_item_id = crafted_item_id
		_sheet_state = STATE_INVENTORY_BROWSE
		_craft_base_item_id = ""
		_last_craft_feedback_text = ""
	else:
		_sheet_state = STATE_INVENTORY_CRAFT_SELECT

	_refresh_highlights()
	_ensure_selected_item_is_valid()
	_render()
	craft_applied.emit(outcome)
	return outcome


func _cache_nodes() -> void:
	_title_label = get_node_or_null("Sheet/VBox/Header/TitleRow/TitleLabel") as Label
	_status_label = get_node_or_null("Sheet/VBox/Header/StatusLabel") as Label
	_inventory_tab_button = get_node_or_null("Sheet/VBox/Tabs/InventoryTabButton") as Button
	_codex_tab_button = get_node_or_null("Sheet/VBox/Tabs/CodexTabButton") as Button
	_close_button = get_node_or_null("Sheet/VBox/Header/TitleRow/CloseButton") as Button
	_craft_card = get_node_or_null("CraftCard") as Control
	_material_one_icon_rect = get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialOneCard/Padding/VBox/ValueRow/MaterialOneIconSlot/IconCenter/MaterialOneIconRect") as TextureRect
	_material_one_value_label = get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialOneCard/Padding/VBox/ValueRow/MaterialOneValueLabel") as Label
	_material_two_icon_rect = get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialTwoCard/Padding/VBox/ValueRow/MaterialTwoIconSlot/IconCenter/MaterialTwoIconRect") as TextureRect
	_material_two_value_label = get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialTwoCard/Padding/VBox/ValueRow/MaterialTwoValueLabel") as Label
	_craft_confirm_button = get_node_or_null("CraftCard/Padding/VBox/ActionsRow/CraftConfirmButton") as Button
	_craft_cancel_button = get_node_or_null("CraftCard/Padding/VBox/ActionsRow/CraftCancelButton") as Button
	_inventory_pane = get_node_or_null("Sheet/VBox/InventoryPane") as Control
	_inventory_scroll = get_node_or_null("Sheet/VBox/InventoryPane/InventoryScroll") as ScrollContainer
	_detail_inset = get_node_or_null("Sheet/VBox/InventoryPane/InventoryScroll/InventoryContent/DetailInset") as Control
	_browse_hint_label = get_node_or_null("Sheet/VBox/InventoryPane/BrowseHintLabel") as Label
	_equipment_rows = get_node_or_null("Sheet/VBox/InventoryPane/EquipmentRows") as HBoxContainer
	_inventory_items = get_node_or_null("Sheet/VBox/InventoryPane/InventoryScroll/InventoryContent/InventoryItems") as VBoxContainer
	_item_detail_sheet = get_node_or_null("ItemDetailSheet") as Control
	_detail_close_button = get_node_or_null("ItemDetailSheet/VBox/Header/DetailCloseButton") as Button
	_item_icon_rect = get_node_or_null("ItemDetailSheet/VBox/Header/ItemIconRect") as TextureRect
	_item_name_label = get_node_or_null("ItemDetailSheet/VBox/Header/ItemNameLabel") as Label
	_item_description_label = get_node_or_null("ItemDetailSheet/VBox/DetailScroll/DetailBody/ItemDescriptionLabel") as Label
	_item_effect_label = get_node_or_null("ItemDetailSheet/VBox/DetailScroll/DetailBody/ItemEffectLabel") as Label
	_mode_message_label = get_node_or_null("ItemDetailSheet/VBox/DetailScroll/DetailBody/ModeMessageLabel") as Label
	_craft_result_icon_rect = null
	_craft_result_value_label = null
	_craft_result_hint_label = null
	_primary_actions = get_node_or_null("ItemDetailSheet/VBox/DetailActions/PrimaryActions") as VBoxContainer
	_secondary_actions = get_node_or_null("ItemDetailSheet/VBox/DetailActions/SecondaryActions") as VBoxContainer
	_craft_actions_row = get_node_or_null("ItemDetailSheet/VBox/DetailActions/CraftActionsRow") as HBoxContainer
	_codex_pane = get_node_or_null("Sheet/VBox/CodexPane") as Control
	_codex_rows = get_node_or_null("Sheet/VBox/CodexPane/CodexScroll/CodexRows") as VBoxContainer


func _bind_buttons() -> void:
	if _inventory_tab_button != null and not _inventory_tab_button.pressed.is_connected(Callable(self, "_on_inventory_tab_pressed")):
		_inventory_tab_button.pressed.connect(Callable(self, "_on_inventory_tab_pressed"))
	if _codex_tab_button != null and not _codex_tab_button.pressed.is_connected(Callable(self, "_on_codex_tab_pressed")):
		_codex_tab_button.pressed.connect(Callable(self, "_on_codex_tab_pressed"))
	if _close_button != null and not _close_button.pressed.is_connected(Callable(self, "_on_close_pressed")):
		_close_button.pressed.connect(Callable(self, "_on_close_pressed"))
	if _craft_cancel_button != null and not _craft_cancel_button.pressed.is_connected(Callable(self, "_on_cancel_craft_pressed")):
		_craft_cancel_button.pressed.connect(Callable(self, "_on_cancel_craft_pressed"))
	if _craft_confirm_button != null and not _craft_confirm_button.pressed.is_connected(Callable(self, "_on_craft_confirm_pressed")):
		_craft_confirm_button.pressed.connect(Callable(self, "_on_craft_confirm_pressed"))
	if _detail_close_button != null and not _detail_close_button.pressed.is_connected(Callable(self, "_on_detail_close_pressed")):
		_detail_close_button.pressed.connect(Callable(self, "_on_detail_close_pressed"))


func _render() -> void:
	_render_header()
	_render_tabs()
	_render_craft_card()
	_render_inventory()
	_render_codex()


func _render_header() -> void:
	if _title_label != null:
		_title_label.text = String(_inventory_payload.get("title", "가방"))
	if _status_label != null:
		_status_label.text = String(_inventory_payload.get("status_text", ""))
		_status_label.visible = not _status_label.text.is_empty()


func _render_tabs() -> void:
	if _inventory_pane != null:
		_inventory_pane.visible = _active_tab == "inventory"
	if _codex_pane != null:
		_codex_pane.visible = _active_tab == "codex"
	if _browse_hint_label != null:
		_browse_hint_label.visible = _active_tab == "inventory"
	if _inventory_tab_button != null:
		_inventory_tab_button.button_pressed = _active_tab == "inventory"
		_style_sheet_tab(_inventory_tab_button, _active_tab == "inventory")
	if _codex_tab_button != null:
		_codex_tab_button.button_pressed = _active_tab == "codex"
		_style_sheet_tab(_codex_tab_button, _active_tab == "codex")


func _render_craft_card() -> void:
	var craft_active := _sheet_state == STATE_INVENTORY_CRAFT_SELECT and not _craft_base_item_id.is_empty()
	if _craft_card != null:
		_craft_card.visible = craft_active
		if craft_active:
			_layout_craft_card()
	if _material_one_icon_rect != null:
		_material_one_icon_rect.texture = _item_icon_for(_craft_base_item_id) if craft_active else null
		_material_one_icon_rect.visible = _material_one_icon_rect.texture != null
	if _material_one_value_label != null:
		_material_one_value_label.text = _display_name_for_item(_craft_base_item_id) if craft_active else ""
	if _material_two_icon_rect != null:
		var second_icon_item_id := ""
		if craft_active and not _selected_item_id.is_empty() and _selected_item_id != _craft_base_item_id:
			second_icon_item_id = _selected_item_id
		_material_two_icon_rect.texture = _item_icon_for(second_icon_item_id)
		_material_two_icon_rect.visible = _material_two_icon_rect.texture != null
	if _material_two_value_label != null:
		var second_item_id := ""
		if craft_active and not _selected_item_id.is_empty() and _selected_item_id != _craft_base_item_id:
			second_item_id = _selected_item_id
		_material_two_value_label.text = _display_name_for_item(second_item_id) if not second_item_id.is_empty() else "비어 있음"
	if _craft_confirm_button != null:
		_craft_confirm_button.disabled = not can_attempt_craft()


func _render_inventory() -> void:
	if _inventory_items == null:
		return

	_clear_children(_inventory_items)
	_item_buttons.clear()
	_item_row_panels.clear()
	_item_badges.clear()

	var inventory_rows := _inventory_rows_for_render()
	if _browse_hint_label != null:
		_browse_hint_label.text = _inventory_hint_text()
	_render_equipment_summary()
	for row in inventory_rows:
		if String(row.get("kind", "")) == "section":
			_inventory_items.add_child(_create_inventory_section_header(row))
		else:
			_inventory_items.add_child(_create_inventory_row(row))

	_refresh_item_button_states()
	_render_item_detail()
	_apply_inventory_scroll_height()
	_render_craft_card()


func _inventory_hint_text() -> String:
	if _sheet_state == STATE_INVENTORY_CRAFT_SELECT:
		return "조합 가능 섹션의 물건부터 눌러 두 번째 재료를 고른다."
	return "먹고 마실 것, 불과 도구, 입을 것을 먼저 나눠 본다."


func _render_equipment_summary() -> void:
	if _equipment_rows == null:
		return
	_clear_children(_equipment_rows)
	_equipment_rows.visible = _active_tab == "inventory" and _sheet_state != STATE_INVENTORY_CRAFT_SELECT
	if not _equipment_rows.visible:
		return

	var equipped_by_slot := {}
	var rows_variant: Variant = _inventory_payload.get("equipped_rows", [])
	if typeof(rows_variant) == TYPE_ARRAY:
		for row_variant in rows_variant:
			if typeof(row_variant) == TYPE_DICTIONARY:
				var row := (row_variant as Dictionary).duplicate(true)
				var slot_id := String(row.get("slot_id", ""))
				if String(row.get("kind", "")) == "equipped" and not slot_id.is_empty():
					equipped_by_slot[slot_id] = row

	var slot_order := ["back", "body", "outer", "head", "face", "feet", "hands", "waist"]
	for slot_id in slot_order:
		var row: Dictionary = equipped_by_slot.get(slot_id, {
			"kind": "empty",
			"slot_id": slot_id,
			"slot_label": _slot_label(slot_id),
			"item_name": "비어 있음",
			"state_text": "",
		})
		_equipment_rows.add_child(_create_equipment_chip(row))


func _create_equipment_chip(row: Dictionary) -> Control:
	var equipped := String(row.get("kind", "")) == "equipped"
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _equipment_chip_style(equipped))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	chip.add_child(box)

	var slot_label := Label.new()
	slot_label.text = String(row.get("slot_label", row.get("summary_text", "장비")))
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.clip_text = true
	_apply_label_style(slot_label, 10, TEXT_SECONDARY_COLOR if equipped else TEXT_MUTED_COLOR, 1)
	box.add_child(slot_label)

	var item_label := Label.new()
	item_label.text = String(row.get("item_name", "비어 있음"))
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_label.clip_text = true
	_apply_label_style(item_label, 11, TEXT_PRIMARY_COLOR if equipped else Color(0.78, 0.84, 0.90, 0.88), 1)
	box.add_child(item_label)

	return chip


func _equipment_chip_style(equipped: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.18, 0.21, 0.95) if equipped else Color(0.08, 0.10, 0.13, 0.82)
	style.border_color = Color(0.50, 0.72, 0.80, 0.70) if equipped else Color(0.34, 0.42, 0.48, 0.50)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _create_inventory_section_header(row: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "InventorySection_%s" % String(row.get("section_id", "misc"))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _inventory_section_style())

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = String(row.get("label", ""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_style(label, 13, TEXT_SECONDARY_COLOR, 2)
	panel.add_child(label)
	return panel


func _inventory_section_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.13, 0.78)
	style.border_color = Color(0.62, 0.78, 0.88, 0.24)
	style.border_width_bottom = 1
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _layout_craft_card() -> void:
	if _craft_card == null:
		return
	var sheet := get_node_or_null("Sheet") as Control
	if sheet == null:
		return
	var sheet_rect := sheet.get_global_rect()
	_craft_card.offset_left = sheet_rect.position.x
	_craft_card.offset_right = sheet_rect.position.x + sheet_rect.size.x
	_craft_card.offset_bottom = sheet_rect.position.y - CRAFT_BAR_GAP
	_craft_card.offset_top = _craft_card.offset_bottom - CRAFT_BAR_HEIGHT


func _apply_inventory_scroll_height() -> void:
	if _inventory_scroll == null:
		return

	_inventory_scroll.custom_minimum_size = Vector2(0.0, INVENTORY_SCROLL_MIN_HEIGHT_BROWSE)
	if _detail_inset == null:
		return

	var inset_height := 0.0
	if is_detail_open():
		inset_height = DETAIL_LIST_INSET_HEIGHT
	_detail_inset.custom_minimum_size = Vector2(0.0, inset_height)


func _create_inventory_row(row: Dictionary) -> Control:
	var item_id := String(row.get("item_id", ""))
	var label_text := String(row.get("label", ""))
	var charges_text := String(row.get("charges_text", ""))

	var panel := PanelContainer.new()
	panel.name = "InventoryRow_%s" % item_id
	panel.set_meta("item_id", item_id)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_kit_resolver.apply_panel(panel, "sheet_set/item_row_idle.png")
	_item_row_panels[item_id] = panel

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var row_line := HBoxContainer.new()
	row_line.add_theme_constant_override("separation", 12)
	box.add_child(row_line)

	var icon_slot := PanelContainer.new()
	icon_slot.custom_minimum_size = Vector2(42, 42)
	icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_kit_resolver.apply_panel(icon_slot, "sheet/inventory_icon_slot.png")
	row_line.add_child(icon_slot)

	var icon_holder := CenterContainer.new()
	icon_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_slot.add_child(icon_holder)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(20, 20)
	icon_rect.texture = _item_icon_for(item_id)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_holder.add_child(icon_rect)

	var compatibility_badge := PanelContainer.new()
	compatibility_badge.name = "CompatibilityBadge"
	compatibility_badge.custom_minimum_size = Vector2(34, 14)
	compatibility_badge.position = Vector2(4, 26)
	compatibility_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	compatibility_badge.visible = false
	compatibility_badge.add_theme_stylebox_override("panel", _compatibility_badge_style())
	icon_slot.add_child(compatibility_badge)
	_item_badges[item_id] = compatibility_badge

	var compatibility_label := Label.new()
	compatibility_label.text = "조합"
	compatibility_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	compatibility_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_style(compatibility_label, 9, TEXT_SECONDARY_COLOR, 1)
	compatibility_badge.add_child(compatibility_label)

	var button := Button.new()
	button.name = "RowButton"
	button.text = label_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.flat = false
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 48)
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.mouse_force_pass_scroll_events = true
	button.focus_mode = Control.FOCUS_NONE
	_ui_kit_resolver.apply_button(
		button,
		"sheet/inventory_row_compact_idle.png",
		"sheet/inventory_row_compact_selected.png"
	)
	_apply_button_text_style(button, 15, TEXT_PRIMARY_COLOR, 2)
	button.pressed.connect(Callable(self, "_on_inventory_item_pressed").bind(item_id))
	row_line.add_child(button)
	_item_buttons[item_id] = button

	var meta_lines: Array[String] = []
	if not charges_text.is_empty():
		meta_lines.append(charges_text)

	if not meta_lines.is_empty():
		var meta_label := Label.new()
		meta_label.name = "MetaLabel"
		meta_label.text = "\n".join(meta_lines)
		meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_label_style(meta_label, 13, TEXT_MUTED_COLOR, 1)
		box.add_child(meta_label)

	var tag_texts := _row_tag_texts(row)
	if not tag_texts.is_empty():
		var tag_row := HBoxContainer.new()
		tag_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag_row.add_theme_constant_override("separation", 6)
		box.add_child(tag_row)
		for tag_text in tag_texts.slice(0, 3):
			tag_row.add_child(_create_inventory_tag_chip(tag_text))

	return panel


func _row_tag_texts(row: Dictionary) -> Array[String]:
	var tag_texts: Array[String] = []
	var tag_texts_variant: Variant = row.get("tag_texts", [])
	if typeof(tag_texts_variant) != TYPE_ARRAY:
		return tag_texts
	for tag_variant in tag_texts_variant:
		var tag_text := String(tag_variant)
		if tag_text.is_empty():
			continue
		tag_texts.append(tag_text)
	return tag_texts


func _create_inventory_tag_chip(text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _inventory_tag_chip_style())

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_style(label, 10, TEXT_SECONDARY_COLOR, 1)
	chip.add_child(label)
	return chip


func _inventory_tag_chip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.18, 0.22, 0.92)
	style.border_color = Color(0.55, 0.75, 0.82, 0.42)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _render_item_detail() -> void:
	var sheet := _selected_item_sheet()
	if _item_detail_sheet != null:
		_item_detail_sheet.visible = _active_tab == "inventory" \
			and bool(sheet.get("visible", false)) \
			and _sheet_state != STATE_INVENTORY_CRAFT_SELECT
	if _item_name_label != null:
		_item_name_label.text = String(sheet.get("title", "아이템"))
	if _item_icon_rect != null:
		var detail_item_id := _selected_item_id if bool(sheet.get("visible", false)) else ""
		_item_icon_rect.texture = _item_icon_for(detail_item_id)
		_item_icon_rect.visible = _item_icon_rect.texture != null
	if _item_description_label != null:
		_item_description_label.text = String(sheet.get("description", "아이템을 선택하면 설명이 나타난다."))
		_item_description_label.visible = not _item_description_label.text.is_empty()
	if _item_effect_label != null:
		_item_effect_label.text = String(sheet.get("effect_text", ""))
		_item_effect_label.visible = not _item_effect_label.text.is_empty()
	if _mode_message_label != null:
		_mode_message_label.text = _mode_message_text(sheet)
		_mode_message_label.visible = not _mode_message_label.text.is_empty()

	_render_item_actions(sheet)


func _render_item_actions(selected_sheet: Dictionary) -> void:
	if _primary_actions == null or _secondary_actions == null:
		return

	_clear_children(_primary_actions)
	_clear_children(_secondary_actions)
	if _sheet_state == STATE_INVENTORY_CRAFT_SELECT:
		if _craft_actions_row != null:
			_craft_actions_row.visible = false
		return
	if _craft_actions_row != null:
		_craft_actions_row.visible = false
	var visible := bool(selected_sheet.get("visible", false))
	if not visible:
		return

	for action_variant in selected_sheet.get("actions", []):
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action := action_variant as Dictionary
		var action_id := String(action.get("id", ""))
		var action_label := String(action.get("label", action_id))
		if action_id.begins_with("read_inventory_") \
			or action_id.begins_with("consume_inventory_") \
			or action_id.begins_with("equip_inventory_") \
			or action_id.begins_with("drop_inventory_"):
			var button := Button.new()
			button.text = action_label
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_apply_button_text_style(button, 14, TEXT_PRIMARY_COLOR, 1)
			_ui_kit_resolver.apply_button(
				button,
				"sheet_set/action_button_primary_normal.png",
				"sheet_set/action_button_primary_pressed.png"
			)
			button.pressed.connect(func() -> void:
				inventory_action_requested.emit(action_id)
			)
			_primary_actions.add_child(button)

	var craft_button := Button.new()
	craft_button.text = "조합 시작"
	craft_button.disabled = _sheet_state == STATE_INVENTORY_CRAFT_SELECT or _selected_item_id.is_empty()
	craft_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_text_style(craft_button, 14, TEXT_PRIMARY_COLOR, 1)
	_ui_kit_resolver.apply_button(
		craft_button,
		"sheet_set/action_button_secondary_normal.png",
		"sheet_set/action_button_secondary_pressed.png"
	)
	craft_button.pressed.connect(func() -> void:
		begin_craft_mode(_selected_item_id)
	)
	_secondary_actions.add_child(craft_button)


func _selected_item_sheet() -> Dictionary:
	if _active_tab != "inventory":
		return {
			"visible": false,
			"title": "아이템",
			"description": "아이템을 선택하면 설명이 나타난다.",
			"effect_text": "",
			"actions": [],
		}
	if _selected_item_id.is_empty():
		return {
			"visible": false,
			"title": "아이템",
			"description": "아이템을 선택하면 설명이 나타난다.",
			"effect_text": "",
			"actions": [],
		}

	var payload_sheet: Dictionary = _inventory_payload.get("selected_sheet", {})
	if _payload_sheet_matches_item(payload_sheet, _selected_item_id):
		return {
			"visible": true,
			"title": String(payload_sheet.get("title", _display_name_for_item(_selected_item_id))),
			"description": _formatted_payload_description(payload_sheet),
			"effect_text": _formatted_payload_effect(payload_sheet),
			"actions": payload_sheet.get("actions", []),
		}

	var item_data := _item_definition(_selected_item_id)
	if item_data.is_empty():
		return {
			"visible": false,
			"title": "아이템",
			"description": "아이템을 찾을 수 없다.",
			"effect_text": "",
			"actions": [],
		}

	return {
		"visible": true,
		"title": _display_name_for_item(_selected_item_id),
		"description": _formatted_item_description(item_data),
		"effect_text": _formatted_item_effect(item_data),
		"actions": _inventory_sheet_actions(item_data, _selected_item_id),
	}


func _mode_message_text(selected_sheet: Dictionary) -> String:
	if _sheet_state == STATE_INVENTORY_CRAFT_SELECT and not _craft_base_item_id.is_empty():
		if not _last_craft_feedback_text.is_empty():
			return _last_craft_feedback_text
		return "다른 재료를 고른 뒤 조합을 시도한다."
	if bool(selected_sheet.get("visible", false)):
		return String(selected_sheet.get("mode_message", ""))
	return ""


func _inventory_rows_for_render() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var payload_rows_variant: Variant = _inventory_payload.get("rows", [])
	if typeof(payload_rows_variant) == TYPE_ARRAY:
		for row_variant in payload_rows_variant:
			if typeof(row_variant) != TYPE_DICTIONARY:
				continue
			var row := (row_variant as Dictionary).duplicate(true)
			var action_id := String(row.get("action_id", ""))
			var item_id := String(row.get("item_id", ""))
			if item_id.is_empty() and action_id.begins_with("inspect_inventory_"):
				item_id = action_id.trim_prefix("inspect_inventory_")
				row["item_id"] = item_id
			if item_id.is_empty():
				continue
			rows.append(row)

	if not rows.is_empty():
		return _sectioned_inventory_rows(_sorted_inventory_rows(rows))

	var grouped := _group_inventory_rows_by_item_id()
	var item_ids: Array[String] = []
	for item_id_variant in grouped.keys():
		item_ids.append(String(item_id_variant))

	for item_id in item_ids:
		var item_data := _item_definition(item_id)
		rows.append({
			"item_id": item_id,
			"count": int(grouped.get(item_id, 0)),
			"label": "%s x%d" % [_display_name_for_item(item_id), int(grouped.get(item_id, 0))],
			"action_id": "inspect_inventory_%s" % item_id,
			"charges_text": _item_charges_text(item_id, item_data),
		})

	return _sectioned_inventory_rows(_sorted_inventory_rows(rows))


func _sorted_inventory_rows(rows: Array[Dictionary]) -> Array[Dictionary]:
	var sorted_rows := rows.duplicate(true)
	sorted_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_priority := _inventory_row_priority(a)
		var b_priority := _inventory_row_priority(b)
		if a_priority != b_priority:
			return a_priority < b_priority
		var a_name := _display_name_for_item(String(a.get("item_id", "")))
		var b_name := _display_name_for_item(String(b.get("item_id", "")))
		return a_name < b_name
	)
	return sorted_rows


func _inventory_row_priority(row: Dictionary) -> int:
	var item_id := String(row.get("item_id", ""))
	if _sheet_state == STATE_INVENTORY_CRAFT_SELECT:
		if item_id == _craft_base_item_id:
			return 0
		if _highlighted_item_ids.has(item_id):
			return 1
		return 2
	return _browse_section_priority(_browse_section_id_for_row(row))


func _sectioned_inventory_rows(rows: Array[Dictionary]) -> Array[Dictionary]:
	if rows.is_empty():
		return [{
			"kind": "section",
			"section_id": "empty",
			"label": "가방이 비었다",
		}]

	var sectioned: Array[Dictionary] = []
	var current_section_id := ""
	for row in rows:
		var section_id := _section_id_for_row(row)
		if section_id != current_section_id:
			current_section_id = section_id
			sectioned.append({
				"kind": "section",
				"section_id": section_id,
				"label": _section_label(section_id),
			})
		sectioned.append(row)
	return sectioned


func _section_id_for_row(row: Dictionary) -> String:
	var item_id := String(row.get("item_id", ""))
	if _sheet_state == STATE_INVENTORY_CRAFT_SELECT:
		if item_id == _craft_base_item_id:
			return "craft_anchor"
		if _highlighted_item_ids.has(item_id):
			return "craft_compatible"
		return "craft_other"
	return _browse_section_id_for_row(row)


func _browse_section_id_for_row(row: Dictionary) -> String:
	var item_data := _item_definition(String(row.get("item_id", "")))
	var category := String(item_data.get("category", ""))
	if category == "food" or category == "drink" or category == "medical" or category == "stimulant":
		return "survival"
	if category == "utility":
		return "tools"
	if bool(item_data.get("readable", false)):
		return "knowledge"
	if not String(item_data.get("equip_slot", "")).is_empty():
		return "wearable"
	var tag_texts := _row_tag_texts(row)
	for tag_text in tag_texts:
		if tag_text.find("tool") >= 0 or tag_text.find("utility") >= 0 or tag_text.find("ignition") >= 0:
			return "tools"
	if float(item_data.get("carry_weight", item_data.get("bulk", 1))) >= 3.0:
		return "heavy"
	return "materials"


func _browse_section_priority(section_id: String) -> int:
	match section_id:
		"survival":
			return 0
		"tools":
			return 1
		"wearable":
			return 2
		"knowledge":
			return 3
		"heavy":
			return 4
		_:
			return 5


func _section_label(section_id: String) -> String:
	match section_id:
		"craft_anchor":
			return "기준 재료"
		"craft_compatible":
			return "조합 가능"
		"craft_other":
			return "다른 물건"
		"survival":
			return "먹고 마실 것"
		"tools":
			return "불과 도구"
		"wearable":
			return "입고 버틸 것"
		"knowledge":
			return "읽을 것"
		"heavy":
			return "무거운 짐"
		"materials":
			return "재료와 기타"
		_:
			return "그 밖의 물건"


func _group_inventory_rows_by_item_id() -> Dictionary:
	var grouped: Dictionary = {}
	if run_state == null or run_state.inventory == null:
		return grouped

	for item_variant in run_state.inventory.items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item := item_variant as Dictionary
		var item_id := String(item.get("id", ""))
		if item_id.is_empty():
			continue
		grouped[item_id] = int(grouped.get(item_id, 0)) + 1

	return grouped


func _refresh_highlights() -> void:
	_highlighted_item_ids.clear()
	if _sheet_state != STATE_INVENTORY_CRAFT_SELECT or _craft_base_item_id.is_empty():
		return
	var only_known_recipes: bool = run_state != null and run_state.has_method("is_hard_mode") and run_state.is_hard_mode()
	_highlighted_item_ids = _compatible_secondary_item_ids(_craft_base_item_id, only_known_recipes)


func _compatible_secondary_item_ids(primary_item_id: String, only_known_recipes: bool = false) -> Array[String]:
	var candidate_ids: Array[String] = []
	if run_state == null or run_state.inventory == null:
		return candidate_ids
	var grouped := _group_inventory_rows_by_item_id()
	for item_id_variant in grouped.keys():
		var item_id := String(item_id_variant)
		if item_id == primary_item_id and int(grouped[item_id]) < 2:
			continue
		var preview: Dictionary = run_state.crafting_resolver.resolve(primary_item_id, item_id, _mode_name, ContentLibrary)
		var recipe_id := String(preview.get("recipe_id", ""))
		if recipe_id.is_empty():
			continue
		if only_known_recipes and not _recipe_is_known(recipe_id):
			continue
		candidate_ids.append(item_id)
	return candidate_ids


func _refresh_item_button_states() -> void:
	for item_id_variant in _item_buttons.keys():
		var item_id := String(item_id_variant)
		var button := _item_buttons.get(item_id) as Button
		if button == null:
			continue
		var panel := _item_row_panels.get(item_id) as PanelContainer

		var panel_path := "sheet_set/item_row_idle.png"
		if _sheet_state == STATE_INVENTORY_CRAFT_SELECT and item_id == _craft_base_item_id:
			panel_path = "sheet_set/item_row_selected.png"
		elif item_id == _selected_item_id:
			panel_path = "sheet_set/item_row_selected.png"
		elif _highlighted_item_ids.has(item_id):
			panel_path = "sheet_set/item_row_highlighted.png"
		button.modulate = Color(1, 1, 1, 1)
		if _highlighted_item_ids.has(item_id) and item_id != _craft_base_item_id:
			panel.modulate = Color(1.06, 1.22, 1.34, 1.0)
		elif item_id == _selected_item_id or (_sheet_state == STATE_INVENTORY_CRAFT_SELECT and item_id == _craft_base_item_id):
			panel.modulate = Color(1.10, 1.20, 1.30, 1.0)
		else:
			panel.modulate = Color(1, 1, 1, 1)
		_ui_kit_resolver.apply_panel(panel, panel_path)
		_ui_kit_resolver.apply_button(button, panel_path, panel_path)
		var badge := _item_badges.get(item_id) as Control
		if badge != null:
			badge.visible = _highlighted_item_ids.has(item_id) and item_id != _craft_base_item_id
			if badge.visible:
				badge.modulate = Color(1, 1, 1, 0.9)


func _current_recipe_outcome() -> Dictionary:
	if run_state == null or _craft_base_item_id.is_empty() or _selected_item_id.is_empty():
		return {
			"ok": false,
			"result_type": "invalid",
			"result_item_id": "",
			"result_item_data": {},
			"result_text": "재료 두 개를 모두 골라야 한다.",
			"minutes_elapsed": 0,
			"recipe_id": "",
		}
	return run_state.crafting_resolver.resolve(_craft_base_item_id, _selected_item_id, _mode_name, ContentLibrary)


func _ensure_selected_item_is_valid() -> void:
	if _selected_item_id.is_empty():
		return
	if _group_inventory_rows_by_item_id().has(_selected_item_id):
		return
	_selected_item_id = ""
	if _sheet_state == STATE_INVENTORY_CRAFT_SELECT:
		_sheet_state = STATE_INVENTORY_BROWSE
		_craft_base_item_id = ""


func _payload_sheet_matches_item(payload_sheet: Dictionary, item_id: String) -> bool:
	if payload_sheet.is_empty() or not bool(payload_sheet.get("visible", false)):
		return false
	var actions_variant: Variant = payload_sheet.get("actions", [])
	if typeof(actions_variant) != TYPE_ARRAY:
		return false
	for action_variant in actions_variant:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action_id := String((action_variant as Dictionary).get("id", ""))
		if action_id.ends_with("_%s" % item_id):
			return true
	return false


func _formatted_payload_description(payload_sheet: Dictionary) -> String:
	var lines: Array[String] = []
	var description := String(payload_sheet.get("description", ""))
	if not description.is_empty():
		lines.append(description)
	var usage_hint := String(payload_sheet.get("usage_hint", ""))
	if not usage_hint.is_empty():
		lines.append("용도: %s" % usage_hint)
	var cold_hint := String(payload_sheet.get("cold_hint", ""))
	if not cold_hint.is_empty():
		lines.append("한파: %s" % cold_hint)
	return "\n".join(lines)


func _formatted_payload_effect(payload_sheet: Dictionary) -> String:
	var lines: Array[String] = []
	var effect_text := String(payload_sheet.get("effect_text", ""))
	if not effect_text.is_empty():
		lines.append(effect_text)
	return "\n".join(lines)


func _formatted_item_description(item_data: Dictionary) -> String:
	var lines: Array[String] = []
	var description := String(item_data.get("description", ""))
	if not description.is_empty():
		lines.append(description)
	var usage_hint := String(item_data.get("usage_hint", ""))
	if not usage_hint.is_empty():
		lines.append("용도: %s" % usage_hint)
	var cold_hint := String(item_data.get("cold_hint", ""))
	if not cold_hint.is_empty():
		lines.append("한파: %s" % cold_hint)
	return "\n".join(lines)


func _formatted_item_effect(item_data: Dictionary) -> String:
	var parts: Array[String] = []
	var effect_text := _item_effect_text(item_data)
	if not effect_text.is_empty():
		parts.append(effect_text)
	return "\n".join(parts)


func _item_definition(item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}

	if run_state != null and run_state.inventory != null:
		var inventory_item: Dictionary = run_state.inventory.get_first_item_by_id(item_id)
		if not inventory_item.is_empty():
			var merged_item: Dictionary = inventory_item.duplicate(true)
			if ContentLibrary != null and ContentLibrary.has_method("get_item"):
				var content_variant: Variant = ContentLibrary.get_item(item_id)
				if typeof(content_variant) == TYPE_DICTIONARY and not (content_variant as Dictionary).is_empty():
					var content_item := (content_variant as Dictionary).duplicate(true)
					for key in merged_item.keys():
						content_item[key] = merged_item[key]
					return content_item
			return merged_item

	if ContentLibrary != null and ContentLibrary.has_method("get_item"):
		var fallback_variant: Variant = ContentLibrary.get_item(item_id)
		if typeof(fallback_variant) == TYPE_DICTIONARY:
			return (fallback_variant as Dictionary).duplicate(true)

	return {}


func _display_name_for_item(item_id: String) -> String:
	var item_data := _item_definition(item_id)
	return String(item_data.get("name", item_id if not item_id.is_empty() else "아이템"))


func _item_tags(item_data: Dictionary) -> Array[String]:
	var tags: Array[String] = []
	var item_tags_variant: Variant = item_data.get("item_tags", [])
	if typeof(item_tags_variant) != TYPE_ARRAY:
		return tags
	for tag_variant in item_tags_variant:
		var tag_text := String(tag_variant)
		if tag_text.is_empty():
			continue
		tags.append("#%s" % tag_text)
	return tags


func _item_charges_text(item_id: String, item_data: Dictionary) -> String:
	if run_state == null or not run_state.has_method("get_tool_charges"):
		return ""
	var max_charges := int(item_data.get("charges_max", item_data.get("max_charges", 0)))
	if max_charges <= 0:
		return ""
	var charge_label := String(item_data.get("charge_label", "잔량"))
	return "%s %d/%d" % [charge_label, run_state.get_tool_charges(item_id), max_charges]


func _item_effect_text(item_data: Dictionary) -> String:
	var parts: Array[String] = []
	var hunger_restore := int(item_data.get("hunger_restore", 0))
	if hunger_restore > 0:
		parts.append("허기 +%d" % hunger_restore)
	var thirst_restore := int(item_data.get("thirst_restore", 0))
	if thirst_restore != 0:
		parts.append("갈증 %s%d" % [_signed_prefix(thirst_restore), abs(thirst_restore)])
	var health_restore := int(item_data.get("health_restore", 0))
	if health_restore > 0:
		parts.append("체력 +%d" % health_restore)
	var fatigue_restore := int(item_data.get("fatigue_restore", 0))
	if fatigue_restore > 0:
		parts.append("피로 -%d" % fatigue_restore)
	var carry_weight := float(item_data.get("carry_weight", item_data.get("bulk", 0)))
	if carry_weight > 0.0:
		parts.append("무게 %.1fkg" % carry_weight)
	var carry_capacity_bonus := float(item_data.get("carry_capacity_bonus", item_data.get("carry_limit_bonus", 0)))
	if carry_capacity_bonus > 0.0:
		parts.append("운반 한계 +%.1fkg" % carry_capacity_bonus)
	var move_speed_bonus := int(item_data.get("move_speed_bonus", 0))
	if move_speed_bonus > 0:
		parts.append("이동속도 +%d" % move_speed_bonus)
	var fatigue_gain_bonus := float(item_data.get("fatigue_gain_bonus", 0.0))
	if fatigue_gain_bonus < 0.0:
		parts.append("피로 누적 -%d%%" % int(round(abs(fatigue_gain_bonus) * 100.0)))
	var equip_effects_variant: Variant = item_data.get("equip_effects", {})
	if typeof(equip_effects_variant) == TYPE_DICTIONARY:
		var equip_effects := equip_effects_variant as Dictionary
		var outdoor_exposure_multiplier := float(equip_effects.get("outdoor_exposure_drain_multiplier", 1.0))
		if outdoor_exposure_multiplier > 0.0 and outdoor_exposure_multiplier < 1.0:
			parts.append("야외 냉기 -%d%%" % int(round((1.0 - outdoor_exposure_multiplier) * 100.0)))
		var hazard_multipliers_variant: Variant = equip_effects.get("outdoor_hazard_multipliers", {})
		if typeof(hazard_multipliers_variant) == TYPE_DICTIONARY:
			parts.append_array(_outdoor_hazard_effect_texts(hazard_multipliers_variant as Dictionary))
	var equip_slot := String(item_data.get("equip_slot", ""))
	if not equip_slot.is_empty():
		parts.append("장착 슬롯: %s" % _slot_label(equip_slot))
	var use_minutes := int(item_data.get("use_minutes", 0))
	if use_minutes > 0:
		parts.append("소요 시간 %d분" % use_minutes)
	var charges_max := int(item_data.get("charges_max", item_data.get("max_charges", 0)))
	var charges_current := int(item_data.get("charges_current", item_data.get("charges", charges_max)))
	if charges_max > 0:
		var charge_label := String(item_data.get("charge_label", "잔량"))
		parts.append("%s %d/%d" % [charge_label, charges_current, charges_max])
	return "효과 없음" if parts.is_empty() else " / ".join(parts)


func _outdoor_hazard_effect_texts(hazard_multipliers: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for hazard_kind_variant in hazard_multipliers.keys():
		var hazard_kind := String(hazard_kind_variant)
		var block_variant: Variant = hazard_multipliers.get(hazard_kind, {})
		if typeof(block_variant) != TYPE_DICTIONARY:
			continue
		var block := block_variant as Dictionary
		for effect_key in ["exposure_loss", "fatigue_gain", "health_loss"]:
			var multiplier := float(block.get(effect_key, 1.0))
			if multiplier > 0.0 and multiplier < 1.0:
				result.append("%s %s -%d%%" % [
					_hazard_kind_label(hazard_kind),
					_hazard_effect_label(effect_key),
					int(round((1.0 - multiplier) * 100.0)),
				])
	return result


func _hazard_kind_label(hazard_kind: String) -> String:
	match hazard_kind:
		"black_ice":
			return "빙판"
		"wind_gap":
			return "틈바람"
		"all":
			return "야외 위험"
		_:
			return hazard_kind


func _hazard_effect_label(effect_key: String) -> String:
	match effect_key:
		"exposure_loss":
			return "체온 손실"
		"fatigue_gain":
			return "피로"
		"health_loss":
			return "부상"
		_:
			return effect_key


func _inventory_sheet_actions(item_data: Dictionary, item_id: String) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if bool(item_data.get("readable", false)):
		actions.append({
			"id": "read_inventory_%s" % item_id,
			"label": "읽는다",
		})
	if _is_consumable(item_data):
		actions.append({
			"id": "consume_inventory_%s" % item_id,
			"label": _consume_action_label(item_data),
		})
	if not String(item_data.get("equip_slot", "")).is_empty():
		actions.append({
			"id": "equip_inventory_%s" % item_id,
			"label": "장착한다",
		})
	actions.append({
		"id": "drop_inventory_%s" % item_id,
		"label": "버린다",
	})
	return actions


func _is_consumable(item_data: Dictionary) -> bool:
	return int(item_data.get("hunger_restore", 0)) > 0 \
		or int(item_data.get("thirst_restore", 0)) != 0 \
		or int(item_data.get("health_restore", 0)) > 0 \
		or int(item_data.get("fatigue_restore", 0)) > 0


func _consume_action_label(item_data: Dictionary) -> String:
	var category := String(item_data.get("category", ""))
	if category == "drink":
		return "마신다"
	if category == "medical" or category == "stimulant":
		return "사용한다"
	return "먹는다"


func _slot_label(slot_id: String) -> String:
	match slot_id:
		"back":
			return "등"
		"feet":
			return "발"
		"feet_layer":
			return "양말"
		"outer":
			return "외투"
		"head":
			return "머리"
		"hands":
			return "손"
		"hands_layer":
			return "장갑 안감"
		"waist":
			return "허리"
		"pocket":
			return "주머니"
		"neck":
			return "목"
		"face":
			return "얼굴"
		"body":
			return "몸"
		_:
			return slot_id


func _signed_prefix(value: int) -> String:
	return "+" if value >= 0 else "-"


func _render_codex() -> void:
	if _codex_rows == null:
		return

	_clear_children(_codex_rows)
	var grouped_rows := _all_codex_rows()
	for category_id in _ordered_codex_category_ids(grouped_rows):
		var category_rows: Array[Dictionary] = grouped_rows.get(category_id, [])
		if category_rows.is_empty():
			continue

		var discovered_count := 0
		for row in category_rows:
			if _recipe_is_known(String(row.get("id", ""))):
				discovered_count += 1

		var heading := Label.new()
		heading.text = "%s %d/%d" % [_codex_category_label(category_id), discovered_count, category_rows.size()]
		_apply_label_style(heading, 13, TEXT_PRIMARY_COLOR, 1)
		_codex_rows.add_child(heading)

		for row in category_rows:
			if _recipe_is_known(String(row.get("id", ""))):
				_codex_rows.add_child(_create_known_codex_row(row))
			else:
				_codex_rows.add_child(_create_unknown_codex_row())


func _all_codex_rows() -> Dictionary:
	var grouped := {}
	if ContentLibrary == null or not ContentLibrary.has_method("get_crafting_combination_rows"):
		return grouped

	for row_variant in ContentLibrary.get_crafting_combination_rows():
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row := (row_variant as Dictionary).duplicate(true)
		var category_id := _codex_category_for_row(row)
		if category_id.is_empty():
			continue
		var bucket: Array[Dictionary] = []
		for existing_row_variant in grouped.get(category_id, []):
			if typeof(existing_row_variant) == TYPE_DICTIONARY:
				bucket.append((existing_row_variant as Dictionary).duplicate(true))
		bucket.append(row)
		grouped[category_id] = bucket

	for category_id_variant in grouped.keys():
		var category_id := String(category_id_variant)
		var rows: Array[Dictionary] = []
		for existing_row_variant in grouped.get(category_id, []):
			if typeof(existing_row_variant) == TYPE_DICTIONARY:
				rows.append((existing_row_variant as Dictionary).duplicate(true))
		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var a_order := int(a.get("codex_order", 9999))
			var b_order := int(b.get("codex_order", 9999))
			if a_order != b_order:
				return a_order < b_order
			return _codex_summary_text(a) < _codex_summary_text(b)
		)
		grouped[category_id] = rows

	return grouped


func _ordered_codex_category_ids(grouped_rows: Dictionary) -> Array[String]:
	var ordered: Array[String] = []
	for category_id in CODEX_CATEGORY_ORDER:
		if grouped_rows.has(category_id):
			ordered.append(category_id)
	for category_id_variant in grouped_rows.keys():
		var category_id := String(category_id_variant)
		if not ordered.has(category_id):
			ordered.append(category_id)
	return ordered


func _recipe_is_known(recipe_id: String) -> bool:
	return run_state != null and run_state.has_method("knows_recipe") and run_state.knows_recipe(recipe_id)


func _create_unknown_codex_row() -> Control:
	var label := Label.new()
	label.text = "???"
	_apply_label_style(label, 13, Color(0.8, 0.82, 0.86, 0.94), 1)
	return label


func _create_known_codex_row(row: Dictionary) -> Control:
	var card := PanelContainer.new()
	_ui_kit_resolver.apply_panel(card, "overlay/map_info_chip.png")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	box.add_child(top_row)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(20, 20)
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture = _item_icon_for(String(row.get("result_item_id", "")))
	icon_rect.visible = icon_rect.texture != null
	top_row.add_child(icon_rect)

	var summary := Label.new()
	summary.text = _codex_summary_text(row)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_label_style(summary, 14, TEXT_PRIMARY_COLOR, 1)
	top_row.add_child(summary)

	var details := Label.new()
	details.text = _codex_detail_text(row)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_style(details, 12, TEXT_SECONDARY_COLOR, 1)
	box.add_child(details)

	return card


func _codex_summary_text(row: Dictionary) -> String:
	var ingredients_variant: Variant = row.get("ingredients", [])
	var ingredient_names: Array[String] = []
	if typeof(ingredients_variant) == TYPE_ARRAY:
		for ingredient_id_variant in ingredients_variant:
			ingredient_names.append(_display_name_for_item(String(ingredient_id_variant)))

	var result_item_id := String(row.get("result_item_id", ""))
	var result_name := _display_name_for_item(result_item_id)
	return "%s -> %s" % [" + ".join(ingredient_names), result_name]


func _codex_detail_text(row: Dictionary) -> String:
	var lines: Array[String] = []
	var result_text := String(row.get("result_text", ""))
	if not result_text.is_empty():
		lines.append(result_text)
	var conditions := _codex_conditions_text(row)
	if not conditions.is_empty():
		lines.append(conditions)
	return "\n".join(lines)


func _item_icon_for(item_id: String) -> Texture2D:
	if item_id.is_empty():
		return null
	return _item_icon_resolver.get_item_icon(item_id)


func _inventory_icon_slot_style() -> StyleBox:
	var stylebox := _ui_kit_resolver.get_stylebox("sheet/inventory_icon_slot.png")
	if stylebox != null:
		return stylebox.duplicate()
	var style := StyleBoxFlat.new()
	style.bg_color = INVENTORY_ICON_SLOT_STYLE["bg"]
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = INVENTORY_ICON_SLOT_STYLE["border"]
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style


func _compatibility_badge_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.24, 0.30, 0.94)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.48, 0.76, 0.90, 0.95)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_right = 7
	style.corner_radius_bottom_left = 7
	style.content_margin_left = 4
	style.content_margin_right = 4
	return style


func _codex_conditions_text(row: Dictionary) -> String:
	var conditions: Array[String] = []
	var contexts_variant: Variant = row.get("contexts", [])
	if typeof(contexts_variant) == TYPE_ARRAY:
		var contexts := contexts_variant as Array
		if contexts.size() == 1 and String(contexts[0]) == "indoor":
			conditions.append("실내 전용")

	var required_tool_ids_variant: Variant = row.get("required_tool_ids", [])
	if typeof(required_tool_ids_variant) == TYPE_ARRAY:
		var tool_names: Array[String] = []
		for tool_item_id_variant in required_tool_ids_variant:
			var tool_item_id := String(tool_item_id_variant)
			if tool_item_id.is_empty():
				continue
			tool_names.append(_display_name_for_item(tool_item_id))
		if not tool_names.is_empty():
			conditions.append("도구: %s" % ", ".join(tool_names))

	return "\n".join(conditions)


func _codex_category_for_row(row: Dictionary) -> String:
	var explicit_category := String(row.get("codex_category", ""))
	if not explicit_category.is_empty():
		return explicit_category

	var recipe_id := String(row.get("id", ""))
	var result_item_id := String(row.get("result_item_id", ""))
	var lower_text := "%s %s" % [recipe_id, result_item_id]
	if _text_matches_any(lower_text, ["water", "tea", "coffee", "soup", "rice", "meal"]):
		return "food_drink"
	if _text_matches_any(lower_text, ["gauze", "alcohol", "wipe", "soap", "tooth", "disinfect", "hygiene", "medical", "wash", "wound", "mask"]):
		return "hygiene_medical"
	if _text_matches_any(lower_text, ["fuel", "stove", "candle", "tinder", "lantern", "heat", "blanket", "warmer", "wrap", "hot_"]):
		return "fire_heat"
	return "repair_fortify"


func _text_matches_any(text: String, fragments: Array[String]) -> bool:
	for fragment in fragments:
		if text.find(fragment) != -1:
			return true
	return false


func _codex_category_label(category_id: String) -> String:
	return String(CODEX_CATEGORY_LABELS.get(category_id, category_id))


func _on_inventory_tab_pressed() -> void:
	open_inventory()


func _on_codex_tab_pressed() -> void:
	open_codex()


func _on_close_pressed() -> void:
	close_sheet()


func _on_cancel_craft_pressed() -> void:
	_craft_base_item_id = ""
	_last_craft_feedback_text = ""
	_sheet_state = STATE_INVENTORY_BROWSE
	_refresh_highlights()
	_render()


func _on_craft_confirm_pressed() -> void:
	confirm_craft()


func _on_inventory_item_pressed(item_id: String) -> void:
	select_inventory_item(item_id)


func _on_detail_close_pressed() -> void:
	_selected_item_id = ""
	if _sheet_state == STATE_INVENTORY_CRAFT_SELECT:
		_craft_base_item_id = ""
		_last_craft_feedback_text = ""
		_sheet_state = STATE_INVENTORY_BROWSE
	_refresh_highlights()
	_render()


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _apply_ui_skin() -> void:
	if _skin_applied:
		return
	_skin_applied = true

	var sheet := get_node_or_null("Sheet") as PanelContainer
	var craft_card := get_node_or_null("CraftCard") as PanelContainer
	var item_detail_sheet := get_node_or_null("ItemDetailSheet") as PanelContainer
	var material_one_card := get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialOneCard") as PanelContainer
	var material_two_card := get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialTwoCard") as PanelContainer
	var result_card := get_node_or_null("CraftCard/Padding/VBox/ResultCard") as PanelContainer
	var material_one_icon_slot := get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialOneCard/Padding/VBox/ValueRow/MaterialOneIconSlot") as PanelContainer
	var material_two_icon_slot := get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialTwoCard/Padding/VBox/ValueRow/MaterialTwoIconSlot") as PanelContainer
	var result_icon_slot := get_node_or_null("CraftCard/Padding/VBox/ResultCard/Padding/VBox/ValueRow/ResultIconSlot") as PanelContainer
	_ui_kit_resolver.apply_panel(sheet, "sheet/sheet_bg_compact.png")
	_ui_kit_resolver.apply_panel(craft_card, "sheet/detail_panel_compact.png")
	_ui_kit_resolver.apply_panel(item_detail_sheet, "sheet/detail_panel_compact.png")
	_ui_kit_resolver.apply_panel(material_one_card, "sheet/inventory_row_compact_idle.png")
	_ui_kit_resolver.apply_panel(material_two_card, "sheet/inventory_row_compact_idle.png")
	_ui_kit_resolver.apply_panel(result_card, "sheet/inventory_row_compact_selected.png")
	_ui_kit_resolver.apply_panel(material_one_icon_slot, "sheet/inventory_icon_slot.png")
	_ui_kit_resolver.apply_panel(material_two_icon_slot, "sheet/inventory_icon_slot.png")
	_ui_kit_resolver.apply_panel(result_icon_slot, "sheet/inventory_icon_slot.png")
	_style_sheet_tab(_inventory_tab_button, true)
	_style_sheet_tab(_codex_tab_button, false)
	_ui_kit_resolver.apply_button(
		_close_button,
		"hud/hud_icon_button_compact_normal.png",
		"hud/hud_icon_button_compact_pressed.png",
		"hud/hud_icon_button_compact_normal.png",
		"hud/hud_icon_button_compact_disabled.png"
	)
	_ui_kit_resolver.apply_button(
		_detail_close_button,
		"hud/hud_icon_button_compact_normal.png",
		"hud/hud_icon_button_compact_pressed.png",
		"hud/hud_icon_button_compact_normal.png",
		"hud/hud_icon_button_compact_disabled.png"
	)
	_ui_kit_resolver.apply_button(
		_craft_confirm_button,
		"sheet/sheet_button_secondary_normal.png",
		"sheet/sheet_button_secondary_pressed.png"
	)
	_ui_kit_resolver.apply_button(
		_craft_cancel_button,
		"sheet/sheet_button_secondary_normal.png",
		"sheet/sheet_button_secondary_pressed.png"
	)
	if _title_label != null:
		_apply_label_style(_title_label, 19, TEXT_PRIMARY_COLOR, 2)
	if _status_label != null:
		_apply_label_style(_status_label, 15, TEXT_SECONDARY_COLOR, 3)
	if _browse_hint_label != null:
		_apply_label_style(_browse_hint_label, 15, TEXT_SECONDARY_COLOR, 3)
	if _inventory_tab_button != null:
		_apply_button_text_style(_inventory_tab_button, 15, TEXT_PRIMARY_COLOR, 2)
	if _codex_tab_button != null:
		_apply_button_text_style(_codex_tab_button, 15, TEXT_PRIMARY_COLOR, 2)
	var craft_header_label := get_node_or_null("CraftCard/Padding/VBox/HeaderLabel") as Label
	if craft_header_label != null:
		_apply_label_style(craft_header_label, 13, TEXT_SECONDARY_COLOR, 1)
	var material_one_title := get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialOneCard/Padding/VBox/MaterialOneTitleLabel") as Label
	if material_one_title != null:
		_apply_label_style(material_one_title, 13, TEXT_SECONDARY_COLOR, 1)
	var material_two_title := get_node_or_null("CraftCard/Padding/VBox/SlotsRow/MaterialTwoCard/Padding/VBox/MaterialTwoTitleLabel") as Label
	if material_two_title != null:
		_apply_label_style(material_two_title, 13, TEXT_SECONDARY_COLOR, 1)
	var result_title := get_node_or_null("CraftCard/Padding/VBox/ResultCard/Padding/VBox/ResultTitleLabel") as Label
	if result_title != null:
		_apply_label_style(result_title, 13, TEXT_SECONDARY_COLOR, 1)
	if _material_one_value_label != null:
		_apply_label_style(_material_one_value_label, 15, TEXT_PRIMARY_COLOR, 2)
	if _material_two_value_label != null:
		_apply_label_style(_material_two_value_label, 15, TEXT_PRIMARY_COLOR, 2)
	if _craft_result_value_label != null:
		_apply_label_style(_craft_result_value_label, 15, TEXT_PRIMARY_COLOR, 2)
	if _craft_result_hint_label != null:
		_apply_label_style(_craft_result_hint_label, 13, TEXT_SECONDARY_COLOR, 1)
	if _craft_confirm_button != null:
		_apply_button_text_style(_craft_confirm_button, 15, TEXT_PRIMARY_COLOR, 2)
	if _craft_cancel_button != null:
		_apply_button_text_style(_craft_cancel_button, 15, TEXT_PRIMARY_COLOR, 2)
	if _item_name_label != null:
		_apply_label_style(_item_name_label, 17, TEXT_PRIMARY_COLOR, 2)
	if _item_description_label != null:
		_apply_label_style(_item_description_label, 16, TEXT_PRIMARY_COLOR, 3)
	if _item_effect_label != null:
		_apply_label_style(_item_effect_label, 15, TEXT_SECONDARY_COLOR, 3)
	if _mode_message_label != null:
		_apply_label_style(_mode_message_label, 15, TEXT_SECONDARY_COLOR, 3)
	if _close_button != null:
		_close_button.text = ""
		_close_button.tooltip_text = "닫기"
		_close_button.custom_minimum_size = Vector2(36, 36)
		_close_button.icon = _ui_kit_resolver.get_texture("icons/light_24/close.png")
		_close_button.expand_icon = false
	if _detail_close_button != null:
		_detail_close_button.text = ""
		_detail_close_button.tooltip_text = "접기"
		_detail_close_button.custom_minimum_size = Vector2(36, 36)
		_detail_close_button.icon = _ui_kit_resolver.get_texture("icons/light_24/close.png")
		_detail_close_button.expand_icon = false


func _style_sheet_tab(button: Button, active: bool) -> void:
	if button == null:
		return
	var normal_path := "sheet/sheet_tab_compact_active.png" if active else "sheet/sheet_tab_compact_idle.png"
	var pressed_path := normal_path
	_ui_kit_resolver.apply_button(button, normal_path, pressed_path)
	_apply_button_text_style(button, 15, TEXT_PRIMARY_COLOR if active else TEXT_SECONDARY_COLOR, 2)
	button.button_pressed = active
	button.modulate = Color(1.08, 1.16, 1.24, 1.0) if active else Color(0.76, 0.80, 0.88, 0.94)


func _apply_label_style(label: Label, font_size: int, font_color: Color, outline_size: int = 1) -> void:
	if label == null:
		return
	label.modulate = font_color
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", TEXT_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", outline_size)


func _apply_button_text_style(button: Button, font_size: int, font_color: Color, outline_size: int = 1) -> void:
	if button == null:
		return
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(font_color.r, font_color.g, font_color.b, 0.55))
	button.add_theme_color_override("font_outline_color", TEXT_OUTLINE_COLOR)
	button.add_theme_constant_override("outline_size", outline_size)
