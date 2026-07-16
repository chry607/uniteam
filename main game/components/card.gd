class_name GameCard
extends PanelContainer
## Cream card with thick outline and soft shadow.


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleFactory.card())
