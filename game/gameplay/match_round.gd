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
var generation: int = 3
var chosen_theme: int = -1

static func create(level_number: int, seed_number: int, generation_number: int = 3, theme_number: int = -1) -> MatchRound:
	var result: MatchRound = MatchRound.new()
	result.level = level_number
	result.seed_value = seed_number
	result.generation = generation_number
	result.chosen_theme = theme_number
	var generated: Dictionary = LevelGenerator.generate(level_number, seed_number, generation_number, theme_number)
	result.identities.assign(generated.identities)
	result.preview.assign(generated.preview)
	return result

func begin_play() -> void:
	opening = false

func select(index: int) -> String:
	if opening or resolving or index < 0 or index >= identities.size():
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

func snapshot() -> Dictionary:
	return {"level": level, "seed": seed_value, "identities": identities.duplicate(), "removed": removed.duplicate(), "attempts": attempts, "opening": opening, "generation": generation, "chosen_theme": chosen_theme}

static func whole(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum

static func from_snapshot(data: Dictionary) -> MatchRound:
	if not whole(data.get("level"), 1, 1000000000) or not whole(data.get("seed"), 0, 2147483647):
		return null
	if not whole(data.get("attempts"), 0, 1000000000) or not data.get("opening") is bool:
		return null
	if not whole(data.get("generation", 1), 1, 3) or not whole(data.get("chosen_theme", -1), -1, 3):
		return null
	var expected: MatchRound = create(int(data.level), int(data.seed), int(data.get("generation", 1)), int(data.get("chosen_theme", -1)))
	var values: Variant = data.get("identities")
	var gone: Variant = data.get("removed")
	if not values is Array or not gone is Array or values.size() != expected.identities.size():
		return null
	# Regeneration validates both the catalog and the exact saved, fixed positions.
	for index: int in range(values.size()):
		if not whole(values[index], 0, 47) or int(values[index]) != expected.identities[index]:
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
