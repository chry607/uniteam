extends Control

# Path to game manager scene
@export var game_scene: PackedScene = preload("res://manager/game_manager.tscn")

@onready var background = $background

func _ready() -> void:
	background.play("default")
	pass

func _input(event: InputEvent) -> void:
	# Detect click or screen tap
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_packed(game_scene)
