extends Control

# Signal to end the round immediately upon winning
signal game_won_early

var instruction_text: String = "CLICK FAST!"
var player_won: bool = false

# Base stats
var base_duration: float = 3.0 
var speed: float = 1.0

@onready var button = $Button

func setup_speed(speed_scale: float) -> void:
	speed = speed_scale
	
	if not is_node_ready():
		await ready
		
func _on_button_pressed() -> void:
	if player_won:
		return
		
	player_won = true
	
	button.text = "GOOD JOB!"
	button.modulate = Color.GREEN
	button.disabled = true

	# Emit the signal
	game_won_early.emit()
