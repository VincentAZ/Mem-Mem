class_name ConsentService
extends Node
signal state_changed(state: String, detail: String)
signal permission_changed(allowed: bool)

var state: String = "unknown"
var detail: String = "Not checked."
var can_request_ads: bool = false
var form_available: bool = false

func request_update() -> void:
	_set_state("unavailable", "Consent service is unavailable.", false)

func show_form() -> void:
	_set_state("unavailable", "No consent form is available.", false)

func _set_state(value: String, description: String, allowed: bool) -> void:
	state = value
	detail = description
	can_request_ads = allowed
	permission_changed.emit(allowed)
	state_changed.emit(state, detail)

