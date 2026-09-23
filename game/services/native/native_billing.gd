class_name NativeBilling
extends BillingService
## Play supplies records; only the verification server can authorize Plus.
var config: MonetizationConfig = MonetizationConfig.new()
var client: Node
var cache_path: String = "user://play_entitlement.json"
var identity_path: String = "user://play_installation.txt"
var verifier: VerifiedEntitlement = VerifiedEntitlement.new()
var access: ReviewAccess
var _http: HTTPRequest
var _receipt: Dictionary = {}
var _nonce: String = ""
var _token: String = ""
var _querying: bool = false
var _requery: bool = false
var _last_time: int = 0
var _check_elapsed: float = 0.0
var _operation: int = 0
var _purchase_revision: int = 0
var _query_revision: int = 0
var _last_tick: int = Time.get_ticks_msec()

func initialize() -> void:
	verifier.public_key = config.receipt_public_key
	if FileAccess.file_exists(identity_path):
		verifier.device_id = FileAccess.get_file_as_string(identity_path).strip_edges()
	if verifier.device_id.length() != 64:
		verifier.device_id = Crypto.new().generate_random_bytes(32).hex_encode()
		var file: FileAccess = FileAccess.open(identity_path, FileAccess.WRITE)
		if file != null:
			file.store_string(verifier.device_id)
	if FileAccess.file_exists(cache_path):
		var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(cache_path))
		if saved is Dictionary:
			_receipt = saved.get("receipt", {}) if saved.get("receipt") is Dictionary else {}
			_last_time = int(saved.get("last_time", 0))
	access = ReviewAccess.new()
	access.verifier = verifier
	access.cache_path = cache_path + ".access"
	if config.billing_enabled() and config.verification_url.ends_with("/v1/play/verify"):
		access.url = config.verification_url.trim_suffix("/v1/play/verify") + "/v1/access/redeem"
	add_child(access)
	access.changed.connect(_refresh_cached)
	access.status_changed.connect(_report)
	access.initialize()
	_refresh_cached()
	connect_store()

func redeem_access(code: String) -> void:
	if access != null and not state in ["purchasing", "verifying"]:
		access.redeem(code)

func can_purchase() -> bool:
	return super.can_purchase() and not (access != null and access.busy)

func clear_access() -> void:
	if access != null:
		access.clear()

func connect_store() -> void:
	if client == null:
		if not Engine.has_singleton("GodotGooglePlayBilling"):
			_report("unavailable", "Purchases require Google Play on Android.")
			return
		var script: Script = load("res://addons/GodotGooglePlayBilling/BillingClient.gd")
		client = script.new() as Node
		client.connect("connected", _on_connected)
		client.connect("connect_error", _on_connection_error)
		client.connect("disconnected", _on_disconnected)
		client.connect("query_product_details_response", _on_products)
		client.connect("query_purchases_response", _on_query)
		client.connect("on_purchase_updated", _on_purchases)
		add_child(client)
	if client.call("is_ready"):
		_on_connected()
		return
	if state == "connecting":
		return
	product_available = false
	_report("connecting", "Connecting to Google Play…")
	client.call("start_connection")
	_watch_operation("connecting")

func purchase(product_id: String = REMOVE_ADS) -> void:
	if not config.billing_enabled():
		_report("disabled", "Purchasing is not configured for this build.")
		return
	if product_id != REMOVE_ADS or not can_purchase():
		return
	if client == null or not client.call("is_ready"):
		_report("unavailable", "Google Play is unavailable. Try restoring your purchase.")
		return
	_report("purchasing", "Complete your purchase in Google Play.")
	var response: Dictionary = client.call("purchase", REMOVE_ADS, config.purchase_option)
	var code: int = int(response.get("response_code", -1))
	if code == 7:
		_report("owned", "Checking your existing purchase…")
		restore()
	elif code != 0:
		_report("cancelled" if code == 1 else "failure", "Purchase cancelled." if code == 1 else "Google Play could not start the purchase. Please try again.")
	else:
		_watch_operation("purchasing")

func restore() -> void:
	_refresh_cached()
	if not _nonce.is_empty():
		_requery = true
		return
	if _querying:
		return
	if client == null or not client.call("is_ready"):
		connect_store()
		return
	_querying = true
	_query_revision = _purchase_revision
	if not product_available and config.billing_enabled():
		client.call("query_product_details", PackedStringArray([REMOVE_ADS]), 0)
	_report("restoring", "Checking your Google Play purchases…")
	client.call("query_purchases", 0)
	_watch_operation("restoring")

func _on_connected() -> void:
	_report("connected", "Google Play connected.")
	restore()

func _on_products(response: Dictionary) -> void:
	product_available = false
	product_price = ""
	if int(response.get("response_code", -1)) == 0:
		for product: Dictionary in response.get("product_details", []):
			if product.get("product_id") != REMOVE_ADS:
				continue
			var offers: Variant = product.get("one_time_purchase_offer_details_list", [])
			if offers is Array:
				for offer: Dictionary in offers:
					if offer.get("purchase_option_id", "") == config.purchase_option and offer.get("offer_id") in [null, ""] and offer.get("rental_details") == null:
						product_price = offer.formatted_price if offer.get("formatted_price") is String else ""
						product_available = not product_price.is_empty()
	state_changed.emit(state, detail)

func _on_connection_error(_code: int, _description: String) -> void:
	_on_disconnected()

func _on_disconnected() -> void:
	_querying = false
	product_available = false
	_report("unavailable", "Google Play is unavailable. You can keep playing and try again later.")

func _on_query(response: Dictionary) -> void:
	var was_querying: bool = _querying
	_querying = false
	if was_querying and _query_revision != _purchase_revision:
		# A purchase update is newer than this ownership snapshot. Query again after
		# verification so the older response cannot erase a newly completed purchase.
		restore()
		return
	_process_purchases(response, true)

func _on_purchases(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) == 0:
		_purchase_revision += 1
	_process_purchases(response, false)

func _process_purchases(response: Dictionary, complete_query: bool) -> void:
	var code: int = int(response.get("response_code", -1))
	if code == 7:
		restore()
		return
	if code != 0:
		if _nonce.is_empty():
			_report("cancelled" if code == 1 else "failure", "Purchase cancelled." if code == 1 else "Couldn't check your purchase. Try Restore purchase when connected.")
		return
	if not response.get("purchases") is Array:
		_report("failure", "Couldn't read your purchases. Please try again.")
		return
	var pending: bool = false
	for record: Dictionary in response.purchases:
		if not REMOVE_ADS in record.get("product_ids", []) or record.get("package_name") != MonetizationConfig.PACKAGE:
			continue
		if int(record.get("purchase_state", 0)) == 2:
			pending = true
		elif int(record.get("purchase_state", 0)) == 1:
			_verify(str(record.get("purchase_token", "")))
			return
	if complete_query:
		_cancel_verification()
		_receipt = {}
		_save_cache()
		_refresh_cached()
	if pending:
		_report("pending", "Payment is pending. Plus unlocks after Google Play confirms it.")
	elif complete_query:
		_report("empty", "No Plus purchase found for this Google Play account.")

func _verify(token: String) -> void:
	if not config.billing_enabled() or token.is_empty():
		_report("verification_required", "Purchase verification is unavailable. Please try Restore purchase later.")
		return
	if not _nonce.is_empty():
		if token != _token:
			_requery = true
		return
	_token = token
	_nonce = Crypto.new().generate_random_bytes(32).hex_encode()
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = 20.0
		_http.body_size_limit = 16384
		_http.max_redirects = 0
		add_child(_http)
		_http.request_completed.connect(_verified)
	_report("verifying", "Confirming your purchase…")
	var body: String = JSON.stringify({"product": REMOVE_ADS, "token": token, "device": verifier.device_id, "nonce": _nonce})
	if _http.request(config.verification_url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body) != OK:
		_verification_failed()

func _verified(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _nonce.is_empty():
		return
	var response: Variant = JSON.parse_string(body.get_string_from_utf8())
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not response is Dictionary:
		_verification_failed()
		return
	var data: Dictionary = verifier.claims(response, _now(), _nonce)
	if data.is_empty() or data.get("token_hash") != _token.sha256_text():
		_verification_failed()
		return
	_nonce = ""
	_token = ""
	_receipt = response if data.status == "active" else {}
	var saved: bool = _save_cache()
	_refresh_cached()
	if data.status == "active":
		_report("purchased", "Mem-Mem Plus is active." if saved else "Plus is active. Offline access couldn't be saved; restore when connected.")
	else:
		_report("pending" if data.status == "pending" else "revoked", "Payment is pending." if data.status == "pending" else "This purchase is no longer active.")
	if _requery:
		_requery = false
		restore()

func _verification_failed() -> void:
	_nonce = ""
	_token = ""
	_requery = false
	_refresh_cached()
	_report("failure", "Couldn't confirm your purchase. Try Restore purchase when connected; you won't be charged again.")

func _cancel_verification() -> void:
	if _http != null:
		_http.cancel_request()
	_nonce = ""
	_token = ""
	_requery = false

func _now() -> int:
	var tick: int = Time.get_ticks_msec()
	var elapsed: int = (tick - _last_tick) / 1000
	_last_time = maxi(_last_time + elapsed, int(Time.get_unix_time_from_system()))
	_last_tick += elapsed * 1000
	return _last_time

func _refresh_cached() -> void:
	var data: Dictionary = verifier.claims(_receipt, _now())
	var active: bool = data.get("status") == "active" or (access != null and access.active)
	if active != ad_free:
		_set_entitlement(active)

func _save_cache() -> bool:
	var file: FileAccess = FileAccess.open(cache_path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"receipt": _receipt, "last_time": _now()}))
	file.close()
	return DirAccess.rename_absolute(cache_path + ".tmp", cache_path) == OK

func _process(delta: float) -> void:
	_check_elapsed += delta
	if _check_elapsed >= 60.0:
		_check_elapsed = 0.0
		if access != null:
			access.refresh()
			access._save()
		_refresh_cached()
		if not _receipt.is_empty():
			_save_cache()

func _watch_operation(expected: String) -> void:
	_operation += 1
	var ticket: int = _operation
	await get_tree().create_timer(60.0).timeout
	if ticket == _operation and state == expected:
		_querying = false
		_report("failure", "Google Play didn't respond. Please try Restore purchase.")

func _exit_tree() -> void:
	_cancel_verification()
	if client != null:
		client.call("end_connection")
