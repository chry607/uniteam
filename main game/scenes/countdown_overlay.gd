class_name CountdownOverlay
extends CanvasLayer
## 3-2-1-GO before each minigame.

signal finished

var _root: Control
var _label: Label
var _subtitle: Label


func _ready() -> void:
	layer = 30
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_subtitle.anchor_left = 0.1
	_subtitle.anchor_right = 0.9
	_subtitle.anchor_top = 0.22
	_subtitle.anchor_bottom = 0.22
	_subtitle.offset_top = 0
	_subtitle.offset_bottom = 90
	FontRegistry.apply_ui(_subtitle, 32, Palette.WHITE, true)
	_root.add_child(_subtitle)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	FontRegistry.apply_display(_label, 180, Palette.YELLOW, true)
	_root.add_child(_label)

	visible = false


func play(minigame_name: String = "") -> void:
	visible = true
	_subtitle.text = minigame_name if minigame_name != "" else GameState.pending_minigame_name
	var steps := ["3", "2", "1", "GO!"]
	var colors := [Palette.TIMER_GREEN, Palette.TIMER_YELLOW, Palette.TIMER_RED, Palette.YELLOW]
	for i in steps.size():
		_label.text = steps[i]
		_label.add_theme_color_override("font_color", colors[i])
		_label.scale = Vector2(0.2, 0.2)
		_label.modulate.a = 1.0
		await get_tree().process_frame
		_label.pivot_offset = _label.size / 2.0
		var n := 3 - i if i < 3 else 0
		if i < 3:
			AudioEvents.emit_countdown(n)
		var tw := create_tween()
		if steps[i] == "GO!":
			tw.tween_property(_label, "scale", Vector2(1.5, 1.5), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(_label, "scale", Vector2(1.1, 1.1), 0.1)
		else:
			# Squash stretch
			tw.tween_property(_label, "scale", Vector2(1.4, 0.7), 0.08)
			tw.tween_property(_label, "scale", Vector2(0.85, 1.25), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(_label, "scale", Vector2.ONE, 0.1)
		await tw.finished
		await get_tree().create_timer(0.18 if i < 3 else 0.12).timeout

	var fade := create_tween()
	fade.tween_property(_label, "modulate:a", 0.0, 0.12)
	await fade.finished
	visible = false
	finished.emit()
