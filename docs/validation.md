# Collection reward correction — 0.5.1

The automatic every-third-board surprise reward has been removed. Only exact
100% accuracy earns one saved choice. Completing a board never adds a character;
the player must select one and confirm Collect. Existing collection ownership,
saved choices, board layouts and points are preserved.

Retired discovery fields remain readable for compatibility with schema 2/3 saves,
but they cannot grant ownership and no longer appear in result or collection copy.

## Validation

`./scripts/validate.sh`: **14,064 checks, zero failures**, including:

- Six consecutive boards at exactly 50% accuracy never earn choices or characters,
  even when an old save is one board away from the retired surprise threshold.
- Perfect completion grants one choice and leaves ownership unchanged.
- Advancing, saving and restarting preserve unclaimed choices without auto-selection.
- Only the player's explicit valid selection adds the chosen character.
- Old surprise metadata still loads without deleting existing characters or boards.
- Completion/reload idempotency, scoring, save recovery, 16-card generation and
  service simulations continue to pass.

`xvfb-run -a ./scripts/smoke_desktop.sh`: passed. The rendered test reproduces a
six-pair board at 50% accuracy with the retired surprise counter at its old threshold.
It verifies zero collection awards, no misleading reward message, and saved ownership
remaining unchanged. Perfect-choice selection, collection animations, 16-card play,
settings, sound and lifecycle checks also passed.

`python3 scripts/smoke_android.py --reset-test-progress`: passed on the isolated
API 35 emulator. Real touch input made three mismatches and three matches on the
first board (exactly 50%), then verified no character or choice after a restart.
The second board earned a perfect choice; the test selected Maya and confirmed
Collect. After clearing levels 1–8, the state held **4,530 banked points**, **6 saved
choices**, and **only Maya collected**. No automatic characters appeared on the
third or sixth boards. Collection animation, Reduce motion, appearance, offline
restart and pause/resume passed; no Godot or Android runtime errors were recorded.

Artifacts: `build/tests.log`, `build/desktop-smoke.log`,
`build/android-collection-results.json`, `build/android-collection-runtime.log`,
and screenshots under `build/screenshots/`. Desktop tests use isolated saves;
Android resets only the dedicated emulator's game progress. Player desktop and
physical-phone saves were not changed.

## APK

`build/mem-mem-debug.apk`: **0.5.1-choice-only**, version code **7**, about 171.3 MiB.
Godot export, signature verification, native-plugin inclusion and 16 KB ZIP/ELF
alignment checks passed.

SHA-256: `ca0d6a02602d4b435e935b278bb068b0be104f754ab4e52c0668b3600cfbcb98`.

Physical-phone feedback and live store/consent/advertising account validation remain
pending. Real-money purchasing remains disabled. See [store setup](store-setup.md).
Earlier layout and collection validation is archived in
[validation-collection.md](validation-collection.md).
