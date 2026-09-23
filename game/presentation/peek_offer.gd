class_name PeekOffer
extends PanelContainer
signal closed
signal watch_requested
signal upgrade_requested
var watch: Button
var detail: Label
var title: Label
var native_test: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 17
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 20)
	margin.add_child(content)
	content.add_child(GameStyle.label("ONE MORE LOOK", 12, true))
	title = GameStyle.label("Quick Peek", 32)
	content.add_child(title)
	var explanation: Label = GameStyle.label("Watch an ad to unlock one 0.5-second peek for this board.\n\nThen tap Quick Peek whenever you’re ready. Your accuracy and rewards stay intact.", 17)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(explanation)
	detail = GameStyle.label("", 13, true)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(detail)
	watch = Button.new()
	watch.text = "Allow & watch test ad"
	watch.custom_minimum_size.y = 54
	watch.pressed.connect(func() -> void: watch_requested.emit())
	content.add_child(watch)
	var upgrade: Button = Button.new()
	upgrade.text = "Get peeks with Mem-Mem Plus"
	upgrade.custom_minimum_size.y = 48
	upgrade.pressed.connect(func() -> void: upgrade_requested.emit())
	content.add_child(upgrade)
	var close: Button = Button.new()
	close.text = "Keep playing"
	close.custom_minimum_size.y = 48
	close.pressed.connect(func() -> void: closed.emit())
	content.add_child(close)
	hide()

func open(use_native: bool, production: bool = false) -> void:
	native_test = use_native
	add_theme_stylebox_override("panel", GameStyle.surface(GamePalette.background, 0, 0))
	GameStyle.skin_button(watch, true)
	detail.text = "GOOGLE TEST AD · Allows test-ad requests only." if native_test else "SIMULATED AD · No network request."
	watch.text = "Allow & watch test ad"
	if production:
		detail.text = "Complete an ad to earn your peek. Closing early won't use a peek."
		watch.text = "Watch ad"
	watch.disabled = false
	show()
