class_name TimerDisplay
extends Control
## Huge countdown timer — green → yellow → red, shakes on final second.

signal finished

var _label: Label
var _seconds: float = 0.0
var _running: bool = false
var _last_int: int = -1
var _base_pos: Vector2


func _ready() -> void:
	custom_minimum_size = Vector2(120, 100)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	FontRegistry.apply_display(_label, 72, Palette.TIMER_GREEN, true)
	_label.text = ""
	add_child(_label)
	_base_pos = position


func start(seconds: float) -> void:
	_seconds = seconds
	_running = true
	_last_int = -1
	visible = true
	_update_visual()


func stop() -> void:
	_running = false


func hide_timer() -> void:
	_running = false
	_label.text = ""


func _process(delta: float) -> void:
	if not _running:
		return
	_seconds = maxf(0.0, _seconds - delta)
	var cur := int(ceil(_seconds))
	if cur != _last_int:
		_last_int = cur
		_update_visual()
		if cur > 0:
			AudioEvents.emit_timer_tick(cur)
		if cur == 1:
			AudioEvents.emit_timer_urgent()
			_shake()
	if _seconds <= 0.0:
		_running = false
		_label.text = "0"
		finished.emit()


func _update_visual() -> void:
	var n := maxi(0, int(ceil(_seconds)))
	_label.text = str(n) if n > 0 else "0"
	var col: Color
	if _seconds > 2.0:
		col = Palette.TIMER_GREEN
	elif _seconds > 1.0:
		col = Palette.TIMER_YELLOW
	else:
		col = Palette.TIMER_RED
	_label.add_theme_color_override("font_color", col)
	# Pulse
	_label.pivot_offset = _label.size / 2.0
	var tw := create_tween()
	tw.tween_property(_label, "scale", Vector2(1.2, 1.2), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _shake() -> void:
	if UIManager and not UIManager.screen_shake_enabled:
		return
	var origin := position
	var tw := create_tween()
	for _i in 8:
		tw.tween_property(self, "position", origin + Vector2(randf_range(-8, 8), randf_range(-6, 6)), 0.04)
	tw.tween_property(self, "position", origin, 0.05)


## Show GO! flash
func show_go() -> void:
	_running = false
	_label.text = "GO!"
	_label.add_theme_color_override("font_color", Palette.YELLOW)
	_label.scale = Vector2(0.3, 0.3)
	_label.pivot_offset = _label.size / 2.0
	var tw := create_tween()
	tw.tween_property(_label, "scale", Vector2(1.4, 1.4), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label, "scale", Vector2.ONE, 0.1)
	await tw.finished
