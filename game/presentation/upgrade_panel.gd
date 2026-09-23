class_name UpgradePanel
extends PanelContainer
signal closed
signal purchase_requested
signal restore_requested
signal access_requested(code: String)
signal access_clear_requested
var buy: Button
var restore_button: Button
var detail: Label
var price: Label
var access_button: Button
var access_dialog: ConfirmationDialog
var access_input: LineEdit

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 18
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	scroll.add_child(content)
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
	price.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	access_button = Button.new()
	access_button.text = "Use access code"
	access_button.custom_minimum_size.y = 40
	access_button.pressed.connect(func() -> void:
		access_input.clear()
		access_dialog.popup_centered(Vector2i(340, 220))
		access_input.grab_focus()
	)
	content.add_child(access_button)
	access_dialog = ConfirmationDialog.new()
	access_dialog.title = "Plus access code"
	access_dialog.ok_button_text = "Verify code"
	var access_content: VBoxContainer = VBoxContainer.new()
	var access_help: Label = Label.new()
	access_help.text = "Enter your provided code to unlock Plus.\nAn internet connection is required."
	access_help.add_theme_font_size_override("font_size", 14)
	access_help.add_theme_color_override("font_color", Color("f4f1e8"))
	access_content.add_child(access_help)
	access_input = LineEdit.new()
	access_input.placeholder_text = "Access code"
	access_input.secret = true
	access_input.max_length = 128
	access_input.custom_minimum_size.y = 44
	access_content.add_child(access_input)
	var clear_access: Button = Button.new()
	clear_access.text = "Remove code access"
	clear_access.pressed.connect(func() -> void:
		access_clear_requested.emit()
		access_dialog.hide()
	)
	access_content.add_child(clear_access)
	access_dialog.add_child(access_content)
	access_dialog.confirmed.connect(func() -> void:
		var code: String = access_input.text
		access_input.clear()
		access_requested.emit(code)
	)
	add_child(access_dialog)
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
	GameStyle.skin_button(access_button)
	access_button.visible = service is NativeBilling and service.config.billing_enabled()
	access_button.disabled = service is NativeBilling and service.access != null and service.access.busy
	price.text = "%s · one-time purchase" % service.product_price if not service.product_price.is_empty() else "Price unavailable · connect to Google Play"
	if service.has_plus():
		price.text = "Your Plus benefits are unlocked."
	buy.text = "Plus active" if service.has_plus() else "Get Plus · %s" % service.product_price if service.product_available else "Purchase unavailable"
	restore_button.text = "Restore purchase"
	buy.disabled = not service.can_purchase()
	restore_button.disabled = service.state in ["connecting", "restoring", "verifying", "purchasing"]
	detail.text = "Characters are collected through perfect rounds."
	if service.simulated:
		buy.text = "Plus active · simulated" if service.has_plus() else "Simulate Plus · %s" % service.product_price
		restore_button.text += " · test"
		detail.text = "DEVELOPMENT TEST · No payment is taken.\n" + detail.text
	if not service.detail.is_empty():
		detail.text += "\n" + service.detail
