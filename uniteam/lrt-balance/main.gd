extends Node2D

signal game_finished(result: String)

# --- Game Tuning Settings ---
var max_balance: float = 100.0
var min_balance: float = 0.0
var recovery_force: float = 12.0     
var passive_drift: float = 10.0      
var jerk_strength: float = 16.0

# --- Game Variables ---
var balance: float = 50.0
var train_jerk_force: float = 0.0
var is_game_over: bool = false
var is_won: bool = false

# --- Component References ---
var environment
var player
var ui
var survival_timer: Timer
var jerk_timer: Timer

func _ready() -> void:
	# 1. Instantiate Components (Pure Code, No Drag and Drop)
	var environment_script = preload("res://lrt-balance/environment.gd")
	environment = environment_script.new()
	add_child(environment)
	
	var player_script = preload("res://lrt-balance/player.gd")
	player = player_script.new()
	add_child(player)
	
	var ui_script = preload("res://lrt-balance/ui.gd")
	ui = ui_script.new()
	add_child(ui)
	
	# 2. Setup Timers
	survival_timer = Timer.new()
	survival_timer.wait_time = 10.0
	survival_timer.one_shot = true
	survival_timer.timeout.connect(_on_survival_timer_timeout)
	add_child(survival_timer)
	survival_timer.start()
	
	jerk_timer = Timer.new()
	jerk_timer.timeout.connect(_on_train_jerk_timer_timeout)
	add_child(jerk_timer)
	start_next_jerk()
	
	# 3. Initialize Game State & UI
	ui.setup_meter(min_balance, max_balance, balance)
	ui.tap_left.connect(_on_input_left)
	ui.tap_right.connect(_on_input_right)


func _process(delta: float) -> void:
	if is_game_over or is_won: return

	# Physics & Forces Logic
	train_jerk_force = move_toward(train_jerk_force, 0.0, delta * 20.0)
	var center_offset: float = balance - 50.0
	var gravity_pull: float = (center_offset / 50.0) * passive_drift

	balance += (train_jerk_force + gravity_pull) * delta * 5.0
	balance = clamp(balance, min_balance, max_balance)

	# Update Components
	ui.update_display(balance, survival_timer.time_left)
	player.update_lean(balance)

	# Win/Lose Check
	if balance <= min_balance or balance >= max_balance:
		trigger_game_over()


# --- INPUT HANDLING ---
func _unhandled_input(event: InputEvent) -> void:
	if is_game_over or is_won: return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_LEFT:
			_on_input_left()
		elif event.keycode == KEY_RIGHT:
			_on_input_right()

func _on_input_left() -> void:
	if is_game_over or is_won: return
	balance -= recovery_force
	player.squish_juice()

func _on_input_right() -> void:
	if is_game_over or is_won: return
	balance += recovery_force
	player.squish_juice()


# --- GAME EVENTS ---
func trigger_game_over() -> void:
	if is_game_over or is_won:
		return
	is_game_over = true
	survival_timer.stop()
	jerk_timer.stop()
	
	ui.show_game_over()
	player.fall_over(balance)
	game_finished.emit("lose")

func _on_survival_timer_timeout() -> void:
	if is_game_over: return
	is_won = true
	jerk_timer.stop()
	
	ui.show_victory()
	player.celebrate_win()
	game_finished.emit("win")

func _on_train_jerk_timer_timeout() -> void:
	if is_game_over or is_won: return
	
	var random_dir: float = [-1.0, 1.0].pick_random()
	train_jerk_force = random_dir * jerk_strength
	
	environment.shake()
	start_next_jerk()

func start_next_jerk() -> void:
	jerk_timer.wait_time = randf_range(1.0, 2.2)
	jerk_timer.start()
