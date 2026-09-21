class_name CollectionCard
extends Button
## Owned cards have a gold frame, stage and animated full-body portrait.
var character: int = 0
var owned: bool = false
var locked: bool = false
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
var reduced_motion: bool = false
var animation_active: bool = false
var person: CollectionPerformer
var name_label: Label
var badge: Label
var feedback_left: float = 0.0
var tap_cooldown: float = 0.0

func _ready() -> void:
	flat = true
	clip_contents = true
	custom_minimum_size = Vector2(0, 212)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_meta("character", character)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	person = CollectionPerformer.new()
	person.variant = character
	person.phase = character * 0.83
	person.style = character % 3
	person.cheering = owned
	person.reduced_motion = true
	add_child(person)
	name_label = GameStyle.label(PeopleCatalog.NAMES[character], 15)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)
	badge = GameStyle.label("COLLECTED" if owned else "PLUS THEME" if locked else "TO DISCOVER", 9)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_color_override("font_color", GameStyle.accent() if owned else GamePalette.muted)
	add_child(badge)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	person.scale = Vector2.ONE * minf(1.23, (size.x - 22) / 64.0)
	person.position = Vector2(size.x / 2, 30)
	name_label.position = Vector2(4, 166)
	name_label.size = Vector2(size.x - 8, 22)
	badge.position = Vector2(4, 188)
	badge.size = Vector2(size.x - 8, 18)
	queue_redraw()

func react(kind: int) -> bool:
	if not owned or not animation_active or tap_cooldown > 0.0:
		return false
	tap_cooldown = 0.20
	feedback_left = CollectionPerformer.DURATION
	badge.text = ["SIDE STEP!", "HAPPY FEET!", "TWIST!", "HEY THERE!", "HELLO!"][kind]
	if not reduced_motion:
		person.perform(kind)
	return true

func stop_feedback() -> void:
	feedback_left = 0.0
	tap_cooldown = 0.0
	if person != null:
		person.stop_reaction()
	if badge != null:
		badge.text = "COLLECTED" if owned else "PLUS THEME" if locked else "TO DISCOVER"

func _process(delta: float) -> void:
	tap_cooldown = maxf(0.0, tap_cooldown - delta)
	if feedback_left > 0.0:
		feedback_left = maxf(0.0, feedback_left - delta)
		if feedback_left == 0.0:
			stop_feedback()
	# The panel runs while gameplay is paused. Backgrounding and Reduce motion
	# explicitly suppress these cosmetic animations; scrolled-off cards stop too.
	var viewport_rect: Rect2 = (get_parent().get_parent() as Control).get_global_rect()
	var moving: bool = owned and animation_active and not reduced_motion and is_visible_in_tree() and viewport_rect.intersects(get_global_rect())
	if not moving and person.reaction >= 0:
		stop_feedback()
	if person.reduced_motion == moving:
		person.reduced_motion = not moving

func _draw() -> void:
	var box: StyleBoxFlat = GameStyle.surface(GameStyle.gold_surface() if owned else GamePalette.card, 18, 0)
	box.border_color = GameStyle.primary() if selected else Color("cc974c") if owned else GamePalette.muted * Color(1, 1, 1, 0.2)
	box.set_border_width_all(3 if selected else 2 if owned else 1)
	draw_style_box(box, Rect2(Vector2(1, 1), size - Vector2(2, 2)))
	if owned:
		draw_circle(Vector2(size.x / 2, 89), minf(size.x * 0.42, 53), Color("bd873b") * Color(1, 1, 1, 0.12))
		draw_line(Vector2(16, 159), Vector2(size.x - 16, 159), Color("cc974c") * Color(1, 1, 1, 0.5), 1.0, true)
		# Corner diamonds make ownership readable without relying on color alone.
		for x: float in [13.0, size.x - 13.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(x, 10), Vector2(x + 3, 14), Vector2(x, 18), Vector2(x - 3, 14)]), Color("cc974c"))
	if has_focus():
		var focus: StyleBoxFlat = GameStyle.surface(Color.TRANSPARENT, 14, 0)
		focus.set_border_width_all(2)
		focus.border_color = GamePalette.ink
		draw_style_box(focus, Rect2(Vector2(5, 5), size - Vector2(10, 10)))
