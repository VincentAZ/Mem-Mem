# Store setup and live validation

The app currently runs without Google Play Console or AdMob accounts. Local
simulations and Google's demo ads are not proof of working purchases, restoration,
or configured privacy messages.

## Google Play

1. Create and verify a Google Play developer account. Create the Mem-Mem app and
   confirm the permanent application ID before the first upload. The local default
   is `io.github.vincentaz.memmem`.
2. Establish an upload key, keep it outside Git, and back it up securely. Use Play
   App Signing. The generated `.tools/keys/debug.keystore` is for local debugging.
3. Complete the required app/account declarations and internal-testing setup.
4. Build a signed AAB using a separate store-testing export preset; add testers and
   install through the internal-test link. Phase 1's supplied script builds a debug APK.
5. Configure a non-consumable `remove_ads` product with a purchase option, localized
   price, and availability. Add license testers and use Google's test instruments.
6. Implement the purchase-verification service before enabling transactions.
   Verify package/product/token, grant only PURCHASED transactions, acknowledge
   verified non-consumables, deduplicate processing, and handle refunds/revocations.
   Never consume permanent ad removal. Do not embed service-account credentials.

The current native adapter deliberately cannot initiate a purchase. Enabling it
requires a later implementation change, not merely entering an application ID.

Test success, cancellation, delayed payment/completion, pending cancellation,
network loss, app termination, repeat callbacks, refund/revocation, reinstall and
restoration, and another device using the same store account. Check ownership
before showing an already-loaded ad. Do not call these checks complete using the
fake store buttons.

## AdMob and consent

1. Create an AdMob account and Android app; link the store listing when available.
2. Create an interstitial unit. Use Google's demo units or registered test devices
   throughout development; do not interact with live ads for testing.
3. Configure privacy messages and a privacy-policy URL in Privacy & messaging.
4. Replace the demo-only permission shortcut with the validated consent flow,
   request a status update at launch, and expose privacy choices when required.
5. Validate UMP with debug geography/test devices, including required/unavailable
   forms, dismissal, errors, returning users, and updated choices.
6. Test ad loading, dismissal, no-fill/network failure, background/resume, and
   permanent suppression by verified ad removal. Add the approved frequency caps
   only when actual level progression exists.

AdMob uses Google's demo application ID and demo interstitial in this build. A
successful native demo ad does not validate your own account or production units.

## Device checks

- Launch with internet unavailable; the demo must remain playable.
- Observe the preview, flip, and shuffle; verify stationary positions afterward.
- Tap rapidly during a mismatch; only two portraits can be revealed.
- Match a pair, background the app during departure, and return.
- Terminate/relaunch after a resolved pair; removed tiles stay removed.
- Open Pause → Development service lab; exercise pending/cancel/failure and
  ad-load/restore races. Closing the lab returns to your paused game.
- Assess readability, thermal behavior, frame pacing, and touch accuracy on a real
  modest Android phone. Software-emulator timing is not a performance benchmark.

References: [Godot billing integration](https://godot-sdk-integrations.github.io/godot-google-play-billing/),
[Google purchase testing](https://developer.android.com/google/play/billing/test),
[Google purchase security](https://developer.android.com/google/play/billing/security),
[AdMob test ads](https://developers.google.com/admob/android/test-ads),
[AdMob privacy](https://developers.google.com/admob/android/privacy).

## Mem-Mem Plus (0.6.0 test implementation)

Use the permanent non-consumable product ID **`remove_ads`**, display name
**Mem-Mem Plus**. The bundle grants all three new themes (Woodland Crew, Snack Squad,
Mythical Misfits), their eligibility for perfect-round collectible claims, complete
ad removal, and one offline Quick Peek per board. It does not auto-collect characters.
The original four themes remain free. No promise covers every future theme pack.

Planned US launch price: **$1.99 once**. Intended later price: **$3.99**, subject to
review and a deliberate Play Console change. Prior buyers retain the bundle. Never
show $3.99 as a previously charged price before it has actually been offered.
The production screen must use Play's localized product price, not a hardcoded USD
conversion. Current screens explicitly show simulated introductory pricing.

The Android debug build uses Google's rewarded demo unit supplied by AdmobPlugin.
Create a production rewarded unit when the AdMob account exists. A completed reward
unlocks one peek for that board; mere dismissal does not. Configure UMP messages and
use its request-permission result before enabling any production ad request.
The development Allow & watch button permits test traffic only and must be replaced
by the production consent flow. Add privacy options where required by UMP.

Before enabling real purchases: implement verified purchase processing and
acknowledgement, handle revocation/refunds, retrieve localized product details,
and validate purchase, pending resolution, restoration and offline entitlements
with Play license testers. Native charges remain unconditionally disabled in this
release. Fake ownership files are never evidence of a real store purchase.
