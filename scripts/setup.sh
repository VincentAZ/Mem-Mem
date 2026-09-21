#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/env.sh"
cd "$MEMMEM_ROOT"
python3 scripts/bootstrap.py
if [[ "${1:-}" != "--accept-android-licenses" ]]; then
  echo 'Review SDK licenses below. For noninteractive setup use --accept-android-licenses.'
  sdkmanager --licenses
else
  # yes can exit with SIGPIPE after sdkmanager has consumed all input.
  set +o pipefail
  yes | sdkmanager --licenses
  result=${PIPESTATUS[1]}
  set -o pipefail
  [[ "$result" == 0 ]] || exit "$result"
fi
sdkmanager 'platform-tools' 'platforms;android-36' 'build-tools;36.1.0' 'ndk;29.0.14206865' 'cmake;3.10.2.4988404'
python3 scripts/prepare_project.py
mkdir -p build
"$GODOT" --headless --path game --editor --import 2>&1 | tee build/import.log
if rg -q 'SCRIPT ERROR|Parse Error|Failed to load script' build/import.log; then exit 1; fi
