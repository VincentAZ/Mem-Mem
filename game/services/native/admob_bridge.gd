class_name AdmobBridge
extends Node
## Shared SDK instance. Production IDs come only from a validated store export.
const DEMO_APP_ID: String = "ca-app-pub-3940256099942544~3347511713"
var sdk: Node
var config: MonetizationConfig = MonetizationConfig.new()

func attach() -> bool:
	if sdk != null:
		return true
	if not Engine.has_singleton("AdmobPlugin"):
		return false
	if config.production and not config.ads_enabled():
		return false
	var script: Script = load("res://addons/AdmobPlugin/Admob.gd")
	sdk = script.new() as Node
	sdk.set("is_real", config.production)
	sdk.set("android_debug_application_id", DEMO_APP_ID)
	if config.production:
		sdk.set("android_real_application_id", config.admob_app_id)
		sdk.set("android_real_rewarded_id", config.rewarded_unit_id)
		sdk.set("child_directed", 1 if config.child_directed else 0)
		sdk.set("under_age_of_consent", 1 if config.under_age_of_consent else 0)
		sdk.set("max_ad_content_rating", 0)
	sdk.set("first_party_id_enabled", false)
	sdk.set("personalization_state", 2)
	sdk.set("global_ads_muted", true)
	sdk.set("global_apply_at_startup", true)
	sdk.set("auto_show_on_resume", false)
	sdk.set("remove_interstitial_ads_after_displayed", true)
	add_child(sdk)
	return true
