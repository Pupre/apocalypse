extends "res://tests/support/test_case.gd"

const ANDROID_MANIFEST_PATH := "res://android/build/AndroidManifest.xml"
const ANDROID_BUILD_VERSION_PATH := "res://android/.build_version"
const ANDROID_ASSETS_DIR := "res://android/build/assets"
const ANDROID_ASSET_PACK_DIR := "res://android/build/assetPacks/installTime/src/main/assets"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	assert_true(
		FileAccess.file_exists(ANDROID_MANIFEST_PATH),
		"Android export manifest should exist so portrait mobile builds can be verified."
	)

	var manifest_text := FileAccess.get_file_as_string(ANDROID_MANIFEST_PATH)
	assert_true(
		manifest_text.contains('android:screenOrientation="portrait"'),
		"Android export manifest should lock the launcher activity to portrait orientation."
	)
	assert_true(
		not manifest_text.contains('android:screenOrientation="landscape"'),
		"Android export manifest should no longer force landscape orientation."
	)
	assert_true(
		FileAccess.file_exists(ANDROID_BUILD_VERSION_PATH),
		"Android build template should include .build_version so Godot can validate the installed template."
	)
	var build_version_text := FileAccess.get_file_as_string(ANDROID_BUILD_VERSION_PATH).strip_edges()
	assert_true(
		build_version_text.begins_with("4.4.1.stable"),
		"Android build template should advertise the Godot 4.4.1 template version."
	)
	assert_true(
		DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(ANDROID_ASSETS_DIR)),
		"Android build template should include the top-level assets directory expected by the Gradle export flow."
	)
	assert_true(
		DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(ANDROID_ASSET_PACK_DIR)),
		"Android build template should include the install-time asset pack target directory for exported game data."
	)

	pass_test("ANDROID_EXPORT_CONTRACT_OK")
