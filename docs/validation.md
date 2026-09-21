# Collection reactions validation — 0.5.2

Validated locally on 2026-09-21. The collection now celebrates eligible selections
with fireworks, celebrates successful saved claims, and responds to owned-character
taps with short randomized dances or greetings plus original sound effects.

## Rules, saves and audio — passed

`./scripts/validate.sh`: Godot import/script checks and **14,073 assertions** passed
with zero failures. Existing perfect-only collection rules, choice banking,
restoration and 50%-accuracy regressions remain covered.

The collection's separate audio pool can play while gameplay is paused; tests verify
that background/hidden gating and mute still override that permission. The gameplay
pool retains its original pause behavior. The three new WAV files are deterministic
project-authored synthesis, checked against `scripts/generate_audio.py`; peak levels
do not clip and all cues remain shorter than 1.5 seconds.

## Desktop UI — passed

`xvfb-run -a ./scripts/smoke_desktop.sh` uses isolated test saves and actual input:

- Browsing without an earned choice has no reward fireworks or sound.
- Selecting an eligible character produces fireworks and sound while gameplay stays
  paused; it neither changes ownership nor consumes the choice.
- A confirmed, successfully saved claim triggers a second burst. Failed saves retain
  ownership/choices and do not show a success celebration.
- Repeated owned-character taps choose different performances without immediate
  repeats, with the matching dance/wave cue. Score, board, ownership and choices
  remain unchanged.
- Backgrounding clears tap effects and stops their sounds. Reduced motion uses still
  reactions, and muted taps keep visual feedback without sound.
- The original matching loop, explicit Next level, 16-card board and celebration,
  collection, settings, lifecycle and the six-pair 50% regression continue to pass.

Selection/confirmation fireworks and the five performer variations were captured
and visually inspected. Performances use the existing 2D cutouts; clapping poses
use dances, while raised-arm poses also support waves. The art is not a 3D rig.

## Android collection interaction — passed

`python3 scripts/smoke_collection.py` installs the current APK on the dedicated API
35 emulator, using the owned-character/earned-choice fixture from `smoke_android.py`.
It spends one test-emulator choice; it never operates on physical-phone saves.

- Updating the APK preserved the exact existing saved progress and collection.
- Five actual owned-character taps produced different reaction captions without
  immediate repeats, leaving ownership and choices unchanged.
- Background/resume during a reaction preserved the board.
- Selection fireworks preceded confirmation without granting ownership. Collect then
  added exactly the selected character and consumed one choice.
- Screenshot comparisons verified a still character after tapping with Reduce motion.
- Restart preserved the explicit claim, current board and banked points.
- No Godot script errors or Android fatal exceptions appeared in the runtime log.

The full eight-level Android gameplay run is recorded for 0.5.1 in
[validation-choice-only.md](validation-choice-only.md); this release ran the targeted
Android collection tests plus the full desktop and headless suites.

Artifacts: `build/tests.log`, `build/desktop-smoke.log`,
`build/android-reactions-results.json`, `build/android-reactions-runtime.log`, and
`build/screenshots/{smoke-,android-reactions-}*.png`.

## APK — passed

`build/mem-mem-debug.apk`: **0.5.2-collection-reactions**, version code **8**.
Export, signature verification, native-plugin inclusion and 16 KB ZIP/native ELF
alignment checks passed.

SHA-256: `1f49e0e118eda720760ef22ae1cd37c57ccca8a82dc53f76606200f583d65f1f`.

Physical-phone animation smoothness and listening/volume feedback remain pending;
emulator output was muted, so automated playback checks do not establish perceived
sound quality. Live billing, ads and consent still require configured accounts.
Real-money purchasing remains disabled. See [store setup](store-setup.md).
