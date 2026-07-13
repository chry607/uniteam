extends Node2D

@onready var timer: Timer = $Timer
@onready var lives_label: Label = $UI/LivesLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var time_bar: ProgressBar = $UI/TimeBar

var click_game: PackedScene = preload("res://minigames/minigame_click.tscn")
var wait_game: PackedScene = preload("res://minigames/minigame_wait.tscn")
var current_minigame: Node = null

func _ready() -> void:
	update_ui()
	status_label.text = "GET READY!"
	await get_tree().create_timer(1.0).timeout 
	show_intermission()

func show_intermission() -> void:
	status_label.text = "" 
	lives_label.show()
	await get_tree().create_timer(1.0).timeout
	load_random_minigame()

func load_random_minigame() -> void:
	var games: Array[PackedScene] = [click_game, wait_game]
	var selected_game: PackedScene = games[randi() % games.size()]
	
	current_minigame = selected_game.instantiate()
	
	# Linear speed scaling: speed increases by 10% per point scored.
	var speed_scale: float = 1.0 + (Global.score * 0.1)
	
	# Direct setup call passing only the speed factor
	if current_minigame.has_method("setup_speed"):
		current_minigame.setup_speed(speed_scale)
	
	add_child(current_minigame)
	
	current_minigame.hide() 
	time_bar.hide() 
	lives_label.hide() 
	
	status_label.text = current_minigame.instruction_text
	status_label.show()
	
	await get_tree().create_timer(1.0).timeout
	
	status_label.text = ""
	current_minigame.show()
	time_bar.show()
	
	# Fetch base duration from the current minigame script
	var minigame_base_time: float = current_minigame.get("base_duration") if "base_duration" in current_minigame else 3.5
	
	# Shrink the timer directly based on the speed scale (min cap of 0.7s)
	var current_time_limit: float = maxf(0.7, minigame_base_time / speed_scale)
	
	time_bar.max_value = current_time_limit
	timer.start(current_time_limit)
	print("timer duration: %f" % time_bar.max_value)

func _process(_delta: float) -> void:
	if not timer.is_stopped():
		time_bar.value = timer.time_left
	else:
		time_bar.hide()

func _on_timer_timeout() -> void:
	var passed: bool = current_minigame.player_won
	lives_label.hide() 
	
	if passed:
		status_label.text = "WIN!"
		Global.score += 1
	else:
		status_label.text = "LOSE!"
		Global.lives -= 1
		
	update_ui()
	current_minigame.queue_free()
	
	if Global.lives > 0:
		await get_tree().create_timer(1.0).timeout 
		show_intermission()
	else:
		status_label.text = "GAME OVER\nFinal Score: " + str(Global.score)

func update_ui() -> void:
	lives_label.text = "Lives: " + str(Global.lives) + " | Score: " + str(Global.score)
