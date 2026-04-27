extends RefCounted
class_name OutdoorThreatDirector

const DEFAULT_SIGHT_DISTANCE := 220.0
const DEFAULT_PROXIMITY_DISTANCE := 72.0
const DEFAULT_CHASE_MEMORY_SECONDS := 3.5
const DEFAULT_MOVE_SPEED := 96.0
const DEFAULT_CONTACT_DISTANCE := 20.0

var _threats: Array[Dictionary] = []


func configure(threat_rows: Array) -> void:
	_threats.clear()
	for row in threat_rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var position_variant: Variant = row.get("position", Vector2.ZERO)
		var forward_variant: Variant = row.get("forward", Vector2.RIGHT)
		var position: Vector2 = position_variant if typeof(position_variant) == TYPE_VECTOR2 else Vector2.ZERO
		var forward: Vector2 = forward_variant if typeof(forward_variant) == TYPE_VECTOR2 else Vector2.RIGHT
		var normalized_forward: Vector2 = forward.normalized()
		if normalized_forward == Vector2.ZERO:
			normalized_forward = Vector2.RIGHT
		_threats.append({
			"id": String(row.get("id", "")),
			"position": position,
			"forward": normalized_forward,
			"state": "idle",
			"memory_seconds": 0.0,
		})


func tick(player_position: Vector2, delta: float) -> Dictionary:
	var any_chasing: bool = false
	var made_contact: bool = false
	for index in range(_threats.size()):
		var threat: Dictionary = _threats[index]
		var threat_position: Vector2 = threat.get("position", Vector2.ZERO)
		var offset: Vector2 = player_position - threat_position
		var distance: float = offset.length()
		var sees_player: bool = _is_in_sight(threat, offset) or distance <= DEFAULT_PROXIMITY_DISTANCE
		if sees_player:
			threat["state"] = "chasing"
			threat["memory_seconds"] = DEFAULT_CHASE_MEMORY_SECONDS
		elif String(threat.get("state", "")) == "chasing":
			var memory_left: float = maxf(0.0, float(threat.get("memory_seconds", 0.0)) - delta)
			threat["memory_seconds"] = memory_left
			if memory_left <= 0.0:
				threat["state"] = "idle"
		if String(threat.get("state", "")) == "chasing":
			any_chasing = true
			if distance <= DEFAULT_CONTACT_DISTANCE:
				made_contact = true
			elif distance > 0.0:
				var next_position: Vector2 = threat_position + offset.normalized() * DEFAULT_MOVE_SPEED * delta
				threat["position"] = next_position
				var new_offset: Vector2 = player_position - next_position
				if new_offset.length() <= DEFAULT_CONTACT_DISTANCE:
					made_contact = true
		_threats[index] = threat
	return {
		"threat_state": "chasing" if any_chasing else "idle",
		"contact": made_contact,
		"threats": _threats.duplicate(true),
	}


func _is_in_sight(threat: Dictionary, offset: Vector2) -> bool:
	var distance: float = offset.length()
	if distance <= 0.0 or distance > DEFAULT_SIGHT_DISTANCE:
		return false
	var forward: Vector2 = threat.get("forward", Vector2.RIGHT)
	var direction: Vector2 = offset.normalized()
	return forward.dot(direction) >= 0.25
