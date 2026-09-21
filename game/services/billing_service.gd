class_name BillingService
extends Node
## Entitlements are separate from transient operation status. PENDING never grants ownership.
signal state_changed(state: String, detail: String)
signal entitlement_changed(ad_free: bool)

const REMOVE_ADS: String = "remove_ads"
var ad_free: bool = false
var state: String = "idle"
var detail: String = ""

func purchase(_product_id: String = REMOVE_ADS) -> void:
	_report("unavailable", "Billing is unavailable.")

func restore() -> void:
	_report("unavailable", "Restoration is unavailable.")

func _report(value: String, description: String) -> void:
	state = value
	detail = description
	state_changed.emit(state, detail)

func _set_entitlement(value: bool) -> void:
	ad_free = value
	entitlement_changed.emit(value)

