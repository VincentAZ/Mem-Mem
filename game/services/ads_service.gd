class_name AdsService
extends Node
signal state_changed(state: String, detail: String)
signal rewarded_state_changed(board_key: String, state: String, detail: String)
signal reward_earned(board_key: String, request_id: String)
var rewarded_state: String = "idle"
var rewarded_board: String = ""
var reward_request: String = ""
var _reward_sequence: int = 0
var _reward_delivered: bool = false


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
	cancel_rewarded()

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


func load_rewarded(_board_key: String) -> void:
	_reward_report("unavailable", "Rewarded ads are unavailable.")

func show_rewarded() -> void:
	_reward_report("unavailable", "Rewarded ads are unavailable.")

func cancel_rewarded() -> void:
	var had_request: bool = not reward_request.is_empty()
	reward_request = ""
	if had_request:
		_reward_report("cancelled", "Ad request closed. Gameplay continues.")
	rewarded_board = ""

func _begin_rewarded(board_key: String) -> bool:
	if not can_request():
		_reward_report("blocked", "Ad removal or consent blocks this request.")
		return false
	if rewarded_state in ["loading", "initializing", "showing"]:
		return false
	_reward_sequence += 1
	reward_request = "%d-%d-%d" % [get_instance_id(), Time.get_ticks_usec(), _reward_sequence]
	rewarded_board = board_key
	_reward_delivered = false
	return true

func _deliver_reward(request_id: String) -> void:
	if request_id.is_empty() or request_id != reward_request or _reward_delivered or not can_request() or not rewarded_state in ["showing", "dismissed"]:
		return
	_reward_delivered = true
	reward_earned.emit(rewarded_board, request_id)

func _reward_report(value: String, description: String) -> void:
	rewarded_state = value
	rewarded_state_changed.emit(rewarded_board, value, description)
