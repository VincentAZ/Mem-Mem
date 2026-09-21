# Discovery update validation — 0.4.0

Validated locally on 2026-09-20. This is a playable iteration of themed discovery,
collection rewards, expressive art, varied presentation, and appearance settings.
It does not establish long-session enjoyment or retention. Historical records:
[Phase 3](validation-phase3.md), [Phase 2](validation-phase2.md), [Phase 1](validation-phase1.md).

## Automated and desktop

- Godot 4.7.2 import/script checks pass. **12,154 assertions, zero failures** in the
  rule/save/service tests, including expanded 24-character generation, perfect-choice
  settlement, no double awards after reload, any-theme collection, duplicate/invalid
  claim rejection, imperfect-board discovery progress, nonduplicate third-board
  discovery, appearance preferences, chosen next-board theme, malformed collection
  fields, and real schema-1 migration preserving the old board and points.
- Existing score, mismatch, rapid-input, interrupted-save, corrupted-file recovery,
  and simulated/native service-boundary tests still pass.
- Rendered desktop smoke passes through real pointer and keyboard input. It verifies
  the longer shuffle precedes the 0.5-second preview of the exact final positions;
  a perfect board can be solved from memory. Both mismatch cards turn down, and
  selected pairs are input-locked until resolution. New expressions, departures,
  full-cast returns, held results, explicit Next level, 12-card bounds, and reduced
  motion are exercised.
- Collection opens from the completed result and pauses animation. Selecting a
  character and confirming it spends exactly one choice and persists ownership.
  A failed save rolls ownership/credit back. Escape returns to the held result.
  Dark mode and background changes apply and persist through UI controls.
- Audio gating/mute persistence, completion sound not replaying on restore, layered
  pause/background/lab states, and muted continued play pass. Xvfb produces only its
  known input-method/VSync warnings, with no script errors or collection-layout warnings.
- Character atlas crops, accessory variants, adult proportions, six-/twelve-card
  previews, results, collection grid, and dark settings were visually inspected.
  Test data remains isolated from the player's desktop journey.

## Android

The **0.4.0-discovery** debug APK (version code 5, about **171.29 MiB**) builds,
installs, and runs on the dedicated Google APIs API 35 x86_64 emulator at 432 × 900,
using ANGLE/SwiftShader and KVM.

- An upgrade from the prior schema-1 installation preserved its exact board,
  level, points, sound, vibration, and motion preferences. Legacy generation stayed
  attached to that board; collection ownership was not fabricated during migration.
- Touch input completed levels 1–5 and advanced only through Next level to level 6.
  One deliberate first-level mismatch yielded 345 points; the complete wave ended
  with exactly **2,505 banked points**.
- A perfect level 2 offered one collection choice. Touching a character and Collect
  saved ownership and spent the choice. Force-stop/relaunch did not lose or duplicate
  either the character or the reward. Four perfect boards minus that claim left
  three banked choices; the three-board surprise added one other unique character.
- Process termination during a departure, restoration of an unadvanced result,
  held completion, repeat Next taps, pause, background/resume, and offline restart pass.
- Saved muting persisted through the full wave. Sound re-enable, dark mode, and Orbit
  background selected through actual touches survived process restart together with
  the collection and score. A test initially used an unsupported keyboard shortcut
  for the background popup; the final script uses touch and passes.
- No GDScript errors, Godot errors, or Android fatal exceptions in the final runtime log.
- APK signature, ZIP 16 KB alignment, native ELF 16 KB alignment, and inclusion of
  both native SDK plugins pass. Eight atlas references and nine sound references
  are packaged. Tests and archived vector art are excluded.

## Evidence and commands

```bash
./scripts/validate.sh
xvfb-run -a ./scripts/smoke_desktop.sh
source scripts/env.sh
xvfb-run -a "$GODOT" --path game --script tests/art_review.gd -- 2
./scripts/build_android.sh
adb -s emulator-5554 install -r build/mem-mem-debug.apk
python3 scripts/smoke_android.py --reset-test-progress
```

The art-review argument selects theme 0–3. Screenshots are under `build/screenshots/`:
`smoke-preview.png`, `smoke-twelve-preview.png`, `smoke-collection.png`,
`smoke-collected.png`, `smoke-dark-complete.png`, `smoke-dark-collection.png`,
`smoke-dark-settings.png`, `character-pack-2.png`, and `android-discovery-*.png`.
Other ignored evidence: `build/tests.log`, `build/desktop-smoke.log`,
`build/android-build.log`, `build/android-discovery-runtime.log`,
`build/android-discovery-results.json`, `build/apk-content.json`, and alignment logs.
The adjacent APK SHA-256 identifies the final artifact. Android tests refuse
physical-device serials and reset only the dedicated emulator's game progress.

## Physical and account testing still pending

No physical phone was connected. The emulator ran with host audio disabled;
asset loading/control behavior is verified, but sound loudness, crowd mixing,
speaker/headphone routing, haptic feel, and interruption behavior require listening
on a phone. Also pending: ARM64 runtime, frame pacing, small/high-density displays,
long-session thermal/battery behavior, and runtime on a 16 KB-page device.

The new art style, accessory overlays, 2D cutout movement, preview difficulty,
collection reward frequency, and desire to continue need player feedback. They are
implemented candidates, not proven solutions to monotony.

Live purchases/restoration and configured AdMob/UMP validation remain pending
accounts. No production charges or ads were enabled. Sharing remains deferred.
See [discovery rules](discovery-update.md), [asset credits](asset-credits.md), and
[store setup](store-setup.md).
