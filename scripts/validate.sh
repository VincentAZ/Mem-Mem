#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/env.sh"
cd "$MEMMEM_ROOT"
mkdir -p build
python3 scripts/generate_people.py --check
python3 scripts/generate_audio.py --check
"$GODOT" --headless --path game --editor --import 2>&1 | tee build/import.log
if rg -q 'SCRIPT ERROR|Parse Error|Failed to load script' build/import.log; then exit 1; fi
"$GODOT" --headless --path game --script tests/run_tests.gd 2>&1 | tee build/tests.log
if rg -q 'SCRIPT ERROR|Parse Error|TEST FAILED' build/tests.log; then exit 1; fi
