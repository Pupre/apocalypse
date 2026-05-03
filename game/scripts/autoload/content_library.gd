extends Node

var jobs: Dictionary = {}
var traits: Dictionary = {}
var buildings: Dictionary = {}
var outdoor_world_layout: Dictionary = {}
var outdoor_blocks: Dictionary = {}
var items: Dictionary = {}
var crafting_combinations: Dictionary = {}
var loot_profiles: Dictionary = {}

const ITEM_DATA_PATHS := [
	"res://data/items.json",
	"res://data/items_survival_expansion.json",
	"res://data/items_everyday_expansion.json",
]
const CRAFTING_COMBINATION_DATA_PATHS := [
	"res://data/crafting_combinations.json",
	"res://data/crafting_combinations_survival_expansion.json",
	"res://data/crafting_combinations_everyday_expansion.json",
]
const LOOT_PROFILE_DATA_PATHS := [
	"res://data/loot_profiles_survival_expansion.json",
	"res://data/loot_profiles_everyday_expansion.json",
]


func _ready() -> void:
	load_all()


func load_all() -> void:
	jobs = _load_indexed_array("res://data/jobs.json")
	traits = _load_indexed_array("res://data/traits.json")
	outdoor_world_layout = _load_dictionary("res://data/outdoor/world_layout.json")
	outdoor_blocks = _load_outdoor_blocks("res://data/outdoor/blocks")
	buildings = _load_buildings("res://data/buildings.json")
	items = _load_items_from_paths(ITEM_DATA_PATHS)
	crafting_combinations = _load_crafting_combinations_from_paths(CRAFTING_COMBINATION_DATA_PATHS)
	loot_profiles = _load_loot_profiles_from_paths(LOOT_PROFILE_DATA_PATHS)


func get_job(job_id: String) -> Dictionary:
	return jobs.get(job_id, {})


func get_trait(trait_id: String) -> Dictionary:
	return traits.get(trait_id, {})


func get_building(building_id: String) -> Dictionary:
	return buildings.get(building_id, {})


func get_building_rows() -> Array[Dictionary]:
	var building_ids: Array[String] = []
	for building_id_variant in buildings.keys():
		building_ids.append(String(building_id_variant))
	building_ids.sort()

	var rows: Array[Dictionary] = []
	for building_id in building_ids:
		rows.append(buildings.get(building_id, {}))
	return rows


func get_outdoor_world_layout() -> Dictionary:
	return outdoor_world_layout.duplicate(true)


func get_outdoor_block(block_coord: Vector2i) -> Dictionary:
	return (outdoor_blocks.get(_outdoor_block_key(block_coord), {}) as Dictionary).duplicate(true)


func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func get_loot_profile_entries(site_id: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if site_id.is_empty():
		return rows

	_append_loot_profile_rows(rows, loot_profiles.get("global", []))

	var building := get_building(site_id)
	var category := String(building.get("category", ""))
	var category_profiles_variant: Variant = loot_profiles.get("building_categories", {})
	if typeof(category_profiles_variant) == TYPE_DICTIONARY and not category.is_empty():
		_append_loot_profile_rows(rows, (category_profiles_variant as Dictionary).get(category, []))

	var site_tags_variant: Variant = building.get("site_tags", [])
	var site_tag_profiles_variant: Variant = loot_profiles.get("site_tags", {})
	if typeof(site_tags_variant) == TYPE_ARRAY and typeof(site_tag_profiles_variant) == TYPE_DICTIONARY:
		var site_tag_profiles := site_tag_profiles_variant as Dictionary
		for tag_variant in site_tags_variant:
			_append_loot_profile_rows(rows, site_tag_profiles.get(String(tag_variant), []))

	var building_profiles_variant: Variant = loot_profiles.get("building_ids", {})
	if typeof(building_profiles_variant) == TYPE_DICTIONARY:
		_append_loot_profile_rows(rows, (building_profiles_variant as Dictionary).get(site_id, []))

	return _dedup_loot_profile_rows(rows)


func get_crafting_combination(primary_item_id: String, secondary_item_id: String) -> Dictionary:
	return crafting_combinations.get(_crafting_pair_key(primary_item_id, secondary_item_id), {})


func get_crafting_combination_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var recipe_ids: Array[String] = []
	for combination_variant in crafting_combinations.values():
		if typeof(combination_variant) != TYPE_DICTIONARY:
			continue
		var combination := combination_variant as Dictionary
		var recipe_id := String(combination.get("id", ""))
		if recipe_id.is_empty():
			continue
		recipe_ids.append(recipe_id)

	recipe_ids.sort()
	for recipe_id in recipe_ids:
		for combination_variant in crafting_combinations.values():
			if typeof(combination_variant) != TYPE_DICTIONARY:
				continue
			var combination := combination_variant as Dictionary
			if String(combination.get("id", "")) != recipe_id:
				continue
			rows.append(combination.duplicate(true))
			break

	return rows


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


func _load_dictionary(path: String) -> Dictionary:
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
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("%s: expected a top-level object, got %s." % [path, type_string(typeof(parsed))])
		return {}

	return (parsed as Dictionary).duplicate(true)


func _load_items(path: String) -> Dictionary:
	var indexed_rows := _load_indexed_array(path)
	var normalized_rows: Dictionary = {}
	for row_id_variant in indexed_rows.keys():
		var row_id := String(row_id_variant)
		var row_variant: Variant = indexed_rows.get(row_id, {})
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		normalized_rows[row_id] = _normalize_item_row(row_variant as Dictionary)
	return normalized_rows


func _load_items_from_paths(paths: Array) -> Dictionary:
	var merged: Dictionary = {}
	for path_variant in paths:
		var path := String(path_variant)
		if path.is_empty() or not FileAccess.file_exists(path):
			continue
		var rows := _load_items(path)
		for row_id_variant in rows.keys():
			var row_id := String(row_id_variant)
			if merged.has(row_id):
				push_error("%s: duplicate item id '%s' already loaded from an earlier item file." % [path, row_id])
				continue
			merged[row_id] = rows[row_id]
	return merged


func _load_buildings(path: String) -> Dictionary:
	var indexed_rows := _load_indexed_array(path)
	var normalized_rows: Dictionary = {}
	for row_id_variant in indexed_rows.keys():
		var row_id := String(row_id_variant)
		var row_variant: Variant = indexed_rows.get(row_id, {})
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		normalized_rows[row_id] = _normalize_building_row(row_variant as Dictionary)
	return normalized_rows


func _normalize_building_row(source_row: Dictionary) -> Dictionary:
	var row := source_row.duplicate(true)
	var block_coord_variant: Variant = row.get("outdoor_block_coord", {})
	var block_coord := block_coord_variant as Dictionary if typeof(block_coord_variant) == TYPE_DICTIONARY else {}
	var anchor_id := String(row.get("outdoor_anchor_id", ""))
	if not block_coord.is_empty() and not anchor_id.is_empty():
		row["outdoor_position"] = _resolve_building_outdoor_position(block_coord, anchor_id)
	return row


func _resolve_building_outdoor_position(block_coord: Dictionary, anchor_id: String) -> Dictionary:
	var block_key := "%d_%d" % [int(block_coord.get("x", 0)), int(block_coord.get("y", 0))]
	var block_row_variant: Variant = outdoor_blocks.get(block_key, {})
	if typeof(block_row_variant) != TYPE_DICTIONARY:
		return {}
	var block_row := block_row_variant as Dictionary
	var anchors_variant: Variant = block_row.get("building_anchors", {})
	if typeof(anchors_variant) != TYPE_DICTIONARY:
		return {}
	var anchors := anchors_variant as Dictionary
	var local_anchor_variant: Variant = anchors.get(anchor_id, {})
	if typeof(local_anchor_variant) != TYPE_DICTIONARY:
		return {}
	var local_anchor := local_anchor_variant as Dictionary
	var block_size_variant: Variant = outdoor_world_layout.get("block_size", {})
	var block_size := block_size_variant as Dictionary if typeof(block_size_variant) == TYPE_DICTIONARY else {}
	return {
		"x": int(block_coord.get("x", 0)) * int(block_size.get("width", 0)) + int(local_anchor.get("x", 0)),
		"y": int(block_coord.get("y", 0)) * int(block_size.get("height", 0)) + int(local_anchor.get("y", 0)),
	}


func _load_outdoor_blocks(path: String) -> Dictionary:
	var indexed: Dictionary = {}
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("%s: could not open outdoor blocks directory." % path)
		return indexed

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var row := _load_dictionary("%s/%s" % [path, file_name])
			var block_coord_variant: Variant = row.get("block_coord", {})
			if typeof(block_coord_variant) != TYPE_DICTIONARY:
				file_name = dir.get_next()
				continue
			var block_coord := block_coord_variant as Dictionary
			indexed["%d_%d" % [int(block_coord.get("x", 0)), int(block_coord.get("y", 0))]] = row
		file_name = dir.get_next()
	dir.list_dir_end()
	return indexed


func _normalize_item_row(source_row: Dictionary) -> Dictionary:
	var row := source_row.duplicate(true)
	var description := String(row.get("description", ""))
	if description.is_empty():
		description = "%s이다." % String(row.get("name", row.get("id", "아이템")))
		row["description"] = description

	var item_tags_variant: Variant = row.get("item_tags", [])
	var item_tags: Array = []
	if typeof(item_tags_variant) == TYPE_ARRAY:
		item_tags = (item_tags_variant as Array).duplicate(true)
	if item_tags.is_empty():
		item_tags = _default_item_tags(row)
	row["item_tags"] = item_tags

	var usage_hint := String(row.get("usage_hint", ""))
	if usage_hint.is_empty():
		row["usage_hint"] = _default_item_usage_hint(row)

	var cold_hint := String(row.get("cold_hint", ""))
	if cold_hint.is_empty():
		row["cold_hint"] = _default_item_cold_hint(row)

	row["readable"] = bool(row.get("readable", false))
	row["knowledge_title"] = String(row.get("knowledge_title", ""))
	var knowledge_recipe_ids_variant: Variant = row.get("knowledge_recipe_ids", [])
	row["knowledge_recipe_ids"] = (knowledge_recipe_ids_variant as Array).duplicate(true) if typeof(knowledge_recipe_ids_variant) == TYPE_ARRAY else []

	var charges_max := int(row.get("charges_max", row.get("max_charges", 0)))
	row["charges_max"] = charges_max
	row["max_charges"] = charges_max
	var initial_charges := int(row.get("initial_charges", row.get("charges_current", charges_max)))
	row["initial_charges"] = initial_charges
	if charges_max > 0:
		row["charges_current"] = int(row.get("charges_current", initial_charges))
	row["charge_label"] = String(row.get("charge_label", ""))

	return row


func _load_crafting_combinations(path: String) -> Dictionary:
	var indexed_rows := _load_indexed_array(path)
	var indexed_combinations: Dictionary = {}
	for row_variant in indexed_rows.values():
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue

		var row := row_variant as Dictionary
		var ingredients_variant: Variant = row.get("ingredients", [])
		if typeof(ingredients_variant) != TYPE_ARRAY:
			push_error("%s: crafting row '%s' must expose an ingredients array." % [path, String(row.get("id", ""))])
			continue

		var ingredients := ingredients_variant as Array
		if ingredients.size() != 2:
			push_error("%s: crafting row '%s' must list exactly two ingredients." % [path, String(row.get("id", ""))])
			continue

		var contexts_variant: Variant = row.get("contexts", [])
		if typeof(contexts_variant) != TYPE_ARRAY or (contexts_variant as Array).is_empty():
			push_error("%s: crafting row '%s' must expose contexts." % [path, String(row.get("id", ""))])
			continue

		var ingredient_rules_variant: Variant = row.get("ingredient_rules", {})
		if typeof(ingredient_rules_variant) != TYPE_DICTIONARY or (ingredient_rules_variant as Dictionary).is_empty():
			push_error("%s: crafting row '%s' must expose ingredient_rules." % [path, String(row.get("id", ""))])
			continue

		var result_items_variant: Variant = row.get("result_items", [])
		if typeof(result_items_variant) != TYPE_ARRAY or (result_items_variant as Array).is_empty():
			push_error("%s: crafting row '%s' must expose non-empty result_items." % [path, String(row.get("id", ""))])
			continue

		var result_items := result_items_variant as Array
		var first_result_variant: Variant = result_items[0]
		if typeof(first_result_variant) != TYPE_DICTIONARY:
			push_error("%s: crafting row '%s' must expose a dictionary first result payload." % [path, String(row.get("id", ""))])
			continue

		var first_result := first_result_variant as Dictionary
		var first_result_id_variant: Variant = first_result.get("id", "")
		if typeof(first_result_id_variant) != TYPE_STRING or String(first_result_id_variant).is_empty():
			push_error("%s: crafting row '%s' must expose a non-empty string result_items[0].id." % [path, String(row.get("id", ""))])
			continue

		var normalized_row := row.duplicate(true)
		normalized_row["codex_category"] = String(normalized_row.get("codex_category", ""))
		var required_tags_variant: Variant = normalized_row.get("required_tags", [])
		if typeof(required_tags_variant) != TYPE_ARRAY:
			normalized_row["required_tags"] = []
		var required_tool_ids_variant: Variant = normalized_row.get("required_tool_ids", [])
		if typeof(required_tool_ids_variant) != TYPE_ARRAY:
			normalized_row["required_tool_ids"] = []
		var tool_charge_costs_variant: Variant = normalized_row.get("tool_charge_costs", {})
		if typeof(tool_charge_costs_variant) != TYPE_DICTIONARY:
			normalized_row["tool_charge_costs"] = {}
		normalized_row["codex_order"] = int(normalized_row.get("codex_order", 0))

		var minutes := int(normalized_row.get("minutes", normalized_row.get("indoor_minutes", 0)))
		normalized_row["minutes"] = minutes
		normalized_row["indoor_minutes"] = int(normalized_row.get("indoor_minutes", minutes))

		var result_item_id_present: bool = normalized_row.has("result_item_id") and typeof(normalized_row.get("result_item_id")) == TYPE_STRING and not String(normalized_row.get("result_item_id", "")).is_empty()
		var first_result_id := String(first_result_id_variant)
		if result_item_id_present:
			if String(normalized_row.get("result_item_id", "")) != first_result_id:
				push_error("%s: crafting row '%s' has mismatched result_item_id '%s' vs first result '%s'." % [path, String(row.get("id", "")), String(normalized_row.get("result_item_id", "")), first_result_id])
				continue
		else:
			normalized_row["result_item_id"] = first_result_id

		var pair_key := _crafting_pair_key(String(ingredients[0]), String(ingredients[1]))
		if indexed_combinations.has(pair_key):
			push_error("%s: duplicate crafting pair '%s'." % [path, pair_key])
			continue

		indexed_combinations[pair_key] = normalized_row

	return indexed_combinations


func _load_crafting_combinations_from_paths(paths: Array) -> Dictionary:
	var merged: Dictionary = {}
	for path_variant in paths:
		var path := String(path_variant)
		if path.is_empty() or not FileAccess.file_exists(path):
			continue
		var rows := _load_crafting_combinations(path)
		for pair_key_variant in rows.keys():
			var pair_key := String(pair_key_variant)
			if merged.has(pair_key):
				push_error("%s: duplicate crafting pair '%s' already loaded from an earlier crafting file." % [path, pair_key])
				continue
			merged[pair_key] = rows[pair_key]
	return merged


func _load_loot_profiles_from_paths(paths: Array) -> Dictionary:
	var merged := {
		"global": [],
		"building_categories": {},
		"site_tags": {},
		"building_ids": {},
	}
	for path_variant in paths:
		var path := String(path_variant)
		if path.is_empty() or not FileAccess.file_exists(path):
			continue
		var row := _load_dictionary(path)
		_append_loot_profile_rows(merged["global"], row.get("global", []))
		_merge_loot_profile_section(merged["building_categories"], row.get("building_categories", {}))
		_merge_loot_profile_section(merged["site_tags"], row.get("site_tags", {}))
		_merge_loot_profile_section(merged["building_ids"], row.get("building_ids", {}))
	return merged


func _merge_loot_profile_section(target: Dictionary, source_variant: Variant) -> void:
	if typeof(source_variant) != TYPE_DICTIONARY:
		return
	var source := source_variant as Dictionary
	for key_variant in source.keys():
		var key := String(key_variant)
		if key.is_empty():
			continue
		if not target.has(key):
			target[key] = []
		_append_loot_profile_rows(target[key], source.get(key_variant, []))


func _append_loot_profile_rows(target: Array, source_variant: Variant) -> void:
	if typeof(source_variant) != TYPE_ARRAY:
		return
	for entry_variant in source_variant:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry := (entry_variant as Dictionary).duplicate(true)
		var item_id := String(entry.get("id", ""))
		if item_id.is_empty() or get_item(item_id).is_empty():
			continue
		entry["id"] = item_id
		entry["weight"] = maxf(0.0, float(entry.get("weight", 1.0)))
		target.append(entry)


func _dedup_loot_profile_rows(source_rows: Array[Dictionary]) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var seen := {}
	for row in source_rows:
		var item_id := String(row.get("id", ""))
		if item_id.is_empty() or seen.has(item_id):
			continue
		seen[item_id] = true
		rows.append(row.duplicate(true))
	return rows


func _default_item_tags(row: Dictionary) -> Array:
	var tags: Array[String] = []
	var category := String(row.get("category", ""))
	match category:
		"food":
			tags.append("food")
			tags.append("consumable")
		"drink":
			tags.append("drink")
			tags.append("consumable")
		"medical":
			tags.append("medical")
			tags.append("consumable")
		"stimulant":
			tags.append("stimulant")
			tags.append("consumable")
		"equipment":
			tags.append("equipment")
		"key":
			tags.append("key")
		"tool":
			tags.append("tool")
		"container":
			tags.append("container")
		"utility":
			tags.append("utility")
		"crafted":
			tags.append("crafted")
		_:
			tags.append("material")

	if int(row.get("hunger_restore", 0)) > 0 or int(row.get("health_restore", 0)) > 0:
		if not tags.has("consumable"):
			tags.append("consumable")
	if int(row.get("thirst_restore", 0)) != 0:
		if not tags.has("drink"):
			tags.append("drink")
		if not tags.has("consumable"):
			tags.append("consumable")
	if int(row.get("fatigue_restore", 0)) > 0 and not tags.has("consumable"):
		tags.append("consumable")
	if not String(row.get("equip_slot", "")).is_empty() and not tags.has("equipment"):
		tags.append("equipment")
	return tags


func _default_item_usage_hint(row: Dictionary) -> String:
	var category := String(row.get("category", ""))
	match category:
		"food", "drink", "medical", "stimulant":
			return "바로 써서 상태를 회복할 수 있다."
		"equipment":
			return "들고 다니다가 장착하거나 조합 재료로 쓸 수 있다."
		"key":
			return "특정 문이나 잠금 장치를 여는 데 쓴다."
		"container":
			return "다른 재료를 담거나 가공할 때 보조 용기로 쓸 수 있다."
		"tool", "utility":
			return "직접 쓰거나 다른 재료와 함께 응용할 수 있다."
		_:
			return "지금은 재료지만 다른 물건과 엮으면 가치가 커진다."


func _default_item_cold_hint(row: Dictionary) -> String:
	var tags_variant: Variant = row.get("item_tags", [])
	if typeof(tags_variant) == TYPE_ARRAY:
		var tags := tags_variant as Array
		if tags.has("ignition"):
			return "추위 속에서 불씨를 만드는 가장 빠른 수단이다."
		if tags.has("fuel") or tags.has("fuel_component"):
			return "작은 열원을 오래 유지하는 데 쓸 수 있다."
		if tags.has("insulation") or tags.has("wind_block"):
			return "외풍과 열 손실을 줄이는 데 직접 연결된다."
		if tags.has("warmth") or tags.has("carry_warmth"):
			return "실외 노출을 늦추거나 회복 효율을 높이는 쪽에 가깝다."

	var category := String(row.get("category", ""))
	match category:
		"drink":
			return "따뜻하게 바꿀 수 있다면 체감 가치가 크게 올라간다."
		"food":
			return "열량 보충은 추위를 버티는 기본 자원이다."
		"equipment":
			return "강추위에서는 노출 부위를 줄이는 장비가 중요하다."
		_:
			return "강추위 속에서는 다른 재료와 엮였을 때 가치가 더 커진다."


func _crafting_pair_key(primary_item_id: String, secondary_item_id: String) -> String:
	var ids := [primary_item_id, secondary_item_id]
	ids.sort()
	return "%s__%s" % ids


func _outdoor_block_key(block_coord: Vector2i) -> String:
	return "%d_%d" % [block_coord.x, block_coord.y]
