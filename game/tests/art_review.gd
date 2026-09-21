extends SceneTree
## Export-only visual review. No GameScreen, services, user saves, or network.
func _initialize() -> void:
	_render.call_deferred()

func _render() -> void:
	var theme_id: int = int(OS.get_cmdline_user_args()[0]) if not OS.get_cmdline_user_args().is_empty() else 0
	theme_id = clampi(theme_id, 0, 3)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1040, 650)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background: ColorRect = ColorRect.new()
	background.color = Color("f8f4ec")
	background.size = viewport.size
	viewport.add_child(background)
	var title: Label = Label.new()
	title.text = "mem·mem  /  " + PeopleCatalog.THEMES[theme_id]
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("244c43"))
	title.position = Vector2(28, 18)
	viewport.add_child(title)
	for family: int in range(6):
		var origin: Vector2 = Vector2(28 + (family % 3) * 340, 78 + (family / 3) * 282)
		for accessory: int in range(2):
			var tile: PortraitTile = PortraitTile.new()
			tile.variant = theme_id * 12 + family * 2 + accessory
			tile.size = Vector2(148, 174)
			tile.position = origin + Vector2(accessory * 154, 0)
			viewport.add_child(tile)
			var person: Walker = Walker.new()
			person.variant = tile.variant
			person.reduced_motion = true
			person.cheering = true
			person.scale = Vector2.ONE * 0.65
			person.position = tile.position + Vector2(74, 199)
			viewport.add_child(person)
	await process_frame
	await RenderingServer.frame_post_draw
	var path: String = ProjectSettings.globalize_path("res://../build/screenshots/character-pack-%d.png" % theme_id)
	var error: Error = viewport.get_texture().get_image().save_png(path)
	print("People pack review: ", path)
	quit(0 if error == OK else 1)
