class_name UpgradePanel
extends PanelContainer
signal closed
signal purchase_requested
signal restore_requested
var buy: Button
var restore_button: Button
var detail: Label
var price: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 18
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)
	var eyebrow: Label = GameStyle.label("MEM-MEM PLUS", 12, true)
	content.add_child(eyebrow)
	content.add_child(GameStyle.label("More to match.", 32))
	var cast: HBoxContainer = HBoxContainer.new()
	cast.add_theme_constant_override("separation", 10)
	content.add_child(cast)
	for character: int in [32, 40, 48]:
		var tile: PortraitTile = PortraitTile.new()
		tile.variant = character
		tile.custom_minimum_size = Vector2(0, 112)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.focus_mode = Control.FOCUS_NONE
		cast.add_child(tile)
	var benefits: Label = GameStyle.label("Three extra themes. 24 new characters to earn.\n\nWoodland Crew · Snack Squad · Mythical Misfits\n\nOne Quick Peek on every board.\nNo ads. Yours with one purchase.", 16)
	benefits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(benefits)
	price = GameStyle.label("", 20)
	content.add_child(price)
	detail = GameStyle.label("", 13, true)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(detail)
	buy = Button.new()
	buy.custom_minimum_size.y = 52
	buy.pressed.connect(func() -> void: purchase_requested.emit())
	content.add_child(buy)
	restore_button = Button.new()
	restore_button.text = "Restore purchase · test"
	restore_button.custom_minimum_size.y = 46
	restore_button.pressed.connect(func() -> void: restore_requested.emit())
	content.add_child(restore_button)
	var close: Button = Button.new()
	close.text = "Back to game"
	close.custom_minimum_size.y = 46
	close.pressed.connect(func() -> void: closed.emit())
	content.add_child(close)
	hide()

func refresh(service: BillingService) -> void:
	add_theme_stylebox_override("panel", GameStyle.surface(GamePalette.background, 0, 0))
	GameStyle.skin_button(buy, true)
	GameStyle.skin_button(restore_button)
	price.text = "%s · one-time launch price" % service.product_price if not service.product_price.is_empty() else "Price unavailable"
	buy.text = "Plus active · simulated" if service.has_plus() else "Simulate Plus · %s" % service.product_price
	buy.disabled = service.has_plus() or service.state in ["purchasing", "pending"]
	detail.text = "DEVELOPMENT TEST · No payment is taken.\nCharacters are collected through perfect rounds."
	if service.state in ["pending", "failure", "cancelled", "restored", "empty", "purchased"]:
		detail.text += "\n" + service.detail
