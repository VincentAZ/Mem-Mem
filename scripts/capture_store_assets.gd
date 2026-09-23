extends SceneTree
## Run with the project engine and an isolated XDG_DATA_HOME (see store-assets/README.md).
## Captures real UI; never changes the production app or a player's save.
var app: GameScreen
var output: String

func _initialize() -> void:
	_run.call_deferred()

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result: int = root.get_texture().get_image().save_png(output.path_join(name + ".png"))
	assert(result == OK)
	print("Captured " + name)

func _phase(value: String) -> void:
	for frame: int in range(1800):
		if app.phase == value:
			return
		await process_frame
	push_error("Capture timed out waiting for " + value)
	quit(1)

func _clear_round() -> void:
	var model: MatchRound = app.progress.round_state
	for i: int in range(model.identities.size()):
		if model.removed.has(i):
			continue
		app._select(i)
		await create_timer(0.25).timeout
		app._select(model.identities.rfind(model.identities[i]))
		if i == 0:
			await create_timer(0.39).timeout
			await _capture("02-find-a-match")
		await create_timer(0.9).timeout
	await _phase("celebrating")
	await create_timer(1.5).timeout

func _run() -> void:
	output = ProjectSettings.globalize_path("res://../store-assets")
	DirAccess.make_dir_recursive_absolute(output)
	# Play applies its own icon mask; keep the existing monogram on a square background.
	var svg: String = FileAccess.get_file_as_string("res://assets/icon.svg").replace('rx="100"', '')
	var icon: Image = Image.new()
	assert(icon.load_svg_from_string(svg, 512.0 / 432.0) == OK)
	assert(icon.save_png(output.path_join("icon.png")) == OK)
	root.size = Vector2i(1080, 1920)
	root.content_scale_size = Vector2i(432, 768)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var fixture: GameProgress = GameProgress.create(4815)
	fixture.sound = false
	fixture.haptics = false
	var capture_store: ProgressStore = ProgressStore.new()
	capture_store.prefix = "user://store_capture_progress_%d" % int(Time.get_unix_time_from_system() * 1000000)
	assert(capture_store.save(fixture))
	app = load("res://scenes/main.tscn").instantiate() as GameScreen
	app.monetization.production = true
	app.store = capture_store
	app.native_billing.cache_path = "user://store_capture_receipt.json"
	app.native_billing.identity_path = "user://store_capture_installation.txt"
	root.add_child(app)
	await _phase("preview")
	await _capture("01-match-pairs")
	await _phase("playing")
	await _clear_round()
	app._open_collection(true)
	await create_timer(0.3).timeout
	await _capture("03-discover-characters")
	app._close_collection()
	app.progress.dark_mode = true
	app.dark_toggle.set_pressed_no_signal(true)
	app._apply_palette()
	app._next_level()
	await _phase("preview")
	await _capture("04-dark-mode")
	app.queue_free()
	await process_frame
	await _feature()
	print("STORE ASSETS CAPTURED")
	quit()

func _feature() -> void:
	root.size = Vector2i(1024, 500)
	root.content_scale_size = Vector2i(1024, 500)
	GamePalette.configure(false, 0)
	var canvas: Control = Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)
	var background: ColorRect = ColorRect.new()
	background.color = Color("f8f4ec")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(background)
	var accent: ColorRect = ColorRect.new()
	accent.color = Color("244c43")
	accent.position = Vector2(64, 104)
	accent.size = Vector2(48, 5)
	canvas.add_child(accent)
	var title: Label = Label.new()
	title.text = "mem·mem"
	title.position = Vector2(60, 127)
	title.add_theme_font_size_override("font_size", 70)
	title.add_theme_color_override("font_color", Color("244c43"))
	canvas.add_child(title)
	var subtitle: Label = Label.new()
	subtitle.text = "A little time for you.\nA match worth finding."
	subtitle.position = Vector2(65, 235)
	subtitle.add_theme_font_size_override("font_size", 25)
	subtitle.add_theme_color_override("font_color", Color("64756a"))
	canvas.add_child(subtitle)
	var note: Label = Label.new()
	note.text = "MATCH  ·  COLLECT  ·  UNWIND"
	note.position = Vector2(66, 364)
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color("98704e"))
	canvas.add_child(note)
	for i: int in range(4):
		var tile: PortraitTile = PortraitTile.new()
		tile.position = Vector2(550 + (i % 2) * 187, 66 + (i / 2) * 191)
		tile.size = Vector2(166, 174)
		tile.variant = 0 if i % 2 == 0 else 18
		tile.delighted = i >= 2
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(tile)
	await _capture("feature-graphic")
