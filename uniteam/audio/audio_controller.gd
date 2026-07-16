extends Node2D

@export var mute: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not mute:
		play_music()
		
func play_music():
	if not mute:
		$music.play()
		
func stop_music():
	$music.stop()

func play_crash():
	$crash.play(0.20)

func play_lrt_move():
	$lrt_move.play()

func play_road_bg():
	$road_bg.play()
	
func stop_road_bg():
	$road_bg.stop()
	
func play_eshock():
	$eshock.play(0.78)

func play_cubao():
	$cubao.play()
	$train.play(9.50)
	
func play_train_crash():
	$train_crash.play()
	
func stop_cubao():
	$cubao.stop()
	$train.stop()

func play_round_win():
	$round_win.play()

func play_round_lose():
	$round_lose.play(1.12)
	
func play_game_done():
	$game_done.play()
