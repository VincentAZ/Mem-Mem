> Historical 0.4.0 notes: the automatic three-board surprise reward described below
> was removed in 0.5.1. Only perfect accuracy earns a choice, and only the player
> selects and collects a character. Existing ownership is preserved.

# Discovery update — 0.4.0

This iteration addresses the desktop feedback: repetitive cast, plain art, limited
comparison details, stiff animation, missing crowd sound, and a weak reason to
continue. It implements a testable collection loop rather than assuming visual
polish alone will make the game engaging.

## What the player gets

- 24 collectable themed characters across Everyday People, Firefighters, Aliens,
  and Golden Years. Each has two visual comparison variants: 48 matching identities.
  The catalog includes adult women and men, older women, and alien explorers.
- Themes rotate every board. Every fifth board mixes the full cast. Pause offers
  a preferred cast that applies to the next board, without moving current cards.
- The shuffle lasts about one second and has an audible card-riffle texture. It
  now happens **before** the 0.5-second preview. That preview shows the real final
  positions, making a perfect board possible through memory rather than blind luck.
- Matched portraits switch to delighted, surprised smiles before departure.
  Textured figures have continuous gait, sway and bounce, varied exit/entry sides,
  split entrances/departures, and different raised-arm, wave, and applause poses.
  These are baked 2D cutouts, not full 3D rigs; motion quality is still a playtest topic.
- Three crowd effects vary without consecutive repeats. All sound obeys the saved
  mute setting and pauses/backgrounding; restored results remain silent.
- **Score this round** appears between pair count and accuracy. Total score stays
  in its existing header. The result remains until **Next level** is pressed.
- Dark mode plus Paper, Botanical, Twilight, and Orbit backgrounds. All preferences
  are saved, including the next-board cast. Collection and settings remain readable
  in both light and dark mode.

## Collection rules

A cleared board with **100% accuracy** earns **one choice of any uncollected
character from any of the four themes**. The character need not have appeared on
that board. Select a card in Collection, then press Collect. Earned choices can be
banked indefinitely by continuing instead; closing/reopening the app does not lose
them. There are no duplicate charges, time limits, ads, or purchases in this reward.

Every **three cleared boards** also grants a surprise uncollected character. A
mismatch still progresses toward this discovery. A perfect third board earns both
the surprise and its free choice. Collection filters show each theme's completion.
All 24 collected means no duplicate surprise is added, and extra perfect choices
remain saved for future additions. This is one collectible per named themed
character, not separate ownership for each accessory variant.

The saved reward-level marker settles each board once, including a completion
restored after process death. Claiming writes the new ownership and consumed
choice together. If a write fails, both roll back and the choice remains available.
Current-round transient selections are retained during that rollback.

## Save compatibility

Schema 1 saves migrate to schema 2 without changing level, exact positions,
removed pairs, attempts, score, or earlier settings. Their current board retains
legacy generation. Subsequent boards use the themed generator. New collection and
appearance fields receive defaults; previous historical levels do not award
retroactive characters. A currently completed result can earn its new reward.

## Art and audio

Eight transparent atlases (four neutral, four celebrating) were generated with the
built-in image-generation tool and copied unchanged into `game/assets/characters/`.
Portraits and walking figures share them. Comparison details use deterministic
shape overlays, so paired variants share identical underlying art. The old vector
people are retained as an archive and excluded from the APK.

See [asset credits](asset-credits.md) for the recording sources and full prompt
record. No runtime AI, Blender installation, cloud image calls, or extra SDK is
needed to play. The existing native billing/ads boundaries remain unchanged.

## What the next playtest should answer

Does the actual-position peek make perfect accuracy feel attainable? Does choosing
a character make another board appealing? Is a surprise every three boards too
frequent or too slow? Are the four casts and comparison details enjoyable and clear?
Do the new smiles, movement, and crowd effects feel satisfying after several boards?

The visual direction is intentionally much more dimensional and adult than the
previous vector pass. It still needs your judgment; this implementation does not
prove retention or enjoyment. Phone readability, audible sound balance, vibration,
frame pacing, battery/thermal behavior, and ARM64 runtime remain physical-device work.
Sharing, production purchases, and a much larger theme library remain future work.
