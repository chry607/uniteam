class_name GameModal
extends Control
## Centered cartoon modal with dark overlay and pop-in animation.

signal closed

@export var close_on_overlay_click: bool = false
@export var title_text: String = ""

var _overlay: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _body: VBoxContainer
var _open := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_overlay = ColorRect.new()
	_overlay.color = Palette.OVERLAY_DARK
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if close_on_overlay_click:
		_overlay.gui_input.connect(_on_overlay_input)
	add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", StyleFactory.modal_panel())
	_panel.custom_minimum_size = Vector2(520, 280)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(margin)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 18)
	_body.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(_body)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_title(_title_label, 48, Palette.TEXT_DARK, true)
	_title_label.text = title_text
	_body.add_child(_title_label)


func get_body() -> VBoxContainer:
	return _body


func set_title(t: String) -> void:
	title_text = t
	if _title_label:
		_title_label.text = t


func open_modal() -> void:
	visible = true
	_open = true
	_overlay.modulate.a = 0.0
	_panel.scale = Vector2(0.5, 0.5)
	_panel.modulate.a = 0.0
	_panel.pivot_offset = _panel.size / 2.0
	# Wait a frame for size
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)
	AudioEvents.emit_ui_pop()


func close_modal() -> void:
	if not _open:
		return
	_open = false
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 0.0, 0.12)
	tw.tween_property(_panel, "scale", Vector2(0.7, 0.7), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.12)
	await tw.finished
	visible = false
	closed.emit()


func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_modal()
