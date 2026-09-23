class_name ReviewAccess
extends Node
## Same Plus benefits; a private reusable credential is verified only on the server.
signal changed
signal status_changed(state: String, detail: String)
var verifier: VerifiedEntitlement
var url: String = ""
var cache_path: String = ""
var active: bool = false
var busy: bool = false
var _receipt: Dictionary = {}
var _nonce: String = ""
var _token_hash: String = ""
var _http: HTTPRequest
var _last_time: int = 0
var _last_tick: int = Time.get_ticks_msec()

func initialize() -> void:
	if FileAccess.file_exists(cache_path):
		var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(cache_path))
		if saved is Dictionary:
			_receipt = saved.get("receipt", {}) if saved.get("receipt") is Dictionary else {}
			_last_time = int(saved.get("last_time", 0))
	refresh()

func _now() -> int:
	var tick: int = Time.get_ticks_msec()
	var elapsed: int = (tick - _last_tick) / 1000
	_last_time = maxi(_last_time + elapsed, int(Time.get_unix_time_from_system()))
	_last_tick += elapsed * 1000
	return _last_time

func refresh() -> void:
	var claims: Dictionary = verifier.claims(_receipt, _now()) if verifier != null else {}
	var valid: bool = claims.get("grant") == "review" and claims.get("status") == "active"
	if valid != active:
		active = valid
		changed.emit()

func redeem(code: String) -> void:
	if busy:
		return
	code = code.strip_edges()
	if not url.begins_with("https://") or code.length() < 32 or code.length() > 128 or verifier == null:
		status_changed.emit("access_failure", "Enter a valid access code. An internet connection is required.")
		return
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = 20.0
		_http.body_size_limit = 16384
		_http.max_redirects = 0
		add_child(_http)
		_http.request_completed.connect(_completed)
	busy = true
	_nonce = Crypto.new().generate_random_bytes(32).hex_encode()
	_token_hash = code.sha256_text()
	status_changed.emit("access_verifying", "Checking your access code…")
	var body: String = JSON.stringify({"product": BillingService.REMOVE_ADS, "token": code, "device": verifier.device_id, "nonce": _nonce})
	if _http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body) != OK:
		_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, [], PackedByteArray())

func _completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not busy:
		return
	busy = false
	var response: Variant = JSON.parse_string(body.get_string_from_utf8())
	var claims: Dictionary = {}
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200 and response is Dictionary:
		claims = verifier.claims(response, _now(), _nonce)
	var valid: bool = not claims.is_empty() and claims.get("grant") == "review" and claims.get("status") == "active" and claims.get("token_hash") == _token_hash
	_nonce = ""
	_token_hash = ""
	if valid:
		_receipt = response
		_save()
		refresh()
		status_changed.emit("access_active", "Plus access is active. Re-enter your code after seven days to renew.")
	else:
		refresh()
		status_changed.emit("access_failure", "Access code was not accepted." if response_code == 403 else "Could not verify access. Check your connection and try again.")

func _save() -> void:
	if cache_path.is_empty():
		return
	var file: FileAccess = FileAccess.open(cache_path + ".tmp", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"receipt": _receipt, "last_time": _now()}))
		file.close()
		DirAccess.rename_absolute(cache_path + ".tmp", cache_path)

func clear() -> void:
	if _http != null:
		_http.cancel_request()
	busy = false
	_nonce = ""
	_token_hash = ""
	_receipt = {}
	_save()
	refresh()
	status_changed.emit("access_cleared", "Access code benefits removed. Purchased Plus access is unchanged.")
