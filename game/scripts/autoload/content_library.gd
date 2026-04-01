extends Node

var jobs: Dictionary = {}
var traits: Dictionary = {}
var buildings: Dictionary = {}
var items: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	jobs = _load_indexed_array("res://data/jobs.json")
	traits = _load_indexed_array("res://data/traits.json")
	buildings = _load_indexed_array("res://data/buildings.json")
	items = _load_indexed_array("res://data/items.json")


func get_job(job_id: String) -> Dictionary:
	return jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return traits.get(trait_id, {})


func get_building(building_id: String) -> Dictionary:
	return buildings.get(building_id, {})


func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func _load_indexed_array(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("%s: could not open content file." % path)
		return {}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		push_error("%s: invalid JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}

	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_ARRAY:
		push_error("%s: expected a top-level array, got %s." % [path, type_string(typeof(parsed))])
		return {}

	var indexed: Dictionary = {}
	var row_number := 0
	for entry in parsed:
		row_number += 1
		if typeof(entry) != TYPE_DICTIONARY:
			push_error("%s: row %d must be an object." % [path, row_number])
			continue

		var row := entry as Dictionary
		if not row.has("id") or String(row["id"]).is_empty():
			push_error("%s: row %d is missing a non-empty 'id' field." % [path, row_number])
			continue

		var row_id := String(row["id"])
		if indexed.has(row_id):
			push_error("%s: duplicate id '%s' at row %d." % [path, row_id, row_number])
			continue

		indexed[row_id] = row
	return indexed
