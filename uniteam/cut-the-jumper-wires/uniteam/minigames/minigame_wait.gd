extends Control

# Signal to end the round immediately upon losing
signal game_over_early

var instruction_text: String = "DO NOTHING!"
var player_won: bool = true

# Base stats
var base_duration: float = 4.0 
var speed: float = 1.0

@onready var button = $Button

func setup_speed(speed_scale: float) -> void:
	speed = speed_scale
	if not is_node_ready():
		await ready

func _on_button_pressed() -> void:
	if not player_won:
		return
		
	player_won = false
	button.text = "YOU FAILED!"
	button.modulate = Color.RED
	button.disabled = true

	# Emit the signal
	game_over_early.emit()
