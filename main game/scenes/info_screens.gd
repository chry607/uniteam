class_name InfoScreens
extends Control
## How to Play + Credits panels.

signal closed

enum Mode { HOW_TO, CREDITS }

var _panel: PanelContainer
var _title: Label
var _body: RichTextLabel
var _mode: Mode = Mode.HOW_TO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay := ColorRect.new()
	overlay.color = Palette.OVERLAY_DARK
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", StyleFactory.modal_panel())
	_panel.custom_minimum_size = Vector2(680, 620)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	margin.add_child(v)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_display(_title, 48, Palette.TEXT_DARK, true)
	v.add_child(_title)

	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = false
	_body.scroll_active = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size = Vector2(580, 400)
	_body.add_theme_font_override("normal_font", FontRegistry.ui())
	_body.add_theme_font_size_override("normal_font_size", 20)
	_body.add_theme_color_override("default_color", Palette.TEXT_DARK)
	v.add_child(_body)

	var back := GameButton.new()
	back.text = "BACK"
	back.button_id = "info_back"
	back.variant = GameButton.Style.PRIMARY
	back.base_font_size = 28
	back.custom_minimum_size = Vector2(200, 60)
	back.pressed.connect(func(): closed.emit())
	var bw := CenterContainer.new()
	bw.add_child(back)
	v.add_child(bw)

	visible = false


func show_how_to() -> void:
	_mode = Mode.HOW_TO
	_title.text = "HOW TO PLAY"
	_body.text = """[center][b]Bilis! Bilis![/b]

Survive as many dumb Pinoy situations as you can.

• Each minigame is [b]short[/b] — act fast!
• Follow the prompt on screen
• Don't lose all your [color=#4DA6FF]bean lives[/color]
• Chain wins for [color=#E06A20]combos[/color]

[b]Controls[/b]
Keyboard and mouse
[ESC] Pause during a run[/center]"""
	_open()


func show_credits() -> void:
	_mode = Mode.CREDITS
	_title.text = "CREDITS"
	_body.text = """[center][b]Minigames & Logic[/b]
Reuter Jan Camacho
Pixel Iris Sibal

[b]UI/UX[/b]
Jason Temporado

[b]Graphics & Assets[/b]
Pixel Iris Sibal
Judd Bragais
Johanna Paulene Campos

[b]Other Contributing Members[/b]
Alphonso Clarence Carandang
Chariz Bialen
Joel Angelo Baldapan[/center]"""
	_open()


func _open() -> void:
	visible = true
	_panel.scale = Vector2(0.5, 0.5)
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0
	var tw := create_tween()
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func exit() -> void:
	visible = false
