class_name MonetizationConfig
extends RefCounted
## Only the store export opts in. Missing configuration always fails closed.
const PACKAGE: String = "io.github.vincentaz.memmem"
var production: bool = OS.has_feature("production")
var verification_url: String = ""
var receipt_public_key: String = ""
var admob_app_id: String = ""
var rewarded_unit_id: String = ""
var privacy_url: String = ""
var purchase_option: String = ""
var child_directed: bool = true
var under_age_of_consent: bool = true
var audience_configured: bool = false

func _init() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load("res://monetization.cfg") != OK:
		return
	verification_url = str(config.get_value("production", "verification_url", ""))
	receipt_public_key = str(config.get_value("production", "receipt_public_key", ""))
	admob_app_id = str(config.get_value("production", "admob_app_id", ""))
	rewarded_unit_id = str(config.get_value("production", "rewarded_unit_id", ""))
	privacy_url = str(config.get_value("production", "privacy_url", ""))
	purchase_option = str(config.get_value("production", "purchase_option", ""))
	var child_setting: Variant = config.get_value("production", "child_directed", null)
	var age_setting: Variant = config.get_value("production", "under_age_of_consent", null)
	audience_configured = child_setting is bool and age_setting is bool
	if audience_configured:
		child_directed = child_setting
		under_age_of_consent = age_setting

func billing_enabled() -> bool:
	return production and verification_url.begins_with("https://") and not receipt_public_key.is_empty() and not purchase_option.is_empty()

func ads_enabled() -> bool:
	return production and audience_configured and admob_app_id.begins_with("ca-app-pub-") and rewarded_unit_id.begins_with("ca-app-pub-") and not admob_app_id.contains("3940256099942544") and not rewarded_unit_id.contains("3940256099942544")

func development_enabled() -> bool:
	return OS.is_debug_build() and not production
