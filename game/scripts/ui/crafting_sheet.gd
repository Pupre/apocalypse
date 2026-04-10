extends CanvasLayer

signal closed
signal craft_applied(outcome: Dictionary)

const CODEX_CATEGORY_ORDER := ["fire_heat", "food_drink", "hygiene_medical", "repair_fortify"]
const CODEX_CATEGORY_LABELS := {
	"fire_heat": "불 / 열",
	"food_drink": "음식 / 음료",
	"hygiene_medical": "위생 / 의료",
	"repair_fortify": "수리 / 보강",
}
const DEFAULT_BUTTON_MODULATE := Color(1, 1, 1, 1)
const HINT_PULSE_BASE := Color(1.0, 0.96, 0.72, 1.0)
const HINT_PULSE_AMPLITUDE := 0.18
const HINT_PULSE_SPEED := 0.008

var run_state = null
var _context_mode_name := ""
var _active_tab := "direct"
var _selected_primary_item_id := ""
var _selected_secondary_item_id := ""
var _item_buttons: Dictionary = {}
var _highlighted_item_ids: Array[String] = []
var _title_label: Label = null
var _close_button: Button = null
var _direct_tab_button: Button = null
var _codex_tab_button: Button = null
var _direct_pane: Control = null
var _codex_pane: Control = null
var _primary_slot_button: Button = null
var _secondary_slot_button: Button = null
var _combine_button: Button = null
var _result_label: Label = null
var _items_container: VBoxContainer = null
var _codex_rows: VBoxContainer = null


func _ready() -> void:
	_cache_nodes()
	_bind_buttons()
	visible = false
	set_process(true)
	_refresh_slots()
	_refresh_result_text("")
	_refresh_tab_state()


func bind_run_state(value) -> void:
	run_state = value
	_rebuild_inventory_buttons()
	_render_codex()


func open_for_mode(mode_name: String, initial_tab: String = "direct") -> void:
	_context_mode_name = mode_name
	_reset_selection()
	visible = true
	_refresh_header()
	_rebuild_inventory_buttons()
	_set_active_tab(initial_tab)


func close_sheet() -> void:
	visible = false
	_reset_selection()
	closed.emit()


func get_context_mode_name() -> String:
	return _context_mode_name


func get_active_tab_id() -> String:
	return _active_tab


func get_highlighted_item_ids() -> Array[String]:
	return _highlighted_item_ids.duplicate()


func _cache_nodes() -> void:
	_title_label = get_node_or_null("Panel/VBox/Header/TitleLabel") as Label
	_close_button = get_node_or_null("Panel/VBox/Header/CloseButton") as Button
	_direct_tab_button = get_node_or_null("Panel/VBox/Tabs/DirectTabButton") as Button
	_codex_tab_button = get_node_or_null("Panel/VBox/Tabs/CodexTabButton") as Button
	_direct_pane = get_node_or_null("Panel/VBox/DirectPane") as Control
	_codex_pane = get_node_or_null("Panel/VBox/CodexPane") as Control
	_primary_slot_button = get_node_or_null("Panel/VBox/DirectPane/SlotsRow/PrimarySlotButton") as Button
	_secondary_slot_button = get_node_or_null("Panel/VBox/DirectPane/SlotsRow/SecondarySlotButton") as Button
	_combine_button = get_node_or_null("Panel/VBox/DirectPane/SlotsRow/CombineButton") as Button
	_result_label = get_node_or_null("Panel/VBox/DirectPane/ResultCard/ResultLabel") as Label
	_items_container = get_node_or_null("Panel/VBox/DirectPane/InventoryScroll/Items") as VBoxContainer
	_codex_rows = get_node_or_null("Panel/VBox/CodexPane/CodexScroll/CodexRows") as VBoxContainer


func _bind_buttons() -> void:
	if _close_button != null and not _close_button.pressed.is_connected(Callable(self, "_on_close_pressed")):
		_close_button.pressed.connect(Callable(self, "_on_close_pressed"))
	if _direct_tab_button != null and not _direct_tab_button.pressed.is_connected(Callable(self, "_on_direct_tab_pressed")):
		_direct_tab_button.pressed.connect(Callable(self, "_on_direct_tab_pressed"))
	if _codex_tab_button != null and not _codex_tab_button.pressed.is_connected(Callable(self, "_on_codex_tab_pressed")):
		_codex_tab_button.pressed.connect(Callable(self, "_on_codex_tab_pressed"))
	if _primary_slot_button != null and not _primary_slot_button.pressed.is_connected(Callable(self, "_on_primary_slot_pressed")):
		_primary_slot_button.pressed.connect(Callable(self, "_on_primary_slot_pressed"))
	if _secondary_slot_button != null and not _secondary_slot_button.pressed.is_connected(Callable(self, "_on_secondary_slot_pressed")):
		_secondary_slot_button.pressed.connect(Callable(self, "_on_secondary_slot_pressed"))
	if _combine_button != null and not _combine_button.pressed.is_connected(Callable(self, "_on_combine_pressed")):
		_combine_button.pressed.connect(Callable(self, "_on_combine_pressed"))


func _refresh_header() -> void:
	if _title_label == null:
		return

	var context_label := "실내" if _context_mode_name == "indoor" else "실외"
	_title_label.text = "%s 조합" % context_label


func _set_active_tab(tab_id: String) -> void:
	_active_tab = "codex" if tab_id == "codex" else "direct"
	_refresh_tab_state()
	if _active_tab == "direct":
		_rebuild_inventory_buttons()
	else:
		_render_codex()


func _refresh_tab_state() -> void:
	if _direct_pane != null:
		_direct_pane.visible = _active_tab == "direct"
	if _codex_pane != null:
		_codex_pane.visible = _active_tab == "codex"
	if _direct_tab_button != null:
		_direct_tab_button.button_pressed = _active_tab == "direct"
		_direct_tab_button.modulate = Color(1, 1, 1, 1) if _active_tab == "direct" else Color(0.76, 0.79, 0.84, 0.96)
	if _codex_tab_button != null:
		_codex_tab_button.button_pressed = _active_tab == "codex"
		_codex_tab_button.modulate = Color(1, 1, 1, 1) if _active_tab == "codex" else Color(0.76, 0.79, 0.84, 0.96)


func _reset_selection() -> void:
	_selected_primary_item_id = ""
	_selected_secondary_item_id = ""
	_refresh_slots()
	_refresh_result_text("")


func _refresh_slots() -> void:
	if _primary_slot_button != null:
		_primary_slot_button.text = _slot_button_text(_selected_primary_item_id, "재료 A")
	if _secondary_slot_button != null:
		_secondary_slot_button.text = _slot_button_text(_selected_secondary_item_id, "재료 B")
	if _combine_button != null:
		_combine_button.disabled = _selected_primary_item_id.is_empty() or _selected_secondary_item_id.is_empty()
	_refresh_item_button_states()


func _slot_button_text(item_id: String, empty_label: String) -> String:
	if item_id.is_empty():
		return empty_label

	return _display_name_for_item(item_id)


func _refresh_result_text(text: String) -> void:
	if _result_label != null:
		_result_label.text = text


func _rebuild_inventory_buttons() -> void:
	if _items_container == null:
		return

	_clear_children(_items_container)
	_item_buttons.clear()
	if run_state == null:
		return

	var grouped_items := _group_inventory_items()
	var item_ids: Array[String] = []
	for item_id_variant in grouped_items.keys():
		item_ids.append(String(item_id_variant))
	item_ids.sort_custom(func(a: String, b: String) -> bool: return _display_name_for_item(a) < _display_name_for_item(b))

	for item_id in item_ids:
		var button := Button.new()
		button.name = "ItemButton_%s" % item_id
		button.text = _inventory_button_text(item_id, int(grouped_items.get(item_id, 0)))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(Callable(self, "_on_item_button_pressed").bind(item_id))
		_items_container.add_child(button)
		_item_buttons[item_id] = button

	_refresh_item_button_states()


func _group_inventory_items() -> Dictionary:
	var grouped: Dictionary = {}
	if run_state == null:
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


func _inventory_button_text(item_id: String, item_count: int) -> String:
	return "%s x%d" % [_display_name_for_item(item_id), max(item_count, 1)]


func _display_name_for_item(item_id: String) -> String:
	if run_state != null:
		for item_variant in run_state.inventory.items:
			if typeof(item_variant) != TYPE_DICTIONARY:
				continue

			var inventory_item := item_variant as Dictionary
			if String(inventory_item.get("id", "")) != item_id:
				continue

			var inventory_name := String(inventory_item.get("name", ""))
			if not inventory_name.is_empty():
				return inventory_name

	if ContentLibrary.has_method("get_item"):
		var content_item := ContentLibrary.get_item(item_id)
		if not content_item.is_empty():
			return String(content_item.get("name", item_id))

	return item_id


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


func _on_item_button_pressed(item_id: String) -> void:
	if _selected_primary_item_id.is_empty():
		_selected_primary_item_id = item_id
		_refresh_slots()
		return

	if _selected_secondary_item_id.is_empty():
		if item_id == _selected_primary_item_id and run_state != null and run_state.inventory.count_item_by_id(item_id) < 2:
			_refresh_result_text("같은 재료를 두 번 쓰려면 두 개 이상 필요하다.")
			return

		_selected_secondary_item_id = item_id
		_refresh_slots()
		return

	_selected_primary_item_id = item_id
	_selected_secondary_item_id = ""
	_refresh_slots()


func _on_direct_tab_pressed() -> void:
	_set_active_tab("direct")


func _on_codex_tab_pressed() -> void:
	_set_active_tab("codex")


func _on_primary_slot_pressed() -> void:
	_selected_primary_item_id = ""
	_refresh_slots()


func _on_secondary_slot_pressed() -> void:
	_selected_secondary_item_id = ""
	_refresh_slots()


func _on_close_pressed() -> void:
	close_sheet()


func _on_combine_pressed() -> void:
	if run_state == null:
		_refresh_result_text("런 상태를 찾지 못했다.")
		return

	var outcome: Dictionary = run_state.attempt_craft(_selected_primary_item_id, _selected_secondary_item_id, _context_mode_name)
	_reset_selection()
	_refresh_result_text(_formatted_result_text(outcome))
	_rebuild_inventory_buttons()
	_render_codex()
	craft_applied.emit(outcome)


func _formatted_result_text(outcome: Dictionary) -> String:
	var lines: Array[String] = []
	var result_item_data: Dictionary = outcome.get("result_item_data", {})
	var result_item_name := String(result_item_data.get("name", outcome.get("result_item_id", "")))
	if not result_item_name.is_empty():
		lines.append(result_item_name)
	if not result_item_data.is_empty():
		lines.append(_result_kind_label(result_item_data))
		var item_description := String(result_item_data.get("description", ""))
		if not item_description.is_empty():
			lines.append(item_description)

	var result_text := String(outcome.get("result_text", ""))
	if not result_text.is_empty():
		lines.append(result_text)

	var minutes_elapsed := int(outcome.get("minutes_elapsed", 0))
	if _context_mode_name == "indoor" and minutes_elapsed > 0:
		lines.append("시간 소모: %d분" % minutes_elapsed)

	return "\n".join(lines)


func _result_kind_label(item_data: Dictionary) -> String:
	var deploy_effects_variant: Variant = item_data.get("deploy_effects", {})
	if typeof(deploy_effects_variant) == TYPE_DICTIONARY and not (deploy_effects_variant as Dictionary).is_empty():
		return "실내 설치"

	var equip_effects_variant: Variant = item_data.get("equip_effects", {})
	if (typeof(equip_effects_variant) == TYPE_DICTIONARY and not (equip_effects_variant as Dictionary).is_empty()) \
		or not String(item_data.get("equip_slot", "")).is_empty():
		return "장비"

	var use_effects_variant: Variant = item_data.get("use_effects", {})
	if (typeof(use_effects_variant) == TYPE_DICTIONARY and not (use_effects_variant as Dictionary).is_empty()) \
		or int(item_data.get("hunger_restore", 0)) > 0 \
		or int(item_data.get("health_restore", 0)) > 0 \
		or int(item_data.get("fatigue_restore", 0)) > 0 \
		or int(item_data.get("thirst_restore", 0)) != 0:
		return "즉시 사용"

	return "중간 재료"


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _process(_delta: float) -> void:
	if not visible or _highlighted_item_ids.is_empty():
		return

	var pulse := 1.0 - HINT_PULSE_AMPLITUDE + (sin(float(Time.get_ticks_msec()) * HINT_PULSE_SPEED) + 1.0) * (HINT_PULSE_AMPLITUDE * 0.5)
	for item_id in _highlighted_item_ids:
		var button := _item_buttons.get(item_id) as Button
		if button == null:
			continue
		button.modulate = Color(HINT_PULSE_BASE.r, HINT_PULSE_BASE.g, HINT_PULSE_BASE.b * pulse, 1.0)


func _refresh_item_button_states() -> void:
	for button_variant in _item_buttons.values():
		var button := button_variant as Button
		if button != null:
			button.modulate = DEFAULT_BUTTON_MODULATE

	_highlighted_item_ids.clear()
	if not _should_show_crafting_hints():
		return
	if _selected_primary_item_id.is_empty() or not _selected_secondary_item_id.is_empty():
		return

	_highlighted_item_ids = _compatible_secondary_item_ids(_selected_primary_item_id)
	for item_id in _highlighted_item_ids:
		var button := _item_buttons.get(item_id) as Button
		if button != null:
			button.modulate = HINT_PULSE_BASE


func _should_show_crafting_hints() -> bool:
	if run_state == null:
		return false
	if run_state.has_method("is_easy_mode"):
		return run_state.is_easy_mode()
	return true


func _compatible_secondary_item_ids(primary_item_id: String) -> Array[String]:
	var candidate_ids: Array[String] = []
	if run_state == null or primary_item_id.is_empty():
		return candidate_ids

	var grouped_items := _group_inventory_items()
	for item_id_variant in grouped_items.keys():
		var candidate_item_id := String(item_id_variant)
		if candidate_item_id.is_empty():
			continue
		if candidate_item_id == primary_item_id and int(grouped_items.get(candidate_item_id, 0)) < 2:
			continue

		var outcome: Dictionary = run_state.crafting_resolver.resolve(primary_item_id, candidate_item_id, _context_mode_name, ContentLibrary)
		if String(outcome.get("recipe_id", "")).is_empty():
			continue
		candidate_ids.append(candidate_item_id)

	candidate_ids.sort_custom(func(a: String, b: String) -> bool: return _display_name_for_item(a) < _display_name_for_item(b))
	return candidate_ids
