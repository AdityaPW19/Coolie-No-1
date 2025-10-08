# MobileControls.gd

extends Control

signal walk_left_pressed
signal walk_left_released
signal walk_right_pressed
signal walk_right_released
signal push_pressed
signal pull_pressed
signal trolley_equip_pressed
signal trolley_flip_pressed

@export var DEBUG_MOBILE_SHOW_CONTROLS: bool = false

var original_scales: Dictionary = {}

@onready var walk_left_button: TextureButton = $WalkLeft
@onready var walk_right_button: TextureButton = $WalkRight
@onready var push_button: TextureButton = $PushButton
@onready var pull_button: TextureButton = $PullButton
@onready var trolley_equip_button: TextureButton = $TrolleyEquipButton
@onready var trolley_flip_button: TextureButton = $TrolleyFlipButton

func _ready():
	if DEBUG_MOBILE_SHOW_CONTROLS:
		visible = true
	else:
		var is_web_mobile = OS.get_name() == "Web" and JavaScriptBridge.eval(
			"/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)",
			true
		)
		visible = bool(is_web_mobile)

	if visible:
		_store_original_scales()
		_connect_buttons()
		update_visibility(false, false)

func _store_original_scales():
	var buttons_to_track = [
		walk_left_button, walk_right_button, 
		push_button, pull_button,
		trolley_equip_button, trolley_flip_button
	]
	for button in buttons_to_track:
		if is_instance_valid(button):
			original_scales[button] = button.scale

func _connect_buttons():
	# --- Game Logic ---
	walk_left_button.button_down.connect(walk_left_pressed.emit)
	walk_left_button.button_up.connect(walk_left_released.emit)
	walk_right_button.button_down.connect(walk_right_pressed.emit)
	walk_right_button.button_up.connect(walk_right_released.emit)
	push_button.pressed.connect(push_pressed.emit)
	pull_button.pressed.connect(pull_pressed.emit)
	# CHANGE: Add print statements to these two connections
	trolley_equip_button.pressed.connect(func():
		print("DEBUG MobileControls: Equip Button PRESSED. Emitting signal.")
		trolley_equip_pressed.emit()
	)
	trolley_flip_button.pressed.connect(func():
		print("DEBUG MobileControls: Flip Button PRESSED. Emitting signal.")
		trolley_flip_pressed.emit()
	)

	# --- Visuals ---
	var all_buttons = [
		walk_left_button, walk_right_button, 
		push_button, pull_button,
		trolley_equip_button, trolley_flip_button
	]
	for button in all_buttons:
		if is_instance_valid(button):
			button.button_down.connect(func(): _animate_press(button))
			button.button_up.connect(func(): _animate_release(button))


func trigger_continuous_press(action: String, is_pressed: bool):
	"""
	Called by the Player script for continuous actions like walking.
	action: "walk_left" or "walk_right"
	is_pressed: true for key down, false for key up
	"""
	var button_to_animate: TextureButton = null
	
	match action:
		"walk_left":
			button_to_animate = walk_left_button
		"walk_right":
			button_to_animate = walk_right_button
			
	if button_to_animate:
		if is_pressed:
			_animate_press(button_to_animate)
		else:
			_animate_release(button_to_animate)

func trigger_discrete_press(action: String):
	"""
	Called by the Player script for single-tap actions.
	This will play a full 'pop' (press and release) animation.
	action: "push", "pull", "equip", "flip"
	"""
	var button_to_animate: TextureButton = null
	
	match action:
		"push":
			button_to_animate = push_button
		"pull":
			button_to_animate = pull_button
		"equip":
			button_to_animate = trolley_equip_button
		"flip":
			button_to_animate = trolley_flip_button
			
	if button_to_animate and button_to_animate.visible:
		# For discrete actions, we create a full press-and-release tween.
		if not original_scales.has(button_to_animate): return
		var original_scale = original_scales[button_to_animate]
		var target_scale = original_scale * 1.2
		
		var tween = create_tween()
		tween.tween_property(button_to_animate, "scale", target_scale, 0.1)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(button_to_animate, "scale", original_scale, 0.1)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

# --- THIS IS THE CORRECTED FUNCTION ---
func update_visibility(player_has_trolley: bool, player_is_near_trolley: bool):
	# For each button, we set BOTH its visibility AND its disabled state.
	# A disabled button cannot be clicked or touched.

	# Walk buttons
	walk_left_button.visible = not player_has_trolley
	walk_left_button.disabled = player_has_trolley
	
	walk_right_button.visible = not player_has_trolley
	walk_right_button.disabled = player_has_trolley
	
	# Push/Pull buttons
	push_button.visible = player_has_trolley
	push_button.disabled = not player_has_trolley
	
	pull_button.visible = player_has_trolley
	pull_button.disabled = not player_has_trolley
	
	# Interaction buttons
	trolley_flip_button.visible = player_has_trolley
	trolley_flip_button.disabled = not player_has_trolley
	
	var should_show_equip = not player_has_trolley and player_is_near_trolley
	trolley_equip_button.visible = should_show_equip
	trolley_equip_button.disabled = not should_show_equip


# --- ANIMATION FUNCTIONS (Unchanged) ---
func _animate_press(button: TextureButton):
	"""Scales the button UP relative to its original size."""
	if not original_scales.has(button): return # Safety check

	var original_scale = original_scales[button]
	var target_scale = original_scale * 1.2 # Scale up by 20%

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, 0.1)

func _animate_release(button: TextureButton):
	if not original_scales.has(button): return
	var original_scale = original_scales[button]
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(button, "scale", original_scale, 0.1)
