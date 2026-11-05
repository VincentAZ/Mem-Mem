# Free edition validation — October 27, 2026

## Completed checks

- Python store-build tests: **4 passed**; signing/version validation remains while ads, billing, verifier URLs and receipt keys are no longer required.
- Godot rule/save/catalog tests: **105,367 checks, zero failures**. Legacy boards, earned choices, collected characters and consumed peeks retain their semantics.
- Scene smoke: **passed**. All 56 characters are browsable without locks; settings contain no purchase, restore, ad or service-lab controls.
- Rendered pointer-driven desktop smoke under Xvfb/software OpenGL: **passed**, including free Quick Peek, Woodland/Snack/Mythical themes, collection claims, motion, lifecycle, settings and persistence.
- Staged Android debug APK: **built** for arm64-v8a and x86_64. The local build used Gradle 8.13 after the template's 8.11.1 cache repeatedly failed to read generated workspace metadata; the repository's pinned Godot template was unchanged.
- `scripts/check_apk.py`: **passed**. No ad, billing or UMP plugin classes; both Godot ABIs present; native load segments satisfy 16 KB alignment.
- Merged manifest: **only vibration permission**, with no internet, network-state, advertising-ID or billing permission.
- README local links and image paths resolve.
- Current files and 357 historical text blobs: no matches for the checked common API-token/private-key patterns and no tracked signing credential files. This focused pattern check is not an exhaustive security audit.

Godot's rule-test process reports resource-cleanup warnings on exit after all checks pass. The rendered desktop run used the dummy audio fallback because the build environment has no audio device; sound event and persistence checks passed.

## Remaining release work

No physical Android device/emulator gameplay run, signed AAB release, or Play Console update was performed. Use the existing upload key and a version code greater than every prior upload, test the installed-app upgrade without clearing data, then publish the free edition and align the store listing, ads declarations, products and privacy disclosures.

## Release preparation — November 5, 2026

- Confirmed GitHub `main` already contained the free-edition commit `8e660f1`.
- Re-ran validation: four Python tests, asset checks, 105,367 game checks with zero failures, and production scene smoke passed.
- Removed stale billing service references from the store screenshot generator and remaining Plus badge copy. Regenerated and visually inspected all four gameplay screenshots.
- Desktop smoke passed when run separately. An earlier concurrent screenshot/smoke run failed the preview wall-clock timing bound; the isolated run passed without changing that bound.
- Play Console production remains version 11 (`0.7.0`), whose release notes describe rewarded ads and Plus. The free release is not yet deployed.
- Deactivated the sole Plus purchase option (`remove_ads` / `buy`) in Play Console; verified **Inactive** and **Your changes have been saved**.
- Recovered the original upload keystore and signing environment from the documented Secret Manager backup without printing credentials. Local signing checks passed.
- Prepared version 12 (`0.8.0`). Signed bundle, Android upgrade checks, listing and disclosure updates, and release submission remain pending.
