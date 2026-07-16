class_name PlaceholderMinigame
extends Control
## Colorful placeholder panel. HUD still runs; success/fail handled by GameState timer.

var _panel: PanelContainer
var _title: Label
var _hint: Label
var _progress: ProgressBar
var _color_idx := 0
var _elapsed := 0.0
var _active := false

const COLORS: Array[Color] = [
	Color("FF6B6B"),
	Color("4ECDC4"),
	Color("FFE66D"),
	Color("95E1D3"),
	Color("F38181"),
	Color("AA96DA"),
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = COLORS[0]
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Decorative circles
	var deco := DecoDraw.new()
	deco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(deco)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", StyleFactory.panel(Palette.CREAM, Palette.OUTLINE, 8, 28, true))
	_panel.custom_minimum_size = Vector2(700, 360)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 36)
	_panel.add_child(margin)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	margin.add_child(v)

	var header := Label.new()
	header.text = "MINIGAME GOES HERE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_display(header, 40, Palette.TEXT_DARK, true)
	v.add_child(header)

	_title = Label.new()
	_title.text = "(Placeholder)"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(_title, 32, Palette.ORANGE_DEEP, true)
	v.add_child(_title)

	_hint = Label.new()
	_hint.text = "Demo auto-plays — drop real minigames later!"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(_hint, 20, Palette.OUTLINE_SOFT)
	v.add_child(_hint)

	_progress = ProgressBar.new()
	_progress.custom_minimum_size = Vector2(400, 28)
	_progress.max_value = 1.0
	_progress.value = 0.0
	_progress.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Palette.TEAL
	fill.set_corner_radius_all(10)
	var bg_s := StyleBoxFlat.new()
	bg_s.bg_color = Palette.CREAM_DARK
	bg_s.set_corner_radius_all(10)
	bg_s.set_border_width_all(3)
	bg_s.border_color = Palette.OUTLINE
	_progress.add_theme_stylebox_override("fill", fill)
	_progress.add_theme_stylebox_override("background", bg_s)
	v.add_child(_progress)

	var tip := Label.new()
	tip.text = "Press ESC / Start to pause"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(tip, 18, Palette.TEXT_DARK)
	v.add_child(tip)

	visible = false


func enter(minigame_name: String, duration: float) -> void:
	visible = true
	_title.text = minigame_name
	_color_idx = randi() % COLORS.size()
	(get_node("BG") as ColorRect).color = COLORS[_color_idx]
	_elapsed = 0.0
	_progress.max_value = duration
	_progress.value = 0.0
	_active = true
	_panel.scale = Vector2(0.7, 0.7)
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0
	var tw := create_tween()
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func exit() -> void:
	_active = false
	visible = false


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	_progress.value = _elapsed
	# Subtle panel wiggle
	_panel.rotation = sin(Time.get_ticks_msec() * 0.005) * 0.015


class DecoDraw extends Control:
	func _draw() -> void:
		for i in 12:
			var p := Vector2(fmod(i * 197.0, size.x), fmod(i * 131.0, size.y))
			draw_circle(p, 20 + i * 3, Color(1, 1, 1, 0.08))
