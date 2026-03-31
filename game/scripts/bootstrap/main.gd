extends Node

func _ready() -> void:
	var app_router := get_node_or_null("/root/AppRouter")
	if app_router == null:
		push_error("AppRouter autoload is missing.")
		return

	app_router.set_host(self)
	app_router.show_title()
