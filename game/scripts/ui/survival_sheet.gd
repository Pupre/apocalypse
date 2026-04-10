extends CanvasLayer

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

const DEFAULT_BUTTON_MODULATE := Color(1, 1, 1, 1)
const SELECTED_BUTTON_MODULATE := Color(0.74, 0.9, 1.0, 1.0)
const CRAFT_BASE_BUTTON_MODULATE := Color(0.7, 0.84, 1.0, 1.0)
const DIM_BUTTON_MODULATE := Color(0.56, 0.58, 0.64, 0.9)
const HINT_PULSE_BASE := Color(1.18, 0.97, 0.46, 1.0)
const HINT_PULSE_TARGET := Color(1.42, 1.08, 0.56, 1.0)
const HINT_PULSE_SPEED := 5.4

var run_state = null
var _mode_name := "indoor"
var _active_tab := "inventory"
var _sheet_state := STATE_HIDDEN
var _selected_item_id := ""
var _craft_base_item_id := ""
var _last_craft_feedback_text := ""
var _highlighted_item_ids: Array[String] = []
var _inventory_payload := {
	"title": "가방",
	"status_text": "",
	"rows": [],
	"selected_sheet": {"visible": false},
	"feedback_message": "",
}
var _pulse_time := 0.0
var _item_buttons: Dictionary = {}
var _title_label: Label = null
var _status_label: Label = null
var _inventory_tab_button: Button = null
var _codex_tab_button: Button = null
var _close_button: Button = null
var _craft_context_strip: HBoxContainer = null
var _craft_context_label: Label = null
var _cancel_craft_button: Button = null
var _inventory_pane: Control = null
var _inventory_items: VBoxContainer = null
var _item_detail_card: Control = null
var _item_name_label: Label = null
var _item_description_label: Label = null
var _item_effect_label: Label = null
var _mode_message_label: Label = null
var _primary_actions: HBoxContainer = null
var _secondary_actions: HBoxContainer = null
var _codex_pane: Control = null
var _codex_rows: VBoxContainer = null


func _ready() -> void:
	_cache_nodes()
	_bind_buttons()
	visible = false
	set_process(true)
	_render()


func _process(delta: float) -> void:
	_pulse_time += delta
	if visible and not _highlighted_item_ids.is_empty():
		_refresh_item_button_states()


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
	_last_craft_feedback_text = ""
	_refresh_highlights()
	_render()


func open_codex() -> void:
	visible = true
	_active_tab = "codex"
	_sheet_state = STATE_CODEX_BROWSE
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
	_selected_item_id = item_id
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
	_title_label = get_node_or_null("Sheet/VBox/Header/TitleLabel") as Label
	_status_label = get_node_or_null("Sheet/VBox/Header/StatusLabel") as Label
	_inventory_tab_button = get_node_or_null("Sheet/VBox/Tabs/InventoryTabButton") as Button
	_codex_tab_button = get_node_or_null("Sheet/VBox/Tabs/CodexTabButton") as Button
	_close_button = get_node_or_null("Sheet/VBox/Header/CloseButton") as Button
	_craft_context_strip = get_node_or_null("Sheet/VBox/CraftContextStrip") as HBoxContainer
	_craft_context_label = get_node_or_null("Sheet/VBox/CraftContextStrip/CraftContextLabel") as Label
	_cancel_craft_button = get_node_or_null("Sheet/VBox/CraftContextStrip/CancelCraftButton") as Button
	_inventory_pane = get_node_or_null("Sheet/VBox/InventoryPane") as Control
	_inventory_items = get_node_or_null("Sheet/VBox/InventoryPane/InventoryScroll/InventoryItems") as VBoxContainer
	_item_detail_card = get_node_or_null("Sheet/VBox/InventoryPane/ItemDetailCard") as Control
	_item_name_label = get_node_or_null("Sheet/VBox/InventoryPane/ItemDetailCard/VBox/ItemNameLabel") as Label
	_item_description_label = get_node_or_null("Sheet/VBox/InventoryPane/ItemDetailCard/VBox/ItemDescriptionLabel") as Label
	_item_effect_label = get_node_or_null("Sheet/VBox/InventoryPane/ItemDetailCard/VBox/ItemEffectLabel") as Label
	_mode_message_label = get_node_or_null("Sheet/VBox/InventoryPane/ItemDetailCard/VBox/ModeMessageLabel") as Label
	_primary_actions = get_node_or_null("Sheet/VBox/InventoryPane/ItemDetailCard/VBox/DetailActions/PrimaryActions") as HBoxContainer
	_secondary_actions = get_node_or_null("Sheet/VBox/InventoryPane/ItemDetailCard/VBox/DetailActions/SecondaryActions") as HBoxContainer
	_codex_pane = get_node_or_null("Sheet/VBox/CodexPane") as Control
	_codex_rows = get_node_or_null("Sheet/VBox/CodexPane/CodexScroll/CodexRows") as VBoxContainer


func _bind_buttons() -> void:
	if _inventory_tab_button != null and not _inventory_tab_button.pressed.is_connected(Callable(self, "_on_inventory_tab_pressed")):
		_inventory_tab_button.pressed.connect(Callable(self, "_on_inventory_tab_pressed"))
	if _codex_tab_button != null and not _codex_tab_button.pressed.is_connected(Callable(self, "_on_codex_tab_pressed")):
		_codex_tab_button.pressed.connect(Callable(self, "_on_codex_tab_pressed"))
	if _close_button != null and not _close_button.pressed.is_connected(Callable(self, "_on_close_pressed")):
		_close_button.pressed.connect(Callable(self, "_on_close_pressed"))
	if _cancel_craft_button != null and not _cancel_craft_button.pressed.is_connected(Callable(self, "_on_cancel_craft_pressed")):
		_cancel_craft_button.pressed.connect(Callable(self, "_on_cancel_craft_pressed"))


func _render() -> void:
	_render_header()
	_render_tabs()
	_render_craft_context_strip()
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
	if _inventory_tab_button != null:
		_inventory_tab_button.button_pressed = _active_tab == "inventory"
		_inventory_tab_button.modulate = DEFAULT_BUTTON_MODULATE if _active_tab == "inventory" else DIM_BUTTON_MODULATE
	if _codex_tab_button != null:
		_codex_tab_button.button_pressed = _active_tab == "codex"
		_codex_tab_button.modulate = DEFAULT_BUTTON_MODULATE if _active_tab == "codex" else DIM_BUTTON_MODULATE


func _render_craft_context_strip() -> void:
	var craft_active := _sheet_state == STATE_INVENTORY_CRAFT_SELECT and not _craft_base_item_id.is_empty()
	if _craft_context_strip != null:
		_craft_context_strip.visible = craft_active
	if _craft_context_label != null:
		_craft_context_label.text = "조합 중: %s" % _display_name_for_item(_craft_base_item_id) if craft_active else ""


func _render_inventory() -> void:
	if _inventory_items == null or _item_detail_card == null:
		return

	_clear_children(_inventory_items)
	_item_buttons.clear()

	var inventory_rows := _inventory_rows_for_render()
	for row in inventory_rows:
		_inventory_items.add_child(_create_inventory_row(row))

	_refresh_item_button_states()
	_render_item_detail()


func _create_inventory_row(row: Dictionary) -> Control:
	var item_id := String(row.get("item_id", ""))
	var label_text := String(row.get("label", ""))
	var tag_texts_variant: Variant = row.get("tag_texts", [])
	var charges_text := String(row.get("charges_text", ""))

	var panel := PanelContainer.new()
	panel.name = "InventoryRow_%s" % item_id
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var button := Button.new()
	button.name = "RowButton"
	button.text = label_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 48)
	button.pressed.connect(Callable(self, "_on_inventory_item_pressed").bind(item_id))
	box.add_child(button)
	_item_buttons[item_id] = button

	var meta_lines: Array[String] = []
	if typeof(tag_texts_variant) == TYPE_ARRAY:
		var tag_labels: Array[String] = []
		for tag_variant in tag_texts_variant:
			var tag_text := String(tag_variant)
			if tag_text.is_empty():
				continue
			tag_labels.append(tag_text)
		if not tag_labels.is_empty():
			meta_lines.append(" ".join(tag_labels))
	if not charges_text.is_empty():
		meta_lines.append(charges_text)

	if not meta_lines.is_empty():
		var meta_label := Label.new()
		meta_label.name = "MetaLabel"
		meta_label.text = "\n".join(meta_lines)
		meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		meta_label.modulate = Color(0.82, 0.86, 0.9, 0.96)
		box.add_child(meta_label)

	return panel


func _render_item_detail() -> void:
	var sheet := _selected_item_sheet()
	if _item_name_label != null:
		_item_name_label.text = String(sheet.get("title", "아이템"))
	if _item_description_label != null:
		_item_description_label.text = String(sheet.get("description", "아이템을 선택하면 설명이 나타난다."))
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
			button.pressed.connect(func() -> void:
				inventory_action_requested.emit(action_id)
			)
			_primary_actions.add_child(button)

	var craft_button := Button.new()
	craft_button.text = "조합" if _sheet_state == STATE_INVENTORY_CRAFT_SELECT else "조합 시작"
	craft_button.disabled = (_sheet_state == STATE_INVENTORY_CRAFT_SELECT and not can_attempt_craft()) or (_sheet_state != STATE_INVENTORY_CRAFT_SELECT and _selected_item_id.is_empty())
	craft_button.pressed.connect(func() -> void:
		if _sheet_state == STATE_INVENTORY_CRAFT_SELECT:
			confirm_craft()
		else:
			begin_craft_mode(_selected_item_id)
	)
	_secondary_actions.add_child(craft_button)


func _selected_item_sheet() -> Dictionary:
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
		return String(_inventory_payload.get("feedback_message", ""))
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
		return rows

	var grouped := _group_inventory_rows_by_item_id()
	var item_ids: Array[String] = []
	for item_id_variant in grouped.keys():
		item_ids.append(String(item_id_variant))
	item_ids.sort_custom(func(a: String, b: String) -> bool: return _display_name_for_item(a) < _display_name_for_item(b))

	for item_id in item_ids:
		var item_data := _item_definition(item_id)
		rows.append({
			"item_id": item_id,
			"count": int(grouped.get(item_id, 0)),
			"label": "%s x%d" % [_display_name_for_item(item_id), int(grouped.get(item_id, 0))],
			"action_id": "inspect_inventory_%s" % item_id,
			"tag_texts": _item_tags(item_data),
			"charges_text": _item_charges_text(item_id, item_data),
		})

	return rows


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
	if run_state != null and run_state.has_method("is_hard_mode") and run_state.is_hard_mode():
		return
	_highlighted_item_ids = _compatible_secondary_item_ids(_craft_base_item_id)


func _compatible_secondary_item_ids(primary_item_id: String) -> Array[String]:
	var candidate_ids: Array[String] = []
	var grouped := _group_inventory_rows_by_item_id()
	for item_id_variant in grouped.keys():
		var item_id := String(item_id_variant)
		if item_id == primary_item_id and int(grouped[item_id]) < 2:
			continue
		var preview: Dictionary = run_state.crafting_resolver.resolve(primary_item_id, item_id, _mode_name, ContentLibrary)
		if String(preview.get("recipe_id", "")).is_empty():
			continue
		candidate_ids.append(item_id)
	return candidate_ids


func _refresh_item_button_states() -> void:
	for item_id_variant in _item_buttons.keys():
		var item_id := String(item_id_variant)
		var button := _item_buttons.get(item_id) as Button
		if button == null:
			continue

		var button_color := DEFAULT_BUTTON_MODULATE
		if _sheet_state == STATE_INVENTORY_CRAFT_SELECT and item_id == _craft_base_item_id:
			button_color = CRAFT_BASE_BUTTON_MODULATE
		elif item_id == _selected_item_id:
			button_color = SELECTED_BUTTON_MODULATE
		elif _highlighted_item_ids.has(item_id):
			var pulse := 0.5 + (0.5 * sin(_pulse_time * HINT_PULSE_SPEED))
			button_color = HINT_PULSE_BASE.lerp(HINT_PULSE_TARGET, pulse)
		button.modulate = button_color


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
	var item_tags_variant: Variant = payload_sheet.get("item_tags", [])
	if typeof(item_tags_variant) == TYPE_ARRAY:
		var tag_labels: Array[String] = []
		for tag_variant in item_tags_variant:
			var tag_text := String(tag_variant)
			if tag_text.is_empty():
				continue
			tag_labels.append("#%s" % tag_text)
		if not tag_labels.is_empty():
			lines.append(" ".join(tag_labels))
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
	var item_tags := _item_tags(item_data)
	if not item_tags.is_empty():
		parts.append(" ".join(item_tags))
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
	var carry_limit_bonus := int(item_data.get("carry_limit_bonus", 0))
	if carry_limit_bonus > 0:
		parts.append("소지 한도 +%d" % carry_limit_bonus)
	var move_speed_bonus := int(item_data.get("move_speed_bonus", 0))
	if move_speed_bonus > 0:
		parts.append("이동속도 +%d" % move_speed_bonus)
	var fatigue_gain_bonus := float(item_data.get("fatigue_gain_bonus", 0.0))
	if fatigue_gain_bonus < 0.0:
		parts.append("피로 누적 -%d%%" % int(round(abs(fatigue_gain_bonus) * 100.0)))
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
		"hands":
			return "손"
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
		heading.modulate = Color(0.92, 0.92, 0.92, 0.96)
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
	label.modulate = Color(0.78, 0.78, 0.78, 0.92)
	return label


func _create_known_codex_row(row: Dictionary) -> Control:
	var card := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var summary := Label.new()
	summary.text = _codex_summary_text(row)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(summary)

	var details := Label.new()
	details.text = _codex_detail_text(row)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.modulate = Color(0.86, 0.88, 0.92, 0.94)
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


func _on_inventory_item_pressed(item_id: String) -> void:
	select_inventory_item(item_id)


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
