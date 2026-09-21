#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/env.sh"
cd "$MEMMEM_ROOT"
mkdir -p build/screenshots
# --smoke uses the demo's own input/state/animation path and exits nonzero on failure.
# Screenshots are written only when a display backend is available.
timeout --kill-after=5s 240s "$GODOT" --path game -- --smoke 2>&1 | tee build/desktop-smoke.log
if rg -q 'SCRIPT ERROR|SMOKE FAILED' build/desktop-smoke.log; then exit 1; fi
rg -q 'SMOKE PASSED' build/desktop-smoke.log
for screenshot in "$XDG_DATA_HOME/mem-mem-foundation"/smoke-*.png; do
  if [[ -f "$screenshot" ]]; then cp "$screenshot" build/screenshots/; fi
done

cp "$XDG_DATA_HOME/mem-mem-foundation/smoke-layout.json" build/smoke-layout.json
