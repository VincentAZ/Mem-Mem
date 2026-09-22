# Mem-Mem — matching game

A Godot 4.7.2 / GDScript Android portrait-matching game.
Version **0.6.1 — Collection applause** has 56 collectible characters across seven themes,
with distinct matching pairs and a 4–16-card difficulty rhythm. Hard boards lead
immediately to four-card boards. The held completion, collection reactions, dark
mode and four backgrounds remain part of the game.

**100% accuracy earns one bankable choice from unlocked themes.** Select a character
and press Collect; there are no automatic or random collection awards. Quick Peek
preserves accuracy and perfect-round eligibility.

**Quick Peek** reveals the remaining cards for 0.5 seconds, once per board. Free
players explicitly watch a rewarded test ad, then tap Ready when they want their
peek. **Settings → Mem-Mem Plus** opens the **$1.99 one-time introductory bundle**:
no ads, a peek on each board, and Woodland Crew, Snack Squad and Mythical Misfits.
The original four themes, now eight characters each, stay free. Plus unlocks paid
characters to earn, not automatic collection ownership.

**This is a development build.** Purchases and restoration are labeled simulations;
no money is charged. Android uses Google's rewarded test ads; desktop has an
explicit simulated Earn reward button. Settings can select simulated rewarded ads
on Android for offline testing. Real purchases and production consent/ads remain
pending store setup. The intended later price is $3.99; there is no automatic price
change or fictitious crossed-out price.

## Run it

On Linux x86_64, install Python 3.12+, `curl`, `ripgrep`, and standard OpenGL runtime libraries, then:

```bash
./scripts/setup.sh
./scripts/validate.sh
./scripts/run.sh
```

Setup prompts for Android SDK license acceptance. Use
`./scripts/setup.sh --accept-android-licenses` only after reviewing the licenses.
Setup downloads the checksum-pinned engine, export templates, JDK 17, Android CLI,
and native plugins. All tools and caches live in ignored `.tools/`; the installed
system Java is not replaced. Allow approximately 12–16 GB for setup, build caches,
and the optional emulator. Network access is required for initial setup/build.

To use the editor with the same isolated environment:

```bash
./scripts/run.sh --editor
```

## Build and install Android

```bash
./scripts/build_android.sh
source scripts/env.sh
adb devices
adb -s YOUR_DEVICE_SERIAL install -r build/mem-mem-debug.apk
```

To send the same APK to testers, keep this running and share the printed link:

```bash
./scripts/share_android.sh
```

Testers open the link on their phone, tap **Download and install**, allow the
browser to install unknown apps, then open Mem-Mem. Same-Wi-Fi testers can use
the LAN address for a faster copy. Do not stop the script until downloads finish.

The APK supports Android 8+ (API 26), targets API 36, and contains arm64-v8a and
x86_64 native libraries. It uses package `io.github.vincentaz.memmem` and a local
debug certificate. Do not publish this debug build to production.

For an emulator, run `./scripts/emulator.sh` in another terminal, then install the
APK. Software emulation is slow when KVM is unavailable. An Android phone with USB
debugging is preferable for animation/performance assessment.

The emulator script uses ANGLE/SwiftShader (`swangle`). The older
`swiftshader_indirect` backend failed this engine's shader uniform-limit checks.
For a headless host, add `-no-window`. Wait for `adb shell getprop sys.boot_completed`
to return `1` before installing. The emulator's Google APIs image tests local SDK
behavior; live purchases need a Play-enabled device and configured store account.

## What's included

- A repeating **4, 6, 8, 6, 12, 4, 8, 6, 16, 4, 8, 6-card** sequence.
  After clearing a board, the cast celebrates around a held result. **Next level**
  continues only when selected, including after restarting the app.
- An audible shuffle, then a **0.5-second preview of the final positions**.
  Positions stay fixed. Quick Peek gives one additional half-second look, never
  auto-revealing when an ad closes and never changing attempts or accuracy.
- Seven themes, eight characters each. Each visible character is one exact matching
  pair; there are no accessory variants. Unlocked themes rotate, with a mixed cast
  every fifth level. Settings can pin an unlocked theme for subsequent boards.
- Mismatches flip **both** portraits back. Matches trigger delighted expressions,
  +100 feedback, and varied left/right/split departures. Return routes and cheer
  movement vary, accompanied by one of three crowd effects.
- Cumulative score: 100 per pair, plus a level accuracy bonus of up to 20 per pair.
  There is no timer, life limit, or score deduction.
- Automatic saves preserve the level, exact layout, completed pairs, attempts,
  score, collection, earned choices, and preferences.
  Interrupted comparisons return face-down after relaunch.
- **Settings** in the bottom navigation opens Appearance (dark mode and backgrounds),
  Sound & Motion, and the next-board cast. The top pause button, Escape and Android
  Back open the same screen. Back to game / Escape / Android Back returns to play.
- **Settings → Development service lab** retains the simulated and native SDK checks.
  Real-money purchases remain disabled; native ads only use Google's demo IDs.
- Rule, persistence, service, and rendered interaction tests.

Character art uses generated, transparent PNG atlases with normal adult proportions.
Portraits and animated cutouts reuse the same unmodified characters. Animals and
food use their full silhouettes and hop/float motion instead of sliced human legs.
Matched portraits switch to delighted expressions before departing. These are 2D
cutout animations with baked dimensional art, not a Blender model or full 3D rig.

**Collection** is in the bottom navigation. It opens **My collection**, which shows
only owned characters with gold frames, warm backgrounds and animated cheering poses.
**Discover all** lets you browse all characters and filter by theme. Select an
uncollected character, then press **Collect** to spend one earned choice. The
character is saved immediately. Duplicate selections cannot spend choices; a failed
save retains the choice. Finishing a collection preserves extra choices for later.
The result card opens Discover all directly. Tapping an eligible character selection
triggers fireworks and a short jump-and-clap animation. Confirming Collect repeats
the celebration only after the save succeeds. The reaction uses dedicated clapping
poses, stops when hidden or deselected, and respects Reduce motion.
Tapping an owned character plays a short random dance or greeting with sound, without
immediate repeats. Reactions never spend choices or change gameplay. Reduce motion
uses still poses/captions and a fading sparkle; muted sound stays muted. Closing the
collection or backgrounding clears effects and stops its sounds.

Sound includes original short effects, a 1.3-second card riffle, and three crowd
variations derived from two CC0 recordings. **Settings → Sound effects** saves your
choice. Backgrounding stops sounds; restoring a completed result stays silent.
See [asset provenance](docs/asset-credits.md) for art prompts and sound sources.

Older saves retain pair positions, progress, collection and score. Duplicate legacy
variants become distinct unused characters in the same theme. After that board, the
easier sequence begins with four cards. Historical score validation keeps the
correct generation boundaries. There is no runtime AI model, live image generation,
analytics, or production purchase backend. Real-money purchasing stays disabled.

## Test

```bash
./scripts/validate.sh
./scripts/smoke_desktop.sh
# On a machine without a desktop session:
xvfb-run -a ./scripts/smoke_desktop.sh
# Run the desktop smoke first: it exports actual UI positions for Android touch tests.
# Dedicated test emulator only; resets its game progress (not desktop saves):
source scripts/env.sh
python3 scripts/smoke_android.py --reset-test-progress
# With the emulator fixture above: installs the APK and spends one test choice.
python3 scripts/smoke_collection.py
```

The Android screenshot checks require Pillow (`python3-pil` on Debian/Ubuntu).

The visual smoke test drives pointer input in the actual scene and writes
screenshots to `build/screenshots/`. It uses separate test saves and fake ownership,
so your journey is untouched. Completion checks cover the full returning cast,
held results, explicit Next level input, still cheering poses with reduced motion,
centered round score, 16-card touch targets, owned collection animation, sound
gating, and saved preferences. Automated service tests also use a separate fake store. The smoke suite additionally
checks rewarded-ad failure/cancellation/earning, one-use peek timing, paid theme
restrictions, simulated Plus purchasing, and all three new themes at 16-card size.

Game saves live under Godot's user data directory (isolated desktop setup:
`.tools/xdg-data/mem-mem-foundation/progress.0.json` and `progress.1.json`).
Two alternating snapshots allow recovery if one is damaged. Phase 1's old
`demo_round.json` remains untouched; the real journey starts at Level 1.

See [validation results](docs/validation.md), [architecture](docs/architecture.md),
and [store setup](docs/store-setup.md) for the remaining device/store checks.

## Layout

- `game/gameplay/`: seeded boards, matching/scoring rules, progress, save recovery, and people catalog.
- `game/demo/`: game screen, portraits, walking/cheering animations, and lifecycle handling.
- `game/presentation/`: shared visual styles, collection cards, backgrounds, audio and match accents.
- `game/assets/characters/`, `game/assets/audio/`: shipped art and sound assets.
- `game/assets/people/`: archived vector art, excluded from Android export.
- `game/services/`: common interfaces, simulations, and isolated native adapters.
- `game/tests/`: deterministic round and service-scenario checks.
- `scripts/`: pinned downloads, local setup, builds, and validation commands.

Downloaded addons, SDKs, build artifacts, signing keys, and runtime saves are
ignored by Git. Original third-party license notices remain in downloaded packages.
See [dependency notes](docs/dependencies.md).

See [discovery update notes](docs/discovery-update.md) for historical art and migration notes; the current reward rule is perfect accuracy
plus an explicit player choice. [Asset credits](docs/asset-credits.md)
records generation prompts and audio sources.
