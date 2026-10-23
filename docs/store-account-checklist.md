# Mem-Mem account setup checklist

**Current status, September 26, 2026:** production release **0.7.0 (11) - US
launch** was approved and the Play listing is public (US only). The AdMob account
is approved, the AdMob app is linked to the Play listing, `app-ads.txt` is served
at https://vincentaz.github.io/app-ads.txt, and the Play listing website now
points at https://vincentaz.github.io so AdMob can crawl it. Only AdMob's
automatic app verification remains; see the status block at the top of
[store-setup.md](store-setup.md). Earlier setup notes below record the sequence
before this point; the current status takes precedence.

- [x] Prepare and submit the production release using the tested bundle.
- [x] Google completes checks/review and publishes the production rollout
  (September 23 submission; approved and public by September 26).
- [x] Verify public store availability, link the public listing in AdMob, publish
  `app-ads.txt` and point the listing website at it (September 26).
- [ ] AdMob automatic app verification: re-run **Verify app → Check for updates**
  after propagation (listing-website change up to 1 hour; crawler up to 7 days).

Use this alongside [store-setup.md](store-setup.md). Unchecked items are pending,
not evidence that an account or resource has been created. No production release
is ready until the live release gates in that guide pass.

## 1. Confirm the owner and audience

- [x] Play Console account accessible, inspected on September 22, 2026.
  The supplied account is an existing Organization account. Mem-Mem has now been
  created; the 10 older apps were left unchanged. Contact and developer email/phone fields show verified.
  A Console notification inspected September 23 confirms identity verification
  succeeded September 22. September 23 follow-up: Android developer verification
  lists **Mem-Mem / io.github.vincentaz.memmem — Registered**, with three keys.
- [x] AdMob account created and dashboard verified. Organization payment profile
  submitted; the incomplete-payment warning cleared after refresh.
- [x] Confirm the primary target market: adult women, clarified by the owner on
  September 22, 2026.
- [x] Finalize intended audience: adults aged 18 and over, with adult women as the
  primary market. Owner explicitly confirmed that children are not targeted.
- [x] Save **18 and over** as the sole target age group in Play Console.
  September 23: reviewer access is saved and the audience summary is confirmed.
  Adult-focused listing text is saved. The optional extra Play minor-blocking
  restriction was left at its default (unchecked).
- [x] Record account type: Organization, confirmed in Play Console.
- [x] Launch country confirmed: United States only.
- [x] Save production country availability in Play Console: **United States** is
  the sole targeted country. Production remains inactive; no release was created.
- [x] Public developer name observed in Console: Plan 9 from Outer Space.
- [x] Support/privacy email confirmed by owner: vincent.serpico@ailearningcenter.ai.
- [x] Website chosen by owner: https://serpico.ai/ (currently redirects to
  https://www.ailearningcenter.ai/). **The Play listing website was changed on
  September 26, 2026 to https://vincentaz.github.io** so AdMob can find
  `app-ads.txt`; do not revert it to serpico.ai. The merchant profile website is
  unchanged.
- [x] Website platform confirmed by owner: Wix.
- [x] Publish the reviewed [privacy policy](privacy-policy.md) on Wix. The owner
  explicitly approved the policy disclosures and publication of all saved site
  changes, including the older September 10 and 14 drafts. Desktop and mobile
  previews were checked; the full live policy is accessible without signing in.
  Verified URL: https://www.ailearningcenter.ai/mem-mem-privacy.
  See [publication notes](privacy-policy-draft.md).

The account owner completes identity checks, payments and agreements directly in
Google. Keep passwords, verification documents and credentials out of this file
and chat. The local store configuration now uses `child_directed: false` and
`under_age_of_consent: false` for the confirmed adult audience. These flags do not
verify a player's age or save the Play Console declarations. The reusable example
keeps both flags `null` so future configurations require an explicit decision.

If children are included in the final intended audience, review the
[Google Play Families requirements](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)
before finalizing monetization. Verify the actual ads SDK version is Families
self-certified and the rewarded ad format meets the child-audience requirements,
including dismissal rules. If the audience includes children and older users,
resolve the neutral age-screen requirement before release. App-wide ad flags alone
do not establish compliance.

## 2. Google Play Console

- [x] Create the [Play Console](https://play.google.com/console/) account.
- [x] Verify known account identity and Mem-Mem package registration: identity
  succeeded September 22; package is **Registered**, confirmed September 23.
  No additional identity task appeared on the inspected verification page.
- [x] Create **Mem-Mem** as a free game, default language English (United States).
  The owner submitted the creation form; the app dashboard was verified afterward
  in Play Console.
  Plus is now an active separate in-app purchase. Bundle 0.7.0 (11) is uploaded
  and **available to internal testers** as of September 23, 2026.
- [x] Check package availability for **`io.github.vincentaz.memmem`** during creation.
- [x] Uploaded bundle uses **`io.github.vincentaz.memmem`**.
- [x] Save the verified public privacy policy URL in Play Console. Console
  confirmed "Change saved. Send for review in Publishing overview." The change
  has not been submitted for review; the internal test release is now published.
- [x] Complete the initial Play payments/merchant setup for selling in-app products.
  September 23: reused the existing **SERPICO ENTERPRISES, L.L.C. Organization
  profile for AdSense**. After the owner's submission attempt, the statement-name
  validation error was corrected from `SERPICO-ENT` to **SERPICO ENT** and the
  form submitted successfully. Console now displays **Google Play Apps / SERPICO
  ENTERPRISES, L.L.C.**, earnings, transactions and payment settings.
  Website: **https://serpico.ai/**; category: **Computer Software**; support email:
  **vincent.serpico@ailearningcenter.ai**. Existing legal and contact details were
  preserved. This does not complete payout-method, tax or later verification tasks.
- [ ] Add a payout method; Console currently says **Add a payment method to receive
  your earnings**. The owner supplies bank/payment details directly in Google.
- [ ] Review eligibility and associated developer accounts for the **15% service
  fee** program. Console offers enrollment, requiring an account group and terms;
  no enrollment or associated-account declaration was made.
- [x] Create and activate **`remove_ads`**, named **Mem-Mem Plus**, with permanent
  **`buy`** purchase option, matching the app and verifier configuration.
- [x] Set **USD 1.99 once**, **United States only**, with other and future regions
  unavailable. Console confirms the buy option is **Active**.
- [x] Prepare internal testing: signed **0.7.0 (11)** bundle uploaded and saved as
  **0.7.0 (11) - Internal validation**. The new **Mem-Mem internal** list contains
  only the owner's Google account and is selected. Existing lists are unchanged.
  The track is **Active**, and the release is **Available to internal testers**
  (September 23, 11:18 AM, Console time). Owner accepted the test invitation.
  The join link is private to the tester list.
  Temporary app name: `io.github.vincentaz.memmem (unreviewed)`.
- [x] Select **Mem-Mem internal** for license testing, with the existing
  **RESPOND_NORMALLY** response preserved. License-test settings apply across the
  developer account; no existing tester list selection was removed.
- [x] Validate the basic Play-installed test purchase, same-account restore after
  clearing local data, and refund with entitlement removal. All passed on Pixel
  version 0.7.0 (11); the live verifier requires Play acknowledgement before access.
- [x] Validate checkout cancellation, immediate decline, pending cancellation,
  pending approval after process interruption, already-owned Restore, and
  revocation preserving existing score/collection on the Play-installed Pixel.
  September 23 results and order IDs are recorded in the main guide.
- [x] Validate reviewer-code redemption, restart persistence and removal on the
  actual Play-installed Pixel, preserving the owner's game progress.
- [ ] Complete remaining purchase edge cases and another-device restore.
  Owner is enrolled and the private download page is available. Owner authorized discarding
  current test installs and starting fresh. Pixel debug app was removed; the
  clean Google Play installation is complete; see [current validation status](store-setup.md#september-23-live-test-status).
- [ ] If this is a personal account created after November 13, 2023, plan a closed
  test with at least **12 testers continuously opted in for 14 days**, then apply
  for production access. Keep feedback and test records. Internal testing is a
  separate step. [Official testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).
- [x] Complete the initial app content, audience, rating, Data safety and listing
  forms. Final live SDK/backend checks remain production release gates.

### Routine Console setup verified September 23, 2026

All **11 initial setup tasks are complete**; the dashboard's initial setup block
has cleared and release setup is unlocked. These are saved Console changes; the
signed bundle is published to the internal track. No production release or
Publishing overview submission was made.
After saving the additional Advertising ID declaration, **App content → Need
attention** confirms **You're all caught up**. Owner license-test settings also
confirm **Your changes have been saved**.
Publishing overview confirms **Changes not yet submitted for review**, with
review submission still pending. The existing US-only
country change remains queued. An existing Google Play Games on PC opt-in also
appears among pending changes; it was not modified in this session and should be
reviewed before release.

- [x] Privacy policy: existing live URL preserved and verified saved.
- [x] Ads: **Yes, my app contains ads**, reflecting optional rewarded Quick Peek ads.
- [x] Content rating: IARC status **Completed**. North America: **Everyone**, with
  **In-Game Purchases**. Digital goods were disclosed; no paid random items,
  player trading, user communication, location sharing, violence, fear, sexual
  content, gambling, offensive language, substances, or crude humor were declared.
  This rating does not change the intended 18+ audience.
- [x] Government apps: **No**.
- [x] Financial features: **My app doesn't provide any financial features**.
- [x] Health: **My app does not have any health features**. Current gameplay has
  no health guidance, health-data access, or brain-training/medical claims. Revisit
  if positioning changes; [Google's definitions](https://support.google.com/googleplay/android-developer/answer/14738291)
  include cognitive-health/brain-training features.
- [x] Category/contact: **Game / Puzzle**; support email
  **vincent.serpico@ailearningcenter.ai**; website **https://vincentaz.github.io**
  (changed from https://serpico.ai/ on September 26, 2026 for `app-ads.txt`).
  Optional phone left blank; existing external-marketing setting preserved.
- [x] Sign in details: **Yes**, with private reusable-code instructions for Plus.
  The code was validated against the live service using the signed bundle on the
  dedicated API 35 emulator; redemption, restart persistence and removal passed.
  See [reviewer-access.md](reviewer-access.md). This does not establish a real Play
  purchase or replace Play-installed validation before production.
- [x] Target audience: **18 and over** only.
- [x] Data safety: completed and saved. See [exact answers and evidence](data-safety.md).
  Declares approximate location, device/other IDs, app interactions, diagnostics
  and purchase history; encrypted transit, no app accounts, and privacy-request URL.
  Current Google SDK guidance describes a newer release than the pinned Mobile
  Ads 24.9.0; final SDK/network validation remains a release check.
- [x] Advertising ID: the bundle triggered this additional declaration; saved
  **Yes**, for analytics, advertising/marketing, and fraud prevention/security/
  compliance. The merged manifest includes Google's AD_ID permission.
- [x] Store listing: English (US) text, 512×512 icon, 1024×500 feature graphic,
  and four 1080×1920 phone screenshots saved. Console status is **Ready to send
  for review**. Screenshot order: opening pairs, matched pair, collection, dark
  mode. Files and capture limitations are in [store-assets](../store-assets/README.md).
  The owner enabled extension file-URL access and uploads now work.
  Per-asset AI labels were applied to the feature graphic and all four screenshots
  because they contain generated character artwork documented in
  [asset-credits.md](asset-credits.md); the vector monogram icon was left unlabeled.
  See [Google's declaration guidance](https://support.google.com/googleplay/android-developer/answer/17262077?hl=en).
  Text is preserved in [store-listing.md](store-listing.md). The listing has not
  been sent for review or published.

Internal testing is active with the owner account and signed bundle. The
access-code privacy addendum and US AdMob message are published. Production still
requires the live release gates in the main guide. The two non-blocking bundle
warnings concern missing deobfuscation metadata and native debug symbols.

## 3. AdMob

- [x] Create the [AdMob](https://admob.google.com/) account.
- [x] Submit the Organization payment profile for SERPICO ENTERPRISES, L.L.C.
  Account type and organization name verified in payment settings. The incomplete
  payment warning cleared after refresh. This does not establish app approval,
  payout-method readiness or tax-form completion.
- [ ] Complete any identity/address verification requested later. The current
  Verification tab says verification may be required once earnings reach the
  threshold; no immediate verification task is shown.
- [x] Add **Mem-Mem** as an unpublished Android app.
- [ ] Link the public store listing when available and complete app review.
- [x] Copy the application ID into local `admob_app_id`.
- [x] Create the **Quick Peek** rewarded ad unit with reward amount **1** and item
  **Quick Peek**; copy its ID into local `rewarded_unit_id`. Partner bidding is off.
- [x] Register **Mem-Mem Pixel 9 Pro XL** as an Android test device in AdMob.
  Production-unit request returned no fill; completed ad remains unverified.
- [x] Save AdMob draft **Mem-Mem US privacy choices**, English (United States),
  assigned to Mem-Mem, targeting all current and future supported US states.
- [x] Review and publish **Mem-Mem US privacy choices**. AdMob confirms
  **Published** on September 23. Both choice explanations now describe
  non-personalized ads, preserving allow/opt-out controls and all supported states.
  The live policy now covers access codes, Cloud Run and 30-day routine logs.
- [x] Validate the published US message in an isolated emulator test build with
  regulated-US UMP test geography: Settings shows the published form; opt-out and
  changing back to allow both persist after restart. Offline first launch blocks
  ads, displays a retry message, and recovers after reconnect/restart.
- [x] Validate completed rewarded-ad delivery with Google's demo unit in the
  isolated build: one earned callback grants one Quick Peek; using it changes
  Ready to Used. Killing the app before completion grants no reward on restart.
- [ ] Validate native early dismissal, remaining reward edge cases, and final
  production-unit delivery on the Play build after AdMob approval. Sample test
  creatives only exposed a close control after reward completion; early dismissal
  is not counted as tested. No-fill fallback passed on the actual Play build.
  See [test scope and evidence](store-setup.md#isolated-ad-and-consent-validation-september-23).
- [ ] Complete AdMob's verification and app-readiness tasks. September 23 Home
  explicitly shows **Your account isn't approved yet / Your account is being
  verified** and **Link to app store**. The payment profile is complete, but
  the app must be linked to its public listing to prompt app review. Live serving
  is not ready; creating IDs and publishing a privacy message do not establish approval.

Follow [AdMob's app setup guide](https://support.google.com/admob/answer/9989980?hl=en)
for the current setup and review flow.

## 4. Local configuration and remaining infrastructure

The working configuration belongs at `.tools/store/config.json` (ignored by Git).
Start from [store-config.example.json](store-config.example.json) if it does not
exist; never overwrite an existing configuration to restart setup.

- [x] `purchase_option` is **buy** in Play, the app and the server.
- [x] Fill in both AdMob IDs; local format validation passes.
- [x] Set `child_directed` and `under_age_of_consent` to `false` for the confirmed
  adult audience.
- [x] Publish the reviewed privacy policy and set local `privacy_url` to the
  verified live page. The store check no longer reports a privacy URL placeholder.
- [x] Generate the Android upload key and receipt-signing keypair without replacing
  existing keys. Signing variables and the reusable reviewer credential are in
  ignored `.tools/store/` files with restricted permissions. An additional
  restricted local backup exists outside the repository.
- [x] Back up release recovery material off-device in the separate Mem-Mem
  project: Secret Manager **mem-mem-release-recovery**, version 1. All eight
  archived files were read back and compared byte-for-byte on September 23. No
  runtime service-account access was granted to this backup.
  See [reviewer-access.md](reviewer-access.md) for recovery details.
- [x] Create the separate **Mem-Mem** project (`mem-mem-509517`), provision its
  service identity and Secret Manager mount, deploy the verifier, and set
  `verification_url`. Live HTTPS access-code redemption, signature, expiry and
  rejection checks pass; Play Console shows the scoped service account Active.
  Project-only USD 20 monthly budget alerts are configured (not a spending cap).
  See [deployment details](cloud-deployment.md). The signed store build now passes
  configuration and signature checks; basic live test purchase, restore and revocation passed on Pixel; remaining
  edge cases and ad/consent validation are still required.
- [x] Console accepted version code **11**, version **0.7.0**, as the first bundle.
  The artifact SHA-256 is recorded alongside `build/mem-mem-store.aab`. Future
  builds must increase the version code.

From the repository root, check readiness with:

```bash
./scripts/build_store.sh .tools/store/config.json --check
```

Until the pending values and signing credentials exist, this command should fail
with a list of missing inputs. It does not contact Play or AdMob, verify website
availability, deploy a service, or upload an app. After it passes, follow the signed
build and live testing steps in the main guide.
