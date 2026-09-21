Historical foundation record. The APK and current results are superseded by
[Phase 2 validation](validation.md).

# Phase 1 validation record

Validated locally on 2026-09-20. The local Android foundation is implemented.
Live store/account integration remains pending.

Follow-up: the opening preview is now 0.5 seconds in the project. Import checks,
all 4,236 assertions, and the desktop animation smoke passed again after this
change. The previously generated APK still contains the original preview timing;
run `scripts/build_android.sh` to include this update. The user's own testing so
far used `scripts/run.sh` on desktop, not a physical Android device.

## Build and automated checks

- Godot 4.7.2 import and GDScript checks passed.
- `scripts/validate.sh`: **4,236 assertions, zero failures**. This includes 200
  seeded boards, mismatch/selection rules, round snapshots, billing outcomes,
  ad/consent failures, restored ownership, asynchronous suppression, and native
  ad-cache cleanup regressions. The count is assertions, not unique test cases.
- Desktop scene smoke passed: preview, shuffle, flip, pair resolution, and walking
  departure. Screenshots were visually inspected.
- Android Gradle debug export passed with both pinned native plugins included.
  The project used isolated Temurin 17.0.20.1+1; system Java 25.0.4 remains installed.
- APK signature verification passed (v2). ZIP alignment and every packaged native
  library's ELF load-segment alignment passed the 16 KB checks. This is a binary
  compatibility check, not a runtime test on a 16 KB-page device.
- APK content inspection confirmed GodotGooglePlayBilling, AdmobPlugin, Google
  Billing, and Google Mobile Ads classes, plus arm64-v8a and x86_64 engine libraries.
- Python compilation and shell syntax checks passed.

Artifact: `build/mem-mem-debug.apk`, approximately 161 MiB, package
`io.github.vincentaz.memmem`, Android API 26 minimum / 36 target. It is a debug
prototype containing two CPU architectures; this size is not a release-size target.
The corresponding SHA-256 is written to `build/mem-mem-debug.apk.sha256`.

## Android emulator checks

Environment: Google APIs API 35 x86_64, KVM acceleration, ANGLE/SwiftShader,
432 × 900 portrait display. No physical Android phone was connected.

- APK installation and launch passed. The six-tile scene renders correctly.
- Actual ADB touch input revealed two different portraits; both flipped back.
  A matching pair produced two walking figures and removed exactly those tiles.
- Background/resume preserved the shuffled positions and matched pair.
  Force-stop/relaunch also restored the same saved round.
- With emulator Wi-Fi and mobile data disabled, launch, preview, shuffle, and
  touch matching passed. Backgrounding during departure and resuming preserved
  the same layout and exactly the two matched tiles. Network settings were restored.
- Simulated pending payment left ownership unset. Restoring a fake account
  purchase suppressed both fake ads and native demo ads. These are simulation
  checks, not evidence of Play purchase or restoration behavior.
- Native billing returned an unavailable-service response on this image;
  gameplay remained usable. The real-purchase action reported disabled.
- The native AdMob SDK loaded and displayed Google's clearly labeled test
  interstitial using the demo application and ad-unit IDs. Tapping its close
  control returned to the app and emitted the native dismissal callback.
- Native UMP returned `NOT_REQUIRED` for the demo app in this environment. No
  required consent form or configured-account consent flow has been validated.

The legacy `swiftshader_indirect` emulator renderer initially exceeded a GLES
shader uniform limit and displayed only the background. Switching the emulator
to `swangle` resolved this without changing the Compatibility renderer in the app.
That configuration is now recorded in `scripts/emulator.sh`.
An ad-cache cleanup error found during native testing was fixed and covered by
regression assertions. The final native test log contains no GDScript errors or
Android fatal exceptions.

## Evidence and reproduction

Run the commands in the [README](../README.md). Generated evidence is deliberately
excluded from version control:

- `build/import.log`, `build/tests.log`, `build/desktop-smoke.log`
- `build/android-build.log`, `build/apk-content.json`, `build/apk-alignment.log`
- `build/android-runtime.log`, `build/android-native.log`
- `build/android-smoke-results.json`: offline/lifecycle snapshot assertions
- `build/screenshots/`: desktop preview/board/lab and Android mismatch,
  walking, resumed/restarted, pending/restored ownership, and Google demo-ad captures.

For device checks, install the APK, tap **Meet the faces again**, wait for the
preview/shuffle, then compare pairs. Use **Lab** for service scenarios. Its fake
ownership reset affects only the development simulation. Reproduce the remaining
manual checks using the [device checklist](store-setup.md#device-checks).

## Explicitly pending

- Physical-device readability, touch accuracy, frame pacing, thermal/battery
  behavior, ARM64 runtime, and Android-version/device-size coverage.
- Runtime on a device using 16 KB memory pages; artifact alignment alone is
  insufficient to certify every SDK's runtime behavior.
- Play Console application setup, signing/upload, internal testing, license
  testers, and a permanent `remove_ads` product.
- Real purchase processing, server verification/acknowledgment, pending payment,
  cancellation, refund/revocation, and restoration across reinstall/devices.
  The current native adapter cannot initiate charges or grant real ownership.
- AdMob account/ad-unit setup, required UMP privacy messages and privacy options,
  test geography, and production consent/advertising behavior.

Follow [store setup](store-setup.md) before attempting live integration. Simulations,
native SDK availability, and a Google demo ad do not satisfy that completion boundary.
