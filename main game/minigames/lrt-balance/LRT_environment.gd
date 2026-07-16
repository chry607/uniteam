class_name TrainEnvironment extends Node2D

# 1. Changed type from ColorRect to Sprite2D
var bg: Sprite2D 
var crowd_left: Sprite2D 
var crowd_right: Sprite2D 
var original_bg_pos: Vector2

func _init() -> void:
	# 1. Background (Now loads your custom PNG background)
	bg = Sprite2D.new()
	# Double check this path matches your actual background file name!
	bg.texture = preload("res://minigames/lrt-balance/lrt-bg.png")
	bg.centered = false
	add_child(bg)
	original_bg_pos = bg.position
	bg.scale = Vector2(1.2, 1.2)
	
	# 2. Crowd Left
	crowd_left = Sprite2D.new()
	crowd_left.texture = preload("res://minigames/lrt-balance/lrt-crowd-left.png")
	crowd_left.centered = false
	crowd_left.position = Vector2(-40, 220)
	bg.add_child(crowd_left)
	
	# 3. Crowd Right
	crowd_right = Sprite2D.new()
	crowd_right.texture = preload("res://minigames/lrt-balance/lrt-crowd-right.png")
	crowd_right.centered = false
	crowd_right.position = Vector2(800, 220)
	bg.add_child(crowd_right)

func shake() -> void:
	var shake_tween = create_tween()
	shake_tween.tween_property(bg, "position", original_bg_pos + Vector2(randf_range(-20, 20), 0), 0.05)
	shake_tween.tween_property(bg, "position", original_bg_pos + Vector2(randf_range(-15, 15), 0), 0.05)
	shake_tween.tween_property(bg, "position", original_bg_pos, 0.05)
