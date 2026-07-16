class_name ScoreCounter
extends VBoxContainer
## Score display with count-up and combo popup.

var _title: Label
var _value: Label
var _combo: Label
var _displayed: int = 0
var _target: int = 0


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 0)

	_title = Label.new()
	_title.text = "SCORE"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(_title, 16, Palette.TEXT_DARK)
	add_child(_title)

	_value = Label.new()
	_value.text = "0"
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_display(_value, 40, Palette.TEXT_DARK, true)
	add_child(_value)

	_combo = Label.new()
	_combo.text = ""
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo.modulate.a = 0.0
	FontRegistry.apply_ui(_combo, 22, Palette.ORANGE_DEEP, true)
	add_child(_combo)

	ScoreManager.score_changed.connect(_on_score)
	ScoreManager.combo_changed.connect(_on_combo)
	_on_score(ScoreManager.score, 0)


func _on_score(new_score: int, _delta: int) -> void:
	_target = new_score
	var tw := create_tween()
	tw.tween_method(_set_display, _displayed, _target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Punch
	_value.pivot_offset = _value.size / 2.0
	var punch := create_tween()
	punch.tween_property(_value, "scale", Vector2(1.25, 1.25), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	punch.tween_property(_value, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_display(v: float) -> void:
	_displayed = int(round(v))
	_value.text = str(_displayed)


func _on_combo(combo: int) -> void:
	if combo < 2:
		return
	_combo.text = "x%d COMBO!" % combo
	_combo.modulate.a = 1.0
	_combo.scale = Vector2(0.5, 0.5)
	_combo.pivot_offset = _combo.size / 2.0
	var tw := create_tween()
	tw.tween_property(_combo, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_combo, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(0.5)
	tw.tween_property(_combo, "modulate:a", 0.0, 0.25)
