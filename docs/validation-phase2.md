# Phase 2 validation record

The playable game loop implements all five requested items: player-controlled levels,
generation/difficulty waves, scoring, saved progress, and interaction polish.
The user's own testing so far has been on desktop; physical-device testing remains pending.

## Automated and desktop results

- Godot 4.7.2 import and script checks pass.
- **12,099 assertions, zero failures** in `scripts/validate.sh`. These cover 288
  generated boards across 18 levels and 16 seeds, pair integrity, deterministic
  layouts, lookalike waves, rapid-tap rejection, mismatch clearing, accuracy math,
  interrupted scoring, 30 consecutive level settlements, malformed saves, recovery
  from a corrupt newest snapshot, preference persistence, and existing service cases.
- Rendered desktop smoke passes using actual pointer events: the half-second preview,
  rapid taps, both mismatch portraits flipping down, walking departure, completion,
  explicit 6-to-8-tile progression, cumulative score, pause during mismatch and
  completion, saved partial next level, 12-tile layout bounds, reduced motion, and
  independent user/background/lab pause states. Completion tests verify all 6 or 12
  characters return, switch to cheering, fit within the board, and never cover the
  result card. The result remains beyond the former automatic delay, survives
  reloading a completed save, and advances exactly once on Next level. Reduced
  motion disables the cheering process and retains the still group. Screenshots are visually inspected.
- Desktop smoke uses separate test saves and never resets the player's journey.

## Android results

The version **0.2.1-celebration** debug APK builds, installs, and runs on the Google
APIs API 35 x86_64 emulator at 432 × 900 using ANGLE/SwiftShader and KVM.

- Actual touch input matched pairs and completed levels 1–5, using Next level to reach
  the six-tile breather at level 6. One deliberate mismatch in level 1 produced a
  45-point accuracy bonus; cumulative score at level 6 was exactly **2,505**.
- Force-stop during departure preserved the earned match, attempts, and fixed board.
  Force-stop after the final match kept the completed result on the same level.
  Background/resume also preserved it. Explicit Next level then settled the result
  once; repeated taps neither skipped a level nor revealed a pair during preview.
- Background/resume preserved an unfinished level 2. Android Back opened/resumed
  pause; background/resume while paused kept the pause screen visible.
- Offline process restart preserved the same level, positions, attempts, and score.
- No GDScript errors, Godot errors, or Android fatal exceptions in the gameplay log.
- APK signature verification, ZIP 16 KB alignment, native ELF 16 KB load-segment
  alignment, and inclusion of both native plugins pass. Android VIBRATE permission
  is included; vibration feel still needs a physical phone.

See `build/android-build.log`, `build/apk-content.json`, `build/apk-alignment.log`,
`build/android-phase2-runtime.log`, `build/android-phase2-results.json`, and
`build/screenshots/android-phase2-*.png`. The APK's adjacent SHA-256 records the
current artifact. Historical Phase 1 SDK demonstrations are documented separately;
they do not constitute live-account integration validation.

## Evidence and reproduction

```bash
./scripts/validate.sh
xvfb-run -a ./scripts/smoke_desktop.sh
./scripts/build_android.sh
source scripts/env.sh
python3 scripts/smoke_android.py --reset-test-progress
```

Generated evidence is excluded from Git: `build/import.log`, `build/tests.log`,
`build/desktop-smoke.log`, and `build/screenshots/smoke-*.png`. The source tests live
in `game/tests/`. Run `scripts/run.sh` for desktop play. Completed levels wait for **Next level**;
**Pause** contains resume, motion/haptic preferences, and the development service lab.
The Android script requires the bundled test emulator with the APK already installed
and explicitly resets only its game-progress files. It refuses physical-device serials
and does not modify desktop progress or simulated purchase ownership.

## Still pending

Physical-phone readability, touch accuracy, frame pacing, thermal/battery behavior,
ARM64 runtime, and Android-version/device-size coverage require real devices. Engine
and APK alignment checks do not replace a runtime test on a 16 KB-page device.

The difficulty wave, accessory readability, half-second preview, and delays are
initial tuning choices, not evidence of long-session enjoyment or retention. User
playtesting remains important. Art is still placeholder, and audio, collections,
paid packs, production ads/purchases, and iOS remain later milestones.

Live Play purchase/restoration and configured AdMob/UMP validation remain pending
account setup. The native billing adapter cannot initiate charges or grant real
ownership. See [store setup](store-setup.md) and the [historical Phase 1 SDK results](validation-phase1.md).
