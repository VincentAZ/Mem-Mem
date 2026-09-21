# Collection and layout update validation — 0.5.0

Validated locally on 2026-09-20. This release makes collection and appearance
controls visible, redesigns the HUD and settings, animates owned characters, and
extends difficulty to 16 cards. Earlier discovery results are retained in
[validation-discovery.md](validation-discovery.md).

## Automated rules and persistence — passed

`./scripts/validate.sh`: Godot import/script checks passed; **14,035 assertions,
zero failures**. Coverage includes deterministic boards, exact pairs, mismatch
resolution, point/bonus bounds, saves and recovery, reward idempotency, collection
claims, audio gating and simulated/native-adapter service behavior.

Expanded-wave checks cover 16-card boards in every theme, eight solvable pairs and
960 perfect-board points. Schema 1 and 2 migrations preserve partially cleared
boards at levels 7, 8, 13 and 48, then survive another full wave of advancing,
saving and reloading. Tests reject contradictory migration boundaries and retain
collection, choices and appearance settings from schema 2.

The new schema 3 stores the first level using generator 3. The current saved board
keeps its old generator and exact positions until it is completed. Score validation
accounts for old-wave history and the expanded wave separately.

## Desktop interaction and visual checks — passed

`xvfb-run -a ./scripts/smoke_desktop.sh` drives real pointer/keyboard events in an
isolated save. Screenshots were inspected in light and dark modes.

- Round score is centered within one pixel; pairs and accuracy flank it in equal columns.
- Persistent bottom buttons open My collection and Settings.
- Empty collections and empty theme filters explain how to earn/find characters.
- Discover all lists the catalog; selection plus Collect spends one choice exactly once.
- Owned cards have gold surfaces, frames, corner markers and animated cheering poses.
- Owned characters animate while gameplay behind the collection is paused; backgrounding
  freezes them, resuming restarts them, and Reduce motion keeps them still.
- The 0.5-second preview, mismatch reset, walking, explicit Next level, held/restored
  results, dark mode, backgrounds and sound preferences still work.
- All 16 cards stay in bounds with at least 88×88 viewport-unit touch targets.
  Every pair was cleared through input, earning exactly 960 round points.
- All 16 characters return and cheer without covering the completion card.

Artifacts: `build/screenshots/smoke-*.png`, `build/desktop-smoke.log` and
`build/smoke-layout.json`. The JSON exports actual control positions for Android
input tests, avoiding a separate copy of the board layout.

## Android API 35 emulator — passed

`python3 scripts/smoke_android.py --reset-test-progress` on the isolated
432×900 `MemMemTest` emulator, using `swangle`. This command resets only emulator
progress; the player's desktop save is never changed. Pillow is required for
screenshot comparisons (`python3-pil` on Debian/Ubuntu).

- Installing over 0.4.0 preserved the old board, score, collected characters,
  saved choices, reward marker, dark mode and background.
- Real Android touch input cleared levels 1–8, including the 16-card peak.
  With one intentional mismatch on level 1, level 9 began with **4,545 banked points**,
  **6 saved choices**, and **3 collected characters** (one chosen plus two surprises).
- Process termination during departure, restored completion, explicit advancement,
  background/resume, pause, offline relaunch and mute/unmute passed.
- A perfect board earned a choice; claiming it survived restart without re-awarding.
- Dark mode and the Orbit background persisted across restart. The popup is tested
  with a direct tap; an earlier keyboard-driven test selected Twilight instead.
- Screenshot differences verified collection animation inside the game area;
  Reduce motion produced identical still frames.
- No Godot script errors, runtime errors or Android fatal exceptions appeared.

After the final empty-state layout adjustment, the final APK was installed and
checked again for launch, exact save preservation, collection animation, the empty
Firefighters filter, and a clean runtime log. That screen was visually inspected.

Artifacts: `build/android-collection-results.json`, `build/android-final-results.json`,
`build/android-collection-runtime.log`, `build/android-final-runtime.log`, and
`build/screenshots/android-{collection,final}-*.png`. The successful old-version
migration check is also recorded in `.tools/layout-android-migration.log`.

## APK — passed

**0.5.0-collection**, version code **6**, approximately **171.3 MiB**:
`build/mem-mem-debug.apk`.

- Godot Android export and APK signature verification passed.
- Native billing and advertising plugins remain included.
- ZIP/native ELF 16 KB alignment checks passed for arm64-v8a and x86_64.
- SHA-256: `88be72b25b3b49b3f1f123c341afe7e0331ddda0e204917dae1a103dee4bbc92`.

## Still requires physical-device or account validation

Physical-phone testing remains pending: accessory readability on the 4×4 board,
thumb reach, animation smoothness, sustained performance, heat/battery behavior,
vibration and speaker/headphone sound. The emulator cannot establish these.

Live Play purchases/restoration, production ad-removal ownership, AdMob and UMP
consent flows still require configured accounts and store/device tests. Simulations
are not live validation. Real-money purchasing remains disabled. See
[store-setup.md](store-setup.md).
