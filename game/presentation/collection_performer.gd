class_name CollectionPerformer
extends Walker
## Short cutout performances, separate from the board's walking/cheering animation.
const DURATION: float = 1.65
const JUMP_CLAP: int = 5
var reaction: int = -1
var reaction_age: float = 0.0
var _clap_mesh: ArrayMesh = ArrayMesh.new()

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
	var source: Rect2 = PeopleCatalog.clap_region(variant) if reaction == JUMP_CLAP else PeopleCatalog.body_region(variant, true)
	# Leave headroom for the selection jumps inside the collection tile.
	var height: float = minf(106.0 if reaction == JUMP_CLAP else 112.0, (61.0 if PeopleCatalog.motion_profile(variant) == "walk" else 84.0) * source.size.y / source.size.x)
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
	elif reaction == JUMP_CLAP:
		var jump: float = absf(sin(t * PI * 3.0))
		hop = -13.0 * jump * envelope
		stretch = Vector2(1.0 - jump * 0.035 * envelope, 1.0 + jump * 0.035 * envelope)
	else:
		tilt = sin(t * TAU * 1.2) * 0.025 * envelope
		hop = -absf(beat) * envelope
	draw_set_transform(Vector2(0, 100), 0, Vector2(1, 0.13))
	draw_circle(Vector2.ZERO, 20, Color(0.08, 0.12, 0.14, 0.12))
	var body: Transform2D = Transform2D(tilt, stretch, 0.0, Vector2(x, 100 + hop))
	draw_set_transform_matrix(body)
	var texture: Texture2D = PeopleCatalog.clap_atlas(variant) if reaction == JUMP_CLAP else PeopleCatalog.atlas(variant, true)
	if reaction == JUMP_CLAP:
		_draw_clap(texture, source, width, height, body, t, envelope)
	elif PeopleCatalog.motion_profile(variant) != "walk":
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

func _draw_clap(texture: Texture2D, source: Rect2, width: float, height: float, _body: Transform2D, t: float, envelope: float) -> void:
	# Purpose-made clapping poses keep the original character intact. A continuous
	# mesh opens/closes the forearms slightly, without detached strips or body seams.
	var hand_y: float = 0.30 if PeopleCatalog.motion_profile(variant) == "walk" else 0.60
	var clap: float = (0.5 - 0.5 * cos(t * TAU * 3.0))
	var vertices: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	const COLUMNS: int = 12
	const ROWS: int = 20
	for row: int in range(ROWS + 1):
		for column: int in range(COLUMNS + 1):
			var uv: Vector2 = Vector2(float(column) / COLUMNS, float(row) / ROWS)
			var chest: float = exp(-pow((uv.y - hand_y) / 0.10, 2.0))
			var spread: float = tanh((uv.x - 0.5) * 16.0) * sin(uv.x * PI)
			var opening: float = spread * chest * (1.0 - clap) * 2.6 * envelope
			vertices.append(Vector3((uv.x - 0.5) * width + opening, (uv.y - 1.0) * height, 0))
			uvs.append((source.position + uv * source.size) / texture.get_size())
	for row: int in range(ROWS):
		for column: int in range(COLUMNS):
			var corner: int = row * (COLUMNS + 1) + column
			indices.append_array([corner, corner + 1, corner + COLUMNS + 1, corner + 1, corner + COLUMNS + 2, corner + COLUMNS + 1])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	_clap_mesh.clear_surfaces()
	_clap_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	draw_mesh(_clap_mesh, texture)
	if clap > 0.90 and envelope > 0.5:
		var contact: Vector2 = Vector2(0, -height * (1.0 - hand_y))
		for direction: float in [-1.0, 1.0]:
			draw_line(contact + Vector2(direction * 6, -2), contact + Vector2(direction * 9, -5), GameStyle.accent(), 1.3, true)
