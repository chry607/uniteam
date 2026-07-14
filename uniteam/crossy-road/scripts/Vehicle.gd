extends Area2D
class_name RoadVehicle

enum VehicleType { JEEPNEY, TRICYCLE, MULTICAB, MOTORCYCLE }

var speed := 150.0
var direction := 1
var vehicle_type: int = VehicleType.TRICYCLE
var lane_width := 900.0  # distance from center before despawning

func _ready() -> void:
	add_to_group("hazard")
	monitoring = true
	monitorable = true
	_build_collision()
	queue_redraw()

func _build_collision() -> void:
	var shape := RectangleShape2D.new()
	match vehicle_type:
		VehicleType.JEEPNEY:
			shape.size = Vector2(150, 60)
		VehicleType.TRICYCLE:
			shape.size = Vector2(80, 55)
		VehicleType.MULTICAB:
			shape.size = Vector2(110, 60)
		VehicleType.MOTORCYCLE:
			shape.size = Vector2(60, 40)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

func _process(delta: float) -> void:
	position.x += speed * direction * delta
	if abs(position.x) > lane_width:
		queue_free()

func _draw() -> void:
	var flip := direction
	match vehicle_type:
		VehicleType.JEEPNEY:
			draw_rect(Rect2(-75, -30, 150, 60), Color8(220, 40, 40))
			draw_rect(Rect2(-75, -30, 150, 14), Color8(255, 210, 0))
			draw_rect(Rect2(-75, 16, 150, 14), Color8(255, 210, 0))
			draw_circle(Vector2(-45 * flip, 32), 12, Color8(20, 20, 20))
			draw_circle(Vector2(45 * flip, 32), 12, Color8(20, 20, 20))
		VehicleType.TRICYCLE:
			draw_rect(Rect2(-40, -22, 80, 44), Color8(30, 140, 220))
			draw_rect(Rect2(10 * flip, -30, 30, 60), Color8(240, 240, 240))
			draw_circle(Vector2(-25 * flip, 26), 10, Color8(20, 20, 20))
			draw_circle(Vector2(25 * flip, 26), 10, Color8(20, 20, 20))
		VehicleType.MULTICAB:
			draw_rect(Rect2(-55, -28, 110, 56), Color8(60, 170, 90))
			draw_circle(Vector2(-30 * flip, 30), 11, Color8(20, 20, 20))
			draw_circle(Vector2(30 * flip, 30), 11, Color8(20, 20, 20))
		VehicleType.MOTORCYCLE:
			draw_rect(Rect2(-28, -14, 56, 28), Color8(240, 120, 30))
			draw_circle(Vector2(-22 * flip, 16), 8, Color8(20, 20, 20))
			draw_circle(Vector2(22 * flip, 16), 8, Color8(20, 20, 20))
