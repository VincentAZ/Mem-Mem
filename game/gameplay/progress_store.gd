class_name ProgressStore
extends RefCounted
## Two alternating atomic snapshots. The checksum detects corruption, not cheating.
var prefix: String = "user://progress"
var revision: int = 0
var recovered: bool = false
var had_files: bool = false

func load_progress() -> GameProgress:
	var best: GameProgress = null
	var invalid: bool = false
	revision = 0
	recovered = false
	had_files = false
	for slot: int in range(2):
		var path: String = "%s.%d.json" % [prefix, slot]
		if not FileAccess.file_exists(path):
			continue
		had_files = true
		var envelope: Dictionary = _read(path)
		if envelope.is_empty():
			invalid = true
			continue
		var parser: JSON = JSON.new()
		var payload: String = envelope.payload
		if parser.parse(payload) != OK or not parser.data is Dictionary:
			invalid = true
			continue
		var progress: GameProgress = GameProgress.from_snapshot(parser.data)
		if progress == null:
			invalid = true
			continue
		if int(envelope.revision) > revision:
			revision = int(envelope.revision)
			best = progress
	recovered = invalid and best != null
	return best

func save(progress: GameProgress) -> bool:
	var next_revision: int = revision + 1
	var target: String = "%s.%d.json" % [prefix, next_revision % 2]
	var payload: String = JSON.stringify(progress.snapshot())
	var stream: FileAccess = FileAccess.open(target + ".tmp", FileAccess.WRITE)
	if stream == null:
		return false
	stream.store_string(JSON.stringify({"revision": next_revision, "payload": payload, "checksum": payload.sha256_text()}))
	stream.flush()
	var error: Error = stream.get_error()
	stream.close()
	if error != OK or DirAccess.rename_absolute(target + ".tmp", target) != OK:
		return false
	revision = next_revision
	return true

func _read(path: String) -> Dictionary:
	# A valid progress file is a few KB, never an unbounded allocation.
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 65536:
		return {}
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return {}
	var value: Dictionary = parser.data
	if not MatchRound.whole(value.get("revision"), 1, 9007199254740991) or not value.get("payload") is String:
		return {}
	if value.get("checksum") != String(value.payload).sha256_text():
		return {}
	return value
