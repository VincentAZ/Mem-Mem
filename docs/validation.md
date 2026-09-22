# Collection selection applause — 0.6.1

Validated locally on 2026-09-21. Selecting an eligible character now starts a short
jump-and-clap alongside the selection fireworks. A successful, saved Collect action
repeats the reaction. Selection does not grant ownership or spend a choice.

## Godot and desktop — passed

`./scripts/validate.sh`: Godot import/script checks and **88,349 checks**, zero failures.
`xvfb-run -a ./scripts/smoke_desktop.sh`: full rendered interaction suite passed.
New interaction assertions verify that an unowned selected character actually animates
while gameplay is paused, and that the successful claim repeats the reaction. Existing
coverage checks explicit ownership, failed-save rollback, hidden/background behavior,
reduced motion, mute, ordinary owned-character reactions, Quick Peek and Plus.

All 56 characters have dedicated clapping poses. Three animation phases across the
whole catalog were rendered and visually inspected, plus the actual phone-sized
collection selection screen. The continuous mesh keeps character silhouettes intact;
short jumps and forearm pulses provide the applause motion. Shared clapping textures
load only when needed. Offscreen/hidden reactions stop. Reduce motion retains still
feedback and the existing static fireworks treatment.

`python3 scripts/measure_character_atlases.py --clap --check` verified all eight
unchanged, transparent generated atlases and their stable-ID bounds. Built-in image
generation prompts and paths are recorded in [asset credits](asset-credits.md) and
[the prompt record](character-art-prompts.json).

## Android — passed

Final emulator collection validation is recorded in `build/android-clap-collection.log`.
The test passed. It installs the APK on the dedicated API 35 emulator and verifies saved progress,
selection without premature collection, explicit claim/choice consumption, owned
reactions, background/resume, reduced motion and restart. It uses only test-emulator
progress; desktop/player saves are untouched.

## APK — passed

`build/mem-mem-debug.apk`: **0.6.1-collection-clap**, version code **10**.
Build, signature verification, native plugin inclusion and 16 KB library/ZIP alignment
checks passed. SHA-256: `3337a77df996d7a8058facb1bffc3d3c11c1a56f8d7cce0037b07b0bcc1e262a`.

Artifacts: `build/validation-clap.log`, `build/desktop-smoke.log`,
`build/clap-review.log`, `build/screenshots/selection-clap-*.png`,
`build/screenshots/smoke-selection-fireworks.png`, `build/android-clap-build.log`,
`build/android-clap-collection.log`, and `build/android-reactions-runtime.log`.

Physical-phone animation feedback remains pending. Real-money purchases remain
unconditionally disabled; production store, advertising and consent validation still
require configured accounts. The broader Quick Peek milestone results are archived
in [validation-quick-peek.md](validation-quick-peek.md).
