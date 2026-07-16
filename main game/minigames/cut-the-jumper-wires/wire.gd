extends Node2D

@export var point_a: Vector2
@export var point_b: Vector2
@export var width: float = 10.0
@export var hit_tolerance: float = 20.0
@export var min_cut_separation: float = 0.15
@export var gap_size: float = 26.0
@export var cuts_needed: int = 2

var wire_color: Color = Color.RED
var current_color: Color = Color.WHITE
var wire_texture: Texture2D = null
var is_target: bool = true
var cut_ts: Array = []
var severed: bool = false
var segment_lines: Array = []
var _ready_done := false

func _dir() -> Vector2:
	return (point_b - point_a).normalized()

func _len() -> float:
	return point_a.distance_to(point_b)

func project(global_pos: Vector2) -> Dictionary:
	var local_pos = to_local(global_pos)
	var dir = _dir()
	var len = _len()
	var t_raw = (local_pos - point_a).dot(dir) / len
	var t = clamp(t_raw, 0.0, 1.0)
	var closest = point_a + dir * t * len
	return {"t": t, "distance": local_pos.distance_to(closest)}

# Returns: "trap", "too_close", "cut", "severed"
func try_cut(global_pos: Vector2) -> String:
	var p = project(global_pos)
	
	if not is_target:
		cut_ts.append(p.t)
		_redraw_segments()
		return "trap"
		
	for existing_t in cut_ts:
		if abs(p.t - existing_t) < min_cut_separation:
			return "too_close"
	
	cut_ts.append(p.t)
	_redraw_segments()          # <-- changed from queue_redraw()
	if cut_ts.size() >= cuts_needed:
		severed = true
		return "severed"
	return "cut"

func _ready():
	_ready_done = true
	for i in range(cuts_needed + 1):
		var l = Line2D.new()
		l.width = width
		l.begin_cap_mode = Line2D.LINE_CAP_ROUND
		l.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(l)
		segment_lines.append(l)
	_apply_texture()
	_redraw_segments()

# texture is optional — pass null to fall back to a plain colored line
func setup(a: Vector2, b: Vector2, color: Color, target: bool, texture: Texture2D = null):
	point_a = a
	point_b = b
	wire_color = color
	is_target = target
	wire_texture = texture
	if _ready_done:
		_apply_texture()
		_redraw_segments()

func _apply_texture():
	for l in segment_lines:
		l.texture = wire_texture
		l.texture_mode = Line2D.LINE_TEXTURE_TILE if wire_texture else Line2D.LINE_TEXTURE_NONE

func show_color():
	current_color = wire_color
	_redraw_segments()

func hide_color():
	current_color = Color.WHITE
	_redraw_segments()

func _set_segment(index: int, a: Vector2, b: Vector2):
	var l = segment_lines[index]
	l.visible = true
	l.default_color = current_color
	l.points = PackedVector2Array([a, b])

func _redraw_segments():
	if segment_lines.is_empty():
		return
	var dir = _dir()
	var len = _len()
	for l in segment_lines:
		l.visible = false

	if cut_ts.is_empty():
		_set_segment(0, point_a, point_b)
		return

	if cut_ts.size() < cuts_needed:
		var sorted_ts = cut_ts.duplicate()
		sorted_ts.sort()
		var gap_t = gap_size / len
		var prev_end = 0.0
		var idx = 0
		for t in sorted_ts:
			var seg_end_t = clamp(t - gap_t / 2.0, prev_end, 1.0)
			_set_segment(idx, point_a + dir * prev_end * len, point_a + dir * seg_end_t * len)
			idx += 1
			prev_end = clamp(t + gap_t / 2.0, 0.0, 1.0)
		_set_segment(idx, point_a + dir * prev_end * len, point_b)
		return

	var sorted_ts = cut_ts.duplicate()
	sorted_ts.sort()
	var first_t = sorted_ts[0]
	var last_t = sorted_ts[sorted_ts.size() - 1]
	var half_gap_t = (gap_size / 2.0) / len
	var left_end_t = clamp(first_t - half_gap_t, 0.0, 1.0)
	var right_start_t = clamp(last_t + half_gap_t, 0.0, 1.0)
	_set_segment(0, point_a, point_a + dir * left_end_t * len)
	_set_segment(1, point_a + dir * right_start_t * len, point_b)
	
