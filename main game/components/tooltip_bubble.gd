class_name TooltipBubble
extends Control
## Speech-bubble tooltip.

var _label: Label
var _panel: PanelContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", StyleFactory.panel(Palette.WHITE, Palette.OUTLINE, 4, 16, true))
	add_child(_panel)

	_label = Label.new()
	FontRegistry.apply_ui(_label, 20, Palette.TEXT_DARK)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(160, 0)
	_panel.add_child(_label)


func show_at(global_pos: Vector2, text: String) -> void:
	_label.text = text
	global_position = global_pos + Vector2(12, -48)
	visible = true
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0
	pivot_offset = size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.1)


func hide_bubble() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.1)
	await tw.finished
	visible = false
