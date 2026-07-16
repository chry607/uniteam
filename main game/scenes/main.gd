extends Control
## Root UI shell — owns all screens and wires the GameState state machine.

const MinigameHostScene := preload("res://scenes/minigame_host.gd")

var splash: SplashScreen
var main_menu: MainMenu
var settings: SettingsScreen
var info: InfoScreens
var countdown: CountdownOverlay
var transition: TransitionOverlay
var hud: GameHUD
var pause_menu: PauseMenu
var game_over: GameOverScreen
var results: ResultsScreen
var minigame_host: Control
var toast: NotificationToast
var loading: LoadingSpinner

var _busy := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Keyboard focus ring uses theme focus styles on GameButton
	get_viewport().gui_focus_changed.connect(_on_focus_changed)

	# Gameplay layer: full-rect host scales design-res minigames to the shell
	minigame_host = MinigameHostScene.new()
	minigame_host.name = "MinigameHost"
	minigame_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	minigame_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(minigame_host)
	minigame_host.completed.connect(_on_minigame_completed)
	# Keep host under menus/HUD in tree order (drawn first = behind)

	splash = SplashScreen.new()
	add_child(splash)

	main_menu = MainMenu.new()
	add_child(main_menu)

	settings = SettingsScreen.new()
	add_child(settings)

	info = InfoScreens.new()
	add_child(info)

	game_over = GameOverScreen.new()
	add_child(game_over)

	results = ResultsScreen.new()
	add_child(results)

	pause_menu = PauseMenu.new()
	add_child(pause_menu)

	hud = GameHUD.new()
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)

	countdown = CountdownOverlay.new()
	add_child(countdown)

	transition = TransitionOverlay.new()
	add_child(transition)

	toast = NotificationToast.new()
	add_child(toast)

	# Wire screens
	splash.finished.connect(_on_splash_finished)

	main_menu.play_pressed.connect(func(): GameState.start_run())
	main_menu.settings_pressed.connect(func(): GameState.go_settings(GameState.State.MAIN_MENU))
	main_menu.credits_pressed.connect(func(): GameState.go_credits())
	main_menu.how_to_play_pressed.connect(func(): GameState.go_how_to_play())
	main_menu.quit_pressed.connect(func(): GameState.quit_game())

	settings.closed.connect(_on_settings_closed)
	info.closed.connect(_on_info_closed)

	pause_menu.resume_pressed.connect(_on_pause_resume)
	pause_menu.restart_pressed.connect(_on_pause_restart)
	pause_menu.main_menu_pressed.connect(_on_pause_main_menu)
	pause_menu.settings_pressed.connect(func(): GameState.go_settings(GameState.State.PAUSE))

	game_over.retry_pressed.connect(func(): GameState.start_run())
	game_over.main_menu_pressed.connect(func(): GameState.go_main_menu())
	game_over.results_pressed.connect(func(): GameState.go_results())

	results.replay_pressed.connect(func(): GameState.start_run())
	results.main_menu_pressed.connect(func(): GameState.go_main_menu())

	GameState.state_changed.connect(_on_state_changed)

	# Start at splash
	_hide_all()
	splash.enter()
	GameState.current_state = GameState.State.SPLASH
	UIManager.notify("Welcome to Difficulty Level: Pinoy!", 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if GameState.current_state == GameState.State.MINIGAME:
			GameState.open_pause()
			get_viewport().set_input_as_handled()
		elif GameState.current_state == GameState.State.PAUSE:
			_on_pause_resume()
			get_viewport().set_input_as_handled()


func _hide_all() -> void:
	splash.visible = false
	main_menu.visible = false
	settings.visible = false
	info.visible = false
	game_over.visible = false
	results.visible = false
	pause_menu.visible = false
	hud.visible = false
	countdown.visible = false
	transition.visible = false


func _on_splash_finished() -> void:
	await splash.exit()
	GameState.go_main_menu()


func _on_state_changed(_from_state: GameState.State, to_state: GameState.State) -> void:
	match to_state:
		GameState.State.SPLASH:
			_hide_all()
			minigame_host.clear()
			splash.enter()
		GameState.State.MAIN_MENU:
			_hide_all()
			get_tree().paused = false
			minigame_host.clear()
			main_menu.enter()
		GameState.State.SETTINGS:
			settings.enter()
		GameState.State.HOW_TO_PLAY:
			info.show_how_to()
		GameState.State.CREDITS:
			info.show_credits()
		GameState.State.COUNTDOWN:
			await _run_countdown()
		GameState.State.MINIGAME:
			_enter_minigame()
		GameState.State.TRANSITION:
			await _run_transition()
		GameState.State.PAUSE:
			pause_menu.open_menu()
		GameState.State.GAME_OVER:
			_enter_game_over()
		GameState.State.RESULTS:
			_enter_results()
		_:
			pass


func _run_countdown() -> void:
	_busy = true
	main_menu.visible = false
	game_over.visible = false
	results.visible = false
	minigame_host.clear()
	hud.show_hud()
	# Real minigames own their own timers — hide shell countdown chip during play
	hud.hide_shell_timer()
	var title := GameState.pending_minigame_name
	if GameState.pending_minigame_intro != "":
		title = "%s\n%s" % [GameState.pending_minigame_name, GameState.pending_minigame_intro]
	countdown.play(title)
	await countdown.finished
	_busy = false
	GameState.begin_minigame()


func _enter_minigame() -> void:
	# Resuming from pause: host already running
	if minigame_host.is_running():
		hud.show_hud()
		return
	hud.show_hud()
	hud.hide_shell_timer()
	if GameState.pending_minigame_entry.is_empty():
		push_error("main: no pending minigame entry")
		GameState.finish_minigame(false)
		return
	minigame_host.start(GameState.pending_minigame_entry)


func _on_minigame_completed(success: bool) -> void:
	if GameState.current_state != GameState.State.MINIGAME:
		return
	GameState.finish_minigame(success)


func _run_transition() -> void:
	_busy = true
	minigame_host.clear()
	hud.hide_shell_timer()
	transition.play()
	await transition.finished
	_busy = false
	GameState.after_transition()


func _enter_game_over() -> void:
	minigame_host.clear()
	hud.hide_hud()
	get_tree().paused = false
	game_over.enter()


func _enter_results() -> void:
	game_over.exit()
	results.enter()


func _on_settings_closed() -> void:
	settings.exit()
	if GameState.settings_return_state == GameState.State.PAUSE:
		GameState.change_state(GameState.State.PAUSE)
	else:
		GameState.go_main_menu()


func _on_info_closed() -> void:
	info.exit()
	GameState.go_main_menu()


func _on_pause_resume() -> void:
	await pause_menu.close_menu()
	GameState.resume_from_pause()


func _on_pause_restart() -> void:
	await pause_menu.close_menu()
	minigame_host.clear()
	GameState.restart_from_pause_or_over()


func _on_pause_main_menu() -> void:
	await pause_menu.close_menu()
	minigame_host.clear()
	ScoreManager.end_run()
	GameState.go_main_menu()


func _on_focus_changed(control: Control) -> void:
	# Accessibility: light scale pulse on newly focused control
	if control == null or not control is BaseButton:
		return
	var tw := control.create_tween()
	tw.tween_property(control, "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(control, "scale", Vector2.ONE, 0.1)
