class_name GamePalette
extends RefCounted
static var dark: bool = false
static var backdrop: int = 0
static var ink: Color = Color("244c43")
static var muted: Color = Color("637367")
static var panel: Color = Color("e9eddf")
static var card: Color = Color("fffdf8")
static var background: Color = Color("f8f4ec")
static var back: Color = Color("31564c")
const BACKGROUNDS: Array[String] = ["Paper", "Botanical", "Twilight", "Orbit"]

static func configure(is_dark: bool, scene: int) -> void:
	dark = is_dark
	backdrop = scene
	background = [Color("f8f4ec"), Color("eaf0e7"), Color("f1eaf1"), Color("e9eff5")][scene] if not dark else [Color("191f27"), Color("14251f"), Color("251c2d"), Color("121d30")][scene]
	ink = Color("edf1e7") if dark else Color("244c43")
	muted = Color("b8c3bc") if dark else Color("637367")
	panel = background.lightened(0.08) if dark else background.darkened(0.035)
	card = Color("34404a") if dark else Color("fffdf8")
	back = [Color("31564c"), Color("375c4a"), Color("59435e"), Color("344b70")][scene]
