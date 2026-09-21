class_name AdsService
extends Node
signal state_changed(state: String, detail: String)

var state: String = "idle"
var detail: String = ""
var ad_free: bool = false
var consent_allowed: bool = false
var loaded: bool = false
var generation: int = 0

func set_ad_free(value: bool) -> void:
	ad_free = value
	if value:
		invalidate()
		_report("suppressed", "Ad removal is active, including previously loaded ads.")

func set_consent_allowed(value: bool) -> void:
	consent_allowed = value
	if not value:
		invalidate()
		_report("blocked", "Ads are waiting for consent availability.")

func invalidate() -> void:
	generation += 1
	loaded = false

func can_request() -> bool:
	return consent_allowed and not ad_free

func load_ad() -> void:
	_report("unavailable", "Advertising is unavailable.")

func show_ad() -> void:
	_report("unavailable", "Advertising is unavailable.")

func _report(value: String, description: String) -> void:
	state = value
	detail = description
	state_changed.emit(state, detail)

