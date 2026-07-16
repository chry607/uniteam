class_name MinigameBase
extends Node2D
## Base class for future minigames.
## Drop a scene that extends this into the shell without changing menus/HUD/transitions.
##
## Lifecycle (managed by shell):
##   1. Shell enters MINIGAME state
##   2. Call setup(context) then start()
##   3. Minigame emits completed(success)
##   4. Shell handles score/lives/transition

signal completed(success: bool)
signal score_gained(amount: int)

var minigame_id: String = "base"
var display_name: String = "Minigame"
var time_limit: float = 5.0
var is_running: bool = false


func setup(context: Dictionary = {}) -> void:
	if context.has("time_limit"):
		time_limit = float(context.time_limit)
	if context.has("display_name"):
		display_name = str(context.display_name)


func start() -> void:
	is_running = true
	_on_start()


func stop() -> void:
	is_running = false
	_on_stop()


func succeed() -> void:
	if not is_running:
		return
	is_running = false
	completed.emit(true)


func fail() -> void:
	if not is_running:
		return
	is_running = false
	completed.emit(false)


func add_bonus_score(amount: int) -> void:
	score_gained.emit(amount)


## Override in subclasses
func _on_start() -> void:
	pass


func _on_stop() -> void:
	pass
