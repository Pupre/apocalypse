extends Control

signal survivor_confirmed(job_id: String, trait_ids: Array[String])

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
var _confirm_button: Button
var _ui_bound := false
var _content_loaded := false


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
		_points_label.text = "남은 포인트: %d" % remaining_points

	if _confirm_button != null:
		_confirm_button.disabled = not is_valid_selection()


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
		return "직업: 선택 안 함"

	var job_data: Dictionary = _jobs.get(job_id, {})
	return "직업: %s" % String(job_data.get("name", job_id))


func _trait_status_text() -> String:
	if trait_ids.is_empty():
		return "특성: 선택 안 함"

	var selected_traits: Array[String] = []
	for trait_key in trait_ids:
		var trait_data: Dictionary = _traits.get(trait_key, {})
		selected_traits.append(String(trait_data.get("name", trait_key)))

	return "특성: %s" % ", ".join(selected_traits)


func _difficulty_status_text() -> String:
	var difficulty_name := "이지" if difficulty_id == "easy" else "하드"
	return "난이도: %s" % difficulty_name


func _get_content_library() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null

	return tree.root.get_node_or_null("ContentLibrary")
