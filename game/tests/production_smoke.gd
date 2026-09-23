extends SceneTree
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("TEST FAILED: " + description)

func _run() -> void:
	root.size = Vector2i(432, 768)
	root.content_scale_size = Vector2i(432, 768)
	var app: GameScreen = load("res://scenes/main.tscn").instantiate() as GameScreen
	app.monetization.production = true
	app.store.prefix = "user://production_smoke_progress"
	app.native_billing.cache_path = "user://production_smoke_entitlement.json"
	app.native_billing.identity_path = "user://production_smoke_installation.txt"
	root.add_child(app)
	await process_frame
	await process_frame
	check(app.billing == app.native_billing, "store scene selects native billing")
	check(app.native_billing.is_inside_tree(), "production initialization reaches service connection")
	check(not app.smoke_mode and app.lab == null, "store scene contains no development lab")
	check(not app.billing.simulated and not app.billing.has_plus(), "store scene ignores simulated ownership")
	app._pause()
	check(not _has_development_button(app.pause_menu), "store settings expose no simulated purchase or ad toggles")
	app._open_upgrade()
	await process_frame
	check(app.upgrade_panel.buy.disabled, "unconfigured store purchase cannot be tapped")
	check(not app.upgrade_panel.detail.text.contains("SIMULAT") and not app.upgrade_panel.detail.text.contains("DEVELOPMENT"), "store offer has player-facing copy")
	check(app.upgrade_panel.restore_button.text == "Restore purchase", "store restoration has a real purchase label")
	check(not app.upgrade_panel.access_button.visible, "unconfigured build does not advertise unavailable access codes")
	# Configure only the public test endpoint to exercise the real access UI; never request it.
	app.monetization.verification_url = "https://verifier.invalid/v1/play/verify"
	app.monetization.receipt_public_key = "fixture-public-key"
	app.monetization.purchase_option = "buy"
	app.upgrade_panel.refresh(app.billing)
	check(app.upgrade_panel.access_button.visible, "configured store build exposes reusable access code entry")
	app.upgrade_panel.access_button.pressed.emit()
	await process_frame
	check(app.upgrade_panel.access_dialog.visible and app.upgrade_panel.access_input.secret, "access credential entry is visible and masked")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://").path_join("../build/screenshots/production-access.png"))
	app.upgrade_panel.access_dialog.hide()
	app._close_upgrade()
	app._resume()
	app._open_lab()
	check(app.lab == null, "production cannot open the development lab")
	app.queue_free()
	await process_frame
	for slot: int in [0, 1]:
		DirAccess.remove_absolute("user://production_smoke_progress.%d.json" % slot)
	DirAccess.remove_absolute("user://production_smoke_entitlement.json")
	DirAccess.remove_absolute("user://production_smoke_installation.txt")
	print("PRODUCTION SMOKE PASSED" if failures == 0 else "PRODUCTION SMOKE FAILED")
	quit(1 if failures else 0)

func _has_development_button(node: Node) -> bool:
	if node is BaseButton:
		var text: String = str(node.get("text")).to_lower()
		if text.contains("simulat") or text.contains("development") or text.contains("· test"):
			return true
	for child: Node in node.get_children():
		if _has_development_button(child):
			return true
	return false
