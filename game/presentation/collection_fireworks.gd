class_name CollectionFireworks
extends Control
## A single reusable, bounded burst layer. Never captures input or grants rewards.
const LIFETIME: float = 1.15
const COLORS: Array[Color] = [Color("edb957"), Color("e28570"), Color("71beac"), Color("c6a2e8")]
var age: float = LIFETIME
var reduced_motion: bool = false
var origins: Array[Vector2] = []
var phase: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_process(false)

func burst(center: Vector2, reduce: bool, confirmed: bool = false) -> void:
	reduced_motion = reduce
	age = 0.0
	phase = randf_range(0.0, TAU)
	origins.clear()
	for offset: Vector2 in [Vector2(-40, -34), Vector2(40, -54), Vector2(0, 4)] if confirmed else [Vector2(-27, -28), Vector2(27, -46)]:
		origins.append(Vector2(clampf(center.x + offset.x, 45, maxf(45, size.x - 45)), clampf(center.y + offset.y, 48, maxf(48, size.y - 48))))
	set_process(true)
	queue_redraw()

func clear() -> void:
	age = LIFETIME
	origins.clear()
	set_process(false)
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	if age >= LIFETIME:
		clear()
	else:
		queue_redraw()

func _draw() -> void:
	for index: int in range(origins.size()):
		var t: float = age - index * 0.10
		if t < 0.0:
			continue
		var fade: float = clampf(1.0 - t / 0.9, 0.0, 1.0)
		for ray: int in range(16):
			var direction: Vector2 = Vector2.from_angle(ray * TAU / 16.0 + phase + index * 0.25)
			var speed: float = 0.72 + float((ray * 7 + index * 3) % 9) / 18.0
			var radius: float = 19.0 if reduced_motion else 5.0 + 68.0 * (1.0 - exp(-t * 4.2)) * speed
			var fall: Vector2 = Vector2.ZERO if reduced_motion else Vector2(0, t * t * 25.0)
			var point: Vector2 = origins[index] + direction * radius + fall
			var color: Color = COLORS[(ray + index) % COLORS.size()]
			color.a = fade
			draw_line(point - direction * (3.0 if reduced_motion else 9.0 * fade), point, color, 2.6, true)
			draw_circle(point, 1.8, color)
