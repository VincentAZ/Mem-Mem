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
	_test_audio()
	_test_native_ad_cleanup()
	await _test_services()
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
			var model: MatchRound = MatchRound.create(level, seed_number)
			check(model.select(0) == "ignored", "preview blocks input")
			check(model.identities.size() == LevelGenerator.pair_count(level) * 2, "wave controls board size")
			check(model.identities != model.preview, "shuffle changes arrangement")
			check(model.identities == MatchRound.create(level, seed_number).identities, "seed reproduces the exact board")
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
	var model: MatchRound = MatchRound.create(3, 44)
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
	check(LevelGenerator.pair_count(6) < LevelGenerator.pair_count(4), "wave includes a breather")
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
	check(p.round_state.identities.all(func(id: int) -> bool: return id >= 12 and id < 24), "second board introduces firefighters")
	p.round_state.begin_play()
	var other: int = 1
	while p.round_state.identities[other] == p.round_state.identities[0]:
		other += 1
	p.round_state.select(0)
	p.round_state.select(other)
	p.round_state.finish_resolution()
	_clear_round(p.round_state)
	p.settle_collection_reward()
	check(p.choice_tokens == 0 and p.discovery_steps == 2, "imperfect board advances discovery without granting a perfect choice")
	p.advance()
	_clear_round(p.round_state)
	p.settle_collection_reward()
	check(p.discovery_steps == 0 and p.collected.size() == 2 and p.last_discovery >= 0 and p.last_discovery != 23, "three boards discover a new nonduplicate character")
	var snapshot: Dictionary = p.snapshot()
	var loaded: GameProgress = GameProgress.from_snapshot(snapshot)
	check(loaded != null and loaded.snapshot() == snapshot and not loaded.settle_collection_reward(), "discovery and earned choices persist exactly once")
	p.dark_mode = true
	p.background = 3
	p.preferred_theme = 3
	loaded = GameProgress.from_snapshot(p.snapshot())
	check(loaded.dark_mode and loaded.background == 3 and loaded.preferred_theme == 3, "appearance and chosen theme survive reload")
	loaded.advance()
	check(loaded.round_state.identities.all(func(id: int) -> bool: return id >= 36), "preferred theme takes effect on next board")
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
	legacy.banked_points = LevelGenerator.completed_pairs(3) * 120
	legacy.round_state.begin_play()
	var old: Dictionary = {"version": 1, "seed": legacy.seed_value, "banked_points": legacy.banked_points, "round": legacy.round_state.snapshot(), "reduced_motion": false, "haptics": true, "sound": false}
	old.round.erase("generation")
	old.round.erase("chosen_theme")
	loaded = GameProgress.from_snapshot(old)
	check(loaded != null and loaded.round_state.identities == legacy.round_state.identities and loaded.total_points() == legacy.total_points(), "schema-1 board and score migrate unchanged")
	check(loaded.round_state.generation == 1 and not loaded.sound and loaded.collected.is_empty(), "legacy generation and settings preserved without invented rewards")
	_clear_round(loaded.round_state)
	loaded.advance()
	check(loaded.round_state.generation == 3, "migrated player enters new generator only after the old board")
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
			check(LevelGenerator.columns(level) == 4, "16 cards use a four-column grid")
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
				check(restored.round_state.generation == 3 and restored.total_points() == points, "advancement changes generation without changing score")
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
