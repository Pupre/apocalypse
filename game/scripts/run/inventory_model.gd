extends RefCounted
class_name InventoryModel

const MAX_OVERFLOW_BULK := 4

var carry_limit: int = 8
var items: Array[Dictionary] = []


func total_bulk() -> int:
	var total := 0
	for item in items:
		total += int(item.get("bulk", 1))
	return total


func can_add(item: Dictionary) -> bool:
	return total_bulk() + int(item.get("bulk", 1)) <= max_bulk()


func add_item(item: Dictionary) -> bool:
	if not can_add(item):
		return false

	var stored_item := item.duplicate(true)
	var max_charges := int(stored_item.get("max_charges", stored_item.get("charges_max", 0)))
	if max_charges > 0:
		stored_item["max_charges"] = max_charges
		stored_item["charges_max"] = max_charges
		var current_charges := int(stored_item.get("charges", stored_item.get("charges_current", stored_item.get("initial_charges", max_charges))))
		stored_item["charges"] = current_charges
		stored_item["charges_current"] = current_charges

	items.append(stored_item)
	return true


func count_item_by_id(item_id: String) -> int:
	if item_id.is_empty():
		return 0

	var count := 0
	for item in items:
		if String(item.get("id", "")) == item_id:
			count += 1
	return count


func remove_first_item_by_id(item_id: String) -> bool:
	return not take_first_item_by_id(item_id).is_empty()


func take_first_item_by_id(item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}

	for index in range(items.size()):
		var item := items[index]
		if String(item.get("id", "")) != item_id:
			continue

		items.remove_at(index)
		return item

	return {}


func get_first_item_by_id(item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}

	for item_variant in items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue

		var item := item_variant as Dictionary
		if String(item.get("id", "")) == item_id:
			return item

	return {}


func has_items_for_pair(primary_item_id: String, secondary_item_id: String) -> bool:
	if primary_item_id.is_empty() or secondary_item_id.is_empty():
		return false

	if primary_item_id == secondary_item_id:
		return count_item_by_id(primary_item_id) >= 2

	return count_item_by_id(primary_item_id) >= 1 and count_item_by_id(secondary_item_id) >= 1


func take_items_by_ids(primary_item_id: String, secondary_item_id: String) -> Array[Dictionary]:
	var removed_items: Array[Dictionary] = []
	if not has_items_for_pair(primary_item_id, secondary_item_id):
		return removed_items

	var primary_item := take_first_item_by_id(primary_item_id)
	if primary_item.is_empty():
		return removed_items
	removed_items.append(primary_item)

	var secondary_item := take_first_item_by_id(secondary_item_id)
	if secondary_item.is_empty():
		add_item(primary_item)
		removed_items.clear()
		return removed_items
	removed_items.append(secondary_item)
	return removed_items


func remove_items_by_rules(primary_item_id: String, secondary_item_id: String, ingredient_rules: Dictionary) -> Array[Dictionary]:
	var removed_items: Array[Dictionary] = []
	if primary_item_id.is_empty() or secondary_item_id.is_empty():
		return removed_items

	if String(ingredient_rules.get(primary_item_id, "consume")) == "consume":
		var removed_primary := take_first_item_by_id(primary_item_id)
		if removed_primary.is_empty():
			return []
		removed_items.append(removed_primary)

	if String(ingredient_rules.get(secondary_item_id, "consume")) == "consume":
		var removed_secondary := take_first_item_by_id(secondary_item_id)
		if removed_secondary.is_empty():
			restore_items(removed_items)
			return []
		removed_items.append(removed_secondary)

	return removed_items


func restore_items(restored_items: Array[Dictionary]) -> void:
	for item_variant in restored_items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		items.append((item_variant as Dictionary).duplicate(true))


func spend_item_charges(item_id: String, amount: int) -> Dictionary:
	if item_id.is_empty():
		return {"ok": false, "reason": "missing_item"}
	if amount <= 0:
		return {"ok": true, "item": get_first_item_by_id(item_id)}

	for index in range(items.size()):
		var item_variant = items[index]
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue

		var item := item_variant as Dictionary
		if String(item.get("id", "")) != item_id:
			continue

		var available_charges := int(item.get("charges", item.get("charges_current", item.get("initial_charges", item.get("max_charges", item.get("charges_max", 0))))))
		if available_charges < amount:
			return {"ok": false, "reason": "insufficient_charges", "item": item}

		item["charges"] = available_charges - amount
		item["charges_current"] = available_charges - amount
		items[index] = item
		return {"ok": true, "item": item}

	return {"ok": false, "reason": "missing_item"}


func max_bulk() -> int:
	return carry_limit + MAX_OVERFLOW_BULK


func overflow_bulk() -> int:
	return max(0, total_bulk() - carry_limit)
