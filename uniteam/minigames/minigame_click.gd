extends Control

var instruction_text: String = "CLICK FAST!"

# The player defaults to losing because they haven't acted yet
var player_won: bool = false
@onready var button = $Button

func _on_button_pressed():
	# They did the thing!
	player_won = true
	
	# Succeed
	button.text = "GOOD JOB!"
	button.modulate = Color.GREEN
	button.disabled = true
