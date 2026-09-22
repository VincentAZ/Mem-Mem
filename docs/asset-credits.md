# Asset provenance

## Character artwork

The twenty-four PNG atlases in `game/assets/characters/` were generated for Mem-Mem using
the built-in `image_gen` tool and the imagegen skill. No user API key or CLI fallback
was used. The original output files were copied unchanged, retaining their alpha.
They are baked images; the game performs no inference and does not call a service.

Each of the seven themes now has eight full-body neutral figures and corresponding
delighted/cheering figures. The original four sheets retain six each; the cast-expansion
sheet adds two per original theme. Atlas regions are recorded in `game/presentation/atlas_regions.gd`.
Portraits crop the shared art. Matching accessory overlays were removed in 0.6.0.
Eight additional `*-clap.png` atlases provide a clapping pose for each of the 56
characters. They were generated from the corresponding cheering sheets with the
built-in image tool, copied unchanged with transparency, and are used only for
collection selection/claim reactions. Prompts and source paths are in the
`clapping_assets` section of the prompt record. `ClapAtlas` stores their measured
bounds; `scripts/measure_character_atlases.py --clap --check` verifies them.

New atlas bounds are measured without editing the PNGs by
`scripts/measure_character_atlases.py`; results are in `ExpandedAtlas`. Named variants are fictional game characters.

Full prompt set, reference-image provenance, and saved source paths:
[`character-art-prompts.json`](character-art-prompts.json).

Runtime assets: `people.png`, `firefighters.png`, `aliens.png`, `golden.png`, and each
corresponding `-cheer.png`, plus `cast-expansion`, `woodland`, `snacks`, and `mythical`
with both pose files, all under `game/assets/characters/`. Previous original
vector artwork remains under `game/assets/people/` as an unshipped archive.

## Crowd recordings

- **Cheers**, Nocturnal_Vanguard / AuraVoice: [author's asset page](https://opengameart.org/content/cheers-0),
  [original OGG](https://opengameart.org/sites/default/files/cheers_1.ogg).
  The author distributes it under CC0. `crowd-1.ogg` is shortened/faded and normalized;
  `crowd-3.ogg` starts later and has a small pitch/rate variation.
- **Applause in a large hall or church**, eXpl0it3r:
  [author's asset page](https://opengameart.org/content/applause-in-a-large-hall-or-church),
  [original WAV](https://opengameart.org/sites/default/files/applause-clapping-church-crowd-immersive.wav).
  Distributed under CC0. `crowd-2.ogg` is a short faded, normalized excerpt beginning
  two seconds into the recording.

License reference: [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).
Source/licensing pages were checked on 2026-09-20. Local originals are in ignored
`.tools/audio-source/`. The three shipped OGG files live in `game/assets/audio/`.
They play at the game's existing effect level and have no consecutive repeats.

Editing used FFmpeg: mono, 44.1 kHz, short fades, loudness target -23 LUFS and true
peak target -5 dB. Exact regeneration commands are in `scripts/prepare_crowd_audio.sh`.
Host/emulator audio output was disabled during automated checks; perceived volume
and mixing still need listening on a phone.

## Original effects

Reveal, mismatch, match, completion, next-level tones, the longer card-riffle,
and collection fireworks/dance/wave sounds are project-authored synthesis from `scripts/generate_audio.py`. It uses only
Python's standard library and no sampled recording. Run with `--check` to verify
checked-in WAVs against the generator. Regeneration does not replace the crowd OGGs.
