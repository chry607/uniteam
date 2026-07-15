extends Node2D

signal game_finished(result: String)

enum State { WAITING, SHOWING, CUTTING, WON, LOST }
var state = State.WAITING
const WIRE_SCENE = preload("res://cut-the-jumper-wires/assets/wire.tscn")

@export var target_wire_count: int = 3
@export var trap_wire_count: int = 8
@export var trap_colors: Array[Color] = [Color.BLUE, Color.YELLOW, Color.GREEN, Color.PURPLE, Color.ORANGE]

# NEW: art assignment — assign these in the Inspector on game.tscn
@export var target_wire_texture: Texture2D          # the RED wire sprite
@export var trap_wire_textures: Array[Texture2D] = [] # MUST be same length & order as trap_colors

# --- "Dumb Ways to Die" style flavor text ---
@export var death_messages: Array[String] = [
	"Snipped the blue one for fun.",
	"Decided yellow looked tastier.",
	"Went for the purple wire on a dare.",
	"Trusted a coin flip over the color.",
	"Cut the wire that sparkled the most.",
	"Confused 'green' with 'go'.",
	"Panicked and grabbed the nearest one.",
	"Never did like the color orange.",	
	"Assumed the countdown was decorative.",
	"Forgot which wire was red. Whoops.",
	"Pulled the wire marked 'DO NOT PULL'.",
	"Figured they were all the same really.",
]
@export var win_messages: Array[String] = [
	"Somehow didn't die today!",
	"Every red wire accounted for. Nice work.",
	"Defused! Go treat yourself.",
	"Not-dumb way to survive: achieved.",
	"Lived to cut wires another day.",
]

var wires: Array = []
var target_wires_remaining: int = 0

var _ui_layer: CanvasLayer
var _message_label: Label
var _hint_label: Label
var _flash_rect: ColorRect

func _ready():
	_build_ui()
	generate_wires()
	start_sequence()

# --- Runtime UI (no .tscn edits needed) ---
func _build_ui():
	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 0, 0, 0)
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_flash_rect)

	_message_label = Label.new()
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.anchor_left = 0.5
	_message_label.anchor_right = 0.5
	_message_label.anchor_top = 0.5
	_message_label.anchor_bottom = 0.5
	_message_label.offset_left = -400
	_message_label.offset_right = 400
	_message_label.offset_top = -60
	_message_label.offset_bottom = 60
	_message_label.pivot_offset = Vector2(400, 60)
	_message_label.add_theme_font_size_override("font_size", 42)
	_message_label.add_theme_color_override("font_color", Color.WHITE)
	_message_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_message_label.add_theme_constant_override("outline_size", 6)
	_message_label.text = ""
	_message_label.scale = Vector2.ZERO
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_message_label)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.anchor_left = 0.5
	_hint_label.anchor_right = 0.5
	_hint_label.anchor_top = 0.5
	_hint_label.anchor_bottom = 0.5
	_hint_label.offset_left = -300
	_hint_label.offset_right = 300
	_hint_label.offset_top = 40
	_hint_label.offset_bottom = 80
	_hint_label.add_theme_font_size_override("font_size", 20)
	_hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_hint_label.text = ""
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_hint_label)

func generate_wires():
	var screen_size = get_viewport_rect().size
	for i in range(target_wire_count):
		wires.append(spawn_wire(screen_size, Color.RED, true, target_wire_texture))
	for i in range(trap_wire_count):
		var idx = randi() % trap_colors.size()
		var color = trap_colors[idx]
		var tex = trap_wire_textures[idx] if idx < trap_wire_textures.size() else null
		wires.append(spawn_wire(screen_size, color, false, tex))
	target_wires_remaining = target_wire_count

func spawn_wire(screen_size: Vector2, color: Color, is_target: bool, texture: Texture2D) -> Node2D:
	var wire = WIRE_SCENE.instantiate()
	add_child(wire)
	var points = random_edge_points(screen_size)
	wire.setup(points[0], points[1], color, is_target, texture)
	return wire

# Picks 2 points on 2 DIFFERENT screen edges (top/bottom/left/right)
func random_edge_points(screen_size: Vector2) -> Array:
	var edges = [0, 1, 2, 3]
	edges.shuffle()
	var point_a = random_point_on_edge(edges[0], screen_size)
	var point_b = random_point_on_edge(edges[1], screen_size)
	return [point_a, point_b]

func random_point_on_edge(edge: int, screen_size: Vector2) -> Vector2:
	match edge:
		0: return Vector2(randf_range(0, screen_size.x), 0)                # top
		1: return Vector2(randf_range(0, screen_size.x), screen_size.y)    # bottom
		2: return Vector2(0, randf_range(0, screen_size.y))                # left
		3: return Vector2(screen_size.x, randf_range(0, screen_size.y))    # right
	return Vector2.ZERO

func start_sequence():
	state = State.WAITING
	_message_label.text = ""
	_hint_label.text = ""
	for w in wires:
		w.hide_color()
	await get_tree().create_timer(2).timeout

	state = State.SHOWING
	for w in wires:
		w.show_color()
	await get_tree().create_timer(2).timeout

	for w in wires:
		w.hide_color()
	print("Color gone. Cut the RED wires!")
	state = State.CUTTING

func _unhandled_input(event):
	# REMOVED the reload_current_scene() logic here!
	if state == State.WON or state == State.LOST:
		return # Do nothing, the Game Manager is handling the transition now.
		
	if state != State.CUTTING:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_click(get_global_mouse_position())

func handle_click(mouse_pos: Vector2):
	# Find the closest un-severed wire within tolerance
	var best_wire = null
	var best_distance = INF

	for w in wires:
		if w.severed:
			continue
		var p = w.project(mouse_pos)
		if p.distance < w.hit_tolerance and p.distance < best_distance:
			best_distance = p.distance
			best_wire = w

	if best_wire == null:
		return  # clicked empty space — no penalty

	var result = best_wire.try_cut(mouse_pos)
	match result:
		"trap":
			lose()
		"cut":
			print("Nicked a red wire — cut it again elsewhere on it!")
		"too_close":
			print("Too close to your first cut on that wire!")
		"severed":
			target_wires_remaining -= 1
			print("Red wire severed! Remaining: ", target_wires_remaining)
			if target_wires_remaining <= 0:
				win()

func win():
	state = State.WON
	print("ALL RED WIRES CUT — YOU WIN!")
	var msg = win_messages[randi() % win_messages.size()] if win_messages.size() > 0 else "YOU WIN!"
	_show_end_message(msg, Color(0.3, 1.0, 0.3))
	game_finished.emit("win")

func lose():
	state = State.LOST
	var msg = death_messages[randi() % death_messages.size()] if death_messages.size() > 0 else "ZZZAP!"
	print("ZZZAP! Wrong wire — electrocuted! ", msg)
	_show_end_message(msg, Color(1.0, 0.3, 0.3))
	_flash_screen()
	_shake_camera()
	game_finished.emit("lose")

# --- "Dumb Ways to Die" flourishes ---
func _show_end_message(msg: String, color: Color):
	_message_label.text = msg
	_message_label.add_theme_color_override("font_color", color)
	_message_label.scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(_message_label, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_message_label, "scale", Vector2.ONE, 0.1)
	_hint_label.text = "Click to try again"

func _flash_screen():
	_flash_rect.color = Color(1, 0, 0, 0.6)
	var tw = create_tween()
	tw.tween_property(_flash_rect, "color:a", 0.0, 0.5)

func _shake_camera():
	var cam = get_node_or_null("Camera2D")
	if cam == null:
		return
	var original_pos = cam.position
	var tw = create_tween()
	for i in range(6):
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		tw.tween_property(cam, "position", original_pos + offset, 0.03)
	tw.tween_property(cam, "position", original_pos, 0.03)
