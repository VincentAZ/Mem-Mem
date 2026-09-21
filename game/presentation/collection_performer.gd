class_name CollectionPerformer
extends Walker
## Short cutout performances, separate from the board's walking/cheering animation.
const DURATION: float = 1.65
var reaction: int = -1
var reaction_age: float = 0.0

func perform(kind: int) -> void:
	reaction = kind
	reaction_age = 0.0
	queue_redraw()

func stop_reaction() -> void:
	reaction = -1
	reaction_age = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	super._process(delta)
	if reaction >= 0:
		reaction_age += delta
		if reaction_age >= DURATION:
			stop_reaction()

func _draw() -> void:
	if reaction < 0 or reduced_motion:
		super._draw()
		return
	var source: Rect2 = PeopleCatalog.body_region(variant, true)
	var height: float = minf(112.0, (61.0 if PeopleCatalog.motion_profile(variant) == "walk" else 84.0) * source.size.y / source.size.x)
	var width: float = height * source.size.x / source.size.y
	var t: float = reaction_age
	var envelope: float = smoothstep(0.0, 0.16, t) * (1.0 - smoothstep(DURATION - 0.3, DURATION, t))
	var beat: float = sin(t * TAU * 2.4)
	var x: float = 0.0
	var hop: float = 0.0
	var tilt: float = 0.0
	var stretch: Vector2 = Vector2.ONE
	if reaction == 0: # Side step: alternating footwork and counter-lean.
		x = sin(t * TAU * 1.2) * 6.0 * envelope
		hop = -absf(beat) * 3.0 * envelope
		tilt = -sin(t * TAU * 1.2) * 0.055 * envelope
	elif reaction == 1: # Two-foot bounce with a soft landing.
		hop = -absf(sin(t * TAU * 1.8)) * 9.0 * envelope
		stretch = Vector2(1.0 - beat * 0.025 * envelope, 1.0 + beat * 0.025 * envelope)
		tilt = beat * 0.03 * envelope
	elif reaction == 2: # Twist: feet and shoulders move in opposite directions.
		x = beat * 3.0 * envelope
		tilt = -beat * 0.085 * envelope
		stretch.x = 1.0 - absf(beat) * 0.07 * envelope
	else:
		tilt = sin(t * TAU * 1.2) * 0.025 * envelope
		hop = -absf(beat) * envelope
	draw_set_transform(Vector2(0, 100), 0, Vector2(1, 0.13))
	draw_circle(Vector2.ZERO, 20, Color(0.08, 0.12, 0.14, 0.12))
	var body: Transform2D = Transform2D(tilt, stretch, 0.0, Vector2(x, 100 + hop))
	draw_set_transform_matrix(body)
	var texture: Texture2D = PeopleCatalog.atlas(variant, true)
	if PeopleCatalog.motion_profile(variant) != "walk":
		draw_texture_rect_region(texture, Rect2(-width / 2, -height, width, height), source)
	elif reaction < 3:
		# Keep the torso intact; pivot the lower leg strips at their hidden hip seam.
		var leg_height: float = height * 0.40
		for leg: int in range(2):
			var swing: float = sin(t * TAU * 2.4 + leg * PI) * (0.11 if reaction == 0 else 0.065) * envelope
			var hip: Vector2 = Vector2(0, -leg_height)
			draw_set_transform_matrix(body * Transform2D(swing, hip))
			var region: Rect2 = Rect2(source.position + Vector2(leg * source.size.x / 2, source.size.y * 0.60), Vector2(source.size.x / 2, source.size.y * 0.40))
			draw_texture_rect_region(texture, Rect2(-width / 2 + leg * width / 2, 0, width / 2, leg_height), region)
		draw_set_transform_matrix(body)
		draw_texture_rect_region(texture, Rect2(-width / 2, -height, width, height * 0.61), Rect2(source.position, Vector2(source.size.x, source.size.y * 0.61)))
	else:
		# Raised-arm poses have separate outer strips; the center/head stay stable.
		# Clapping poses use dances instead, avoiding an anatomically false wave.
		var arm_width: float = width * 0.28
		var arm_height: float = height * 0.40
		draw_texture_rect_region(texture, Rect2(-width / 2, -height + arm_height, width, height - arm_height), Rect2(source.position + Vector2(0, source.size.y * 0.40), Vector2(source.size.x, source.size.y * 0.60)))
		draw_texture_rect_region(texture, Rect2(-width * 0.22, -height, width * 0.44, arm_height), Rect2(source.position + Vector2(source.size.x * 0.28, 0), Vector2(source.size.x * 0.44, source.size.y * 0.40)))
		for arm: int in range(2):
			var sign_value: float = -1.0 if arm == 0 else 1.0
			var pivot: Vector2 = Vector2(sign_value * width * 0.22, -height + arm_height * 0.85)
			var angle: float = sin(t * TAU * (3.2 if reaction == 3 else 2.5) + arm * PI) * 0.20 * envelope
			if reaction == 3 and arm == 1:
				angle = 0.0
			draw_set_transform_matrix(body * Transform2D(angle, pivot))
			var corner: Vector2 = Vector2(-width / 2 if arm == 0 else width * 0.22, -height)
			var region: Rect2 = Rect2(source.position + Vector2(0 if arm == 0 else source.size.x * 0.72, 0), Vector2(source.size.x * 0.28, source.size.y * 0.40))
			draw_texture_rect_region(texture, Rect2(corner - pivot, Vector2(arm_width, arm_height)), region)
	draw_set_transform(Vector2.ZERO)
