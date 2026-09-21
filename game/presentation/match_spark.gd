class_name MatchSpark
extends Node2D
## One short, deterministic match accent. No processing after it finishes.
const COLORS: Array[Color] = [Color("d2a557"), Color("bd795e"), Color("729c89")]
var age: float = 0.0

func _process(delta: float) -> void:
	age += delta
	if age >= 0.5:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var progress: float = age / 0.5
	for index: int in range(7):
		var angle: float = index * TAU / 7.0 - PI * 0.5
		var direction: Vector2 = Vector2.from_angle(angle)
		var center: Vector2 = direction * (10.0 + progress * 29.0)
		var color: Color = COLORS[index % COLORS.size()]
		color.a = 1.0 - progress
		draw_line(center, center + direction * 4.0, color, 2.8, true)
