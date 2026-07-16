class_name StyleFactory
extends RefCounted
## Builds chunky cartoon StyleBoxFlat resources at runtime.


static func panel(bg: Color, border: Color = Palette.OUTLINE, border_w: int = 5, radius: int = 24, shadow: bool = true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(border_w)
	s.border_color = border
	s.set_corner_radius_all(radius)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	if shadow:
		s.shadow_color = Palette.SHADOW
		s.shadow_size = 8
		s.shadow_offset = Vector2(0, 5)
	return s


static func button_normal(bg: Color = Palette.YELLOW_BUTTON) -> StyleBoxFlat:
	var s := panel(bg, Palette.OUTLINE, 6, 28, true)
	s.content_margin_left = 36
	s.content_margin_right = 36
	s.content_margin_top = 18
	s.content_margin_bottom = 18
	s.shadow_offset = Vector2(0, 6)
	s.shadow_size = 0
	# Fake "chunky bottom" via border bottom thicker look — use expand
	return s


static func button_hover(bg: Color = Palette.YELLOW_BUTTON_HOVER) -> StyleBoxFlat:
	var s := button_normal(bg)
	s.shadow_offset = Vector2(0, 4)
	return s


static func button_pressed(bg: Color = Palette.YELLOW_BUTTON_PRESS) -> StyleBoxFlat:
	var s := button_normal(bg)
	s.shadow_offset = Vector2(0, 2)
	s.content_margin_top = 20
	s.content_margin_bottom = 16
	return s


static func button_secondary(bg: Color = Palette.CREAM) -> StyleBoxFlat:
	return button_normal(bg)


static func hud_chip(bg: Color = Color(1, 1, 1, 0.82)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(4)
	s.border_color = Palette.OUTLINE
	s.set_corner_radius_all(18)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.shadow_color = Palette.SHADOW
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 3)
	return s


static func modal_panel() -> StyleBoxFlat:
	return panel(Palette.CREAM, Palette.OUTLINE, 7, 32, true)


static func card() -> StyleBoxFlat:
	return panel(Palette.PAPER, Palette.OUTLINE, 5, 22, true)
