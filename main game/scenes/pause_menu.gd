class_name PauseMenu
extends Control
## Dark overlay pause with Resume / Restart / Main Menu / Settings.

signal resume_pressed
signal restart_pressed
signal main_menu_pressed
signal settings_pressed

var _overlay: ColorRect
var _panel: PanelContainer
var _open := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = ColorRect.new()
	_overlay.color = Palette.OVERLAY_DARK
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", StyleFactory.modal_panel())
	_panel.custom_minimum_size = Vector2(480, 420)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(v)

	var title := Label.new()
	title.text = "PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_display(title, 64, Palette.TEXT_DARK, true)
	v.add_child(title)

	var sub := Label.new()
	sub.text = "Sandali lang…"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(sub, 22, Palette.OUTLINE_SOFT)
	v.add_child(sub)

	v.add_child(_btn("RESUME", "resume", func(): resume_pressed.emit(), GameButton.Style.PRIMARY))
	v.add_child(_btn("RESTART", "restart", func(): restart_pressed.emit(), GameButton.Style.SECONDARY))
	v.add_child(_btn("SETTINGS", "pause_settings", func(): settings_pressed.emit(), GameButton.Style.SECONDARY))
	v.add_child(_btn("MAIN MENU", "pause_menu", func(): main_menu_pressed.emit(), GameButton.Style.DANGER))

	visible = false


func _btn(text: String, id: String, cb: Callable, variant: int) -> GameButton:
	var b := GameButton.new()
	b.text = text
	b.button_id = id
	b.variant = variant
	b.base_font_size = 28
	b.custom_minimum_size = Vector2(320, 64)
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.pressed.connect(cb)
	return b


func open_menu() -> void:
	visible = true
	_open = true
	get_tree().paused = true
	_overlay.modulate.a = 0.0
	_panel.scale = Vector2(0.5, 0.5)
	_panel.modulate.a = 0.0
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)
	AudioEvents.emit_menu_open("pause")


func close_menu() -> void:
	if not _open:
		return
	_open = false
	get_tree().paused = false
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 0.0, 0.12)
	tw.tween_property(_panel, "scale", Vector2(0.7, 0.7), 0.15)
	await tw.finished
	visible = false
	AudioEvents.emit_menu_close("pause")
