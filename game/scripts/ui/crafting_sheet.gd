extends CanvasLayer

signal closed
signal craft_applied(outcome: Dictionary)

var run_state = null
var _context_mode_name := ""
var _selected_primary_item_id := ""
var _selected_secondary_item_id := ""
var _title_label: Label = null
var _close_button: Button = null
var _primary_slot_button: Button = null
var _secondary_slot_button: Button = null
var _combine_button: Button = null
var _result_label: Label = null
var _items_container: VBoxContainer = null


func _ready() -> void:
	_cache_nodes()
	_bind_buttons()
	visible = false
	_refresh_slots()
	_refresh_result_text("")


func bind_run_state(value) -> void:
	run_state = value
	_rebuild_inventory_buttons()


func open_for_mode(mode_name: String) -> void:
	_context_mode_name = mode_name
	_reset_selection()
	visible = true
	_refresh_header()
	_rebuild_inventory_buttons()


func close_sheet() -> void:
	visible = false
	_reset_selection()
	closed.emit()


func get_context_mode_name() -> String:
	return _context_mode_name


func _cache_nodes() -> void:
	_title_label = get_node_or_null("Panel/VBox/Header/TitleLabel") as Label
	_close_button = get_node_or_null("Panel/VBox/Header/CloseButton") as Button
	_primary_slot_button = get_node_or_null("Panel/VBox/SlotsRow/PrimarySlotButton") as Button
	_secondary_slot_button = get_node_or_null("Panel/VBox/SlotsRow/SecondarySlotButton") as Button
	_combine_button = get_node_or_null("Panel/VBox/SlotsRow/CombineButton") as Button
	_result_label = get_node_or_null("Panel/VBox/ResultCard/ResultLabel") as Label
	_items_container = get_node_or_null("Panel/VBox/InventoryScroll/Items") as VBoxContainer


func _bind_buttons() -> void:
	if _close_button != null and not _close_button.pressed.is_connected(Callable(self, "_on_close_pressed")):
		_close_button.pressed.connect(Callable(self, "_on_close_pressed"))
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
