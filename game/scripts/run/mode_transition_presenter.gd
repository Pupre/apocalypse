extends CanvasLayer

@export var fade_duration: float = 0.25

var _fade_rect: ColorRect


func _ready() -> void:
	_cache_fade_rect()
	_set_input_blocking(false)
	_set_fade_alpha(0.0)


func set_duration_for_tests(seconds: float) -> void:
	fade_duration = maxf(0.0, seconds)


func fade_out() -> void:
	await _fade_to(1.0)


func fade_in() -> void:
	await _fade_to(0.0)


func _fade_to(target_alpha: float) -> void:
	_cache_fade_rect()
	if _fade_rect == null:
		return

	if target_alpha > 0.0:
		_set_input_blocking(true)

	if fade_duration <= 0.0:
		_set_fade_alpha(target_alpha)
		if is_equal_approx(target_alpha, 0.0):
			_set_input_blocking(false)
		await get_tree().process_frame
		return

	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", target_alpha, fade_duration)
	await tween.finished
	if is_equal_approx(target_alpha, 0.0):
		_set_input_blocking(false)


func _cache_fade_rect() -> void:
	if _fade_rect == null:
		_fade_rect = get_node_or_null("FadeRect") as ColorRect


func _set_fade_alpha(alpha: float) -> void:
	if _fade_rect == null:
		return

	var color := _fade_rect.color
	color.a = alpha
	_fade_rect.color = color


func _set_input_blocking(enabled: bool) -> void:
	if _fade_rect == null:
		return

	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
