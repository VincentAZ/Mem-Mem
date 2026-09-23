# Google Play listing assets

Prepared September 23, 2026. These files have been visually inspected and pass
the dimensions and file-size limits shown in Console. All six files are now
uploaded and saved in the English (US) listing, whose status is **Ready to send
for review**. The screenshots are ordered 01, 02, 03, 04. The feature graphic and
four screenshots have per-asset AI labels because they contain generated character
artwork; the vector monogram icon is unlabeled. No review submission was made.

- `icon.png`: 512×512; the existing SVG monogram on an opaque square background.
  Google Play supplies its own icon mask.
- `feature-graphic.png`: 1024×500; composed in Godot from the existing palette,
  typography and `PortraitTile` renderer. Existing character artwork is unchanged.
- `01-match-pairs.png`: 1080×1920; opening board preview.
- `02-find-a-match.png`: 1080×1920; matched pair after the score animation settles.
- `03-discover-characters.png`: 1080×1920; character browsing after earning a choice.
- `04-dark-mode.png`: 1080×1920; next-board preview in dark mode.

The screenshots are captures of the current game scene rendered by the desktop
Godot engine at a 9:16 portrait viewport, with production UI selected, rather
than photographs or mockups. The capture plays a real first round and earns its
collection choice. No production credentials, simulated purchase controls, or
unearned Plus access are shown. These captures do not validate Android billing,
ads, UMP, or final device rendering. Spot-check the signed Android build before
sending the listing for review.

The generator lives outside `game/`, so it is not shipped in the app. It uses
an isolated data directory, unique progress prefix, and separate receipt/identity
paths. It does not touch existing player or smoke-test saves.

From the repository root:

```bash
source scripts/env.sh
export XDG_DATA_HOME="$MEMMEM_ROOT/.tools/store-capture-data"
xvfb-run -a -s '-screen 0 1200x2100x24' "$GODOT" \
  --path game --audio-driver Dummy --script ../scripts/capture_store_assets.gd
```

The last successful capture log is `build/store-assets-capture.log`. Existing
art provenance is in `docs/asset-credits.md`.
