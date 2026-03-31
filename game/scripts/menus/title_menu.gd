extends Control

signal start_requested


@onready var _start_button: Button = get_node_or_null("Center/Panel/VBox/StartButton") as Button


func _ready() -> void:
	_bind_events()


func _bind_events() -> void:
	if _start_button == null:
		push_error("Title menu start button is missing.")
		return

	_start_button.pressed.connect(Callable(self, "_on_start_pressed"))


func _on_start_pressed() -> void:
	start_requested.emit()
