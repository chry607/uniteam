extends Node2D
class_name RoadLane

enum LaneType { SAFE, ROAD, RAIL }

const LANE_HALF_WIDTH := 700.0

var lane_type: int = LaneType.SAFE
var row := 0
var speed := 0.0
var direction := 1
var spawn_timer := 0.0
var spawn_interval := 1.6
var vehicle_types: Array = []

var rail_state := "idle"  # idle, warning, train, cooldown
var warning_timer := 0.0
var train_hazard: Area2D = null

const TILE_SIZE := 100

func _ready() -> void:
	# FIX: Position lanes upwards (negative Y) matching player coordinate movements
	position.y = -row * TILE_SIZE
	if lane_type == LaneType.RAIL:
		warning_timer = randf_range(2.0, 5.0)
	queue_redraw()

func _process(delta: float) -> void:
	match lane_type:
		LaneType.ROAD:
			spawn_timer -= delta
			if spawn_timer <= 0.0:
				_spawn_vehicle()
				
				# --- NEW ANTI-OVERLAP LOGIC ---
				# 150px for the longest vehicle (Jeepney) + 100px for the player = 250px gap required.
				# Time = Distance / Speed
				var min_safe_time: float = 250.0 / speed
				
				# We add the minimum safe time + a little random variance so it isn't robotic
				spawn_timer = min_safe_time + randf_range(0.2, 1.2)
				
		LaneType.RAIL:
			_process_rail(delta)

func _spawn_vehicle() -> void:
	var vehicle_script = preload("res://minigames/crossy-road/scripts/Vehicle.gd")
	var v = vehicle_script.new()
	v.vehicle_type = vehicle_types[randi() % vehicle_types.size()]
	v.speed = speed
	v.direction = direction
	v.lane_width = LANE_HALF_WIDTH + 100
	v.position = Vector2(-LANE_HALF_WIDTH * direction, 0)
	add_child(v)

func _process_rail(delta: float) -> void:
	warning_timer -= delta
	if warning_timer <= 0.0:
		match rail_state:
			"idle":
				rail_state = "warning"
				warning_timer = 1.4
			"warning":
				rail_state = "train"
				warning_timer = 0.4
				_spawn_train_hazard()
			"train":
				rail_state = "cooldown"
				warning_timer = randf_range(3.0, 6.0)
				if train_hazard:
					train_hazard.queue_free()
					train_hazard = null
			"cooldown":
				rail_state = "idle"
				warning_timer = randf_range(2.5, 4.5)
	queue_redraw()

func _spawn_train_hazard() -> void:
	train_hazard = Area2D.new()
	train_hazard.add_to_group("hazard")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1600, 90)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	train_hazard.add_child(cs)
	train_hazard.monitoring = true
	train_hazard.monitorable = true
	add_child(train_hazard)

func _draw() -> void:
	match lane_type:
		LaneType.SAFE:
			# --- DYNAMIC FIX: Ask the main scene where the finish line is ---
			var final_row := 10
			if get_parent() and "target_row" in get_parent():
				final_row = get_parent().target_row
				
			if row == final_row:
				# Draw a fun "Dumb Ways to Die" checkered finish line!
				draw_rect(Rect2(-800, -50, 1600, 100), Color8(255, 215, 0)) # Gold base
				var x := -750
				while x < 800:
					draw_rect(Rect2(x, -50, 50, 50), Color8(255, 255, 255))
					draw_rect(Rect2(x + 50, -50, 50, 50), Color8(0, 0, 0))
					draw_rect(Rect2(x, 0, 50, 50), Color8(0, 0, 0))
					draw_rect(Rect2(x + 50, 0, 50, 50), Color8(255, 255, 255))
					x += 100
			else:
				draw_rect(Rect2(-800, -50, 1600, 100), Color8(120, 190, 110))
				
		LaneType.ROAD:
			# Draws the dark grey road base
			draw_rect(Rect2(-800, -50, 1600, 100), Color8(70, 70, 75))
			var x := -750
			# Draws the yellow dashed lines!
			while x < 800:
				draw_rect(Rect2(x, -4, 50, 8), Color8(230, 200, 60))
				x += 100
				
		LaneType.RAIL:
			# Draws the dirt/gravel base
			draw_rect(Rect2(-800, -50, 1600, 100), Color8(150, 130, 90))
			# Draws the iron rails
			draw_rect(Rect2(-800, -8, 1600, 16), Color8(90, 90, 90))
			if rail_state == "warning":
				if int(warning_timer * 6) % 2 == 0:
					draw_circle(Vector2(0, -40), 14, Color8(255, 40, 40))
			elif rail_state == "train":
				draw_rect(Rect2(-800, -35, 1600, 70), Color8(230, 30, 30))
