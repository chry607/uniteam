class_name GameHUD
extends CanvasLayer
## Always-on gameplay HUD: lives, timer, score, round. Thin, edge-anchored.

var lives: LivesCounter
var timer: TimerDisplay
var score: ScoreCounter
var round_label: Label
var _root: Control
var _top_bar: Control
## Center timer chip — only shown when the shell runs a countdown timer.
## Minigames use their own timers, so this stays hidden during normal play
## (avoids an empty white box in the top center).
var _timer_panel: PanelContainer


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Top bar container
	_top_bar = Control.new()
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_bottom = 120
	_top_bar.offset_left = 24
	_top_bar.offset_right = -24
	_top_bar.offset_top = 16
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_top_bar)

	# Lives — top left
	var lives_panel := PanelContainer.new()
	lives_panel.add_theme_stylebox_override("panel", StyleFactory.hud_chip())
	lives_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	lives_panel.position = Vector2(0, 0)
	_top_bar.add_child(lives_panel)
	lives = LivesCounter.new()
	lives_panel.add_child(lives)

	# Timer — top center (hidden until start_minigame_timer is used)
	_timer_panel = PanelContainer.new()
	_timer_panel.add_theme_stylebox_override("panel", StyleFactory.hud_chip(Color(1, 1, 1, 0.88)))
	_timer_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_timer_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_timer_panel.position = Vector2(0, 0)
	_timer_panel.anchor_left = 0.5
	_timer_panel.anchor_right = 0.5
	_timer_panel.offset_left = -70
	_timer_panel.offset_right = 70
	_timer_panel.offset_top = 0
	_timer_panel.offset_bottom = 100
	_timer_panel.visible = false
	_top_bar.add_child(_timer_panel)
	timer = TimerDisplay.new()
	timer.custom_minimum_size = Vector2(100, 80)
	_timer_panel.add_child(timer)

	# Score — top right
	var score_panel := PanelContainer.new()
	score_panel.add_theme_stylebox_override("panel", StyleFactory.hud_chip())
	score_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	score_panel.anchor_left = 1.0
	score_panel.anchor_right = 1.0
	score_panel.offset_left = -160
	score_panel.offset_right = 0
	score_panel.offset_top = 0
	score_panel.offset_bottom = 90
	_top_bar.add_child(score_panel)
	score = ScoreCounter.new()
	score_panel.add_child(score)

	# Round — under score-ish bottom of top left area
	round_label = Label.new()
	round_label.text = "ROUND 0"
	FontRegistry.apply_ui(round_label, 18, Palette.TEXT_DARK)
	round_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	round_label.position = Vector2(8, 70)
	_top_bar.add_child(round_label)
	ScoreManager.round_changed.connect(_on_round)
	_on_round(ScoreManager.current_round)

	visible = false


func show_hud() -> void:
	visible = true
	_top_bar.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_top_bar, "modulate:a", 1.0, 0.2)


func hide_hud() -> void:
	visible = false
	hide_shell_timer()


func start_minigame_timer(seconds: float = 4.0) -> void:
	if _timer_panel:
		_timer_panel.visible = true
	timer.start(seconds)


func hide_shell_timer() -> void:
	timer.hide_timer()
	if _timer_panel:
		_timer_panel.visible = false


func _on_round(r: int) -> void:
	round_label.text = "ROUND %d" % r
