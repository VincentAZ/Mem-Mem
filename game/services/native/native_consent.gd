class_name NativeConsent
extends ConsentService
var bridge: AdmobBridge
var _attached: bool = false
var production: bool = false
var under_age_of_consent: bool = true
var ump: Object

func _attach_ump() -> bool:
	if ump != null:
		return true
	if not Engine.has_singleton("MemMemConsent"):
		return false
	ump = Engine.get_singleton("MemMemConsent")
	ump.connect("consent_updated", _production_updated)
	return true

func request_update() -> void:
	if production:
		if state == "updating" or state == "showing":
			return
		if not _attach_ump():
			_set_state("unavailable", "Privacy choices are unavailable. You can keep playing.", false)
			return
		_set_state("updating", "Checking privacy choices…", false)
		ump.call("request_update", under_age_of_consent)
		return
	if bridge == null or not bridge.attach():
		_set_state("unavailable", "Native UMP requires Android with the AdMob plugin.", false)
		return
	if not _attached:
		bridge.sdk.connect("consent_info_updated", _updated)
		bridge.sdk.connect("consent_info_update_failed", _failed)
		bridge.sdk.connect("consent_form_loaded", _form_loaded)
		bridge.sdk.connect("consent_form_failed_to_load", _failed)
		bridge.sdk.connect("consent_form_dismissed", _dismissed)
		_attached = true
	_set_state("updating", "Requesting native UMP status. A configured AdMob app is needed for live validation.", false)
	bridge.sdk.call("update_consent_info")

func show_form() -> void:
	if production:
		request_update()
		return
	if not form_available or bridge.sdk == null:
		super.show_form()
		return
	bridge.sdk.call("load_consent_form")

func _updated() -> void:
	var consent: RefCounted = bridge.sdk.call("get_consent_status") as RefCounted
	var status: String = consent.call("to_status_string")
	form_available = bool(bridge.sdk.call("is_consent_form_available"))
	_set_state(status.to_lower(), "Native UMP: " + status, status == "OBTAINED" or status == "NOT_REQUIRED")

func _form_loaded() -> void:
	bridge.sdk.call("show_consent_form")

func _dismissed(error: Variant) -> void:
	# The wrapper emits a FormError object even on success (empty data, code 0).
	if error != null and int(error.call("get_code")) != 0:
		_failed(error)
	else:
		_updated()

func _failed(_error: Variant) -> void:
	form_available = false
	_set_state("failure", "Native UMP unavailable or unconfigured. No live consent validation; play continues.", false)

func show_privacy_options() -> void:
	if not production:
		super.show_privacy_options()
		return
	if privacy_options_required and _attach_ump() and not state in ["updating", "showing"]:
		_set_state("showing", "Your privacy choices", false)
		ump.call("show_privacy_options")

func _production_updated(allowed: bool, options_required: bool, error: String) -> void:
	privacy_options_required = options_required
	form_available = options_required
	_set_state("ready" if error.is_empty() else "failure", "Privacy choices updated." if error.is_empty() else error, allowed)
