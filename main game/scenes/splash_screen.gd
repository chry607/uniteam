class_name SplashScreen
extends Control
## Animated logo + busy street + Press Any Key.

signal finished

var _street: FilipinoStreet
var _logo: VBoxContainer
var _press: Label
var _ready_input := false
var _logo_scale_base := Vector2.ONE


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_street = FilipinoStreet.new()
	_street.busy = true
	_street.show_characters = true
	add_child(_street)

	# Dim vignette for readability
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.25)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_logo = VBoxContainer.new()
	_logo.alignment = BoxContainer.ALIGNMENT_CENTER
	_logo.add_theme_constant_override("separation", 0)
	center.add_child(_logo)

	var title := Label.new()
	title.text = "Difficulty Level: Pinoy"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_display(title, 64, Palette.CREAM, true)
	_logo.add_child(title)

	_press = Label.new()
	_press.text = "PRESS ANY KEY"
	_press.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(_press, 28, Palette.WHITE, true)
	_press.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_press.anchor_top = 1.0
	_press.anchor_bottom = 1.0
	_press.offset_top = -100
	_press.offset_bottom = -50
	_press.anchor_left = 0.0
	_press.anchor_right = 1.0
	add_child(_press)

	visible = false


func enter() -> void:
	visible = true
	_ready_input = false
	_street._viewport_size = get_viewport_rect().size
	_logo.scale = Vector2(0.3, 0.3)
	_logo.modulate.a = 0.0
	await get_tree().process_frame
	_logo.pivot_offset = _logo.size / 2.0
	# Center pivot properly
	_logo.position = _logo.position  # no-op ensure
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_logo, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_logo, "modulate:a", 1.0, 0.25)
	await tw.finished
	_ready_input = true
	_blink_press()


func exit() -> void:
	_ready_input = false
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	visible = false
	modulate.a = 1.0


func _blink_press() -> void:
	while visible and _ready_input:
		var tw := create_tween()
		tw.tween_property(_press, "modulate:a", 0.25, 0.55)
		tw.tween_property(_press, "modulate:a", 1.0, 0.55)
		await tw.finished


func _input(event: InputEvent) -> void:
	if not visible or not _ready_input:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_consume()
	elif event is InputEventMouseButton and event.pressed:
		_consume()
	elif event is InputEventJoypadButton and event.pressed:
		_consume()


func _consume() -> void:
	_ready_input = false
	AudioEvents.emit_button_click("splash_continue")
	finished.emit()
