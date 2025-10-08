extends Area2D

# Signal to announce the delivery is complete
signal delivery_achieved

# We will tell the zone which body to wait for (the trolley)
var target_body: RigidBody2D = null
@onready var Arrow: Sprite2D = $Arrow
@onready var DialogueBubble: Sprite2D = $DialogueBubble
var DialogueBubble_scale: Vector2 

var idle_tween: Tween

func _ready():
	# Connect the signal for when a body enters this area
	body_entered.connect(_on_body_entered)
	DialogueBubble_scale = DialogueBubble.scale
	
	# MODIFIED: Start visible but not monitoring (instead of completely hidden)
	monitoring = false
	visible = true  # CHANGED: Keep visible, just disable monitoring
	
	# Force sprites to stay visible even off-screen
	Arrow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	DialogueBubble.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	
	# Disable automatic culling
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	DialogueBubble.hide()
	Arrow.show()
	_animate_arrow_idle()
	
	print("DeliveryZone: Initialized - visible but not monitoring")

#func setup_delivery_zone(track_body: RigidBody2D):
	#"""
	#Called by the LevelController to activate the zone for a new delivery.
	#This also resets the visuals to their default state.
	#"""
	#target_body = track_body
	#
	## Reset state for the new delivery
	#monitoring = true
	#visible = true
	#Arrow.show()
	#DialogueBubble.hide()
	## Ensure the bubble scale is reset from the previous animation
	#DialogueBubble.scale = Vector2.ONE 
	
func setup_delivery_zone(track_body: RigidBody2D):
	"""
	Called by the LevelController to activate the zone for a new delivery.
	This also resets the visuals to their default state.
	"""
	print("DeliveryZone: Setting up for new delivery at position ", global_position)
	
	target_body = track_body
	
	# Reset state for the new delivery
	monitoring = true
	visible = true
	Arrow.show()
	DialogueBubble.hide()
	DialogueBubble.scale = Vector2.ONE
	
	# NEW: Force visibility to prevent culling issues
	force_visibility()
	
	# NEW: Use call_deferred to ensure visibility sticks
	call_deferred("force_visibility")
	
	print("DeliveryZone: Setup complete - monitoring enabled, visibility forced")


func force_visibility():
	"""Forces the delivery zone to be visible regardless of camera position"""
	visible = true
	Arrow.visible = true
	
	# Force sprite updates
	Arrow.force_update_transform()
	DialogueBubble.force_update_transform()
	
	# Ensure arrow animation is running
	if not (idle_tween and idle_tween.is_running()):
		_animate_arrow_idle()
	
	print("DeliveryZone: Visibility forced at position ", global_position)
	
	
func _process(delta):
	# Only check visibility when monitoring (active delivery)
	if monitoring and not visible:
		print("DeliveryZone: Detected hidden state during active delivery - forcing visible")
		force_visibility()
		
		
func _on_body_entered(body: RigidBody2D):
	# We use two checks:
	# 1. Is it the correct body (the trolley)?
	# 2. Is the zone still monitoring? (This prevents the code from running multiple times)
	if body == target_body and monitoring:
		# --- START OF NEW ANIMATION SEQUENCE ---
		
		# Immediately disable monitoring to prevent re-triggering while animating.
		monitoring = false 
				# 5. Now, run the original completion logic.
		print("DeliveryZone: Correct target reached! Emitting signal.")
		emit_signal("delivery_achieved")
		# 1. Hide the arrow and prepare the bubble for its pop-in animation.
		Arrow.hide()
		DialogueBubble.scale = Vector2.ZERO # Start invisible and tiny
		DialogueBubble.show()
		
		# 2. Create the "pop" animation using a tween.
		var tween = create_tween()
		# Animate the scale from 0 to 1 in 0.4 seconds.
		# TRANS_BACK creates a nice overshoot effect, making it feel like a "pop".
		tween.tween_property(DialogueBubble, "scale", DialogueBubble_scale, 0.4)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
		# 3. Wait for the pop animation to finish.
		await tween.finished
		
		# 4. Wait for 2 seconds while the bubble is visible.
		await get_tree().create_timer(2.0).timeout
		
		# --- END OF NEW ANIMATION SEQUENCE ---
		

		
		# 6. Finally, hide the entire delivery zone node.
		# The setup_delivery_zone() function will handle making it visible again.
		visible = false

func _animate_arrow_idle():
	if idle_tween and idle_tween.is_running():
		idle_tween.kill()

	var start_pos = Arrow.position
	var bob_offset = Vector2(0, -100) # Made the bob a bit smaller for subtlety

	idle_tween = create_tween()
	idle_tween.set_loops()

	idle_tween.tween_property(Arrow, "position", start_pos + bob_offset, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(Arrow, "position", start_pos, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Note: The empty _on_body_exited and _on_ready functions were removed for clarity.
