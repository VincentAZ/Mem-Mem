# Data safety declaration

Saved in Play Console September 23, 2026, for signed bundle 0.7.0 (11).
The expanded preview was reviewed before saving. This is a saved declaration,
not approval by Google or a production launch.

## Saved answers

The app collects/shares data, uses encrypted transport, has no account creation
and does not sign users into outside accounts. A reusable access code is not an
account. The deletion-request link is the published Mem-Mem privacy policy,
which provides the privacy contact, local deletion instructions and limits for
Google-held records. No independent security-review badge is claimed.

- **Approximate location:** collected and shared; required; not ephemeral.
  Purposes: analytics, advertising, and fraud prevention/security/compliance.
  IP-based region processing applies to consent and advertising; the app does
  not request precise location permission.
- **Device or other IDs:** collected and shared; required; not ephemeral.
  Same purposes, plus app functionality for collection. Includes Google SDK
  identifiers and the installation identifier used by entitlement verification.
  Advertising-ID deletion does not disable every other identifier.
- **App interactions** and **Diagnostics:** collected and shared; optional;
  not ephemeral. Purposes: analytics, advertising, fraud prevention/security/
  compliance. The app initializes Mobile Ads for the user-selected rewarded ad
  flow. It does not upload game progress or use a separate analytics/crash SDK.
- **Purchase history:** collected; optional; not ephemeral. Purposes: app
  functionality and fraud prevention/security/compliance. The verifier itself
  processes requests in memory; Google Play retains purchase records. Purchase
  processing and hosting service-provider transfers are not declared as separate
  third-party sharing. No payment-card data reaches the app/backend.

No contacts, files, messages, photos, microphone, health, precise location, or
user-created content are collected by the game.

## Evidence and release checks

The actual merged bundle manifest targets API 36, minimum 26, with BILLING and
Google advertising-ID permissions. It contains the production AdMob application
ID, native billing and MemMemConsent integrations. Mobile Ads is pinned to
24.9.0, the plugin is 7.0, and UMP is 3.2.0.

[Google's Mobile Ads disclosure guidance](https://developers.google.com/admob/android/privacy/play-data-disclosure)
lists automatic IP-based location, interactions, diagnostics and identifiers,
with TLS and advertising/analytics/fraud purposes. The current page describes
25.5.0, so it is not an exact-version audit of the pinned release. The declaration
uses those documented categories together with the app's actual integration.
Recheck the declaration after any SDK upgrade and during live ad/consent testing;
do not treat these saved answers as evidence that all SDK network paths were
independently observed.

Cloud Run request logs retain operational data for 30 days. App logs exclude
request bodies and credentials; no purchase/redemption database exists. See
[deployment](cloud-deployment.md) and [privacy policy](privacy-policy.md).
The access-code addendum, Cloud Run provider and 30-day routine request-log
retention were published and verified September 23; see [publication notes](privacy-policy-draft.md).
