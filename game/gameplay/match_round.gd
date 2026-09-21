class_name MatchRound
extends RefCounted
## Rules and score are committed before cosmetic animation. No rendering dependencies.
const POINTS_PER_PAIR: int = 100
const MAX_BONUS_PER_PAIR: int = 20
var level: int = 1
var seed_value: int = 0
var identities: Array[int] = []
var preview: Array[int] = []
var removed: Array[int] = []
var selected: Array[int] = []
var attempts: int = 0
var opening: bool = true
var resolving: bool = false
var generation: int = 4
var wave_start: int = 1
var theme_pool: Array[int] = [0, 1, 2, 3]
var peek_earned: bool = false
var peek_used: bool = false
var peeking: bool = false
var _legacy_characters: Dictionary = {}
var chosen_theme: int = -1

static func create(level_number: int, seed_number: int, generation_number: int = 4, theme_number: int = -1, start_level: int = 1, available: Array[int] = [0, 1, 2, 3]) -> MatchRound:
	var result: MatchRound = MatchRound.new()
	result.level = level_number
	result.seed_value = seed_number
	result.generation = generation_number
	result.chosen_theme = theme_number
	result.wave_start = start_level
	result.theme_pool = available.duplicate()
	var generated: Dictionary = LevelGenerator.generate(level_number, seed_number, generation_number, theme_number, start_level, available)
	result.identities.assign(generated.identities)
	result.preview.assign(generated.preview)
	if generation_number < 4:
		result._legacy_characters = LevelGenerator.legacy_characters(result.identities)
	return result

func begin_play() -> void:
	opening = false

func select(index: int) -> String:
	if opening or resolving or peeking or index < 0 or index >= identities.size():
		return "ignored"
	if removed.has(index) or selected.has(index):
		return "ignored"
	selected.append(index)
	if selected.size() == 1:
		return "first"
	attempts += 1
	resolving = true
	if identities[selected[0]] == identities[selected[1]]:
		removed.append_array(selected)
		return "match"
	return "mismatch"

func finish_resolution() -> void:
	selected.clear()
	resolving = false

func matches() -> int:
	return removed.size() / 2

func complete() -> bool:
	return not identities.is_empty() and removed.size() == identities.size()

func accuracy() -> float:
	return float(matches()) / attempts if attempts > 0 else 0.0

func bonus() -> int:
	return floori(MAX_BONUS_PER_PAIR * matches() * accuracy()) if complete() else 0

func points() -> int:
	return matches() * POINTS_PER_PAIR + bonus()

func character_at(index: int) -> int:
	return int(_legacy_characters[identities[index]]) if generation < 4 else identities[index]

func character_layout() -> Array[int]:
	var result: Array[int] = []
	for index: int in range(identities.size()):
		result.append(character_at(index))
	return result

func board_key() -> String:
	return "%d:%d:%d" % [seed_value, level, generation]

func earn_peek(key: String) -> bool:
	if key != board_key() or peek_earned or peek_used or complete():
		return false
	peek_earned = true
	return true

func can_peek(plus: bool) -> bool:
	return not opening and not resolving and not peeking and not complete() and not peek_used and (plus or peek_earned)

func begin_peek(plus: bool) -> bool:
	if not can_peek(plus):
		return false
	peek_used = true
	peeking = true
	return true

func finish_peek() -> void:
	peeking = false

func snapshot() -> Dictionary:
	return {"level": level, "seed": seed_value, "identities": identities.duplicate(), "removed": removed.duplicate(), "attempts": attempts, "opening": opening, "generation": generation, "chosen_theme": chosen_theme, "wave_start": wave_start, "theme_pool": theme_pool.duplicate(), "peek_earned": peek_earned, "peek_used": peek_used}

static func whole(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum

static func from_snapshot(data: Dictionary) -> MatchRound:
	if not whole(data.get("level"), 1, 1000000000) or not whole(data.get("seed"), 0, 2147483647):
		return null
	if not whole(data.get("attempts"), 0, 1000000000) or not data.get("opening") is bool:
		return null
	if not whole(data.get("generation", 1), 1, 4) or not whole(data.get("chosen_theme", -1), -1, 6):
		return null
	var generation_number: int = int(data.get("generation", 1))
	var start: Variant = data.get("wave_start", 1)
	var pool: Variant = data.get("theme_pool", [0, 1, 2, 3])
	if not whole(start, 1, int(data.level)) or not pool is Array or pool.is_empty() or pool.size() > 7:
		return null
	var themes: Array[int] = []
	for theme_id: Variant in pool:
		if not whole(theme_id, 0, 6) or themes.has(int(theme_id)):
			return null
		themes.append(int(theme_id))
	if themes != PeopleCatalog.FREE_THEMES and themes != PeopleCatalog.ALL_THEMES:
		return null
	if generation_number < 4 and (int(start) != 1 or int(data.get("chosen_theme", -1)) > 3 or themes != PeopleCatalog.FREE_THEMES):
		return null
	if generation_number >= 4 and int(data.get("chosen_theme", -1)) >= 0 and not themes.has(int(data.chosen_theme)):
		return null
	for field: String in ["peek_earned", "peek_used"]:
		if not data.get(field, false) is bool:
			return null
	if bool(data.opening) and bool(data.get("peek_used", false)):
		return null
	var expected: MatchRound = create(int(data.level), int(data.seed), generation_number, int(data.get("chosen_theme", -1)), int(start), themes)
	expected.peek_earned = data.get("peek_earned", false)
	expected.peek_used = data.get("peek_used", false)
	var values: Variant = data.get("identities")
	var gone: Variant = data.get("removed")
	if not values is Array or not gone is Array or values.size() != expected.identities.size():
		return null
	# Regeneration validates both the catalog and the exact saved, fixed positions.
	for index: int in range(values.size()):
		if not whole(values[index], 0, PeopleCatalog.COUNT - 1 if generation_number >= 4 else 47) or int(values[index]) != expected.identities[index]:
			return null
	var removed_counts: Dictionary = {}
	for value: Variant in gone:
		if not whole(value, 0, values.size() - 1) or expected.removed.has(int(value)):
			return null
		expected.removed.append(int(value))
		var identity: int = expected.identities[int(value)]
		removed_counts[identity] = int(removed_counts.get(identity, 0)) + 1
	for count: int in removed_counts.values():
		if count != 2:
			return null
	expected.attempts = int(data.attempts)
	expected.opening = data.opening
	if expected.attempts < expected.matches() or (expected.opening and (expected.attempts != 0 or not gone.is_empty())):
		return null
	return expected
