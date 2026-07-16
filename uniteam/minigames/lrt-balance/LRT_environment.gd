class_name TrainEnvironment extends Node2D

var bg: ColorRect
var crowd_left: ColorRect # Kept as ColorRect
var crowd_right: Sprite2D # Changed to Sprite2D
var original_bg_pos: Vector2

func _init() -> void:
	# 1. Background
	bg = ColorRect.new()
	bg.color = Color(0.2, 0.25, 0.3)
	bg.set_size(Vector2(1280, 720))
	add_child(bg)
	original_bg_pos = bg.position
	
	# 2. Crowd Left (Kept as the original black rectangle)
	crowd_left = ColorRect.new()
	crowd_left.color = Color(0.1, 0.1, 0.1)
	crowd_left.set_size(Vector2(300, 500))
	crowd_left.position = Vector2(0, 220)
	bg.add_child(crowd_left)
	
	# 3. Crowd Right (Now loads your custom PNG)
	crowd_right = Sprite2D.new()
	# REPLACE this path with your actual crowd PNG file path if it's different!
	crowd_right.texture = preload("res://minigames/lrt-balance/lrt-crowd-right.png")
	crowd_right.centered = false
	crowd_right.position = Vector2(900, 220)
	bg.add_child(crowd_right)

func shake() -> void:
	var shake_tween = create_tween()
	shake_tween.tween_property(bg, "position", original_bg_pos + Vector2(randf_range(-20, 20), 0), 0.05)
	shake_tween.tween_property(bg, "position", original_bg_pos + Vector2(randf_range(-15, 15), 0), 0.05)
	shake_tween.tween_property(bg, "position", original_bg_pos, 0.05)
