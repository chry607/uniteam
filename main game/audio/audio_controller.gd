extends Node
## Global SFX / music bank (from Uniteam). Accessed as AudioController autoload.
## Builds players in code so we don't depend on a fragile .tscn + import UID graph.

const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_PLAYERS := ["music"]

@export var mute: bool = false

## Linear 0..1 multipliers applied on top of each player's authored base volume.
var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.9

var _players: Dictionary = {} # name -> AudioStreamPlayer
var _base_volumes: Dictionary = {} # name -> float (authored dB at full volume)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_player("music", "res://audio/bg.mp3", 0.0)
	_setup_player("crash", "res://audio/car_crash.wav", 16.0)
	_setup_player("lrt_move", "res://audio/lrt_move.mp3", 7.0)
	_setup_player("road_bg", "res://audio/road_bg.mp3", -12.0)
	_setup_player("eshock", "res://audio/eshock.mp3", -5.0)
	_setup_player("cubao", "res://audio/arriving_cubao.mp3", -10.0)
	_setup_player("train", "res://audio/train.mp3", -6.0)
	_setup_player("train_crash", "res://audio/train_crash.mp3", 7.0)
	_setup_player("round_win", "res://audio/round_win.wav", 7.0)
	_setup_player("round_lose", "res://audio/round_lose.mp3", 0.0)
	_setup_player("game_done", "res://audio/game_done.wav", 9.0)
	load_settings()
	if not mute and master_volume > 0.001 and music_volume > 0.001:
		play_music()


func _setup_player(p_name: String, path: String, volume_db: float) -> void:
	var player := AudioStreamPlayer.new()
	player.name = p_name
	player.volume_db = volume_db
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			player.stream = stream
		else:
			push_warning("AudioController: failed to load %s" % path)
	else:
		push_warning("AudioController: missing audio file %s" % path)
	add_child(player)
	_players[p_name] = player
	_base_volumes[p_name] = volume_db


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	_sync_music_playback()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	_sync_music_playback()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()


func _apply_volumes() -> void:
	for p_name in _players:
		var player: AudioStreamPlayer = _players[p_name]
		var base: float = float(_base_volumes.get(p_name, 0.0))
		var channel: float = music_volume if p_name in MUSIC_PLAYERS else sfx_volume
		var linear: float = master_volume * channel
		if linear <= 0.0001:
			player.volume_db = -80.0
		else:
			player.volume_db = base + linear_to_db(linear)


func _sync_music_playback() -> void:
	var music: AudioStreamPlayer = _players.get("music")
	if music == null:
		return
	var should_play := not mute and master_volume > 0.001 and music_volume > 0.001
	if not should_play:
		if music.playing:
			music.stop()
		return
	if music.playing:
		return
	# Don't auto-resume during game-over silence.
	if GameState != null and GameState.current_state == GameState.State.GAME_OVER:
		return
	play_music()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		master_volume = clampf(float(cfg.get_value("audio", "master", master_volume)), 0.0, 1.0)
		music_volume = clampf(float(cfg.get_value("audio", "music", music_volume)), 0.0, 1.0)
		sfx_volume = clampf(float(cfg.get_value("audio", "sfx", sfx_volume)), 0.0, 1.0)
	_apply_volumes()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SETTINGS_PATH)


func _play(p_name: String, from_pos: float = 0.0) -> void:
	if mute:
		return
	if master_volume <= 0.0001:
		return
	var is_music := p_name in MUSIC_PLAYERS
	if is_music and music_volume <= 0.0001:
		return
	if not is_music and sfx_volume <= 0.0001:
		return
	var p: AudioStreamPlayer = _players.get(p_name)
	if p == null or p.stream == null:
		return
	p.play(from_pos)


func _stop(p_name: String) -> void:
	var p: AudioStreamPlayer = _players.get(p_name)
	if p:
		p.stop()


func play_music() -> void:
	_play("music")


func stop_music() -> void:
	_stop("music")


func play_crash() -> void:
	_play("crash", 0.20)


func play_lrt_move() -> void:
	_play("lrt_move")


func play_road_bg() -> void:
	_play("road_bg")


func stop_road_bg() -> void:
	_stop("road_bg")


func play_eshock() -> void:
	_play("eshock", 0.78)


func play_cubao() -> void:
	_play("cubao")
	_play("train", 9.50)


func play_train_crash() -> void:
	_play("train_crash")


func stop_cubao() -> void:
	_stop("cubao")
	_stop("train")


func play_round_win() -> void:
	_play("round_win")


func play_round_lose() -> void:
	_play("round_lose", 1.12)


func play_game_done() -> void:
	_play("game_done")


func stop_all_minigame_sfx() -> void:
	stop_road_bg()
	stop_cubao()
