extends Node
## Sound placeholder hooks. Emit these; do not play audio here.
## Wire a real AudioManager later to connect to these signals.

signal button_click(button_id: String)
signal button_hover(button_id: String)
signal countdown(value: int)
signal warning(phrase: String)
signal life_lost(lives_remaining: int)
signal game_over(final_score: int)
signal score_increment(amount: int, total: int)
signal transition_start(phrase: String)
signal transition_end()
signal menu_open(menu_name: String)
signal menu_close(menu_name: String)
signal pause_open()
signal pause_close()
signal screen_enter(screen_name: String)
signal screen_exit(screen_name: String)
signal notification_show(message: String)
signal combo_popup(combo: int)
signal timer_tick(seconds: int)
signal timer_urgent()
signal ui_pop()
signal ui_slide()

func emit_button_click(id: String = "") -> void:
	button_click.emit(id)


func emit_button_hover(id: String = "") -> void:
	button_hover.emit(id)


func emit_countdown(value: int) -> void:
	countdown.emit(value)


func emit_warning(phrase: String) -> void:
	warning.emit(phrase)


func emit_life_lost(lives: int) -> void:
	life_lost.emit(lives)


func emit_game_over(score: int) -> void:
	game_over.emit(score)


func emit_score_increment(amount: int, total: int) -> void:
	score_increment.emit(amount, total)


func emit_transition_start(phrase: String) -> void:
	transition_start.emit(phrase)


func emit_transition_end() -> void:
	transition_end.emit()


func emit_menu_open(name: String) -> void:
	menu_open.emit(name)


func emit_menu_close(name: String) -> void:
	menu_close.emit(name)


func emit_pause_open() -> void:
	pause_open.emit()


func emit_pause_close() -> void:
	pause_close.emit()


func emit_screen_enter(name: String) -> void:
	screen_enter.emit(name)


func emit_screen_exit(name: String) -> void:
	screen_exit.emit(name)


func emit_notification(message: String) -> void:
	notification_show.emit(message)


func emit_combo(combo: int) -> void:
	combo_popup.emit(combo)


func emit_timer_tick(seconds: int) -> void:
	timer_tick.emit(seconds)


func emit_timer_urgent() -> void:
	timer_urgent.emit()


func emit_ui_pop() -> void:
	ui_pop.emit()


func emit_ui_slide() -> void:
	ui_slide.emit()
