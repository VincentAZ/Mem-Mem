# Reusable access for Google Play review

Implemented, deployed and saved in Play Console September 23, 2026.
This is the same Plus entitlement used by paying players: three additional theme
packs, one Quick Peek per board, and ad suppression. It does not change gameplay,
pre-collect characters, impersonate a purchase or hide different review behavior.

## Reviewer instructions

The saved **Sign in details** contains a condensed 429-character version of these
English instructions. The credential comes from
`.tools/store/review-access-code.txt` and is only in the private access instructions; never
commit it or include it in public listing text.

1. The free game does not require an account. Play a round or open Settings.
2. Open **Settings → Mem-Mem Plus · themes & peeks → Use access code**. The Plus
   page scrolls on shorter screens.
3. Enter the supplied reusable code and select **Verify code** while connected
   to the internet. No payment, account registration, email or OTP is required.
4. Return to the game. Plus themes are available to earn through perfect rounds;
   purchasing or code redemption does not automatically collect characters.
5. To test free gameplay and rewarded ads, reopen **Use access code**, select
   **Remove code access**, and return to the game. Existing actual Play purchases
   remain active. Use a device without a Plus purchase for the free experience.
6. The same code works again on any installation and has no geographic restriction
   or redemption limit. Device receipts last seven days; re-enter the same code
   online after expiry or reinstall. Keep the server credential valid continuously.

The signed 0.7.0 (11) bundle was installed on the dedicated API 35 emulator:
redemption unlocked Plus, restart preserved access, the per-board Quick Peek no
longer required an ad, and Remove code access restored the free state. The same
bundle is published and available to internal testers. September 23 follow-up:
redemption, restart persistence and removal also passed on the actual
Play-installed Pixel 9 Pro XL. Its level 5 progress and collection were preserved. Google requires [reusable, continuously available reviewer access](https://support.google.com/googleplay/android-developer/answer/15748846).

## Deployment

`POST /v1/access/redeem` uses the same HTTPS origin as `/v1/play/verify`. The
bounded JSON body contains `product`, `token` (the code), `device` and `nonce`.
The verifier compares a SHA-256 hash in constant time and returns an RSA-signed,
installation-bound receipt with `grant: review`. Review requests do not call
Google Play. Missing or mismatched server configuration fails closed.

Configure `ACCESS_CODE_SHA256` from the ignored `.tools/store/verifier.env` in
the hosting service, alongside `PURCHASE_OPTION_ID=buy` and
`RECEIPT_PRIVATE_KEY_FILE`. Mount the receipt private key from a secret store.
The plaintext review code and private key must never be packaged into the app.
The code is not saved on the device; only the signed receipt is cached separately
from purchased access. API and proxy logs must not record request bodies.

Rotating or removing the server hash stops new grants, but existing receipts may
remain valid for up to seven days. If a credential must change, update the private
Console instructions at the same time; do not interrupt an ongoing review.

The service currently has a bounded body and concurrent-request limit. Configure
host request limits and billing alerts when deploying. Its current HTTP handler
does not provide a distributed per-client rate limiter.

## Prepared local release secrets

Private files are under `.tools/store/` with restricted permissions and are
ignored by Git: `upload.jks`, `signing.env`, `receipt-private.pem`,
`review-access-code.txt`, and `verifier.env`. `receipt-public.pem` is public
configuration. Existing files were preserved during generation.

An additional restricted local copy exists outside the repository. This protects
against losing the working
directory, **not loss of the machine**. Off-device recovery is now also stored in
Secret Manager **mem-mem-release-recovery**, version 1, in project
`mem-mem-509517`. It contains upload/signing files, receipt keys, review credential
and verifier/store configuration; all eight files were read back and compared
byte-for-byte September 23. The runtime service account was not granted access
to this recovery secret. Download with `gcloud secrets versions access` using
`--out-file` to preserve the binary gzip archive; do not print its contents. Do not rotate either key merely to repeat setup.

To check the signed build configuration without exposing the password:

```bash
source .tools/store/signing.env
./scripts/build_store.sh .tools/store/config.json --check
```

The owner selected a separate project. The service is now deployed in
`mem-mem-509517`; see [deployment details](cloud-deployment.md). Live HTTPS code
redemption and signed-receipt checks pass. Store configuration and upload-signature
checks pass; the 0.7.0 (11) bundle has been built. Play-installed device validation
is still required before production.

The access-code disclosure was published September 23 and Data safety is saved.
Complete the remaining live SDK, consent and Play-purchase checks before production.
