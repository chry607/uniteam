class_name ResultsScreen
extends Control
## Final stats: score, combo, survival, games cleared, fun lines.

signal replay_pressed
signal main_menu_pressed

var _card: PanelContainer
var _stats_box: VBoxContainer
var _fun_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Palette.SKY_DEEP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Simple decorative street strip
	var street := FilipinoStreet.new()
	street.busy = true
	street.show_characters = false
	street.modulate = Color(1, 1, 1, 0.45)
	add_child(street)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", StyleFactory.modal_panel())
	_card.custom_minimum_size = Vector2(640, 620)
	center.add_child(_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	_card.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(v)

	var title := Label.new()
	title.text = "RESULTS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_display(title, 56, Palette.TEXT_DARK, true)
	v.add_child(title)

	_stats_box = VBoxContainer.new()
	_stats_box.add_theme_constant_override("separation", 8)
	v.add_child(_stats_box)

	_fun_box = VBoxContainer.new()
	_fun_box.add_theme_constant_override("separation", 4)
	v.add_child(_fun_box)

	var replay := GameButton.new()
	replay.text = "  REPLAY!  "
	replay.button_id = "replay"
	replay.variant = GameButton.Style.PRIMARY
	replay.base_font_size = 36
	replay.custom_minimum_size = Vector2(320, 80)
	replay.pressed.connect(func(): replay_pressed.emit())
	var rw := CenterContainer.new()
	rw.add_child(replay)
	v.add_child(rw)

	var menu := GameButton.new()
	menu.text = "MAIN MENU"
	menu.button_id = "results_menu"
	menu.variant = GameButton.Style.SECONDARY
	menu.base_font_size = 22
	menu.custom_minimum_size = Vector2(220, 56)
	menu.pressed.connect(func(): main_menu_pressed.emit())
	var mw := CenterContainer.new()
	mw.add_child(menu)
	v.add_child(mw)

	visible = false


func enter() -> void:
	visible = true
	_refresh()
	_card.scale = Vector2(0.5, 0.5)
	_card.modulate.a = 0.0
	await get_tree().process_frame
	_card.pivot_offset = _card.size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "modulate:a", 1.0, 0.15)


func exit() -> void:
	visible = false


func _refresh() -> void:
	for c in _stats_box.get_children():
		c.queue_free()
	for c in _fun_box.get_children():
		c.queue_free()

	_add_stat("Final Score", str(ScoreManager.score))
	_add_stat("Highest Combo", "x%d" % ScoreManager.highest_combo)
	_add_stat("Longest Survival", "%.1fs" % ScoreManager.survival_seconds)
	_add_stat("Games Cleared", str(ScoreManager.games_cleared))
	_add_stat("Deaths", str(ScoreManager.deaths))

	var sep := HSeparator.new()
	_fun_box.add_child(sep)
	for line in ScoreManager.get_fun_stat_lines():
		var l := Label.new()
		l.text = "• " + line
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		FontRegistry.apply_ui(l, 20, Palette.OUTLINE_SOFT)
		_fun_box.add_child(l)


func _add_stat(name: String, value: String) -> void:
	var row := HBoxContainer.new()
	var n := Label.new()
	n.text = name
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	FontRegistry.apply_ui(n, 24, Palette.TEXT_DARK)
	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	FontRegistry.apply_ui(val, 28, Palette.ORANGE_DEEP, true)
	row.add_child(n)
	row.add_child(val)
	_stats_box.add_child(row)
