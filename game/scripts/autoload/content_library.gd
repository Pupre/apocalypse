extends Node

var jobs: Dictionary = {}
var traits: Dictionary = {}
var buildings: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	jobs = _load_indexed_array("res://data/jobs.json")
	traits = _load_indexed_array("res://data/traits.json")
	buildings = _load_indexed_array("res://data/buildings.json")


func get_job(job_id: String) -> Dictionary:
	return jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return traits.get(trait_id, {})


func get_building(building_id: String) -> Dictionary:
	return buildings.get(building_id, {})


func _load_indexed_array(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Expected array in %s" % path)
		return {}

	var indexed: Dictionary = {}
	for entry in parsed:
		if entry is Dictionary and entry.has("id"):
			indexed[entry["id"]] = entry
	return indexed
