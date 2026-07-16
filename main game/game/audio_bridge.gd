extends Node
## Connects shell AudioEvents + run lifecycle to the Uniteam AudioController.

func _ready() -> void:
	# Shell UI hooks
	AudioEvents.life_lost.connect(_on_life_lost)
	AudioEvents.game_over.connect(_on_game_over)
	AudioEvents.score_increment.connect(_on_score)
	AudioEvents.button_click.connect(_on_button_click)

	GameState.state_changed.connect(_on_state_changed)
	GameState.request_minigame_end.connect(_on_minigame_end)


func _on_state_changed(_from: GameState.State, to: GameState.State) -> void:
	match to:
		GameState.State.MAIN_MENU:
			_ensure_music()
		GameState.State.COUNTDOWN:
			_ensure_music()
		GameState.State.GAME_OVER:
			if AudioController:
				AudioController.stop_music()
				AudioController.play_game_done()
		GameState.State.RESULTS:
			pass
		_:
			pass


func _on_minigame_end(success: bool) -> void:
	if AudioController == null:
		return
	if success:
		AudioController.play_round_win()
	else:
		AudioController.play_round_lose()


func _on_life_lost(_lives: int) -> void:
	# round_lose already plays on minigame fail; keep light for non-minigame losses
	pass


func _on_game_over(_score: int) -> void:
	# Handled on GAME_OVER state to avoid double play_game_done
	pass


func _on_score(_amount: int, _total: int) -> void:
	pass


func _on_button_click(_id: String) -> void:
	# No dedicated click SFX in the Uniteam bank yet
	pass


func _ensure_music() -> void:
	if AudioController == null:
		return
	var music := AudioController.get_node_or_null("music") as AudioStreamPlayer
	if music and not music.playing and not AudioController.mute:
		AudioController.play_music()
