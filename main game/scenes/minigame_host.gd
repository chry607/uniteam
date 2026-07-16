class_name MinigameHost
extends Control
## Hosts real minigames in a fixed design-resolution SubViewport, then scales
## that viewport to fit the shell (letterboxed). Game content sizes stay the same;
## only the presentation layer scales.

signal completed(success: bool)

## Original Uniteam / LRT layout size (16:9). Matches hardcoded LRT coords.
const DESIGN_SIZE := Vector2i(1280, 720)

var _letterbox: ColorRect
var _container: SubViewportContainer
var _viewport: SubViewport
var _current: Node = null
var _finished := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	# Fill unused edges when window aspect ≠ design aspect
	_letterbox = ColorRect.new()
	_letterbox.color = Color(0.04, 0.05, 0.07)
	_letterbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_letterbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_letterbox)

	# stretch=false: keep SubViewport at DESIGN_SIZE pixels, scale the container Control
	_container = SubViewportContainer.new()
	_container.stretch = false
	_container.mouse_filter = Control.MOUSE_FILTER_STOP
	_container.focus_mode = Control.FOCUS_NONE
	add_child(_container)

	_viewport = SubViewport.new()
	_viewport.name = "MinigameViewport"
	_viewport.size = DESIGN_SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.handle_input_locally = true
	_viewport.physics_object_picking = true
	_viewport.audio_listener_enable_2d = true
	_viewport.gui_disable_input = false
	_viewport.transparent_bg = false
	_container.add_child(_viewport)

	resized.connect(_fit_to_rect)
	# In case size is ready next frame
	call_deferred("_fit_to_rect")


func is_running() -> bool:
	return _current != null and not _finished


func start(entry: Dictionary) -> void:
	clear()
	_finished = false
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	var packed: PackedScene = MinigameRegistry.load_scene(entry)
	if packed == null:
		push_error("MinigameHost: could not load minigame, treating as fail")
		_emit_completed(false)
		return

	_current = packed.instantiate()
	_current.name = "ActiveMinigame"
	_current.process_mode = Node.PROCESS_MODE_PAUSABLE

	# Apply difficulty before enter-tree/_ready so lane counts, wire counts, etc. scale.
	if _current.has_method("set_difficulty"):
		var level := MinigameRegistry.get_difficulty_for_entry(entry)
		_current.call("set_difficulty", level)

	if _current.has_signal("game_finished"):
		_current.game_finished.connect(_on_game_finished)
	else:
		push_warning("MinigameHost: scene has no game_finished signal: %s" % entry.get("id", "?"))

	_viewport.add_child(_current)
	_fit_to_rect()
	# Layout can settle after first frame (parent Control size, stretch)
	await get_tree().process_frame
	_fit_to_rect()


func clear() -> void:
	if _current != null and is_instance_valid(_current):
		if _current.has_signal("game_finished") and _current.game_finished.is_connected(_on_game_finished):
			_current.game_finished.disconnect(_on_game_finished)
		_current.queue_free()
	_current = null
	_finished = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	AudioController.stop_all_minigame_sfx()


## Scale the design-resolution viewport to fill this host while keeping aspect ratio.
func _fit_to_rect() -> void:
	if _container == null or _viewport == null:
		return

	var area := size
	if area.x < 2.0 or area.y < 2.0:
		# Fall back to root viewport if we aren't laid out yet
		area = get_viewport().get_visible_rect().size
	if area.x < 2.0 or area.y < 2.0:
		return

	var design := Vector2(DESIGN_SIZE)
	_viewport.size = DESIGN_SIZE

	var scale_f := minf(area.x / design.x, area.y / design.y)
	# Avoid zero / NaN
	scale_f = maxf(scale_f, 0.01)

	var fitted := design * scale_f
	# Logical size stays at design pixels; Control.scale upscales the texture + input
	_container.size = design
	_container.scale = Vector2(scale_f, scale_f)
	_container.position = (area - fitted) * 0.5
	_container.pivot_offset = Vector2.ZERO


func _on_game_finished(result: String) -> void:
	if _finished:
		return
	_finished = true
	var success := result == "win"
	clear()
	_emit_completed(success)


func _emit_completed(success: bool) -> void:
	completed.emit(success)
