class_name FontRegistry
extends RefCounted
## Lazy-loaded cartoon fonts.

static var _title: FontFile
static var _ui: FontFile
static var _ui_black: FontFile
static var _display: FontFile


static func title() -> Font:
	if _title == null:
		_title = load("res://assets/fonts/Fredoka-Bold.ttf") as FontFile
	return _title


static func ui() -> Font:
	if _ui == null:
		_ui = load("res://assets/fonts/Nunito-ExtraBold.ttf") as FontFile
	return _ui


static func ui_black() -> Font:
	if _ui_black == null:
		_ui_black = load("res://assets/fonts/Nunito-Black.ttf") as FontFile
	return _ui_black


static func display() -> Font:
	if _display == null:
		_display = load("res://assets/fonts/Baloo2-ExtraBold.ttf") as FontFile
	return _display


static func apply_title(label: Label, size: int = 72, color: Color = Palette.TEXT_LIGHT, outline: bool = true) -> void:
	label.add_theme_font_override("font", title())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if outline:
		label.add_theme_color_override("font_outline_color", Palette.OUTLINE)
		label.add_theme_constant_override("outline_size", max(4, size / 12))


static func apply_ui(label: Label, size: int = 28, color: Color = Palette.TEXT_DARK, outline: bool = false) -> void:
	label.add_theme_font_override("font", ui())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if outline:
		label.add_theme_color_override("font_outline_color", Palette.OUTLINE)
		label.add_theme_constant_override("outline_size", max(3, size / 14))


static func apply_display(label: Label, size: int = 96, color: Color = Palette.YELLOW, outline: bool = true) -> void:
	label.add_theme_font_override("font", display())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if outline:
		label.add_theme_color_override("font_outline_color", Palette.OUTLINE)
		label.add_theme_constant_override("outline_size", max(5, size / 10))


static func apply_button(btn: Button, size: int = 36) -> void:
	btn.add_theme_font_override("font", ui_black())
	btn.add_theme_font_size_override("font_size", size)
	btn.add_theme_color_override("font_color", Palette.TEXT_DARK)
	btn.add_theme_color_override("font_hover_color", Palette.TEXT_DARK)
	btn.add_theme_color_override("font_pressed_color", Palette.TEXT_DARK)
	btn.add_theme_color_override("font_focus_color", Palette.TEXT_DARK)
