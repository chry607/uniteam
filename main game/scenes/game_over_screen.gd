class_name GameOverScreen
extends Control
## Comic game-over card with dead bean, score, retry / menu.

signal retry_pressed
signal main_menu_pressed
signal results_pressed

var _overlay: ColorRect
var _card: PanelContainer
var _score_label: Label
var _best_label: Label
var _bean: DeadBeanDraw


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_overlay = ColorRect.new()
	_overlay.color = Color(0.08, 0.1, 0.14, 0.78)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", StyleFactory.panel(Palette.CREAM, Palette.OUTLINE, 7, 36, true))
	_card.custom_minimum_size = Vector2(560, 560)
	center.add_child(_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_card.add_child(margin)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	margin.add_child(v)

	var title := Label.new()
	title.text = "Game over"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_display(title, 56, Palette.HEART_RED, true)
	v.add_child(title)

	var sub := Label.new()
	sub.text = "You're out of lives."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(sub, 24, Palette.OUTLINE_SOFT)
	v.add_child(sub)

	_bean = DeadBeanDraw.new()
	_bean.custom_minimum_size = Vector2(140, 140)
	var bean_wrap := CenterContainer.new()
	bean_wrap.add_child(_bean)
	v.add_child(bean_wrap)

	var score_title := Label.new()
	score_title.text = "SCORE"
	score_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(score_title, 20, Palette.TEXT_DARK)
	v.add_child(score_title)

	_score_label = Label.new()
	_score_label.text = "0"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_display(_score_label, 72, Palette.TEXT_DARK, true)
	v.add_child(_score_label)

	_best_label = Label.new()
	_best_label.text = "Best: 0"
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(_best_label, 22, Palette.ORANGE_DEEP)
	v.add_child(_best_label)

	var retry := GameButton.new()
	retry.text = "  RETRY  "
	retry.button_id = "retry"
	retry.variant = GameButton.Style.PRIMARY
	retry.base_font_size = 32
	retry.custom_minimum_size = Vector2(280, 72)
	retry.pressed.connect(func(): retry_pressed.emit())
	var rw := CenterContainer.new()
	rw.add_child(retry)
	v.add_child(rw)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)

	var results := GameButton.new()
	results.text = "RESULTS"
	results.button_id = "to_results"
	results.variant = GameButton.Style.SECONDARY
	results.base_font_size = 20
	results.custom_minimum_size = Vector2(160, 52)
	results.pressed.connect(func(): results_pressed.emit())
	row.add_child(results)

	var menu := GameButton.new()
	menu.text = "MAIN MENU"
	menu.button_id = "go_menu"
	menu.variant = GameButton.Style.SECONDARY
	menu.base_font_size = 20
	menu.custom_minimum_size = Vector2(160, 52)
	menu.pressed.connect(func(): main_menu_pressed.emit())
	row.add_child(menu)

	visible = false


func enter() -> void:
	visible = true
	_score_label.text = str(ScoreManager.score)
	_best_label.text = "Best: %d" % ScoreManager.best_score
	_overlay.modulate.a = 0.0
	_card.scale = Vector2(0.4, 0.4)
	_card.modulate.a = 0.0
	await get_tree().process_frame
	_card.pivot_offset = _card.size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.2)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "modulate:a", 1.0, 0.15)
	_bean.wiggle = true


func exit() -> void:
	_bean.wiggle = false
	visible = false


class DeadBeanDraw extends Control:
	var wiggle := false
	var _t := 0.0

	func _process(delta: float) -> void:
		if wiggle:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var c := size / 2.0 + Vector2(sin(_t * 3.0) * 3.0, 0)
		draw_circle(c + Vector2(0, 8), 48, Palette.OUTLINE)
		draw_circle(c + Vector2(0, 6), 44, Palette.BLUE_BEAN)
		# X eyes
		draw_line(c + Vector2(-18, -8), c + Vector2(-6, 4), Palette.OUTLINE, 5.0)
		draw_line(c + Vector2(-18, 4), c + Vector2(-6, -8), Palette.OUTLINE, 5.0)
		draw_line(c + Vector2(6, -8), c + Vector2(18, 4), Palette.OUTLINE, 5.0)
		draw_line(c + Vector2(6, 4), c + Vector2(18, -8), Palette.OUTLINE, 5.0)
		# Tongue
		draw_circle(c + Vector2(8, 22), 10, Palette.OUTLINE)
		draw_circle(c + Vector2(8, 22), 8, Palette.PINK_BEAN)
		# Halo
		draw_arc(c + Vector2(0, -52), 18, 0, TAU, 24, Palette.YELLOW, 4.0, true)
