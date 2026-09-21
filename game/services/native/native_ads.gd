class_name NativeAds
extends AdsService
## Calls the real Android SDK, always using Google's built-in demo interstitial unit.
var bridge: AdmobBridge
var _attached: bool = false

func load_ad() -> void:
	if not can_request():
		_report("blocked", "Native demo request blocked by ad removal or permission.")
		return
	if loaded or state == "loading" or state == "initializing" or state == "showing":
		return
	if bridge == null or not bridge.attach():
		_report("unavailable", "Native test ads require Android with the AdMob plugin.")
		return
	if not _attached:
		bridge.sdk.connect("initialization_completed", _initialized)
		bridge.sdk.connect("interstitial_ad_loaded", _loaded)
		bridge.sdk.connect("interstitial_ad_failed_to_load", _load_failed)
		bridge.sdk.connect("interstitial_ad_failed_to_show_full_screen_content", _show_failed)
		bridge.sdk.connect("interstitial_ad_dismissed_full_screen_content", _dismissed)
		_attached = true
	if bridge.sdk.get("is_initialization_completed"):
		_request()
	else:
		_report("initializing", "Initializing native SDK with Google demo IDs.")
		bridge.sdk.call("initialize")

func show_ad() -> void:
	if not can_request() or not loaded or bridge == null or bridge.sdk == null:
		_report("not_ready", "No eligible native test ad. Gameplay continues.")
		return
	loaded = false
	_report("showing", "Showing a Google demo interstitial.")
	bridge.sdk.call("show_interstitial_ad")

func invalidate() -> void:
	super.invalidate()
	if bridge != null and bridge.sdk != null:
		while bridge.sdk.call("is_interstitial_ad_loaded"):
			bridge.sdk.call("remove_interstitial_ad")

func _initialized(_info: Variant) -> void:
	if can_request() and state == "initializing":
		_request()

func _request() -> void:
	_report("loading", "Loading Google's demo interstitial. No production ads are enabled.")
	bridge.sdk.call("load_interstitial_ad")

func _loaded(_ad: Variant, _info: Variant) -> void:
	if not can_request():
		invalidate()
		return
	loaded = true
	_report("ready", "Native Google demo interstitial loaded.")

func _load_failed(_ad: Variant, _error: Variant) -> void:
	loaded = false
	if not can_request():
		return
	_report("failure", "Native test ad failed to load. Gameplay continues.")

func _show_failed(_ad: Variant, _error: Variant) -> void:
	loaded = false
	_report("failure", "Native test ad could not display. Gameplay continues.")

func _dismissed(_ad: Variant) -> void:
	loaded = false
	_report("dismissed", "Native Google demo interstitial dismissed.")
