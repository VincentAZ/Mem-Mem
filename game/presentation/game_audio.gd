class_name GameAudio
extends Node
## Bounded one-shot pool. Audio never drives timing, scoring, or progression.
signal cue_played(cue: StringName)
const CUES: Dictionary = {
	&"reveal": preload("res://assets/audio/reveal.wav"),
	&"shuffle": preload("res://assets/audio/shuffle.wav"),
	&"match": preload("res://assets/audio/match.wav"),
	&"mismatch": preload("res://assets/audio/mismatch.wav"),
	&"complete": preload("res://assets/audio/complete.wav"),
	&"next": preload("res://assets/audio/next.wav"),
}
var enabled: bool = true:
	set(value):
		enabled = value
		if not value:
			stop_all()
var suspended: bool = false:
	set(value):
		suspended = value
		if value:
			stop_all()
var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0
const CROWD: Array[AudioStream] = [preload("res://assets/audio/crowd-1.ogg"), preload("res://assets/audio/crowd-2.ogg"), preload("res://assets/audio/crowd-3.ogg")]
var last_cheer: int = -1

func play_cheer() -> bool:
	if not enabled or suspended or get_tree().paused or voices.is_empty():
		return false
	last_cheer = (last_cheer + randi_range(1, CROWD.size() - 1)) % CROWD.size()
	var voice: AudioStreamPlayer = voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stop()
	voice.stream = CROWD[last_cheer]
	voice.play()
	cue_played.emit(&"crowd")
	return true

func _ready() -> void:
	# Stop on pause/background rather than resuming an old reward sound later.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index: int in range(4):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.volume_db = -5.0
		add_child(voice)
		voices.append(voice)

func play_cue(cue: StringName) -> bool:
	if not enabled or suspended or get_tree().paused or not CUES.has(cue) or voices.is_empty():
		return false
	var voice: AudioStreamPlayer = voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stop()
	voice.stream = CUES[cue] as AudioStream
	voice.play()
	cue_played.emit(cue)
	return true

func stop_all() -> void:
	for voice: AudioStreamPlayer in voices:
		voice.stop()
