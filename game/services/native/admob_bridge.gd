class_name AdmobBridge
extends Node
## Shared plugin node for the native advertising and UMP adapters. Google demo IDs only.
const DEMO_APP_ID: String = "ca-app-pub-3940256099942544~3347511713"
var sdk: Node

func attach() -> bool:
	if sdk != null:
		return true
	if not Engine.has_singleton("AdmobPlugin"):
		return false
	var script: Script = load("res://addons/AdmobPlugin/Admob.gd")
	sdk = script.new() as Node
	sdk.set("is_real", false)
	sdk.set("android_debug_application_id", DEMO_APP_ID)
	sdk.set("first_party_id_enabled", false)
	sdk.set("personalization_state", 2)
	sdk.set("global_ads_muted", true)
	sdk.set("global_apply_at_startup", true)
	sdk.set("auto_show_on_resume", false)
	sdk.set("remove_interstitial_ads_after_displayed", true)
	add_child(sdk)
	return true
