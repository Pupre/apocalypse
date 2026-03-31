extends RefCounted
class_name InventoryModel

var carry_limit: int = 8
var items: Array[Dictionary] = []


func total_bulk() -> int:
	var total := 0
	for item in items:
		total += int(item.get("bulk", 1))
	return total


func can_add(item: Dictionary) -> bool:
	return total_bulk() + int(item.get("bulk", 1)) <= carry_limit


func add_item(item: Dictionary) -> bool:
	if not can_add(item):
		return false

	items.append(item.duplicate(true))
	return true
