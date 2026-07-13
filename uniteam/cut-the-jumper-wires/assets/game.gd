extends Node2D

enum State { WAITING, SHOWING, CUTTING, WON, LOST }
var state = State.WAITING
const WIRE_SCENE = preload("res://assets/wire.tscn")

@export var target_wire_count: int = 3
@export var trap_wire_count: int = 8
@export var trap_colors: Array[Color] = [Color.BLUE, Color.YELLOW, Color.GREEN, Color.PURPLE, Color.ORANGE]

# NEW: art assignment — assign these in the Inspector on game.tscn
@export var target_wire_texture: Texture2D          # the RED wire sprite
@export var trap_wire_textures: Array[Texture2D] = [] # MUST be same length & order as trap_colors

var wires: Array = []
var target_wires_remaining: int = 0

func _ready():
	generate_wires()
	start_sequence()

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

func lose():
	state = State.LOST
	print("ZZZAP! Wrong wire — electrocuted!")
