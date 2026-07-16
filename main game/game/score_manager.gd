extends Node
## Tracks score, lives, combo, rounds, and run statistics.

signal score_changed(new_score: int, delta: int)
signal lives_changed(lives: int)
signal combo_changed(combo: int)
signal round_changed(round_num: int)
signal best_score_changed(best: int)

const MAX_LIVES := 3
const STARTING_LIVES := 3

var score: int = 0
var best_score: int = 0
var lives: int = STARTING_LIVES
var combo: int = 0
var highest_combo: int = 0
var current_round: int = 0
var games_cleared: int = 0
var deaths: int = 0
var survival_seconds: float = 0.0
var longest_survival: float = 0.0
var run_active: bool = false

var _run_start_msec: int = 0


func _ready() -> void:
	best_score = _load_best()


func reset_run() -> void:
	score = 0
	lives = STARTING_LIVES
	combo = 0
	highest_combo = 0
	current_round = 0
	games_cleared = 0
	deaths = 0
	survival_seconds = 0.0
	run_active = true
	_run_start_msec = Time.get_ticks_msec()
	score_changed.emit(score, 0)
	lives_changed.emit(lives)
	combo_changed.emit(combo)
	round_changed.emit(current_round)


func end_run() -> void:
	run_active = false
	survival_seconds = (Time.get_ticks_msec() - _run_start_msec) / 1000.0
	if survival_seconds > longest_survival:
		longest_survival = survival_seconds
	if score > best_score:
		best_score = score
		_save_best(best_score)
		best_score_changed.emit(best_score)


func add_score(amount: int, from_success: bool = true) -> void:
	if amount <= 0:
		return
	score += amount
	if from_success:
		combo += 1
		if combo > highest_combo:
			highest_combo = combo
		combo_changed.emit(combo)
		AudioEvents.emit_combo(combo)
	score_changed.emit(score, amount)
	AudioEvents.emit_score_increment(amount, score)


func break_combo() -> void:
	if combo != 0:
		combo = 0
		combo_changed.emit(combo)


func lose_life() -> void:
	if lives <= 0:
		return
	lives -= 1
	deaths += 1
	break_combo()
	lives_changed.emit(lives)
	AudioEvents.emit_life_lost(lives)


func advance_round() -> void:
	current_round += 1
	games_cleared += 1
	round_changed.emit(current_round)


func is_dead() -> bool:
	return lives <= 0


func get_fun_stat_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	if survival_seconds < 15.0:
		lines.append("You barely left the sari-sari store.")
	elif survival_seconds < 45.0:
		lines.append("You survived rush hour briefly.")
	else:
		lines.append("You outlasted the jeepney queue.")
	lines.append("You only died %d times." % max(deaths, 1 if is_dead() else deaths))
	if highest_combo >= 5:
		lines.append("Highest combo: x%d." % highest_combo)
	elif highest_combo >= 2:
		lines.append("Not bad — highest combo x%d." % highest_combo)
	else:
		lines.append("No combo recorded.")
	if games_cleared == 0:
		lines.append("Zero games cleared.")
	elif games_cleared < 5:
		lines.append("%d games cleared." % games_cleared)
	else:
		lines.append("%d games cleared." % games_cleared)
	return lines


func _load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		return int(cfg.get_value("scores", "best", 0))
	return 0


func _save_best(value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://save.cfg")
	cfg.set_value("scores", "best", value)
	cfg.save("user://save.cfg")
