class_name NotificationToast
extends Control
## Comic-style toast that slides in from the top.

var _label: Label
var _panel: PanelContainer
var _queue: Array[Dictionary] = []
var _busy := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	offset_bottom = 120
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", StyleFactory.panel(Palette.YELLOW, Palette.OUTLINE, 5, 20, true))
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_panel)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(_label, 28, Palette.TEXT_DARK, false)
	_label.text = ""
	_panel.add_child(_label)

	_panel.modulate.a = 0.0
	UIManager.notification_requested.connect(show_message)


func show_message(message: String, duration: float = 1.6) -> void:
	_queue.append({"msg": message, "dur": duration})
	if not _busy:
		_process_queue()


func _process_queue() -> void:
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	var item: Dictionary = _queue.pop_front()
	_label.text = str(item.msg)
	_panel.position.y = -80
	_panel.modulate.a = 1.0
	_panel.scale = Vector2(0.8, 0.8)
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "position:y", 16.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	await get_tree().create_timer(float(item.dur)).timeout

	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(_panel, "position:y", -100.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw2.tween_property(_panel, "modulate:a", 0.0, 0.2)
	await tw2.finished
	_process_queue()
