class_name CharacterAccessory
extends RefCounted
## Deterministic comparison details, overlaid on the EXACT SAME base portrait.
## Coordinates use the 166x174 portrait frame. Shape differs as well as color.
static func draw_on(canvas: CanvasItem, identity: int) -> void:
	var kind: int = PeopleCatalog.family(identity) % 6
	var second: bool = identity % 2 == 1
	var gold: Color = Color("e1b65d")
	var ink: Color = Color("382d35")
	match kind:
		0: # Round versus square eyeglass frames.
			for x: float in [73.0, 94.0]:
				if second:
					canvas.draw_rect(Rect2(x - 8, 32, 16, 13), ink, false, 1.8)
				else:
					canvas.draw_arc(Vector2(x, 38), 7.5, 0, TAU, 24, ink, 1.8, true)
			canvas.draw_line(Vector2(81, 38), Vector2(86, 38), ink, 1.8, true)
		1: # Neckerchief stripe versus dots.
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(66, 77), Vector2(101, 77), Vector2(92, 92), Vector2(72, 88)]), Color("ca6354"))
			if second:
				for p: Vector2 in [Vector2(75, 81), Vector2(88, 81), Vector2(83, 87)]:
					canvas.draw_circle(p, 2, Color("ffe8c7"))
			else:
				canvas.draw_line(Vector2(70, 81), Vector2(95, 86), Color("ffe8c7"), 3, true)
		2: # Round brooch versus diamond.
			if second:
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(112, 96), Vector2(120, 105), Vector2(112, 114), Vector2(104, 105)]), gold)
			else:
				canvas.draw_circle(Vector2(112, 105), 8, gold)
			canvas.draw_circle(Vector2(112, 105), 2, Color("fff6d9"))
		3: # Two-stripe versus three-stripe insignia.
			canvas.draw_rect(Rect2(106, 96, 18, 20), Color("30464b"))
			for i: int in range(3 if second else 2):
				canvas.draw_line(Vector2(109, 100 + i * 5), Vector2(121, 100 + i * 5), gold, 2, true)
		4: # Bow tie versus necktie.
			var cloth: Color = Color("303a5c")
			if second:
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(80, 79), Vector2(89, 79), Vector2(92, 102), Vector2(85, 111), Vector2(77, 102)]), cloth)
			else:
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(69, 77), Vector2(85, 83), Vector2(100, 77), Vector2(100, 92), Vector2(85, 86), Vector2(69, 92)]), cloth)
			canvas.draw_circle(Vector2(85, 83), 3, gold)
		5: # Hair ornament: crescent versus a pair of beads.
			if second:
				canvas.draw_circle(Vector2(101, 24), 3, gold)
				canvas.draw_circle(Vector2(103, 31), 3, gold)
			else:
				canvas.draw_arc(Vector2(102, 28), 6, 0.9, 5.3, 20, gold, 2.8, true)
