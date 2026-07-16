extends Node2D

signal game_finished(result: String)

enum State { WAITING, SHOWING, CUTTING, WON, LOST }
var state = State.WAITING
const WIRE_SCENE = preload("res://minigames/cut-the-jumper-wires/wire.tscn")

@export var target_wire_count: int = 3
@export var trap_wire_count: int = 8
@export var trap_colors: Array[Color] = [Color.BLUE, Color.YELLOW, Color.GREEN, Color.PURPLE, Color.ORANGE]

@export var target_wire_texture: Texture2D          
@export var trap_wire_textures: Array[Texture2D] = [] 

@export var memorize_duration: float = 2.5
@export var base_duration: float = 8.0
@export var base_target_wires: int = 3
var speed: float = 1.0
var time_remaining: float = 0.0
var difficulty_level: int = 0
var active_game_duration: float = 8.0  # Tracks the scaled timer for the active level

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
	"Ran out of time dithering around!"
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

func set_difficulty(level: int) -> void:
	difficulty_level = clampi(level, 0, 100)  # Uncapped to allow infinite scaling!

	# Rule 1: EVERY ROUND, make the time shorter
	# Subtracts 0.75 seconds per level. Floor at 3.0s so it stays playable.
	active_game_duration = max(base_duration - (difficulty_level * 0.75), 3.0)

	# Rule 2: EVERY 3 ROUNDS, add 1 wire to be cut
	# Level 0, 1, 2 = +0 | Level 3, 4, 5 = +1 | Level 6, 7, 8 = +2, etc.
	var extra_wires := difficulty_level / 3
	target_wire_count = base_target_wires + extra_wires

	# Prevent spawning more target wires than screen space allows
	target_wire_count = min(target_wire_count, 8)

	# Keep scaling up trap wires slightly so they don't get drowned out by target wires
	trap_wire_count = min(8 + (difficulty_level * 1), 16)

var _ui_layer: CanvasLayer
var _message_label: Label
var _hint_label: Label
var _flash_rect: ColorRect
var _timer_bar: TextureProgressBar

func _ready():
	# TextureRect under Node2D does not get a layout size (anchors are ignored),
	# so the wires background never appears. Rebuild it as a fitted Sprite2D.
	_setup_background()
	_center_camera()
	_build_ui()
	generate_wires()
	start_sequence()


func _setup_background() -> void:
	# Free immediately so the new node can reuse the WireBG name this frame.
	var existing := get_node_or_null("WireBG")
	if existing:
		remove_child(existing)
		existing.free()
	var path := "res://assets/wires-assets/wires_bg.png"
	if not ResourceLoader.exists(path):
		push_warning("Wire minigame: missing background %s" % path)
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		push_warning("Wire minigame: failed to load background texture")
		return
	var bg := Sprite2D.new()
	bg.name = "WireBG"
	bg.texture = tex
	bg.centered = false
	bg.z_index = -100
	var vs := get_viewport_rect().size
	if vs.x < 2.0 or vs.y < 2.0:
		vs = Vector2(1280, 720)
	var tex_size := tex.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		bg.scale = Vector2(vs.x / tex_size.x, vs.y / tex_size.y)
	add_child(bg)
	move_child(bg, 0)


func _center_camera() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	var vs := get_viewport_rect().size
	if vs.x < 2.0 or vs.y < 2.0:
		vs = Vector2(1280, 720)
	cam.position = vs * 0.5
	cam.make_current()


func _process(delta: float):
	if state == State.CUTTING:
		time_remaining -= delta
		
		# Update visual timer bar using active dynamically scaled game duration
		if _timer_bar:
			_timer_bar.value = (time_remaining / active_game_duration) * 100.0
			
		# Time out check
		if time_remaining <= 0.0:
			time_remaining = 0.0
			print("Time's up!")
			lose()

# --- Runtime UI (no .tscn edits needed) ---
func _build_ui():
	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 0, 0, 0)
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_flash_rect)

	# Visual Countdown Timer Bar
	_timer_bar = TextureProgressBar.new()
	_timer_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_timer_bar.offset_top = 20
	_timer_bar.offset_left = 100
	_timer_bar.offset_right = -100
	_timer_bar.offset_bottom = 40
	_timer_bar.nine_patch_stretch = true
	_timer_bar.value = 100
	_timer_bar.tint_progress = Color(0.2, 0.8, 0.2) # Starts green
	
	# Fallback colored textures for the bar
	var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex = ImageTexture.create_from_image(img)
	_timer_bar.texture_progress = tex
	
	var bg_img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	bg_img.fill(Color(0.1, 0.1, 0.1, 0.6))
	_timer_bar.texture_under = ImageTexture.create_from_image(bg_img)
	
	_timer_bar.visible = false
	_ui_layer.add_child(_timer_bar)

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

func random_edge_points(screen_size: Vector2) -> Array:
	var edges = [0, 1, 2, 3]
	edges.shuffle()
	var point_a = random_point_on_edge(edges[0], screen_size)
	var point_b = random_point_on_edge(edges[1], screen_size)
	return [point_a, point_b]

func random_point_on_edge(edge: int, screen_size: Vector2) -> Vector2:
	match edge:
		0: return Vector2(randf_range(0, screen_size.x), 0)                 
		1: return Vector2(randf_range(0, screen_size.x), screen_size.y)     
		2: return Vector2(0, randf_range(0, screen_size.y))                 
		3: return Vector2(screen_size.x, randf_range(0, screen_size.y))     
	return Vector2.ZERO

func start_sequence():
	state = State.WAITING
	_message_label.text = ""
	_hint_label.text = ""
	_timer_bar.visible = false
	
	for w in wires:
		w.hide_color()

	# Fixed quick delay before colors blink on screen
	await get_tree().create_timer(0.5).timeout

	state = State.SHOWING
	for w in wires:
		w.show_color()

	# Uses customizable memorize_duration so players can learn the layout
	await get_tree().create_timer(memorize_duration).timeout

	for w in wires:
		w.hide_color()
	print("Color gone. Cut the RED wires!")

	# Start countdown timer phase using the dynamically scaled round time
	time_remaining = active_game_duration
	_timer_bar.visible = true
	state = State.CUTTING

func _unhandled_input(event):
	if state == State.WON or state == State.LOST:
		return
		
	if state != State.CUTTING:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_click(get_global_mouse_position())

func handle_click(mouse_pos: Vector2):
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
	_timer_bar.visible = false
	print("ALL RED WIRES CUT — YOU WIN!")
	var msg = win_messages[randi() % win_messages.size()] if win_messages.size() > 0 else "YOU WIN!"
	_show_end_message(msg, Color(0.3, 1.0, 0.3))
	game_finished.emit("win")

func lose():
	AudioController.play_eshock()
	state = State.LOST
	_timer_bar.visible = false
	var msg = death_messages[randi() % death_messages.size()] if death_messages.size() > 0 else "ZZZAP!"
	print("ZZZAP! Wrong wire — electrocuted! ", msg)
	_show_end_message(msg, Color(1.0, 0.3, 0.3))
	_flash_screen()
	_shake_camera()
	game_finished.emit("lose")

func _show_end_message(msg: String, color: Color):
	_message_label.text = msg
	_message_label.add_theme_color_override("font_color", color)
	_message_label.scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(_message_label, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_message_label, "scale", Vector2.ONE, 0.1)

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
