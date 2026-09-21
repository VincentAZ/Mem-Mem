class_name PeopleCatalog
extends RefCounted
## 24 collectable people; two matching identities per person. No runtime generation.
const COUNT: int = 24
const THEMES: Array[String] = ["Everyday People", "Firefighters", "Aliens", "Golden Years"]
const NAMES: Array[String] = ["Maya", "Theo", "June", "Leo", "Imani", "Claire", "Riley", "Marcus", "Frankie", "Dean", "Sasha", "Ellis", "Nova", "Orion", "Lyra", "Rook", "Vega", "Sage", "Florence", "Ruby", "Mei", "Beatrice", "Anita", "Vivian"]
const ATLASES: Array[Texture2D] = [preload("res://assets/characters/people.png"), preload("res://assets/characters/firefighters.png"), preload("res://assets/characters/aliens.png"), preload("res://assets/characters/golden.png")]
const CHEERS: Array[Texture2D] = [preload("res://assets/characters/people-cheer.png"), preload("res://assets/characters/firefighters-cheer.png"), preload("res://assets/characters/aliens-cheer.png"), preload("res://assets/characters/golden-cheer.png")]
const BACKDROP: Array[Color] = [Color("eadaca"), Color("e4d9ba"), Color("cbd7e8"), Color("e4d7e4")]

static func family(identity: int) -> int:
	return clampi(identity / 2, 0, COUNT - 1)

static func theme_name(theme_id: int) -> String:
	return "Mixed cast" if theme_id < 0 else THEMES[theme_id]

static func portrait_region(identity: int, excited: bool = false) -> Rect2:
	var character: int = family(identity)
	var normal: Rect2 = AtlasRegions.NORMAL[character]
	var pose: Rect2 = AtlasRegions.CHEER[character] if excited else normal
	return Rect2(normal.get_center().x - 112, pose.position.y, 224, 228)

static func atlas(identity: int, excited: bool = false) -> Texture2D:
	return CHEERS[family(identity) / 6] if excited else ATLASES[family(identity) / 6]
