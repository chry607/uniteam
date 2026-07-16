class_name SettingsScreen
extends Control
## Settings modal: master/music/SFX volume and screen shake. Values apply live and persist.

signal closed

var _panel: PanelContainer
var _master: HSlider
var _music: HSlider
var _sfx: HSlider
var _shake_check: CheckButton
var _master_value: Label
var _music_value: Label
var _sfx_value: Label
var _suppress_save := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS

	var overlay := ColorRect.new()
	overlay.color = Palette.OVERLAY_DARK
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", StyleFactory.modal_panel())
	_panel.custom_minimum_size = Vector2(560, 480)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	margin.add_child(v)

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_display(title, 48, Palette.TEXT_DARK, true)
	v.add_child(title)

	_master = _add_slider(v, "Master Volume", 0.8)
	_master_value = _master.get_meta("value_label") as Label
	_music = _add_slider(v, "Music", 0.7)
	_music_value = _music.get_meta("value_label") as Label
	_sfx = _add_slider(v, "SFX", 0.9)
	_sfx_value = _sfx.get_meta("value_label") as Label

	var shake_row := HBoxContainer.new()
	shake_row.add_theme_constant_override("separation", 12)
	_shake_check = CheckButton.new()
	_shake_check.text = "Screen Shake"
	_shake_check.focus_mode = Control.FOCUS_ALL
	_shake_check.button_pressed = true
	_shake_check.add_theme_font_override("font", FontRegistry.ui())
	_shake_check.add_theme_font_size_override("font_size", 24)
	_shake_check.add_theme_color_override("font_color", Palette.TEXT_DARK)
	_shake_check.add_theme_color_override("font_pressed_color", Palette.TEXT_DARK)
	_shake_check.add_theme_color_override("font_hover_color", Palette.TEXT_DARK)
	_shake_check.add_theme_color_override("font_hover_pressed_color", Palette.TEXT_DARK)
	_shake_check.add_theme_color_override("font_focus_color", Palette.TEXT_DARK)
	_shake_check.process_mode = Node.PROCESS_MODE_ALWAYS
	# Keep toggles from bubbling into pause/menu handlers while settings is open.
	_shake_check.mouse_filter = Control.MOUSE_FILTER_STOP
	shake_row.add_child(_shake_check)
	v.add_child(shake_row)

	var note := Label.new()
	note.text = "Changes apply immediately and are saved."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontRegistry.apply_ui(note, 16, Palette.OUTLINE_SOFT)
	v.add_child(note)

	var back := GameButton.new()
	back.text = "BACK"
	back.button_id = "settings_back"
	back.variant = GameButton.Style.PRIMARY
	back.base_font_size = 28
	back.custom_minimum_size = Vector2(200, 60)
	back.process_mode = Node.PROCESS_MODE_ALWAYS
	back.pressed.connect(func(): closed.emit())
	var bw := CenterContainer.new()
	bw.add_child(back)
	v.add_child(bw)

	_master.value_changed.connect(_on_master_changed)
	_music.value_changed.connect(_on_music_changed)
	_sfx.value_changed.connect(_on_sfx_changed)
	_sfx.drag_ended.connect(_on_sfx_drag_ended)
	_shake_check.toggled.connect(_on_shake_toggled)

	_sync_from_systems()
	visible = false


func _add_slider(parent: VBoxContainer, label: String, value: float) -> HSlider:
	var row := VBoxContainer.new()
	var header := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	FontRegistry.apply_ui(l, 22, Palette.TEXT_DARK)
	header.add_child(l)
	var value_label := Label.new()
	value_label.text = _pct(value)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	FontRegistry.apply_ui(value_label, 20, Palette.OUTLINE_SOFT)
	header.add_child(value_label)
	row.add_child(header)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(400, 28)
	s.process_mode = Node.PROCESS_MODE_ALWAYS
	s.set_meta("value_label", value_label)
	row.add_child(s)
	parent.add_child(row)
	return s


func _pct(value: float) -> String:
	return "%d%%" % int(round(value * 100.0))


func _sync_from_systems() -> void:
	_suppress_save = true
	if AudioController:
		_master.set_value_no_signal(AudioController.master_volume)
		_music.set_value_no_signal(AudioController.music_volume)
		_sfx.set_value_no_signal(AudioController.sfx_volume)
		_master_value.text = _pct(_master.value)
		_music_value.text = _pct(_music.value)
		_sfx_value.text = _pct(_sfx.value)
	if UIManager:
		# Avoid toggled signal loops that flip the control while syncing.
		_shake_check.set_pressed_no_signal(UIManager.screen_shake_enabled)
	_suppress_save = false


func _persist_all() -> void:
	if AudioController:
		AudioController.save_settings()
	if UIManager:
		UIManager.save_settings()


func _on_master_changed(value: float) -> void:
	_master_value.text = _pct(value)
	if _suppress_save or AudioController == null:
		return
	AudioController.set_master_volume(value)
	AudioController.save_settings()


func _on_music_changed(value: float) -> void:
	_music_value.text = _pct(value)
	if _suppress_save or AudioController == null:
		return
	AudioController.set_music_volume(value)
	AudioController.save_settings()


func _on_sfx_changed(value: float) -> void:
	_sfx_value.text = _pct(value)
	if _suppress_save or AudioController == null:
		return
	AudioController.set_sfx_volume(value)
	AudioController.save_settings()


func _on_sfx_drag_ended(value_changed: bool) -> void:
	# One preview blip when the user finishes adjusting SFX.
	if value_changed and not _suppress_save and AudioController and _sfx.value > 0.001:
		AudioController.play_round_win()


func _on_shake_toggled(pressed: bool) -> void:
	if _suppress_save or UIManager == null:
		return
	# Write flag only — do not re-sync the control from disk here.
	UIManager.screen_shake_enabled = pressed
	UIManager.save_settings()


func enter() -> void:
	_sync_from_systems()
	visible = true
	_panel.scale = Vector2(0.5, 0.5)
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioEvents.emit_menu_open("settings")


func exit() -> void:
	visible = false
	_persist_all()
	AudioEvents.emit_menu_close("settings")
