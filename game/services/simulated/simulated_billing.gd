class_name SimulatedBilling
extends BillingService
## Development-only fake ownership. This file is never read by the native adapter.
var outcome: String = "success"
var save_path: String = "user://simulated_ownership.json"
var pending: bool = false
var _generation: int = 0
var _busy: bool = false

func purchase(product_id: String = REMOVE_ADS) -> void:
	if product_id != REMOVE_ADS:
		_report("failure", "SIMULATED: unknown product.")
		return
	if _busy or pending:
		return
	if ad_free:
		_report("owned", "SIMULATED: already owned.")
		return
	_busy = true
	_generation += 1
	var ticket: int = _generation
	var chosen_outcome: String = outcome
	_report("purchasing", "SIMULATED: no payment will be made.")
	await get_tree().create_timer(0.15).timeout
	if ticket != _generation:
		return
	_busy = false
	match chosen_outcome:
		"success":
			_grant("purchased")
		"cancel":
			_report("cancelled", "SIMULATED: user cancelled; ownership unchanged.")
		"pending":
			pending = true
			_report("pending", "SIMULATED: awaiting payment. Ads remain enabled.")
		_:
			_report("failure", "SIMULATED: store unavailable; try again later.")

func complete_pending(success: bool) -> void:
	if not pending:
		return
	pending = false
	if success:
		_grant("purchased")
	else:
		_report("cancelled", "SIMULATED: pending payment cancelled.")

func restore() -> void:
	_generation += 1
	_busy = false
	pending = false
	var owns: bool = false
	if FileAccess.file_exists(save_path):
		var parser: JSON = JSON.new()
		if parser.parse(FileAccess.get_file_as_string(save_path)) == OK and parser.data is Dictionary:
			owns = parser.data.get("version") == 1 and parser.data.get("simulated_ad_free", false) == true
	_set_entitlement(owns)
	_report("restored" if owns else "empty", "SIMULATED: restored ownership." if owns else "SIMULATED: no purchases to restore.")

func seed_restorable_purchase() -> void:
	# Simulates an account-owned purchase independently of this device's current state.
	_write(true)

func reset_simulation() -> void:
	_generation += 1
	_busy = false
	pending = false
	_write(false)
	_set_entitlement(false)
	_report("idle", "SIMULATED: ownership reset.")

func _grant(result: String) -> void:
	if not _write(true):
		_report("failure", "SIMULATED: could not save ownership; retry restoration.")
		return
	_set_entitlement(true)
	_report(result, "SIMULATED: ad removal is active. No money was charged.")

func _write(value: bool) -> bool:
	var temporary: String = save_path + ".tmp"
	var stream: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if stream == null:
		return false
	stream.store_string(JSON.stringify({"version": 1, "simulated_ad_free": value}))
	stream.close()
	return DirAccess.rename_absolute(temporary, save_path) == OK
