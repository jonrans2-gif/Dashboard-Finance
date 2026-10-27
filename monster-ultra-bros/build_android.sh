#!/usr/bin/env bash
# Builds a signed release APK of Monster Ultra Bros.
# Requires: Godot 4.7.x on PATH as `godot`, Android export templates installed,
# Android SDK + JDK configured in Godot's editor settings, and a keystore:
#   MUB_KEYSTORE=/path/to.keystore MUB_KEY_ALIAS=alias MUB_KEY_PASS=pass ./build_android.sh
set -euo pipefail
cd "$(dirname "$0")"
: "${MUB_KEYSTORE:?set MUB_KEYSTORE to your release keystore}"
: "${MUB_KEY_ALIAS:?set MUB_KEY_ALIAS}"
: "${MUB_KEY_PASS:?set MUB_KEY_PASS}"
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$MUB_KEYSTORE"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$MUB_KEY_ALIAS"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$MUB_KEY_PASS"
mkdir -p build
godot --headless --path . --import
godot --headless --path . --fixed-fps 60 res://tests/test_runner.tscn   # abort on failing tests
godot --headless --path . --export-release Android build/MonsterUltraBros.apk
echo "APK: $(pwd)/build/MonsterUltraBros.apk"
