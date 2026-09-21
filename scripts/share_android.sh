#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/env.sh"
cd "$MEMMEM_ROOT"
if [[ ! -s build/mem-mem-debug.apk ]]; then
  echo 'Build the APK first: ./scripts/build_android.sh' >&2
  exit 1
fi
exec python3 scripts/share_android.py "$@"
