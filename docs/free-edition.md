# Free edition — October 27, 2026

Every shipped feature is free. All seven themes are available, and every board includes one offline Quick Peek. Characters remain earned through perfect boards and explicit choices.

The runtime no longer contains billing, advertising, consent, simulated commerce, access-code entry, receipt checks, or a purchase server. Android exports disable internet and network-state permissions. Setup removes cached ad/billing plugins from older working copies so they cannot leak into a fresh build.

Existing gameplay snapshots keep their schema and contents. A saved board, score, collected character, preference, or consumed Quick Peek is not reset. Old earned-peek fields remain readable for compatibility but no longer control access. A new board includes a new Peek.

## Release checklist

1. Run `./scripts/validate.sh` and the desktop/device smoke checks.
2. Build the signed AAB with a version code higher than every previous Play upload.
3. Verify the final APK/AAB manifest and dependency contents contain no advertising or billing SDKs or permissions. `scripts/check_apk.py` audits the APK.
4. Test upgrading an installed copy without clearing its app data, including saved boards and former Plus themes.
5. Upload to Play Console, set the listing as free, remove obsolete in-app products and ads declarations where applicable, and update the privacy/data-safety/store copy. Existing published binaries are unchanged until a new release is distributed.

`docs/store-setup.md`, `docs/privacy-policy.md`, `docs/data-safety.md`, and `docs/store-listing.md` describe the free edition. Other milestone/setup records that describe Plus, purchases, or advertising are historical; do not follow their monetization instructions.

Local results are recorded in [Free edition validation](free-edition-validation.md).
