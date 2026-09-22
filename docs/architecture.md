# Game architecture

## Rules, generation, and rendering

`LevelGenerator` creates deterministic boards from a journey seed and level number.
Generator 4 repeats 2, 3, 4, 3, 6, 2, 4, 3, 8, 2, 4, 3 pairs. Both hard board
sizes (12 and 16 cards) are immediately followed by four cards. The wave is anchored
at the saved `easy_from_level`, starting after the current board for migrated users.
Sixteen cards use four columns, twelve use three, and smaller boards use two.

Each of seven themes has eight unique characters. The first four themes are free;
Plus unlocks the other three. A round snapshots its eligible theme pool, so an
entitlement change cannot invalidate its exact board. Mixed boards use only that
pool. Generators 1–3 still regenerate historical matching IDs and layouts. A
bijective display mapping reserves each original person, then replaces duplicate
variants with unused same-theme characters in sorted legacy-ID order. No two
different pairs have the same visible character. New boards match stable character
IDs directly. No runtime AI is involved.

`MatchRound` owns the fixed shuffled positions, selected/removed indexes, comparison
count, and opening phase. It rejects input during preview or two-card resolution,
self-matches, and taps on removed tiles. A mismatch increments the comparison count;
resolving it clears both selections. Matches commit removed indexes before animation.

`GameScreen` presents a longer shuffle, the 0.5-second preview of the final positions,
conceal, input, walking departures,
persistent completion card, and explicit Next level button. Animation never awards points or determines
ownership. A generation counter prevents stale asynchronous callbacks from touching a
later board. The last departure completes before the result appears. `CheerLineup`
brings back all 4–16 tile characters, including both members of each pair. They walk
in on varied left/right/split routes, then cheer in one or two rows around the unchanged score/accuracy
result. Only Next level advances; it locks immediately against repeated taps.
There is no share control in this milestone.

## Score and progression

Every pair contributes 100 points. Completing a level adds
`floor(20 × pair_count × pair_count / comparisons)` as an accuracy bonus.
A perfect three-pair board earns 360 points; four comparisons earn 345. Mismatches
never deduct earned points. There is no time, life, combo, or spending requirement.

The total is completed-level points plus the active round's derived points. Advancing
moves the completed round into the bank and creates the next round together. Advancing
an incomplete or resolving round is rejected. Repeated taps, callbacks, and reloads
therefore cannot double-award the same match or completion bonus.

The twelve-level wave repeats with newly seeded boards, providing variety without an
unbounded increase in visual difficulty. The catalog and generator are replaceable;
these are initial tuning values to refine with real play sessions.

## Persistence and lifecycle

`ProgressStore` alternates `progress.0.json` and `progress.1.json`. Each file contains a
revision, serialized payload, and SHA-256 checksum. Writes flush a sibling temporary
file and rename it into one slot. On load, the highest valid revision wins; if damaged,
the older intact slot recovers progress. This detects accidental corruption, not cheating.
Both invalid slots result in a fresh journey with a visible notice. A failed write
leaves existing saves intact and displays a save warning without blocking play.

Schema 4 payloads contain the journey seed, current level, exact board, removed pairs,
comparison count, opening status, completed-level points, preferences, collection
ownership, saved choice tokens, and the last settled reward level. Retired discovery
fields remain readable solely for compatibility with earlier saves.
Validation regenerates the board and checks pair integrity, integer ranges, and score
bounds. Transient selections are cleared on process restart. An interrupted opening
repeats its preview; an interrupted completion restores its result and cheering cast,
then waits for Next level. Schema 1 migrates explicitly: absent generation means
legacy generator 1, current positions stay unchanged, and collection/settings fields
start at their defaults. Sound retains the earlier optional-field migration. The
next board uses generator 4 and its snapshotted unlocked theme pool. Schema 4 adds
`easy_from_level`, round `wave_start`, `theme_pool`, `peek_earned`, and `peek_used`.
The existing `expanded_from_level` still separates generations 1/2 from 3.
Bank bounds sum pairs in all historical intervals, plus the new wave anchored at
`easy_from_level`. Both boundaries must agree with the current round generation.
Paid ownership is runtime service state, deliberately absent from progress saves.
 Rewards are not invented for
historical completed levels. The current completed board can settle its reward.
No time-based callback advances a level or awards score.

Checkpoints occur before the first preview, after opening, immediately after every
comparison, at level transition, on preference changes, pause, background, and close.
Phase 1's fixture save is retained but does not become real progression or points.
Test fixtures use separate save prefixes and cannot replace the player's journey.

User pause, backgrounding, development lab, and simulated full-screen ads are separate
pause reasons. Clearing one reason never overrides another. Timers and tweens pause
with gameplay; pause/lab controls remain interactive. Reduced motion uses immediate
reveals, no spatial shuffle/departure, and a short fade. The returning cast appears
in a still cheering pose with animation processing disabled. Pausing freezes animated
cheers; changing motion preferences updates the cast immediately. Android match
haptics are optional. Turning reduced motion on settles an active
card flip to its intended face and removes active walking/point/spark effects.

## Collection and presentation

`GameProgress.settle_collection_reward()` handles each cleared board at most once,
using the saved reward-level marker. Exact perfect accuracy (`attempts == matches`)
grants one bankable choice. Imperfect rounds grant no collection reward. Board
completion never picks or collects a character: only an explicit claim adds ownership,
requiring a valid, unowned character from an unlocked theme and a positive credit balance. The earlier
every-third-board surprise reward was removed in 0.5.1. Already collected characters
and banked choices are preserved; old discovery counters cannot trigger new awards.

`CollectionPanel` opens My collection from the persistent bottom navigation; result
cards open Discover all for claiming rewards. Both views filter by theme.
`CollectionCard` presents full-body characters: owned cards have a gold stage, border,
corner diamonds, an explicit ownership label and an animated cheering pose. Unowned
cards use neutral surfaces and still poses. Collection runs while gameplay pauses,
but stops animations offscreen, when hidden, in the background, or with Reduce motion.
Claims require an explicit Collect button after selection.

`CollectionFireworks` is one reusable, input-transparent effect layer. Eligible card
selection starts a preview burst and a short jump-and-clap without granting ownership; the successful saved
claim starts a second burst after the refreshed layout settles. Navigation cancels
stale deferred celebrations, and save failures cannot trigger confirmation effects.
`CollectionPerformer` uses the existing cutout art for three dances and two raised-arm
wave variations. Clapping poses use dances. Reactions avoid immediate repeats per
character; rapid taps are throttled and reuse the same actor. They never modify the
progress model. Reduce motion substitutes still captions and fading static sparkles.

The collection owns a separate four-voice `GameAudio` pool that explicitly allows
UI sounds while gameplay is paused. Its visibility/background gate still suppresses
all playback, and it reads the saved sound preference. The main gameplay audio pool
keeps its normal pause gate. Closing, filtering or backgrounding stops collection
sounds; returning does not replay an interrupted sound or performance.
 `GameScreen` saves ownership and credit
consumption together, rolling back only those two fields if a write fails; it never
replaces the live round or its in-flight selection. All-owned collections preserve
extra credits. The feature is local game progression, independent of paid ownership.

`PeopleCatalog` defines 56 stable IDs. IDs 0–23 retain their old meaning. IDs
24–31 add two characters to each original theme; IDs 32–55 are the new paid themes.
Twenty-four PNG atlases supply neutral, delighted and collection-clapping poses. `AtlasRegions` preserves
original bounds; `ExpandedAtlas` contains measured alpha bounds for the new sheets.
Explicit theme-member lists and artwork groups map stable IDs to atlas regions,
portrait framing, and walk/hop/float profiles. They do not infer theme or atlas
membership from character-number arithmetic. Atlases load on demand into a shared
strong-reference cache. Accessory overlays are unused.
`Walker` preserves whole nonhuman silhouettes; only human figures use leg strips.

`GameStyle` centralizes surfaces, button states and accent colors. The HUD uses three
equal-width statistic columns with a highlighted round score centered on the screen.
Collection and Settings remain visible in the bottom navigation. Settings groups
Appearance, Sound & Motion, and the next-board cast; opening it pauses the game.
`GamePalette` and `GameBackdrop` apply four backgrounds in light/dark modes.
Settings persist immediately and do not restart the current board. Reduced motion
omits walking and sparks and keeps static cheer poses. Sound has a four-voice pool,
six short interaction cues (including the extended card riffle), and three crowd
variants that avoid consecutive repeats. Muting and overlays/backgrounding stop
voices immediately. A restored result does not replay reward audio. See the asset
credits and prompt record for generated images and CC0 recording provenance.

## Services

- `BillingService`: purchase/restore, product information, Plus entitlement, and unlocked themes.
- `AdsService`: interstitial and rewarded load/show, board/request IDs, earned-reward events, consent/ownership gates, and cancellation.
- `ConsentService`: request status/show form, availability, and ad-request permission.

The lab injects simulated implementations. Fake ownership is explicitly named
`simulated_ownership.json`; the native billing adapter never reads it. Pending,
cancelled, and failed purchases cannot grant ownership. Ad ownership changes
invalidate pending loads, so late callbacks cannot resurrect a suppressed ad.

Native adapters are separate nodes. `NativeBilling` can connect/query Google Play,
but `purchase()` is unconditionally disabled. Returned store records are marked as
requiring verification; they are not acknowledged or granted in this foundation.
Purchase tokens are not logged. Production requires server verification and a
proper purchase-processing lifecycle before enabling transactions.

`AdmobBridge` lazily creates the plugin node on Android. `NativeAds` uses only the
plugin's fixed Google demo interstitial and rewarded units. The lab's explicit demo-ad action
permits demo traffic without claiming a successful UMP flow; the independent
`NativeConsent` controls exercise actual UMP status and form APIs. This shortcut
must never be carried into a production advertising path. Production consent and
entitlement verification are required before production ad units can be introduced.

Missing platform singletons report unavailable and leave gameplay running. The
Android build includes the native plugins even though the default scene uses
simulations. No billing, ad, or consent operation runs automatically during a level.

## Deferred work

Physical-device tuning and further art feedback, additional themes, paid packs,
verified purchase processing, production ads, analytics, and iOS export remain future
work. Native purchases are still disabled. Device playtesting will guide further
pacing, readability, and difficulty tuning.

## Quick Peek and test monetization

`MatchRound` owns the earned/consumed allowance and blocks input during Peek.
A single use reveals unmatched cards for 0.5 fully visible foreground seconds,
excluding flips. The first selection is preserved. Consumption is checkpointed
before reveal; a failed checkpoint leaves the allowance usable. Restart ends any
transient reveal without restoring a consumed allowance. Background hides the board
and pauses the reveal timer. Ads never change attempts, points or perfect eligibility.

The default debug experience uses `SimulatedBilling` for the complete Plus bundle
under the permanent `remove_ads` product. Pending/cancelled/failed operations grant
nothing. The UI labels every purchase simulation; native purchasing stays disabled.
Plus restores theme access, automatic per-board peeks and complete ad suppression.
Already earned collection ownership remains local and survives entitlement loss.

`NativeAds` places a unique non-personal request token in the test rewarded request's
custom data and validates callbacks against it. Only `rewarded_ad_user_earned_reward`
grants an allowance, once per request and once per board. Dismissal grants nothing.
Cancellation invalidates pending requests and cached ads. An explicit test permission
allows Google's demo traffic; it is not a production UMP consent implementation.
The UI returns to a Ready button after reward rather than automatically peeking.
No ads or purchases are automatically shown during play.

The selection-clap routine uses a continuous 2D mesh over a dedicated clapping pose,
with repeated short jumps and subtle forearm pulses. Faces and silhouettes stay
intact. Eligible unowned selections can run this routine while the game is paused;
ordinary unowned cards remain still. Deselection, hiding, offscreen scrolling and
backgrounding end it. Reduce motion keeps a still cheering pose and reaction caption.
