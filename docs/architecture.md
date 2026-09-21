# Game architecture

## Rules, generation, and rendering

`LevelGenerator` creates deterministic boards from a journey seed and level number.
Generator 3 repeats 3, 4, 4, 6, 4, 3, 6, 8, 4, 6, 8, 4 pairs. The corresponding
lookalike-family counts are 0, 0, 1, 2, 1, 0, 2, 2, 1, 3, 4, 1. Sixteen-card boards
use four columns; twelve-card boards use three; smaller boards use two. At least
two lookalike families let eight pairs fit within a six-character theme.
Four themes rotate, with a mixed cast every fifth level unless the player pins a
theme. Every matching identity occurs exactly twice. Generators 1 and 2 retain the
old six-level wave and exact seeded layouts for existing saves. No runtime AI is
involved. Cosmetics and presentation randomness cannot alter scoring/layout.

`MatchRound` owns the fixed shuffled positions, selected/removed indexes, comparison
count, and opening phase. It rejects input during preview or two-card resolution,
self-matches, and taps on removed tiles. A mismatch increments the comparison count;
resolving it clears both selections. Matches commit removed indexes before animation.

`GameScreen` presents a longer shuffle, the 0.5-second preview of the final positions,
conceal, input, walking departures,
persistent completion card, and explicit Next level button. Animation never awards points or determines
ownership. A generation counter prevents stale asynchronous callbacks from touching a
later board. The last departure completes before the result appears. `CheerLineup`
brings back all 6–16 tile characters, including both members of each pair. They walk
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

Schema 3 payloads contain the journey seed, current level, exact board, removed pairs,
comparison count, opening status, completed-level points, preferences, collection
ownership, saved choice tokens, and the last settled reward level. Retired discovery
fields remain readable solely for compatibility with earlier saves.
Validation regenerates the board and checks pair integrity, integer ranges, and score
bounds. Transient selections are cleared on process restart. An interrupted opening
repeats its preview; an interrupted completion restores its result and cheering cast,
then waits for Next level. Schema 1 migrates explicitly: absent generation means
legacy generator 1, current positions stay unchanged, and collection/settings fields
start at their defaults. Sound retains the earlier optional-field migration. The
next board uses generator 3 and the selected theme. Schema 2 keeps all existing
collection and appearance fields. The new `expanded_from_level` boundary records
the first expanded-wave board. Bank bounds sum old-wave pairs before that boundary
and new-wave pairs afterward, counting only completed levels. The boundary must
agree with the saved round's generator; invalid or contradictory values are rejected. Rewards are not invented for
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
requiring a valid, unowned character ID and a positive credit balance. The earlier
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
selection starts a preview burst without granting ownership; the successful saved
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

`PeopleCatalog` defines 24 collectable character IDs and 48 match IDs. Eight PNG
atlases cover four themes in neutral and delighted/cheering poses. Atlas bounds are
in `AtlasRegions`; portrait and walking art share the source. Accessories are
code-controlled, so paired variants differ only in the comparison detail.
`Walker` uses textured cutouts with continuous leg, bounce, and sway motion. Entry
and exit sides, split routes, phases, and cheer styles vary independently of rules.

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

- `BillingService`: `purchase`, `restore`, state messages, and entitlement changes.
- `AdsService`: load/show, consent/ownership gating, and invalidation of loaded ads.
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
plugin's fixed Google demo interstitial unit. The lab's explicit demo-ad action
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
