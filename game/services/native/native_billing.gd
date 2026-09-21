class_name NativeBilling
extends BillingService
## Phase 1 can probe the real SDK, but cannot initiate a charge or grant real entitlements.
var client: Node

func connect_store() -> void:
	if not Engine.has_singleton("GodotGooglePlayBilling"):
		_report("unavailable", "Native billing requires the Android build and Google Play.")
		return
	if client != null:
		client.call("start_connection")
		return
	var script: Script = load("res://addons/GodotGooglePlayBilling/BillingClient.gd")
	client = script.new() as Node
	client.connect("connected", _on_connected)
	client.connect("connect_error", _on_connection_error)
	client.connect("disconnected", func() -> void: _report("disconnected", "Google Play connection closed."))
	client.connect("query_purchases_response", _on_purchases)
	client.connect("on_purchase_updated", _on_purchases)
	add_child(client)
	_report("connecting", "Connecting to Google Play. Purchases remain disabled.")
	client.call("start_connection")

func purchase(_product_id: String = REMOVE_ADS) -> void:
	_report("disabled", "Real-money purchasing is disabled in Phase 1.")

func restore() -> void:
	if client == null or not client.call("is_ready"):
		_report("unavailable", "Connect to Google Play first.")
		return
	client.call("query_purchases", 0)

func _on_connected() -> void:
	_report("connected", "Native Google Play SDK connected. Live validation requires a configured store app.")

func _on_connection_error(_code: int, description: String) -> void:
	_report("failure", description)

func _on_purchases(response: Dictionary) -> void:
	var code: int = int(response.get("response_code", -1))
	if code != 0:
		_report("cancelled" if code == 1 else "failure", "Google Play response code: %d" % code)
		return
	var purchases: Array = response.get("purchases", [])
	if purchases.is_empty():
		_report("empty", "No store purchases returned. No live restoration validated.")
		return
	# Do not log tokens, acknowledge, or grant anything before server verification exists.
	_report("verification_required", "Store records received; server verification is not configured. Ownership unchanged.")

func _exit_tree() -> void:
	if client != null:
		client.call("end_connection")

