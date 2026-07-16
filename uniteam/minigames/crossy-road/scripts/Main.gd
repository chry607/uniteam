extends Node2D

signal game_finished(result: String)

const TILE_SIZE := 100

var lanes := {}
var game_over := false
var won := false

# Game rule constants
var time_left := 20.0 # 12 seconds to survive/finish
const TARGET_ROW := 10

var player
var camera: Camera2D
var camera_target := Vector2.ZERO

# UI Elements
var timer_label: Label
var lanes_label: Label
var game_over_panel: Control
var final_message_label: Label

func _ready() -> void:
	AudioController.play_road_bg()
	randomize()
	_build_ui()
	_setup_camera()
	_spawn_player()
	
	# Pre-generate lanes from row -2 (buffer behind player) up to 12 (buffer past finish line)
	for i in range(-2, 13):
		_generate_lane(i)

func _process(delta: float) -> void:
	if game_over or won:
		return
		
	# Handle countdown timer
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_on_time_out()
	_update_ui()

	# --- STRICTLY VERTICAL CAMERA TRACKING ---
	if camera and player:
		# 150px deadzone: Player can move up/down slightly without camera moving immediately
		var deadzone := 150.0 
		var target_y := camera.position.y
		
		if player.position.y < camera.position.y - deadzone:
			target_y = player.position.y + deadzone
		elif player.position.y > camera.position.y + deadzone:
			target_y = player.position.y - deadzone
			
		# Keep camera from looking too far past start (100) or finish line (-1050)
		target_y = clamp(target_y, -1050, 100)
		
		# Smoothly follow Y, but lock X to 0 (NO sideways scrolling!)
		camera.position.y = lerp(camera.position.y, target_y, 0.1)
		camera.position.x = 0

# ---------- UI ----------

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	# Top bar for Timer (Centered)
	timer_label = Label.new()
	timer_label.text = "TIME: 12.00s"
	timer_label.add_theme_font_size_override("font_size", 44)
	timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timer_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	timer_label.position = Vector2(-150, 20)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(timer_label)

	# Lanes tracker (Top Left)
	lanes_label = Label.new()
	lanes_label.text = "Lanes: 0 / 10"
	lanes_label.add_theme_font_size_override("font_size", 28)
	lanes_label.position = Vector2(30, 20)
	canvas.add_child(lanes_label)

	# Game Over / Win Panel
	game_over_panel = Control.new()
	game_over_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_panel.visible = false
	canvas.add_child(game_over_panel)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color8(47, 207, 183, 230) # Cute pastel teal
	game_over_panel.add_child(bg)

	final_message_label = Label.new()
	final_message_label.text = "Dumb Way to Die"
	final_message_label.add_theme_font_size_override("font_size", 48)
	final_message_label.set_anchors_preset(Control.PRESET_CENTER)
	final_message_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	final_message_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	final_message_label.position = Vector2(-250, -80)
	final_message_label.size = Vector2(500, 100)
	final_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_panel.add_child(final_message_label)

	var restart_btn := Button.new()
	restart_btn.text = "Try Again"
	restart_btn.add_theme_font_size_override("font_size", 24)
	restart_btn.set_anchors_preset(Control.PRESET_CENTER)
	restart_btn.position = Vector2(-100, 40)
	restart_btn.size = Vector2(200, 50)
	game_over_panel.add_child(restart_btn)

func _update_ui() -> void:
	timer_label.text = "TIME: %.2fs" % time_left
	if time_left < 4.0:
		timer_label.add_theme_color_override("font_color", Color8(255, 60, 60)) # Red text warning
	else:
		timer_label.add_theme_color_override("font_color", Color8(255, 255, 255))

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.zoom = Vector2(0.9, 0.9)
	add_child(camera)
	camera.make_current()

func _spawn_player() -> void:
	var player_script = preload("res://minigames/crossy-road/scripts/Player.gd")
	player = player_script.new()
	player.moved.connect(_on_player_moved)
	player.died.connect(_on_player_died)
	add_child(player)
	player.position = Vector2.ZERO

# ---------- Lane generation ----------

func _generate_lane(row: int) -> void:
	if lanes.has(row):
		return
	var lane_script = preload("res://minigames/crossy-road/scripts/Lane.gd")
	var lane := lane_script.new()
	lane.row = row
	
	# Start and end lanes are strictly SAFE.
	if row <= 0 or row >= TARGET_ROW:
		lane.lane_type = 0
	else:
		var roll := randf()
		if roll < 0.15:
			lane.lane_type = 0
		elif roll < 0.30:
			lane.lane_type = 2
		else:
			lane.lane_type = 1
			lane.direction = 1 if randi() % 2 == 0 else -1
			lane.speed = randf_range(130, 280) 
			lane.spawn_interval = randf_range(0.8, 1.6)
			lane.vehicle_types = [0, 1, 2, 3]
	add_child(lane)
	lanes[row] = lane

# ---------- Signals & Game States ----------

func _on_player_moved(row: int) -> void:
	if won or game_over:
		return
		
	lanes_label.text = "Lanes: %d / 10" % clampi(row, 0, TARGET_ROW)
	
	if row >= TARGET_ROW:
		# Wait for the exact duration of the player's movement animation
		await get_tree().create_timer(player.MOVE_TIME).timeout
		
		# Make sure they didn't die while landing on the tile!
		if not game_over:
			_on_player_won()

func _on_player_died() -> void:
	if game_over or won:
		return
	game_over = true
	AudioController.stop_road_bg()
	game_finished.emit("lose") # Tell the manager you died. NO PAUSING!

func _on_time_out() -> void:
	if game_over or won:
		return
	game_over = true
	AudioController.stop_road_bg()
	game_finished.emit("lose")

func _on_player_won() -> void:
	if won or game_over:
		return
	won = true
	AudioController.stop_road_bg()
	game_finished.emit("win")

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
