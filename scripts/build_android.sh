#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/env.sh"
cd "$MEMMEM_ROOT"
python3 scripts/prepare_consent.py
mkdir -p build .tools/keys
key="$MEMMEM_ROOT/.tools/keys/debug.keystore"
if [[ ! -f "$key" ]]; then
  keytool -genkeypair -keystore "$key" -storepass android -alias androiddebugkey \
    -keypass android -dname 'CN=Android Debug,O=Android,C=US' -keyalg RSA -validity 10000
fi
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$key"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android
rm -f build/mem-mem-debug.apk
"$GODOT" --headless --path game --editor --import 2>&1 | tee build/import.log
if rg -q 'SCRIPT ERROR|Parse Error|Failed to load script' build/import.log; then exit 1; fi
"$GODOT" --headless --path game --export-debug Android "$MEMMEM_ROOT/build/mem-mem-debug.apk" 2>&1 | tee build/android-build.log
if rg -q 'SCRIPT ERROR|Parse Error|Project export .* failed' build/android-build.log; then exit 1; fi
test -s build/mem-mem-debug.apk
"$ANDROID_HOME/build-tools/36.1.0/apksigner" verify --verbose build/mem-mem-debug.apk
"$ANDROID_HOME/build-tools/36.1.0/zipalign" -c -P 16 -v 4 build/mem-mem-debug.apk > build/apk-alignment.log
python3 scripts/check_apk.py build/mem-mem-debug.apk > build/apk-content.json
sha256sum build/mem-mem-debug.apk > build/mem-mem-debug.apk.sha256
