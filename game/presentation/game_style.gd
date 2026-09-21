class_name GameStyle
extends RefCounted
## Shared spacing, surfaces and control states for the game and its overlays.
static func surface(color: Color, radius: int = 18, padding: int = 16) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	return style

static func accent() -> Color:
	return Color("e8b96e") if GamePalette.dark else Color("8b541d")

static func gold_surface() -> Color:
	return Color("423520") if GamePalette.dark else Color("fff0cd")

static func primary() -> Color:
	return Color("b8dbbc") if GamePalette.dark else Color("244c43")

static func on_primary() -> Color:
	return Color("182b23") if GamePalette.dark else Color("fffdf8")

static func skin_button(button: Button, prominent: bool = false) -> void:
	var color: Color = primary() if prominent else GamePalette.card
	var ink: Color = on_primary() if prominent else GamePalette.ink
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var fill: Color = color
		if state == "hover":
			fill = color.lightened(0.06)
		elif state == "pressed":
			fill = color.darkened(0.07)
		elif state == "disabled":
			fill = GamePalette.panel
		button.add_theme_stylebox_override(state, surface(fill, 14, 12))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, ink)
	button.add_theme_color_override("font_disabled_color", GamePalette.muted)
	button.set_meta("prominent", prominent)

static func label(value: String, font_size: int, muted: bool = false) -> Label:
	var result: Label = Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", GamePalette.muted if muted else GamePalette.ink)
	return result
