extends Node2D

@onready var score_label: Label = $UI/ScoreLabel
@onready var lives_container: HBoxContainer = $UI/LivesContainer
@onready var status_label: Label = $UI/StatusLabel
@onready var time_bar: ProgressBar = $UI/TimeBar

# Grab the reference to the new button
@onready var try_again_btn: Button = $UI/TryAgainButton

var challenge_scenes: Array[PackedScene] = [
	preload("res://minigames/cut-the-jumper-wires/game_wire.tscn"),
	preload("res://minigames/crossy-road/Main.tscn"),
	preload("res://minigames/lrt-balance/game_LRTbalance.tscn")
]

var challenge_names: Array[String] = [
	"CUT THE JUMPER WIRES",
	"CROSSY THE EDSA",
	"LRT BALANCE"
]

var challenge_intros: Array[String] = [
	"DON'T CUT THE WRONG WIRE!",
	"SURVIVE THE CROSSING!",
	"STAY BALANCED ON THE TRAIN!"
]

var current_challenge: Node = null

# Keep track of the last game played
var last_played_index: int = -1 

func _ready() -> void:
	# Wire up the Try Again button via code
	try_again_btn.pressed.connect(_on_try_again_pressed)
	try_again_btn.hide() # Ensure it's hidden when starting
	
	_hide_time_bar() # Enforce invisible time bar from launch
	update_ui()
	status_label.text = "WELCOME TO MANILA!"
	await get_tree().create_timer(0.8).timeout
	start_next_challenge()

func start_next_challenge() -> void:
	if current_challenge != null:
		current_challenge.queue_free()
		current_challenge = null

	# ANTI-REPEAT LOGIC
	var index: int = randi() % challenge_scenes.size()
	# If the new random game is the same as the last one, roll again!
	while index == last_played_index:
		index = randi() % challenge_scenes.size()
		
	# Save this index for the NEXT time we roll
	last_played_index = index 

	var selected_scene: PackedScene = challenge_scenes[index]
	current_challenge = selected_scene.instantiate()
	current_challenge.name = "Challenge"

	if current_challenge.has_signal("game_finished"):
		current_challenge.game_finished.connect(_on_challenge_finished)

	add_child(current_challenge)

	status_label.text = challenge_names[index] + "\n" + challenge_intros[index]
	
	_hide_time_bar()
	score_label.hide()
	lives_container.hide()

	await get_tree().create_timer(1.0).timeout
	status_label.text = ""
	
	_hide_time_bar() # Replaced time_bar.show() to keep it strictly hidden!
	# score_label.show()
	lives_container.show()

func _on_challenge_finished(result: String) -> void:
	if current_challenge == null:
		return

	# Delete the mini-game immediately
	current_challenge.queue_free()
	current_challenge = null

	_hide_time_bar()
	
	if result == "win":
		AudioController.play_round_win()
		Global.score += 1
		status_label.text = "SURVIVED!\n\n"
	else:
		AudioController.play_round_lose()
		Global.lives -= 1
		status_label.text = "YOU GOT HIT!\n\nLives Left: " + str(Global.lives)

	update_ui()
	score_label.show()
	lives_container.show()

	# The Intermission
	await get_tree().create_timer(1.2).timeout

	if Global.lives > 0:
		start_next_challenge()
	else:
		# 4. GAME OVER SEQUENCE
		AudioController.stop_music()
		AudioController.play_game_done()
		status_label.text = "GAME OVER\n\nFinal Score: " + str(Global.score)
		score_label.hide()
		lives_container.hide()
		_hide_time_bar()
		try_again_btn.show() # Reveal the button!

func update_ui() -> void:
	score_label.text = "SCORE: " + str(Global.score)
	
	var life_icons = lives_container.get_children()
	for i in range(life_icons.size()):
		if i < Global.lives:
			life_icons[i].show()
		else:
			life_icons[i].hide()

# Helper method to force hide time_bar completely (visibility + alpha zeroed)
func _hide_time_bar() -> void:
	if time_bar:
		time_bar.hide()
		time_bar.visible = false
		time_bar.modulate.a = 0.0

# 5. RESTART LOGIC
func _on_try_again_pressed() -> void:
	# Reset global variables back to starting defaults
	Global.score = 0
	Global.lives = 3 # (Change this to whatever your starting max is!)
	
	# Reload the entire Game Manager scene fresh
	get_tree().reload_current_scene()
