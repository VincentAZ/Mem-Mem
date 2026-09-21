class_name PortraitTile
extends Button
var variant: int = 0
var face_up: bool = true
var delighted: bool = false:
	set(value):
		delighted = value
		queue_redraw()
var flipping: bool = false
var chosen: bool = false:
	set(value):
		chosen = value
		queue_redraw()
var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		if value and flipping:
			if _flip != null:
				_flip.kill()
			face_up = _target_face
			flipping = false
			scale = Vector2.ONE
			queue_redraw()
var keyboard_focus: bool = true
var _flip: Tween
var _target_face: bool = true

func _ready() -> void:
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	focus_mode = Control.FOCUS_ALL
	pressed.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			keyboard_focus = false
		elif event is InputEventKey:
			keyboard_focus = true
	)

func flip_to(show_face: bool) -> void:
	if face_up == show_face and not flipping:
		return
	if _flip != null:
		_flip.kill()
	_target_face = show_face
	if reduced_motion:
		face_up = show_face
		flipping = false
		scale = Vector2.ONE
		queue_redraw()
		return
	flipping = true
	pivot_offset = size * 0.5
	_flip = create_tween()
	_flip.tween_property(self, "scale:x", 0.015, 0.11).set_trans(Tween.TRANS_SINE)
	_flip.tween_callback(func() -> void:
		face_up = show_face
		queue_redraw()
	)
	_flip.tween_property(self, "scale:x", 1.0, 0.11).set_trans(Tween.TRANS_SINE)
	_flip.tween_callback(func() -> void: flipping = false)

func _draw() -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = GamePalette.card if face_up else GamePalette.back
	box.set_corner_radius_all(17)
	box.shadow_color = Color(0.14, 0.23, 0.19, 0.08)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 4)
	if chosen or (has_focus() and keyboard_focus):
		box.border_color = Color("b77952")
		box.set_border_width_all(3)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	# Uniform scaling preserves proportions on 2- and 3-column boards.
	var fit: float = minf(size.x / 166.0, size.y / 174.0)
	var offset: Vector2 = (size - Vector2(166, 174) * fit) * 0.5
	draw_set_transform(offset, 0, Vector2.ONE * fit)
	if face_up:
		_draw_portrait()
	else:
		var rim: StyleBoxFlat = StyleBoxFlat.new()
		rim.bg_color = Color.TRANSPARENT
		rim.border_color = Color("668275")
		rim.set_border_width_all(1)
		rim.set_corner_radius_all(12)
		draw_style_box(rim, Rect2(8, 8, 150, 158))
		for ring_offset: float in [-14.0, 14.0]:
			draw_arc(Vector2(83 + ring_offset, 83), 23, 0, TAU, 48, Color("ddcdb1"), 2.0, true)
		draw_circle(Vector2(83, 120), 2.5, Color("ddcdb1"))
		draw_arc(Vector2(83, 83), 43, -0.75, 0.75, 20, Color("668275"), 1.0, true)
		draw_arc(Vector2(83, 83), 43, PI - 0.75, PI + 0.75, 20, Color("668275"), 1.0, true)
	draw_set_transform(Vector2.ZERO)

func _draw_portrait() -> void:
	draw_circle(Vector2(83, 83), 73, PeopleCatalog.BACKDROP[PeopleCatalog.theme_of(variant)].darkened(0.18 if GamePalette.dark else 0.0))
	var crop: Rect2 = PeopleCatalog.portrait_region(variant, delighted)
	var fit: float = minf(156.0 / crop.size.x, 164.0 / crop.size.y)
	var extent: Vector2 = crop.size * fit
	draw_texture_rect_region(PeopleCatalog.atlas(variant, delighted), Rect2(Vector2(83, 87) - extent / 2, extent), crop)
