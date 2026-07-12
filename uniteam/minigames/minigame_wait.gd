extends Control

var instruction_text: String = "DO NOTHING!"

# The player defaults to winning, as long as they don't touch anything!
var player_won: bool = true
@onready var button = $Button

func _on_button_pressed():
	# should not be pressed!
	player_won = false
	
	button.text = "YOU FAILED!"
	button.modulate = Color.RED # Turns the button red
	button.disabled = true
