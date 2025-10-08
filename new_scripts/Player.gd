extends CharacterBody2D

# Remove class_name to avoid global conflict
# class_name Player

## Movement constants (from GDD: 2m per tap, 2m/s speed)
#const MOVEMENT_DISTANCE = 100.0  # 2 meters = 20 pixels (since 100m = 1000 pixels)
#const MOVEMENT_SPEED = 200.0     # Pixels per second for smooth movement

# --- NEW: PULL ALL VALUES FROM THE SINGLE SOURCE OF TRUTH ---
const PLAYER_WALK_SPEED = GameConstants.GAME.PLAYER_WALK_SPEED_PIXELS
const TROLLEY_MOVE_SPEED = GameConstants.GAME.TROLLEY_MOVE_SPEED_PIXELS

@onready var mobile_controls: Control = $"../../UI/MobileControls"
var mobile_walk_direction: int = 0

# NEW: Constants for moving WITH the trolley. These are balanced with the timer.
# The distance the trolley moves in one discrete tap. You wanted to keep this at 100px.
const TROLLEY_MOVE_DISTANCE = 100.0

# Replace with these new variables:
var current_arrow_direction: String = ""
var arrow_needs_update: bool = false

# Animation states
enum AnimationState {
	IDLE,
	WALK,
	PUSH,
	PULL
}

# Node references
@onready var animated_sprite: AnimatedSprite2D = $PlayerSprite
@onready var movement_timer: Timer = $Timer
@onready var PlayerSpawn: Marker2D = $"../PlayerSpawn"
#@onready var EventManager: Node = $"../../EventManager"
@onready var DirectionArrowSprite: Sprite2D = $DirectionArrow

# Movement variables
var current_animation_state: AnimationState = AnimationState.IDLE
var is_moving: bool = false
var target_position: Vector2
var movement_direction: int = 1  # 1 for right, -1 for left
var is_facing_right: bool = true

var fixed_delivery_direction: String = ""

# Trolley interaction variables (from GDD)
var is_with_trolley: bool = false
var current_trolley: RigidBody2D = null
var nearby_trolley: RigidBody2D = null
var last_seen_trolley: RigidBody2D = null

# Input handling with proper state tracking
var can_move: bool = true
var f_key_was_pressed: bool = false  # Track F key state
var left_key_was_pressed: bool = false  # Track A/Left key state
var right_key_was_pressed: bool = false  # Track D/Right key state

# Tween for arrow animation
var arrow_tween: Tween
var idle_tween: Tween

func _ready():
	# Set starting position using PlayerSpawn (GDD: start at center 200m)
	position.x = PlayerSpawn.position.x
	target_position = position
	
	# Set initial animation
	_set_animation_state(AnimationState.IDLE)
	
		# Setup timer for movement completion
	movement_timer.wait_time = 0.1
	movement_timer.timeout.connect(_on_movement_timer_timeout)
	# Connect to GameManager signal for delivery direction
	GameManager.connect("delivery_started", Callable(self, "_on_delivery_started"))
	
	# Initialize arrow
	DirectionArrowSprite.visible = true
	arrow_tween = create_tween()
	_animate_arrow_idle()  # Start idle animation (gentle bob)
	
	# Setup timer for movement completion
	movement_timer.wait_time = 0.1
	movement_timer.timeout.connect(_on_movement_timer_timeout)

	if is_instance_valid(mobile_controls):
		mobile_controls.walk_left_pressed.connect(_on_mobile_walk_left_pressed)
		mobile_controls.walk_left_released.connect(_on_mobile_walk_left_released)
		mobile_controls.walk_right_pressed.connect(_on_mobile_walk_right_pressed)
		mobile_controls.walk_right_released.connect(_on_mobile_walk_right_released)
		mobile_controls.push_pressed.connect(_on_mobile_push)
		mobile_controls.pull_pressed.connect(_on_mobile_pull)
		
		# NEW: Connect to the interaction button signals
		mobile_controls.trolley_equip_pressed.connect(_on_mobile_trolley_interact)
		mobile_controls.trolley_flip_pressed.connect(_on_mobile_trolley_interact)
		
		# NEW: Set the initial button visibility
		#mobile_controls.update_visibility(is_with_trolley, nearby_trolley != null)
	
	print("Player initialized at position: ", position.x / 10.0, "m")
	print("can_move: ", can_move, " is_moving: ", is_moving)

#func _on_delivery_started(delivery_data: Dictionary):
	#var trolley_direction = GameManager.get_trolley_direction_from_delivery()
	#
	## Initially show trolley direction (since player doesn't have trolley yet)
	#_update_arrow_direction(trolley_direction)
	#
	### Connect to delivery direction changes
	##if not GameManager.is_connected("delivery_direction_changed", _on_delivery_direction_changed):
		##GameManager.connect("delivery_direction_changed", _on_delivery_direction_changed)
		

func _on_delivery_started(delivery_data: Dictionary):
	"""Reset arrow system for new delivery"""
	# Reset arrow state
	current_arrow_direction = ""
	
	# Show arrow and trigger update
	_show_arrow()
	trigger_arrow_update()
	
	print("New delivery started - arrow system reset")

# Add this new function to handle delivery direction changes:
func _on_delivery_direction_changed(new_direction: String):
	"""Called when GameManager updates delivery direction"""
	if is_with_trolley and DirectionArrowSprite.visible:
		_update_arrow_direction(new_direction)

func _on_mobile_trolley_interact():
	# This logic is a direct copy of the F-key check, but for a single press event.
	if is_with_trolley and current_trolley != null:
		# If we have a trolley, the "F" key (or mobile button) means "flip".
		_flip_trolley()
	elif nearby_trolley != null and not nearby_trolley.get_is_occupied():
		# If we are near a trolley, the "F" key (or mobile button) means "equip".
		nearby_trolley.equip_trolley(self)
		nearby_trolley = null

#func _handle_pc_visual_feedback():
	#"""Checks for PC key presses to trigger mobile button animations."""
	#if not is_instance_valid(mobile_controls):
		#return
#
	## Handle walking keys (continuous press)
	#if Input.is_action_just_pressed("ui_left"):
		#mobile_controls.trigger_continuous_press("walk_left", true)
	#if Input.is_action_just_released("ui_left"):
		#mobile_controls.trigger_continuous_press("walk_left", false)
		#
	#if Input.is_action_just_pressed("ui_right"):
		#mobile_controls.trigger_continuous_press("walk_right", true)
	#if Input.is_action_just_released("ui_right"):
		#mobile_controls.trigger_continuous_press("walk_right", false)
		
func _handle_pc_visual_feedback():
	"""Checks for PC key presses to trigger mobile button animations."""
	if not is_instance_valid(mobile_controls):
		return

	# Handle walking keys (continuous press) - A/D keys only
	if Input.is_key_pressed(KEY_A):
		mobile_controls.trigger_continuous_press("walk_left", true)
	else:
		mobile_controls.trigger_continuous_press("walk_left", false)
		
	if Input.is_key_pressed(KEY_D):
		mobile_controls.trigger_continuous_press("walk_right", true)
	else:
		mobile_controls.trigger_continuous_press("walk_right", false)
		

func _update_arrow_direction(direction: String):
	# Flip horizontally
	DirectionArrowSprite.flip_h = (direction == "left")
	
	# Stop any existing lean tween
	if arrow_tween and arrow_tween.is_running():
		arrow_tween.kill()
	
	var lean_angle = deg_to_rad(8) if direction == "right" else deg_to_rad(-8)
	arrow_tween = create_tween()

	# Lean in, then back to neutral
	arrow_tween.tween_property(DirectionArrowSprite, "rotation", lean_angle, 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	arrow_tween.tween_property(DirectionArrowSprite, "rotation", 0, 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _animate_arrow_idle():
	if idle_tween and idle_tween.is_running():
		idle_tween.kill()

	var start_pos = DirectionArrowSprite.position
	var bob_offset = Vector2(0, -4)  # Slight upward movement

	idle_tween = create_tween()
	idle_tween.set_loops()  # Infinite loop

	idle_tween.tween_property(DirectionArrowSprite, "position", start_pos + bob_offset, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(DirectionArrowSprite, "position", start_pos, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func trigger_arrow_update():
	"""
	Triggers an immediate arrow direction update on the next frame.
	Call this whenever game state changes that might affect arrow direction.
	"""
	arrow_needs_update = true
	print("Arrow update triggered")	

func _update_arrow_direction_immediate():
	"""
	Immediately updates arrow direction based on current game state.
	Called when game state changes, not on a timer.
	"""
	var new_direction: String
	
	if is_with_trolley:
		# When carrying trolley: arrow points toward delivery destination
		new_direction = get_direction_to_delivery()
	else:
		# When walking freely: arrow points toward trolley location
		new_direction = get_direction_to_trolley()
	
	# Always update (no change detection needed for immediate updates)
	current_arrow_direction = new_direction
	_update_arrow_direction(new_direction)
	
	var state = "carrying trolley -> delivery" if is_with_trolley else "walking -> trolley"
	print("Arrow direction updated immediately (", state, ") to: ", new_direction)

#func get_direction_to_trolley() -> String:
	#"""
	#Returns the direction from player to the nearest trolley.
	#Used when player is NOT carrying trolley.
	#"""
	#if nearby_trolley and is_instance_valid(nearby_trolley):
		#var player_pos_meters = get_current_position_meters()
		#var trolley_pos_meters = nearby_trolley.global_position.x / 20.0
		#
		#var direction = "right" if trolley_pos_meters > player_pos_meters else "left"
		#print("Direction to trolley: ", direction, " (Player: ", player_pos_meters, "m -> Trolley: ", trolley_pos_meters, "m)")
		#return direction
	#
	## Fallback: use GameManager's trolley direction
	#print_debug("using GM trolley direction")
	#return GameManager.get_trolley_direction_from_delivery()
func get_direction_to_trolley() -> String:
	"""
	Simple and robust: Uses delivery data to calculate direction.
	This data is always available and accurate.
	"""
	var delivery_data = GameManager.get_current_delivery_info()
	
	if not delivery_data.is_empty():
		var trolley_target_pos = delivery_data.get("trolley_pos", 0.0)
		var player_pos_meters = get_current_position_meters()+40
		print_debug("player position in meter  get trolly direction :  ",player_pos_meters)
		
		var direction = "right" if trolley_target_pos > player_pos_meters else "left"
		print("Direction to trolley: ", direction, " (Player: ", player_pos_meters, "m -> Trolley at: ", trolley_target_pos, "m)")
		return direction
	
	# Simple fallback
	print_debug("using GM trolley direction")
	return GameManager.get_trolley_direction_from_delivery()
	
func find_current_scene_trolley() -> RigidBody2D:
	"""Finds the active trolley in the current scene"""
	# Get the level root (adjust path as needed)
	var level_root = get_tree().current_scene
	
	# Search for trolleys
	var trolleys = level_root.find_children("*", "RigidBody2D", true, false)
	
	for trolley in trolleys:
		# Check if it's a trolley and visible (active)
		if ("trolley" in trolley.name.to_lower() or trolley.scene_file_path.contains("trolley")) and trolley.visible:
			return trolley
	
	return null
	
		
	
func get_direction_to_delivery() -> String:
	"""
	Returns the direction from current trolley position to delivery destination.
	Used when player IS carrying trolley.
	"""
	var delivery_data = GameManager.get_current_delivery_info()
	if delivery_data.is_empty():
		return "right"  # Default fallback
	
	var destination = delivery_data.get("destination", 0.0)
	var current_pos_meters: float
	
	if is_with_trolley and is_instance_valid(current_trolley):
		# Use trolley position for delivery direction
		current_pos_meters = current_trolley.global_position.x / 20.0
	else:
		# Use player position as fallback
		current_pos_meters = get_current_position_meters()
	
	var direction = "right" if destination > current_pos_meters else "left"
	print("Direction to delivery: ", direction, " (Current: ", current_pos_meters, "m -> Target: ", destination, "m)")
	return direction

func _physics_process(delta):
	# Handle interaction input first (F key functionality)
	_handle_pc_visual_feedback()
	_handle_interaction_input()
	
	if not can_move:
		velocity = Vector2.ZERO
		return
		
		 # NEW: Real-time arrow updates when needed
	if DirectionArrowSprite.visible and arrow_needs_update:
		_update_arrow_direction_immediate()
		arrow_needs_update = false
	
	# Main movement router
	if is_with_trolley:
		# TAP-TO-MOVE: Discrete 2m movements with trolley (GDD requirement)
		_handle_trolley_input()
		if is_moving:
			_handle_smooth_movement(delta)
	else:
		# HOLD-TO-MOVE: Continuous walking without trolley
		_handle_walking_movement(delta)
		
	if is_instance_valid(mobile_controls):
		mobile_controls.update_visibility(is_with_trolley, nearby_trolley != null)
	
	
# NEW: Add handler functions for the new press/release signals
func _on_mobile_walk_left_pressed():
	mobile_walk_direction = -1

func _on_mobile_walk_right_pressed():
	mobile_walk_direction = 1

func _on_mobile_walk_left_released():
	# Only set to 0 if the current direction is from this button
	if mobile_walk_direction == -1:
		mobile_walk_direction = 0

func _on_mobile_walk_right_released():
	# Only set to 0 if the current direction is from this button
	if mobile_walk_direction == 1:
		mobile_walk_direction = 0
		
#func _on_mobile_push():
	#if can_move and is_with_trolley and not is_moving:
		## For PUSH: we move AWAY from the handle
		#var trolley_direction = current_trolley.get_trolley_direction()
		#var move_direction = -trolley_direction  # Opposite of handle direction
		#_move_with_trolley(move_direction)
		
func _on_mobile_push():
	if can_move and is_with_trolley and not is_moving:
		_execute_push_or_pull("push")

#func _on_mobile_pull():
	#if can_move and is_with_trolley and not is_moving:
		## For PULL: we move IN THE SAME direction as the handle
		#var trolley_direction = current_trolley.get_trolley_direction()
		#var move_direction = trolley_direction  # Same as handle direction
		#_move_with_trolley(move_direction)
func _on_mobile_pull():
	if can_move and is_with_trolley and not is_moving:
		_execute_push_or_pull("pull")

#rest everything in player
func reset_for_new_delivery():
	"""Resets all variables for the start of a new delivery leg."""
	print("DEBUG_PLAYER: Resetting state for new delivery.")
	current_trolley = null
	nearby_trolley = null
	is_with_trolley = false
	is_moving = false
	
	# Add any other state resets here (like push/pull animations)
	_set_animation_state(AnimationState.IDLE)

# --- Input Handlers (Fixed with proper state tracking) ---

func _handle_interaction_input():
	"""Handles F key: pickup trolley OR flip trolley when holding (with proper state tracking)"""
	# Add a guard clause here as well
	if not can_move:
		return
	var f_key_is_pressed = Input.is_key_pressed(KEY_F)
	
	# Only trigger on F key PRESS (not hold)
	if f_key_is_pressed and not f_key_was_pressed:
		# --- ADD THIS PRINT ---
		print("DEBUG_PLAYER: 'F' was pressed. Current value of nearby_trolley is: ", nearby_trolley)
		# -----------------------

		if is_with_trolley and current_trolley != null:
			# Player is holding trolley - F key flips trolley
			if is_instance_valid(mobile_controls):
				mobile_controls.trigger_discrete_press("flip") # <-- ADD THIS
			_flip_trolley()
			print("F pressed: Flipping trolley (player is holding trolley)")
		elif nearby_trolley != null and not nearby_trolley.get_is_occupied():
			# Player is near trolley - F key picks up trolley
			if is_instance_valid(mobile_controls):
				mobile_controls.trigger_discrete_press("equip") # <-- ADD THIS

			nearby_trolley.equip_trolley(self)
			nearby_trolley = null
			print("F pressed: Picked up trolley")
		else:
			print("F pressed: No action (no trolley nearby or already holding)")
	
	# Update F key state for next frame
	f_key_was_pressed = f_key_is_pressed

#func _handle_trolley_input():
	#"""Handles discrete 2m push/pull moves - ONE TAP = ONE 2M MOVE (GDD requirement)"""
	#
	## Get current key states
	#var left_key_is_pressed = Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	#var right_key_is_pressed = Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)
	#
	## Only allow movement if NOT currently moving (GDD: discrete movement)
	#if not is_moving:
		## LEFT MOVEMENT - Only trigger on key PRESS (not hold)
		#if left_key_is_pressed and not left_key_was_pressed:
			#_move_with_trolley(-1)
			#print("LEFT key pressed: Starting 2m trolley movement")
		#
		## RIGHT MOVEMENT - Only trigger on key PRESS (not hold)
		#elif right_key_is_pressed and not right_key_was_pressed:
			#_move_with_trolley(1)
			#print("RIGHT key pressed: Starting 2m trolley movement")
	#else:
		## Player is moving - ignore input until movement completes
		#if left_key_is_pressed and not left_key_was_pressed:
			#print("LEFT key pressed: Cannot move - already moving!")
		#elif right_key_is_pressed and not right_key_was_pressed:
			#print("RIGHT key pressed: Cannot move - already moving!")
	#
	## Update key states for next frame
	#left_key_was_pressed = left_key_is_pressed
	#right_key_was_pressed = right_key_is_pressed
	
func _handle_trolley_input():
	"""Handles discrete 2m push/pull moves - A=PUSH, D=PULL"""
	
	# Get current key states - A for PUSH, D for PULL
	var a_key_is_pressed = Input.is_key_pressed(KEY_A)  # PUSH
	var d_key_is_pressed = Input.is_key_pressed(KEY_D)  # PULL
	
	# Only allow movement if NOT currently moving (GDD: discrete movement)
	if not is_moving:
		# A KEY - PUSH
		if a_key_is_pressed and not left_key_was_pressed:
			_execute_push_or_pull("push")
			print("A key pressed: PUSHING trolley")
		
		# D KEY - PULL
		elif d_key_is_pressed and not right_key_was_pressed:
			_execute_push_or_pull("pull")
			print("D key pressed: PULLING trolley")
	else:
		# Player is moving - ignore input until movement completes
		if a_key_is_pressed and not left_key_was_pressed:
			print("A key pressed: Cannot PUSH - already moving!")
		elif d_key_is_pressed and not right_key_was_pressed:
			print("D key pressed: Cannot PULL - already moving!")
	
	# Update key states for next frame
	left_key_was_pressed = a_key_is_pressed
	right_key_was_pressed = d_key_is_pressed
	
func _execute_push_or_pull(action: String):
	"""Executes push or pull based on action, determining direction from trolley handle"""
	if not is_instance_valid(current_trolley): 
		return
	if is_moving: 
		return
	
	# Get trolley handle direction
	var trolley_direction = current_trolley.get_trolley_direction()
	var move_direction: int
	
	if action == "push":
		# PUSH: Move opposite to handle direction
		move_direction = -trolley_direction
	else:  # pull
		# PULL: Move same as handle direction
		move_direction = trolley_direction
	
	# Now call the existing movement function
	_move_with_trolley(move_direction)



#func _handle_walking_movement(delta):
	#"""Handles continuous walking when not with trolley (hold-to-move)"""
	#var input_axis = 0
	#
	## IMPORTANT: Don't allow A/D walking when with trolley
	## A/D are now dedicated push/pull buttons when with trolley
	#if not is_with_trolley:
		## Check A/D keys only when NOT with trolley
		#if Input.is_key_pressed(KEY_A):
			#input_axis = -1
		#elif Input.is_key_pressed(KEY_D):
			#input_axis = 1
	#
	## If there's no keyboard input, use the mobile input
	#if input_axis == 0:
		#input_axis = mobile_walk_direction
	#
	#if input_axis != 0:
		#velocity.x = input_axis * PLAYER_WALK_SPEED
		#_update_facing_direction(input_axis)
		#_set_animation_state(AnimationState.WALK)
	#else:
		#velocity.x = move_toward(velocity.x, 0, PLAYER_WALK_SPEED)
		#_set_animation_state(AnimationState.IDLE)
		#
	#move_and_slide() 

func _handle_walking_movement(delta):
	"""Handles continuous walking when not with trolley (hold-to-move)"""
	var input_axis = 0
	
	# IMPORTANT: Don't allow A/D walking when with trolley
	if not is_with_trolley:
		# Check A/D keys only when NOT with trolley
		if Input.is_key_pressed(KEY_A):
			input_axis = -1
		elif Input.is_key_pressed(KEY_D):
			input_axis = 1
	
	# If there's no keyboard input, use the mobile input
	if input_axis == 0:
		input_axis = mobile_walk_direction
	
	# ADD THIS: Block movement if it would pass through a trolley
	if input_axis != 0 and not is_with_trolley:
		var next_position = global_position.x + (input_axis * PLAYER_WALK_SPEED * delta)
		if _would_collide_with_trolley(next_position):
			input_axis = 0  # Stop movement
			velocity.x = 0  # Immediately stop
			print("Blocked: Cannot walk through trolley!")
	
	if input_axis != 0:
		velocity.x = input_axis * PLAYER_WALK_SPEED
		_update_facing_direction(input_axis)
		_set_animation_state(AnimationState.WALK)
	else:
		velocity.x = move_toward(velocity.x, 0, PLAYER_WALK_SPEED)
		_set_animation_state(AnimationState.IDLE)
		
	move_and_slide()
	
func _would_collide_with_trolley(next_x_position: float) -> bool:
	"""Check if moving to next_x_position would collide with any trolley"""
	
	if nearby_trolley and is_instance_valid(nearby_trolley):
		var trolley_x = nearby_trolley.global_position.x
		var distance = abs(next_x_position - (trolley_x + 20.0))  # Apply offset
		
		# Debug print
		print("Collision check: Player next_x=", next_x_position, 
			  " Trolley_x=", trolley_x, 
			  " Adjusted=", trolley_x + 20.0,
			  " Distance=", distance)
		
		if distance < 40.0:
			print("COLLISION DETECTED!")
			return true
	
	return false

# --- Movement Handlers (GDD Implementation) ---

func _move_with_trolley(direction: int):
	"""
	Final diagnostic version.
	"""
	
	# --- Part A: Initial Checks ---
	if not is_instance_valid(current_trolley): return
	if is_moving: return

	# ####################################################################
	# ## THE MASTER DEBUG PRINT - This is the line we need to see.
	# ####################################################################
	print("--- PLAYER DEBUG ---")
	print("Attempting to move. Direction input: ", direction)
	print("Is trolley valid? ", is_instance_valid(current_trolley))
	if is_instance_valid(current_trolley):
		print("Trolley's handle direction is: ", current_trolley.get_trolley_direction())
	print("--------------------")
	# ####################################################################

	# --- Part B: Determine Force Type (Using Your Old, Correct Logic) ---
	var trolley_direction = current_trolley.get_trolley_direction()
	var force_type = "pull" 
	
	if (direction > 0 and trolley_direction == -1) or (direction < 0 and trolley_direction == 1):
		force_type = "push"
		
	if is_instance_valid(mobile_controls):
		mobile_controls.trigger_discrete_press(force_type)

	# --- Part C: Check Effort Meter with the GameManager ---
	if not GameManager.can_use_effort(force_type):
		print("Player: Cannot move! Not enough '", force_type.to_upper(), "' effort.")
		return 

	GameManager.spend_effort(force_type)

	# --- Part D: Execute the Move and Set Animation ---
	print("Action Determined: ", force_type.to_upper())
	
	is_moving = true
	movement_direction = direction
	target_position = Vector2(position.x + (direction * TROLLEY_MOVE_DISTANCE), position.y)
	
	_update_facing_direction(direction)
	
	if force_type == "push":
		_set_animation_state(AnimationState.PUSH)
	else:
		_set_animation_state(AnimationState.PULL)
	print("Target position: ", target_position.x / 10.0, "m - Movement will take ", TROLLEY_MOVE_DISTANCE / TROLLEY_MOVE_SPEED, " seconds")

func _handle_smooth_movement(delta):
	"""Completes the discrete 2-meter move (GDD: smooth animation)"""
	var distance_to_target = target_position.distance_to(position)
	var direction_vector = (target_position - position).normalized()
	velocity = direction_vector * TROLLEY_MOVE_SPEED
	move_and_slide()

	# Move trolley with player
	if is_with_trolley and current_trolley != null:
		_move_trolley_to_player_position()
	
	# Check if movement is complete
	if distance_to_target <= velocity.length() * delta:
		position = target_position
		is_moving = false
		_set_animation_state(AnimationState.IDLE)
		
		# NO MORE REAL-TIME UPDATES - keep the fixed direction
		
		GameManager.emit_signal("player_moved_with_trolley", self)
		
		if is_with_trolley and current_trolley != null:
			_move_trolley_to_player_position()
			current_trolley.linear_velocity = Vector2.ZERO
			GameManager.emit_signal("player_completed_first_move", self)
			
		# NEW: Trigger arrow update after movement (position changed!)
		trigger_arrow_update()

		print("✓ 2m movement completed!")
# --- Helper Functions (GDD Implementation) ---

func _move_trolley_to_player_position():
	"""Maintains correct trolley-player relationship (GDD: auto-positioning)"""
	if current_trolley != null:
		# CORRECTED COORDINATE MATH:
		var trolley_direction = current_trolley.get_trolley_direction()
		var player_point_name = "PlayerPointRight" if trolley_direction == 1 else "PlayerPointLeft"
		var player_point = current_trolley.get_node(player_point_name)
		
		if player_point:
			# CORRECT: Use global coordinates instead of local position math
			var desired_trolley_position = global_position - player_point.position
			
			print("DEBUG: Moving trolley from ", current_trolley.global_position, " to ", desired_trolley_position)
			
			# Only update if the difference is significant (avoid micro-movements)
			if global_position.distance_to(current_trolley.global_position + player_point.position) > 5.0:
				current_trolley.global_position = desired_trolley_position
			
			# Stop any physics movement
			current_trolley.linear_velocity = Vector2.ZERO
			current_trolley.angular_velocity = 0.0

func _update_facing_direction(direction: float):
	"""Updates player sprite facing direction"""
	if direction > 0 and not is_facing_right:
		animated_sprite.flip_h = false
		is_facing_right = true
	elif direction < 0 and is_facing_right:
		animated_sprite.flip_h = true
		is_facing_right = false

func _set_animation_state(new_state: AnimationState):
	"""Sets player animation state (GDD: visual feedback)"""
	if current_animation_state == new_state:
		return
	
	current_animation_state = new_state
	
	match current_animation_state:
		AnimationState.IDLE:
			animated_sprite.play("idle")
		AnimationState.WALK:
			animated_sprite.play("walk")
		AnimationState.PUSH:
			animated_sprite.play("push")
		AnimationState.PULL:
			animated_sprite.play("pull")

func _on_movement_timer_timeout():
	pass

func _show_arrow():
	"""Shows the direction arrow"""
	DirectionArrowSprite.visible = true
	_animate_arrow_idle()

func _hide_arrow():
	"""Hides the direction arrow"""
	DirectionArrowSprite.visible = false
	# Stop any running tweens
	if arrow_tween and arrow_tween.is_running():
		arrow_tween.kill()
	if idle_tween and idle_tween.is_running():
		idle_tween.kill()

# --- Trolley Interaction Functions (Proper State Management) ---

#func set_nearby_trolley(trolley: RigidBody2D):
	#"""Called by trolley when player enters/exits interaction area"""
	#if trolley:
		#print("DEBUG_PLAYER: set_nearby_trolley CALLED. Setting nearby_trolley to: ", trolley.name)
		#nearby_trolley = trolley
		## Hide arrow when near trolley
		#_hide_arrow()
		#trigger_arrow_update()
		#print("Trolley nearby - press F to pick up")
	#else:
		#print("DEBUG_PLAYER: set_nearby_trolley CALLED. Clearing nearby_trolley (setting to null).")
		#nearby_trolley = trolley
		## Show trolley direction again when leaving trolley area (if not holding trolley)
		#if not is_with_trolley:
			#_hide_arrow()
		#else:
			## Still carrying trolley, just update direction
			#trigger_arrow_update()
		## NEW: Update mobile UI whenever our proximity to a trolley changes.
	#if is_instance_valid(mobile_controls):
		#mobile_controls.update_visibility(is_with_trolley, nearby_trolley != null)
		#print("No trolley nearby")
		
func set_nearby_trolley(trolley_node: RigidBody2D):
	"""Called by trolley when player enters/exits interaction area"""
	if trolley_node:
		print("DEBUG_PLAYER: set_nearby_trolley CALLED. Setting nearby_trolley to: ", trolley_node.name)
		nearby_trolley = trolley_node
		
		# Hide arrow when near trolley (can interact directly)
		_hide_arrow()
		print("Trolley nearby - press F to pick up")
	else:
		print("DEBUG_PLAYER: set_nearby_trolley CALLED. Player leaving trolley area.")
		
		# When leaving trolley area
		if not is_with_trolley:
			# Show arrow and update direction BEFORE clearing the reference
			_show_arrow()
			#trigger_arrow_update()  # This uses nearby_trolley while it's still valid
			
			print("Left trolley area - showing direction arrow to trolley")
		else:
			# Still carrying trolley, just update delivery direction
			trigger_arrow_update()
			print("Left trolley area while carrying trolley - refreshing delivery direction")
		
		# NOW clear the nearby_trolley reference (after arrow update)
		nearby_trolley = null
	
	# Update mobile UI
	if is_instance_valid(mobile_controls):
		mobile_controls.update_visibility(is_with_trolley, nearby_trolley != null)
		
func _start_position_tracking_timer():
	"""Creates a 2-second timer to track position changes after trolley interaction"""
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.5  # Check every 0.5 seconds
	timer.timeout.connect(_on_position_debug_timer)
	timer.start()
	
	# Set up data for tracking
	set_meta("debug_timer_count", 0)
	set_meta("debug_timer_instance", timer)

func _on_position_debug_timer():
	"""Called every 0.5 seconds to track positions"""
	var count = get_meta("debug_timer_count", 0)
	var timer = get_meta("debug_timer_instance", null)
	
	count += 1
	set_meta("debug_timer_count", count)
	
	var time_elapsed = count * 0.5
	print("T+", time_elapsed, "s - Player position: ", global_position)
	if current_trolley and is_instance_valid(current_trolley):
		print("T+", time_elapsed, "s - Trolley position: ", current_trolley.global_position)
	else:
		print("T+", time_elapsed, "s - No valid trolley")
	
	# Stop after 2 seconds (4 calls)
	if count >= 4:
		print("=== POSITION TRACKING COMPLETE ===")
		if timer and is_instance_valid(timer):
			timer.queue_free()
		remove_meta("debug_timer_count")
		remove_meta("debug_timer_instance")

func interact_with_trolley(trolley: RigidBody2D):
	"""Called when player picks up trolley (GDD: F key interaction)"""
	print("Interacting with trolley")
	current_trolley = trolley
	is_with_trolley = true
	velocity = Vector2.ZERO
	
	# Position player at correct point based on handle direction
	var trolley_direction = trolley.get_trolley_direction()
	var player_point_name = "PlayerPointRight" if trolley_direction == 1 else "PlayerPointLeft"
	var player_point = trolley.get_node(player_point_name)
	
	if player_point:
		# Use the PlayerPoint's global position directly
		global_position = player_point.global_position
		target_position = global_position
		print("Player positioned at trolley ", player_point_name, " using global coordinates")
	
	#Reset arrow state
	current_arrow_direction = ""
	
	# Show arrow and trigger immediate update
	_show_arrow()
	trigger_arrow_update()
	
	if is_instance_valid(mobile_controls):
		mobile_controls.update_visibility(is_with_trolley, nearby_trolley != null)
	
	GameManager.emit_signal("player_picked_up_trolley", self, trolley)
	_set_animation_state(AnimationState.IDLE)
	print("✓ Player equipped with trolley - TAP A/D for 2m moves, F to flip")

func _flip_trolley():
	"""Flips trolley handle direction - ONLY works when holding trolley."""
	
	# --- 1. Basic Sanity Checks ---
	if not is_with_trolley:
		print("Cannot flip trolley - not holding any trolley!")
		return
	if is_moving:
		print("Cannot flip trolley while moving! Wait for movement to complete.")
		return
	if not is_instance_valid(current_trolley):
		print("Error: No valid trolley to flip!")
		return
		
	# --- 2. NEW: Level Feature Check ---
	# Ask the GameManager if the "flip" feature is enabled for the current level.
	if not GameManager.is_level_feature_enabled("flip"):
		print("Player: Flipping is disabled in this level!")
		# You could add a "buzz" sound effect here for negative feedback.
		return
	# ------------------------------------

	# --- 3. Execute the Flip ---
	print("Flipping trolley with F key...")
	current_trolley.flip_trolley()
	
	# --- 4. Reposition the Player ---
	# Reposition player after flip (GDD: 1 second animation)
	var trolley_direction = current_trolley.get_trolley_direction()
	var player_point_name = "PlayerPointRight" if trolley_direction == 1 else "PlayerPointLeft"
	var player_point = current_trolley.get_node(player_point_name)
	
	if player_point:
		# Use global_position for Marker2D children of the trolley for accuracy
		global_position = player_point.global_position
		target_position = global_position
		print("✓ Player repositioned to ", player_point_name, " after F key flip")

func release_trolley():
	"""Called programmatically when player should drop trolley (not by F key)"""
	print("Releasing trolley")
	current_trolley = null
	is_with_trolley = false
	is_moving = false
	# Reset arrow state
	current_arrow_direction = ""
	
	_hide_arrow()
	_set_animation_state(AnimationState.IDLE)
	print("Player released from trolley")
	
		# NEW: Update mobile UI now that we've released the trolley.
	if is_instance_valid(mobile_controls):
		mobile_controls.update_visibility(is_with_trolley, nearby_trolley != null)
	print("Player released from trolley")

# --- Public Interface (GDD Support) ---

func get_is_with_trolley() -> bool:
	return is_with_trolley

func get_is_moving() -> bool:
	return is_moving

func set_can_move(value: bool):
	"""Enable/disable player movement (for UI/game state management)"""
	can_move = value
	if not can_move and is_moving:
		is_moving = false
		_set_animation_state(AnimationState.IDLE)

func get_current_position_meters() -> float:
	"""Returns current position in meters (GDD: 400m platform)"""
	return position.x / 20.0

func teleport_to_position(new_position: Vector2):
	"""Teleports player to a specific PIXEL position and resets its state."""
	global_position = new_position
	target_position = new_position # If you use this for discrete movement
	velocity = Vector2.ZERO      # Stop any current movement
	is_moving = false            # Reset any movement state flags
	_set_animation_state(AnimationState.IDLE)
	print("Player teleported to: ", new_position)

#func get_direction_to_trolley() -> int:
	#"""
	#Returns a direction vector towards the nearest trolley.
	#Returns 0 if no trolley is nearby.
	#1 for right, -1 for left.
	#"""
	#if nearby_trolley and not is_with_trolley:
		#if nearby_trolley.global_position.x > global_position.x:
			#return 1
		#else:
			#return -1
	#return 0

# Animation state getters for external systems
func is_idle() -> bool:
	return current_animation_state == AnimationState.IDLE

func is_walking() -> bool:
	return current_animation_state == AnimationState.WALK

func is_pushing() -> bool:
	return current_animation_state == AnimationState.PUSH

func is_pulling() -> bool:
	return current_animation_state == AnimationState.PULL
