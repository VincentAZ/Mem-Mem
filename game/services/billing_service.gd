class_name BillingService
extends Node
## Entitlements are separate from transient operation status. PENDING never grants ownership.
signal state_changed(state: String, detail: String)
signal entitlement_changed(ad_free: bool)

const REMOVE_ADS: String = "remove_ads"
const PLUS_TITLE: String = "Mem-Mem Plus"
const INTRO_PRICE_USD: String = "$1.99"
var product_price: String = ""
var simulated: bool = false

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


func has_plus() -> bool:
	return ad_free

func unlocked_themes() -> Array[int]:
	return PeopleCatalog.available_themes(has_plus())

func product_information() -> Dictionary:
	return {"id": REMOVE_ADS, "title": PLUS_TITLE, "price": product_price, "simulated": simulated, "permanent": true}
