class_name LevelGenerator
extends RefCounted
## Twelve-level waves, peaking at 16 cards. Old saves retain their exact layout.
const PAIRS: Array[int] = [3, 4, 4, 6, 4, 3, 6, 8, 4, 6, 8, 4]
const LEGACY_PAIRS: Array[int] = [3, 4, 4, 6, 4, 3]
const LOOKALIKES: Array[int] = [0, 0, 1, 2, 1, 0, 2, 2, 1, 3, 4, 1]
const LEGACY_LOOKALIKES: Array[int] = [0, 0, 1, 2, 1, 0]
const MOODS: Array[String] = ["Meet your matches", "New faces", "Spot the difference", "Double take", "In the groove", "Quick match"]
const FAMILY_COUNT: int = 6

static func pair_count(level: int, generation: int = 3) -> int:
	var wave: Array[int] = PAIRS if generation >= 3 else LEGACY_PAIRS
	return wave[(level - 1) % wave.size()]

static func columns(level: int, generation: int = 3) -> int:
	var pairs: int = pair_count(level, generation)
	return 4 if pairs == 8 else 3 if pairs == 6 else 2

static func mood(level: int) -> String:
	return MOODS[(level - 1) % MOODS.size()]

static func theme_for(level: int, chosen_theme: int = -1) -> int:
	if chosen_theme >= 0:
		return chosen_theme
	return -1 if level % 5 == 0 else (level - 1) % 4

static func generate(level: int, seed_value: int, generation: int = 3, chosen_theme: int = -1) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value + level * 104729
	var families: Array[int] = [0, 1, 2, 3, 4, 5]
	if generation >= 2:
		families.clear()
		var theme_id: int = theme_for(level, chosen_theme)
		for family_id: int in range(24) if theme_id < 0 else range(theme_id * 6, theme_id * 6 + 6):
			families.append(family_id)
	shuffle(families, rng)
	var difficulty: Array[int] = LOOKALIKES if generation >= 3 else LEGACY_LOOKALIKES
	var twins: int = difficulty[(level - 1) % difficulty.size()]
	var identities: Array[int] = []
	for index: int in range(pair_count(level, generation) - twins):
		var family: int = families[index]
		if index < twins:
			identities.append_array([family * 2, family * 2 + 1])
		else:
			identities.append(family * 2 + rng.randi_range(0, 1))
	shuffle(identities, rng)
	var preview: Array[int] = identities.duplicate()
	preview.append_array(identities)
	var layout: Array[int] = preview.duplicate()
	shuffle(layout, rng)
	if layout == preview:
		layout.push_back(layout.pop_front())
	return {"preview": preview, "identities": layout}

static func shuffle(values: Array[int], rng: RandomNumberGenerator) -> void:
	for index: int in range(values.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var value: int = values[index]
		values[index] = values[other]
		values[other] = value

static func completed_pairs(level_count: int, generation: int = 3) -> int:
	var wave: Array[int] = PAIRS if generation >= 3 else LEGACY_PAIRS
	var wave_total: int = 0
	for pairs: int in wave:
		wave_total += pairs
	var total: int = (level_count / wave.size()) * wave_total
	for index: int in range(level_count % wave.size()):
		total += wave[index]
	return total
