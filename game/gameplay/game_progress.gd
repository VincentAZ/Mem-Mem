class_name GameProgress
extends RefCounted
## Only completed levels enter the bank. Active points are derived, never incremented twice.
const VERSION: int = 4
# The easier wave starts after the current legacy board, never halfway through it.
var easy_from_level: int = 1
# Runtime service entitlement; deliberately excluded from game-save ownership.
var plus_enabled: bool = false
# Earlier levels used the old six-board wave; retain its score bounds on migration.
var expanded_from_level: int = 1
var seed_value: int = 0
var banked_points: int = 0
var round_state: MatchRound
var reduced_motion: bool = false
var haptics: bool = true
var sound: bool = true
var dark_mode: bool = false
var background: int = 0
var preferred_theme: int = -1
var collected: Array[int] = []
var choice_tokens: int = 0
var reward_level: int = 0
# Retired surprise-reward fields remain readable for existing schema 2/3 saves.
# They no longer award ownership or appear in the UI.
var discovery_steps: int = 0
var last_discovery: int = -1

func settle_collection_reward() -> bool:
	if not round_state.complete() or round_state.resolving or reward_level >= round_state.level:
		return false
	reward_level = round_state.level
	last_discovery = -1
	if round_state.attempts == round_state.matches():
		choice_tokens += 1
	discovery_steps = 0
	return true

func collect_character(character: int) -> bool:
	if choice_tokens <= 0 or not PeopleCatalog.is_unlocked(character, plus_enabled) or collected.has(character):
		return false
	collected.append(character)
	choice_tokens -= 1
	return true

static func create(seed_number: int) -> GameProgress:
	var result: GameProgress = GameProgress.new()
	result.seed_value = seed_number
	result.round_state = MatchRound.create(1, seed_number)
	return result

func total_points() -> int:
	return banked_points + round_state.points()

func advance() -> bool:
	if not round_state.complete() or round_state.resolving:
		return false
	settle_collection_reward()
	banked_points += round_state.points()
	var pool: Array[int] = PeopleCatalog.available_themes(plus_enabled)
	var chosen: int = preferred_theme if pool.has(preferred_theme) else -1
	round_state = MatchRound.create(round_state.level + 1, seed_value, 4, chosen, easy_from_level, pool)
	return true

func snapshot() -> Dictionary:
	return {"version": VERSION, "expanded_from_level": expanded_from_level, "easy_from_level": easy_from_level, "seed": seed_value, "banked_points": banked_points, "round": round_state.snapshot(), "reduced_motion": reduced_motion, "haptics": haptics, "sound": sound, "dark_mode": dark_mode, "background": background, "preferred_theme": preferred_theme, "collected": collected.duplicate(), "choice_tokens": choice_tokens, "reward_level": reward_level, "discovery_steps": discovery_steps, "last_discovery": last_discovery}

static func from_snapshot(data: Dictionary) -> GameProgress:
	if not MatchRound.whole(data.get("version"), 1, VERSION) or not MatchRound.whole(data.get("seed"), 0, 2147483647):
		return null
	if not data.get("round") is Dictionary or not data.get("reduced_motion") is bool or not data.get("haptics") is bool:
		return null
	# Phase 2 saves predate sound. Absence defaults on; malformed values are rejected.
	if not data.get("sound", true) is bool:
		return null
	var saved_round: MatchRound = MatchRound.from_snapshot(data.round)
	if saved_round == null or saved_round.seed_value != int(data.seed):
		return null
	var expanded_from: int = saved_round.level + 1
	if int(data.version) >= 3:
		if not MatchRound.whole(data.get("expanded_from_level"), 1, saved_round.level + 1):
			return null
		expanded_from = int(data.expanded_from_level)
	elif saved_round.generation >= 3:
		return null
	var easy_from: int = saved_round.level + 1
	if int(data.version) >= 4:
		if not MatchRound.whole(data.get("easy_from_level"), expanded_from, saved_round.level + 1):
			return null
		easy_from = int(data.easy_from_level)
	elif saved_round.generation >= 4:
		return null
	if (saved_round.generation >= 3) != (saved_round.level >= expanded_from) or (saved_round.generation >= 4) != (saved_round.level >= easy_from):
		return null
	if saved_round.generation >= 4 and saved_round.wave_start != easy_from:
		return null
	var legacy_levels: int = mini(expanded_from - 1, saved_round.level - 1)
	var expanded_levels: int = mini(easy_from - 1, saved_round.level - 1)
	var completed: int = LevelGenerator.completed_pairs(legacy_levels, 2) + LevelGenerator.completed_pairs(expanded_levels, 3) - LevelGenerator.completed_pairs(legacy_levels, 3) + LevelGenerator.completed_pairs(maxi(0, saved_round.level - easy_from), 4)
	if not MatchRound.whole(data.get("banked_points"), completed * 100, completed * 120):
		return null
	var result: GameProgress = GameProgress.new()
	result.expanded_from_level = expanded_from
	result.easy_from_level = easy_from
	result.seed_value = int(data.seed)
	result.banked_points = int(data.banked_points)
	result.round_state = saved_round
	result.reduced_motion = data.reduced_motion
	result.haptics = data.haptics
	result.sound = data.get("sound", true)
	if int(data.version) >= 2:
		if not data.get("dark_mode") is bool or not MatchRound.whole(data.get("background"), 0, 3) or not MatchRound.whole(data.get("preferred_theme"), -1, 6 if int(data.version) >= 4 else 3):
			return null
		if not MatchRound.whole(data.get("choice_tokens"), 0, saved_round.level) or not MatchRound.whole(data.get("reward_level"), 0, saved_round.level) or not MatchRound.whole(data.get("discovery_steps"), 0, 2):
			return null
		if not data.get("collected") is Array or data.collected.size() > PeopleCatalog.COUNT or not MatchRound.whole(data.get("last_discovery"), -1, 23):
			return null
		for character: Variant in data.collected:
			if not MatchRound.whole(character, 0, PeopleCatalog.COUNT - 1 if int(data.version) >= 4 else 23) or result.collected.has(int(character)):
				return null
			result.collected.append(int(character))
		if int(data.reward_level) == saved_round.level and not saved_round.complete():
			return null
		if int(data.choice_tokens) > int(data.reward_level) or (int(data.last_discovery) >= 0 and not result.collected.has(int(data.last_discovery))):
			return null
		result.dark_mode = data.dark_mode
		result.background = int(data.background)
		result.preferred_theme = int(data.preferred_theme)
		result.choice_tokens = int(data.choice_tokens)
		result.reward_level = int(data.reward_level)
		result.discovery_steps = int(data.discovery_steps)
		result.last_discovery = int(data.last_discovery)
	return result
