class_name GameButton
extends Button
## Chunky, pressable cartoon button with bounce + sound hooks.

enum Style { PRIMARY, SECONDARY, DANGER, GHOST }

@export var button_id: String = ""
@export var variant: Style = Style.PRIMARY
@export var base_font_size: int = 36
@export var enable_bounce: bool = true

var _base_scale := Vector2.ONE
var _hovering := false


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_styles()
	FontRegistry.apply_button(self, base_font_size)
	pivot_offset = size / 2.0
	resized.connect(_on_resized)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	pressed.connect(_on_pressed)
	# Ensure pivot after first layout
	call_deferred("_on_resized")


func _on_resized() -> void:
	pivot_offset = size / 2.0


func _apply_styles() -> void:
	var normal_bg: Color
	var hover_bg: Color
	var press_bg: Color
	match variant:
		Style.PRIMARY:
			normal_bg = Palette.YELLOW_BUTTON
			hover_bg = Palette.YELLOW_BUTTON_HOVER
			press_bg = Palette.YELLOW_BUTTON_PRESS
		Style.SECONDARY:
			normal_bg = Palette.CREAM
			hover_bg = Palette.CREAM_DARK
			press_bg = Color("E0D2B0")
		Style.DANGER:
			normal_bg = Palette.ORANGE
			hover_bg = Color("FF9F5A")
			press_bg = Palette.ORANGE_DEEP
		Style.GHOST:
			normal_bg = Color(1, 1, 1, 0.75)
			hover_bg = Color(1, 1, 1, 0.9)
			press_bg = Color(0.95, 0.95, 0.95, 0.85)
	add_theme_stylebox_override("normal", StyleFactory.button_normal(normal_bg))
	add_theme_stylebox_override("hover", StyleFactory.button_hover(hover_bg))
	add_theme_stylebox_override("pressed", StyleFactory.button_pressed(press_bg))
	add_theme_stylebox_override("focus", StyleFactory.button_hover(hover_bg))
	add_theme_stylebox_override("disabled", StyleFactory.button_normal(Color(0.7, 0.7, 0.7)))


func set_variant(v: Style) -> void:
	variant = v
	_apply_styles()


func _on_hover() -> void:
	_hovering = true
	AudioEvents.emit_button_hover(button_id if button_id else text)
	if enable_bounce:
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_unhover() -> void:
	_hovering = false
	if enable_bounce:
		var tw := create_tween()
		tw.tween_property(self, "scale", _base_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_down() -> void:
	if enable_bounce:
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(0.94, 0.94), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_up() -> void:
	if enable_bounce:
		var target := Vector2(1.06, 1.06) if _hovering else _base_scale
		var tw := create_tween()
		tw.tween_property(self, "scale", target, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_pressed() -> void:
	AudioEvents.emit_button_click(button_id if button_id else text)
