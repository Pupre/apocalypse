extends SceneTree

var _failed := false


func _fail(message: String) -> bool:
	if _failed:
		return false

	_failed = true
	push_error(message)
	quit(1)
	return false


func assert_true(value: bool, message: String = "") -> bool:
	if value:
		return true

	return _fail(message if message != "" else "Expected condition to be true.")


func assert_eq(actual, expected, message: String = "") -> bool:
	if actual == expected:
		return true

	var default_message := "Expected %s to equal %s." % [str(actual), str(expected)]
	return _fail(message if message != "" else default_message)


func pass_test(message: String = "") -> bool:
	if _failed:
		return false

	if message != "":
		print(message)
	quit(0)
	return true
