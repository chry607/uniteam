class_name LoadingSpinner
extends Control
## Cute rotating jeepney wheel spinner.

@export var radius: float = 36.0
@export var spin_speed: float = 3.5

var _angle: float = 0.0
var _label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(radius * 3, radius * 3.5)
	_label = Label.new()
	_label.text = "Loading…"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(_label, 22, Palette.TEXT_DARK)
	_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_label.offset_top = -28
	add_child(_label)


func _process(delta: float) -> void:
	_angle += delta * spin_speed
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0 - Vector2(0, 12)
	var r := radius
	# Tire
	draw_circle(c, r, Palette.OUTLINE)
	draw_circle(c, r * 0.82, Color("2A2A2A"))
	draw_circle(c, r * 0.45, Color("C0C0C0"))
	draw_circle(c, r * 0.22, Palette.YELLOW)
	# Spokes
	for i in 6:
		var a := _angle + i * TAU / 6.0
		var p1 := c + Vector2(cos(a), sin(a)) * (r * 0.25)
		var p2 := c + Vector2(cos(a), sin(a)) * (r * 0.72)
		draw_line(p1, p2, Palette.OUTLINE, 4.0, true)
	# Hub cap
	draw_circle(c, r * 0.12, Palette.OUTLINE)
