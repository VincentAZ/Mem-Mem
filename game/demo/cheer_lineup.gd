class_name CheerLineup
extends Node2D
## Decorative only: every tile's person returns; no score or progression callbacks.
var people: Array[Walker] = []
var targets: Array[Vector2] = []
var entrances: Array[Tween] = []
var reduced_motion: bool = false
var entrance_style: int = 0

func clear() -> void:
	_stop_entrances()
	for person: Walker in people:
		person.free()
	people.clear()
	targets.clear()

func start(identities: Array[int], board_size: Vector2, result_rect: Rect2, reduce: bool) -> void:
	clear()
	reduced_motion = reduce
	entrance_style = (entrance_style + randi_range(1, 2)) % 3
	var cast: Array[int] = identities.duplicate()
	cast.sort()
	for index: int in range(cast.size()):
		var person: Walker = Walker.new()
		person.variant = cast[index]
		person.phase = index * 0.73
		person.style = (index + entrance_style) % 3
		person.reduced_motion = reduce
		add_child(person)
		people.append(person)
	_layout(board_size, result_rect)
	for index: int in range(people.size()):
		var person: Walker = people[index]
		if reduce:
			person.position = targets[index]
			person.cheering = true
			continue
		var from_left: bool = entrance_style == 1 or (entrance_style == 2 and index % 2 == 0)
		person.position = Vector2(-40 - index * 7 if from_left else board_size.x + 40 + index * 7, targets[index].y)
		person.facing_left = not from_left
		var entrance: Tween = person.create_tween()
		entrance.tween_interval(index * 0.045)
		entrance.tween_property(person, "position", targets[index], (0.72 + (index % 3) * 0.06)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		entrance.tween_callback(_cheer.bind(person))
		entrances.append(entrance)

func relayout(board_size: Vector2, result_rect: Rect2) -> void:
	if people.is_empty():
		return
	_layout(board_size, result_rect)
	_settle()

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	for person: Walker in people:
		person.reduced_motion = value
	if value:
		_settle()

func _layout(board_size: Vector2, result_rect: Rect2) -> void:
	targets.clear()
	var columns: int = people.size() if people.size() <= 6 else people.size() / 2
	var top_space: float = result_rect.position.y - 20.0
	var bottom_space: float = board_size.y - result_rect.end.y - 20.0
	var space: float = minf(top_space, bottom_space) if people.size() > 6 else top_space
	var person_scale: float = minf(0.9, minf(space / 130.0, board_size.x / columns / 64.0))
	for index: int in range(people.size()):
		var column: int = index % columns
		var y: float = result_rect.position.y - 14.0 - 100.0 * person_scale
		if index >= columns:
			y = result_rect.end.y + 14.0 + 28.0 * person_scale
		targets.append(Vector2((column + 0.5) * board_size.x / columns, y))
		people[index].scale = Vector2.ONE * person_scale

func _settle() -> void:
	_stop_entrances()
	for index: int in range(people.size()):
		people[index].position = targets[index]
		_cheer(people[index])

func _stop_entrances() -> void:
	for entrance: Tween in entrances:
		if entrance.is_valid():
			entrance.kill()
	entrances.clear()

func _cheer(person: Walker) -> void:
	person.facing_left = false
	person.cheering = true
