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

## Release work outstanding on October 27

No physical Android device/emulator gameplay run, signed AAB release, or Play Console update was performed. Use the existing upload key and a version code greater than every prior upload, test the installed-app upgrade without clearing data, then publish the free edition and align the store listing, ads declarations, products and privacy disclosures.

## Initial release preparation — November 5, 2026

- Confirmed GitHub `main` already contained the free-edition commit `8e660f1`.
- Re-ran validation: four Python tests, asset checks, 105,367 game checks with zero failures, and production scene smoke passed.
- Removed stale billing service references from the store screenshot generator and remaining Plus badge copy. Regenerated and visually inspected all four gameplay screenshots.
- Desktop smoke passed when run separately. An earlier concurrent screenshot/smoke run failed the preview wall-clock timing bound; the isolated run passed without changing that bound.
- At the start of preparation, Play Console production was version 11 (`0.7.0`), whose release notes describe rewarded ads and Plus. The free release had not yet been deployed.
- Deactivated the sole Plus purchase option (`remove_ads` / `buy`) in Play Console; verified **Inactive** and **Your changes have been saved**.
- Recovered the original upload keystore and signing environment from the documented Secret Manager backup without printing credentials. Local signing checks passed.
- Prepared version 12 (`0.8.0`). At this stage, the signed bundle, Android upgrade checks, listing and disclosure updates, and release submission were still pending.

## Signed release validation — November 5, 2026

- Final game source: `64168f2`; version 12 (`0.8.0`). Four Python tests, asset checks, **105,368 Godot checks with zero failures**, and production scene smoke passed.
- Pointer-driven desktop smoke passed in isolation without relaxing its timing assertions, including free Quick Peek and all themes.
- Full API 35 Android emulator gameplay smoke passed: levels 1–10, scoring, collection, settings, offline play, persistence, animation and reduced motion, with no Godot errors or fatal exceptions. The Android smoke script does not exercise Quick Peek. An earlier run encountered a Godot shader-cache read error; the complete rerun passed after the cache was warmed. A startup race in the test was fixed by waiting for the expected persisted state.
- Signed AAB passed bundletool validation. Its manifest requests only vibration; it contains no internet, advertising-ID or billing permissions. APK inspection found no ad, billing or UMP classes. Signature and 16 KB alignment checks passed.
- AAB SHA-256: `6e48846793aaeab833b00a6231af6645b9f48d7d36e96f321cb1755fcc65f0a0`.
- Installed the APK generated from that exact AAB over the upload-key-signed test APK without clearing data. Both save files were byte-identical immediately after installation; after launch, the newest saved payload was unchanged (level 10, 4,180 points, seven choices, collection and settings). Release startup logs contained no Godot errors or fatal exceptions. This verifies the test-build-to-release installation; legacy save migration is covered by the Godot tests rather than an installed 0.7.0 binary.
- Published version 12 to internal testing; Play Console confirms **Available to internal testers**. Play reported no lost supported devices. Its two non-blocking warnings concern optional deobfuscation files and native debug symbols.
- Uploaded the four free-edition screenshots and saved the new listing, no-ads, no-advertising-ID, no-data-collection/sharing, unrestricted-access and privacy-policy declarations for review.
- Public privacy policy: https://vincentaz.github.io/Mem-Mem/privacy-policy.html (published with GitHub Pages and verified against the committed HTML).
- Saved the production release for a 100% rollout to all targeted countries.
- Verified Play app pricing explicitly states the app is free and cannot be changed to paid.

## Production submission — November 5, 2026

- With explicit user approval, accepted the IARC Terms of Use and saved the new questionnaire declaring no digital purchases. The rating summary no longer lists **In-Game Purchases**; it shows ESRB Everyone, PEGI 3 and Brazil All ages.
- Submitted all seven changes together: production version 12 (`0.8.0`) for full rollout, store description, phone screenshots, content rating, privacy-policy URL, ads declaration and Data safety.
- Play Console publishing overview now shows **Changes in review**. Automated quick checks are running, with up to 14 minutes indicated; the page says the changes will be sent for review after those checks complete successfully. This is submission evidence, not review approval or proof that the free edition is publicly live.
- Managed publishing is **off**. Unrestricted sign-in access and the **No** Advertising ID declaration are acknowledged as informational declarations for review.
- Remaining deployment verification: confirm successful quick checks, Google review approval and production availability of version 12 with the updated listing and disclosures.
