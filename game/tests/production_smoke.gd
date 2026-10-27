extends SceneTree
var failures: int = 0
func _initialize() -> void:
	_run.call_deferred()
func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("TEST FAILED: " + description)
func _run() -> void:
	root.size = Vector2i(432, 900)
	var app: GameScreen = load("res://scenes/main.tscn").instantiate() as GameScreen
	app.store.prefix = "user://production_smoke_progress"
	root.add_child(app)
	await process_frame
	await process_frame
	check(PeopleCatalog.available_themes(false) == PeopleCatalog.ALL_THEMES, "all seven themes are free even for a legacy free save")
	app._pause()
	check(not _has_purchase_button(app.pause_menu), "settings contain no purchases, ad offers or restoration")
	app.progress.round_state.begin_play()
	check(app.progress.round_state.can_peek(false), "free Quick Peek needs no ad or entitlement")
	app._open_collection(true)
	check(app.collection_panel.entries.size() == 56, "all 56 characters can be browsed")
	check(app.collection_panel.entries.all(func(card: CollectionCard) -> bool: return not card.locked), "no character has a paid lock")
	app.queue_free()
	await process_frame
	for slot: int in [0, 1]:
		DirAccess.remove_absolute("user://production_smoke_progress.%d.json" % slot)
	print("PRODUCTION SMOKE PASSED" if failures == 0 else "PRODUCTION SMOKE FAILED")
	quit(1 if failures else 0)
func _has_purchase_button(node: Node) -> bool:
	if node is BaseButton:
		var text: String = str(node.get("text")).to_lower()
		if text.contains("purchase") or text.contains("plus") or text.contains("watch ad") or text.contains("service lab"):
			return true
	for child: Node in node.get_children():
		if _has_purchase_button(child):
			return true
	return false
