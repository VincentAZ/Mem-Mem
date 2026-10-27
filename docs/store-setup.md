# Build and publish the free edition

The app has no ads, billing products, receipt service, or advertising consent setup. All features work offline.

Run `scripts/setup.sh` first. Copy `docs/store-config.example.json` to `.tools/store/config.json` and choose a version code higher than every previous Play upload. Configure these environment variables using your own secure local method:

- `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`: existing upload keystore path
- `GODOT_ANDROID_KEYSTORE_RELEASE_USER`: upload key alias
- `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`: keystore password

Never commit the keystore, credentials, or local configuration.

```bash
./scripts/build_store.sh .tools/store/config.json --check
./scripts/build_store.sh .tools/store/config.json
```

The script stages a clean isolated game project without cached addons, exports the signed AAB, verifies its signature, and writes a SHA-256 file. Test it through a Play internal track before production.

In Play Console, publish with no download charge, no ads, and no in-app purchases. Retire obsolete Plus products, update the listing and data-safety answers to reflect the final binary, and provide the current privacy policy. Changing source code does not publish a store update or change Console pricing.
