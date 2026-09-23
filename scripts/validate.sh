#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/env.sh"
cd "$MEMMEM_ROOT"
mkdir -p build
node --test server/*.test.mjs
node server/receipt_fixture.mjs build/receipt-fixture.json
python3 -m unittest discover -s tests -p 'test_*.py'
python3 scripts/generate_people.py --check
python3 scripts/generate_audio.py --check
"$GODOT" --headless --path game --editor --import 2>&1 | tee build/import.log
if rg -q 'SCRIPT ERROR|Parse Error|Failed to load script' build/import.log; then exit 1; fi
timeout --kill-after=5s 120s "$GODOT" --headless --path game --script tests/run_tests.gd 2>&1 | tee build/tests.log
if rg -q 'SCRIPT ERROR|Parse Error|TEST FAILED' build/tests.log; then exit 1; fi
timeout --kill-after=5s 60s "$GODOT" --headless --path game --script tests/production_smoke.gd 2>&1 | tee build/production-smoke.log
if rg -q 'SCRIPT ERROR|Parse Error|TEST FAILED' build/production-smoke.log; then exit 1; fi
rg -q 'PRODUCTION SMOKE PASSED' build/production-smoke.log
