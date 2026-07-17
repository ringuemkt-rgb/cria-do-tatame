#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

: "${GODOT_BIN:?Defina GODOT_BIN para o executável Godot 4.2.2}"
: "${ANDROID_HOME:?Defina ANDROID_HOME para o Android SDK}"
: "${JAVA_HOME:?Defina JAVA_HOME para o JDK 17}"

APK="builds/android/CriaDoTatame-debug.apk"
HASH_FILE="${APK}.sha256.txt"
LOG="reports/build/android_export.log"
REPORT="reports/build/android_build_report.json"

mkdir -p builds/android reports/build
npm run quality
"$GODOT_BIN" --headless --editor --path . --quit
"$GODOT_BIN" --headless --path . --script tests/runtime_smoke.gd
"$GODOT_BIN" --headless --path . --script tests/full_game_smoke.gd
"$GODOT_BIN" --headless --path . --script tests/faction_director_smoke.gd
"$GODOT_BIN" --headless --path . --export-debug "Android Debug" "$APK" 2>&1 | tee "$LOG"

unzip -t "$APK" >/dev/null
"$ANDROID_HOME/build-tools/34.0.0/apksigner" verify --verbose "$APK" >/dev/null
BADGING="$($ANDROID_HOME/build-tools/34.0.0/aapt dump badging "$APK" 2>/dev/null || true)"
grep -q "package: name='com.criadotatame.pressao'" <<<"$BADGING"
APK_FILES="$(unzip -Z1 "$APK")"
grep -Fxq 'lib/arm64-v8a/libgodot_android.so' <<<"$APK_FILES"
sha256sum "$APK" > "$HASH_FILE"

SIZE="$(stat -c %s "$APK")"
SHA="$(cut -d' ' -f1 "$HASH_FILE")"
cat > "$REPORT" <<JSON
{
  "artifact": "$APK",
  "preset": "Android Debug",
  "engine": "Godot 4.2.2 stable",
  "package_id": "com.criadotatame.pressao",
  "architecture": "arm64-v8a",
  "build_type": "debug",
  "signed": true,
  "device_tested": false,
  "size_bytes": $SIZE,
  "sha256": "$SHA",
  "validation": {
    "npm_quality": "passed",
    "runtime_smoke": "passed",
    "full_game_smoke": "passed",
    "faction_smoke": "passed",
    "godot_import": "passed",
    "apk_zip_integrity": "passed",
    "apk_signature": "passed",
    "apk_manifest": "passed"
  }
}
JSON

printf 'APK: %s\nSHA-256: %s\nRelatório: %s\n' "$APK" "$SHA" "$REPORT"
