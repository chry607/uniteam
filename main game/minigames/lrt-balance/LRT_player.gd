class_name PlayerCharacter extends Node2D

# 1. Changed type to Sprite2D
var visual: Sprite2D 
var base_scale: Vector2 = Vector2(0.4, 0.4)

func _init() -> void:
	self.position = Vector2(700, 780) # Root acts as the pivot at the bottom center of the screen
	
	# 2. Instantiate Sprite2D and load your PNG
	visual = Sprite2D.new()
	# REPLACE this path with the actual path to your PNG file!
	visual.texture = preload("res://minigames/lrt-balance/lrt-balance-player.png") 
	add_child(visual)
	
	# 3. Pivot Point Adjustment
	# To make the sprite rotate and squish from its feet/base (0,0) rather than its center,
	# we offset the texture upward by half its height while keeping the node at (0,0).
	var tex_size = visual.texture.get_size()
	visual.centered = true
	visual.scale = base_scale
	visual.offset = Vector2(0, -tex_size.y / 2.0)

func update_lean(balance: float) -> void:
	self.rotation_degrees = (balance - 50.0) * 0.8 

func squish_juice() -> void:
	# Because we offset the sprite texture, scaling 'visual' scales beautifully from the bottom up!
	var scale_tween = create_tween()
	scale_tween.tween_property(visual, "scale", base_scale * Vector2(0.95, 1.05), 0.05)
	scale_tween.tween_property(visual, "scale", base_scale, 0.1)

func fall_over(balance: float) -> void:
	var fall_direction: float = -1.0 if balance < 50.0 else 1.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "rotation_degrees", fall_direction * 90.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", self.position.y + 100.0, 0.35)

func celebrate_win() -> void:
	var tween = create_tween()
	# 4. Changed 'color' to 'modulate' (which is how you tint Sprites in Godot)
	tween.tween_property(visual, "modulate", Color(0.2, 0.9, 0.2), 0.2)
	tween.tween_property(self, "position:x", self.position.x + 800.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
