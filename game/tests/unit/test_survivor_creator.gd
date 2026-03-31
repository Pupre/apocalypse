extends "res://tests/support/test_case.gd"

const BOOTSTRAP_SCENE_PATH := "res://scenes/bootstrap/main.tscn"

var _confirmed := false
var _confirmed_job_id := ""
var _confirmed_trait_ids: Array[String] = []


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var bootstrap_scene := load(BOOTSTRAP_SCENE_PATH) as PackedScene
	if not assert_true(bootstrap_scene != null, "Missing bootstrap scene: %s" % BOOTSTRAP_SCENE_PATH):
		return

	var bootstrap = bootstrap_scene.instantiate()
	if not assert_true(bootstrap != null, "Failed to instantiate bootstrap scene."):
		return

	root.add_child(bootstrap)

	var title_menu = bootstrap.get_node_or_null("TitleMenu")
	if not assert_true(title_menu != null, "Bootstrap should show the title menu first."):
		bootstrap.free()
		return

	var start_button := title_menu.get_node_or_null("Center/Panel/VBox/StartButton") as Button
	if not assert_true(start_button != null, "Title menu start button is missing."):
		bootstrap.free()
		return

	start_button.emit_signal("pressed")

	var survivor_creator = bootstrap.get_node_or_null("SurvivorCreator")
	if not assert_true(survivor_creator != null, "Bootstrap should swap to the survivor creator after start."):
		bootstrap.free()
		return

	if not assert_true(bootstrap.get_node_or_null("TitleMenu") == null, "Title menu should be replaced after start."):
		bootstrap.free()
		return

	if not assert_true(survivor_creator.has_signal("survivor_confirmed"), "Survivor creator should expose survivor_confirmed."):
		bootstrap.free()
		return

	survivor_creator.survivor_confirmed.connect(Callable(self, "_on_survivor_confirmed"))

	var courier_button := survivor_creator.get_node_or_null("Center/Panel/VBox/JobButtons/CourierButton") as Button
	var athlete_button := survivor_creator.get_node_or_null("Center/Panel/VBox/TraitButtons/AthleteButton") as CheckButton
	var unlucky_button := survivor_creator.get_node_or_null("Center/Panel/VBox/TraitButtons/UnluckyButton") as CheckButton
	var confirm_button := survivor_creator.get_node_or_null("Center/Panel/VBox/ConfirmButton") as Button

	if not assert_true(courier_button != null, "Courier button is missing."):
		bootstrap.free()
		return
	if not assert_true(athlete_button != null, "Athlete trait button is missing."):
		bootstrap.free()
		return
	if not assert_true(unlucky_button != null, "Unlucky trait button is missing."):
		bootstrap.free()
		return
	if not assert_true(confirm_button != null, "Confirm button is missing."):
		bootstrap.free()
		return

	assert_true(confirm_button.disabled, "Confirm should be gated until the selection is valid.")

	courier_button.emit_signal("pressed")
	athlete_button.button_pressed = true
	unlucky_button.button_pressed = true

	assert_eq(survivor_creator.job_id, "courier", "Expected courier to be the selected job.")
	assert_eq(survivor_creator.trait_ids, ["athlete", "unlucky"], "Traits should preserve selection order.")
	assert_eq(survivor_creator.remaining_points, 0, "Expected selected traits to spend all points.")
	assert_true(not confirm_button.disabled, "Confirm should enable once the selection is valid.")

	confirm_button.emit_signal("pressed")

	assert_true(_confirmed, "Confirm should emit survivor_confirmed.")
	assert_eq(_confirmed_job_id, "courier", "Confirmed job should match the selected job.")
	assert_eq(_confirmed_trait_ids, ["athlete", "unlucky"], "Confirmed trait order should match the selection order.")

	bootstrap.free()
	bootstrap = null
	bootstrap_scene = null

	pass_test("SURVIVOR_CREATOR_OK")


func _on_survivor_confirmed(job_id: String, trait_ids: Array[String]) -> void:
	_confirmed = true
	_confirmed_job_id = job_id
	_confirmed_trait_ids = trait_ids.duplicate()
