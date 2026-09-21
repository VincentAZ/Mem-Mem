class_name CollectionPanel
extends PanelContainer
signal closed
signal character_chosen(character: int)
var progress: GameProgress
var selected: int = -1
var filter_theme: int = -1
var owned_only: bool = true
var grid: GridContainer
var summary: Label
var tally: Label
var empty: Label
var action: Button
var filters: OptionButton
var mine: Button
var discover: Button
var back: Button
var entries: Array[Button] = []
var animation_allowed: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 12
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
	tally = GameStyle.label("0 / 24", 21)
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
	for i: int in range(4):
		filters.add_item(PeopleCatalog.THEMES[i], i)
	filters.item_selected.connect(func(index: int) -> void:
		filter_theme = index - 1
		selected = -1
		refresh()
	)
	column.add_child(filters)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 3
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
	add_theme_stylebox_override("panel", GameStyle.surface(GamePalette.background, 0, 0))
	tally.text = "%02d / 24" % progress.collected.size()
	summary.text = "%d %s saved · Next surprise in %d %s\n100%% accuracy earns your choice of any character." % [progress.choice_tokens, "choice" if progress.choice_tokens == 1 else "choices", 3 - progress.discovery_steps, "board" if progress.discovery_steps == 2 else "boards"]
	if progress.collected.size() == 24:
		summary.text = "All 24 collected! Your extra choices stay saved."
	mine.text = "My collection · %d" % progress.collected.size()
	GameStyle.skin_button(mine, owned_only)
	GameStyle.skin_button(discover, not owned_only)
	GameStyle.skin_button(back)
	GameStyle.skin_button(action, true)
	for child: Node in grid.get_children():
		child.free()
	entries.clear()
	for character: int in range(24):
		if (filter_theme >= 0 and character / 6 != filter_theme) or (owned_only and not progress.collected.has(character)):
			continue
		var entry: CollectionCard = CollectionCard.new()
		entry.character = character
		entry.owned = progress.collected.has(character)
		entry.selected = character == selected
		entry.reduced_motion = progress.reduced_motion
		entry.tooltip_text = "%s · %s" % [PeopleCatalog.NAMES[character], "Collected" if entry.owned else "Not collected"]
		entry.pressed.connect(_pick.bind(character))
		grid.add_child(entry)
		entries.append(entry)
	empty.visible = entries.is_empty()
	(grid.get_parent() as ScrollContainer).visible = not entries.is_empty()
	empty.text = "Your collection starts here.\nClear a perfect board to choose anyone,\nor finish 3 boards for a surprise." if progress.collected.is_empty() else "No collected characters in this theme yet.\nTry Discover all."
	_update_action()
	_sync_animation()

func _pick(character: int) -> void:
	selected = character
	for entry: CollectionCard in entries:
		entry.selected = entry.character == character
	_update_action()

func _update_action() -> void:
	action.disabled = selected < 0 or progress.choice_tokens <= 0 or progress.collected.has(selected)
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
	for entry: CollectionCard in entries:
		entry.animation_active = animation_allowed and visible
		entry.set_process(entry.animation_active)
		if not entry.animation_active:
			entry.person.reduced_motion = true

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()
