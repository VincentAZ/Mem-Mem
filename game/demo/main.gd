class_name GameScreen
extends Control
## Playable loop. Service experiments remain in an explicitly separate development lab.
const PREVIEW_SECONDS: float = 0.5
const SAVE_WARNING: String = "Progress isn't saving. Please keep the app open."
var INK: Color = Color("244c43")
var MUTED: Color = Color("758176")
var progress: GameProgress
var store: ProgressStore = ProgressStore.new()
var tiles: Array[PortraitTile] = []
var board: Control
var status_label: Label
var pairs_label: Label
var level_label: Label
var mood_label: Label
var score_label: Label
var accuracy_label: Label
var progress_bar: ProgressBar
var save_notice: Label
var completion: PanelContainer
var completion_title: Label
var completion_detail: Label
var next_level_button: Button
var cheer_lineup: CheerLineup
var pause_menu: PanelContainer
var pause_detail: Label
var motion_toggle: CheckButton
var haptics_toggle: CheckButton
var sound_toggle: CheckButton
var audio: GameAudio = GameAudio.new()
var epoch: int = 0
var phase: String = "opening"
var backgrounded: bool = false
var user_paused: bool = false
var opening_animating: bool = false
var smoke_mode: bool = false
var score_tween: Tween
var shown_score: int = 0
var lab: PanelContainer
var log_label: Label
var lab_state: Label
var ad_overlay: PanelContainer
var logs: Array[String] = []
var billing = SimulatedBilling.new()
var monetization: MonetizationConfig = MonetizationConfig.new()
var privacy_button: Button
var waiting_for_consent: bool = false
var ads: SimulatedAds = SimulatedAds.new()
var consent: SimulatedConsent = SimulatedConsent.new()
var native_billing: NativeBilling = NativeBilling.new()
var bridge: AdmobBridge = AdmobBridge.new()
var native_ads: NativeAds = NativeAds.new()
var native_consent: NativeConsent = NativeConsent.new()
var motion_layer: Node2D
var round_score_label: Label
var tip_label: Label
var stats_panel: PanelContainer
var backdrop: GameBackdrop
var collection_panel: CollectionPanel
var collection_button: Button
var collect_reward_button: Button
var dark_toggle: CheckButton
var background_choice: OptionButton
var theme_choice: OptionButton
var presentation_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var last_departure: int = -1
var preview_started_usec: int = 0
var settings_button: Button
var pause_button: Button
var difficulty_label: Label
var round_score_panel: PanelContainer
var peek_button: Button
var peek_offer: PeekOffer
var upgrade_panel: UpgradePanel
var test_reward_button: Button
var use_native_rewarded: bool = OS.get_name() == "Android"
var native_reward_showing: bool = false
var peek_started_usec: int = 0
var themed_panels: Array[PanelContainer] = []

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	smoke_mode = monetization.development_enabled() and (OS.get_cmdline_user_args().has("--smoke") or OS.get_cmdline_user_args().has("--smoke-plus"))
	if not monetization.development_enabled():
		billing.free()
		billing = native_billing if monetization.production else BillingService.new()
		use_native_rewarded = monetization.production
	native_billing.config = monetization
	bridge.config = monetization
	native_consent.production = monetization.production
	native_consent.under_age_of_consent = monetization.under_age_of_consent
	if smoke_mode:
		store.prefix = "user://smoke_progress"
		billing.save_path = "user://smoke_ownership.json"
		progress = GameProgress.create(4815)
	else:
		progress = store.load_progress()
	if progress == null:
		progress = GameProgress.create(int(Time.get_unix_time_from_system()) % 2147483647)
	add_child(audio)
	audio.enabled = progress.sound
	GamePalette.configure(progress.dark_mode, progress.background)
	INK = GamePalette.ink
	MUTED = GamePalette.muted
	presentation_rng.randomize()
	backdrop = GameBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_build_theme()
	_build_game()
	_build_pause()
	if monetization.development_enabled():
		_build_lab()
	_build_ad_overlay()
	collection_panel = CollectionPanel.new()
	add_child(collection_panel)
	collection_panel.closed.connect(_close_collection)
	collection_panel.character_chosen.connect(_collect_character)
	collection_panel.upgrade_requested.connect(_open_upgrade)
	_build_monetization()
	_apply_palette()
	_connect_services()
	resized.connect(_layout_tiles)
	shown_score = progress.total_points()
	if store.recovered:
		save_notice.text = "Recovered your last intact save."
	elif store.had_files and store.revision == 0:
		save_notice.text = "Your save couldn't be read. Starting a fresh journey."
	_checkpoint()
	_show_level.call_deferred()
	if smoke_mode:
		var smoke: Node = load("res://tests/scene_smoke.gd").new() as Node
		add_child(smoke)
		smoke.call_deferred("run_plus_only" if OS.get_cmdline_user_args().has("--smoke-plus") else "run", self)

func _build_theme() -> void:
	var design: Theme = Theme.new()
	design.default_font_size = 15
	design.set_color("font_color", "Label", INK)
	for kind: String in ["Button", "CheckButton", "OptionButton", "PopupMenu"]:
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			design.set_color(state, kind, INK)
		design.set_color("font_disabled_color", kind, MUTED)
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			design.set_stylebox(state, kind, GameStyle.surface(GamePalette.card.lightened(0.03 if state == "hover" else 0.0), 14, 12))
		var focus: StyleBoxFlat = GameStyle.surface(Color.TRANSPARENT, 14, 12)
		focus.set_border_width_all(2)
		focus.border_color = GameStyle.accent()
		design.set_stylebox("focus", kind, focus)
	design.set_stylebox("panel", "PopupMenu", GameStyle.surface(GamePalette.card, 14, 10))
	theme = design

func _build_game() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var brand: HBoxContainer = HBoxContainer.new()
	brand.custom_minimum_size.y = 46
	brand.add_theme_constant_override("separation", 16)
	column.add_child(brand)
	var wordmark: Label = _label("mem·mem", 25)
	wordmark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_child(wordmark)
	var total: VBoxContainer = VBoxContainer.new()
	total.add_theme_constant_override("separation", 0)
	brand.add_child(total)
	var total_caption: Label = GameStyle.label("TOTAL SCORE", 9, true)
	total_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total.add_child(total_caption)
	score_label = _label("0", 21)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total.add_child(score_label)
	pause_button = _button("Ⅱ", _pause)
	pause_button.tooltip_text = "Pause game"
	pause_button.add_theme_font_size_override("font_size", 20)
	pause_button.custom_minimum_size = Vector2(46, 46)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	brand.add_child(pause_button)
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.custom_minimum_size.y = 56
	column.add_child(title_row)
	var title_stack: VBoxContainer = VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override("separation", 1)
	title_row.add_child(title_stack)
	level_label = GameStyle.label("LEVEL 1", 11, true)
	title_stack.add_child(level_label)
	mood_label = _label("Everyday People", 26)
	title_stack.add_child(mood_label)
	difficulty_label = GameStyle.label("6 CARDS", 10, true)
	difficulty_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	difficulty_label.add_theme_constant_override("outline_size", 0)
	title_row.add_child(difficulty_label)
	stats_panel = PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", GameStyle.surface(GamePalette.card, 20, 6))
	column.add_child(stats_panel)
	var stats_stack: VBoxContainer = VBoxContainer.new()
	stats_stack.add_theme_constant_override("separation", 7)
	stats_panel.add_child(stats_stack)
	var stats_row: HBoxContainer = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 0)
	stats_stack.add_child(stats_row)
	pairs_label = _stat(stats_row, "PAIRS", 21)
	round_score_label = _stat(stats_row, "SCORE THIS ROUND", 30, true)
	accuracy_label = _stat(stats_row, "ACCURACY", 21)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 4
	progress_bar.show_percentage = false
	stats_stack.add_child(progress_bar)
	board = Control.new()
	board.custom_minimum_size.y = 320
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(board)
	board.resized.connect(_layout_tiles)
	status_label = _label("", 14)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size.y = 26
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	peek_button = _button("Quick Peek", _quick_peek)
	peek_button.custom_minimum_size.y = 44
	peek_button.add_theme_font_size_override("font_size", 14)
	column.add_child(peek_button)
	column.add_child(status_label)
	tip_label = GameStyle.label("", 11, true)
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(tip_label)
	var navigation: HBoxContainer = HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 10)
	column.add_child(navigation)
	collection_button = _button("Collection · 0 / 56", _open_collection)
	collection_button.custom_minimum_size.y = 54
	collection_button.add_theme_font_size_override("font_size", 14)
	navigation.add_child(collection_button)
	settings_button = _button("Settings", _pause)
	settings_button.custom_minimum_size.y = 54
	settings_button.add_theme_font_size_override("font_size", 14)
	navigation.add_child(settings_button)
	save_notice = _label("", 11)
	save_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_notice.add_theme_color_override("font_color", Color("986143"))
	save_notice.hide()
	column.add_child(save_notice)
	motion_layer = Node2D.new()
	motion_layer.z_index = 3
	add_child(motion_layer)
	cheer_lineup = CheerLineup.new()
	cheer_lineup.z_index = 3
	board.add_child(cheer_lineup)
	completion = PanelContainer.new()
	completion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	completion.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	completion.position = Vector2.ZERO
	completion.z_index = 4
	board.add_child(completion)
	var message: VBoxContainer = VBoxContainer.new()
	message.add_theme_constant_override("separation", 12)
	message.custom_minimum_size = Vector2(280, 238)
	message.alignment = BoxContainer.ALIGNMENT_CENTER
	completion.add_child(message)
	var victory: Label = GameStyle.label("LEVEL COMPLETE", 10, true)
	victory.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_child(victory)
	completion_title = _label("Board cleared!", 27)
	completion_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_child(completion_title)
	completion_detail = _label("", 13)
	completion_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_child(completion_detail)
	collect_reward_button = _button("Choose a character", _open_collection.bind(true))
	collect_reward_button.custom_minimum_size.y = 46
	collect_reward_button.add_theme_font_size_override("font_size", 13)
	message.add_child(collect_reward_button)
	next_level_button = _button("Next level  →", _next_level)
	next_level_button.custom_minimum_size.y = 50
	GameStyle.skin_button(next_level_button, true)
	message.add_child(next_level_button)
	completion.hide()

func _stat(row: HBoxContainer, caption: String, font_size: int, featured: bool = false) -> Label:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	panel.custom_minimum_size.y = 70
	panel.add_theme_stylebox_override("panel", GameStyle.surface(GameStyle.gold_surface() if featured else Color.TRANSPARENT, 15, 0))
	row.add_child(panel)
	if featured:
		round_score_panel = panel
	var stack: VBoxContainer = VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	panel.add_child(stack)
	var heading: Label = GameStyle.label(caption, 9, true)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.clip_text = true
	stack.add_child(heading)
	var value: Label = _label("0", font_size)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.clip_text = true
	value.custom_minimum_size.y = 40
	stack.add_child(value)
	return value

func _show_level() -> void:
	phase = "opening"
	epoch += 1
	ads.cancel_rewarded()
	native_ads.cancel_rewarded()
	var ticket: int = epoch
	opening_animating = false
	completion.hide()
	next_level_button.disabled = true
	cheer_lineup.clear()
	for tile: PortraitTile in tiles:
		tile.free()
	tiles.clear()
	for child: Node in motion_layer.get_children():
		child.queue_free()
	var model: MatchRound = progress.round_state
	for index: int in range(model.identities.size()):
		var tile: PortraitTile = PortraitTile.new()
		tile.variant = model.character_at(index)
		tile.face_up = false
		tile.reduced_motion = progress.reduced_motion
		tile.tooltip_text = "Reveal portrait %d" % (index + 1)
		tile.pressed.connect(_select.bind(index))
		board.add_child(tile)
		tile.visible = not model.removed.has(index)
		tiles.append(tile)
	_update_hud(false)
	_layout_tiles()
	await get_tree().process_frame
	if ticket != epoch:
		return
	_layout_tiles()
	if model.complete():
		_present_completion()
	elif model.opening:
		_opening_sequence(ticket)
	else:
		phase = "playing"
		_refresh_peek()
		status_label.text = "Pick up where you left off."

func _opening_sequence(ticket: int) -> void:
	# Shuffle first so the half-second peek shows the actual, stable playing positions.
	phase = "shuffling"
	status_label.text = "Shuffling…"
	audio.play_cue(&"shuffle")
	opening_animating = true
	if not progress.reduced_motion:
		var gather: Tween = create_tween().set_parallel(true)
		for index: int in range(tiles.size()):
			gather.tween_property(tiles[index], "position", (board.size - tiles[index].size) * 0.5 + Vector2(index, index), 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await gather.finished
		if ticket != epoch:
			return
		var riffle: Tween = create_tween().set_parallel(true)
		for index: int in range(tiles.size()):
			riffle.tween_property(tiles[index], "position:x", (board.size.x - tiles[index].size.x) * 0.5 + (28 if index % 2 == 0 else -28), 0.22).set_trans(Tween.TRANS_SINE)
		await riffle.finished
		if ticket != epoch:
			return
		var spread: Tween = create_tween().set_parallel(true)
		for index: int in range(tiles.size()):
			spread.tween_property(tiles[index], "position", _tile_position(index), 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await spread.finished
	else:
		await get_tree().create_timer(1.02, false).timeout
	if ticket != epoch:
		return
	opening_animating = false
	_layout_tiles()
	for tile: PortraitTile in tiles:
		tile.flip_to(true)
	await get_tree().create_timer(0.25, false).timeout
	if ticket != epoch:
		return
	phase = "preview"
	status_label.text = "Remember the lineup…"
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	preview_started_usec = Time.get_ticks_usec()
	await get_tree().create_timer(PREVIEW_SECONDS, false).timeout
	if ticket != epoch:
		return
	phase = "concealing"
	for tile: PortraitTile in tiles:
		tile.flip_to(false)
	await get_tree().create_timer(0.25, false).timeout
	if ticket != epoch:
		return
	progress.round_state.begin_play()
	phase = "playing"
	_refresh_peek()
	status_label.text = "Tap two portraits to find a pair."
	_checkpoint()

func _tile_size() -> Vector2:
	var columns: int = LevelGenerator.columns(progress.round_state.level, progress.round_state.generation, progress.round_state.wave_start)
	var rows: int = ceili(float(progress.round_state.identities.size()) / columns)
	return Vector2((board.size.x - 10 * (columns - 1)) / columns, (board.size.y - 10 * (rows - 1)) / rows).floor()

func _tile_position(index: int) -> Vector2:
	var columns: int = LevelGenerator.columns(progress.round_state.level, progress.round_state.generation, progress.round_state.wave_start)
	var cell: Vector2 = _tile_size() + Vector2(10, 10)
	return Vector2((index % columns) * cell.x, (index / columns) * cell.y)

func _layout_tiles() -> void:
	if board == null or progress == null or opening_animating:
		return
	for index: int in range(tiles.size()):
		tiles[index].size = _tile_size()
		tiles[index].pivot_offset = tiles[index].size * 0.5
		tiles[index].position = _tile_position(index)
	if completion != null:
		completion.position = (board.size - completion.size) * 0.5
		if completion.visible:
			cheer_lineup.relayout(board.size, completion.get_rect())

func _select(index: int) -> void:
	if get_tree().paused or phase != "playing":
		return
	var model: MatchRound = progress.round_state
	var result: String = model.select(index)
	if result == "ignored":
		return
	tiles[index].chosen = true
	tiles[index].flip_to(true)
	if result == "first":
		audio.play_cue(&"reveal")
		status_label.text = "Find their match."
		return
	# Attempts and awards survive termination even before either flip has finished.
	_checkpoint()
	_update_hud(true)
	var ticket: int = epoch
	var pair: Array[int] = model.selected.duplicate()
	if result == "mismatch":
		status_label.text = "Not a match. Try another pair."
		audio.play_cue(&"mismatch")
		await get_tree().create_timer(0.95, false).timeout
		if ticket != epoch:
			return
		for selected: int in pair:
			tiles[selected].chosen = false
			tiles[selected].flip_to(false)
		await get_tree().create_timer(0.25, false).timeout
		if ticket != epoch:
			return
		model.finish_resolution()
		status_label.text = "Tap two portraits to find a pair."
	else:
		status_label.text = "Match! +100"
		audio.play_cue(&"match")
		for selected: int in pair:
			tiles[selected].delighted = true
		if progress.haptics and OS.get_name() == "Android":
			Input.vibrate_handheld(18)
		await get_tree().create_timer(0.50, false).timeout
		if ticket != epoch:
			return
		last_departure = (last_departure + presentation_rng.randi_range(1, 2)) % 3
		for selected: int in pair:
			_depart(selected)
		_float_points(pair)
		model.finish_resolution()
		if model.complete():
			phase = "finishing"
			_finish_level(ticket)

func _depart(index: int) -> void:
	var tile: PortraitTile = tiles[index]
	tile.chosen = false
	if progress.reduced_motion:
		var fade: Tween = tile.create_tween()
		fade.tween_property(tile, "modulate:a", 0.0, 0.16)
		fade.tween_callback(tile.hide)
		return
	var vanish: Tween = tile.create_tween()
	vanish.tween_property(tile, "modulate:a", 0.0, 0.16)
	vanish.tween_callback(tile.hide)
	var person: Walker = Walker.new()
	person.variant = tile.variant
	person.style = last_departure
	person.phase = index * 0.65
	person.position = tile.global_position + tile.size * Vector2(0.5, 0.28)
	person.modulate.a = 0.0
	motion_layer.add_child(person)
	var departure: Tween = person.create_tween().set_parallel(true)
	departure.tween_property(person, "modulate:a", 1.0, 0.16)
	var leave_left: bool = last_departure == 1 or (last_departure == 2 and index % 2 == 0)
	person.facing_left = leave_left
	departure.tween_property(person, "position:x", -60 if leave_left else size.x + 60, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	departure.tween_property(person, "position:y", person.position.y + (12 if last_departure == 2 else 0), 1.05)
	departure.chain().tween_callback(person.queue_free)

func _float_points(pair: Array[int]) -> void:
	if progress.reduced_motion:
		return
	for index: int in pair:
		var spark: MatchSpark = MatchSpark.new()
		spark.position = tiles[index].global_position + tiles[index].size * 0.5
		motion_layer.add_child(spark)
	var reward: Label = _label("+100", 22)
	reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward.position = tiles[pair[0]].global_position + Vector2(12, 12)
	motion_layer.add_child(reward)
	var float_up: Tween = reward.create_tween().set_parallel(true)
	float_up.tween_property(reward, "position:y", reward.position.y - 26, 0.65).set_trans(Tween.TRANS_SINE)
	float_up.tween_property(reward, "modulate:a", 0.0, 0.45).set_delay(0.2)
	float_up.chain().tween_callback(reward.queue_free)

func _finish_level(ticket: int) -> void:
	# Wait for the last pair to leave, then bring the whole cast back to celebrate.
	await get_tree().create_timer(0.25 if progress.reduced_motion else 1.2, false).timeout
	if ticket != epoch:
		return
	_present_completion(true)

func _present_completion(play_sound: bool = false) -> void:
	phase = "celebrating"
	var model: MatchRound = progress.round_state
	if progress.settle_collection_reward():
		_checkpoint()
	completion_title.text = "Perfect match!" if model.accuracy() == 1.0 else "Board cleared!"
	if play_sound:
		audio.play_cue(&"complete")
		audio.play_cheer()
	completion_detail.text = "%d pairs · %d%% accuracy\n+%d accuracy bonus" % [model.matches(), roundi(model.accuracy() * 100), model.bonus()]
	if model.accuracy() == 1.0:
		completion_detail.text += "\n1 character choice earned"
	collect_reward_button.text = "Choose a character · %d saved" % progress.choice_tokens if progress.choice_tokens > 0 else "View collection · %d / 56" % progress.collected.size()
	_update_hud(false)
	completion.modulate.a = 0.0
	completion.show()
	_layout_tiles()
	create_tween().tween_property(completion, "modulate:a", 1.0, 0.18)
	cheer_lineup.start(model.character_layout(), board.size, completion.get_rect(), progress.reduced_motion)
	next_level_button.disabled = false
	status_label.text = "Level %d complete." % model.level

func _next_level() -> void:
	if get_tree().paused or phase != "celebrating" or not progress.round_state.complete():
		return
	# Lock before changing the round, so repeated taps can settle it only once.
	phase = "transitioning"
	audio.play_cue(&"next")
	next_level_button.disabled = true
	if progress.advance():
		_checkpoint()
		_show_level()

func _update_hud(animate_score: bool) -> void:
	var model: MatchRound = progress.round_state
	level_label.text = "LEVEL %d" % model.level
	mood_label.text = PeopleCatalog.theme_name(LevelGenerator.theme_for_pool(model.level, model.chosen_theme, model.theme_pool)) if model.generation >= 4 else PeopleCatalog.theme_name(LevelGenerator.theme_for(model.level, model.chosen_theme)) if model.generation >= 2 else "Everyday People"
	pairs_label.text = "%d / %d" % [model.matches(), model.identities.size() / 2]
	round_score_label.text = str(model.points())
	difficulty_label.text = "%d CARDS" % model.identities.size()
	collection_button.text = "Collection · %d / 56" % progress.collected.size()
	tip_label.text = "100% accuracy → choose a character"
	accuracy_label.text = "%d%%" % roundi(model.accuracy() * 100) if model.attempts > 0 else "—"
	progress_bar.max_value = model.identities.size() / 2
	progress_bar.value = model.matches()
	if score_tween != null:
		score_tween.kill()
	if animate_score and not progress.reduced_motion:
		score_tween = create_tween()
		score_tween.tween_method(_display_score, shown_score, progress.total_points(), 0.32)
	else:
		_display_score(progress.total_points())

func _display_score(value: int) -> void:
	shown_score = value
	score_label.text = str(value)

func _checkpoint() -> void:
	if progress == null:
		return
	var saved: bool = store.save(progress)
	if save_notice != null:
		if not saved:
			save_notice.text = SAVE_WARNING
		elif save_notice.text == SAVE_WARNING:
			save_notice.text = ""
		save_notice.visible = not save_notice.text.is_empty()

func _build_pause() -> void:
	pause_menu = PanelContainer.new()
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu.z_index = 8
	add_child(pause_menu)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	pause_menu.add_child(margin)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var resume_button: Button = _button("‹  Back to game", _resume)
	resume_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var escape: InputEventKey = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	resume_button.shortcut = Shortcut.new()
	resume_button.shortcut.events = [escape]
	column.add_child(resume_button)
	column.add_child(_label("Settings", 30))
	pause_detail = GameStyle.label("", 13, true)
	column.add_child(pause_detail)
	var appearance: VBoxContainer = _settings_section(column, "APPEARANCE")
	dark_toggle = CheckButton.new()
	dark_toggle.text = "Dark mode"
	dark_toggle.custom_minimum_size.y = 46
	dark_toggle.button_pressed = progress.dark_mode
	dark_toggle.toggled.connect(func(value: bool) -> void:
		progress.dark_mode = value
		_apply_palette()
		_checkpoint()
	)
	appearance.add_child(dark_toggle)
	appearance.add_child(GameStyle.label("BACKGROUND", 10, true))
	background_choice = OptionButton.new()
	background_choice.custom_minimum_size.y = 46
	for name: String in GamePalette.BACKGROUNDS:
		background_choice.add_item(name)
	background_choice.select(progress.background)
	background_choice.item_selected.connect(func(index: int) -> void:
		progress.background = index
		_apply_palette()
		_checkpoint()
	)
	appearance.add_child(background_choice)
	var play: VBoxContainer = _settings_section(column, "SOUND & MOTION")
	sound_toggle = CheckButton.new()
	sound_toggle.text = "Sound effects"
	sound_toggle.custom_minimum_size.y = 46
	sound_toggle.button_pressed = progress.sound
	sound_toggle.toggled.connect(func(value: bool) -> void:
		progress.sound = value
		audio.enabled = value
		_checkpoint()
	)
	play.add_child(sound_toggle)
	haptics_toggle = CheckButton.new()
	haptics_toggle.text = "Vibration (Android)"
	haptics_toggle.custom_minimum_size.y = 46
	haptics_toggle.button_pressed = progress.haptics
	haptics_toggle.toggled.connect(func(value: bool) -> void:
		progress.haptics = value
		_checkpoint()
	)
	play.add_child(haptics_toggle)
	motion_toggle = CheckButton.new()
	motion_toggle.text = "Reduce motion"
	motion_toggle.custom_minimum_size.y = 46
	motion_toggle.button_pressed = progress.reduced_motion
	motion_toggle.toggled.connect(func(value: bool) -> void:
		progress.reduced_motion = value
		for tile: PortraitTile in tiles:
			tile.reduced_motion = value
		cheer_lineup.set_reduced_motion(value)
		if value:
			for effect: Node in motion_layer.get_children():
				effect.queue_free()
		_checkpoint()
	)
	play.add_child(motion_toggle)
	var cast: VBoxContainer = _settings_section(column, "CAST FOR THE NEXT BOARD")
	theme_choice = OptionButton.new()
	theme_choice.custom_minimum_size.y = 46
	theme_choice.add_item("Surprise me · rotating themes")
	for name: String in PeopleCatalog.THEMES:
		theme_choice.add_item(name + (" · Plus" if PeopleCatalog.THEMES.find(name) >= 4 else ""))
	theme_choice.select(progress.preferred_theme + 1)
	theme_choice.item_selected.connect(func(index: int) -> void:
		if not billing.unlocked_themes().has(index - 1) and index > 0:
			theme_choice.select(progress.preferred_theme + 1)
			_open_upgrade()
			return
		progress.preferred_theme = index - 1
		_checkpoint()
	)
	cast.add_child(theme_choice)
	var rules: Label = GameStyle.label("100 points per pair + an accuracy bonus.\n100% accuracy earns a choice from unlocked themes.", 12, true)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(rules)
	column.add_child(_button("Your collection", _open_collection))
	column.add_child(_button("Mem-Mem Plus · themes & peeks", _open_upgrade))
	column.add_child(_button("Restore purchase · test" if monetization.development_enabled() else "Restore purchase", billing.restore))
	if monetization.production:
		privacy_button = _button("Privacy choices", native_consent.show_privacy_options)
		privacy_button.hide()
		column.add_child(privacy_button)
		if monetization.privacy_url.begins_with("https://"):
			column.add_child(_button("Privacy policy", func() -> void: OS.shell_open(monetization.privacy_url)))
	if monetization.development_enabled():
		var rewarded_mode: CheckButton = CheckButton.new()
		rewarded_mode.text = "Use simulated rewarded ads (testing)"
		rewarded_mode.button_pressed = not use_native_rewarded
		rewarded_mode.toggled.connect(func(value: bool) -> void:
			ads.cancel_rewarded()
			native_ads.cancel_rewarded()
			use_native_rewarded = not value and OS.get_name() == "Android"
		)
		column.add_child(rewarded_mode)
		var development: Button = _button("Development service lab", _open_lab)
		development.add_theme_font_size_override("font_size", 12)
		column.add_child(development)
	pause_menu.hide()

func _settings_section(parent: VBoxContainer, caption: String) -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	themed_panels.append(panel)
	parent.add_child(panel)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(stack)
	stack.add_child(GameStyle.label(caption, 10, true))
	return stack

func _pause() -> void:
	user_paused = true
	pause_detail.text = "Level %d · Game paused" % progress.round_state.level
	pause_menu.show()
	_checkpoint()
	_sync_pause()

func _resume() -> void:
	if upgrade_panel.visible:
		_close_upgrade()
		return
	if peek_offer.visible and not ad_overlay.visible:
		_close_peek_offer()
		return
	# Escape belongs to the topmost visible overlay, never an obscured resume button.
	if collection_panel.visible:
		_close_collection()
		return
	if ad_overlay.visible:
		_dismiss_simulated_ad()
		return
	if lab != null and lab.visible:
		_close_lab()
		return
	user_paused = false
	pause_menu.hide()
	_sync_pause()

func _open_lab() -> void:
	if not monetization.development_enabled():
		return
	lab.show()
	_sync_pause()

func _close_lab() -> void:
	lab.hide()
	_sync_pause()

func _sync_pause() -> void:
	get_tree().paused = backgrounded or user_paused or (lab != null and lab.visible) or (ad_overlay != null and ad_overlay.visible) or (collection_panel != null and collection_panel.visible) or (peek_offer != null and peek_offer.visible) or (upgrade_panel != null and upgrade_panel.visible) or native_reward_showing
	audio.suspended = get_tree().paused
	board.visible = not backgrounded
	if collection_panel != null:
		collection_panel.set_animation_active(not backgrounded and not upgrade_panel.visible)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		backgrounded = true
		_checkpoint()
		_sync_pause()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		backgrounded = false
		_sync_pause()
		if monetization.production:
			native_billing.restore()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if get_tree().paused:
			_resume()
		else:
			_pause()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_checkpoint()
		get_tree().quit()

func _centered_label(value: String, font_size: int) -> Label:
	var result: Label = _label(value, font_size)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return result

func _connect_services() -> void:
	for service: Node in [billing, ads, consent, native_billing, bridge, native_ads, native_consent]:
		service.process_mode = Node.PROCESS_MODE_ALWAYS
		if service.get_parent() == null:
			add_child(service)
	native_ads.bridge = bridge
	native_consent.bridge = bridge
	billing.entitlement_changed.connect(_plus_changed)
	billing.state_changed.connect(func(_state: String, _detail: String) -> void: upgrade_panel.refresh(billing))
	billing.entitlement_changed.connect(ads.set_ad_free)
	billing.entitlement_changed.connect(native_ads.set_ad_free)
	consent.permission_changed.connect(ads.set_consent_allowed)
	native_consent.permission_changed.connect(native_ads.set_consent_allowed)
	native_consent.state_changed.connect(_privacy_updated)
	for service: Node in [billing, ads, consent, native_billing, native_ads, native_consent]:
		if not service.is_connected("state_changed", _service_event):
			service.connect("state_changed", _service_event)
	ads.state_changed.connect(_simulated_ad_event)
	for provider: AdsService in [ads, native_ads]:
		provider.reward_earned.connect(_peek_reward_earned)
		provider.rewarded_state_changed.connect(_rewarded_event.bind(provider))
	if monetization.production:
		native_billing.initialize()
		if monetization.audience_configured:
			native_consent.request_update()
	else:
		billing.restore()
		if monetization.development_enabled():
			consent.request_update()

func _service_event(state: String, detail: String) -> void:
	if not monetization.development_enabled():
		return
	logs.push_front("%s · %s" % [state.to_upper(), detail])
	if logs.size() > 6:
		logs.resize(6)
	log_label.text = "\n\n".join(logs)
	lab_state.text = "Fake ownership: %s  |  Fake ad: %s\nNative billing: %s  |  Native ad: %s" % ["ad-free" if billing.ad_free else "none", ads.state, native_billing.state, native_ads.state]

func _simulated_ad_event(state: String, _detail: String) -> void:
	ad_overlay.visible = state == "showing" or ads.rewarded_state == "showing"
	test_reward_button.visible = ads.rewarded_state == "showing"
	_sync_pause()

func _build_lab() -> void:
	lab = PanelContainer.new()
	lab.process_mode = Node.PROCESS_MODE_ALWAYS
	lab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lab.add_theme_stylebox_override("panel", _box(Color("f8f4ec"), 0))
	lab.z_index = 10
	add_child(lab)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	lab.add_child(margin)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	content.add_child(_button("Back", _close_lab))
	content.add_child(_label("Service lab", 30))
	var intro: Label = _label("Development controls only. Simulations never charge money or validate a real purchase.", 13)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	lab_state = _label("", 12)
	lab_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(lab_state)
	content.add_child(_label("01 / Simulated billing", 18))
	var purchase_grid: GridContainer = GridContainer.new()
	purchase_grid.columns = 2
	content.add_child(purchase_grid)
	for outcome: String in ["success", "cancel", "pending", "failure"]:
		purchase_grid.add_child(_button(outcome.capitalize(), _simulate_purchase.bind(outcome)))
	content.add_child(_button("Complete pending payment", func() -> void: billing.complete_pending(true)))
	content.add_child(_button("Cancel pending payment", func() -> void: billing.complete_pending(false)))
	content.add_child(_button("Restore fake account purchase", func() -> void:
		billing.seed_restorable_purchase()
		billing.restore()
	))
	content.add_child(_button("Reset fake ownership", billing.reset_simulation))
	content.add_child(_label("02 / Simulated consent", 18))
	var consent_grid: GridContainer = GridContainer.new()
	consent_grid.columns = 2
	content.add_child(consent_grid)
	for outcome: String in ["required", "not_required", "unavailable", "failure"]:
		consent_grid.add_child(_button(outcome.replace("_", " ").capitalize(), _simulate_consent.bind(outcome)))
	var consent_choices: HBoxContainer = HBoxContainer.new()
	content.add_child(consent_choices)
	consent_choices.add_child(_button("Allow", func() -> void: consent.resolve(true)))
	consent_choices.add_child(_button("Decline", func() -> void: consent.resolve(false)))
	content.add_child(_label("03 / Simulated advertising", 18))
	content.add_child(_button("Load fake ad", _simulate_ad.bind(false)))
	content.add_child(_button("Fail fake ad load", _simulate_ad.bind(true)))
	content.add_child(_button("Show fake ad", func() -> void:
		ads.fail_show = false
		ads.show_ad()
	))
	content.add_child(_button("Fail fake ad display", func() -> void:
		ads.fail_show = true
		ads.show_ad()
	))
	content.add_child(_label("04 / Native SDK checks", 18))
	var native_note: Label = _label("Android only. Google demo ad IDs are fixed. The demo-ad button grants a test-only permission; it does not validate UMP consent. Real purchases are disabled.", 12)
	native_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(native_note)
	content.add_child(_button("Connect native Google Play SDK", native_billing.connect_store))
	content.add_child(_button("Query native purchases", native_billing.restore))
	content.add_child(_button("Verify real purchases are disabled", native_billing.purchase))
	content.add_child(_button("Load Google demo interstitial", func() -> void:
		native_ads.set_consent_allowed(true)
		native_ads.load_ad()
	))
	content.add_child(_button("Show Google demo interstitial", native_ads.show_ad))
	content.add_child(_button("Request native UMP status", native_consent.request_update))
	content.add_child(_button("Show native UMP form", native_consent.show_form))
	content.add_child(_label("Recent results", 18))
	log_label = _label("", 12)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(log_label)
	lab.hide()

func _build_ad_overlay() -> void:
	ad_overlay = PanelContainer.new()
	ad_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	ad_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ad_overlay.add_theme_stylebox_override("panel", _box(INK, 0))
	ad_overlay.z_index = 20
	add_child(ad_overlay)
	var center: CenterContainer = CenterContainer.new()
	ad_overlay.add_child(center)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	center.add_child(content)
	var heading: Label = _label("SIMULATED AD", 27)
	content.add_child(heading)
	var message: Label = _label("No network request. No money involved.", 14)
	content.add_child(message)
	test_reward_button = _button("Earn test reward & return", func() -> void:
		ads.earn_test_reward()
		ads.dismiss_rewarded()
	)
	content.add_child(test_reward_button)
	content.add_child(_button("Close without reward", _dismiss_simulated_ad))
	ad_overlay.hide()

func _simulate_purchase(outcome: String) -> void:
	billing.outcome = outcome
	billing.purchase()

func _simulate_consent(outcome: String) -> void:
	consent.outcome = outcome
	consent.request_update()

func _simulate_ad(fail: bool) -> void:
	ads.fail_load = fail
	ads.load_ad()

func _label(value: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_color_override("font_color", INK)
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _button(value: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = value
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	return button

func _box(color: Color, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	return box

func _open_collection(choosing: bool = false) -> void:
	collection_panel.open(progress, choosing)
	_sync_pause()

func _close_collection() -> void:
	if upgrade_panel.visible:
		_close_upgrade()
		return
	collection_panel.hide()
	_sync_pause()
	_update_hud(false)
	if phase == "celebrating":
		collect_reward_button.text = "Choose a character · %d saved" % progress.choice_tokens if progress.choice_tokens > 0 else "View collection · %d / 56" % progress.collected.size()

func _collect_character(character: int) -> void:
	var before: Dictionary = progress.snapshot()
	if not progress.collect_character(character):
		return
	if not store.save(progress):
		# Preserve the live round's transient selection/timers while rolling back only ownership.
		progress.collected.assign(before.collected)
		progress.choice_tokens = int(before.choice_tokens)
		collection_panel.refresh()
		collection_panel.summary.text = "Couldn't save. Your choice is still available. Try again."
		return
	collection_panel.refresh()
	collection_panel.celebrate_claim(character)
	collection_panel.summary.text = "%s collected! %d / 56 in your collection.\n%d choices saved." % [PeopleCatalog.NAMES[character], progress.collected.size(), progress.choice_tokens]
	_update_hud(false)

func _apply_palette() -> void:
	var old_ink: Color = INK
	var old_muted: Color = MUTED
	GamePalette.configure(progress.dark_mode, progress.background)
	INK = GamePalette.ink
	MUTED = GamePalette.muted
	_build_theme()
	_recolor(self, old_ink, old_muted)
	backdrop.queue_redraw()
	stats_panel.add_theme_stylebox_override("panel", GameStyle.surface(GamePalette.card, 20, 6))
	round_score_panel.add_theme_stylebox_override("panel", GameStyle.surface(GameStyle.gold_surface(), 15, 0))
	round_score_label.add_theme_color_override("font_color", GameStyle.accent())
	completion.add_theme_stylebox_override("panel", GameStyle.surface(GamePalette.card, 24, 18))
	progress_bar.add_theme_stylebox_override("background", GameStyle.surface(GamePalette.panel, 3, 0))
	progress_bar.add_theme_stylebox_override("fill", GameStyle.surface(GameStyle.primary(), 3, 0))
	for overlay: PanelContainer in [pause_menu, lab, ad_overlay]:
		if overlay != null:
			overlay.add_theme_stylebox_override("panel", GameStyle.surface(GamePalette.background, 0, 0))
	for panel: PanelContainer in themed_panels:
		panel.add_theme_stylebox_override("panel", GameStyle.surface(GamePalette.panel, 18, 14))
	for button: Button in [next_level_button, collection_button, settings_button, collect_reward_button]:
		GameStyle.skin_button(button, button == next_level_button or button == collection_button)
	collect_reward_button.add_theme_stylebox_override("normal", GameStyle.surface(GameStyle.gold_surface(), 14, 12))
	collect_reward_button.add_theme_color_override("font_color", GameStyle.accent())
	for tile: PortraitTile in tiles:
		tile.queue_redraw()
	if collection_panel.visible:
		collection_panel.refresh()

func _recolor(node: Node, old_ink: Color, old_muted: Color) -> void:
	if node is Label:
		var label: Label = node as Label
		var color: Color = label.get_theme_color("font_color")
		if color == old_muted:
			label.add_theme_color_override("font_color", MUTED)
		elif color == old_ink:
			label.add_theme_color_override("font_color", INK)
	for child: Node in node.get_children():
		_recolor(child, old_ink, old_muted)

func _build_monetization() -> void:
	upgrade_panel = UpgradePanel.new()
	add_child(upgrade_panel)
	upgrade_panel.closed.connect(_close_upgrade)
	upgrade_panel.purchase_requested.connect(func() -> void: billing.purchase())
	upgrade_panel.restore_requested.connect(billing.restore)
	upgrade_panel.access_requested.connect(billing.redeem_access)
	upgrade_panel.access_clear_requested.connect(billing.clear_access)
	peek_offer = PeekOffer.new()
	add_child(peek_offer)
	peek_offer.closed.connect(_close_peek_offer)
	peek_offer.watch_requested.connect(_watch_peek_ad)
	# Godot GUI hit testing follows tree order, independently of CanvasItem z_index.
	move_child(ad_overlay, -1)
	peek_offer.upgrade_requested.connect(func() -> void:
		_close_peek_offer()
		_open_upgrade()
	)

func _open_upgrade() -> void:
	if monetization.production and not native_billing.product_available:
		native_billing.restore()
	upgrade_panel.refresh(billing)
	upgrade_panel.show()
	_sync_pause()

func _close_upgrade() -> void:
	upgrade_panel.hide()
	_sync_pause()

func _plus_changed(value: bool) -> void:
	progress.plus_enabled = value
	if not billing.unlocked_themes().has(progress.preferred_theme):
		progress.preferred_theme = -1
		theme_choice.select(0)
	if collection_panel.visible:
		collection_panel.refresh()
	upgrade_panel.refresh(billing)
	_refresh_peek()
	_checkpoint()

func _process(_delta: float) -> void:
	if peek_button != null:
		_refresh_peek()

func _refresh_peek() -> void:
	var model: MatchRound = progress.round_state
	peek_button.disabled = phase != "playing" or model.opening or model.resolving or model.peeking or model.complete() or model.peek_used
	var caption: String = "Quick Peek · Used" if model.peek_used else "Quick Peek · Ready" if billing.has_plus() or model.peek_earned else "Quick Peek · Watch ad"
	if peek_button.text != caption:
		peek_button.text = caption
		GameStyle.skin_button(peek_button, caption.ends_with("Ready"))

func _quick_peek() -> void:
	var model: MatchRound = progress.round_state
	if phase != "playing" or get_tree().paused or model.opening or model.resolving or model.complete() or model.peek_used:
		return
	if model.can_peek(billing.has_plus()):
		_run_peek()
	else:
		peek_offer.open(use_native_rewarded, monetization.production)
		_sync_pause()

func _run_peek() -> void:
	var model: MatchRound = progress.round_state
	if not model.begin_peek(billing.has_plus()):
		return
	if not store.save(progress):
		model.peek_used = false
		model.finish_peek()
		_checkpoint()
		return
	var ticket: int = epoch
	phase = "peeking"
	peek_started_usec = 0
	status_label.text = "One more look…"
	for index: int in range(tiles.size()):
		if not model.removed.has(index):
			tiles[index].flip_to(true)
	await get_tree().create_timer(0.25, false).timeout
	if ticket != epoch:
		return
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	peek_started_usec = Time.get_ticks_usec()
	await get_tree().create_timer(PREVIEW_SECONDS, false).timeout
	if ticket != epoch:
		return
	phase = "peek_concealing"
	for index: int in range(tiles.size()):
		if not model.removed.has(index) and not model.selected.has(index):
			tiles[index].flip_to(false)
	await get_tree().create_timer(0.25, false).timeout
	if ticket != epoch:
		return
	model.finish_peek()
	phase = "playing"
	_refresh_peek()
	status_label.text = "Find their match." if not model.selected.is_empty() else "Tap two characters to find a pair."
	_refresh_peek()

func _reward_provider() -> AdsService:
	return native_ads if use_native_rewarded else ads

func _watch_peek_ad() -> void:
	if not peek_offer.visible or billing.has_plus() or progress.round_state.peek_earned or progress.round_state.peek_used:
		return
	var provider: AdsService = _reward_provider()
	if monetization.production:
		if not monetization.ads_enabled():
			peek_offer.detail.text = "Ads are unavailable. You can keep playing."
			return
		if not native_consent.can_request_ads:
			waiting_for_consent = true
			peek_offer.watch.disabled = true
			peek_offer.detail.text = "Checking privacy choices…"
			native_consent.request_update()
			return
	elif monetization.development_enabled():
		provider.set_consent_allowed(true)
	else:
		return
	peek_offer.watch.disabled = true
	provider.load_rewarded(progress.round_state.board_key())
	var request: String = provider.reward_request
	await get_tree().create_timer(25.0).timeout
	if request == provider.reward_request and provider.rewarded_state in ["loading", "initializing"]:
		provider.cancel_rewarded()
		peek_offer.detail.text = "The ad timed out. Keep playing or try again."
		peek_offer.watch.disabled = false

func _close_peek_offer() -> void:
	waiting_for_consent = false
	peek_offer.hide()
	ads.cancel_rewarded()
	native_ads.cancel_rewarded()
	_sync_pause()

func _rewarded_event(key: String, state: String, detail: String, provider: AdsService) -> void:
	if key != progress.round_state.board_key():
		return
	peek_offer.detail.text = detail
	peek_offer.watch.disabled = state in ["loading", "initializing", "showing"]
	if state == "ready" and peek_offer.visible and not backgrounded and not billing.has_plus():
		provider.show_rewarded()
		return # The nested showing event owns visibility and pause state.
	elif state == "ready":
		peek_offer.watch.disabled = false
	if provider == native_ads:
		native_reward_showing = state == "showing"
	else:
		ad_overlay.visible = state == "showing"
		test_reward_button.visible = ad_overlay.visible
	if state == "dismissed":
		peek_offer.hide()
		status_label.text = "Quick Peek is ready. Tap when you want another look." if progress.round_state.peek_earned else "No peek used. Keep matching."
	_sync_pause()
	_refresh_peek()

func _peek_reward_earned(key: String, _request: String) -> void:
	if not progress.round_state.earn_peek(key):
		return
	# One persisted board allowance also deduplicates callbacks after a restart.
	_checkpoint()
	_refresh_peek()

func _dismiss_simulated_ad() -> void:
	if ads.rewarded_state == "showing":
		ads.dismiss_rewarded()
	else:
		ads.dismiss()

func _privacy_updated(state: String, detail: String) -> void:
	if not monetization.production:
		return
	if privacy_button != null:
		privacy_button.visible = native_consent.privacy_options_required
		privacy_button.disabled = state in ["updating", "showing"]
	if not waiting_for_consent or state in ["updating", "showing"]:
		return
	waiting_for_consent = false
	if not peek_offer.visible:
		return
	peek_offer.watch.disabled = false
	if native_consent.can_request_ads and not backgrounded:
		_watch_peek_ad.call_deferred()
	else:
		peek_offer.detail.text = detail + " Keep playing or try again."
