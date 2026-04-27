extends "res://tests/support/test_case.gd"

const THREAT_DIRECTOR_SCRIPT := "res://scripts/outdoor/outdoor_threat_director.gd"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var threat_director_script := load(THREAT_DIRECTOR_SCRIPT) as Script
	if not assert_true(threat_director_script != null, "Missing outdoor threat director script: %s" % THREAT_DIRECTOR_SCRIPT):
		return

	var threat_director = threat_director_script.new()
	if not assert_true(threat_director != null, "Threat director should instantiate."):
		return

	threat_director.configure([
		{
			"id": "pack_01",
			"position": Vector2(320, 340),
			"forward": Vector2.RIGHT,
		},
	])

	var calm: Dictionary = threat_director.tick(Vector2(80, 340), 0.5)
	assert_eq(String(calm.get("threat_state", "")), "idle", "A threat should stay idle when the player is outside sight and proximity.")

	var spotted: Dictionary = threat_director.tick(Vector2(380, 340), 0.5)
	assert_eq(String(spotted.get("threat_state", "")), "chasing", "A threat should switch to chasing when the player enters sight.")

	var lingering: Dictionary = threat_director.tick(Vector2(260, 340), 0.5)
	assert_eq(String(lingering.get("threat_state", "")), "chasing", "Chase state should persist briefly even after line-of-sight breaks.")

	var contact: Dictionary = threat_director.tick(Vector2(322, 340), 0.25)
	assert_true(bool(contact.get("contact", false)), "A threat should report contact when it reaches the player.")

	pass_test("OUTDOOR_THREAT_DIRECTOR_OK")
