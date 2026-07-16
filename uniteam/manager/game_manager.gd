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

# Keep track of the last game played and difficulty scales
var last_played_index: int = -1 
var challenge_levels: Array[int] = [0, 0, 0] # Tracks difficulty for each of the 3 games

# --- NEW: Holds the indices of the games remaining in the current block ---
var challenge_bag: Array[int] = []

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

	# --- DYNAMIC PLAYLIST SYSTEM ---
	# If our playlist/bag is empty, refill it with [0, 1, 2] and shuffle it!
	if challenge_bag.is_empty():
		var new_bag: Array[int] = []
		for i in range(challenge_scenes.size()):
			new_bag.append(i)
		new_bag.shuffle()
		
		# Transition Safeguard: If the first game in the new 3-game block is 
		# the exact same as the last game of the previous block, swap it with
		# the second game. This prevents a game playing twice in a row!
		if last_played_index != -1 and new_bag.size() > 1 and new_bag[0] == last_played_index:
			var temp = new_bag[0]
			new_bag[0] = new_bag[1]
			new_bag[1] = temp
			
		challenge_bag = new_bag

	# Draw the next game from the front of our shuffled bag!
	var index: int = challenge_bag.pop_front()
	last_played_index = index 

	var selected_scene: PackedScene = challenge_scenes[index]
	current_challenge = selected_scene.instantiate()
	current_challenge.name = "Challenge"

	# DIFFICULTY SCALING: Pass the level before adding to the tree so _ready() uses new stats
	if current_challenge.has_method("set_difficulty"):
		current_challenge.set_difficulty(challenge_levels[index])
	
	# Increment the difficulty level for the next time this specific game is rolled
	challenge_levels[index] += 1

	if current_challenge.has_signal("game_finished"):
		current_challenge.game_finished.connect(_on_challenge_finished)

	add_child(current_challenge)

	status_label.text = challenge_names[index] + "\n" + challenge_intros[index]
	
	_hide_time_bar()
	score_label.hide()
	lives_container.hide()

	await get_tree().create_timer(1.0).timeout
	status_label.text = ""
	
	_hide_time_bar() 
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

func _hide_time_bar() -> void:
	if time_bar:
		time_bar.hide()
		time_bar.visible = false
		time_bar.modulate.a = 0.0

func _on_try_again_pressed() -> void:
	# Reset global variables back to starting defaults
	AudioController.play_music()
	Global.score = 0
	Global.lives = 3
	
	# Reloading the scene natively resets the challenge_levels and challenge_bag array!
	get_tree().reload_current_scene()
