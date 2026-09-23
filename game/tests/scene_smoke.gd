extends Node
## Uses a separate save prefix and fake store; never replaces the player's journey.
var app: GameScreen
var failures: int = 0
var cues: Array[StringName] = []
var collection_cues: Array[StringName] = []
var layout: Dictionary = {}

func run(screen: GameScreen) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	app = screen
	app.audio.cue_played.connect(func(cue: StringName) -> void: cues.append(cue))
	app.collection_panel.audio.cue_played.connect(func(cue: StringName) -> void: collection_cues.append(cue))
	await _wait_phase("preview")
	_check(app.phase == "preview", "opening preview is visible after the shuffle")
	for index: int in range(app.tiles.size()):
		_check(app.tiles[index].variant == app.progress.round_state.identities[index] and app.tiles[index].position == app._tile_position(index), "peek reveals the actual final playing positions")
	await _capture("preview")
	while app.phase == "preview":
		await get_tree().process_frame
	var preview_seconds: float = (Time.get_ticks_usec() - app.preview_started_usec) / 1000000.0
	_check(GameScreen.PREVIEW_SECONDS == 0.5 and preview_seconds >= 0.48 and preview_seconds < 0.85, "preview lasts half a second after the first displayed frame")
	await _wait_phase("playing")
	await _capture("board")
	layout["board"] = [app.board.global_position.x, app.board.global_position.y, app.board.size.x, app.board.size.y]
	_record_layout("collection", app.collection_button)
	_record_layout("settings", app.settings_button)
	var score_center: float = app.round_score_label.global_position.x + app.round_score_label.size.x / 2
	_check(absf(score_center - app.size.x / 2) <= 1.0, "round score is centered on the screen")
	await _click(app.collection_button.global_position + app.collection_button.size * 0.5)
	_check(app.collection_panel.owned_only and app.collection_panel.entries.is_empty() and app.collection_panel.empty.visible, "new players see an explicit empty My collection state")
	await _capture("empty-collection")
	await _click(app.collection_panel.discover.global_position + app.collection_panel.discover.size * 0.5)
	_check(app.collection_panel.entries.size() == PeopleCatalog.COUNT and app.collection_panel.action.disabled, "Discover all exposes the full catalog without claiming unearned characters")
	_check(app.collection_panel.entries[0].mouse_filter == Control.MOUSE_FILTER_PASS and app.collection_panel.grid.mouse_filter == Control.MOUSE_FILTER_PASS, "character cards pass touch drags through to the collection scroller")
	_check(app.collection_panel.scroll.scroll_deadzone >= 8, "collection touch scrolling keeps a tap deadzone")
	var start_scroll: int = app.collection_panel.scroll.scroll_vertical
	var drag_from: Vector2 = app.collection_panel.scroll.global_position + Vector2(36, app.collection_panel.scroll.size.y * 0.5)
	await _drag(drag_from, drag_from + Vector2(0, -220))
	_check(app.collection_panel.scroll.scroll_vertical > start_scroll + 40, "dragging a character scrolls the collection without using the scrollbar")
	_check(app.collection_panel.selected == -1 and app.collection_panel.fireworks.origins.is_empty(), "a drag does not select the character under the finger")
	app.collection_panel.scroll.scroll_vertical = 0
	await get_tree().process_frame
	await _click(app.collection_panel.entries[0].global_position + app.collection_panel.entries[0].size * 0.5)
	_check(app.collection_panel.fireworks.origins.is_empty() and collection_cues.is_empty(), "browsing without an earned choice does not celebrate a nonexistent reward")
	await _capture("discover")
	await _escape()
	var model: MatchRound = app.progress.round_state
	var other: int = 1
	while model.identities[other] == model.identities[0]:
		other += 1
	await _tap(0)
	await _tap(other)
	await _tap((other + 1) % model.identities.size())
	await get_tree().create_timer(0.28).timeout
	_check(model.attempts == 1 and model.selected.size() == 2, "rapid third tap cannot reveal another tile")
	_check(cues.count(&"reveal") == 1 and cues.count(&"mismatch") == 1, "accepted taps sound once; rejected third tap is silent")
	await _capture("mismatch")
	app._pause()
	_check(app.audio.suspended, "pause suspends the audio pool")
	for voice: AudioStreamPlayer in app.audio.voices:
		_check(not voice.playing, "pause stops active sounds instead of replaying them on resume")
	await get_tree().create_timer(1.4).timeout
	_check(model.resolving and app.tiles[0].face_up and app.tiles[other].face_up, "pause freezes mismatch timer and faces")
	await _capture("pause")
	_record_layout("sound", app.sound_toggle)
	_record_layout("dark", app.dark_toggle)
	_record_layout("background", app.background_choice)
	_record_layout("motion", app.motion_toggle)
	app._resume()
	await get_tree().create_timer(1.3).timeout
	_check(not model.resolving and model.selected.is_empty(), "resume resolves both selections")
	_check(not app.tiles[0].face_up and not app.tiles[other].face_up, "both mismatch portraits flip down")
	_check(not app.tiles[0].chosen and not app.tiles[other].chosen, "both selection outlines clear")
	await _capture("mismatch-reset")
	for index: int in range(model.identities.size()):
		if model.removed.has(index):
			continue
		await _tap(index)
		await _tap(model.identities.rfind(model.identities[index]))
		await get_tree().create_timer(0.66).timeout
		if model.matches() == 1:
			await _capture("walking")
	await _wait_phase("celebrating")
	await get_tree().create_timer(1.45).timeout
	_check(model.complete() and model.points() == 226, "two matches and 67 percent accuracy produce 226 points")
	_check(app.motion_layer.get_child_count() == 0, "departures finish before the completion card")
	_check_cast(4)
	_check(cues.count(&"match") == 2 and cues.count(&"complete") == 1, "each pair sounds once and completion sounds once")
	await _capture("complete")
	await get_tree().create_timer(2.2).timeout
	_check(app.phase == "celebrating" and app.progress.round_state.level == 1 and app.completion.visible, "completion remains until Next level is pressed")
	var cheer_phase: float = app.cheer_lineup.people[0].phase
	app._pause()
	await get_tree().create_timer(0.3).timeout
	_check(app.cheer_lineup.people[0].phase == cheer_phase, "pause freezes the cheering animation")
	app._next_level()
	_check(app.progress.round_state.level == 1, "paused Next level is ignored")
	app._resume()
	# Reload the saved completed round through the same path used on app launch.
	app.progress = app.store.load_progress()
	app._show_level()
	await _wait_phase("celebrating")
	await get_tree().create_timer(1.45).timeout
	_check(app.progress.total_points() == 226 and app.progress.round_state.level == 1, "reloading a completion keeps its result and score")
	_check_cast(4)
	_check(cues.count(&"complete") == 1, "restoring a completed result does not replay its reward sound")
	await _capture("complete-restored")
	await _click(app.next_level_button.global_position + app.next_level_button.size * 0.5)
	app._next_level()
	await _wait_phase("playing")
	_check(app.progress.round_state.level == 2 and app.tiles.size() == 6, "Next level opens a new 6-tile board only once")
	_check(app.progress.total_points() == 226, "advancement does not award twice")
	_check(app.cheer_lineup.people.is_empty(), "next level removes the previous celebration cast")
	await _capture("level-two")
	model = app.progress.round_state
	await _tap(0)
	await _tap(model.identities.rfind(model.identities[0]))
	await get_tree().create_timer(0.66).timeout
	var saved: GameProgress = app.store.load_progress()
	_check(saved != null and saved.total_points() == 326 and saved.round_state.matches() == 1, "partial next level is saved with cumulative score")
	_check(saved.round_state.identities == model.identities, "saved board retains exact positions")
	# Change the preference in the middle of a real flip, while paused.
	var reveal_index: int = 0
	while model.removed.has(reveal_index):
		reveal_index += 1
	await _tap(reveal_index)
	app._pause()
	await _click(app.motion_toggle.global_position + app.motion_toggle.size * 0.5)
	_check(app.progress.reduced_motion and app.tiles[reveal_index].face_up and not app.tiles[reveal_index].flipping and app.tiles[reveal_index].scale == Vector2.ONE, "enabling reduced motion settles an in-flight flip to its intended face")
	app._resume()
	# Reach the peak board using the same model, then exercise its actual UI.
	while app.progress.round_state.level < 5:
		_clear_model(app.progress.round_state)
		app.progress.advance()
	app.progress.reduced_motion = true
	app._checkpoint()
	app._show_level()
	await _wait_phase("preview")
	await _capture("twelve-preview")
	await _wait_phase("playing")
	_check(app.tiles.size() == 12 and app.tiles[0].size.x >= 100, "12-tile board preserves readable touch targets")
	for tile: PortraitTile in app.tiles:
		_check(Rect2(Vector2.ZERO, app.board.size).encloses(tile.get_rect()), "tile stays within the board")
	await _capture("twelve-board")
	await _tap(0)
	_check(app.tiles[0].face_up and not app.tiles[0].flipping, "reduced motion reveals without a flip tween")
	await _tap(app.progress.round_state.identities.rfind(app.progress.round_state.identities[0]))
	await get_tree().create_timer(0.65).timeout
	_check(app.motion_layer.get_child_count() == 0, "reduced motion omits walking and floating points")
	_clear_model(app.progress.round_state)
	app._checkpoint()
	app._show_level()
	await _wait_phase("celebrating")
	await get_tree().create_timer(0.25).timeout
	_check_cast(12)
	_check(not app.cheer_lineup.people[0].is_processing(), "reduced motion uses a still cheering pose")
	await _capture("twelve-complete-reduced")
	app.progress.reduced_motion = false
	app.motion_toggle.set_pressed_no_signal(false)
	app.cheer_lineup.set_reduced_motion(false)
	app._show_level()
	await _wait_phase("celebrating")
	await get_tree().create_timer(1.45).timeout
	_check_cast(12)
	await _capture("twelve-complete")
	_record_layout("next", app.next_level_button)
	_record_layout("reward", app.collect_reward_button)
	_check(app.progress.choice_tokens >= 1, "perfect board offers a saved collection choice")
	var credits_before: int = app.progress.choice_tokens
	await _click(app.collect_reward_button.global_position + app.collect_reward_button.size * 0.5)
	_check(app.collection_panel.visible and get_tree().paused, "completion opens the collection while pausing cheers")
	await _capture("collection")
	# Pick from the first row through the actual card button, then confirm.
	var pick: CollectionCard = app.collection_panel.entries[0] as CollectionCard
	if app.progress.collected.has(int(pick.get_meta("character"))):
		pick = app.collection_panel.entries[1] as CollectionCard
	_record_layout("first_character", app.collection_panel.entries[0])
	_record_layout("second_character", app.collection_panel.entries[1])
	_record_layout("discover", app.collection_panel.discover)
	_record_layout("mine", app.collection_panel.mine)
	_record_layout("claim", app.collection_panel.action)
	var chosen: int = int(pick.get_meta("character"))
	await _click(pick.global_position + pick.size * 0.5)
	_check(not app.collection_panel.action.disabled, "selecting an uncollected character enables the claim")
	_check(pick.person.reaction == CollectionPerformer.JUMP_CLAP and not pick.person.reduced_motion, "eligible unowned selection starts jump-and-clap while gameplay is paused")
	_check(not app.collection_panel.fireworks.origins.is_empty() and collection_cues.back() == &"fireworks", "tapping an eligible selection bursts fireworks with sound while gameplay stays paused")
	_check(not app.progress.collected.has(chosen) and app.progress.choice_tokens == credits_before, "selection fireworks do not collect or spend a choice before confirmation")
	await get_tree().create_timer(0.22).timeout
	_check(pick.person.reaction_age > 0.15, "unowned selection animation advances instead of being stopped by the ownership gate")
	await _capture("selection-fireworks")
	await _click(app.collection_panel.action.global_position + app.collection_panel.action.size * 0.5)
	_check(app.progress.collected.has(chosen) and app.progress.choice_tokens == credits_before - 1, "confirmed choice collects the selected character once")
	var claimed_save: GameProgress = app.store.load_progress()
	_check(claimed_save.collected == app.progress.collected and claimed_save.choice_tokens == app.progress.choice_tokens, "collection ownership and remaining choices persist together")
	await get_tree().create_timer(0.20).timeout
	_check(app.collection_panel.fireworks.origins.size() == 3, "successful saved claim has a confirmation burst")
	var confirmed_card: CollectionCard = app.collection_panel.entries.filter(func(card: CollectionCard) -> bool: return card.character == chosen)[0]
	_check(confirmed_card.person.reaction == CollectionPerformer.JUMP_CLAP, "successful explicit claim repeats jump-and-clap")
	await _capture("collected")
	await _click(app.collection_panel.mine.global_position + app.collection_panel.mine.size * 0.5)
	_check(app.collection_panel.owned_only and app.collection_panel.entries.size() == app.progress.collected.size(), "My collection shows only owned characters")
	var owned_card: CollectionCard = app.collection_panel.entries[0] as CollectionCard
	_check(owned_card.owned and owned_card.person.cheering, "owned cards have their own presentation and cheering pose")
	await get_tree().create_timer(0.1).timeout
	var owned_phase: float = owned_card.person.phase
	await get_tree().create_timer(0.25).timeout
	_check(owned_card.person.phase != owned_phase and get_tree().paused, "owned characters animate while the game is paused behind collection")
	var owned_snapshot: Dictionary = app.progress.snapshot()
	var previous_reaction: int = -1
	for tap: int in range(6):
		await _click(owned_card.global_position + owned_card.size * 0.5)
		_check(owned_card.person.reaction >= 0 and owned_card.person.reaction != previous_reaction, "owned-character taps start a random performance without an immediate repeat")
		previous_reaction = owned_card.person.reaction
		_check(collection_cues.back() == (&"dance" if previous_reaction < 3 else &"wave"), "each performance has its matching collection sound")
		await get_tree().create_timer(0.24).timeout
	_check(app.progress.snapshot() == owned_snapshot, "playing with owned characters cannot spend choices or change gameplay/ownership")
	await _capture("owned-reaction")
	# Inspect every routine through the same performer used by tapped cards.
	for routine: int in range(5):
		owned_card.react(routine)
		await get_tree().create_timer(0.30).timeout
		await _capture("reaction-%d" % routine)
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(owned_card.person.reaction == -1 and app.collection_panel.fireworks.origins.is_empty(), "backgrounding clears tap effects without replaying them later")
	for voice: AudioStreamPlayer in app.collection_panel.audio.voices:
		_check(not voice.playing, "backgrounding stops collection sound effects")
	owned_phase = owned_card.person.phase
	await get_tree().create_timer(0.2).timeout
	_check(owned_card.person.phase == owned_phase, "backgrounding freezes collection animations")
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await get_tree().create_timer(0.1).timeout
	_check(owned_card.person.phase != owned_phase, "foregrounding resumes collection animations")
	await _capture("my-collection")
	app.progress.reduced_motion = true
	app.collection_panel.refresh()
	owned_card = app.collection_panel.entries[0] as CollectionCard
	owned_phase = owned_card.person.phase
	await get_tree().create_timer(0.25).timeout
	_check(owned_card.person.phase == owned_phase, "Reduce motion leaves owned characters still")
	await _click(owned_card.global_position + owned_card.size * 0.5)
	_check(owned_card.person.reaction == -1 and owned_card.person.phase == owned_phase and owned_card.feedback_left > 0, "Reduce motion gives a still reaction caption instead of dancing")
	app.progress.sound = false
	app.collection_panel._sync_animation()
	await get_tree().create_timer(0.22).timeout
	var collection_sound_count: int = collection_cues.size()
	await _click(owned_card.global_position + owned_card.size * 0.5)
	_check(collection_cues.size() == collection_sound_count, "muted collection taps still respond without sound")
	app.progress.sound = true
	app.collection_panel._sync_animation()
	app.progress.reduced_motion = false
	app.collection_panel.refresh()
	var empty_theme: int = 0
	while app.progress.collected.any(func(id: int) -> bool: return PeopleCatalog.theme_of(id) == empty_theme):
		empty_theme += 1
	app.collection_panel.filters.select(empty_theme + 1)
	app.collection_panel.filters.item_selected.emit(empty_theme + 1)
	await get_tree().process_frame
	_check(app.collection_panel.entries.is_empty() and app.collection_panel.empty.visible, "theme filtering has an explicit empty-owned state")
	await _capture("empty-theme")
	app.collection_panel.filters.select(0)
	app.collection_panel.filters.item_selected.emit(0)
	var saved_prefix: String = app.store.prefix
	var collection_before: Array[int] = app.progress.collected.duplicate()
	var saved_credits: int = app.progress.choice_tokens
	var candidate: int = 0
	while app.progress.collected.has(candidate):
		candidate += 1
	app.store.prefix = "user://missing_directory/failed_collection"
	app._collect_character(candidate)
	_check(app.progress.collected == collection_before and app.progress.choice_tokens == saved_credits, "failed collection write retains both ownership and the choice")
	_check(app.collection_panel.fireworks.origins.is_empty(), "a failed save never shows a claim celebration")
	app.store.prefix = saved_prefix
	await _escape()
	_check(not app.collection_panel.visible and not get_tree().paused and app.phase == "celebrating", "Escape returns from collection to the held result")
	app._pause()
	await _click(app.dark_toggle.global_position + app.dark_toggle.size * 0.5)
	_check(app.progress.dark_mode and GamePalette.dark, "dark mode applies through actual touch")
	app.background_choice.select(3)
	app.background_choice.item_selected.emit(3)
	_check(app.store.load_progress().dark_mode and app.store.load_progress().background == 3, "dark mode and background persist")
	await _capture("dark-settings")
	app._resume()
	await _capture("dark-complete")
	app._open_collection()
	await _capture("dark-collection")
	await _escape()
	app._pause()
	await _click(app.sound_toggle.global_position + app.sound_toggle.size * 0.5)
	_check(not app.progress.sound and not app.audio.enabled, "sound toggle mutes through actual pointer input")
	_check(not app.store.load_progress().sound, "sound toggle persists immediately")
	await _capture("sound-muted")
	app._open_lab()
	await _capture("lab")
	await _escape()
	_check(not app.lab.visible and app.user_paused, "Escape closes the topmost overlay without resuming play")
	_check(get_tree().paused, "closing the lab preserves user pause")
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_check(get_tree().paused, "OS resume preserves user pause")
	await _escape()
	_check(not app.user_paused and not get_tree().paused, "Escape resumes from pause")
	var sound_count: int = cues.size()
	await _click(app.next_level_button.global_position + app.next_level_button.size * 0.5)
	await _wait_phase("playing")
	await _tap(0)
	await _tap(app.progress.round_state.identities.rfind(app.progress.round_state.identities[0]))
	await get_tree().create_timer(0.66).timeout
	_check(cues.size() == sound_count and app.progress.round_state.matches() == 1, "muted next, shuffle, reveal, and match stay silent while gameplay continues")
	app._pause()
	await _click(app.sound_toggle.global_position + app.sound_toggle.size * 0.5)
	_check(app.progress.sound and app.audio.enabled and app.store.load_progress().sound, "sound can be enabled again and saved")
	app._resume()
	# Exercise the new peak with actual input and full 16-person celebration.
	while app.progress.round_state.level < 9:
		_clear_model(app.progress.round_state)
		app.progress.advance()
	app._checkpoint()
	app._show_level()
	await _wait_phase("preview")
	await _capture("sixteen-preview")
	await _wait_phase("playing")
	_check(app.tiles.size() == 16, "level 9 reaches the expanded 16-card peak")
	for tile: PortraitTile in app.tiles:
		_check(tile.size.x >= 88 and tile.size.y >= 88 and Rect2(Vector2.ZERO, app.board.size).encloses(tile.get_rect()), "16-card touch targets stay usable and inside the board")
	await _capture("sixteen-board")
	model = app.progress.round_state
	for index: int in range(16):
		if not model.removed.has(index):
			await _tap(index)
			await _tap(model.identities.rfind(model.identities[index]))
			await get_tree().create_timer(0.66).timeout
	await _wait_phase("celebrating")
	await get_tree().create_timer(1.7).timeout
	_check(model.points() == 960 and model.attempts == 8, "16-card perfect board earns exactly 960 round points")
	_check_cast(16)
	await _capture("sixteen-complete")
	await _click(app.collection_button.global_position + app.collection_button.size * 0.5)
	_check(app.collection_panel.visible and app.collection_panel.owned_only, "bottom Collection opens My collection directly")
	await _capture("sixteen-collection")
	await _escape()
	await _click(app.settings_button.global_position + app.settings_button.size * 0.5)
	_check(app.pause_menu.visible and get_tree().paused, "bottom Settings opens appearance and pauses play")
	await _escape()
	# Reproduce the reported six-pair, 50% result at the retired surprise threshold.
	app.progress = GameProgress.create(4815)
	app.progress.round_state = MatchRound.create(5, 4815)
	app.progress.banked_points = LevelGenerator.completed_pairs(4) * 120
	app.progress.discovery_steps = 2
	_clear_model(app.progress.round_state)
	app.progress.round_state.attempts = 12
	await app._show_level()
	await _wait_phase("celebrating")
	_check(app.progress.round_state.accuracy() == 0.5 and app.progress.choice_tokens == 0 and app.progress.collected.is_empty(), "50 percent result never offers or auto-selects a collection reward")
	_check(not app.completion_detail.text.contains("Discovered") and not app.completion_detail.text.contains("choice earned"), "imperfect result has no misleading collection award message")
	await _capture("fifty-percent-no-reward")
	var restored_reward: GameProgress = app.store.load_progress()
	_check(restored_reward != null and restored_reward.collected.is_empty() and restored_reward.choice_tokens == 0, "50 percent result persists without collection ownership")
	await _test_plus_peek()
	var layout_file: FileAccess = FileAccess.open("user://smoke-layout.json", FileAccess.WRITE)
	layout_file.store_string(JSON.stringify(layout))
	layout_file.close()
	print("SMOKE PASSED: preview, mismatch, walking, returning cast, cheers, persistent result, explicit Next level, completed save, score, centered score, discoverable settings, 16 cards and returning people, animated owned collection, reduced motion, lifecycle, sound and persistence" if failures == 0 else "SMOKE FAILED: %d failures" % failures)
	for suffix: String in [".0.json", ".1.json", ".0.json.tmp", ".1.json.tmp"]:
		DirAccess.remove_absolute(app.store.prefix + suffix)
	get_tree().quit(0 if failures == 0 else 1)

func _clear_model(model: MatchRound) -> void:
	model.begin_play()
	model.finish_resolution()
	for index: int in range(model.identities.size()):
		if not model.removed.has(index):
			model.select(index)
			model.select(model.identities.rfind(model.identities[index]))
			model.finish_resolution()

func _tap(index: int) -> void:
	var point: Vector2 = app.tiles[index].global_position + app.tiles[index].size * 0.5
	await _click(point)

func _drag(from: Vector2, to: Vector2) -> void:
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.position = from
	press.global_position = from
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().process_frame
	var previous: Vector2 = from
	const STEPS := 8
	for step: int in STEPS:
		var point: Vector2 = from.lerp(to, float(step + 1) / float(STEPS))
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		motion.relative = point - previous
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		previous = point
		await get_tree().process_frame
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.position = to
	release.global_position = to
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	Input.parse_input_event(release)
	await get_tree().process_frame

func _click(point: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		Input.parse_input_event(event)
		await get_tree().process_frame

	# Allow visibility/layout changes from the released button to settle.
	await get_tree().create_timer(0.04).timeout

func _check_cast(expected_count: int) -> void:
	_check(app.cheer_lineup.people.size() == expected_count, "every tile's character returns, including both members of each pair")
	var identities: Array[int] = []
	var board_rect: Rect2 = Rect2(Vector2.ZERO, app.board.size)
	for person: Walker in app.cheer_lineup.people:
		identities.append(person.variant)
		_check(person.cheering and not person.facing_left, "returning character switches from walking to cheering")
		var person_rect: Rect2 = Rect2(person.position + Vector2(-32, -28) * person.scale, Vector2(64, 132) * person.scale)
		_check(board_rect.encloses(person_rect), "cheering character fits the board")
		_check(not app.completion.get_rect().intersects(person_rect), "cheering character never covers the result card")
	identities.sort()
	var expected: Array[int] = app.progress.round_state.identities.duplicate()
	expected.sort()
	_check(identities == expected, "celebration uses the same people as the cleared board")

func _escape() -> void:
	for down: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.pressed = down
		Input.parse_input_event(event)
		await get_tree().process_frame

func _wait_phase(value: String) -> void:
	for tick: int in range(160):
		if app.phase == value:
			return
		await get_tree().create_timer(0.05).timeout
	_check(false, "timed out waiting for " + value + "; got " + app.phase)

func _check(condition: bool, detail: String) -> void:
	if not condition:
		failures += 1
		push_error("SMOKE FAILED: " + detail)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://smoke-" + label + ".png")

func _record_layout(key: String, control: Control) -> void:
	var point: Vector2 = control.global_position + control.size / 2
	layout[key] = [point.x, point.y]

func _test_plus_peek() -> void:
	app.billing.reset_simulation()
	app.use_native_rewarded = false
	app.progress = GameProgress.create(99303)
	app._show_level()
	await _wait_phase("playing")
	_record_layout("peek", app.peek_button)
	await _click(app.peek_button.global_position + app.peek_button.size / 2)
	_check(app.peek_offer.visible and not app.progress.round_state.peek_earned, "free Peek opens an optional offer without granting or showing an ad")
	_record_layout("watch_ad", app.peek_offer.watch)
	await _capture("peek-offer")
	app.ads.fail_load = true
	await _click(app.peek_offer.watch.global_position + app.peek_offer.watch.size / 2)
	await get_tree().create_timer(0.25).timeout
	_check(not app.peek_offer.watch.disabled and not app.progress.round_state.peek_earned, "no-fill keeps retry and continued play available")
	app.ads.fail_load = false
	await _click(app.peek_offer.watch.global_position + app.peek_offer.watch.size / 2)
	await get_tree().create_timer(0.25).timeout
	_check(app.ad_overlay.visible and app.ads.rewarded_state == "showing", "explicit Watch opens the simulated rewarded placement")
	_record_layout("earn_ad", app.test_reward_button)
	app._dismiss_simulated_ad()
	_check(not app.progress.round_state.peek_earned and not get_tree().paused, "closing without an earned callback grants no peek and returns to play")
	await _click(app.peek_button.global_position + app.peek_button.size / 2)
	await _click(app.peek_offer.watch.global_position + app.peek_offer.watch.size / 2)
	await get_tree().create_timer(0.25).timeout
	await _capture("test-ad")
	await _click(app.test_reward_button.global_position + app.test_reward_button.size / 2)
	_check(app.progress.round_state.peek_earned and not app.progress.round_state.peek_used and not get_tree().paused, "earned ad unlocks Ready without immediately revealing cards")
	_check(app.tiles.all(func(tile: PortraitTile) -> bool: return not tile.face_up), "returning from the ad does not flash the cards")
	_check(app.store.load_progress().round_state.peek_earned, "earned ad allowance survives restart")
	await _tap(0)
	await get_tree().create_timer(0.25).timeout
	await _click(app.peek_button.global_position + app.peek_button.size / 2)
	for _frame: int in range(180):
		if app.peek_started_usec > 0:
			break
		await get_tree().process_frame
	if app.peek_started_usec == 0:
		_check(false, "peek did not become visible")
		return
	_check(app.tiles.all(func(tile: PortraitTile) -> bool: return tile.face_up), "Quick Peek reveals every remaining character")
	await _capture("quick-peek")
	await _wait_phase("peek_concealing")
	var seconds: float = (Time.get_ticks_usec() - app.peek_started_usec) / 1000000.0
	_check(seconds >= 0.48 and seconds < 0.70, "Quick Peek is fully face-up for half a second, excluding flips")
	await _wait_phase("playing")
	_check(app.progress.round_state.selected == [0] and app.tiles[0].face_up and app.progress.round_state.attempts == 0, "Peek preserves first selection without a comparison penalty")
	_check(app.peek_button.disabled and app.store.load_progress().round_state.peek_used, "used peek persists and disables additional uses")
	_clear_model(app.progress.round_state)
	app._checkpoint()
	app._show_level()
	await _wait_phase("celebrating")
	_check(app.progress.choice_tokens == 1, "peek-assisted perfect board earns its character choice")
	app._open_collection(true)
	app.collection_panel.filters.select(5)
	app.collection_panel.filters.item_selected.emit(5)
	await get_tree().process_frame
	var locked: CollectionCard = app.collection_panel.entries[0] as CollectionCard
	_check(locked.locked, "paid theme is visibly labeled as locked")
	await _click(locked.global_position + locked.size / 2)
	_check(app.upgrade_panel.visible and app.progress.choice_tokens == 1 and app.progress.collected.is_empty(), "locked character opens Plus without consuming a perfect choice")
	_record_layout("buy_plus", app.upgrade_panel.buy)
	_record_layout("restore_plus", app.upgrade_panel.restore_button)
	await _capture("plus")
	app.billing.outcome = "pending"
	await _click(app.upgrade_panel.buy.global_position + app.upgrade_panel.buy.size / 2)
	await get_tree().create_timer(0.25).timeout
	_check(app.upgrade_panel.buy.disabled and not app.progress.plus_enabled, "pending test purchase leaves all paid benefits locked")
	app.billing.complete_pending(false)
	app.billing.outcome = "success"
	await _click(app.upgrade_panel.buy.global_position + app.upgrade_panel.buy.size / 2)
	await get_tree().create_timer(0.25).timeout
	_check(app.progress.plus_enabled and app.ads.ad_free and app.native_ads.ad_free, "successful test purchase grants all Plus benefits together")
	_check(app.progress.collected.is_empty() and app.progress.choice_tokens == 1, "purchase unlocks eligibility without auto-collecting characters")
	app._close_upgrade()
	await get_tree().process_frame
	var unlocked: CollectionCard = app.collection_panel.entries[0] as CollectionCard
	await _click(unlocked.global_position + unlocked.size / 2)
	await _click(app.collection_panel.action.global_position + app.collection_panel.action.size / 2)
	_check(app.progress.collected == [32] and app.progress.choice_tokens == 0, "player can explicitly collect an unlocked paid character")
	await _capture("woodland-collected")
	app._close_collection()
	app._next_level()
	await _wait_phase("playing")
	await _click(app.peek_button.global_position + app.peek_button.size / 2)
	await get_tree().create_timer(0.30).timeout
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(not app.board.visible and get_tree().paused, "backgrounding conceals the active peek")
	await get_tree().create_timer(0.65).timeout
	_check(app.progress.round_state.peeking, "background time does not consume the foreground reveal timer")
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _wait_phase("playing")
	_check(app.progress.round_state.peek_used and app.peek_button.disabled, "paid peek resumes once and cannot repeat")
	# Exercise all new theme silhouettes at the actual sixteen-card size.
	for theme_id: int in [4, 5, 6]:
		app.progress.round_state = MatchRound.create(9, app.progress.seed_value, 4, theme_id, 1, PeopleCatalog.ALL_THEMES)
		app.progress.banked_points = LevelGenerator.completed_pairs(8, 4) * 120
		app._checkpoint()
		app._show_level()
		await _wait_phase("preview")
		await _capture("plus-theme-%d-preview" % theme_id)
		await _wait_phase("playing")
		_check(app.tiles.size() == 16 and app.tiles.all(func(tile: PortraitTile) -> bool: return PeopleCatalog.theme_of(tile.variant) == theme_id), "paid theme shows eight distinct pairs at sixteen-card scale")
		app._quick_peek()
		await get_tree().create_timer(0.3).timeout
		await _capture("plus-theme-%d-peek" % theme_id)
		await _wait_phase("playing")
		_clear_model(app.progress.round_state)
		app._checkpoint()
		app._show_level()
		await _wait_phase("celebrating")
		await get_tree().create_timer(1.45).timeout
		await _capture("plus-theme-%d-cheer" % theme_id)
	app.billing.reset_simulation()

func run_plus_only(screen: GameScreen) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	app = screen
	await _wait_phase("playing")
	await _test_plus_peek()
	print("PLUS SMOKE PASSED" if failures == 0 else "PLUS SMOKE FAILED: %d" % failures)
	get_tree().quit(0 if failures == 0 else 1)
