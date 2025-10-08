extends RigidBody2D

# Remove class_name to avoid conflicts if needed
# class_name Trolley

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var player_point_right: Marker2D = $PlayerPointRight
@onready var player_point_left: Marker2D = $PlayerPointLeft
@onready var wheel_holder_right: PinJoint2D = $WheelHolderRight
@onready var wheel_holder_left: PinJoint2D = $WheelHolderLeft
@onready var wheel_right: RigidBody2D = $WheelHolderRight/Wheel
@onready var wheel_left: RigidBody2D = $WheelHolderLeft/Wheel
@onready var left_trolley_wheel_position: Marker2D = $LeftTrolleyWheelPosition
@onready var right_trolley_wheel_position: Marker2D = $RightTrolleyWheelPosition
@onready var right_collision: CollisionShape2D = $RightCollision
@onready var left_collision: CollisionShape2D = $LeftCollision
@onready var LuggageSpriteLeft: Sprite2D = $LuggageHolder/Luggage/LuggageSpriteLeft
@onready var LuggageSpriteRight: Sprite2D = $LuggageHolder/Luggage/LuggageSpriteRight
@onready var PickUpText: RichTextLabel = $Text


# Trolley state (GDD Implementation)
var is_occupied: bool = false
var current_player = null  # Changed from Player type to avoid conflicts
var trolley_direction: int = 1  # 1 = handle on right, -1 = handle on left (GDD requirement)
var can_flip: bool = true
var flip_cooldown: float = 1.0  # GDD: 1 second flip animation
var flip_timer: float = 0.0

func _ready():
	print("Trolley initializing...")
	
	# Initialize interaction area connections (GDD: proximity-based interaction)
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	PickUpText.hide()
	
	# Set physics properties (GDD: controlled trolley movement)
	gravity_scale = 0
	lock_rotation = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	
	# Initialize trolley direction (GDD: handle direction matters)
	set_trolley_direction(1)
	print("Trolley initialized with handle direction: ", trolley_direction)

func _process(delta):
	# Handle flip cooldown (GDD: prevent flip spam)
	if not can_flip:
		flip_timer += delta
		if flip_timer >= flip_cooldown:
			can_flip = true
			flip_timer = 0.0

# --- Interaction System (GDD: F key pickup) ---

#func _on_body_entered(body: Node2D):
	#"""Player enters trolley interaction area - make trolley available for pickup"""
	#if body.has_method("set_nearby_trolley") and not is_occupied:
		#body.set_nearby_trolley(self)
		#print("Player entered trolley area - trolley available for pickup")
#
#func _on_body_exited(body: Node2D):
	#"""Player leaves trolley interaction area - remove availability"""
	#if body.has_method("set_nearby_trolley") and body.nearby_trolley == self:
		#body.set_nearby_trolley(null)
		#print("Player left trolley area")
		
func _on_body_entered(body: Node2D):
	"""Player enters trolley interaction area - make trolley available for pickup"""
	if body is CharacterBody2D and body.has_method("set_nearby_trolley"):
		if not is_occupied:
			body.set_nearby_trolley(self)
			PickUpText.show()
			print("Trolley: Player has entered my area.")


func _on_body_exited(body: Node2D):
	"""Player leaves trolley interaction area - remove availability"""
	if body is CharacterBody2D and body.has_method("set_nearby_trolley"):
		# IMPORTANT: Only clear the player's nearby trolley if it's THIS trolley.
		# This prevents a different trolley from clearing the wrong reference.
		if body.nearby_trolley == self:
			body.set_nearby_trolley(null)
			PickUpText.hide()
			print("Trolley: Player has left my area.")

# --- Movement System (GDD: 2m discrete movement) ---

func set_movement_mode(is_moving: bool):
	"""Controls trolley physics during movement (GDD: smooth 2m movement)"""
	if is_moving:
		freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	else:
		freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		linear_velocity = Vector2.ZERO
		
#reset everything in trolley
func reset_for_new_delivery():
	"""Resets all variables for the start of a new delivery."""
	print("DEBUG_TROLLEY: Resetting state for new delivery.")
	is_occupied = false
	current_player = null
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	
	# This is still a good idea to force-clear the physics engine's memory
	interaction_area.monitoring = false
	await get_tree().process_frame
	interaction_area.monitoring = true

# --- Handle Direction System (GDD: Critical thinking mechanic) ---

func flip_trolley():
	"""Flips trolley handle direction (GDD: Level 2 mechanic with 1s animation)"""
	if not can_flip or not is_occupied:
		print("Cannot flip trolley - either on cooldown or not occupied")
		return
		
	print("Flipping trolley...")
	
	# Start flip cooldown (GDD: 1 second animation time)
	can_flip = false
	flip_timer = 0.0
	
	# Store old position for smooth transition
	var old_player_pos = current_player.position
	
	# Toggle handle direction (GDD: switch between push/pull positions)
	trolley_direction *= -1
	
	# Update trolley visual and physics state
	set_trolley_direction(trolley_direction)
	
	# Ensure smooth player transition (GDD: automatic repositioning)
	#_update_player_position(old_player_pos)
	
	print("Trolley flipped - new handle direction: ", "right" if trolley_direction == 1 else "left")

func set_trolley_direction(direction: int):
	"""
	Sets the trolley's handle direction. This is the final version with
	the wheel visibility logic corrected to match the visual requirement.
	"""
	trolley_direction = direction

	# 1. Reset Wheel Holder Positions (Failsafe)
	wheel_holder_right.position = right_trolley_wheel_position.position
	wheel_holder_left.position = left_trolley_wheel_position.position

	# 2. Update Collision Shapes
	right_collision.disabled = (direction != 1)
	left_collision.disabled = (direction == 1)

	# 3. Update Wheel Physics and Visibility (### THIS BLOCK IS NOW CORRECTED ###)
	if direction == -1:  # Handle is on the LEFT (default state)
		# To show the LEFT handle, we need the RIGHT wheel system visible.
		wheel_right.visible = true
		wheel_left.visible = false
		print("Trolley handle set to LEFT (Right Wheel Active)")
	else:  # Handle is on the RIGHT (direction = 1, flipped state)
		# To show the RIGHT handle, we need the LEFT wheel system visible.
		wheel_left.visible = true
		wheel_right.visible = false
		print("Trolley handle set to RIGHT (Left Wheel Active)")

	# 4. Update Main Sprite Visual
	animated_sprite.flip_h = (direction == 1)
	LuggageSpriteLeft.visible = (direction != 1)
	LuggageSpriteRight.visible = (direction == 1)

#func _update_player_position(old_pos: Vector2):
	#"""Updates player position after trolley flip (GDD: automatic repositioning)"""
	#if not current_player or not is_occupied:
		#return
	#
	#print("DEBUG: Trolley _update_player_position called")
	#print("  Player position BEFORE: ", current_player.global_position)
	#print("  Trolley position: ", global_position)
		#
	#var target_point = player_point_right if trolley_direction == 1 else player_point_left
	#var new_pos = position + target_point.position
	#
	#print("  Calculated new player position: ", new_pos)
	#
	## Update player position smoothly
	#current_player.position = new_pos
	#current_player.target_position = new_pos
	#
	#print("  Player position AFTER: ", current_player.global_position)
	#print("Player repositioned to: ", "right" if trolley_direction == 1 else "left", " side of trolley")


func _start_trolley_tracking():
	"""Track trolley state for 3 seconds after equip"""
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.5
	timer.timeout.connect(_on_trolley_debug_timer)
	timer.start()
	
	set_meta("debug_timer_count", 0)
	set_meta("debug_timer_instance", timer)

func _on_trolley_debug_timer():
	"""Track trolley state every 0.5 seconds"""
	var count = get_meta("debug_timer_count", 0)
	var timer = get_meta("debug_timer_instance", null)
	
	count += 1
	set_meta("debug_timer_count", count)
	
	var time_elapsed = count * 0.5
	print("TROLLEY T+", time_elapsed, "s - Position: ", global_position)
	print("TROLLEY T+", time_elapsed, "s - Visible: ", visible)
	print("TROLLEY T+", time_elapsed, "s - Valid: ", is_instance_valid(self))
	print("TROLLEY T+", time_elapsed, "s - Freeze mode: ", freeze_mode)
	print("TROLLEY T+", time_elapsed, "s - In scene tree: ", is_inside_tree())
	
	# Stop after 3 seconds
	if count >= 6:
		print("=== TROLLEY TRACKING COMPLETE ===")
		if timer and is_instance_valid(timer):
			timer.queue_free()
		remove_meta("debug_timer_count")
		remove_meta("debug_timer_instance")
		
		
# --- Trolley Pickup/Release System (GDD: F key interaction) ---

func equip_trolley(player):
	"""Player picks up trolley using F key (GDD: interaction system)"""
	if is_occupied:
		print("Trolley already occupied!")
		return
		
	print("=== TROLLEY EQUIP DEBUG START ===")
	print("Trolley position before equip: ", global_position)
	print("Trolley visible before equip: ", visible)
	print("Trolley freeze_mode before equip: ", freeze_mode)
	
	is_occupied = true
	current_player = player
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	
	print("Trolley freeze_mode after setting: ", freeze_mode)
	
	PickUpText.hide()
	
	GameManager.start_delivery_timer()
	
	# Call player's interaction method
	player.interact_with_trolley(self)
	
	print("Trolley position after player interaction: ", global_position)
	print("Trolley visible after player interaction: ", visible)
	print("=== TROLLEY EQUIP DEBUG END ===")
	
	# Start a timer to track trolley state over time
	_start_trolley_tracking()
	
	print("Trolley equipped - handle direction: ", "right" if trolley_direction == 1 else "left")
	
	
func hide_and_disable():
	"""Makes the trolley invisible and disables its physics and interactions."""
	print("Hiding and disabling trolley.")
	visible = false
	
	# --- FIX: Use the correct @onready var names ---
	# Disable both collision shapes, as we don't know which one is active.
	if right_collision:
		right_collision.disabled = true
	if left_collision:
		left_collision.disabled = true
	# -----------------------------------------------

	# Disable the interaction area
	if interaction_area:
		interaction_area.monitoring = false

func show_and_enable():
	"""Makes the trolley visible and enables its physics and interactions."""
	print("Showing and enabling trolley.")
	visible = true

	# --- FIX: Use the correct @onready var names ---
	# The trolley's internal logic will decide which shape should be enabled,
	# so we just need to re-enable them both here. The 'disabled' property
	# on the node itself will be controlled by the _set_trolley_direction logic.
	if right_collision:
		right_collision.disabled = false
	if left_collision:
		left_collision.disabled = false
	# -----------------------------------------------
	
	# Re-enable the interaction area
	if interaction_area:
		interaction_area.monitoring = true

#func release_trolley():
	#"""Player releases trolley (GDD: F key release or automatic)"""
	#if not is_occupied:
		#print("Trolley not occupied!")
		#return
		#
	#print("Releasing trolley")
	#is_occupied = false
	#
	#if current_player:
		## Make trolley available for pickup again
		#current_player.set_nearby_trolley(self)
		#current_player.release_trolley()
		#current_player = null
	#
	## Set trolley to static mode when not in use
	#freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	#print("Trolley released and available for pickup")
	
#func release_trolley():
	#"""
	#Releases the trolley, resetting its state. This should only manage the trolley's
	#own variables and nodes.
	#"""
	#if not is_occupied:
		#return
		#
	#print("Releasing trolley...")
	#is_occupied = false
	#current_player = null # The trolley forgets the player
	#
	## Set trolley to static mode so it doesn't slide away
	#freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	#
	## --- THIS IS THE FIX FOR THE INTERACTION BUG ---
	## We briefly disable and re-enable monitoring on the InteractionArea.
	## This forces Godot to re-evaluate what bodies are inside, clearing its "memory".
	#interaction_area.monitoring = false
	#await get_tree().process_frame # Wait for one physics frame
	#interaction_area.monitoring = true
	## ------------------------------------------------
	#
	#print("Trolley released and available for next interaction.")
func release_trolley():
	"""Releases the trolley, resetting its state."""
	if not is_occupied:
		return
		
	print("Releasing trolley...")
	is_occupied = false
	current_player = null
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	
	# After releasing, we need to immediately check if the player is still physically
	# inside our interaction area. If so, we must re-set them as the nearby trolley.
	# This fixes the bug where body_entered doesn't fire again.
	await get_tree().process_frame # Wait one frame for physics to settle
	
	for body in interaction_area.get_overlapping_bodies():
		if body is CharacterBody2D and body.has_method("set_nearby_trolley"):
			body.set_nearby_trolley(self)
			PickUpText.show()
			print("Trolley: Re-checking after release. Player is still inside my area.")
			# We only need to do this for the first one we find
			break

	print("Trolley released and available for next interaction.")

# --- Getter Methods (GDD: Game system integration) ---

func get_is_occupied() -> bool:
	"""Returns if trolley is currently being used by a player"""
	return is_occupied

func get_current_player():
	"""Returns the player currently using this trolley"""
	return current_player

func get_trolley_direction() -> int:
	"""Returns handle direction: 1 = right, -1 = left (GDD: critical for push/pull logic)"""
	return trolley_direction

func get_handle_side() -> String:
	"""Returns human-readable handle direction for debugging"""
	return "right" if trolley_direction == 1 else "left"

# --- Debug Methods ---

func debug_trolley_state():
	"""Prints current trolley state for debugging"""
	print("=== TROLLEY DEBUG ===")
	print("Occupied: ", is_occupied)
	print("Handle Direction: ", get_handle_side())
	print("Can Flip: ", can_flip)
	print("Flip Timer: ", flip_timer)
	print("Position: ", position)
	if current_player:
		print("Player Position: ", current_player.position)
	print("===================")

# --- GDD Compliance Notes ---
# This trolley system implements:
# 1. Handle direction system (critical thinking for push/pull)
# 2. F key pickup/release interaction
# 3. Automatic player positioning based on handle direction
# 4. Flip trolley power with 1-second cooldown (Level 2)
# 5. Physics-based movement for 2m discrete movements
# 6. Visual feedback through sprite flipping
