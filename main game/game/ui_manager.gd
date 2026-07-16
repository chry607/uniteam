extends Node
## Coordinates screen visibility, focus, notifications, and global UI helpers.

const SETTINGS_PATH := "user://settings.cfg"

signal notification_requested(message: String, duration: float)
signal shake_requested(intensity: float, duration: float)

var safe_margin := Vector2(24, 20)
var screen_shake_enabled: bool = true


func _ready() -> void:
	load_settings()


func notify(message: String, duration: float = 1.6) -> void:
	notification_requested.emit(message, duration)
	AudioEvents.emit_notification(message)


func shake(intensity: float = 8.0, duration: float = 0.25) -> void:
	if not screen_shake_enabled:
		return
	shake_requested.emit(intensity, duration)


func set_screen_shake_enabled(enabled: bool) -> void:
	screen_shake_enabled = enabled
	save_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	# ConfigFile may store bools as bool or 0/1 depending on writer.
	var raw: Variant = cfg.get_value("gameplay", "screen_shake", true)
	if raw is bool:
		screen_shake_enabled = raw
	elif raw is int or raw is float:
		screen_shake_enabled = int(raw) != 0
	else:
		screen_shake_enabled = str(raw).to_lower() in ["true", "1", "yes", "on"]


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("gameplay", "screen_shake", screen_shake_enabled)
	cfg.save(SETTINGS_PATH)


## Ease-out back overshoot helper for manual tweens (t 0..1 → eased)
static func ease_out_back(t: float, overshoot: float = 1.70158) -> float:
	t -= 1.0
	return t * t * ((overshoot + 1.0) * t + overshoot) + 1.0


static func ease_out_elastic(t: float) -> float:
	if t == 0.0 or t == 1.0:
		return t
	return pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * (2.0 * PI) / 3.0) + 1.0


func pop_in(node: CanvasItem, duration: float = 0.35, from_scale: float = 0.4) -> Tween:
	node.scale = Vector2.ONE * from_scale
	node.modulate.a = 0.0
	var tw := node.create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.5)
	AudioEvents.emit_ui_pop()
	return tw


func slide_in(node: Control, from: Vector2, duration: float = 0.35) -> Tween:
	var target := node.position
	node.position = from
	var tw := node.create_tween()
	tw.tween_property(node, "position", target, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioEvents.emit_ui_slide()
	return tw


func bounce_button(node: Control) -> void:
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(0.92, 0.92), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(1.06, 1.06), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func shake_node(node: CanvasItem, intensity: float = 10.0, duration: float = 0.3) -> void:
	if not screen_shake_enabled or node == null:
		return
	var origin: Vector2 = node.position
	var tw := node.create_tween()
	var steps := 6
	for i in steps:
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity * 0.5, intensity * 0.5))
		tw.tween_property(node, "position", origin + offset, duration / steps)
	tw.tween_property(node, "position", origin, 0.05)
