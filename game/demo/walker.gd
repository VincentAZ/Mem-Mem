class_name Walker
extends Node2D
## Textured cutout motion: full-size authored adults, continuous gait and varied cheers.
var variant: int = 0
var phase: float = 0.0
var style: int = 0
var cheering: bool = false:
	set(value):
		cheering = value
		queue_redraw()
var facing_left: bool = false
var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		set_process(not value)
		queue_redraw()

func _ready() -> void:
	set_process(not reduced_motion)

func _process(delta: float) -> void:
	phase += delta * (3.8 + style * 0.6 if cheering else 7.0 + style * 0.7)
	queue_redraw()

func _draw() -> void:
	var family: int = PeopleCatalog.family(variant)
	var source: Rect2 = AtlasRegions.CHEER[family] if cheering else AtlasRegions.NORMAL[family]
	var height: float = minf(112.0, 61.0 * source.size.y / source.size.x)
	var width: float = height * source.size.x / source.size.y
	var bounce: float = 0.0 if reduced_motion else -absf(sin(phase)) * (2.0 + style * 0.4)
	var tilt: float = 0.0 if reduced_motion else sin(phase * 0.5) * (0.022 if cheering else 0.01)
	draw_set_transform(Vector2(0, 100), 0, Vector2(1, 0.13))
	draw_circle(Vector2.ZERO, 20, Color(0.08, 0.12, 0.14, 0.12))
	var mirror: Vector2 = Vector2(-1, 1) if facing_left else Vector2.ONE
	draw_set_transform(Vector2(0, 100 + bounce), tilt, mirror)
	var texture: Texture2D = PeopleCatalog.atlas(variant, cheering)
	if cheering or reduced_motion:
		draw_texture_rect_region(texture, Rect2(-width / 2, -height, width, height), source)
	else:
		# Two leg strips pivot at the hips; their tops remain covered by the torso.
		var split: float = source.size.y * 0.59
		var thigh: float = height * 0.41
		for leg: int in range(2):
			var swing: float = sin(phase + leg * PI) * 0.055
			draw_set_transform(Vector2(0, 100 + bounce - thigh), tilt + swing, mirror)
			var region: Rect2 = Rect2(source.position + Vector2(leg * source.size.x / 2, split), Vector2(source.size.x / 2, source.size.y - split))
			draw_texture_rect_region(texture, Rect2(-width / 2 + leg * width / 2, 0, width / 2, thigh), region)
		draw_set_transform(Vector2(0, 100 + bounce), tilt, mirror)
		draw_texture_rect_region(texture, Rect2(-width / 2, -height, width, height * 0.60), Rect2(source.position, Vector2(source.size.x, source.size.y * 0.60)))
	# Carry the comparison detail into the walking/cheering representation.
	var crop: Rect2 = PeopleCatalog.portrait_region(variant, cheering)
	var factor: float = height / source.size.y
	var origin: Vector2 = Vector2((crop.position.x - source.position.x - source.size.x / 2) * factor, 100 + bounce - height)
	draw_set_transform(origin, 0, Vector2.ONE * factor * 224.0 / 166.0)
	CharacterAccessory.draw_on(self, variant)
	draw_set_transform(Vector2.ZERO)
