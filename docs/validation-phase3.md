# Phase 3 validation record

Validated locally on 2026-09-20. Phase 3 implements the first character, animation,
sound, and copy polish pass. The user's own testing has been on desktop;
physical-phone review remains pending. Earlier records are preserved in
[Phase 2](validation-phase2.md) and [Phase 1](validation-phase1.md).

## Automated and desktop results

- Godot 4.7.2 import/script checks pass. **12,129 assertions, zero failures** cover
  the existing gameplay, scoring, save recovery, and service scenarios, plus old-save
  compatibility, sound preference validation/persistence, valid imported audio,
  bounded playback, immediate muting, and pause/background gates.
- Generated SVGs and WAVs match their editable source scripts. All six sound
  effects are under 0.8 seconds and pass synthesis clipping checks. All 24 portrait
  and head assets use shared per-family drawings with hoop/pearl variants.
- The rendered desktop smoke passes using actual pointer input. It covers the
  half-second preview, rejected extra taps, both mismatch cards turning down,
  match departures, score, all-character return, held completion, completed-save
  reload, Next level, 12-card layout bounds, pause/background/lab behavior, and
  reduced motion. Enabling reduced motion during a flip settles its intended face.
- Audio interaction checks pass: accepted taps emit one cue, rejected taps are
  silent, each matched pair sounds once, completion sounds once, and restoring
  a result does not replay it. Pause stops active effects. Muting through the UI
  persists immediately and permits a silent Next level, shuffle, reveal, and match.
  Re-enabling sound saves correctly.
- The full twelve-identity contact sheet, six-/twelve-card previews, walking,
  completion groups, and settings screen were rendered and visually inspected.
  The returning figures use the same faces/accessories as their portrait cards.
- Desktop tests use separate progress/ownership files and leave player saves alone.
  Xvfb reports input-method and unsupported VSync warnings; there are no script
  errors. These software-rendered checks do not measure phone frame pacing.

## Android results

The **0.3.0-polish** debug APK (version code 4, approximately 161.86 MiB) builds,
installs, and runs on the dedicated Google APIs API 35 x86_64 emulator at 432 × 900
using ANGLE/SwiftShader and KVM.

- Updating the installed Phase 2 build preserved its saved board, removed pairs,
  attempts, level, points, and preferences, adding the default sound setting.
- Actual touch input completed levels 1–5 and explicitly advanced to level 6.
  A deliberate first-level mismatch yielded the expected 45-point bonus and
  exactly **2,505 banked points** at level 6.
- Force-stop during a departure and after completion preserved progress correctly.
  Completed results stayed on the same level after restart and background/resume.
  Next level settled each result once; repeated taps neither skipped levels nor
  selected cards during opening.
- Android Back, background/resume while paused, and offline restart passed.
- Actual taps muted sound in Pause; the saved preference remained off through
  background/resume, offline restart, and the full difficulty wave. Re-enabling
  sound also survived process restart. Board/score were unchanged by the setting.
- No GDScript errors, Godot errors, or Android fatal exceptions in the gameplay log.
- APK signature, ZIP 16 KB alignment, native ELF 16 KB alignment, and inclusion of
  both native SDK plugins pass. All 24 people assets and six audio references are
  packaged. Test/review scripts are excluded from the export.

The emulator runs with host audio disabled. Audio asset/loading and control tests
are verified; audible balance and physical vibration are **not** verified by these
runs. No physical phone was connected.

## Evidence and reproduction

```bash
./scripts/validate.sh
xvfb-run -a ./scripts/smoke_desktop.sh
source scripts/env.sh
xvfb-run -a "$GODOT" --path game --script tests/art_review.gd
./scripts/build_android.sh
# With the dedicated emulator running:
adb -s emulator-5554 install -r build/mem-mem-debug.apk
python3 scripts/smoke_android.py --reset-test-progress
```

Generated evidence is ignored by Git: `build/tests.log`, `build/desktop-smoke.log`,
`build/android-build.log`, `build/apk-content.json`, `build/apk-alignment.log`,
`build/android-phase3-runtime.log`, `build/android-phase3-results.json`, and
`build/screenshots/`. The APK's adjacent SHA-256 records the current artifact.
The Android script refuses physical-device serials and resets only the dedicated
emulator's progress, preserving desktop saves and simulated purchase ownership.

## Remaining review

On a physical Android phone, assess earring readability, thumb reach, perceived
sound volume, speaker/headphone routing, interruption behavior, and haptic strength.
Also pending: ARM64 runtime, frame pacing, longer-session thermal/battery behavior,
Android-version/device-size coverage, and runtime testing on a 16 KB-page device.

The art direction, difficulty wave, timing, and sounds remain tuning candidates;
these checks do not establish long-session enjoyment or retention. Collections,
additional themed packs, sharing, and production monetization remain later work.

Live Play purchases/restoration and configured AdMob/UMP validation remain pending
account setup. Native purchasing stays disabled. See [store setup](store-setup.md)
and [Phase 3 notes](phase3-polish.md).
