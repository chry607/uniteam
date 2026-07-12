extends Node2D

@onready var timer = $Timer
@onready var lives_label = $UI/LivesLabel
@onready var status_label = $UI/StatusLabel
@onready var time_bar = $UI/TimeBar

var click_game = preload("res://minigames/minigame_click.tscn")
var wait_game = preload("res://minigames/minigame_wait.tscn")
var current_minigame = null

var base_time: float = 3.0
var current_time_limit: float = 3.0

func _ready():
	update_ui()
	status_label.text = "GET READY!"
	await get_tree().create_timer(1.0).timeout 
	show_intermission()

func show_intermission():
	status_label.text = "" 
	lives_label.show()
	await get_tree().create_timer(1.0).timeout
	load_random_minigame()

func load_random_minigame():
	var games = [click_game, wait_game]
	var selected_game = games[randi() % games.size()]
	
	current_minigame = selected_game.instantiate()
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
	
	current_time_limit = max(0.8, base_time - (Global.score * 0.2))
	time_bar.max_value = current_time_limit
	timer.start(current_time_limit)

func _process(_delta):
	if not timer.is_stopped():
		time_bar.value = timer.time_left
	else:
		time_bar.hide()

func _on_timer_timeout():
	var passed = current_minigame.player_won
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

func update_ui():
	lives_label.text = "Lives: " + str(Global.lives) + " | Score: " + str(Global.score)
