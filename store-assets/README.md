# Google Play listing assets

Refreshed November 5, 2026 from the free edition. These local assets are ready
for the next Play listing update; they have not yet been uploaded. The screenshots
are ordered 01, 02, 03, 04. Character artwork provenance is unchanged.

- `icon.png`: 512×512; the existing SVG monogram on an opaque square background.
  Google Play supplies its own icon mask.
- `feature-graphic.png`: 1024×500; composed in Godot from the existing palette,
  typography and `PortraitTile` renderer. Existing character artwork is unchanged.
- `01-match-pairs.png`: 1080×1920; opening board preview.
- `02-find-a-match.png`: 1080×1920; matched pair after the score animation settles.
- `03-discover-characters.png`: 1080×1920; character browsing after earning a choice.
- `04-dark-mode.png`: 1080×1920; next-board preview in dark mode.

The screenshots capture the real game scene rendered by the desktop Godot engine
at a 9:16 portrait viewport. The capture plays a first round and earns its
collection choice. All themes and Quick Peek are free; no billing or advertising
setup is used. Spot-check the signed Android build before release.

The generator lives outside `game/`, so it is not shipped in the app. It uses
an isolated data directory and unique progress prefix, preserving player saves.

From the repository root:

```bash
source scripts/env.sh
export XDG_DATA_HOME="$MEMMEM_ROOT/.tools/store-capture-data"
xvfb-run -a -s '-screen 0 1200x2100x24' "$GODOT" \
  --path game --audio-driver Dummy --script ../scripts/capture_store_assets.gd
```

The last successful capture log is `build/store-assets-capture.log`. Existing
art provenance is in `docs/asset-credits.md`.
