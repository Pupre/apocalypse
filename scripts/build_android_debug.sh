#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME_DIR="$ROOT_DIR/game"
ANDROID_BUILD_DIR="$GAME_DIR/android/build"
EXPORT_PRESETS="$GAME_DIR/export_presets.cfg"
OUTPUT_DIR="$GAME_DIR/builds/android"
OUTPUT_APK="$OUTPUT_DIR/apocalypse-debug.apk"
PACK_PATH="${PACK_PATH:-/tmp/apocalypse-data.pck}"
GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"

GODOT_BIN="${GODOT_BIN:-/home/muhyeon_shin/packages/.local-tools/godot/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64}"
ANDROID_SDK="${ANDROID_SDK:-/home/muhyeon_shin/packages/.local-tools/android-sdk}"
DEBUG_KEYSTORE="${DEBUG_KEYSTORE:-/tmp/codex-godot-export-test/godot/keystores/debug.keystore}"
DEBUG_KEY_ALIAS="${DEBUG_KEY_ALIAS:-androiddebugkey}"
DEBUG_KEY_PASSWORD="${DEBUG_KEY_PASSWORD:-android}"

ASSET_DIR="$ANDROID_BUILD_DIR/assets"
ASSET_PACK_DIR="$ANDROID_BUILD_DIR/assetPacks/installTime/src/main/assets"
GRADLE_OUTPUT_APK="$ANDROID_BUILD_DIR/build/outputs/apk/standard/debug/android_debug.apk"
LOCAL_PROPERTIES="$ANDROID_BUILD_DIR/local.properties"

read_export_value() {
	local key="$1"
	grep -E "^${key}=" "$EXPORT_PRESETS" | head -n 1 | sed -E 's/^[^=]+=//; s/^"//; s/"$//'
}

require_file() {
	local path="$1"
	if [[ ! -f "$path" ]]; then
		echo "Missing required file: $path" >&2
		exit 1
	fi
}

require_dir() {
	local path="$1"
	if [[ ! -d "$path" ]]; then
		echo "Missing required directory: $path" >&2
		exit 1
	fi
}

require_file "$GODOT_BIN"
require_file "$EXPORT_PRESETS"
require_file "$DEBUG_KEYSTORE"
require_dir "$ANDROID_SDK"
require_dir "$ANDROID_BUILD_DIR"

PACKAGE_NAME="$(read_export_value 'package/unique_name')"
VERSION_CODE="$(read_export_value 'version/code')"
VERSION_NAME="$(read_export_value 'version/name')"
MIN_SDK="$(read_export_value 'gradle_build/min_sdk')"
TARGET_SDK="$(read_export_value 'gradle_build/target_sdk')"
ENABLED_ABIS="$(awk -F= '/^architectures\// { abi=$1; sub(/^architectures\//, "", abi); if ($2 == "true") printf "%s|", abi }' "$EXPORT_PRESETS" | sed 's/|$//')"

if [[ -z "$PACKAGE_NAME" || -z "$VERSION_CODE" || -z "$VERSION_NAME" || -z "$MIN_SDK" || -z "$TARGET_SDK" || -z "$ENABLED_ABIS" ]]; then
	echo "Failed to read Android export settings from $EXPORT_PRESETS" >&2
	exit 1
fi

mkdir -p "$OUTPUT_DIR" "$ASSET_DIR" "$ASSET_PACK_DIR"
mkdir -p "$GRADLE_USER_HOME"
cat > "$LOCAL_PROPERTIES" <<EOF
sdk.dir=$ANDROID_SDK
EOF

echo "==> Exporting Android pack"
"$GODOT_BIN" --headless --path "$GAME_DIR" --export-pack Android "$PACK_PATH"

echo "==> Copying pack into Android template"
cp "$PACK_PATH" "$ASSET_DIR/data.pck"
cp "$PACK_PATH" "$ASSET_PACK_DIR/data.pck"

echo "==> Building debug APK with Gradle"
(
	cd "$ANDROID_BUILD_DIR"
	export GRADLE_USER_HOME
	./gradlew assembleDebug \
		-Pexport_package_name="$PACKAGE_NAME" \
		-Pexport_version_code="$VERSION_CODE" \
		-Pexport_version_name="$VERSION_NAME" \
		-Pexport_version_min_sdk="$MIN_SDK" \
		-Pexport_version_target_sdk="$TARGET_SDK" \
		-Pexport_enabled_abis="$ENABLED_ABIS" \
		-Pperform_signing=true \
		-Pdebug_keystore_file="$DEBUG_KEYSTORE" \
		-Pdebug_keystore_password="$DEBUG_KEY_PASSWORD" \
		-Pdebug_keystore_alias="$DEBUG_KEY_ALIAS" \
		-Pgodot_editor_version=4.4.1.stable
)

require_file "$GRADLE_OUTPUT_APK"
cp "$GRADLE_OUTPUT_APK" "$OUTPUT_APK"

echo "==> Built APK"
echo "$OUTPUT_APK"
