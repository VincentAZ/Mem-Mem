# Phase 3: character, animation, sound, and voice pass

The game now has an original six-person illustration pack with twelve matching
identities, refined walking/cheering figures, match accents, six short sound
effects, and straightforward playful copy. This is an implemented art direction
for review in the game; physical-phone tuning and user feedback remain pending.

## People and movement

Each adult has a distinct hairstyle, facial details, outfit, and color palette.
Lookalike variants share the exact base drawing and differ only in hoop versus
pearl earrings. There are no unrelated facial changes between a family's variants.
Adult portrait crops and normal full-body proportions avoid oversized mascot heads.
The head, glasses, hair, and accessory follow each person from tile to walking
figure, then back into the completion lineup. Existing identity numbers stay stable.

Walking has articulated knees/elbows, shoes, and a contact shadow. The returning
cast uses staggered timing and individual one-arm/two-arm cheer poses. A brief match
spark complements the points and sound. Reduced motion keeps still cheering poses,
omits spatial effects, and settles an interrupted card flip immediately.

The 0.5-second preview, both cards flipping back on mismatch, fixed positions,
scoring, all-character return, held result card, and explicit Next level remain.
Sharing remains deferred.

## Sound

Original mallet/wood-like effects accompany a reveal, shuffle, match, mismatch,
completed board, and Next level. Every cue is under 0.8 seconds. The mismatch uses
a short low tone rather than an alarm; there is no looping soundtrack. Effects are
stored as mono 44.1 kHz PCM WAVs with short attack/release envelopes and no clipping.

Pause → Sound effects mutes immediately and persists across levels and restarts.
Audio stops on pause, backgrounding, or a development overlay. A restored completed
board stays silent, and ignored taps never create audio. A bounded pool prevents
unlimited overlapping sounds. Previous saves default sound on without changing
the player's board, score, or other settings.

Waveform checks and playback/gating tests pass locally. Speaker/headphone balance,
perceived loudness, device audio routing, and interruption behavior still require
listening on a physical Android phone. The emulator runs with host audio disabled.

## Copy direction

Use concise, adult, game-focused language. Friendly is good; constant reassurance
is unnecessary. Avoid therapy language, repeated diminutives, and praise for every
ordinary tap. Also avoid pressure, guilt, and aggressive failure messages.

- Opening: “Meet the lineup…” and “Shuffling…”
- Match: “Match! +100”
- Mismatch: “Not a match. Try another pair.”
- Result: “Board cleared!” or “Perfect match!” for 100% accuracy
- Pause: “Paused” and “Resume”
- Wave titles: “Meet your matches,” “New faces,” “Spot the difference,”
  “Double take,” “In the groove,” and “Quick match”

## Asset provenance and editing

All Phase 3 art and sound are original project-authored assets. SVGs extend the
existing vector direction; no stock assets, image-generation service, downloaded
fonts, music samples, or additional runtime dependencies were used.

- Art source: `scripts/generate_people.py`; output: `game/assets/people/`.
  Both portrait and head files use the same drawing function. SVG imports use
  three times the design resolution for dense phone displays.
- Audio source: `scripts/generate_audio.py`; output: `game/assets/audio/`.
  Synthesis uses only Python's standard library. WAV assets are checked in.
- Runtime: `game/demo/portrait_tile.gd`, `game/demo/walker.gd`,
  `game/presentation/game_audio.gd`, and `game/presentation/match_spark.gd`.

Regenerate and validate after editing their source:

```bash
python3 scripts/generate_people.py
python3 scripts/generate_audio.py
./scripts/validate.sh
```

Validation verifies generated assets against their sources before Godot checks.
To render the complete pack without touching saves or services:

```bash
source scripts/env.sh
xvfb-run -a "$GODOT" --path game --script tests/art_review.gd
```

The contact sheet is `build/screenshots/people-pack.png`. Tests and review tools
are excluded from the Android export. The shipped game has no runtime AI model.

## Next review on a phone

Install the new debug APK over the existing app to retain progress. Spend a few
minutes on the six- and twelve-card boards. Check the hoop/pearl difference at
normal viewing distance, thumb reach, animation smoothness, effect volume, and
vibration strength. Try sound off, reduced motion, background/resume, and headphones.
This pass should guide the next adjustment before expanding into collections and
unlockable character packs. Longer sessions and device performance/battery tests
remain separate work; emulator success does not establish retention or enjoyment.
