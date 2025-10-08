extends Node

signal push_action_started
signal push_action_ended
signal pull_action_started
signal pull_action_ended
signal walk_left
signal walk_right
signal flip_trolley_requested
signal interact_requested  # New signal for F key interaction
signal pause_requested

# Input state tracking
var is_pushing := false
var is_pulling := false
var push_hold_time := 0.0
var pull_hold_time := 0.0
var last_tap_time := 0.0
var tap_count := 0

# Touch tracking
var touch_start_pos := Vector2.ZERO
var current_touch_pos := Vector2.ZERO
var active_touches := {}

# Virtual button areas (will be set by UI)
var push_button_rect := Rect2()
var pull_button_rect := Rect2()
var interact_button_rect := Rect2()  # For F key functionality
var pause_button_rect := Rect2()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input_actions()

func _setup_input_actions():
	# Ensure input actions exist
	if not InputMap.has_action("push_action"):
		InputMap.add_action("push_action")
		var push_key = InputEventKey.new()
		push_key.keycode = KEY_SPACE
		InputMap.action_add_event("push_action", push_key)
	
	if not InputMap.has_action("pull_action"):
		InputMap.add_action("pull_action")
		var pull_key = InputEventKey.new()
		pull_key.keycode = KEY_SHIFT
		InputMap.action_add_event("pull_action", pull_key)
	
	if not InputMap.has_action("walk_left"):
		InputMap.add_action("walk_left")
		var left_key = InputEventKey.new()
		left_key.keycode = KEY_A
		InputMap.action_add_event("walk_left", left_key)
		var left_arrow = InputEventKey.new()
		left_arrow.keycode = KEY_LEFT
		InputMap.action_add_event("walk_left", left_arrow)
	
	if not InputMap.has_action("walk_right"):
		InputMap.add_action("walk_right")
		var right_key = InputEventKey.new()
		right_key.keycode = KEY_D
		InputMap.action_add_event("walk_right", right_key)
		var right_arrow = InputEventKey.new()
		right_arrow.keycode = KEY_RIGHT
		InputMap.action_add_event("walk_right", right_arrow)
	
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var interact_key = InputEventKey.new()
		interact_key.keycode = KEY_F
		InputMap.action_add_event("interact", interact_key)
	
	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
		var pause_key = InputEventKey.new()
		pause_key.keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", pause_key)

func _input(event):
	# Handle keyboard input
	if event is InputEventKey:
		_handle_keyboard_input(event)
	
	# Handle touch input
	elif event is InputEventScreenTouch:
		_handle_touch_input(event)
	
	# Handle mouse input (for testing)
	elif event is InputEventMouseButton:
		_handle_mouse_input(event)

func _handle_keyboard_input(event: InputEventKey):
	# Push/Pull actions
	if event.is_action_pressed("push_action"):
		_start_push()
	elif event.is_action_released("push_action"):
		_end_push()
	
	if event.is_action_pressed("pull_action"):
		_start_pull()
	elif event.is_action_released("pull_action"):
		_end_pull()
	
	# Walking actions
	if event.is_action_pressed("walk_left"):
		emit_signal("walk_left")
	elif event.is_action_pressed("walk_right"):
		emit_signal("walk_right")
	
	# Interact action (F key)
	if event.is_action_pressed("interact"):
		emit_signal("interact_requested")
	
	if event.is_action_pressed("pause"):
		emit_signal("pause_requested")

func _handle_touch_input(event: InputEventScreenTouch):
	if event.pressed:
		active_touches[event.index] = event.position
		_check_button_press(event.position)
	else:
		active_touches.erase(event.index)
		_check_button_release(event.position)

func _handle_mouse_input(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_check_button_press(event.position)
		else:
			_check_button_release(event.position)

func _check_button_press(pos: Vector2):
	# Check virtual button areas
	if push_button_rect.has_point(pos):
		_start_push()
	elif pull_button_rect.has_point(pos):
		_start_pull()
	elif interact_button_rect.has_point(pos):
		emit_signal("interact_requested")
	elif pause_button_rect.has_point(pos):
		emit_signal("pause_requested")

func _check_button_release(pos: Vector2):
	if push_button_rect.has_point(pos):
		_end_push()
	elif pull_button_rect.has_point(pos):
		_end_pull()

func _start_push():
	if not is_pushing:
		is_pushing = true
		push_hold_time = 0.0
		emit_signal("push_action_started")

func _end_push():
	if is_pushing:
		is_pushing = false
		emit_signal("push_action_ended")

func _start_pull():
	if not is_pulling:
		is_pulling = true
		pull_hold_time = 0.0
		emit_signal("pull_action_started")

func _end_pull():
	if is_pulling:
		is_pulling = false
		emit_signal("pull_action_ended")

func _process(delta):
	# Track hold times for continuous movement
	if is_pushing:
		push_hold_time += delta
	if is_pulling:
		pull_hold_time += delta

# UI can call these to set button areas
func set_push_button_area(rect: Rect2):
	push_button_rect = rect

func set_pull_button_area(rect: Rect2):
	pull_button_rect = rect

func set_interact_button_area(rect: Rect2):
	interact_button_rect = rect

func set_pause_button_area(rect: Rect2):
	pause_button_rect = rect

# Helper functions
func is_any_action_active() -> bool:
	return is_pushing or is_pulling

func get_active_action() -> String:
	if is_pushing:
		return "push"
	elif is_pulling:
		return "pull"
	return "none"

func get_movement_input() -> float:
	# For walking without trolley
	return Input.get_axis("walk_left", "walk_right")
