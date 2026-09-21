class_name SimulatedAds
extends AdsService
var fail_load: bool = false
var fail_show: bool = false

func load_ad() -> void:
	if not can_request():
		_report("suppressed" if ad_free else "blocked", "SIMULATED: ad removal or consent blocks this request.")
		return
	if state == "showing":
		return
	invalidate()
	var ticket: int = generation
	var should_fail: bool = fail_load
	_report("loading", "SIMULATED: loading a test ad.")
	await get_tree().create_timer(0.15).timeout
	if ticket != generation or not can_request():
		return
	if should_fail:
		_report("failure", "SIMULATED: ad failed to load. Play can continue.")
	else:
		loaded = true
		_report("ready", "SIMULATED: test ad is ready.")

func show_ad() -> void:
	if not can_request() or not loaded:
		_report("suppressed" if ad_free else "not_ready", "SIMULATED: no eligible ad. Play can continue.")
		return
	loaded = false
	_report("failure" if fail_show else "showing", "SIMULATED: display failed." if fail_show else "SIMULATED AD — dismiss to return.")

func dismiss() -> void:
	if state == "showing":
		_report("dismissed", "SIMULATED: ad dismissed. Play can continue.")

