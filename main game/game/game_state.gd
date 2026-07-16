extends Node
## Global state machine for the UI shell.
## Splash → Main Menu → Countdown → Minigame ⇄ Transition → Game Over → Results → Main Menu

enum State {
	SPLASH,
	MAIN_MENU,
	SETTINGS,
	HOW_TO_PLAY,
	CREDITS,
	COUNTDOWN,
	MINIGAME,
	TRANSITION,
	PAUSE,
	GAME_OVER,
	RESULTS,
}

signal state_changed(from_state: State, to_state: State)
signal request_minigame_start(round_num: int)
signal request_minigame_end(success: bool)

var current_state: State = State.SPLASH
var previous_state: State = State.SPLASH
var pending_minigame_name: String = ""
var pending_minigame_intro: String = ""
var pending_minigame_id: String = ""
var pending_minigame_entry: Dictionary = {}
var settings_return_state: State = State.MAIN_MENU
## Result of the minigame that just ended (used by the between-round overlay).
var last_round_success: bool = true

## True while a real minigame instance is active (not placeholder auto-timer)
var _minigame_active: bool = false


func change_state(to: State) -> void:
	if to == current_state:
		return
	previous_state = current_state
	current_state = to
	state_changed.emit(previous_state, current_state)
	AudioEvents.emit_screen_enter(_state_name(to))


func _state_name(s: State) -> String:
	return State.keys()[s]


func go_splash() -> void:
	change_state(State.SPLASH)


func go_main_menu() -> void:
	_minigame_active = false
	change_state(State.MAIN_MENU)


func go_settings(from: State = State.MAIN_MENU) -> void:
	settings_return_state = from
	change_state(State.SETTINGS)


func go_how_to_play() -> void:
	change_state(State.HOW_TO_PLAY)


func go_credits() -> void:
	change_state(State.CREDITS)


func start_run() -> void:
	ScoreManager.reset_run()
	if MinigameRegistry.has_method("reset_difficulties"):
		MinigameRegistry.reset_difficulties()
	_pick_next_minigame()
	change_state(State.COUNTDOWN)


func begin_minigame() -> void:
	ScoreManager.advance_round()
	_minigame_active = true
	change_state(State.MINIGAME)
	request_minigame_start.emit(ScoreManager.current_round)


func finish_minigame(success: bool) -> void:
	if current_state != State.MINIGAME and current_state != State.PAUSE:
		return
	_minigame_active = false
	last_round_success = success
	request_minigame_end.emit(success)
	if success:
		var pts := 5 + mini(ScoreManager.combo, 10)
		ScoreManager.add_score(pts, true)
		# Next time this minigame is rolled, scale difficulty (Uniteam-style).
		if MinigameRegistry.has_method("advance_difficulty_for_entry"):
			MinigameRegistry.advance_difficulty_for_entry(pending_minigame_entry)
	else:
		ScoreManager.lose_life()
		if ScoreManager.is_dead():
			ScoreManager.end_run()
			AudioEvents.emit_game_over(ScoreManager.score)
			change_state(State.GAME_OVER)
			return
	_pick_next_minigame()
	change_state(State.TRANSITION)


func after_transition() -> void:
	if ScoreManager.is_dead():
		change_state(State.GAME_OVER)
	else:
		change_state(State.COUNTDOWN)


func open_pause() -> void:
	if current_state == State.MINIGAME:
		change_state(State.PAUSE)
		get_tree().paused = true
		AudioEvents.emit_pause_open()


func resume_from_pause() -> void:
	if current_state == State.PAUSE:
		get_tree().paused = false
		change_state(State.MINIGAME)
		_minigame_active = true
		AudioEvents.emit_pause_close()


func restart_from_pause_or_over() -> void:
	get_tree().paused = false
	_minigame_active = false
	start_run()


func go_results() -> void:
	change_state(State.RESULTS)


func quit_game() -> void:
	get_tree().quit()


## Between-round message shown on the transition overlay.
func get_transition_message() -> String:
	var lives: int = ScoreManager.lives
	var lives_line := "%d %s remaining" % [lives, "life" if lives == 1 else "lives"]
	if last_round_success:
		return "Round cleared\n%s" % lives_line
	return "Failed round\n%s" % lives_line


## Kept for older call sites; prefers the new lives-aware message.
func get_random_transition_phrase() -> String:
	return get_transition_message()


func _pick_next_minigame() -> void:
	var entry: Dictionary = MinigameRegistry.pick_next()
	pending_minigame_entry = entry
	pending_minigame_id = str(entry.get("id", ""))
	pending_minigame_name = str(entry.get("display_name", "Minigame"))
	pending_minigame_intro = str(entry.get("intro", ""))


func is_gameplay_state() -> bool:
	return current_state in [State.MINIGAME, State.COUNTDOWN, State.TRANSITION, State.PAUSE]
