class_name PeopleCatalog
extends RefCounted
## Stable collectible IDs. Matching and artwork use the same unmodified character.
const COUNT: int = 56
const FREE_THEMES: Array[int] = [0, 1, 2, 3]
const ALL_THEMES: Array[int] = [0, 1, 2, 3, 4, 5, 6]
const THEMES: Array[String] = ["Everyday People", "Firefighters", "Aliens", "Golden Years", "Woodland Crew", "Snack Squad", "Mythical Misfits"]
const NAMES: Array[String] = ["Maya", "Theo", "June", "Leo", "Imani", "Claire", "Riley", "Marcus", "Frankie", "Dean", "Sasha", "Ellis", "Nova", "Orion", "Lyra", "Rook", "Vega", "Sage", "Florence", "Ruby", "Mei", "Beatrice", "Anita", "Vivian", "Kai", "Zara", "Cooper", "Nadia", "Cosmo", "Zuri", "Dottie", "Hector", "Fox", "Bear", "Owl", "Rabbit", "Raccoon", "Deer", "Hedgehog", "Beaver", "Coffee", "Taco", "Doughnut", "Croissant", "Ice Cream", "Pizza", "Sushi", "Popcorn", "Dragon", "Unicorn", "Phoenix", "Yeti", "Griffin", "Kraken", "Mushroom Sprite", "Wizard"]
const BACKDROP: Array[Color] = [Color("eadaca"), Color("e4d9ba"), Color("cbd7e8"), Color("e4d7e4"), Color("d8e6ce"), Color("f0dbbe"), Color("ddd4ed")]

# Membership and presentation are explicit metadata, independent of ID arithmetic.
# IDs 0–23 remain the original collectible IDs across every save generation.
const THEME_CHARACTERS: Array[Array] = [
	[0, 1, 2, 3, 4, 5, 24, 25],
	[6, 7, 8, 9, 10, 11, 26, 27],
	[12, 13, 14, 15, 16, 17, 28, 29],
	[18, 19, 20, 21, 22, 23, 30, 31],
	[32, 33, 34, 35, 36, 37, 38, 39],
	[40, 41, 42, 43, 44, 45, 46, 47],
	[48, 49, 50, 51, 52, 53, 54, 55],
]
const ART_GROUPS: Array[Dictionary] = [
	{"atlas": "people", "ids": [0, 1, 2, 3, 4, 5], "regions": [0, 1, 2, 3, 4, 5], "expanded": false, "framing": "portrait", "motion": "walk"},
	{"atlas": "firefighters", "ids": [6, 7, 8, 9, 10, 11], "regions": [6, 7, 8, 9, 10, 11], "expanded": false, "framing": "portrait", "motion": "walk"},
	{"atlas": "aliens", "ids": [12, 13, 14, 15, 16, 17], "regions": [12, 13, 14, 15, 16, 17], "expanded": false, "framing": "portrait", "motion": "walk"},
	{"atlas": "golden", "ids": [18, 19, 20, 21, 22, 23], "regions": [18, 19, 20, 21, 22, 23], "expanded": false, "framing": "portrait", "motion": "walk"},
	{"atlas": "cast-expansion", "ids": [24, 25, 26, 27, 28, 29, 30, 31], "regions": [0, 1, 2, 3, 4, 5, 6, 7], "expanded": true, "framing": "upper_body", "motion": "walk"},
	{"atlas": "woodland", "ids": [32, 33, 34, 35, 36, 37, 38, 39], "regions": [8, 9, 10, 11, 12, 13, 14, 15], "expanded": true, "framing": "silhouette", "motion": "hop"},
	{"atlas": "snacks", "ids": [40, 41, 42, 43, 44, 45, 46, 47], "regions": [16, 17, 18, 19, 20, 21, 22, 23], "expanded": true, "framing": "silhouette", "motion": "hop"},
	{"atlas": "mythical", "ids": [48, 49, 50, 51, 52, 53, 54, 55], "regions": [24, 25, 26, 27, 28, 29, 30, 31], "expanded": true, "framing": "silhouette", "motion": "hop"},
]
const MOTION_OVERRIDES: Dictionary = {34: "float", 48: "float", 50: "float", 52: "float", 53: "float"}
const WAVING_CHARACTERS: Array[int] = [0, 1, 3, 4, 6, 7, 9, 10, 12, 13, 15, 16, 18, 19, 21, 22]
static var _characters: Dictionary = {}
static var _textures: Dictionary = {}

static func character_metadata(character: int) -> Dictionary:
	if _characters.is_empty():
		for group: Dictionary in ART_GROUPS:
			for slot: int in range(group.ids.size()):
				var character_id: int = group.ids[slot]
				var region: int = group.regions[slot]
				var entry: Dictionary = {
					"id": character_id, "name": NAMES[character_id], "atlas": group.atlas,
					"normal": ExpandedAtlas.NORMAL[region] if group.expanded else AtlasRegions.NORMAL[region],
					"cheer": ExpandedAtlas.CHEER[region] if group.expanded else AtlasRegions.CHEER[region],
					"framing": group.framing, "motion": MOTION_OVERRIDES.get(character_id, group.motion),
					"wave": WAVING_CHARACTERS.has(character_id),
				}
				for theme_id: int in range(THEME_CHARACTERS.size()):
					if THEME_CHARACTERS[theme_id].has(character_id):
						entry.theme = theme_id
						break
				entry.make_read_only()
				_characters[character_id] = entry
	return _characters[character]

static func family(identity: int) -> int:
	return clampi(identity, 0, COUNT - 1)

static func theme_of(character: int) -> int:
	return character_metadata(character).theme

static func characters(theme_id: int) -> Array[int]:
	var result: Array[int] = []
	if theme_id >= 0 and theme_id < THEME_CHARACTERS.size():
		result.assign(THEME_CHARACTERS[theme_id])
	return result

static func available_themes(plus: bool) -> Array[int]:
	return ALL_THEMES.duplicate() if plus else FREE_THEMES.duplicate()

static func is_unlocked(character: int, plus: bool) -> bool:
	return character >= 0 and character < COUNT and available_themes(plus).has(theme_of(character))

static func theme_name(theme_id: int) -> String:
	return "Mixed cast" if theme_id < 0 else THEMES[theme_id]

static func body_region(character: int, excited: bool = false) -> Rect2:
	return character_metadata(character).cheer if excited else character_metadata(character).normal

static func portrait_region(character: int, excited: bool = false) -> Rect2:
	var normal: Rect2 = body_region(character)
	var pose: Rect2 = body_region(character, excited)
	match character_metadata(character).framing:
		"portrait":
			return Rect2(normal.get_center().x - 112, pose.position.y, 224, 228)
		"upper_body":
			var width: float = maxf(pose.size.x, pose.size.y * 0.52)
			return Rect2(pose.get_center().x - width / 2, pose.position.y, width, width * 1.05)
	# Nonhuman cards retain their full defining silhouette.
	return pose

static func atlas(character: int, excited: bool = false) -> Texture2D:
	var path: String = "res://assets/characters/%s%s.png" % [character_metadata(character).atlas, "-cheer" if excited else ""]
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path] as Texture2D

static func motion_profile(character: int) -> String:
	return character_metadata(character).motion

static func can_wave(character: int) -> bool:
	return character_metadata(character).wave

static func clap_region(character: int) -> Rect2:
	return ClapAtlas.REGIONS[character]

static func clap_atlas(character: int) -> Texture2D:
	var path: String = "res://assets/characters/%s-clap.png" % character_metadata(character).atlas
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path] as Texture2D
