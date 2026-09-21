class_name SimulatedConsent
extends ConsentService
var outcome: String = "required"

func request_update() -> void:
	form_available = false
	match outcome:
		"not_required":
			_set_state("not_required", "SIMULATED: consent not required.", true)
		"obtained":
			_set_state("obtained", "SIMULATED: permission available.", true)
		"required":
			form_available = true
			_set_state("required", "SIMULATED: choose Allow or Decline below.", false)
		"unavailable":
			_set_state("unavailable", "SIMULATED: form unavailable; ads stay blocked.", false)
		_:
			_set_state("failure", "SIMULATED: consent update failed; gameplay continues.", false)

func show_form() -> void:
	if form_available:
		_set_state("required", "SIMULATED: choose Allow or Decline below.", false)
	else:
		super.show_form()

func resolve(allow: bool) -> void:
	if not form_available:
		return
	form_available = false
	_set_state("obtained" if allow else "declined", "SIMULATED: allowed." if allow else "SIMULATED: declined. Gameplay continues.", allow)

