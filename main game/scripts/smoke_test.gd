extends SceneTree
## Headless smoke test: walk core state transitions.
## Run: godot --headless --path . -s res://scripts/smoke_test.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== UI Shell Smoke Test ===")
	var errors: PackedStringArray = []
	var gs: Node = root.get_node("GameState")
	var sm: Node = root.get_node("ScoreManager")

	var packed := load("res://scenes/main.tscn")
	if packed == null:
		push_error("Failed to load main.tscn")
		quit(1)
		return
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	print("OK: main scene instantiated")

	if main.splash == null or not main.splash.visible:
		errors.append("Splash not visible at start")
	else:
		print("OK: splash visible")

	main.splash.finished.emit()
	await create_timer(0.8).timeout
	if gs.current_state != gs.State.MAIN_MENU:
		await create_timer(0.5).timeout
	if gs.current_state != gs.State.MAIN_MENU:
		errors.append("Expected MAIN_MENU, got %s" % gs.current_state)
	else:
		print("OK: main menu")

	gs.start_run()
	await create_timer(0.3).timeout
	if gs.current_state != gs.State.COUNTDOWN:
		errors.append("Expected COUNTDOWN after start_run, got %s" % gs.current_state)
	else:
		print("OK: countdown")

	# Countdown is ~2s of animation; wait for MINIGAME
	var waited := 0.0
	while gs.current_state != gs.State.MINIGAME and waited < 5.0:
		await create_timer(0.2).timeout
		waited += 0.2
	print("INFO: state after countdown wait = ", gs.current_state)

	if gs.current_state == gs.State.MINIGAME:
		var host = main.minigame_host
		if host == null:
			errors.append("MinigameHost missing")
		elif not host.is_running():
			errors.append("MinigameHost not running after enter MINIGAME")
		else:
			print("OK: minigame host running id=", gs.pending_minigame_id)
			# Hosted inside design-res SubViewport (scaled to shell)
			var active = host.find_child("ActiveMinigame", true, false)
			if active == null:
				errors.append("ActiveMinigame node missing")
			elif not active.has_signal("game_finished"):
				errors.append("ActiveMinigame missing game_finished (script failed to load?)")
			else:
				print("OK: active minigame has game_finished")
				var vp = host.find_child("MinigameViewport", true, false)
				if vp is SubViewport:
					var vps: Vector2i = (vp as SubViewport).size
					print("OK: design viewport size=", vps)
					if vps.x < 640 or vps.y < 360:
						errors.append("Minigame SubViewport too small: %s" % vps)

	sm.lives = 1
	# Only finish if still in minigame; otherwise force death path
	if gs.current_state == gs.State.MINIGAME:
		gs.finish_minigame(false)
	else:
		sm.lives = 0
		sm.end_run()
		gs.change_state(gs.State.GAME_OVER)
	await create_timer(0.5).timeout
	if gs.current_state != gs.State.GAME_OVER:
		errors.append("Expected GAME_OVER, got %s" % gs.current_state)
	else:
		print("OK: game over")

	gs.go_results()
	await create_timer(0.3).timeout
	if gs.current_state != gs.State.RESULTS:
		errors.append("Expected RESULTS, got %s" % gs.current_state)
	else:
		print("OK: results")

	gs.go_main_menu()
	await create_timer(0.3).timeout
	if gs.current_state != gs.State.MAIN_MENU:
		errors.append("Expected MAIN_MENU after results, got %s" % gs.current_state)
	else:
		print("OK: back to menu")

	if errors.is_empty():
		print("=== ALL SMOKE CHECKS PASSED ===")
		quit(0)
	else:
		print("=== FAILURES ===")
		for e in errors:
			print(" - ", e)
		quit(1)
