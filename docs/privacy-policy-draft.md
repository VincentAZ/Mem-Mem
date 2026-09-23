# Mem-Mem privacy policy publication notes

Status: the full policy is published on the native Wix page named
**Mem-Mem Privacy Policy**, hidden from the main menu, with URL slug
`mem-mem-privacy`. Desktop and mobile previews were checked, including section
headings and the policy ending. The live public page was verified on September
22, 2026, without a site login:
https://www.ailearningcenter.ai/mem-mem-privacy.
The owner explicitly approved inserting the full policy into Wix, including the
LLC name, support email and data-practice disclosures. The earlier automatic
approval rejection is resolved.

The owner explicitly authorized publishing all saved website changes, including
the pre-existing September 10 and 14 revisions. Wix confirmed the site is
published and live online. Those drafts were neither restored nor discarded.

The page copy is in [privacy-policy.md](privacy-policy.md). This file contains
internal notes only and must not be pasted into the public page.

## Confirmed publication details

- Operator: SERPICO ENTERPRISES, L.L.C., publishing as Plan 9 from Outer Space,
  matches the observed Play and AdMob organization. Owner approved its inclusion.
- Support email: vincent.serpico@ailearningcenter.ai, confirmed by the owner.
- Intended audience: adults 18+, primarily adult women; United States launch only.
- A 90-day support-email retention policy after resolution was proposed to the
  owner, with legal/dispute exceptions. No approval received yet. The prepared
  copy currently uses purpose-based retention criteria and does not assert a
  configured 90-day deletion schedule.
- Initial publication: September 22, 2026. Current effective date and update:
  September 23, 2026.

## Wix page

- Site: ailearningcenter.ai, the destination of the owner's serpico.ai domain.
- Page title: **Mem-Mem Privacy Policy**.
- URL slug: **mem-mem-privacy**.
- Published URL: https://www.ailearningcenter.ai/mem-mem-privacy.
- Use a normal public page with selectable text and working links, without a
  password or members-only restriction. Preserve the website's existing policy.
- Desktop and mobile previews have been inspected. The policy uses a centered
  800-pixel desktop text column, 16-pixel body text, a prominent title, bold section
  headings and added space before each section. Wix adapts it to mobile width.
- The published page exposes both Google policy URLs and the contact email as
  links with the correct HTTPS and mailto destinations.
- Wix confirmed "Your changes are saved." Site History recorded the latest save
  on September 22, 2026, at 7:30 PM (as displayed by Wix).
- Public access and full policy text were verified after publication. The local
  `privacy_url` in `.tools/store/config.json` now points to the live page.
- The same URL is saved in Play Console. Console confirmed the change is saved
  and awaits submission through Publishing overview. No app release or review
  submission was performed as part of publishing the website policy.

## Release checks

- The verifier is now deployed to Cloud Run in `mem-mem-509517`, with 30-day
  operational log retention, no purchase/redemption database, and no request-body
  logging. See [deployment](cloud-deployment.md). The existing public policy
  now names Google Cloud Run and the normal 30-day request-log retention,
  with incident/legal/dispute exceptions.
- Do not log verification request bodies or token-bearing upstream URLs.
- Google Mobile Ads 24.9.0 and UMP 3.2.0 are pinned in the project. Review the
  actual merged release manifest and dependency graph before store submission.
- The app requests non-personalized ads and disables the plugin first-party ID.
  Neither setting justifies claiming that the SDK collects no data.
- Adult-audience flags are set and **18 and over** is saved in Play Console.
- AdMob **Mem-Mem US privacy choices** is published for all current and future
  supported US states. Its choice descriptions now reflect non-personalized ads.
  Test Settings → Privacy choices before production.
- U.S. store distribution does not prove that a user never travels abroad; test
  consent failure behavior and keep advertising blocked when permission is absent.
- No purchase-verification hosting or ad approval is implied by publication of
  this policy. Align final Data safety responses with the released SDKs and host.

## Evidence

- `game/gameplay/progress_store.gd`: local game progress.
- `game/services/native/native_billing.gd`: installation ID, verification request,
  receipt caching and restoration.
- `game/services/native/verified_entitlement.gd`: signature and seven-day access
  validation. Authorization expiry is not a claim of file deletion.
- `game/services/native/admob_bridge.gd`: non-personalized requests and ID settings.
- `game/services/native/native_consent.gd` and `android/consent/MemMemConsent.java`:
  consent and privacy choices.
- `server/server.mjs`, `server/verifier.mjs`, `server/play.mjs`: request processing,
  in-memory verification and sanitized application logging.
- [Google Mobile Ads data disclosure](https://developers.google.com/admob/android/privacy/play-data-disclosure).
- [Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en).
- [AdMob US state privacy messages](https://support.google.com/admob/answer/10862202?hl=en).
# September 23 addendum published

The owner authorized publication. Wix confirmed publication, and the public page
was independently reloaded and verified with the September 23 effective date,
access-code section and 30-day routine request-log retention. Desktop and mobile
previews were inspected. Existing Google-policy and support-email links remain
correct. The current published copy is in `privacy-policy.md`. The signed bundle
is now available on the internal testing track.

## Provided access codes

If we provide an access code, the app sends that code, a randomly generated
installation identifier, and a request-validation value to our verification
service over HTTPS to confirm access. The service checks the code and returns a
digitally signed receipt valid for up to seven days. We do not store submitted
codes in application logs or a redemption-history database. The app stores the
receipt on your device, not the code. You can remove code-based access in the app
or clear Android app storage. Hosting providers may process operational request
information as described under Support and service operations.
