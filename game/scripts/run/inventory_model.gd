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

	items.append(item.duplicate(true))
	return true


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


func max_bulk() -> int:
	return carry_limit + MAX_OVERFLOW_BULK


func overflow_bulk() -> int:
	return max(0, total_bulk() - carry_limit)
