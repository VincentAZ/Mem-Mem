# Mem-Mem verification service

Deployed September 23, 2026 in the separate **Mem-Mem** Google Cloud project
`mem-mem-509517`, as requested by the owner.
Existing unrelated projects were not modified. The project uses the existing
organization billing account.

- Cloud Run service: `mem-mem-verifier`, region `us-central1`.
- Origin: the service's Cloud Run HTTPS URL, recorded as `verification_url` in
  the ignored store configuration.
- Purchase endpoint: `/v1/play/verify`; reusable-code endpoint: `/v1/access/redeem`.
- Liveness: `/health`. Avoid `/healthz`: Cloud Run reserves some paths ending in
  `z` ([known issues](https://docs.cloud.google.com/run/docs/known-issues#reserved-url-paths)).
- Runtime identity: `mem-mem-verifier@mem-mem-509517.iam.gserviceaccount.com`.
  Play Console shows it Active, with access only to Mem-Mem: required read access,
  View financial data, and Manage orders and subscriptions. No release permissions.
- Receipt private key: Secret Manager `mem-mem-receipt-key`, version 1, mounted at
  `/secrets/receipt/key.pem`. Only this secret grants the runtime identity access.
  No downloaded service-account key is used.
- Artifact Registry repository: `us-central1-docker.pkg.dev/mem-mem-509517/mem-mem`.
  Current image tag: `verifier:20260923-health`; revision
  `mem-mem-verifier-00002-lhr` serves all traffic.
- Runtime: 1 CPU, 256 MiB, concurrency 16, 30-second timeout, CPU throttling,
  minimum zero and maximum two instances at service and revision levels.
- Monthly project-only budget: USD 20, alerts at 50%, 90%, and 100%, delivered to
  billing account recipients. Alerts are not a spending cap.
- Cloud Logging `_Default` retention: 30 days. Request logs can include IP address,
  timestamp, endpoint and response status. Application logging excludes request
  bodies, access codes and purchase tokens. No purchase/redemption database.

Live HTTPS validation passed: liveness, reusable-code redemption, RSA signature,
installation and nonce binding, seven-day expiry, invalid-code 403 and malformed
request 400. Eleven server tests pass. These checks do not establish successful
Google Play purchases, acknowledgement or refunds; test those through Play.

The signed bundle `build/mem-mem-store.aab` is version 0.7.0 (11), SHA-256
`6b23cf824227516a4bd7be765d93c971f6a37f3dc4a2373609a90c7d1a1f3964`.
Play accepted it and the internal track is active as of September 23, 11:18 AM
(Console time), with the release available to internal testers. The bundle signature passed;
bundletool 1.18.3 generated the emulator APK from that same artifact. Emulator
screenshots are in `build/screenshots/store-android-*.png`. The prior dedicated
emulator's test files were backed up to `build/emulator-pre-store-files.tar` before
installing the differently signed release. No physical-device app was changed.

The local store configuration now points to the deployed purchase endpoint.
Cloud SDK credentials are isolated under ignored `.tools/gcloud-config`; the SDK
is installed under `.tools/google-cloud-sdk`. Private runtime configuration is in
`.tools/store/cloudrun-env.yaml`; do not commit it or print its contents.

The server has body, concurrency and timeout bounds, but no distributed per-client
rate limiter. Keep the service and review credential available throughout review.
Signing and review credentials are described in [reviewer-access.md](reviewer-access.md).

September 23 follow-up: a fresh Google Play install on Pixel 9 Pro XL completed
a no-charge license-test purchase through the live verifier, restored Plus after
clearing local app data, then returned to free mode after Console refund/revocation.
See [live test status](store-setup.md#fresh-pixel-validation-completed-september-23).
The owner authorized discarding prior test installations and saves; the physical
Pixel now runs Play version 0.7.0 (11).
