class_name NativeAds
extends AdsService
## Rewarded ads use the bridge's build-specific IDs and the shared permission gate.
var bridge: AdmobBridge
var _attached: bool = false
var _reward_attached: bool = false
var _reward_ad_id: String = ""

func load_ad() -> void:
	if bridge != null and bridge.config.production:
		_report("unavailable", "Only optional rewarded ads are offered.")
		return
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

func load_rewarded(board_key: String) -> void:
	if rewarded_state in ["ready", "failure", "dismissed"]:
		cancel_rewarded()
	if not _begin_rewarded(board_key):
		return
	if bridge == null or not bridge.attach():
		_reward_report("unavailable", "Ads are unavailable. You can keep playing.")
		return
	if not _reward_attached:
		bridge.sdk.connect("initialization_completed", _reward_initialized)
		bridge.sdk.connect("rewarded_ad_loaded", _reward_loaded)
		bridge.sdk.connect("rewarded_ad_failed_to_load", _reward_load_failed)
		bridge.sdk.connect("rewarded_ad_failed_to_show_full_screen_content", _reward_show_failed)
		bridge.sdk.connect("rewarded_ad_dismissed_full_screen_content", _reward_dismissed)
		bridge.sdk.connect("rewarded_ad_user_earned_reward", _reward_earned)
		_reward_attached = true
	if bridge.sdk.get("is_initialization_completed"):
		_request_rewarded()
	else:
		_reward_report("initializing", "Preparing your ad…")
		bridge.sdk.call("initialize")

func _reward_initialized(_info: Variant) -> void:
	if can_request() and rewarded_state == "initializing":
		_request_rewarded()

func _request_rewarded() -> void:
	_reward_report("loading", "Loading your ad…")
	var request: Variant = bridge.sdk.call("create_rewarded_ad_request")
	request.call("set_custom_data", reward_request)
	bridge.sdk.call("load_rewarded_ad", request)

func _matches_reward_request(ad: Variant) -> bool:
	if ad == null or reward_request.is_empty():
		return false
	var request: Variant = ad.call("get_load_ad_request")
	return request != null and request.call("get_custom_data") == reward_request

func _reward_loaded(ad: Variant, _info: Variant) -> void:
	if not _matches_reward_request(ad) or not can_request() or rewarded_state != "loading":
		bridge.sdk.call("remove_rewarded_ad", ad.call("get_ad_id"))
		return
	_reward_ad_id = ad.call("get_ad_id")
	_reward_report("ready", "Your rewarded ad is ready.")

func show_rewarded() -> void:
	if not can_request() or rewarded_state != "ready" or _reward_ad_id.is_empty():
		_reward_report("not_ready", "No rewarded ad available. Keep playing.")
		return
	_reward_report("showing", "Complete the ad to earn your peek.")
	bridge.sdk.call("show_rewarded_ad", _reward_ad_id)

func _reward_load_failed(ad: Variant, _error: Variant) -> void:
	if _matches_reward_request(ad) and can_request():
		_reward_report("failure", "No ad available. Keep playing or try again.")

func _reward_show_failed(ad: Variant, _error: Variant) -> void:
	if _matches_reward_request(ad):
		bridge.sdk.call("remove_rewarded_ad", ad.call("get_ad_id"))
		_reward_ad_id = ""
		_reward_report("failure", "The ad could not open. Your peek was not used.")

func _reward_dismissed(ad: Variant) -> void:
	if _matches_reward_request(ad):
		_reward_ad_id = ""
		_reward_report("dismissed", "Ad closed.")

func _reward_earned(ad: Variant, _reward: Variant) -> void:
	if _matches_reward_request(ad):
		_deliver_reward(reward_request)

func cancel_rewarded() -> void:
	var showing: bool = rewarded_state == "showing"
	super.cancel_rewarded()
	if bridge != null and bridge.sdk != null and bridge.sdk.has_method("is_rewarded_ad_loaded") and not showing:
		while bridge.sdk.call("is_rewarded_ad_loaded"):
			bridge.sdk.call("remove_rewarded_ad")
	_reward_ad_id = ""
