extends "res://tests/support/test_case.gd"

const KNOWLEDGE_CODEX_SCRIPT_PATH := "res://scripts/autoload/knowledge_codex.gd"
const TEST_STORAGE_PATH := "user://knowledge_codex_test.json"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var codex_script := load(KNOWLEDGE_CODEX_SCRIPT_PATH) as Script
	if not assert_true(codex_script != null, "KnowledgeCodex script should exist at %s." % KNOWLEDGE_CODEX_SCRIPT_PATH):
		return

	var codex = codex_script.new()
	if not assert_true(codex != null, "KnowledgeCodex should instantiate for persistence tests."):
		return

	assert_true(codex.has_method("set_storage_path"), "KnowledgeCodex should let tests redirect persistence output.")
	assert_true(codex.has_method("clear_all"), "KnowledgeCodex should support clearing all saved journal data.")
	assert_true(codex.has_method("register_item"), "KnowledgeCodex should register discovered items.")
	assert_true(codex.has_method("record_attempt"), "KnowledgeCodex should record crafting attempts.")
	assert_true(codex.has_method("save"), "KnowledgeCodex should persist its journal to disk.")
	assert_true(codex.has_method("load_from_disk"), "KnowledgeCodex should reload saved journal data.")
	assert_true(codex.has_method("get_item_entry"), "KnowledgeCodex should expose item-centric journal entries.")

	codex.set_storage_path(TEST_STORAGE_PATH)
	codex.clear_all()
	codex.register_item("newspaper")
	codex.record_attempt("newspaper", "cooking_oil", {
		"result_type": "success",
		"result_item_id": "dense_fuel",
		"result_label": "고농축 땔감",
	})
	codex.save()

	var reloaded = codex_script.new()
	reloaded.set_storage_path(TEST_STORAGE_PATH)
	reloaded.load_from_disk()

	var newspaper_entry: Dictionary = reloaded.get_item_entry("newspaper")
	assert_eq(String(newspaper_entry.get("item_id", "")), "newspaper", "Reloaded entries should stay keyed by discovered item id.")
	var attempts: Array = newspaper_entry.get("attempts", [])
	assert_eq(attempts.size(), 1, "Reloaded item entries should preserve recorded attempts.")
	assert_eq(String((attempts[0] as Dictionary).get("other_item_id", "")), "cooking_oil", "Codex rows should keep the paired item id for each attempt.")
	assert_eq(String((attempts[0] as Dictionary).get("result_item_id", "")), "dense_fuel", "Codex rows should keep the recorded result item id.")

	var autoload = root.get_node_or_null("KnowledgeCodex")
	assert_true(autoload != null, "KnowledgeCodex should be registered as an autoload singleton.")
	codex.free()
	reloaded.free()
	pass_test("KNOWLEDGE_CODEX_OK")
