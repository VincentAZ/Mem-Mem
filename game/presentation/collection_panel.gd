class_name CollectionPanel
extends PanelContainer
signal upgrade_requested
signal closed
signal character_chosen(character: int)
var progress: GameProgress
var selected: int = -1
var filter_theme: int = -1
var owned_only: bool = true
const DRAG_DEADZONE := 16
var scroll: ScrollContainer
var grid: GridContainer
var summary: Label
var drag_tracking: bool = false
var drag_scrolling: bool = false
var drag_origin: Vector2 = Vector2.ZERO
var drag_scroll_origin: int = 0
var tally: Label
var empty: Label
var action: Button
var filters: OptionButton
var mine: Button
var discover: Button
var back: Button
var entries: Array[Button] = []
var animation_allowed: bool = true
var fireworks: CollectionFireworks
var audio: GameAudio = GameAudio.new()
var last_reactions: Dictionary = {}
var last_selection_msec: int = -1000
var presentation_revision: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 12
	audio.allow_while_paused = true
	audio.suspended = true
	add_child(audio)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	back = Button.new()
	back.text = "‹  Back to game"
	back.custom_minimum_size.y = 44
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: closed.emit())
	column.add_child(back)
	var heading: HBoxContainer = HBoxContainer.new()
	column.add_child(heading)
	var title: Label = GameStyle.label("The collection", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	tally = GameStyle.label("0 / 56", 21)
	heading.add_child(tally)
	summary = GameStyle.label("", 13, true)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	column.add_child(tabs)
	mine = Button.new()
	mine.text = "My collection"
	discover = Button.new()
	discover.text = "Discover all"
	for tab: Button in [mine, discover]:
		tab.custom_minimum_size.y = 46
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(tab)
	mine.pressed.connect(_set_view.bind(true))
	discover.pressed.connect(_set_view.bind(false))
	filters = OptionButton.new()
	filters.custom_minimum_size.y = 44
	filters.add_item("All themes", -1)
	for i: int in range(PeopleCatalog.THEMES.size()):
		filters.add_item(PeopleCatalog.THEMES[i], i)
	filters.item_selected.connect(func(index: int) -> void:
		filter_theme = index - 1
		selected = -1
		refresh()
	)
	column.add_child(filters)
	# Cards are buttons, which stop pointer events. Pass lets a touch drag reach this
	# scroller; the deadzone keeps a short tap as a character selection.
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = DRAG_DEADZONE
	column.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 3
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	empty = GameStyle.label("", 16, true)
	empty.custom_minimum_size.y = 120
	empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(empty)
	action = Button.new()
	action.custom_minimum_size.y = 52
	action.add_theme_font_size_override("font_size", 14)
	action.pressed.connect(func() -> void:
		if selected >= 0:
			character_chosen.emit(selected)
	)
	column.add_child(action)
	fireworks = CollectionFireworks.new()
	fireworks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fireworks.z_index = 2
	add_child(fireworks)
	visibility_changed.connect(_sync_animation)
	hide()

func open(model: GameProgress, choosing: bool = false) -> void:
	progress = model
	selected = -1
	owned_only = not choosing
	filter_theme = -1
	filters.select(0)
	refresh()
	show()

func _set_view(only_owned: bool) -> void:
	owned_only = only_owned
	selected = -1
	refresh()

func refresh() -> void:
	presentation_revision += 1
	fireworks.clear()
	audio.stop_all()
	add_theme_stylebox_override("panel", GameStyle.surface(GamePalette.background, 0, 0))
	tally.text = "%02d / %d" % [progress.collected.size(), PeopleCatalog.COUNT]
	summary.text = "%d character %s saved\n100%% accuracy earns your choice from unlocked themes." % [progress.choice_tokens, "choice" if progress.choice_tokens == 1 else "choices"]
	if progress.collected.size() == PeopleCatalog.COUNT:
		summary.text = "All 56 collected! Your extra choices stay saved."
	mine.text = "My collection · %d" % progress.collected.size()
	GameStyle.skin_button(mine, owned_only)
	GameStyle.skin_button(discover, not owned_only)
	GameStyle.skin_button(back)
	GameStyle.skin_button(action, true)
	for child: Node in grid.get_children():
		child.free()
	entries.clear()
	for character: int in range(PeopleCatalog.COUNT):
		if (filter_theme >= 0 and PeopleCatalog.theme_of(character) != filter_theme) or (owned_only and not progress.collected.has(character)):
			continue
		var entry: CollectionCard = CollectionCard.new()
		entry.character = character
		entry.owned = progress.collected.has(character)
		entry.locked = not PeopleCatalog.is_unlocked(character, progress.plus_enabled)
		entry.selected = character == selected
		entry.reduced_motion = progress.reduced_motion
		entry.tooltip_text = "%s · %s" % [PeopleCatalog.NAMES[character], "Collected" if entry.owned else "Not collected"]
		entry.pressed.connect(_pick.bind(character))
		grid.add_child(entry)
		entries.append(entry)
	empty.visible = entries.is_empty()
	scroll.visible = not entries.is_empty()
	empty.text = "Your collection starts here.\nFinish a board with 100% accuracy,\nthen choose a character from an unlocked theme." if progress.collected.is_empty() else "No collected characters in this theme yet.\nTry Discover all."
	_update_action()
	_sync_animation()

func _pick(character: int) -> void:
	if not visible or not animation_allowed:
		return
	if not PeopleCatalog.is_unlocked(character, progress.plus_enabled) and not progress.collected.has(character):
		upgrade_requested.emit()
		return
	selected = character
	var picked: CollectionCard
	for entry: CollectionCard in entries:
		entry.selected = entry.character == character
		if entry.selected:
			picked = entry
	_update_action()
	if picked == null:
		return
	if picked.owned:
		var options: Array[int] = [0, 1, 2]
		if PeopleCatalog.can_wave(character):
			options.append_array([3, 4])
		options.erase(int(last_reactions.get(character, -1)))
		var kind: int = options[randi_range(0, options.size() - 1)]
		if picked.react(kind):
			last_reactions[character] = kind
			audio.play_cue(&"dance" if kind < 3 else &"wave")
	elif progress.choice_tokens > 0 and Time.get_ticks_msec() - last_selection_msec >= 200:
		last_selection_msec = Time.get_ticks_msec()
		picked.celebrate_selection()
		_burst_at(picked)

func _burst_at(card: CollectionCard, confirmed: bool = false) -> void:
	var center: Vector2 = card.global_position - global_position + Vector2(card.size.x / 2, 76)
	fireworks.burst(center, progress.reduced_motion, confirmed)
	audio.play_cue(&"fireworks")

func celebrate_claim(character: int) -> void:
	# Wait for refreshed cards to be laid out; navigation cancels stale celebrations.
	var revision: int = presentation_revision
	await get_tree().process_frame
	if revision != presentation_revision or not visible or not animation_allowed:
		return
	for entry: CollectionCard in entries:
		if entry.character == character and entry.owned:
			entry.celebrate_selection()
			_burst_at(entry, true)
			return

func _update_action() -> void:
	action.disabled = selected < 0 or progress.choice_tokens <= 0 or progress.collected.has(selected) or not PeopleCatalog.is_unlocked(selected, progress.plus_enabled)
	action.visible = not owned_only
	if selected < 0:
		action.text = "Choose a character above" if progress.choice_tokens > 0 else "Perfect a board to earn a choice"
	elif progress.collected.has(selected):
		action.text = PeopleCatalog.NAMES[selected] + " is in your collection"
	elif progress.choice_tokens > 0:
		action.text = "Collect %s · use 1 choice" % PeopleCatalog.NAMES[selected]
	else:
		action.text = "Earn a choice to collect " + PeopleCatalog.NAMES[selected]

func set_animation_active(value: bool) -> void:
	animation_allowed = value
	_sync_animation()

func _sync_animation() -> void:
	audio.enabled = progress.sound if progress != null else false
	audio.suspended = not (animation_allowed and visible)
	if audio.suspended and fireworks != null:
		fireworks.clear()
	for entry: CollectionCard in entries:
		entry.animation_active = animation_allowed and visible
		entry.set_process(entry.animation_active)
		if not entry.animation_active:
			entry.stop_feedback()
			entry.person.reduced_motion = true

func _input(event: InputEvent) -> void:
	# Touchscreens drag-scroll through ScrollContainer once children pass events.
	# Pointer drags need the same gesture where no touchscreen is reported.
	if DisplayServer.is_touchscreen_available() or scroll == null:
		return
	if not visible or not scroll.visible:
		drag_tracking = false
		drag_scrolling = false
		return
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event as InputEventMouseButton
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		if button.pressed:
			drag_tracking = false
			drag_scrolling = false
			if not _can_drag_from(button.position):
				return
			drag_tracking = true
			drag_origin = button.position
			drag_scroll_origin = scroll.scroll_vertical
		else:
			drag_tracking = false
			drag_scrolling = false
	elif event is InputEventMouseMotion and drag_tracking:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return
		var traveled: float = motion.position.y - drag_origin.y
		if absf(traveled) < float(DRAG_DEADZONE):
			return
		if not drag_scrolling:
			drag_scrolling = true
			scroll.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
		var slop: float = signf(traveled) * float(DRAG_DEADZONE)
		scroll.scroll_vertical = drag_scroll_origin - int(traveled - slop)
		get_viewport().set_input_as_handled()

func _can_drag_from(point: Vector2) -> bool:
	if not scroll.get_global_rect().has_point(point):
		return false
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	if bar.visible and bar.get_global_rect().has_point(point):
		return false
	return bar.max_value > bar.page

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()
