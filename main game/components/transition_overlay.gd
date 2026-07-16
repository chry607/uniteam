class_name TransitionOverlay
extends CanvasLayer
## Fast WarioWare-style transition: TV static + warning phrase + optional countdown feel.

signal finished

var _root: Control
var _static_rect: ColorRect
var _phrase: Label
var _noise_img: Image
var _noise_tex: ImageTexture
var _running := false


func _ready() -> void:
	layer = 40
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_static_rect = ColorRect.new()
	_static_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_static_rect.color = Color.BLACK
	_root.add_child(_static_rect)

	# Noise texture overlay via draw node
	var noise := NoiseDraw.new()
	noise.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	noise.name = "Noise"
	_root.add_child(noise)

	_phrase = Label.new()
	_phrase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phrase.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_phrase.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_phrase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FontRegistry.apply_display(_phrase, 72, Palette.YELLOW, true)
	_phrase.text = "Failed round\n3 lives remaining"
	_root.add_child(_phrase)

	visible = false
	set_process(false)


func play(phrase: String = "") -> void:
	if phrase == "":
		phrase = GameState.get_transition_message() if GameState.has_method("get_transition_message") else GameState.get_random_transition_phrase()
	_phrase.text = phrase
	# Slightly smaller type when two lines so both stay readable.
	var line_count := phrase.split("\n").size()
	FontRegistry.apply_display(_phrase, 64 if line_count > 1 else 72, Palette.YELLOW, true)
	visible = true
	_running = true
	set_process(true)
	AudioEvents.emit_transition_start(phrase)
	AudioEvents.emit_warning(phrase)

	_phrase.scale = Vector2(0.2, 2.2)  # stretch
	_phrase.pivot_offset = _phrase.size / 2.0
	_phrase.modulate = Color.WHITE
	await get_tree().process_frame
	_phrase.pivot_offset = _phrase.size / 2.0

	# Squash / stretch entrance
	var tw := create_tween()
	tw.tween_property(_phrase, "scale", Vector2(1.3, 0.7), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_phrase, "scale", Vector2(0.9, 1.15), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_phrase, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished

	# Hold with wiggle
	var hold := 0.35 + randf() * 0.25
	var t0 := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - t0) / 1000.0 < hold:
		_phrase.rotation = sin(Time.get_ticks_msec() * 0.03) * 0.08
		await get_tree().process_frame
	_phrase.rotation = 0.0

	# Exit stretch
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(_phrase, "scale", Vector2(2.0, 0.2), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw2.tween_property(_phrase, "modulate:a", 0.0, 0.12)
	await tw2.finished

	_running = false
	set_process(false)
	visible = false
	AudioEvents.emit_transition_end()
	finished.emit()


func _process(_delta: float) -> void:
	if _running:
		var noise: NoiseDraw = _root.get_node("Noise")
		noise.queue_redraw()


class NoiseDraw extends Control:
	func _draw() -> void:
		# Random static bars — cheap comic TV static
		for i in 40:
			var y := randf() * size.y
			var h := randf_range(1.0, 6.0)
			var a := randf_range(0.05, 0.35)
			var col := Color(1, 1, 1, a) if randf() > 0.5 else Color(0, 0, 0, a)
			draw_rect(Rect2(0, y, size.x, h), col)
		for i in 80:
			var p := Vector2(randf() * size.x, randf() * size.y)
			draw_rect(Rect2(p, Vector2(3, 3)), Color(1, 1, 1, randf() * 0.5))
