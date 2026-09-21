# Mem-Mem — matching game

A Godot 4.7.2 / GDScript Android portrait-matching game.
The collection update adds a redesigned HUD, animated owned characters and levels
up to 16 cards. There are 24 collectable characters across Everyday People,
Firefighters, Aliens, and Golden Years. Matched characters react and leave together;
the full cast returns to celebrate. Dark mode and four backgrounds are available.

**Perfect accuracy earns one choice of any uncollected character across all themes.**
Every three cleared boards also discovers a surprise character. Choices can be
saved for later and persist across restarts. No purchase is required.

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

- A repeating 6, 8, 8, 12, 8, 6, 12, 16, 8, 12, 16, 8-card difficulty wave.
  New journeys first reach a 4×4 board at level 8; level 11 adds more lookalike pairs. After clearing a board,
  every character returns and cheers around the result card. **Next level** continues
  only when you choose; results also remain after restarting the app.
- A longer audible shuffle, then a **0.5-second preview of the actual final positions**,
  then cards turn down. Positions stay fixed for the whole board, so memory can earn perfection.
- Four themes, six collectable characters each, and two comparison variants per
  character: 48 matching identities. Glasses, scarf patterns, brooches, insignia,
  ties, and hair ornaments provide more varied lookalike details. Themes rotate;
  every fifth board mixes the cast. Settings can pin a theme for subsequent boards.
- Mismatches flip **both** portraits back. Matches trigger delighted expressions,
  +100 feedback, and varied left/right/split departures. Return routes and cheer
  movement vary, accompanied by one of three crowd effects.
- Cumulative score: 100 per pair, plus a level accuracy bonus of up to 20 per pair.
  There is no timer, life limit, or score deduction.
- Automatic saves preserve the level, exact layout, completed pairs, attempts,
  score, collection, earned choices, discovery progress, and preferences.
  Interrupted comparisons return face-down after relaunch.
- **Settings** in the bottom navigation opens Appearance (dark mode and backgrounds),
  Sound & Motion, and the next-board cast. The top pause button, Escape and Android
  Back open the same screen. Back to game / Escape / Android Back returns to play.
- **Settings → Development service lab** retains the simulated and native SDK checks.
  Real-money purchases remain disabled; native ads only use Google's demo IDs.
- Rule, persistence, service, and rendered interaction tests.

Character art uses generated, transparent PNG atlases with normal adult proportions.
Portraits and animated cutouts reuse the same characters. Deterministic accessory
overlays keep comparison variants identical except for their intended detail.
Matched portraits switch to delighted expressions before departing. These are 2D
cutout animations with baked dimensional art, not a Blender model or full 3D rig.

**Collection** is in the bottom navigation. It opens **My collection**, which shows
only owned characters with gold frames, warm backgrounds and animated cheering poses.
**Discover all** lets you browse all characters and filter by theme. Select an
uncollected character, then press **Collect** to spend one earned choice. The
character is saved immediately. Duplicate selections cannot spend choices; a failed
save retains the choice. Finishing a collection preserves extra choices for later.
The result card opens Discover all directly. Reduce motion keeps collection poses
still; hidden, offscreen and backgrounded collection animations stop.

Sound includes original short effects, a 1.3-second card riffle, and three crowd
variations derived from two CC0 recordings. **Settings → Sound effects** saves your
choice. Backgrounding stops sounds; restoring a completed result stays silent.
See [asset provenance](docs/asset-credits.md) for art prompts and sound sources.

Older saves retain their exact board and score. After that board, the new generator
uses the expanded difficulty wave. Saved scores retain the correct bounds for both
the old and new progression. There is no runtime AI model, live image generation,
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
```

The Android screenshot checks require Pillow (`python3-pil` on Debian/Ubuntu).

The visual smoke test drives pointer input in the actual scene and writes
screenshots to `build/screenshots/`. It uses separate test saves and fake ownership,
so your journey is untouched. Completion checks cover the full returning cast,
held results, explicit Next level input, still cheering poses with reduced motion,
centered round score, 16-card touch targets, owned collection animation, sound
gating, and saved preferences. Automated service tests also use a separate fake store.

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

See [discovery update notes](docs/discovery-update.md) for reward rules, migration,
art direction, and remaining phone review; [asset credits](docs/asset-credits.md)
records generation prompts and audio sources.
