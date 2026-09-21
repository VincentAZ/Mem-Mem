class_name GameBackdrop
extends Control
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), GamePalette.background)
	var color: Color = GamePalette.ink
	color.a = 0.045 if GamePalette.dark else 0.035
	match GamePalette.backdrop:
		1:
			for i: int in range(7):
				var p: Vector2 = Vector2(size.x + 8, size.y * 0.28 + i * 36)
				draw_set_transform(p, -0.65, Vector2(1, 0.35))
				draw_circle(Vector2.ZERO, 80, color)
		2:
			for i: int in range(4):
				draw_arc(Vector2(-80, size.y * 0.85), 160 + i * 25, -1.6, 1.4, 64, color, 10, true)
		3:
			for i: int in range(28):
				var p: Vector2 = Vector2(fmod(i * 83.0 + 17, size.x), fmod(i * 137.0 + 9, size.y))
				draw_circle(p, 1.5 + i % 3, color)
	draw_set_transform(Vector2.ZERO)
