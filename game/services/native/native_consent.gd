class_name NativeConsent
extends ConsentService
var bridge: AdmobBridge
var _attached: bool = false

func request_update() -> void:
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
