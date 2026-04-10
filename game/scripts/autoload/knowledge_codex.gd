extends Node

const DEFAULT_STORAGE_PATH := "user://knowledge_codex.json"

var storage_path: String = DEFAULT_STORAGE_PATH
var discovered_items: Dictionary = {}


func _ready() -> void:
	load_from_disk()


func set_storage_path(path: String) -> void:
	if path.is_empty():
		return

	storage_path = path


func clear_all() -> void:
	discovered_items = {}
	save()


func register_item(item_id: String) -> void:
	if item_id.is_empty() or discovered_items.has(item_id):
		return

	discovered_items[item_id] = {
		"item_id": item_id,
		"item_name": _item_name(item_id),
		"attempts": [],
	}


func record_attempt(primary_item_id: String, secondary_item_id: String, payload: Dictionary) -> void:
	if primary_item_id.is_empty() or secondary_item_id.is_empty():
		return

	register_item(primary_item_id)
	register_item(secondary_item_id)
	_upsert_attempt(primary_item_id, secondary_item_id, payload)
	_upsert_attempt(secondary_item_id, primary_item_id, payload)
	save()


func save() -> void:
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		push_error("KnowledgeCodex could not open %s for writing." % storage_path)
		return

	file.store_string(JSON.stringify({
		"discovered_items": discovered_items,
	}, "\t"))


func load_from_disk() -> void:
	discovered_items = {}
	if not FileAccess.file_exists(storage_path):
		return

	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		push_error("KnowledgeCodex could not open %s for reading." % storage_path)
		return

	var json := JSON.new()
	var parse_error: int = json.parse(file.get_as_text())
	if parse_error != OK:
		push_error("%s: invalid JSON at line %d: %s" % [storage_path, json.get_error_line(), json.get_error_message()])
		return

	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("%s: expected a top-level object." % storage_path)
		return

	var payload := parsed as Dictionary
	discovered_items = _normalize_discovered_items(payload.get("discovered_items", {}))


func get_item_rows() -> Array[Dictionary]:
	var item_ids: Array[String] = []
	for item_id_variant in discovered_items.keys():
		item_ids.append(String(item_id_variant))
	item_ids.sort()

	var rows: Array[Dictionary] = []
	for item_id in item_ids:
		var entry: Dictionary = discovered_items.get(item_id, {})
		var attempts := _dictionary_array(entry.get("attempts", []))
		rows.append({
			"item_id": item_id,
			"label": String(entry.get("item_name", _item_name(item_id))),
			"attempt_count": attempts.size(),
		})

	return rows


func get_item_entry(item_id: String) -> Dictionary:
	if item_id.is_empty() or not discovered_items.has(item_id):
		return {}

	return (discovered_items.get(item_id, {}) as Dictionary).duplicate(true)


func _upsert_attempt(primary_item_id: String, secondary_item_id: String, payload: Dictionary) -> void:
	var entry: Dictionary = discovered_items.get(primary_item_id, {})
	var attempts := _dictionary_array(entry.get("attempts", []))
	var attempt_row := payload.duplicate(true)
	attempt_row["other_item_id"] = secondary_item_id
	attempt_row["other_item_name"] = _item_name(secondary_item_id)

	var result_item_id := String(attempt_row.get("result_item_id", ""))
	if not result_item_id.is_empty() and not attempt_row.has("result_item_name"):
		attempt_row["result_item_name"] = _item_name(result_item_id)
	if not attempt_row.has("result_label") and not result_item_id.is_empty():
		attempt_row["result_label"] = _item_name(result_item_id)

	var replaced := false
	for index in range(attempts.size()):
		var existing := attempts[index]
		if String(existing.get("other_item_id", "")) != secondary_item_id:
			continue
		attempts[index] = attempt_row
		replaced = true
		break

	if not replaced:
		attempts.append(attempt_row)

	entry["item_id"] = primary_item_id
	entry["item_name"] = _item_name(primary_item_id)
	entry["attempts"] = attempts
	discovered_items[primary_item_id] = entry


func _normalize_discovered_items(raw_value: Variant) -> Dictionary:
	if typeof(raw_value) != TYPE_DICTIONARY:
		return {}

	var source := raw_value as Dictionary
	var normalized: Dictionary = {}
	for item_id_variant in source.keys():
		var item_id := String(item_id_variant)
		var entry_variant: Variant = source.get(item_id_variant, {})
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry := entry_variant as Dictionary
		normalized[item_id] = {
			"item_id": item_id,
			"item_name": String(entry.get("item_name", _item_name(item_id))),
			"attempts": _dictionary_array(entry.get("attempts", [])),
		}

	return normalized


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return rows

	for row_variant in value:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		rows.append((row_variant as Dictionary).duplicate(true))

	return rows


func _item_name(item_id: String) -> String:
	if item_id.is_empty():
		return ""

	if not is_inside_tree():
		return item_id

	var tree := get_tree()
	if tree != null and tree.root != null:
		var content_library := tree.root.get_node_or_null("ContentLibrary")
		if content_library != null and content_library.has_method("get_item"):
			var item_definition: Dictionary = content_library.get_item(item_id)
			if not item_definition.is_empty():
				return String(item_definition.get("name", item_id))

	return item_id
