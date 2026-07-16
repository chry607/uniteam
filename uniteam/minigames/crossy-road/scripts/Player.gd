extends Area2D
class_name PlayerPawn

signal moved(row: int)
signal died

const TILE_SIZE := 100
const MOVE_TIME := 0.12
const MIN_COL := -7 # Increased so you can walk to the very left edge
const MAX_COL := 7  # Increased so you can walk to the very right edge

var grid_x := 0
var grid_y := 0
var is_moving := false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	z_index = 10
	monitoring = true
	monitorable = true
	_build_visual()

func _build_visual() -> void:
	var body := ColorRect.new()
	body.size = Vector2(56, 64)
	body.position = Vector2(-28, -32)
	body.color = Color8(255, 220, 80)
	add_child(body)

	var hat := ColorRect.new()
	hat.size = Vector2(66, 16)
	hat.position = Vector2(-33, -40)
	hat.color = Color8(50, 120, 200)
	add_child(hat)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(50, 56)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

func _unhandled_input(event: InputEvent) -> void:
	if is_moving:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		AudioController.play_lrt_move()
		match event.keycode:
			KEY_UP, KEY_W:
				_try_move(0, -1)
			KEY_DOWN, KEY_S:
				_try_move(0, 1)
			KEY_LEFT, KEY_A:
				_try_move(-1, 0)
			KEY_RIGHT, KEY_D:
				_try_move(1, 0)

func _try_move(dx: int, dy: int) -> void:
	# Clamps strictly prevent the player from walking off the left/right screen edges
	var new_x: int = clamp(grid_x + dx, MIN_COL, MAX_COL)
	
	# Clamps strictly prevent the player from walking past Start (0) or Finish (-10)
	var new_y: int = clamp(grid_y + dy, -10, 0) 
	
	if new_x == grid_x and new_y == grid_y:
		return
		
	grid_x = new_x
	grid_y = new_y
	is_moving = true
	var target := Vector2(grid_x * TILE_SIZE, grid_y * TILE_SIZE)
	var tw := create_tween()
	tw.tween_property(self, "position", target, MOVE_TIME).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): is_moving = false)
	moved.emit(-grid_y)
	
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("hazard"):
		AudioController.play_crash()
		died.emit()
