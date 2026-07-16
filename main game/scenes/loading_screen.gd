class_name LoadingScreen
extends Control
## Full-screen loading with rotating jeepney wheel.

signal finished

var _spinner: LoadingSpinner
var _label: Label
var _progress: ProgressBar


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Palette.SKY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 20)
	center.add_child(v)

	var title := Label.new()
	title.text = "Sandali…"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_display(title, 48, Palette.TEXT_DARK, true)
	v.add_child(title)

	_spinner = LoadingSpinner.new()
	_spinner.custom_minimum_size = Vector2(140, 140)
	var sw := CenterContainer.new()
	sw.add_child(_spinner)
	v.add_child(sw)

	_label = Label.new()
	_label.text = "Loading the barangay…"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(_label, 22, Palette.TEXT_DARK)
	v.add_child(_label)

	_progress = ProgressBar.new()
	_progress.custom_minimum_size = Vector2(360, 24)
	_progress.max_value = 1.0
	_progress.value = 0.0
	_progress.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Palette.YELLOW_BUTTON
	fill.set_corner_radius_all(10)
	fill.set_border_width_all(3)
	fill.border_color = Palette.OUTLINE
	var pbg := StyleBoxFlat.new()
	pbg.bg_color = Palette.CREAM
	pbg.set_corner_radius_all(10)
	pbg.set_border_width_all(3)
	pbg.border_color = Palette.OUTLINE
	_progress.add_theme_stylebox_override("fill", fill)
	_progress.add_theme_stylebox_override("background", pbg)
	v.add_child(_progress)

	visible = false


func play(duration: float = 1.2, message: String = "Loading the barangay…") -> void:
	visible = true
	_label.text = message
	_progress.value = 0.0
	var tw := create_tween()
	tw.tween_property(_progress, "value", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	visible = false
	finished.emit()
