extends RefCounted


func assert_true(value: bool, message: String = "") -> bool:
	if value:
		return true

	push_error(message if message != "" else "Expected condition to be true.")
	return false


func assert_eq(actual, expected, message: String = "") -> bool:
	if actual == expected:
		return true

	var default_message := "Expected %s to equal %s." % [str(actual), str(expected)]
	push_error(message if message != "" else default_message)
	return false


func pass_test(message: String = "") -> bool:
	if message != "":
		print(message)
	return true
