extends RefCounted
class_name CraftingResolver

const INVALID_INDOOR_MINUTES := 5


func resolve(primary_item_id: String, secondary_item_id: String, context: String = "indoor", content_source = null) -> Dictionary:
	if primary_item_id.is_empty() or secondary_item_id.is_empty():
		return _invalid_result("재료 두 개를 모두 골라야 한다.", context)

	var source = ContentLibrary if content_source == null else content_source
	if source == null or not source.has_method("get_crafting_combination"):
		return _invalid_result("조합 데이터를 불러오지 못했다.", context)

	var combination: Dictionary = source.get_crafting_combination(primary_item_id, secondary_item_id)
	if combination.is_empty():
		return _invalid_result("두 재료 사이에 의미 있는 변화는 없었다.", context)

	var contexts_variant: Variant = combination.get("contexts", [])
	var contexts: Array = []
	if typeof(contexts_variant) == TYPE_ARRAY:
		contexts = (contexts_variant as Array).duplicate(true)
	if not contexts.is_empty() and not contexts.has(context):
		return _invalid_result("지금 있는 위치에서는 그 조합을 시도할 수 없다.", context)

	var ingredient_rules_variant: Variant = combination.get("ingredient_rules", {})
	var ingredient_rules: Dictionary = {}
	if typeof(ingredient_rules_variant) == TYPE_DICTIONARY:
		ingredient_rules = (ingredient_rules_variant as Dictionary).duplicate(true)

	var required_tags_variant: Variant = combination.get("required_tags", [])
	var required_tags: Array = []
	if typeof(required_tags_variant) == TYPE_ARRAY:
		required_tags = (required_tags_variant as Array).duplicate(true)

	var result_items_variant: Variant = combination.get("result_items", [])
	var result_items: Array = []
	if typeof(result_items_variant) == TYPE_ARRAY:
		result_items = (result_items_variant as Array).duplicate(true)

	var result_type := String(combination.get("result_type", "invalid"))
	var result_item_id := String(combination.get("result_item_id", ""))
	if result_item_id.is_empty() and not result_items.is_empty() and typeof(result_items[0]) == TYPE_DICTIONARY:
		result_item_id = String((result_items[0] as Dictionary).get("id", ""))
	var result_item_data: Dictionary = {}
	if not result_item_id.is_empty() and source.has_method("get_item"):
		result_item_data = source.get_item(result_item_id)

	return {
		"ok": true,
		"result_type": result_type,
		"result_item_id": result_item_id,
		"result_items": result_items,
		"result_item_data": result_item_data,
		"ingredient_rules": ingredient_rules,
		"required_tags": required_tags,
		"contexts": contexts,
		"result_text": String(combination.get("result_text", _default_result_text(result_type, result_item_data, result_item_id))),
		"minutes_elapsed": _minutes_for_context(int(combination.get("minutes", combination.get("indoor_minutes", INVALID_INDOOR_MINUTES))), context),
		"consumes_ingredients": result_type != "invalid",
		"recipe_id": String(combination.get("id", "")),
	}


func _invalid_result(message: String, context: String) -> Dictionary:
	return {
		"ok": true,
		"result_type": "invalid",
		"result_item_id": "",
		"result_items": [],
		"result_item_data": {},
		"ingredient_rules": {},
		"required_tags": [],
		"contexts": [],
		"result_text": message,
		"minutes_elapsed": _minutes_for_context(INVALID_INDOOR_MINUTES, context),
		"consumes_ingredients": false,
		"recipe_id": "",
	}


func _minutes_for_context(indoor_minutes: int, context: String) -> int:
	if context != "indoor":
		return 0
	return max(0, indoor_minutes)


func _default_result_text(result_type: String, result_item_data: Dictionary, result_item_id: String) -> String:
	var result_name := String(result_item_data.get("name", result_item_id))
	match result_type:
		"success":
			return "%s을(를) 만들었다." % result_name
		"failure":
			return "%s만 남겼다." % result_name
		_:
			return "아무 일도 일어나지 않았다."
