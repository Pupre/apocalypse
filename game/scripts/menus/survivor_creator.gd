extends Control

signal survivor_confirmed(job_id: String, trait_ids: Array[String])

const UiKitResolver = preload("res://scripts/ui/ui_kit_resolver.gd")

const TEXT_PRIMARY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const TEXT_SECONDARY_COLOR := Color(0.92, 0.96, 1.0, 0.98)
const TEXT_MUTED_COLOR := Color(0.76, 0.84, 0.90, 0.96)
const TEXT_WARNING_COLOR := Color(1.0, 0.88, 0.66, 1.0)
const TEXT_GOOD_COLOR := Color(0.76, 1.0, 0.86, 1.0)
const TEXT_OUTLINE_COLOR := Color(0.0, 0.02, 0.04, 1.0)
const BASE_POINTS := 0
const DEFAULT_DIFFICULTY := "easy"
const JOB_BUTTON_PATHS := {
	"clerk": "Center/Panel/VBox/JobButtons/ClerkButton",
	"courier": "Center/Panel/VBox/JobButtons/CourierButton",
}
const DIFFICULTY_BUTTON_PATHS := {
	"easy": "Center/Panel/VBox/DifficultyButtons/EasyButton",
	"hard": "Center/Panel/VBox/DifficultyButtons/HardButton",
}
const TRAIT_BUTTON_PATHS := {
	"athlete": "Center/Panel/VBox/TraitButtons/AthleteButton",
	"light_sleeper": "Center/Panel/VBox/TraitButtons/LightSleeperButton",
	"unlucky": "Center/Panel/VBox/TraitButtons/UnluckyButton",
	"heavy_sleeper": "Center/Panel/VBox/TraitButtons/HeavySleeperButton",
}
const JOB_STATUS_LABEL_PATH := "Center/Panel/VBox/JobStatusLabel"
const DIFFICULTY_STATUS_LABEL_PATH := "Center/Panel/VBox/DifficultyStatusLabel"
const TRAIT_STATUS_LABEL_PATH := "Center/Panel/VBox/TraitStatusLabel"
const POINTS_LABEL_PATH := "Center/Panel/VBox/PointsLabel"
const CONFIRM_BUTTON_PATH := "Center/Panel/VBox/ConfirmButton"
const SUMMARY_LABEL_PATH := "Center/Panel/VBox/SummaryLabel"

var job_id: String = ""
var trait_ids: Array[String] = []
var difficulty_id: String = DEFAULT_DIFFICULTY
var remaining_points: int = BASE_POINTS

var _content_library
var _jobs: Dictionary = {}
var _traits: Dictionary = {}
var _job_buttons: Dictionary = {}
var _difficulty_buttons: Dictionary = {}
var _trait_buttons: Dictionary = {}
var _job_status_label: Label
var _difficulty_status_label: Label
var _trait_status_label: Label
var _points_label: Label
var _summary_label: Label
var _confirm_button: Button
var _ui_bound := false
var _content_loaded := false
var _skin_applied := false
var _ui_kit_resolver := UiKitResolver.new()


func _ready() -> void:
	load_content()


func load_content() -> void:
	_cache_ui()
	_content_library = _get_content_library()
	if _content_library == null:
		push_error("ContentLibrary autoload is missing.")
		return

	_jobs = _content_library.jobs
	_traits = _content_library.traits
	if _jobs.is_empty() or _traits.is_empty():
		push_error("ContentLibrary has not loaded its content.")
		return

	if not _ui_bound:
		_bind_ui()
		_ui_bound = true

	_apply_ui_skin()
	_refresh_view()
	_content_loaded = true


func select_job(selected_job_id: String) -> void:
	if not _content_loaded or not _jobs.has(selected_job_id):
		return

	job_id = selected_job_id
	_refresh_view()


func select_difficulty(selected_difficulty_id: String) -> void:
	if not DIFFICULTY_BUTTON_PATHS.has(selected_difficulty_id):
		return

	difficulty_id = selected_difficulty_id
	_refresh_view()


func toggle_trait(trait_id: String) -> void:
	set_trait_selected(trait_id, not trait_ids.has(trait_id))


func set_trait_selected(trait_id: String, selected: bool) -> void:
	if not _content_loaded or not _traits.has(trait_id):
		return

	var selected_index := trait_ids.find(trait_id)
	if selected:
		if selected_index == -1:
			trait_ids.append(trait_id)
	else:
		if selected_index != -1:
			trait_ids.remove_at(selected_index)

	_refresh_view()


func confirm_selection() -> void:
	if not is_valid_selection():
		return

	survivor_confirmed.emit(job_id, trait_ids.duplicate())


func get_survivor_config() -> Dictionary:
	return {
		"job_id": job_id,
		"trait_ids": trait_ids.duplicate(),
		"difficulty": difficulty_id,
		"remaining_points": remaining_points,
	}


func is_valid_selection() -> bool:
	return job_id != "" and remaining_points == 0


func _cache_ui() -> void:
	_job_buttons = {
		"clerk": get_node_or_null(JOB_BUTTON_PATHS["clerk"]) as Button,
		"courier": get_node_or_null(JOB_BUTTON_PATHS["courier"]) as Button,
	}
	_difficulty_buttons = {
		"easy": get_node_or_null(DIFFICULTY_BUTTON_PATHS["easy"]) as Button,
		"hard": get_node_or_null(DIFFICULTY_BUTTON_PATHS["hard"]) as Button,
	}
	_trait_buttons = {
		"athlete": get_node_or_null(TRAIT_BUTTON_PATHS["athlete"]) as CheckButton,
		"light_sleeper": get_node_or_null(TRAIT_BUTTON_PATHS["light_sleeper"]) as CheckButton,
		"unlucky": get_node_or_null(TRAIT_BUTTON_PATHS["unlucky"]) as CheckButton,
		"heavy_sleeper": get_node_or_null(TRAIT_BUTTON_PATHS["heavy_sleeper"]) as CheckButton,
	}
	_job_status_label = get_node_or_null(JOB_STATUS_LABEL_PATH) as Label
	_difficulty_status_label = get_node_or_null(DIFFICULTY_STATUS_LABEL_PATH) as Label
	_trait_status_label = get_node_or_null(TRAIT_STATUS_LABEL_PATH) as Label
	_points_label = get_node_or_null(POINTS_LABEL_PATH) as Label
	_summary_label = get_node_or_null(SUMMARY_LABEL_PATH) as Label
	_confirm_button = get_node_or_null(CONFIRM_BUTTON_PATH) as Button


func _bind_ui() -> void:
	_bind_job_button("clerk")
	_bind_job_button("courier")
	_bind_difficulty_button("easy")
	_bind_difficulty_button("hard")
	_bind_trait_button("athlete")
	_bind_trait_button("light_sleeper")
	_bind_trait_button("unlucky")
	_bind_trait_button("heavy_sleeper")

	if _confirm_button != null:
		_confirm_button.pressed.connect(Callable(self, "confirm_selection"))


func _bind_job_button(job_key: String) -> void:
	var button := _job_buttons.get(job_key) as Button
	if button == null:
		push_error("Missing job button for %s." % job_key)
		return

	var job_data: Dictionary = _jobs.get(job_key, {})
	if not job_data.is_empty():
		button.text = String(job_data.get("name", button.text))

	var selected_job_key := job_key
	button.pressed.connect(Callable(self, "_on_job_button_pressed").bind(selected_job_key))


func _bind_trait_button(trait_key: String) -> void:
	var button := _trait_buttons.get(trait_key) as CheckButton
	if button == null:
		push_error("Missing trait button for %s." % trait_key)
		return

	var trait_data: Dictionary = _traits.get(trait_key, {})
	if not trait_data.is_empty():
		button.text = "%s (%+d)" % [String(trait_data.get("name", button.text)), int(trait_data.get("cost", 0))]

	var selected_trait_key := trait_key
	button.toggled.connect(Callable(self, "_on_trait_button_toggled").bind(selected_trait_key))


func _bind_difficulty_button(difficulty_key: String) -> void:
	var button := _difficulty_buttons.get(difficulty_key) as Button
	if button == null:
		push_error("Missing difficulty button for %s." % difficulty_key)
		return

	var button_text := "이지" if difficulty_key == "easy" else "하드"
	button.text = button_text
	var selected_difficulty_key := difficulty_key
	button.pressed.connect(Callable(self, "_on_difficulty_button_pressed").bind(selected_difficulty_key))


func _refresh_view() -> void:
	remaining_points = BASE_POINTS - _selected_trait_cost_total()

	for job_key in _job_buttons.keys():
		var job_button := _job_buttons.get(job_key) as Button
		if job_button != null:
			job_button.disabled = job_key == job_id

	for difficulty_key in _difficulty_buttons.keys():
		var difficulty_button := _difficulty_buttons.get(difficulty_key) as Button
		if difficulty_button != null:
			difficulty_button.disabled = difficulty_key == difficulty_id

	for trait_key in _trait_buttons.keys():
		var trait_button := _trait_buttons.get(trait_key) as CheckButton
		if trait_button != null:
			var selected := trait_ids.has(trait_key)
			if trait_button.button_pressed != selected:
				trait_button.set_pressed_no_signal(selected)

	if _job_status_label != null:
		_job_status_label.text = _job_status_text()

	if _difficulty_status_label != null:
		_difficulty_status_label.text = _difficulty_status_text()

	if _trait_status_label != null:
		_trait_status_label.text = _trait_status_text()

	if _points_label != null:
		_points_label.text = _points_status_text()
		_apply_label_style(
			_points_label,
			15,
			TEXT_GOOD_COLOR if remaining_points == 0 else TEXT_WARNING_COLOR,
			2
		)

	if _summary_label != null:
		_summary_label.text = _summary_text()

	if _confirm_button != null:
		_confirm_button.disabled = not is_valid_selection()
		_confirm_button.text = "이 생존자로 시작" if is_valid_selection() else "직업과 균형을 맞춰야 한다"


func _on_job_button_pressed(job_key: String) -> void:
	select_job(job_key)


func _on_difficulty_button_pressed(selected_difficulty_id: String) -> void:
	select_difficulty(selected_difficulty_id)


func _on_trait_button_toggled(pressed: bool, trait_key: String) -> void:
	set_trait_selected(trait_key, pressed)


func _selected_trait_cost_total() -> int:
	var total := 0
	for trait_key in trait_ids:
		var trait_data: Dictionary = _traits.get(trait_key, {})
		total += int(trait_data.get("cost", 0))

	return total


func _job_status_text() -> String:
	if job_id == "":
		return "아직 정하지 않았다. 첫 동선과 가방 여유를 바꿀 선택이다."

	var job_data: Dictionary = _jobs.get(job_id, {})
	var job_name := String(job_data.get("name", job_id))
	if job_id == "clerk":
		return "%s · 매장과 창고 수색에 익숙하고 가방 여유가 조금 늘어난다." % job_name
	if job_id == "courier":
		return "%s · 바깥길을 빠르게 읽고 오래 걸어도 피로가 덜 쌓인다." % job_name
	return "%s · %s" % [job_name, String(job_data.get("description", ""))]


func _trait_status_text() -> String:
	if trait_ids.is_empty():
		return "특성 없음 · 안정적이지만 강점도 약점도 흐릿하다."

	var selected_traits: Array[String] = []
	for trait_key in trait_ids:
		var trait_data: Dictionary = _traits.get(trait_key, {})
		selected_traits.append(_trait_summary(trait_key, trait_data))

	return " / ".join(selected_traits)


func _difficulty_status_text() -> String:
	var difficulty_name := "이지" if difficulty_id == "easy" else "하드"
	if difficulty_id == "easy":
		return "%s · 조합 실험과 초반 판단을 더 너그럽게 받아준다." % difficulty_name
	return "%s · 조합 힌트가 줄어들어 알고 있는 선택의 무게가 커진다." % difficulty_name


func _points_status_text() -> String:
	if remaining_points == 0:
		return "균형: 맞음"
	if remaining_points > 0:
		return "균형: 약점 보상이 %d 남음" % remaining_points
	return "균형: 강점 대가가 %d 부족함" % abs(remaining_points)


func _summary_text() -> String:
	var parts: Array[String] = []
	if job_id.is_empty():
		parts.append("직업 미정")
	else:
		parts.append(String((_jobs.get(job_id, {}) as Dictionary).get("name", job_id)))
	parts.append("이지" if difficulty_id == "easy" else "하드")
	if trait_ids.is_empty():
		parts.append("특성 없음")
	else:
		var names: Array[String] = []
		for trait_key in trait_ids:
			names.append(String((_traits.get(trait_key, {}) as Dictionary).get("name", trait_key)))
		parts.append(", ".join(names))
	var verdict := "출발 가능" if is_valid_selection() else "출발 준비 중"
	return "%s · %s" % [" / ".join(parts), verdict]


func _trait_summary(trait_key: String, trait_data: Dictionary) -> String:
	var trait_name := String(trait_data.get("name", trait_key))
	match trait_key:
		"athlete":
			return "%s: 이동과 피로에 강하지만 대가가 크다." % trait_name
		"light_sleeper":
			return "%s: 잠을 덜 자도 반응이 빠르다." % trait_name
		"unlucky":
			return "%s: 수색 운이 나쁘지만 강점 비용을 메워준다." % trait_name
		"heavy_sleeper":
			return "%s: 회복은 길어지지만 아침 대응이 늦다." % trait_name
	return "%s (%+d)" % [trait_name, int(trait_data.get("cost", 0))]


func _apply_ui_skin() -> void:
	if _skin_applied:
		return
	_skin_applied = true

	var panel := get_node_or_null("Center/Panel") as PanelContainer
	_ui_kit_resolver.apply_panel(panel, "sheet/sheet_bg_compact.png")

	var labels := [
		get_node_or_null("Center/Panel/VBox/TitleLabel") as Label,
		get_node_or_null("Center/Panel/VBox/SubtitleLabel") as Label,
		get_node_or_null("Center/Panel/VBox/JobHeadingLabel") as Label,
		get_node_or_null("Center/Panel/VBox/DifficultyHeadingLabel") as Label,
		get_node_or_null("Center/Panel/VBox/TraitHeadingLabel") as Label,
	]
	_apply_label_style(labels[0], 24, TEXT_PRIMARY_COLOR, 4)
	_apply_label_style(labels[1], 15, TEXT_SECONDARY_COLOR, 2)
	_apply_label_style(labels[2], 16, TEXT_PRIMARY_COLOR, 3)
	_apply_label_style(labels[3], 16, TEXT_PRIMARY_COLOR, 3)
	_apply_label_style(labels[4], 16, TEXT_PRIMARY_COLOR, 3)
	_apply_label_style(_job_status_label, 15, TEXT_SECONDARY_COLOR, 2)
	_apply_label_style(_difficulty_status_label, 15, TEXT_SECONDARY_COLOR, 2)
	_apply_label_style(_trait_status_label, 15, TEXT_SECONDARY_COLOR, 2)
	_apply_label_style(_summary_label, 16, TEXT_PRIMARY_COLOR, 3)
	_apply_label_style(_points_label, 15, TEXT_GOOD_COLOR, 2)

	for button_variant in _job_buttons.values():
		_apply_choice_button(button_variant as Button)
	for button_variant in _difficulty_buttons.values():
		_apply_choice_button(button_variant as Button)
	for button_variant in _trait_buttons.values():
		_apply_choice_button(button_variant as Button)
	_apply_primary_button(_confirm_button)


func _apply_choice_button(button: Button) -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(0, 48)
	button.focus_mode = Control.FOCUS_NONE
	_ui_kit_resolver.apply_button(
		button,
		"sheet/sheet_button_secondary_normal.png",
		"sheet/sheet_button_secondary_pressed.png",
		"sheet/sheet_button_secondary_pressed.png",
		"sheet/sheet_button_primary_pressed.png"
	)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", TEXT_PRIMARY_COLOR)
	button.add_theme_color_override("font_outline_color", TEXT_OUTLINE_COLOR)
	button.add_theme_constant_override("outline_size", 2)


func _apply_primary_button(button: Button) -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(0, 56)
	button.focus_mode = Control.FOCUS_NONE
	_ui_kit_resolver.apply_button(
		button,
		"sheet/sheet_button_primary_normal.png",
		"sheet/sheet_button_primary_pressed.png",
		"sheet/sheet_button_primary_pressed.png",
		"sheet/sheet_button_secondary_normal.png"
	)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", TEXT_PRIMARY_COLOR)
	button.add_theme_color_override("font_outline_color", TEXT_OUTLINE_COLOR)
	button.add_theme_constant_override("outline_size", 3)


func _apply_label_style(label: Label, font_size: int, font_color: Color, outline_size: int) -> void:
	if label == null:
		return
	label.modulate = font_color
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", TEXT_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", outline_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _get_content_library() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null

	return tree.root.get_node_or_null("ContentLibrary")
