class_name FilipinoStreet
extends Node2D
## Animated Filipino neighborhood: jeepneys, wires, clouds, dogs, sari-sari, tricycle.

@export var busy: bool = true
@export var show_characters: bool = true

var _time: float = 0.0
var _viewport_size := Vector2(1920, 1080)

# Parallax elements
var _clouds: Array[Dictionary] = []
var _jeep_x: float = -200.0
var _tricycle_x: float = 2200.0
var _dog_x: float = 400.0
var _dog_dir: float = 1.0
var _wire_phase: float = 0.0
var _ped_phase: float = 0.0


func _ready() -> void:
	_viewport_size = get_viewport_rect().size
	_init_clouds()
	set_process(true)
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	_viewport_size = get_viewport_rect().size
	queue_redraw()


func _init_clouds() -> void:
	_clouds.clear()
	for i in 5:
		_clouds.append({
			"x": randf() * 2000.0,
			"y": 40.0 + randf() * 160.0,
			"s": 0.6 + randf() * 0.8,
			"spd": 12.0 + randf() * 22.0,
		})


func _process(delta: float) -> void:
	_time += delta
	_wire_phase = sin(_time * 1.4) * 6.0
	_ped_phase = sin(_time * 2.0) * 3.0
	if busy:
		_jeep_x += 90.0 * delta
		if _jeep_x > _viewport_size.x + 250.0:
			_jeep_x = -280.0
		_tricycle_x -= 110.0 * delta
		if _tricycle_x < -200.0:
			_tricycle_x = _viewport_size.x + 200.0
		_dog_x += 40.0 * delta * _dog_dir
		if _dog_x > _viewport_size.x - 100.0:
			_dog_dir = -1.0
		elif _dog_x < 80.0:
			_dog_dir = 1.0
		for c in _clouds:
			c.x += c.spd * delta
			if c.x > _viewport_size.x + 120.0:
				c.x = -150.0
				c.y = 40.0 + randf() * 160.0
	queue_redraw()


## Named layout guides derived from the current viewport.
## Used by drawing and by shell presentation property checks.
func get_layout_guides(w: float = -1.0, h: float = -1.0) -> Dictionary:
	if w < 0.0:
		w = _viewport_size.x
	if h < 0.0:
		h = _viewport_size.y
	var road_y := h * 0.72
	var sidewalk_top := road_y - 28.0
	var ground_baseline := road_y
	var edge_safe := 36.0
	# Deliberate center safe region keeps a bounded gap (< 45% of width)
	# while leaving room for title/play controls and bean characters.
	var center_safe_half := clampf(w * 0.16, 220.0, 360.0)
	var center_x := w * 0.5
	return {
		"viewport_w": w,
		"viewport_h": h,
		"skyline_base": h * 0.48,
		"sidewalk_top": sidewalk_top,
		"road_y": road_y,
		"ground_baseline": ground_baseline,
		"edge_safe": edge_safe,
		"center_safe_left": center_x - center_safe_half,
		"center_safe_right": center_x + center_safe_half,
	}


## Same-plane midground buildings, bottoms on the shared ground baseline.
## Left and right masses sit outside the center-safe region for balanced weight.
func get_midground_building_rects(w: float = -1.0, h: float = -1.0) -> Array[Rect2]:
	var g := get_layout_guides(w, h)
	var baseline: float = g.ground_baseline
	var edge: float = g.edge_safe
	var left_end: float = g.center_safe_left
	var right_start: float = g.center_safe_right
	var vw: float = g.viewport_w

	# Left mass: taller storefront-adjacent block near the edge, companion toward center.
	# Keep horizontal overlap with the near-plane karinderya under half the building width.
	var l1_w := 100.0
	var l1_h := 280.0
	var l1_x := edge
	var l2_w := 130.0
	var l2_h := 230.0
	var l2_x := left_end - l2_w - 16.0
	if l2_x < l1_x + l1_w + 20.0:
		l2_x = l1_x + l1_w + 20.0

	# Right mass: mirror the left visual weight inside the right band.
	var r2_w := 100.0
	var r2_h := 300.0
	var r2_x := vw - edge - r2_w
	var r1_w := 130.0
	var r1_h := 250.0
	var r1_x := right_start + 16.0
	if r1_x + r1_w + 20.0 > r2_x:
		r1_x = r2_x - r1_w - 20.0

	return [
		Rect2(l1_x, baseline - l1_h, l1_w, l1_h),
		Rect2(l2_x, baseline - l2_h, l2_w, l2_h),
		Rect2(r1_x, baseline - r1_h, r1_w, r1_h),
		Rect2(r2_x, baseline - r2_h, r2_w, r2_h),
	]


## Near-plane storefronts (drawn after road/sidewalk for intentional occlusion).
func get_storefront_rects(w: float = -1.0, h: float = -1.0) -> Dictionary:
	var g := get_layout_guides(w, h)
	var road_y: float = g.road_y
	var vw: float = g.viewport_w
	# Karinderya sits in front of the left mass but only partially overlaps building 0.
	var karinderya := Rect2(88.0, road_y - 160.0, 200.0, 160.0)
	var sari_sari := Rect2(vw - 320.0, road_y - 200.0, 260.0, 200.0)
	return {
		"karinderya": karinderya,
		"sari_sari": sari_sari,
	}


## Explicit painter's order layers for back-to-front occlusion.
func get_draw_layer_order() -> PackedStringArray:
	return PackedStringArray([
		"sky",
		"distant_skyline",
		"clouds",
		"midground_buildings",
		"wires",
		"road_and_sidewalk",
		"near_storefronts",
		"vehicles_and_dog",
		"characters",
	])


func _draw() -> void:
	var w := _viewport_size.x
	var h := _viewport_size.y
	var guides := get_layout_guides(w, h)
	var road_y: float = guides.road_y

	# Painter's order (back → front): sky, distant skyline, clouds,
	# midground buildings, wires, road/sidewalk, near storefronts,
	# vehicles/dog, characters.

	# 1. Sky gradient-ish bands (flat, not glass)
	draw_rect(Rect2(0, 0, w, h * 0.55), Palette.SKY)
	draw_rect(Rect2(0, h * 0.42, w, h * 0.15), Palette.SKY_LIGHT)

	# 2. Distant city silhouettes
	_draw_skyline(w, h)

	# 3. Clouds
	for c in _clouds:
		_draw_cloud(Vector2(c.x, c.y), c.s)

	# 4. Midground buildings (shared ground baseline)
	_draw_buildings(w, h)

	# 5. Electric wires
	_draw_wires(w, h)

	# 6. Road + sidewalk (shared ground plane)
	draw_rect(Rect2(0, road_y, w, h - road_y), Palette.STREET)
	var dash := 60.0
	var gap := 40.0
	var x := fmod(_time * 80.0, dash + gap)
	while x < w:
		draw_rect(Rect2(x, road_y + (h - road_y) * 0.45, dash, 8), Palette.STREET_LINE)
		x += dash + gap

	draw_rect(Rect2(0, road_y - 28, w, 28), Color("A8A8A8"))
	draw_rect(Rect2(0, road_y - 30, w, 4), Palette.OUTLINE)

	# 7. Near storefronts (intentional foreground occlusion)
	var storefronts := get_storefront_rects(w, h)
	var sari: Rect2 = storefronts.sari_sari
	var kari: Rect2 = storefronts.karinderya
	_draw_sari_sari(sari.position, road_y)
	_draw_karinderya(kari.position, road_y)

	# 8. Moving vehicles + dog
	if busy:
		_draw_jeepney(Vector2(_jeep_x, road_y + 20))
		_draw_tricycle(Vector2(_tricycle_x, road_y + 40))
		_draw_dog(Vector2(_dog_x, road_y - 8), _dog_dir)

	# 9. Idle bean characters
	if show_characters:
		_draw_bean_row(Vector2(w * 0.5, road_y - 10))


func _draw_skyline(w: float, h: float) -> void:
	var base: float = get_layout_guides(w, h).skyline_base
	var cols := [
		Color("9BB7C9"), Color("7FA3B8"), Color("A8C5D4"), Color("8EADC0")
	]
	var x := 0.0
	var i := 0
	while x < w:
		var bw := 60.0 + (i * 37 % 80)
		var bh := 80.0 + (i * 53 % 140)
		draw_rect(Rect2(x, base - bh, bw, bh + 20), cols[i % cols.size()])
		# Windows
		for wy in range(3):
			for wx in range(2):
				if (i + wx + wy) % 3 != 0:
					draw_rect(Rect2(x + 10 + wx * 22, base - bh + 12 + wy * 28, 12, 14), Color("F5E6A3"))
		x += bw + 8
		i += 1


func _draw_cloud(pos: Vector2, s: float) -> void:
	var r := 28.0 * s
	draw_circle(pos, r, Palette.CLOUD)
	draw_circle(pos + Vector2(r * 0.9, 4), r * 0.85, Palette.CLOUD)
	draw_circle(pos + Vector2(-r * 0.8, 6), r * 0.7, Palette.CLOUD)
	draw_circle(pos + Vector2(r * 0.2, -r * 0.4), r * 0.65, Palette.CLOUD)


func _draw_buildings(w: float, h: float) -> void:
	var buildings := get_midground_building_rects(w, h)
	var colors: Array[Color] = [
		Palette.BUILDING_A, Palette.BUILDING_B, Palette.BUILDING_C, Palette.BUILDING_D
	]
	var signs: Array[String] = ["LUTONG", "", "", ""]
	for i in buildings.size():
		_draw_building(buildings[i], colors[i], signs[i])


func _draw_building(rect: Rect2, color: Color, sign_text: String) -> void:
	draw_rect(rect, color)
	draw_rect(rect, Palette.OUTLINE, false, 4.0)
	# Roof
	var roof := PackedVector2Array([
		rect.position + Vector2(-8, 10),
		rect.position + Vector2(rect.size.x / 2, -20),
		rect.position + Vector2(rect.size.x + 8, 10),
	])
	draw_colored_polygon(roof, Color("C0392B"))
	draw_polyline(roof + PackedVector2Array([roof[0]]), Palette.OUTLINE, 3.0, true)
	# Windows
	for row in 3:
		for col in 2:
			var wr := Rect2(rect.position.x + 18 + col * 50, rect.position.y + 40 + row * 55, 32, 36)
			draw_rect(wr, Color("FDF2D0"))
			draw_rect(wr, Palette.OUTLINE, false, 2.5)
	if sign_text != "":
		var sr := Rect2(rect.position.x + 10, rect.end.y - 50, rect.size.x - 20, 30)
		draw_rect(sr, Palette.ORANGE_RIBBON)
		draw_rect(sr, Palette.OUTLINE, false, 2.0)


func _draw_wires(w: float, h: float) -> void:
	var y := h * 0.22
	# Poles
	for px in [120.0, w * 0.35, w * 0.65, w - 140.0]:
		draw_line(Vector2(px, y - 40), Vector2(px, h * 0.72 - 30), Palette.WIRE, 5.0)
		draw_line(Vector2(px - 20, y - 30), Vector2(px + 20, y - 30), Palette.WIRE, 4.0)
	# Sagging wires with sway
	var points: PackedVector2Array = []
	var poles := [120.0, w * 0.35, w * 0.65, w - 140.0]
	for i in poles.size() - 1:
		var a := Vector2(poles[i], y - 30)
		var b := Vector2(poles[i + 1], y - 30)
		points.clear()
		for t_i in 12:
			var t := t_i / 11.0
			var mid := a.lerp(b, t)
			var sag := sin(t * PI) * (28.0 + _wire_phase)
			points.append(mid + Vector2(0, sag))
		draw_polyline(points, Palette.WIRE, 2.5, true)
		# Second wire
		var points2: PackedVector2Array = []
		for t_i in 12:
			var t := t_i / 11.0
			var mid := a.lerp(b, t)
			var sag := sin(t * PI) * (36.0 + _wire_phase * 0.7) + 8
			points2.append(mid + Vector2(0, sag))
		draw_polyline(points2, Palette.WIRE, 2.0, true)


func _draw_sari_sari(pos: Vector2, road_y: float) -> void:
	var body := Rect2(pos.x, pos.y, 260, road_y - pos.y)
	draw_rect(body, Color("F5CBA7"))
	draw_rect(body, Palette.OUTLINE, false, 4.0)
	# Awning
	draw_rect(Rect2(pos.x - 10, pos.y, 280, 36), Color("E74C3C"))
	draw_rect(Rect2(pos.x - 10, pos.y, 280, 36), Palette.OUTLINE, false, 3.0)
	# Stripes
	for i in 7:
		if i % 2 == 0:
			draw_rect(Rect2(pos.x - 10 + i * 40, pos.y, 40, 36), Color("F1C40F"))
	# Sign LOAD NA DITO
	var sign := Rect2(pos.x + 20, pos.y + 50, 220, 50)
	draw_rect(sign, Palette.YELLOW)
	draw_rect(sign, Palette.OUTLINE, false, 4.0)
	# Shelves blobs
	var shelf_colors: Array[Color] = [
		Palette.ORANGE, Palette.TEAL, Palette.PINK_BEAN, Palette.GREEN_BEAN, Palette.BLUE_BEAN
	]
	for row in 3:
		for col in 4:
			var colr: Color = shelf_colors[(row + col) % 5]
			draw_rect(Rect2(pos.x + 30 + col * 50, pos.y + 120 + row * 40, 36, 28), colr)
			draw_rect(Rect2(pos.x + 30 + col * 50, pos.y + 120 + row * 40, 36, 28), Palette.OUTLINE, false, 2.0)


func _draw_karinderya(pos: Vector2, road_y: float) -> void:
	var body := Rect2(pos.x, pos.y, 200, road_y - pos.y)
	draw_rect(body, Color("FAD7A0"))
	draw_rect(body, Palette.OUTLINE, false, 4.0)
	draw_rect(Rect2(pos.x - 8, pos.y - 10, 216, 28), Color("27AE60"))
	draw_rect(Rect2(pos.x - 8, pos.y - 10, 216, 28), Palette.OUTLINE, false, 3.0)
	# Pots
	for i in 3:
		var cx := pos.x + 40 + i * 55
		var cy := pos.y + 90
		draw_circle(Vector2(cx, cy), 22, Palette.OUTLINE)
		draw_circle(Vector2(cx, cy), 18, Color("BDC3C7"))
		draw_circle(Vector2(cx, cy - 8), 10, Color("E67E22"))


func _draw_jeepney(pos: Vector2) -> void:
	# Body
	var body := Rect2(pos.x, pos.y, 200, 70)
	draw_rect(Rect2(body.position.x, body.position.y + 10, body.size.x, 50), Palette.JEEPNEY_GREEN)
	draw_rect(Rect2(body.position.x, body.position.y + 10, body.size.x, 50), Palette.OUTLINE, false, 4.0)
	# Roof
	draw_rect(Rect2(pos.x + 10, pos.y, 160, 18), Palette.JEEPNEY_YELLOW)
	draw_rect(Rect2(pos.x + 10, pos.y, 160, 18), Palette.OUTLINE, false, 3.0)
	# Windows
	for i in 3:
		draw_rect(Rect2(pos.x + 30 + i * 45, pos.y + 22, 36, 24), Color("AED6F1"))
		draw_rect(Rect2(pos.x + 30 + i * 45, pos.y + 22, 36, 24), Palette.OUTLINE, false, 2.0)
	# Wheels
	_draw_wheel(Vector2(pos.x + 40, pos.y + 70), 16)
	_draw_wheel(Vector2(pos.x + 160, pos.y + 70), 16)
	# Plate
	draw_rect(Rect2(pos.x + 70, pos.y + 48, 60, 16), Palette.WHITE)
	draw_rect(Rect2(pos.x + 70, pos.y + 48, 60, 16), Palette.OUTLINE, false, 2.0)


func _draw_tricycle(pos: Vector2) -> void:
	draw_circle(Vector2(pos.x + 30, pos.y + 40), 28, Palette.OUTLINE)
	draw_circle(Vector2(pos.x + 30, pos.y + 40), 24, Palette.ORANGE)
	draw_rect(Rect2(pos.x + 50, pos.y + 20, 70, 40), Palette.TEAL)
	draw_rect(Rect2(pos.x + 50, pos.y + 20, 70, 40), Palette.OUTLINE, false, 3.0)
	_draw_wheel(Vector2(pos.x + 20, pos.y + 65), 14)
	_draw_wheel(Vector2(pos.x + 100, pos.y + 65), 14)


func _draw_wheel(c: Vector2, r: float) -> void:
	draw_circle(c, r, Palette.OUTLINE)
	draw_circle(c, r * 0.7, Color("333333"))
	draw_circle(c, r * 0.25, Palette.YELLOW)


func _draw_dog(pos: Vector2, dir: float) -> void:
	var flip := 1.0 if dir > 0 else -1.0
	var body_col := Color("D4A574")
	draw_circle(pos + Vector2(0, 0), 14, Palette.OUTLINE)
	draw_circle(pos, 12, body_col)
	draw_circle(pos + Vector2(14 * flip, -6), 9, Palette.OUTLINE)
	draw_circle(pos + Vector2(14 * flip, -6), 7, body_col)
	# Legs bounce
	var leg := sin(_time * 10.0) * 3.0
	draw_line(pos + Vector2(-6, 8), pos + Vector2(-8, 18 + leg), Palette.OUTLINE, 3.0)
	draw_line(pos + Vector2(6, 8), pos + Vector2(8, 18 - leg), Palette.OUTLINE, 3.0)


func _draw_bean_row(center: Vector2) -> void:
	var beans := [
		{"c": Palette.GREEN_BEAN, "ox": -220.0},
		{"c": Palette.PURPLE_BEAN, "ox": -110.0},
		{"c": Palette.BLUE_BEAN, "ox": 0.0},
		{"c": Palette.YELLOW_BEAN, "ox": 110.0},
		{"c": Palette.PINK_BEAN, "ox": 220.0},
	]
	for i in beans.size():
		var b: Dictionary = beans[i]
		var bob := sin(_time * 2.5 + i * 0.8) * 6.0
		_draw_bean(center + Vector2(b.ox, bob - 50), b.c, i)


func _draw_bean(pos: Vector2, color: Color, variant: int) -> void:
	# Body
	draw_circle(pos + Vector2(0, 8), 36, Palette.OUTLINE)
	draw_circle(pos + Vector2(0, 6), 32, color)
	# Eyes
	draw_circle(pos + Vector2(-10, 0), 5, Palette.OUTLINE)
	draw_circle(pos + Vector2(10, 0), 5, Palette.OUTLINE)
	draw_circle(pos + Vector2(-9, -1), 1.8, Palette.WHITE)
	draw_circle(pos + Vector2(11, -1), 1.8, Palette.WHITE)
	# Smile
	draw_arc(pos + Vector2(0, 8), 10, 0.15, PI - 0.15, 12, Palette.OUTLINE, 3.0, true)
	# Accessories
	match variant:
		0: # Green - salakot-ish bucket hat
			draw_circle(pos + Vector2(0, -28), 18, Palette.OUTLINE)
			draw_circle(pos + Vector2(0, -28), 15, Color("C4A35A"))
			draw_rect(Rect2(pos.x - 22, pos.y - 28, 44, 8), Color("A67C52"))
		1: # Purple - curly hair
			for ox in [-16, -6, 6, 16]:
				draw_circle(pos + Vector2(ox, -24), 10, Palette.OUTLINE)
				draw_circle(pos + Vector2(ox, -24), 8, Color("4A2C6A"))
		2: # Blue - big salakot
			var hat := PackedVector2Array([
				pos + Vector2(-40, -18),
				pos + Vector2(0, -48),
				pos + Vector2(40, -18),
			])
			draw_colored_polygon(hat, Color("C4A35A"))
			draw_polyline(hat + PackedVector2Array([hat[0]]), Palette.OUTLINE, 3.0, true)
			draw_circle(pos + Vector2(0, -22), 12, Color("E8C97A"))
		3: # Yellow - hair tuft
			draw_circle(pos + Vector2(-8, -30), 8, Palette.OUTLINE)
			draw_circle(pos + Vector2(-8, -30), 6, Color("2C2C2C"))
			draw_circle(pos + Vector2(6, -28), 7, Palette.OUTLINE)
			draw_circle(pos + Vector2(6, -28), 5, Color("2C2C2C"))
		4: # Pink - flower + flag
			draw_circle(pos + Vector2(20, -26), 10, Palette.OUTLINE)
			draw_circle(pos + Vector2(20, -26), 8, Palette.WHITE)
			draw_circle(pos + Vector2(20, -26), 3, Palette.YELLOW)
			# Mini flag
			draw_line(pos + Vector2(28, 0), pos + Vector2(28, -30), Palette.OUTLINE, 2.5)
			draw_rect(Rect2(pos.x + 28, pos.y - 30, 22, 14), Color("0038A8"))
			draw_rect(Rect2(pos.x + 28, pos.y - 16, 22, 7), Color("CE1126"))
