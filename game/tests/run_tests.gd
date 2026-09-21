extends SceneTree
var checks: int = 0
var failures: int = 0

class AdCacheStub extends Node:
	var cached: int = 0
	var invalid_removals: int = 0
	func is_interstitial_ad_loaded() -> bool:
		return cached > 0
	func remove_interstitial_ad() -> void:
		if cached == 0:
			invalid_removals += 1
		else:
			cached -= 1

class RewardRequestStub extends RefCounted:
	var token: String = ""
	func set_custom_data(value: String) -> void:
		token = value
	func get_custom_data() -> String:
		return token

class RewardInfoStub extends RefCounted:
	var id: String = ""
	var request: RewardRequestStub
	func get_ad_id() -> String:
		return id
	func get_load_ad_request() -> RewardRequestStub:
		return request

class RewardSDKStub extends Node:
	signal initialization_completed(info: Variant)
	signal rewarded_ad_loaded(ad: Variant, info: Variant)
	signal rewarded_ad_failed_to_load(ad: Variant, error: Variant)
	signal rewarded_ad_failed_to_show_full_screen_content(ad: Variant, error: Variant)
	signal rewarded_ad_dismissed_full_screen_content(ad: Variant)
	signal rewarded_ad_user_earned_reward(ad: Variant, reward: Variant)
	var is_initialization_completed: bool = true
	var request: RewardRequestStub
	var cached: Array[String] = []
	var shown: String = ""
	func create_rewarded_ad_request() -> RewardRequestStub:
		return RewardRequestStub.new()
	func load_rewarded_ad(value: RewardRequestStub) -> void:
		request = value
	func is_rewarded_ad_loaded() -> bool:
		return not cached.is_empty()
	func remove_rewarded_ad(id: String = "") -> void:
		if id.is_empty():
			cached.pop_back()
		else:
			cached.erase(id)
	func show_rewarded_ad(id: String) -> void:
		shown = id
	func is_interstitial_ad_loaded() -> bool:
		return false

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("TEST FAILED: " + description)

func _run() -> void:
	_test_round()
	_test_progress()
	_test_expanded_progress()
	_test_collection()
	_test_easier_boards()
	_test_peek_rules()
	_test_audio()
	_test_native_ad_cleanup()
	_test_native_rewarded_callbacks()
	await _test_services()
	await _test_rewarded_services()
	print("%d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_native_ad_cleanup() -> void:
	var bridge: AdmobBridge = AdmobBridge.new()
	var sdk: AdCacheStub = AdCacheStub.new()
	var ads: NativeAds = NativeAds.new()
	root.add_child(bridge)
	bridge.add_child(sdk)
	bridge.sdk = sdk
	root.add_child(ads)
	ads.bridge = bridge
	ads.set_consent_allowed(false)
	check(sdk.invalid_removals == 0, "native consent gate never removes a nonexistent SDK ad")
	sdk.cached = 2
	ads.loaded = true
	ads.set_ad_free(true)
	check(sdk.cached == 0 and not ads.loaded, "native restoration drains every cached ad")
	ads.set_ad_free(true)
	check(sdk.invalid_removals == 0, "repeated native invalidation is safe")
	ads._load_failed(null, null)
	check(ads.state == "suppressed", "late native failure preserves suppression status")
	ads.queue_free()
	bridge.queue_free()

func _test_round() -> void:
	for seed_number: int in range(16):
		for level: int in range(1, 19):
			var model: MatchRound = MatchRound.create(level, seed_number, 3)
			check(model.select(0) == "ignored", "preview blocks input")
			check(model.identities.size() == LevelGenerator.pair_count(level, 3) * 2, "wave controls board size")
			check(model.identities != model.preview, "shuffle changes arrangement")
			check(model.identities == MatchRound.create(level, seed_number, 3).identities, "seed reproduces the exact board")
			var counts: Dictionary = {}
			for identity: int in model.identities:
				counts[identity] = int(counts.get(identity, 0)) + 1
			for count: int in counts.values():
				check(count == 2, "every identity has exactly one mate")
			var twins: int = 0
			for family: int in range(24):
				if counts.has(family * 2) and counts.has(family * 2 + 1):
					twins += 1
			check(twins == LevelGenerator.LOOKALIKES[(level - 1) % LevelGenerator.LOOKALIKES.size()], "lookalike difficulty follows the wave")
			model.begin_play()
			var layout: Array[int] = model.identities.duplicate()
			for identity: int in counts:
				var first: int = model.identities.find(identity)
				var mate: int = model.identities.rfind(identity)
				check(model.select(first) == "first", "first tap reveals")
				check(model.select(first) == "ignored", "self match rejected")
				check(model.select(mate) == "match", "exact pair matches")
				check(model.select((first + 1) % model.identities.size()) == "ignored", "third rapid tap rejected")
				var restored: MatchRound = MatchRound.from_snapshot(model.snapshot())
				check(restored != null and restored.points() == model.points(), "interrupted match retains exact points")
				check(restored.selected.is_empty() and not restored.resolving, "transient reveals reset on process restart")
				check(restored.select(first) == "ignored", "restored match cannot earn points again")
				model.finish_resolution()
			check(model.complete(), "all generated boards are clearable")
			check(model.attempts == counts.size(), "attempts count pairs, not taps")
			check(model.points() == counts.size() * 120, "perfect accuracy bonus capped at 20 percent")
			check(model.identities == layout, "positions never move during play")
	var model: MatchRound = MatchRound.create(3, 44, 3)
	model.begin_play()
	var other: int = 1
	while model.identities[other] == model.identities[0]:
		other += 1
	check(model.select(0) == "first" and model.select(other) == "mismatch", "mismatch recognized")
	check(model.attempts == 1 and model.points() == 0, "mismatch records an attempt without losing points")
	var interrupted: MatchRound = MatchRound.from_snapshot(model.snapshot())
	check(interrupted.attempts == 1 and interrupted.selected.is_empty(), "mismatch attempt persists through termination")
	model.finish_resolution()
	check(model.selected.is_empty() and model.removed.is_empty(), "both mismatch selections clear")
	_clear_round(model)
	check(model.points() == 400 + floori(80.0 * 4.0 / 5.0), "accuracy bonus uses matches divided by comparisons")
	var invalid: Dictionary = model.snapshot()
	invalid.removed = [0]
	check(MatchRound.from_snapshot(invalid) == null, "partial removed pair rejected")
	invalid.removed = [0, 0]
	check(MatchRound.from_snapshot(invalid) == null, "duplicate removed index rejected")
	invalid = model.snapshot()
	invalid.identities[0] = 1.5
	check(MatchRound.from_snapshot(invalid) == null, "fractional identity rejected")
	invalid = model.snapshot()
	invalid.attempts = 0
	check(MatchRound.from_snapshot(invalid) == null, "score cannot exceed number of attempts")
	invalid = model.snapshot()
	invalid.opening = true
	check(MatchRound.from_snapshot(invalid) == null, "opening phase cannot contain earned points")

func _clear_round(model: MatchRound) -> void:
	model.begin_play()
	for index: int in range(model.identities.size()):
		if model.removed.has(index):
			continue
		model.select(index)
		model.select(model.identities.rfind(model.identities[index]))
		model.finish_resolution()

func _test_progress() -> void:
	var progress: GameProgress = GameProgress.create(993)
	check(not progress.advance(), "cannot skip an unfinished level")
	var previous_score: int = 0
	for level: int in range(1, 31):
		_clear_round(progress.round_state)
		var before: int = progress.total_points()
		check(before > previous_score, "score grows across levels")
		var restored: GameProgress = GameProgress.from_snapshot(progress.snapshot())
		check(restored != null and restored.round_state.complete(), "completed level persists before transition")
		check(restored.round_state.level == level and restored.total_points() == before, "restored completion remains on its level without granting again")
		check(restored.advance() and restored.total_points() == before, "explicit advance settles completed level once")
		check(not restored.advance() and restored.total_points() == before, "duplicate advance cannot award again")
		check(progress.advance() and progress.total_points() == before, "live and restored score agree")
		check(progress.round_state.identities == restored.round_state.identities, "next board survives transition restart")
		check(progress.round_state.level == level + 1, "explicit advance increments exactly once")
		previous_score = before
	check(LevelGenerator.pair_count(6) < LevelGenerator.pair_count(5), "wave includes a breather")
	var invalid: Dictionary = progress.snapshot()
	invalid.banked_points += 100000
	check(GameProgress.from_snapshot(invalid) == null, "impossible bank balance rejected")
	invalid = progress.snapshot()
	invalid.version = 999
	check(GameProgress.from_snapshot(invalid) == null, "future schema rejected")
	invalid = progress.snapshot()
	invalid.round = []
	check(GameProgress.from_snapshot(invalid) == null, "wrong round type rejected")
	progress.reduced_motion = true
	progress.haptics = false
	progress.sound = false
	var legacy: Dictionary = progress.snapshot()
	legacy.erase("sound")
	var migrated: GameProgress = GameProgress.from_snapshot(legacy)
	check(migrated != null and migrated.sound, "Phase 2 saves default sound on")
	check(migrated.total_points() == progress.total_points() and migrated.round_state.snapshot() == progress.round_state.snapshot(), "adding sound preserves an old save's exact board and score")
	for bad_sound: Variant in [null, "false", 0, [], {}]:
		invalid = progress.snapshot()
		invalid.sound = bad_sound
		check(GameProgress.from_snapshot(invalid) == null, "malformed sound preference rejected")
	var store: ProgressStore = ProgressStore.new()
	store.prefix = "user://unit_test_progress"
	for suffix: String in [".0.json", ".1.json", ".0.json.tmp", ".1.json.tmp"]:
		DirAccess.remove_absolute(store.prefix + suffix)
	check(store.load_progress() == null, "missing saves start fresh")
	check(store.save(progress), "atomic first checkpoint writes")
	progress.round_state.begin_play()
	check(store.save(progress), "alternate checkpoint writes")
	var reader: ProgressStore = ProgressStore.new()
	reader.prefix = store.prefix
	var loaded: GameProgress = reader.load_progress()
	check(loaded != null and not loaded.round_state.opening, "latest valid checkpoint wins")
	check(loaded.total_points() == progress.total_points() and loaded.reduced_motion and not loaded.haptics, "score and preferences persist")
	check(not loaded.sound, "muted sound survives saved progress reload")
	var corrupt: FileAccess = FileAccess.open(store.prefix + ".0.json", FileAccess.WRITE)
	corrupt.store_string("interrupted or corrupt data")
	corrupt.close()
	loaded = reader.load_progress()
	check(loaded != null and loaded.round_state.opening and reader.recovered, "corrupt latest checkpoint falls back safely")
	check(reader.save(loaded), "recovery replaces the damaged slot")
	check(reader.load_progress().total_points() == progress.total_points(), "recovered score does not duplicate")
	var failing: ProgressStore = ProgressStore.new()
	failing.prefix = "user://directory_that_does_not_exist/progress"
	check(not failing.save(progress), "save failure is returned to the UI")
	for suffix: String in [".0.json", ".1.json", ".0.json.tmp", ".1.json.tmp"]:
		DirAccess.remove_absolute(store.prefix + suffix)

func _test_collection() -> void:
	var p: GameProgress = GameProgress.create(77)
	check(not p.settle_collection_reward() and not p.collect_character(0), "unfinished board cannot grant a collectible")
	_clear_round(p.round_state)
	check(p.settle_collection_reward() and p.choice_tokens == 1, "perfect accuracy earns one free choice")
	check(not p.settle_collection_reward() and p.choice_tokens == 1, "repeat completion cannot award another choice")
	p = GameProgress.from_snapshot(p.snapshot())
	check(not p.settle_collection_reward() and p.choice_tokens == 1, "completed reward survives reload without duplication")
	check(p.collect_character(23) and p.collected == [23] and p.choice_tokens == 0, "choice can collect ANY character from another theme")
	check(not p.collect_character(23) and not p.collect_character(-1) and not p.collect_character(24), "duplicates and invalid choices cannot spend credits")
	p.advance()
	check(p.round_state.identities.all(func(id: int) -> bool: return PeopleCatalog.theme_of(id) == 1), "second board introduces firefighters")
	p.round_state.begin_play()
	var other: int = 1
	while p.round_state.identities[other] == p.round_state.identities[0]:
		other += 1
	p.round_state.select(0)
	p.round_state.select(other)
	p.round_state.finish_resolution()
	_clear_round(p.round_state)
	p.settle_collection_reward()
	check(p.choice_tokens == 0 and p.collected == [23], "imperfect board grants neither a choice nor a character")
	p.advance()
	_clear_round(p.round_state)
	p.settle_collection_reward()
	check(p.choice_tokens == 1 and p.collected == [23], "third board earns only a perfect choice and never auto-selects a character")
	var snapshot: Dictionary = p.snapshot()
	var loaded: GameProgress = GameProgress.from_snapshot(snapshot)
	check(loaded != null and loaded.snapshot() == snapshot and not loaded.settle_collection_reward(), "ownership and earned choices persist exactly once")
	p.dark_mode = true
	p.background = 3
	p.preferred_theme = 3
	loaded = GameProgress.from_snapshot(p.snapshot())
	check(loaded.dark_mode and loaded.background == 3 and loaded.preferred_theme == 3, "appearance and chosen theme survive reload")
	loaded.advance()
	check(loaded.round_state.identities.all(func(id: int) -> bool: return PeopleCatalog.theme_of(id) == 3), "preferred theme takes effect on next board")
	for key: String in ["collected", "choice_tokens", "reward_level", "background", "preferred_theme", "dark_mode", "discovery_steps", "last_discovery"]:
		var corrupt: Dictionary = p.snapshot()
		corrupt[key] = "invalid"
		check(GameProgress.from_snapshot(corrupt) == null, "invalid collection/settings field rejected: " + key)
	var duplicate: Dictionary = p.snapshot()
	duplicate.collected = [23, 23]
	check(GameProgress.from_snapshot(duplicate) == null, "duplicate collection IDs rejected")
	# A real schema-1 fixture lacks both generation and collection fields.
	var legacy: GameProgress = GameProgress.create(4815)
	legacy.round_state = MatchRound.create(4, 4815, 1)
	legacy.banked_points = LevelGenerator.completed_pairs(3, 2) * 120
	legacy.round_state.begin_play()
	var old: Dictionary = {"version": 1, "seed": legacy.seed_value, "banked_points": legacy.banked_points, "round": legacy.round_state.snapshot(), "reduced_motion": false, "haptics": true, "sound": false}
	old.round.erase("generation")
	old.round.erase("chosen_theme")
	loaded = GameProgress.from_snapshot(old)
	check(loaded != null and loaded.round_state.identities == legacy.round_state.identities and loaded.total_points() == legacy.total_points(), "schema-1 board and score migrate unchanged")
	check(loaded.round_state.generation == 1 and not loaded.sound and loaded.collected.is_empty(), "legacy generation and settings preserved without invented rewards")
	_clear_round(loaded.round_state)
	loaded.advance()
	check(loaded.round_state.generation == 4, "migrated player enters new generator only after the old board")
	# Regression: 50% accuracy at the old three-board threshold must never collect.
	var imperfect: GameProgress = GameProgress.create(211)
	for level: int in range(1, 7):
		imperfect.round_state.begin_play()
		var nonmatch: int = 1
		while imperfect.round_state.identities[nonmatch] == imperfect.round_state.identities[0]:
			nonmatch += 1
		for attempt: int in range(imperfect.round_state.identities.size() / 2):
			imperfect.round_state.select(0)
			imperfect.round_state.select(nonmatch)
			imperfect.round_state.finish_resolution()
		_clear_round(imperfect.round_state)
		imperfect.discovery_steps = 2 # Existing saves can be one board from the retired reward.
		check(imperfect.round_state.accuracy() == 0.5, "regression fixture reaches exactly 50 percent accuracy")
		check(imperfect.settle_collection_reward(), "50 percent completion settles once")
		check(imperfect.choice_tokens == 0 and imperfect.collected.is_empty(), "50 percent never grants a choice or auto-collects, including every third board")
		imperfect = GameProgress.from_snapshot(imperfect.snapshot())
		check(imperfect != null and not imperfect.settle_collection_reward() and imperfect.collected.is_empty(), "reloading an imperfect result cannot award a character")
		imperfect.advance()
	_clear_round(imperfect.round_state)
	imperfect.settle_collection_reward()
	check(imperfect.choice_tokens == 1 and imperfect.collected.is_empty(), "100 percent offers a choice without choosing for the player")
	imperfect.advance()
	imperfect = GameProgress.from_snapshot(imperfect.snapshot())
	check(imperfect.choice_tokens == 1 and imperfect.collected.is_empty(), "advancing and restarting bank an unclaimed choice without auto-selection")
	check(imperfect.collect_character(17) and imperfect.collected == [17], "only the player's explicit selection adds their chosen character")
	# Preserve old ownership, including surprise characters, without replaying old rewards.
	var historical: Dictionary = imperfect.snapshot()
	historical.discovery_steps = 2
	historical.last_discovery = 17
	var preserved: GameProgress = GameProgress.from_snapshot(historical)
	check(preserved != null and preserved.collected == [17] and preserved.round_state.snapshot() == imperfect.round_state.snapshot(), "retired surprise metadata still loads without losing owned characters or the board")
	_clear_round(preserved.round_state)
	preserved.settle_collection_reward()
	check(preserved.collected == [17] and preserved.choice_tokens == 1 and preserved.last_discovery == -1, "old surprise progress cannot grant another automatic character")
	# Full collections retain perfect choices for later content without duplicate awards.
	p.collected.clear()
	for id: int in range(24):
		p.collected.append(id)
	var credits: int = p.choice_tokens
	check(not p.collect_character(4) and p.choice_tokens == credits, "full collection never consumes a choice for duplicates")

func _test_expanded_progress() -> void:
	for level: int in [8, 11, 20, 23]:
		for chosen_theme: int in [-1, 0, 1, 2, 3]:
			var model: MatchRound = MatchRound.create(level, 924, 3, chosen_theme)
			check(model.identities.size() == 16, "peak boards have 16 cards in every theme")
			check(LevelGenerator.columns(level, 3) == 4, "16 cards use a four-column grid")
			check(MatchRound.from_snapshot(model.snapshot()) != null, "peak board round-trips before play")
			_clear_round(model)
			check(model.matches() == 8 and model.points() == 960, "all eight pairs are clearable for a perfect 960")
	# Both previous schemas used the old six-level wave, even at high level numbers.
	for version: int in [1, 2]:
		for level: int in [7, 8, 13, 48]:
			var old: GameProgress = GameProgress.create(9087)
			old.round_state = MatchRound.create(level, old.seed_value, version)
			old.banked_points = LevelGenerator.completed_pairs(level - 1, 2) * 120
			old.round_state.begin_play()
			old.round_state.select(0)
			old.round_state.select(old.round_state.identities.rfind(old.round_state.identities[0]))
			old.round_state.finish_resolution()
			old.dark_mode = true
			old.collected = [4, 12]
			old.choice_tokens = 2
			old.reward_level = level - 1
			var data: Dictionary = old.snapshot()
			data.version = version
			data.erase("expanded_from_level")
			var restored: GameProgress = GameProgress.from_snapshot(data)
			check(restored != null, "legacy high-level score remains valid after changing the wave")
			if restored == null:
				continue
			check(restored.round_state.snapshot() == old.round_state.snapshot() and restored.total_points() == old.total_points(), "migration preserves exact partially cleared board, attempts and points")
			check(restored.expanded_from_level == level + 1, "expanded wave begins after the saved board")
			if version == 2:
				check(restored.collected == old.collected and restored.choice_tokens == 2 and restored.dark_mode, "owned characters, choices and appearance migrate unchanged")
			var corrupt: Dictionary = restored.snapshot()
			corrupt.expanded_from_level = 1
			check(GameProgress.from_snapshot(corrupt) == null, "wave metadata cannot contradict the saved board generation")
			for step: int in range(14):
				_clear_round(restored.round_state)
				var points: int = restored.total_points()
				restored.advance()
				check(restored.round_state.generation == 4 and restored.total_points() == points, "advancement changes generation without changing score")
				var reloaded: GameProgress = GameProgress.from_snapshot(restored.snapshot())
				check(reloaded != null and reloaded.snapshot() == restored.snapshot(), "mixed legacy/new wave saves stay valid across another complete wave")
	var fresh: GameProgress = GameProgress.create(483)
	for bad: Variant in [0, 3, 1.5, "1", null]:
		var corrupt: Dictionary = fresh.snapshot()
		corrupt.expanded_from_level = bad
		check(GameProgress.from_snapshot(corrupt) == null, "invalid wave migration boundary rejected")

func _test_audio() -> void:
	var sound: GameAudio = GameAudio.new()
	root.add_child(sound)
	for cue: StringName in GameAudio.CUES:
		var stream: AudioStream = GameAudio.CUES[cue]
		check(stream.get_length() > 0.05 and stream.get_length() < 1.5, "each imported sound is a short valid stream")
		check(sound.play_cue(cue), "available cue plays")
	check(sound.voices.size() == 4, "rapid effects use a bounded voice pool")
	sound.enabled = false
	check(not sound.play_cue(&"match"), "muted effects cannot start")
	for voice: AudioStreamPlayer in sound.voices:
		check(not voice.playing, "muting stops all currently playing effects")
	sound.enabled = true
	sound.suspended = true
	check(not sound.play_cue(&"complete"), "background and overlays suppress sound")
	sound.suspended = false
	paused = true
	check(not sound.play_cue(&"reveal"), "paused gameplay cannot make sound")
	sound.allow_while_paused = true
	check(sound.play_cue(&"wave"), "collection's isolated pool can play an explicit reaction while the board is paused")
	sound.suspended = true
	check(not sound.play_cue(&"dance"), "background/hidden collection remains silent even with overlay audio enabled")
	sound.suspended = false
	sound.enabled = false
	check(not sound.play_cue(&"fireworks"), "collection sound honors mute while paused")
	sound.enabled = true
	sound.stop_all()
	paused = false
	check(not sound.play_cue(&"missing"), "unavailable cue fails without interrupting gameplay")
	check(sound.play_cue(&"next"), "unmuting and resuming allows the next cue")
	sound.free()

func _test_services() -> void:
	var billing: SimulatedBilling = SimulatedBilling.new()
	billing.save_path = "user://test_ownership.json"
	var ads: SimulatedAds = SimulatedAds.new()
	var consent: SimulatedConsent = SimulatedConsent.new()
	root.add_child(billing)
	root.add_child(ads)
	root.add_child(consent)
	billing.entitlement_changed.connect(ads.set_ad_free)
	consent.permission_changed.connect(ads.set_consent_allowed)
	billing.reset_simulation()
	ads.load_ad()
	check(not ads.loaded and ads.state == "blocked", "unknown consent blocks ads")
	consent.outcome = "required"
	consent.request_update()
	check(consent.form_available and not consent.can_request_ads, "required consent exposes form")
	consent.resolve(false)
	check(not ads.can_request(), "decline permits gameplay but blocks ads")
	consent.request_update()
	consent.resolve(true)
	check(ads.can_request(), "explicit simulated consent permits test ads")
	billing.outcome = "pending"
	billing.purchase()
	await create_timer(0.2).timeout
	check(billing.pending and not billing.ad_free and ads.can_request(), "pending purchase never grants entitlement")
	billing.complete_pending(false)
	check(not billing.pending and not billing.ad_free, "pending cancellation preserves ownership")
	for outcome: String in ["cancel", "failure"]:
		billing.outcome = outcome
		billing.purchase()
		await create_timer(0.2).timeout
		check(not billing.ad_free, "cancel/failure cannot unlock ownership")
	ads.fail_load = true
	ads.load_ad()
	await create_timer(0.2).timeout
	check(ads.state == "failure" and not ads.loaded, "ad load failure returns without blocking gameplay")
	ads.fail_load = false
	ads.load_ad()
	await create_timer(0.2).timeout
	ads.fail_show = true
	ads.show_ad()
	check(ads.state == "failure" and not ads.loaded, "ad show failure consumes unusable ad")
	ads.load_ad()
	await create_timer(0.2).timeout
	ads.fail_show = false
	ads.show_ad()
	check(ads.state == "showing", "simulated ad shows")
	ads.dismiss()
	check(ads.state == "dismissed", "ad dismissal returns to gameplay")
	ads.load_ad()
	await create_timer(0.2).timeout
	billing.seed_restorable_purchase()
	billing.restore()
	check(billing.ad_free and not ads.loaded, "restore invalidates already-loaded ad")
	ads.show_ad()
	check(ads.state == "suppressed", "restored ownership prevents ad display")
	billing.reset_simulation()
	ads.load_ad()
	billing.seed_restorable_purchase()
	billing.restore()
	await create_timer(0.2).timeout
	check(not ads.loaded and ads.state == "suppressed", "late ad callback cannot undo restored ownership")
	billing.reset_simulation()
	ads.load_ad()
	consent.outcome = "failure"
	consent.request_update()
	await create_timer(0.2).timeout
	check(not ads.loaded and not ads.can_request(), "consent failure invalidates in-flight ad load")
	consent.outcome = "unavailable"
	consent.request_update()
	check(not consent.form_available and not ads.can_request(), "unavailable consent stays gated")
	billing.outcome = "pending"
	billing.purchase()
	await create_timer(0.2).timeout
	billing.complete_pending(true)
	check(billing.ad_free, "completed pending payment grants simulated ownership")
	var replacement: SimulatedBilling = SimulatedBilling.new()
	replacement.save_path = billing.save_path
	root.add_child(replacement)
	replacement.restore()
	check(replacement.ad_free, "ownership persists across service instances")
	billing.reset_simulation()
	billing.outcome = "success"
	billing.purchase()
	billing.reset_simulation()
	await create_timer(0.2).timeout
	check(not billing.ad_free, "reset cancels in-flight simulated purchase")
	var native: NativeBilling = NativeBilling.new()
	root.add_child(native)
	native.purchase()
	check(native.state == "disabled" and not native.ad_free, "native adapter cannot start a real charge")
	native.restore()
	check(native.state == "unavailable", "unconnected native restoration fails gracefully")
	var corrupt: FileAccess = FileAccess.open(billing.save_path, FileAccess.WRITE)
	corrupt.store_string("not json")
	corrupt.close()
	billing.restore()
	check(not billing.ad_free, "corrupt simulation file cannot grant ownership")
	for node: Node in [native, replacement, billing, ads, consent]:
		node.queue_free()
	DirAccess.remove_absolute("user://test_ownership.json")
	await process_frame

func _test_easier_boards() -> void:
	check(PeopleCatalog.COUNT == 56, "56 stable collectible IDs")
	for theme_id: int in range(7):
		check(PeopleCatalog.characters(theme_id).size() == 8, "eight different characters per theme")
	for seed_number: int in range(12):
		for level: int in range(1, 37):
			for plus: bool in [false, true]:
				var pool: Array[int] = PeopleCatalog.available_themes(plus)
				for theme_id: int in [-1] + pool:
					var model: MatchRound = MatchRound.create(level, seed_number, 4, theme_id, 1, pool)
					var counts: Dictionary = {}
					for character: int in model.character_layout():
						check(PeopleCatalog.is_unlocked(character, plus), "locked characters never enter a generated board")
						counts[character] = int(counts.get(character, 0)) + 1
					for count: int in counts.values():
						check(count == 2, "every visible character has exactly one identical mate")
					check(model.identities.size() == LevelGenerator.EASY_PAIRS[(level - 1) % 12] * 2, "new card-count rhythm is exact")
					check(MatchRound.from_snapshot(model.snapshot()) != null, "new board regenerates with its frozen theme pool")
					if model.identities.size() >= 12:
						check(LevelGenerator.pair_count(level + 1) == 2, "every hard board is immediately followed by four cards")
	# Every old pair maps one-to-one onto a distinct visible character, including twins.
	for generation: int in [1, 2, 3]:
		for level: int in range(1, 25):
			var model: MatchRound = MatchRound.create(level, 992, generation)
			var mapping: Dictionary = {}
			for index: int in range(model.identities.size()):
				mapping[model.identities[index]] = model.character_at(index)
			var unique: Dictionary = {}
			for character: int in mapping.values():
				unique[character] = true
			check(unique.size() == mapping.size(), "legacy variants never produce identical-looking nonmatches")
			var old: GameProgress = GameProgress.create(992)
			old.round_state = model
			old.expanded_from_level = 1 if generation == 3 else level + 1
			old.banked_points = LevelGenerator.completed_pairs(level - 1, generation) * 110
			var fixture: Dictionary = old.snapshot()
			fixture.version = 3
			fixture.erase("easy_from_level")
			var restored: GameProgress = GameProgress.from_snapshot(fixture)
			check(restored != null and restored.round_state.identities == model.identities and restored.round_state.character_layout() == model.character_layout(), "schema-3 layouts migrate deterministically without losing pairs")
			if restored != null:
				_clear_round(restored.round_state)
				restored.advance()
				check(restored.round_state.identities.size() == 4, "all migrated players enter the easier wave with four cards")
				check(GameProgress.from_snapshot(restored.snapshot()) != null, "score bounds preserve all three historical generations")
	var p: GameProgress = GameProgress.create(27)
	_clear_round(p.round_state)
	p.settle_collection_reward()
	check(not p.collect_character(32) and p.choice_tokens == 1, "free perfect choice cannot claim a paid character")
	p.plus_enabled = true
	check(p.collect_character(55) and p.collected == [55], "Plus unlocks paid collectible choices without auto-claiming")
	p.preferred_theme = 6
	p.advance()
	var snapshot: Dictionary = p.snapshot()
	var reloaded: GameProgress = GameProgress.from_snapshot(snapshot)
	check(not reloaded.plus_enabled and reloaded.collected == [55], "game saves preserve owned characters but never grant a purchase")
	check(reloaded.round_state.identities == p.round_state.identities and reloaded.round_state.theme_pool == PeopleCatalog.ALL_THEMES, "active paid board survives a missing/revoked entitlement unchanged")
	_clear_round(reloaded.round_state)
	reloaded.advance()
	check(reloaded.round_state.theme_pool == PeopleCatalog.FREE_THEMES and reloaded.round_state.chosen_theme == -1, "next board respects current entitlement")

func _test_peek_rules() -> void:
	var p: GameProgress = GameProgress.create(51)
	var m: MatchRound = p.round_state
	check(not m.begin_peek(true), "opening cannot consume a peek")
	m.begin_play()
	check(not m.begin_peek(false), "free players need an earned ad reward")
	check(not m.earn_peek("wrong-board"), "stale reward cannot unlock a different board")
	check(m.earn_peek(m.board_key()) and not m.earn_peek(m.board_key()), "earned callback grants one persisted allowance")
	m.select(0)
	var selected: Array[int] = m.selected.duplicate()
	check(m.begin_peek(false) and m.selected == selected and m.attempts == 0, "peek preserves a selected card and does not count as an attempt")
	check(m.select(m.identities.rfind(m.identities[0])) == "ignored", "peek blocks matching input")
	check(not m.begin_peek(true), "purchase during a peek cannot grant a second use")
	var reload: MatchRound = MatchRound.from_snapshot(m.snapshot())
	check(reload != null and reload.peek_used and not reload.peeking and not reload.begin_peek(true), "restart conceals cards and keeps a consumed peek consumed")
	m.finish_peek()
	check(m.select(m.identities.rfind(m.identities[0])) == "match", "first selection still matches normally after peek")
	m.finish_resolution()
	_clear_round(m)
	check(p.settle_collection_reward() and p.choice_tokens == 1, "peek-assisted perfect round earns one choice")
	check(not p.settle_collection_reward() and not m.earn_peek(m.board_key()), "completed board cannot receive extra choice or peek")
	p.advance()
	check(not p.round_state.peek_used and not p.round_state.peek_earned, "next board gets a fresh allowance, not a banked ad reward")
	p.round_state.begin_play()
	check(p.round_state.begin_peek(true), "paid player can peek offline without an ad")

func _test_rewarded_services() -> void:
	var ads: SimulatedAds = SimulatedAds.new()
	root.add_child(ads)
	var rewards: Array[String] = []
	ads.reward_earned.connect(func(key: String, _request: String) -> void: rewards.append(key))
	ads.load_rewarded("board-a")
	check(ads.rewarded_state == "blocked", "rewarded ads honor consent")
	ads.set_consent_allowed(true)
	ads.load_rewarded("board-a")
	await create_timer(0.2).timeout
	ads.show_rewarded()
	ads.dismiss_rewarded()
	check(rewards.is_empty(), "dismissing a rewarded ad never grants its reward")
	ads.load_rewarded("board-a")
	await create_timer(0.2).timeout
	ads.show_rewarded()
	var old_request: String = ads.reward_request
	ads.earn_test_reward()
	ads.earn_test_reward()
	ads.dismiss_rewarded()
	check(rewards == ["board-a"], "only the explicit earned callback rewards, exactly once")
	ads.load_rewarded("board-b")
	await create_timer(0.2).timeout
	ads.show_rewarded()
	ads._deliver_reward(old_request)
	check(rewards.size() == 1, "old callback cannot award a new board")
	ads.set_ad_free(true)
	ads.earn_test_reward()
	check(rewards.size() == 1 and ads.reward_request.is_empty(), "restored Plus suppresses pending rewarded callbacks")
	ads.set_ad_free(false)
	ads.fail_load = true
	ads.load_rewarded("board-c")
	await create_timer(0.2).timeout
	check(ads.rewarded_state == "failure" and rewards.size() == 1, "no-fill grants nothing")
	ads.fail_load = false
	ads.load_rewarded("board-c")
	ads.cancel_rewarded()
	await create_timer(0.2).timeout
	check(ads.rewarded_state == "cancelled", "late loading result cannot reopen a cancelled ad")
	ads.load_rewarded("board-c")
	await create_timer(0.2).timeout
	ads.fail_show = true
	ads.show_rewarded()
	ads.earn_test_reward()
	check(ads.rewarded_state == "failure" and rewards.size() == 1, "failed presentation grants nothing")
	ads.queue_free()

func _test_native_rewarded_callbacks() -> void:
	var bridge: AdmobBridge = AdmobBridge.new()
	var sdk: RewardSDKStub = RewardSDKStub.new()
	var ads: NativeAds = NativeAds.new()
	root.add_child(bridge)
	bridge.add_child(sdk)
	bridge.sdk = sdk
	root.add_child(ads)
	ads.bridge = bridge
	ads.set_consent_allowed(true)
	var earned: Array[String] = []
	ads.reward_earned.connect(func(key: String, _request: String) -> void: earned.append(key))
	ads.load_rewarded("native-a")
	var late: RewardInfoStub = RewardInfoStub.new()
	late.id = "late-ad"
	late.request = sdk.request
	ads.cancel_rewarded()
	ads.load_rewarded("native-b")
	sdk.cached.append(late.id)
	sdk.rewarded_ad_loaded.emit(late, null)
	check(ads.rewarded_state == "loading" and sdk.cached.is_empty(), "late native load is discarded by its original request token")
	var ad: RewardInfoStub = RewardInfoStub.new()
	ad.id = "current-ad"
	ad.request = sdk.request
	sdk.cached.append(ad.id)
	sdk.rewarded_ad_loaded.emit(ad, null)
	check(ads.rewarded_state == "ready", "matching native callback makes rewarded ad ready")
	ads.show_rewarded()
	check(sdk.shown == ad.id and ads.rewarded_state == "showing", "native display targets the exact ready ad")
	sdk.rewarded_ad_user_earned_reward.emit(late, null)
	check(earned.is_empty(), "stale native earned event cannot grant a different board")
	sdk.rewarded_ad_user_earned_reward.emit(ad, null)
	sdk.rewarded_ad_user_earned_reward.emit(ad, null)
	check(earned == ["native-b"], "native SDK earned event grants exactly once")
	sdk.rewarded_ad_dismissed_full_screen_content.emit(ad)
	check(ads.rewarded_state == "dismissed" and earned.size() == 1, "native dismissal adds no reward")
	ads.set_ad_free(true)
	check(sdk.cached.is_empty(), "restored Plus drains native rewarded cache")
	sdk.rewarded_ad_user_earned_reward.emit(ad, null)
	check(earned.size() == 1, "restoration invalidates a late native earned event")
	ads.set_ad_free(false)
	ads.load_rewarded("native-c")
	ad.request = sdk.request
	sdk.rewarded_ad_failed_to_load.emit(ad, null)
	check(ads.rewarded_state == "failure", "native load failure remains retryable")
	ads.load_rewarded("native-c")
	ad.request = sdk.request
	sdk.cached.append(ad.id)
	sdk.rewarded_ad_loaded.emit(ad, null)
	ads.show_rewarded()
	sdk.rewarded_ad_failed_to_show_full_screen_content.emit(ad, null)
	sdk.rewarded_ad_user_earned_reward.emit(ad, null)
	check(ads.rewarded_state == "failure" and earned.size() == 1, "native presentation failure cannot grant a reward")
	ads.queue_free()
	bridge.queue_free()
