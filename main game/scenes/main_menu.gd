class_name MainMenu
extends Control
## Large centered layout: title, START GAME, secondary buttons, living neighborhood.

signal play_pressed
signal settings_pressed
signal credits_pressed
signal how_to_play_pressed
signal quit_pressed

var _street: FilipinoStreet
var _title_box: VBoxContainer
var _play_btn: GameButton
var _buttons: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_street = FilipinoStreet.new()
	_street.busy = true
	_street.show_characters = true
	add_child(_street)

	# Top-left icon buttons (Options / How to)
	var top_left := HBoxContainer.new()
	top_left.add_theme_constant_override("separation", 16)
	top_left.position = Vector2(36, 28)
	add_child(top_left)

	var opt := _icon_button("⚙", "OPTIONS", "options", func(): settings_pressed.emit())
	top_left.add_child(opt)

	var how := _icon_button("?", "HOW TO PLAY", "how", func(): how_to_play_pressed.emit())
	top_left.add_child(how)

	# Top-right score chip
	var top_right := PanelContainer.new()
	top_right.add_theme_stylebox_override("panel", StyleFactory.hud_chip())
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.anchor_left = 1.0
	top_right.anchor_right = 1.0
	top_right.offset_left = -200
	top_right.offset_right = -36
	top_right.offset_top = 28
	top_right.offset_bottom = 88
	add_child(top_right)
	var best_lbl := Label.new()
	best_lbl.name = "BestLabel"
	best_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(best_lbl, 24, Palette.TEXT_DARK)
	best_lbl.text = "★  %d" % ScoreManager.best_score
	top_right.add_child(best_lbl)
	ScoreManager.best_score_changed.connect(func(b): best_lbl.text = "★  %d" % b)

	# Center column
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.anchor_left = 0.5
	center.anchor_right = 0.5
	center.anchor_top = 0.5
	center.anchor_bottom = 0.5
	center.offset_left = -360
	center.offset_right = 360
	center.offset_top = -320
	center.offset_bottom = 320
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 18)
	add_child(center)

	_title_box = VBoxContainer.new()
	_title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_title_box.add_theme_constant_override("separation", -5)
	center.add_child(_title_box)

	var title := Label.new()
	title.text = "Difficulty Level: Pinoy"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	FontRegistry.apply_display(title, 56, Palette.CREAM, true)
	_title_box.add_child(title)

	# Spacer
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 24)
	center.add_child(sp)

	_play_btn = GameButton.new()
	_play_btn.text = "  START GAME  ▶  "
	_play_btn.button_id = "play"
	_play_btn.variant = GameButton.Style.PRIMARY
	_play_btn.base_font_size = 48
	_play_btn.custom_minimum_size = Vector2(420, 96)
	_play_btn.pressed.connect(func(): play_pressed.emit())
	var play_wrap := CenterContainer.new()
	play_wrap.add_child(_play_btn)
	center.add_child(play_wrap)

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 16)
	center.add_child(_buttons)

	_buttons.add_child(_small_btn("SETTINGS", "settings", func(): settings_pressed.emit()))
	_buttons.add_child(_small_btn("CREDITS", "credits", func(): credits_pressed.emit()))
	_buttons.add_child(_small_btn("HOW TO PLAY", "howto", func(): how_to_play_pressed.emit()))
	_buttons.add_child(_small_btn("QUIT", "quit", func(): quit_pressed.emit(), GameButton.Style.SECONDARY))

	visible = false


func _icon_button(icon: String, caption: String, id: String, cb: Callable) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.custom_minimum_size = Vector2(96, 0)
	var btn := GameButton.new()
	btn.text = icon
	btn.button_id = id
	btn.variant = GameButton.Style.GHOST
	btn.base_font_size = 28
	btn.custom_minimum_size = Vector2(72, 72)
	btn.pressed.connect(cb)
	box.add_child(btn)
	var cap := Label.new()
	cap.text = caption
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD
	cap.custom_minimum_size = Vector2(96, 0)
	FontRegistry.apply_ui(cap, 12, Palette.WHITE, true)
	box.add_child(cap)
	return box


func _small_btn(text: String, id: String, cb: Callable, variant: int = GameButton.Style.SECONDARY) -> GameButton:
	var b := GameButton.new()
	b.text = text
	b.button_id = id
	b.variant = variant
	b.base_font_size = 20
	b.custom_minimum_size = Vector2(160, 56)
	b.pressed.connect(cb)
	return b


func enter() -> void:
	visible = true
	modulate.a = 1.0
	_street._viewport_size = get_viewport_rect().size
	var best: Label = find_child("BestLabel", true, false)
	if best:
		best.text = "★  %d" % ScoreManager.best_score
	_title_box.scale = Vector2(0.6, 0.6)
	_title_box.modulate.a = 0.0
	_play_btn.scale = Vector2(0.5, 0.5)
	_play_btn.modulate.a = 0.0
	await get_tree().process_frame
	_title_box.pivot_offset = _title_box.size / 2.0
	_play_btn.pivot_offset = _play_btn.size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_title_box, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_title_box, "modulate:a", 1.0, 0.2)
	tw.tween_property(_play_btn, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.1)
	tw.tween_property(_play_btn, "modulate:a", 1.0, 0.2).set_delay(0.1)
	# Idle bounce on play
	await tw.finished
	_idle_bounce()


func _idle_bounce() -> void:
	while visible:
		var tw := create_tween()
		tw.tween_property(_play_btn, "scale", Vector2(1.04, 1.04), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_play_btn, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tw.finished


func exit() -> void:
	visible = false
