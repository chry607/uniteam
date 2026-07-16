class_name GameUI extends CanvasLayer

signal tap_left
signal tap_right

var balance_meter: ProgressBar
var time_label: Label
var left_btn: Button
var right_btn: Button

func _init() -> void:
	balance_meter = ProgressBar.new()
	balance_meter.set_size(Vector2(600, 40))
	balance_meter.position = Vector2(340, 50)
	balance_meter.show_percentage = false
	add_child(balance_meter)
	
	time_label = Label.new()
	time_label.position = Vector2(340, 100)
	time_label.set_size(Vector2(600, 100))
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 36)
	add_child(time_label)
	
	left_btn = Button.new()
	add_child(left_btn)
	
	right_btn = Button.new()
	add_child(right_btn)
	
	# Internal connections
	left_btn.pressed.connect(func(): tap_left.emit())
	right_btn.pressed.connect(func(): tap_right.emit())

func setup_meter(min_val: float, max_val: float, start_val: float) -> void:
	balance_meter.min_value = min_val
	balance_meter.max_value = max_val
	balance_meter.value = start_val

func update_display(current_balance: float, time_left: float) -> void:
	balance_meter.value = current_balance
	time_label.text = "Press the arrow keys to balance\nArriving in Cubao Station in: %d s" % int(ceil(time_left))

func show_game_over() -> void:
	time_label.text = "You Fell!\nAura Points ---"
	left_btn.disabled = true
	right_btn.disabled = true

func show_victory() -> void:
	time_label.text = "You can safely get off the train!\nAura Points +++!"
	left_btn.disabled = true
	right_btn.disabled = true
