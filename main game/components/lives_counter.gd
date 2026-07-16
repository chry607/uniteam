class_name LivesCounter
extends HBoxContainer
## Heart / bean lives with shake on loss.

@export var max_lives: int = 3
@export var use_beans: bool = true

var _icons: Array[Control] = []
var _current: int = 3


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_rebuild()
	ScoreManager.lives_changed.connect(set_lives)
	set_lives(ScoreManager.lives)


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_icons.clear()
	for i in max_lives:
		var icon := _make_icon()
		add_child(icon)
		_icons.append(icon)


func _make_icon() -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(44, 44)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var draw := LivesIconDraw.new()
	draw.use_bean = use_beans
	draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(draw)
	return wrap


func set_lives(lives: int) -> void:
	var prev := _current
	_current = clampi(lives, 0, max_lives)
	for i in _icons.size():
		var draw: LivesIconDraw = _icons[i].get_child(0)
		draw.alive = i < _current
		draw.queue_redraw()
		if i >= _current and i < prev:
			_shake(_icons[i])


func _shake(node: Control) -> void:
	# Flash red even when screen shake is off; only skip position jitter.
	var origin := node.position
	var tw := create_tween()
	if UIManager == null or UIManager.screen_shake_enabled:
		for _i in 5:
			tw.tween_property(node, "position", origin + Vector2(randf_range(-6, 6), randf_range(-4, 4)), 0.04)
		tw.tween_property(node, "position", origin, 0.04)
		tw.parallel().tween_property(node, "modulate", Color(1, 0.4, 0.4), 0.08)
	else:
		tw.tween_property(node, "modulate", Color(1, 0.4, 0.4), 0.08)
	tw.tween_property(node, "modulate", Color.WHITE, 0.2)


class LivesIconDraw extends Control:
	var alive: bool = true
	var use_bean: bool = true

	func _draw() -> void:
		var c := size / 2.0
		if use_bean:
			var col := Palette.BLUE_BEAN if alive else Palette.HEART_LOST
			draw_circle(c + Vector2(0, 2), 16, Palette.OUTLINE)
			draw_circle(c, 14, col)
			if alive:
				draw_circle(c + Vector2(-5, -3), 2.5, Palette.OUTLINE)
				draw_circle(c + Vector2(5, -3), 2.5, Palette.OUTLINE)
				draw_arc(c + Vector2(0, 3), 5, 0.2, PI - 0.2, 12, Palette.OUTLINE, 2.0, true)
			else:
				# X eyes
				draw_line(c + Vector2(-8, -6), c + Vector2(-2, 0), Palette.OUTLINE, 2.5)
				draw_line(c + Vector2(-8, 0), c + Vector2(-2, -6), Palette.OUTLINE, 2.5)
				draw_line(c + Vector2(2, -6), c + Vector2(8, 0), Palette.OUTLINE, 2.5)
				draw_line(c + Vector2(2, 0), c + Vector2(8, -6), Palette.OUTLINE, 2.5)
		else:
			var col := Palette.HEART_RED if alive else Palette.HEART_LOST
			_draw_heart(c, 16, Palette.OUTLINE)
			_draw_heart(c, 13, col)

	func _draw_heart(c: Vector2, r: float, col: Color) -> void:
		draw_circle(c + Vector2(-r * 0.35, -r * 0.15), r * 0.45, col)
		draw_circle(c + Vector2(r * 0.35, -r * 0.15), r * 0.45, col)
		var pts := PackedVector2Array([
			c + Vector2(-r * 0.75, -r * 0.05),
			c + Vector2(0, r * 0.85),
			c + Vector2(r * 0.75, -r * 0.05),
		])
		draw_colored_polygon(pts, col)
