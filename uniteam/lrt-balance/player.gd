class_name PlayerCharacter extends Node2D

var visual: ColorRect

func _init() -> void:
	self.position = Vector2(640, 720) # Root acts as the pivot at the bottom center
	
	visual = ColorRect.new()
	visual.color = Color(0.9, 0.7, 0.2)
	visual.set_size(Vector2(140, 350))
	visual.position = Vector2(-70, -350) 
	add_child(visual)
	
	var face = ColorRect.new()
	face.color = Color(0.1, 0.1, 0.1)
	face.set_size(Vector2(80, 40))
	face.position = Vector2(30, 40)
	visual.add_child(face)

func update_lean(balance: float) -> void:
	self.rotation_degrees = (balance - 50.0) * 0.8 

func squish_juice() -> void:
	var scale_tween = create_tween()
	scale_tween.tween_property(visual, "scale", Vector2(0.95, 1.05), 0.05)
	scale_tween.tween_property(visual, "scale", Vector2(1.0, 1.0), 0.1)

func fall_over(balance: float) -> void:
	var fall_direction: float = -1.0 if balance < 50.0 else 1.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "rotation_degrees", fall_direction * 90.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", self.position.y + 100.0, 0.35)

func celebrate_win() -> void:
	var tween = create_tween()
	tween.tween_property(visual, "color", Color(0.2, 0.9, 0.2), 0.2)
	tween.tween_property(self, "position:x", self.position.x + 800.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
