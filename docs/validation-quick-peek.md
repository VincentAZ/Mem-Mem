# Easier matching, 56 characters and Quick Peek — 0.6.0

Validated locally on 2026-09-21. This is a **test integration release**: Google test
rewarded ads work on Android; purchasing and restoration are explicitly simulated.
Real-money charging remains disabled.

## Rules, migration and services — passed

`./scripts/validate.sh`: Godot 4.7.2 import/script checks and **88,349 checks**, with
zero failures. Coverage includes:

- Multiple complete difficulty cycles, all theme selections and entitlement pools:
  4, 6, 8, 6, 12, 4, 8, 6, 16, 4, 8, 6 cards; exactly two of each distinct character;
  every hard board immediately followed by four cards; no locked-theme leakage.
- Schema 1–3 saves, partially matched legacy variant pairs, deterministic replacement
  with unused same-theme characters, exact saved positions/progress, original 24
  collection IDs, and score bounds spanning the old/new generator boundaries.
- Snapshot theme pools remain valid when entitlement changes. A previously generated
  paid board remains intact if test ownership is removed; subsequent boards use the
  currently unlocked pool. New collection claims remain entitlement-gated.
- One persisted Peek per board, first-card selection, input locking, repeated taps,
  saved consumption and restart, stale board IDs and duplicate reward callbacks.
  A purchase mid-board cannot replenish a consumed Peek.
- Perfect boards with or without Peek grant one bankable choice. Imperfect boards
  grant none. Purchase/restore never chooses or auto-collects a character.
- Simulated success, cancellation, pending payment, failure and restore; pending
  never grants Plus. Restored Plus suppresses cached/loading ads.
- Rewarded cancellation, no-fill, show failure, and dismissal without reward.
  Native-ad SDK stubs also check request correlation, stale callbacks, cache cleanup,
  duplicate earned events and ad suppression. Only an earned event grants a Peek.

## Desktop interaction and artwork — passed

`xvfb-run -a ./scripts/smoke_desktop.sh` drives the actual scene with pointer and
keyboard input using isolated saves and fake ownership. The full suite passed.

It covers the opening preview and Peek at **0.5 seconds fully face-up**, with flips
excluded; first-selection preservation; input blocking; pause/background handling;
restart; ad failure, cancellation and explicit simulated earning; saved Ready state;
locked-character upgrade access; pending/successful Plus simulations; offline paid
Peek; and all three new themes on 16-card boards and their returning celebrations.

Existing regressions remain covered: both mismatch cards conceal, matches walk away,
results stay until Next level, centered score, explicit collection claims and
fireworks, varied owned-character reactions, dark mode/backgrounds, reduced motion,
mute and sound gates, and failed-save rollback.

All seven eight-character contact sheets were rendered. New characters use shared
transparent neutral/cheer atlases. Phone-sized 16-card screenshots were inspected for
silhouettes, distinct pairs, clipping and room for Quick Peek. Art uses 2D cutouts,
not full 3D rigs. Animal, food and mythical bodies use whole-silhouette hop/float
motion; human figures retain the existing walk animation.

## Android gameplay and native test reward — passed

Dedicated **API 35 Google APIs emulator**, 432×900, density 160, ANGLE/SwiftShader.
No physical phone was connected or tested.

`python3 scripts/smoke_android.py --reset-test-progress` passed the complete run
through level 9 into level 10. It exercised actual touch, mismatches, departure
termination/restart, held completion, repeated Next taps, background/resume, offline
play, collection choices, dark mode/backgrounds, sound preference and reduced motion.
The installed update preserved an existing legacy board and began the easier wave
after it. Both the 12-card and 16-card boards were followed by four cards. The
16-card board had 16 usable touch targets. The fixture ended with 4,180 banked points,
one explicitly collected character and seven saved choices.

The final APK was reinstalled after the catalog metadata cleanup; the paid board,
selected theme, banked choice and consumed Peek survived unchanged, and the three
Plus theme previews rendered correctly. `python3 scripts/smoke_collection.py` also
passed on that final APK: five varied owned-character reactions, background/resume,
selection fireworks without premature ownership, an explicit saved claim, reduced
motion and restart.

Additional actual Android interactions verified:

1. Quick Peek opened a **native Google rewarded test ad** (the SDK's Test Ad label
   was visible). Its earned callback saved `peek_earned=true`, `peek_used=false`.
   Dismissing returned to **Quick Peek · Ready**, with all cards still concealed.
2. Restart retained the earned allowance. Tapping Peek consumed it without changing
   attempts, score or layout. Repeated taps could not grant another reveal.
3. Settings → Mem-Mem Plus → Simulate Plus saved only development ownership.
   Collection, choice credits and the used Peek remained unchanged. No charge occurred.
4. With Wi-Fi and mobile data disabled, restart and the explicit test Restore control
   retained Plus. Snack Squad could be selected for the next board.
5. Finishing the board perfectly after using the ad-earned Peek granted exactly one
   choice and no automatic character. Next level produced eight Snack Squad cards
   with the complete Plus theme pool snapshotted in the save.
6. That new paid board had a usable offline Peek without an ad reward. Consumption
   survived another restart and did not increment attempts.

Native failure/duplicate cases are deterministic SDK-stub and desktop checks; they
are not claims that every Google network outcome was reproduced on the emulator.
Native test-ad success does not validate production AdMob units or production UMP.

Artifacts (ignored build output): `build/tests.log`, `build/desktop-smoke.log`,
`build/android-plus-smoke.log`, `build/android-collection-results.json`,
`build/android-peek-earned.json`, `build/android-plus-peek-results.json`,
`build/android-native-peek-runtime.log`, `build/android-plus-peek-runtime.log`,
`build/android-final-collection.log`, `build/android-reactions-results.json`,
and `build/screenshots/{smoke-,character-pack-,android-}*.png`.
No Godot script errors or Android fatal exceptions were observed in the successful
Android runs. The dedicated emulator's temporary purchase fixture is restored after
focused testing; desktop/player save files are not touched by these tests.

## APK

`build/mem-mem-debug.apk`: **0.6.0-quick-peek**, version code **9**.
Export, signing verification, native-plugin inclusion and 16 KB ZIP/native ELF
alignment checks pass. Arm64-v8a and x86_64; minimum Android 8 / API 26.

SHA-256: 2878098eade3056d5f4c7751b19129db9d6937e130558a21ba81aca9bb3da783.

## Still pending

- Physical-phone readability at 16 cards, touch feel, animation smoothness,
  battery/thermal behavior and listening/volume feedback. Emulator output was muted;
  automated playback checks do not establish perceived sound quality.
- Player feedback on engagement and the easier difficulty rhythm. Automated checks
  cannot establish retention or sales conversion.
- Play Console/AdMob accounts, license testers, localized product queries, verified
  purchase processing/acknowledgement, refunds/revocation, genuine purchases and
  restoration, production UMP messages and production advertising. Simulations do
  not count as live validation. See [store setup](store-setup.md).

The previous collection-reaction release is archived in
[validation-reactions.md](validation-reactions.md).
