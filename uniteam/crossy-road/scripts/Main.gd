extends Node2D

const TILE_SIZE := 100

var lanes := {}
var game_over := false
var won := false

# Game rule constants
var time_left := 20.0 # 12 seconds to survive/finish
const TARGET_ROW := 10

var player: PlayerPawn
var camera: Camera2D
var camera_target := Vector2.ZERO

# UI Elements
var timer_label: Label
var lanes_label: Label
var game_over_panel: Control
var final_message_label: Label

func _ready() -> void:
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
	restart_btn.pressed.connect(_on_restart_pressed)
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
	# Notice we removed all the camera margin properties here!

func _spawn_player() -> void:
	player = PlayerPawn.new()
	player.moved.connect(_on_player_moved)
	player.died.connect(_on_player_died)
	add_child(player)
	player.position = Vector2.ZERO
	# DO NOT add the camera as a child of the player!
# ---------- Lane generation ----------

func _generate_lane(row: int) -> void:
	if lanes.has(row):
		return
	var lane := RoadLane.new()
	lane.row = row
	
	# Start and end lanes are strictly SAFE.
	if row <= 0 or row >= TARGET_ROW:
		lane.lane_type = RoadLane.LaneType.SAFE
	else:
		var roll := randf()
		if roll < 0.15:
			lane.lane_type = RoadLane.LaneType.SAFE
		elif roll < 0.30:
			lane.lane_type = RoadLane.LaneType.RAIL
		else:
			lane.lane_type = RoadLane.LaneType.ROAD
			lane.direction = 1 if randi() % 2 == 0 else -1
			lane.speed = randf_range(130, 280) # Speed updated for higher tension
			lane.spawn_interval = randf_range(0.8, 1.6)
			lane.vehicle_types = [
				RoadVehicle.VehicleType.JEEPNEY,
				RoadVehicle.VehicleType.TRICYCLE,
				RoadVehicle.VehicleType.MULTICAB,
				RoadVehicle.VehicleType.MOTORCYCLE
			]
	add_child(lane)
	lanes[row] = lane

# ---------- Signals & Game States ----------

func _on_player_moved(row: int) -> void:
	if won or game_over:
		return
		
	lanes_label.text = "Lanes: %d / 10" % clampi(row, 0, TARGET_ROW)
	
	if row >= TARGET_ROW:
		_on_player_won()

func _on_player_died() -> void:
	if game_over or won:
		return
	game_over = true
	final_message_label.text = "Dumb Way to Die!\nYou were flattened!"
	
	# Color background Coral Red on death
	var bg = game_over_panel.get_child(0) as ColorRect
	if bg:
		bg.color = Color8(255, 107, 107, 230)
		
	game_over_panel.visible = true
	get_tree().paused = true

func _on_time_out() -> void:
	if game_over or won:
		return
	game_over = true
	final_message_label.text = "Dumb Way to Die!\nTime ran out!"
	
	var bg = game_over_panel.get_child(0) as ColorRect
	if bg:
		bg.color = Color8(255, 107, 107, 230)
		
	game_over_panel.visible = true
	get_tree().paused = true

func _on_player_won() -> void:
	won = true
	final_message_label.text = "Dumb Victory!\nYou Survived!"
	
	var bg = game_over_panel.get_child(0) as ColorRect
	if bg:
		bg.color = Color8(47, 207, 183, 230) # Pastel Teal
		
	game_over_panel.visible = true
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
