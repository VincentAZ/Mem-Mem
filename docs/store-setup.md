# Store setup and production monetization

**Production submission: September 23, 2026, approximately 21:40 UTC.**
Play Console now shows **Changes in review** for **0.7.0 (11) - US launch**, with
**Start full rollout** and **United States** as the only added country. All 11
queued changes were submitted. At **21:46 UTC**, the quick-check progress block
was replaced by **Your changes are now in review**. Google approval remains
pending, so **the app is not yet verified published to production**. Managed
publishing is off; approved changes are set to publish automatically. The existing
Google Play Games on PC opt-in was preserved in this submission.

The production integration is implemented and internal testing is active. Basic
Play purchase, same-account restore and refund/revocation passed. US consent and
completed reward delivery passed in an isolated native test build. AdMob account
and app approval are pending; optional ads currently fall back gracefully on no
fill. Remaining extended device tests below are not claimed complete. The user
explicitly directed continuing through production publication on September 23.
Debug builds use simulated purchases and Google demo ads; the submitted store
bundle uses native billing, server verification, signed offline access, UMP and
optional rewarded ads with the configured production IDs.

The [Mem-Mem privacy policy](https://www.ailearningcenter.ai/mem-mem-privacy) is
published and publicly accessible, updated September 23, 2026 with access-code
disclosures, Google Cloud Run hosting and 30-day routine request-log retention. The local
`privacy_url` points to that verified page. The URL is also saved in Play Console;
it is included in the submitted production review.

As of September 23, all **11 initial Play setup tasks are complete**, and the
additional Advertising ID declaration is saved. The dashboard's initial setup
block has cleared. The English-US listing and disclosures are included in the
production submission. See the [account checklist](store-account-checklist.md)
and [Data safety record](data-safety.md).

The separate Google Cloud project **Mem-Mem** (`mem-mem-509517`) hosts the deployed
verification service; live HTTPS and signed access-code checks pass. The
**0.7.0 (11)** signed bundle is **available to internal testers** as of September
23, 2026, 11:18 AM (Console time). The owner's Google account is the only tester
and has accepted the invitation. The same bundle passed
review-code redemption, restart persistence and removal checks on the dedicated
API 35 emulator. See [deployment details](cloud-deployment.md) and
[reviewer access](reviewer-access.md).

**Mem-Mem Plus** (`remove_ads`, permanent `buy` option) is **Active**, priced at
**USD 1.99**, available only in the United States. Play merchant setup is complete;
payout method and 15% service-fee enrollment remain separate owner/account tasks.
The internal release is published; production rollout is submitted for review
and is not yet confirmed available to the public. The access-code policy
addendum and AdMob US message are published. Complete Play-installed purchase
and consent validation before production.

Internal test: https://play.google.com/apps/internaltest/4701136527198574687.
Testers currently see the temporary name `io.github.vincentaz.memmem (unreviewed)`.

## The offer

The confirmed intended audience is **adults aged 18 and over**, primarily adult
women, without targeting children. The local store configuration uses
`child_directed: false` and `under_age_of_consent: false`. Match the final app
presentation and Play target-audience declaration to this decision before release.
These flags do not perform age verification. The example configuration intentionally
requires each publisher to set its own audience treatment.

Initial distribution is **United States only**. Production country targeting is
saved in Play Console, but the track is inactive. AdMob's **Mem-Mem US privacy
choices** message is **Published** in English for all current and future
supported US states. Both choice explanations now reflect non-personalized ads;
the published form, changed choices and restart persistence passed in an isolated
emulator build with regulated-US test geography. Final Play-build ad serving still
awaits AdMob account and app approval.

- Permanent non-consumable product: **`remove_ads`**, display name **Mem-Mem Plus**.
- One permanent **buy** purchase option; use its exact ID in both configurations.
  Do not configure rental or multi-quantity purchases for this bundle.
- US launch price: **$1.99 once**, saved and active in Play Console. The screen uses
  the eligible option's localized Play price. It never invents currency conversions
  or displays a fictitious previous price. Any later $3.99 price is a deliberate
  Console change; existing buyers keep the bundle.
- Plus grants Woodland Crew, Snack Squad and Mythical Misfits (24 characters to
  earn), one Quick Peek per board and complete ad suppression. It does not
  auto-collect characters or promise every future theme pack.
- Free players can explicitly choose a rewarded ad for one Quick Peek. No banners,
  forced interstitials or automatic ad displays are part of the production flow.

## Account setup, in order

For the first setup session, use the [account checklist](store-account-checklist.md)
to collect the Console values needed by the local store configuration.

1. Create and verify the Google Play developer account. Create Mem-Mem using the
   permanent application ID **`io.github.vincentaz.memmem`**. Finish account and
   app requirements shown in your Console, including the target audience, content
   rating, Data safety, privacy-policy URL and testing requirements.
2. Create an upload key and enable Play App Signing. Keep the key, its password and
   a backup outside Git. Use the same store/key password for Godot. The repository's
   `.tools/keys/debug.keystore` cannot sign a store export.
3. Configure the one-time product and its permanent buy option, regions and prices.
   Add license testers and an internal test track. Install the app through Play for
   real purchase-flow testing.
   Personal developer accounts created after November 13, 2023 also need a closed
   test with at least 12 testers opted in continuously for at least 14 days before
   applying for production access. Internal testing does not replace this gate.
   See [Google's testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).
4. Create the AdMob app and a **rewarded** ad unit. Configure and publish the relevant
   Privacy & messaging forms. Register your physical test devices in AdMob before
   using your own ad unit for internal testing. Development APKs still use demo IDs.
5. Confirm the intended audience before setting `child_directed` and
   `under_age_of_consent` in the store configuration. Both are deliberately unset in
   the example. The chosen app-wide treatment must match the actual audience;
   mixed-age differentiated treatment needs an age flow before using adult settings.
   Child-directed builds remove the AD_ID permission. Ads use G content rating,
   non-personalized requests and no first-party ID. These technical flags do not
   replace Console declarations or validation of applicable Families requirements.
6. Set up the verification service below, put its public URL and public key into the
   store configuration, then build and test a signed bundle.

## Purchase verification service

`server/` is a dependency-free Node 22+ HTTP service, suitable for an HTTPS container
host such as Cloud Run. It fixes the application ID and product server-side and
accepts only `POST /v1/play/verify` JSON bodies containing `product`, `token`, a
random installation `device` ID and a per-request `nonce`. No service credential or
private signing key goes into the game.

The service queries Play's `purchases.productsv2.getproductpurchasev2`. It checks
product, permanent purchase option, purchase state, consumption and refundable
quantity. Pending payments never grant access. A verified purchase is acknowledged
and confirmed with Play before an active receipt is issued. The permanent product
is **never consumed**. Duplicate processing has the same boolean result, and
concurrent requests for a token share work within a server instance.

Create a separate RSA receipt-signing key (this is **not** your Android upload key):

```bash
mkdir -p .tools/store
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 \
  -out .tools/store/receipt-private.pem
chmod 600 .tools/store/receipt-private.pem
openssl pkey -in .tools/store/receipt-private.pem -pubout \
  -out .tools/store/receipt-public.pem
```

Provision a Google service account with Android Publisher API access and the
required app-level purchase-management permissions in Play Console. On Cloud Run,
attach that identity to the service; the server obtains its access token through
Google's metadata service. For a local service process, set
`GOOGLE_APPLICATION_CREDENTIALS` to the service-account JSON **outside Git**.
Do not send service-account keys or private signing keys through chat.

Runtime configuration:

```text
RECEIPT_PRIVATE_KEY_FILE=/mounted-secret/receipt-private.pem
PURCHASE_OPTION_ID=buy
PORT=8080
```

Build the container with `docker build -t mem-mem-verifier server`. Mount the receipt
key from your host's secret store, expose the service through HTTPS, and set request
rate limits and billing/availability alerts on the host. The application limits body
size, concurrent verification, request duration and upstream timeouts; it logs only
sanitized error categories. Do not enable request-body or token-bearing upstream
URL logging. `/health` is a process liveness check, not proof of Play permissions.

The game has no app accounts. The Play purchase token acts as a bearer credential:
restoration on another device uses the same Play account's token and obtains a
new installation-bound receipt. Treat purchase tokens as secrets. There is no
user-account binding or Play Integrity attestation in this implementation.

### Offline use and refunds

The server signs each response with RSA-SHA256, including the package, product,
installation, token hash, nonce, result and expiry. Godot validates the signature
before granting anything and atomically caches active receipts for **up to seven
days**. It remembers the highest observed time and checks expiry while running.
An edited ownership JSON flag or a receipt copied to a different installation is
not accepted. Reinstall requires a connected Play restore.

Launch, foreground resume and Restore purchase query Play ownership again. A
successful empty query clears access; a verified refunded/cancelled/consumed
purchase clears access too. Temporary failures preserve an unexpired signed receipt.
There is **no immediate offline revocation**: a refund can retain access until the
next successful check or the seven-day expiry. No RTDN receiver or customer account
database is included. The server rechecks Play on every verification and does not
cache positive purchase states between completed requests. Keep the signing key
stable; changing it requires a client update and connected restores for old receipts.

## Signed store build

Copy [the example configuration](store-config.example.json) to an ignored local
path such as `.tools/store/config.json`. Replace every placeholder. Use an absolute
path for the **public** receipt key. Set both audience flags after deciding the
actual audience, and choose a version code greater than every previous Play upload.

Provide these in your shell or CI secret environment:

```text
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/absolute/path/to/upload.jks
GODOT_ANDROID_KEYSTORE_RELEASE_USER=your-upload-key-alias
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=<secret>
```

Then run:

```bash
./scripts/validate.sh
./scripts/build_store.sh .tools/store/config.json --check
./scripts/build_store.sh .tools/store/config.json
```

The script validates configuration, the public key and upload certificate. It
stages a separate project under `build/store-project`, creates a `production`
feature export, installs the native UMP extension, injects the public configuration
and AdMob manifest ID, and exports `build/mem-mem-store.aab`. It verifies the bundle
signature and writes its SHA-256. Signing secrets come from environment variables.
The normal project, debug preset, demo ad IDs and test-save files are not rewritten.
No upload or deployment happens in this script.

Production selects native billing and hides the development lab and simulated-ad
controls. Missing product information disables Buy; missing consent permission
blocks advertising. Settings exposes UMP privacy choices when required and links
the configured privacy policy. Debug ownership is never read by native billing.

## Live release gates

Automated tests and a successful build cannot establish any of these store results.
Complete them on a Play-installed internal-track build before production:

- Localized price matches the final Play purchase dialog. Correct product/option
  unlocks Plus once; already-owned restores instead of charging again.
- Success, cancellation, decline, pending completion/cancellation, process death
  during purchase, network loss and server outage all recover through Restore.
- Google confirms acknowledgement. Refund/revoke a purchase and verify that Plus
  is removed on recheck while already-earned collection characters remain.
- Reinstall and restore on another device using the same Play account. Verify
  signed offline access, expiry and failed restoration without charging again.
- Validate the configured UMP messages on registered test devices for the relevant
  regions, first launch, returning players, errors and changed privacy choices.
  The default debug lab still tests the older plugin UMP wrapper; production uses
  `MemMemConsent`. Test geography must be configured in a dedicated native test
  build, never carried into a published build.
- Reward is granted only by the earned-reward callback, once for the originating
  board. Early dismissal, no-fill, timeout and stale callbacks grant nothing.
  Buying/restoring Plus suppresses already-loaded ads as well as new requests.
- Review the actual merged manifest, Data safety answers, privacy policy, target
  audience and current store requirements against the SDKs and backend deployed.

## Verification sources

- [Billing plugin API](https://godot-sdk-integrations.github.io/godot-google-play-billing/)
- [Pinned 3.3.0 response serialization](https://github.com/godot-sdk-integrations/godot-google-play-billing/blob/3.3.0/godot-google-play-billing/src/main/java/org/godotengine/plugin/googleplaybilling/Utils.kt)
- [Play purchase security](https://developer.android.com/google/play/billing/security)
- [ProductPurchaseV2 fields](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.productsv2)
- [Play purchase testing](https://developer.android.com/google/play/billing/test)
- [AdMob UMP](https://developers.google.com/admob/android/privacy)
- [AdMob audience settings](https://developers.google.com/admob/android/targeting)
- [Godot Android signing](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)

## September 23 live test status

The internal tester invitation and private Play download page were verified. The
owner is enrolled; the listing has an Install button and shows device availability.
The temporary unreviewed listing does not yet display the saved public listing,
content rating or Data safety information.

On the signed release APK in the dedicated API 35 emulator, UMP contacted the live
service without a logged consent error. No privacy-choice entry point was required
in this observed session; this does not validate the supported-state opt-out form.
The production rewarded ad unit initialized only after choosing Watch ad. The SDK
confirmed a test-device request, then returned load error 3 (no fill). The app
displayed “No ad available. Keep playing or try again.” and allowed return to play.
At this stage, completed-ad reward delivery and state-specific consent were
unverified; the later isolated test results below cover both with test settings.
Evidence: `build/screenshots/store-consent-*.png`.

The owner explicitly authorized a fresh start: existing installations and saves
are disposable test data, with upgrade preservation deferred to future Google
Play upgrades. The Pixel debug installation was uninstalled successfully; a
fresh install from the internal Google Play listing completed successfully.
Android reports version 0.7.0 (11), installer `com.android.vending`. The earlier
backup remains private at `build/device-backups/pixel-game-files-20260923.tar`;
restoring it is no longer part of the plan.

### Fresh Pixel validation completed September 23

- Fresh Google Play installation starts at level 1, score 0, collection 0/56.
- The app and Play checkout both show USD 1.99 for Mem-Mem Plus. Checkout
  explicitly used “Test card, always approves” and said no charge would occur.
- The test purchase unlocked Plus through the deployed verifier. No reviewer
  access code was entered. The server only returns active receipts after checking
  acknowledgement with Play; this is implementation-backed evidence, not a
  separately captured Publisher API acknowledgement response.
- Clearing app storage and relaunching restored Plus automatically from the same
  Play account. Quick Peek became Ready without an ad or another payment.
- Console showed the test order Processed, then confirmed “1 order refunded”
  after a 100% refund with Remove entitlement selected (reason Other). On return
  to the app, Plus was removed and Quick Peek returned to Watch ad.
- AdMob test device **Mem-Mem Pixel 9 Pro XL** was registered using the advertising
  ID displayed in Android Settings. No device privacy setting was changed.
- The production rewarded unit returned SDK load error 3 / no fill on the Pixel.
  The app displayed its no-ad fallback. No ad was shown or clicked, so completed
  reward delivery and early-dismissal behavior remain unverified.

Evidence: `build/screenshots/pixel-play-*.png`, `pixel-ad-*.png`; test order
`GPA.3395-2616-3677-20565` in Play Console. The Pixel remains on the fresh Play
build in free mode after revocation. Upgrade/save migration testing is deferred
to future Google Play upgrades per the owner. Decline/pending flows, another-device
restore, offline expiry, outage recovery and supported-state consent remain
production release gates. The earlier cancellation attempt was not captured after
the UI settled and is not counted as a completed validation.


### Isolated ad and consent validation September 23

The AdMob Home page was rechecked: **Your account isn't approved yet / Your account
is being verified**, with **Link to app store** outstanding. Payment profile is
complete. App review requires linking the public store listing, which is not yet
published. These are concrete live-serving blockers; test-ad success does not
establish approval or production-unit fill.

An ignored copy of `build/store-project` at `build/ads-consent-validation` was
exported as **Mem-Mem TEST ONLY** and installed only on the dedicated API 35
emulator. It retains the production feature and application ID, actual AdMob app
ID and native consent/reward logic. Test-only differences: regulated-US UMP debug
geography, Google's rewarded demo unit injected at the SDK bridge, and sanitized
consent/reward diagnostic logging. The initial attempt to put a demo ID into the
production configuration correctly failed closed; the production configuration
guard was preserved. These test settings were never uploaded to Play.

Observed results:

- The actual published **My data preferences** form loads from Settings, including
  the Mem-Mem logo and custom non-personalized-ad explanations. UMP reports
  privacy options REQUIRED and permits eligible non-personalized requests.
- Selecting **Don't sell or share my data**, saving, restarting, and reopening the
  form preserves the opt-out. Changing back to **Allow the sale or sharing of my
  data**, saving, and restarting preserves the changed choice. UMP logs show the
  corresponding GPP storage updates. This verifies the form and stored choices,
  not every downstream advertising network's processing.
- With fresh app data and both emulator networks disabled, UMP returns unavailable
  and `canRequestAds=false`. Watch ad shows the privacy retry message; no rewarded
  SDK request is issued. Restoring both networks and restarting restores the
  required privacy entry point and eligibility. Both network settings were
  restored to their original enabled state.
- A creative visibly labeled **Test Ad** completes with **Reward granted**. Exactly
  one delivered-reward log appears for that request. On dismissal, Quick Peek is
  **Ready**; using it changes the button to disabled **Used** on that board.
  This also passed while the saved US opt-out was in effect.
- Force-stopping the app immediately after another test ad starts, before the
  earned callback, produces no delivered-reward log. Restart shows **Watch ad**,
  with no unearned peek. This is process-interruption coverage, not native early
  dismissal coverage.
- Sample creatives ignored Back before completion and exposed their close control
  after awarding a reward. Native early dismissal remains unverified. Timeout,
  stale callback, and Plus suppression of an already-loaded ad also remain live
  release checks; existing automated coverage does not replace them.

Evidence is local and ignored: `build/screenshots/consent-test-form.png`,
`consent-test-optout-restart.png`, `consent-test-allow-restart.png`,
`consent-test-offline-blocked.png`, `ads-test-complete-screen.png`,
`ads-test-earned.png`, `ads-test-used.png`, `ads-test-interruption-restart.png`,
plus `build/ads-test-completion.log`, `ads-test-interruption.log`,
`consent-test-offline.log`, and `consent-test-changes.log`.

The Pixel's Play-installed 0.7.0 (11) was not replaced. The original uploaded AAB
is unchanged, SHA-256
`6b23cf824227516a4bd7be765d93c971f6a37f3dc4a2373609a90c7d1a1f3964`.

Cleanup completed: the original signed `mem-mem-store-universal.apk` was
reinstalled successfully on the emulator, temporary test data cleared, and the
dedicated emulator stopped. The TEST ONLY APK remains clearly named in ignored
`build/` for local evidence; it must never be uploaded or distributed.


### Production submission September 23

- Selected the existing **11 (0.7.0)** bundle from Play's library; no rebuild or
  replacement upload. Release name: **0.7.0 (11) - US launch**.
- Release validation had zero blocking errors and two existing advisory warnings:
  missing deobfuscation metadata and native debug symbols.
- Saved and sent all **11 changes**. Publishing overview shows **Changes in
  review**, **Start full rollout**, US-only country addition, saved listing and
  content declarations. At 21:40 UTC quick checks were still running with up to
  14 minutes indicated. Review and publication remain external pending work.
- Managed publishing remains **off**. The submitted rollout is intended to go
  live automatically on approval, as authorized by the user.
- `scripts/validate.sh` passed: 11 server tests, 5 Python tests, 88,383 game checks,
  zero failures, and production smoke. Local store/signing checks passed.
- Manifest was decoded from the exact AAB again: API 36/minimum 26, expected
  billing/advertising permissions, native billing/consent plugins and real AdMob
  app ID. No location, contacts, microphone or storage read permission appears.
- Release recovery was archived to Secret Manager **mem-mem-release-recovery**
  in the separate Mem-Mem project, read back and all eight files compared to
  originals. No runtime IAM binding was added to this backup.
- Pixel is still the Google Play installation; further purchase edge-case tests
  currently need the owner to unlock its screen. No device test was fabricated or
  treated as passed because review was submitted. Extended tests and AdMob
  readiness remain explicitly pending.

Android developer verification was checked after submission: Mem-Mem /
`io.github.vincentaz.memmem` is **Registered**, with three keys. The Identity tab
shows the organization details without an additional verification action.

Submission activity independently confirms **submission 1**, sent **September 23,
2026, 2:40 PM Phoenix (21:40 UTC)**, status **In review**.
[Submission details](https://play.google.com/console/u/0/developers/8105003511787020834/app/4976157516315816306/publishing/submission-activity/1/details).
The Dashboard now labels the production track Active, but Update status remains
In review; this is not evidence of public availability.

Follow-up review check at **21:46 UTC**: submission 1 still reports **In review**;
quick checks have finished and Publishing overview says **Your changes are now
in review**. There is no new issue or action shown. Monitor and improve reports **No policy issues found**. The
Pre-launch report page has no generated report yet, so no Google device-test
result is claimed. Public-store verification through the web tool was unavailable
and is not treated as evidence of either publication or rejection. The Pixel was subsequently unlocked and the additional device checks below
completed.


### Pixel purchase edge cases, September 23, 22:08–22:17 UTC

Tested on the unchanged Play-installed **0.7.0 (11)**, using only Google license
test instruments. Checkout explicitly stated **This is a test order, you will not
be charged**. Preserved the owner's current level 5 completed board, score 2078,
and collection 3/56; no app storage was cleared or installation replaced.

- **Checkout cancellation:** Android Back dismisses checkout; app returns to free
  mode with purchase enabled and no Plus entitlement.
- **Immediate decline:** **Test card, always declines** returns the Google error
  **Declined by always denied test instrument**. Dismissing it returns to free
  mode with a retry available; no benefit is granted.
- **Pending then canceled:** **Slow test card, declines after a few minutes**
  shows the app's pending message and disables another purchase. Force-stop and
  restart preserve the pending state. After Google cancels it, Restore returns
  **No Plus purchase found** and enables purchase again. Console independently
  lists order **GPA.3368-4228-2500-73101** as **Canceled**.
- **Pending then approved / process interruption:** **Slow test card, approves
  after a few minutes** shows pending and does not unlock Plus. Force-stopped
  Mem-Mem while waiting; Google processed the order while the app was closed.
  Relaunch automatically recovered and verified the purchase, showing **Plus
  active**. Explicit Restore also preserves access without opening checkout.
  Order **GPA.3366-9212-7075-45416** was received at 22:12:17 UTC and processed
  at 22:13:18 UTC according to Console. The already-active Plus purchase button
  remains disabled, preventing duplicate purchase through the app.
- **Refund/revocation with existing progress:** refunded that same test order at
  22:15:04 UTC, 100%, **Remove entitlement** checked, reason Other. Console shows
  **Refunded**; Restore removes Plus. Final board still shows level 5 completed,
  score **2078**, round score **665**, accuracy **55%**, collection **3/56** and
  free **Quick Peek · Watch ad**. Existing collected characters were preserved.
- **Reviewer access on the actual Play installation:** entered the private code
  already provided to Google; it unlocks Plus through the live service, survives
  restart, and **Remove code access** returns the app to free mode. No plaintext
  code was printed or included in evidence. Minor copy limitation: after restart,
  the detail line can say no Play purchase was found while the separate code
  entitlement correctly keeps Plus active; code access and payment are distinct.

Restored the payment-method selection to **Test card, always approves** and
canceled checkout without making another order. Removed reviewer access, returned
the phone to its original completed level 5 board, and preserved the existing
600000 ms screen timeout. No network or device privacy setting was changed.
Evidence: `build/screenshots/pixel-purchase-*.png` and `pixel-review-code-*.png`.

Still unverified on a Play installation: another-device restore, seven-day offline
expiry, network loss/server outage recovery, and the remaining live-ad edge cases.
The device is connected over Wi-Fi ADB; this pass did not interrupt its network or
alter its clock. These extended checks are not implicitly marked complete by the
successful cancellation, pending-payment, recovery, and revocation results.
