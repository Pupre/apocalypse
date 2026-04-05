extends Node

var jobs: Dictionary = {}
var traits: Dictionary = {}
var buildings: Dictionary = {}
var items: Dictionary = {}
var crafting_combinations: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	jobs = _load_indexed_array("res://data/jobs.json")
	traits = _load_indexed_array("res://data/traits.json")
	buildings = _load_indexed_array("res://data/buildings.json")
	items = _load_items("res://data/items.json")
	crafting_combinations = _load_crafting_combinations("res://data/crafting_combinations.json")


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


func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func get_crafting_combination(primary_item_id: String, secondary_item_id: String) -> Dictionary:
	return crafting_combinations.get(_crafting_pair_key(primary_item_id, secondary_item_id), {})


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
		var required_tags_variant: Variant = normalized_row.get("required_tags", [])
		if typeof(required_tags_variant) != TYPE_ARRAY:
			normalized_row["required_tags"] = []

		var minutes := int(normalized_row.get("minutes", normalized_row.get("indoor_minutes", 0)))
		normalized_row["minutes"] = minutes
		normalized_row["indoor_minutes"] = int(normalized_row.get("indoor_minutes", minutes))

		var result_item_id_present := normalized_row.has("result_item_id") and typeof(normalized_row.get("result_item_id")) == TYPE_STRING and not String(normalized_row.get("result_item_id", "")).is_empty()
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
