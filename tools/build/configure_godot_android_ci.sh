#!/usr/bin/env bash
set -euo pipefail

: "${ANDROID_HOME:?ANDROID_HOME não definido}"
: "${JAVA_HOME:?JAVA_HOME não definido}"

GODOT_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/godot"
GODOT_SETTINGS="$GODOT_CONFIG_DIR/editor_settings-4.tres"
GODOT_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot"
GODOT_KEYSTORE="$GODOT_DATA_DIR/keystores/debug.keystore"

mkdir -p "$GODOT_CONFIG_DIR" "$GODOT_DATA_DIR/keystores" "$HOME/.android" builds/android reports/full_game_audit

if [[ ! -s "$GODOT_KEYSTORE" ]]; then
  keytool -genkeypair -v \
    -keystore "$GODOT_KEYSTORE" \
    -storepass android \
    -alias androiddebugkey \
    -keypass android \
    -dname "CN=Android Debug,O=Android,C=US" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000
fi

cp "$GODOT_KEYSTORE" "$HOME/.android/debug.keystore"

cat > "$GODOT_SETTINGS" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/java_sdk_path = "$JAVA_HOME"
export/android/android_sdk_path = "$ANDROID_HOME"
export/android/debug_keystore = "$GODOT_KEYSTORE"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
EOF

[[ -d "$ANDROID_HOME" ]]
[[ -x "$JAVA_HOME/bin/java" ]]
[[ -x "$JAVA_HOME/bin/jarsigner" ]]
[[ -s "$GODOT_KEYSTORE" ]]
[[ -s "$GODOT_SETTINGS" ]]

printf 'ANDROID_HOME=%s\n' "$ANDROID_HOME"
printf 'JAVA_HOME=%s\n' "$JAVA_HOME"
printf 'GODOT_SETTINGS=%s\n' "$GODOT_SETTINGS"
printf 'GODOT_KEYSTORE=%s\n' "$GODOT_KEYSTORE"
