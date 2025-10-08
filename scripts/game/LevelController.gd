extends Node2D

# --- Node References ---
@export var player: CharacterBody2D
@export var trolley: RigidBody2D
var delivery_zone: Area2D

#@onready var event_manager: EventManager = $EventManager


# Reference to the parent node holding all our markers
@export var delivery_markers_container: Node2D 
@onready var pause_menu: Control = $UI/PauseMenu
@onready var game_ui: Control = $UI/GameUI
@onready var CompletionUI: Control = $UI/CompletionUI
@onready var MobileControls: Control = $"UI/MobileControls"
@onready var EventDisplayUI: Control = $UI/EventDisplayUI


# This dictionary will store our major marker positions for quick lookups
var marker_positions = {}

const DeliveryZoneScene = preload("res://scene/game/DeliveryZone.tscn")
const TrolleyScene = preload("res://scene/objects/trolley_new.tscn")
var active_trolley: RigidBody2D = null

func _ready():
	# --- Populate the marker dictionary with MAJOR markers (0, 100, 200, etc.) ---
	if delivery_markers_container:
		for marker in delivery_markers_container.get_children():
			if marker is Marker2D:
				var meter_value = int(marker.name)
				marker_positions[meter_value] = marker.global_position
				print("Found MAJOR marker: ", marker.name, " at position ", marker.global_position)
	else:
		push_warning("DeliveryMarkers container not set in LevelController!")
		
	# Connect to GameManager signals
	GameManager.level_started.connect(_on_level_started)
	GameManager.delivery_started.connect(_on_delivery_started)
	GameManager.pause_menu_instance = pause_menu
	GameManager.game_ui_instance = game_ui
	GameManager.completion_ui_instance = CompletionUI
	GameManager.mobile_controls_instance = MobileControls
	GameManager.event_display_instance = EventDisplayUI

	#event_manager.initialize_references(player, trolley, self)

	# Instantiate and add the delivery zone
	delivery_zone = DeliveryZoneScene.instantiate()
	add_child(delivery_zone)
	delivery_zone.delivery_achieved.connect(_on_delivery_achieved)
	
	
	
			## Add EventManager initialization
	#var event_manager = EventManager.new()
	#add_child(event_manager)
	#event_manager.initialize_references(player, trolley, self)
	
	# Start the game for testing
	#GameManager.start_level(2)
	#GameManager.start_game()

func _reset_all_ui_for_level(level_number: int):
	"""Reset all UI components for the new level"""
	print("LevelController: Resetting all UI for level ", level_number)
	
	# Make sure game is not paused
	get_tree().paused = false
	
	# Reset GameUI
	if game_ui:
		game_ui.visible = true
		game_ui.modulate.a = 1.0
	
	# Hide and reset CompletionUI
	if CompletionUI:
		CompletionUI.hide()
		if CompletionUI.has_method("_reset_for_new_level"):
			CompletionUI._reset_for_new_level()
	
	# Hide and reset PauseMenu
	if pause_menu:
		pause_menu.hide()
		pause_menu.is_paused = false
		pause_menu.is_animating = false
	
	# Update GameManager UI references
	GameManager.pause_menu_instance = pause_menu
	GameManager.game_ui_instance = game_ui
	GameManager.completion_ui_instance = CompletionUI

func _on_level_started(level_number: int):
	print("LevelController: Level ", level_number, " started")
	
	# Reset all UI states properly
	_reset_all_ui_for_level(level_number)
	
	# Reset player state
	player.reset_for_new_delivery()
	
	# Clean up any existing trolleys
	if trolley and is_instance_valid(trolley):
		trolley.queue_free()
		trolley = null
	if active_trolley and is_instance_valid(active_trolley):
		active_trolley.queue_free()
		active_trolley = null
	
	print("LevelController: Level ", level_number, " setup complete")

func spawn_new_trolley(position_meters: int, handle_direction: String) -> RigidBody2D:
	"""
	Spawns a completely fresh trolley at the specified position.
	Returns the new trolley instance.
	"""
	print("LevelController: Spawning new trolley at ", position_meters, "m")
	
	# Calculate spawn position
	var spawn_position = _calculate_position_from_meters(position_meters)
	spawn_position.y = 600
	
	# Create new trolley instance
	var new_trolley = TrolleyScene.instantiate()
	add_child(new_trolley)
	
	# Set position and properties
	new_trolley.global_position = spawn_position
	new_trolley.set_trolley_direction(1 if handle_direction == "right" else -1)
	# Force PlayerPoints to update their global positions
	var right_point = new_trolley.get_node("PlayerPointRight")
	var left_point = new_trolley.get_node("PlayerPointLeft") 
	if right_point:
		right_point.global_position = new_trolley.global_position + right_point.position
	if left_point:
		left_point.global_position = new_trolley.global_position + left_point.position
	
	# Ensure it's completely static and stable
	new_trolley.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	new_trolley.linear_velocity = Vector2.ZERO
	new_trolley.angular_velocity = 0.0
	new_trolley.visible = true
	# Mark this as a spawned trolley for debugging
	new_trolley.set_meta("is_spawned", true)
	
	# Ensure PlayerPoints are properly positioned
	await get_tree().process_frame 
	
	print("LevelController: New trolley spawned successfully at ", spawn_position)
	return new_trolley

# In LevelController.gd, add debug to destroy functions:
func destroy_active_trolley():
	"""Completely removes the current active trolley from the scene."""
	print("DEBUG: destroy_active_trolley called!")
	print("  Current active_trolley: ", active_trolley)
	print("  Is valid: ", is_instance_valid(active_trolley))
	
	if active_trolley and is_instance_valid(active_trolley):
		print("LevelController: Destroying active trolley at position: ", active_trolley.global_position)
		active_trolley.queue_free()
		active_trolley = null
	if trolley and is_instance_valid(trolley):
		trolley = null
		
		
# ---------------------------- NEW HELPER FUNCTION ----------------------------
func _calculate_position_from_meters(meters: int) -> Vector2:
	"""
	Calculates a precise pixel position by finding the closest major marker
	and adding a calculated pixel offset.
	"""
	print("--- Calculating position for ", meters, "m ---")

	# 1. Find the base marker (e.g., 170 -> 100, 280 -> 200)
	var base_marker_meters = (meters / 100) * 100 
	print("  Base marker determined to be: ", base_marker_meters, "m")
	
	if not marker_positions.has(base_marker_meters):
		push_error("Cannot calculate position! Major marker missing for base: " + str(base_marker_meters))
		return Vector2.ZERO

	# 2. Get the base marker's pixel position from our dictionary
	var base_position = marker_positions[base_marker_meters]
	print("  Base marker's stored pixel position is: ", base_position)
	
	# 3. Calculate the offset distance in meters
	var offset_meters = meters - base_marker_meters
	print("  Offset distance in meters: ", offset_meters, "m")
	
	# 4. Convert the offset meters to offset pixels using GameConstants
	var offset_pixels = GameConstants.meters_to_pixels(offset_meters)
	print("  Offset distance in pixels (using ", GameConstants.VISUAL.platform_pixels_per_meter, " px/m): ", offset_pixels, "px")
	
	# 5. Calculate the final position
	var final_position = Vector2(base_position.x + offset_pixels, base_position.y)
	print("  Final calculated pixel position: ", final_position, "\n") # Added newline for readability
	
	return final_position

func get_delivery_direction_for_object(object_position_meters: float) -> String:
	"""
	Helper function for other game objects to get delivery direction.
	They can call this instead of accessing GameManager directly.
	"""
	return GameManager.get_current_delivery_direction(object_position_meters)

# ---------------------------- UPDATED DELIVERY FUNCTION ----------------------------
#func _on_delivery_started(delivery_data: Dictionary):
	#print("LevelController: Received delivery order: ", delivery_data)
	#
	## --- This function now uses the helper to calculate all positions ---
	## Also reset at the start of every delivery leg to be extra safe.
	#player.reset_for_new_delivery()
	#trolley.reset_for_new_delivery()
	## --- YOUR FIX IMPLEMENTED HERE ---
#
	## 1. HIDE the trolley before moving it
	#trolley.hide_and_disable()
#
	## 2. TELEPORT the invisible trolley
	#var trolley_start_meters = int(delivery_data.trolley_pos)
	#trolley.global_position = _calculate_position_from_meters(trolley_start_meters)
	#trolley.set_trolley_direction(1 if delivery_data.handle == "right" else -1)
	#
	## We wait for one frame to ensure the position change is fully processed
	## before making it visible again. This prevents visual glitches.
	##await get_tree().process_frame
	#await get_tree().create_timer(1.5).timeout
#
	## 3. SHOW the trolley in its new location
	#trolley.show_and_enable()
	#
	## 2. Position the Player
	##player.release_trolley()
	##var player_start_meters = int(delivery_data.start)
	##var player_start_pos = _calculate_position_from_meters(player_start_meters)
	### Use the calculated X but keep the player's current Y to be safe
	##player.teleport_to_position(Vector2(player_start_pos.x, player.global_position.y))
#
	## 3. Position and activate the Delivery Zone
	#var destination_meters = int(delivery_data.destination)
	#delivery_zone.global_position = _calculate_position_from_meters(destination_meters)
	#delivery_zone.setup_delivery_zone(trolley)
	#
	## 4. Enable player controls
	#player.set_can_move(true)
	
func _on_delivery_started(delivery_data: Dictionary):
	print("LevelController: Received delivery order: ", delivery_data)
	
	# Reset player state
	player.reset_for_new_delivery()
	
	# 1. DISABLE delivery zone monitoring first
	delivery_zone.monitoring = false
	print("DeliveryZone: Monitoring disabled during setup")

	# 2. DESTROY old trolley completely (no teleportation!)
	if trolley and is_instance_valid(trolley):
		print("LevelController: Destroying old main trolley")
		trolley.queue_free()
		trolley = null
	if active_trolley and is_instance_valid(active_trolley):
		print("LevelController: Destroying old active trolley")
		active_trolley.queue_free()
		active_trolley = null
	
	# 3. Wait for destruction to complete
	await get_tree().process_frame
	
	# 4. SPAWN completely fresh trolley
	var trolley_start_meters = int(delivery_data.trolley_pos)
	var handle_direction = delivery_data.handle
	active_trolley = await spawn_new_trolley(trolley_start_meters, handle_direction)
	
	# 5. Update the main reference for other systems
	trolley = active_trolley
	
	## 6. Position the Delivery Zone
	#var destination_meters = int(delivery_data.destination)
	#delivery_zone.global_position = _calculate_position_from_meters(destination_meters)
	#delivery_zone.setup_delivery_zone(active_trolley)
	
	# 6. Position the Delivery Zone
	var destination_meters = int(delivery_data.destination)
	delivery_zone.global_position = _calculate_position_from_meters(destination_meters)
	delivery_zone.setup_delivery_zone(active_trolley)

	# NEW: Add extra visibility enforcement
	await get_tree().process_frame  # Let setup complete
	delivery_zone.force_visibility()  # Force visibility after positioning

	print("Delivery zone positioned and forced visible at: ", delivery_zone.global_position)

	# 7. Wait for everything to settle
	await get_tree().create_timer(0.5).timeout
	
	# 8. RE-ENABLE delivery zone monitoring
	delivery_zone.monitoring = true
	print("DeliveryZone: Monitoring re-enabled - ready for delivery")
	
	# 9. Enable player controls
	player.set_can_move(true)
	
	print("LevelController: Fresh trolley spawn complete - ready for delivery!")


func _on_delivery_achieved():
	print("LevelController: Delivery achieved! Notifying GameManager.")
	player.set_can_move(false)
	
	# Destroy the trolley immediately after delivery
	if active_trolley and is_instance_valid(active_trolley):
		print("LevelController: Destroying trolley after successful delivery")
		active_trolley.queue_free()
		active_trolley = null
	if trolley and is_instance_valid(trolley):
		trolley = null  # Clear the reference
	
	var delivery_data = GameManager.get_current_delivery_info()
	GameManager.emit_signal("delivery_succeeded", delivery_data, 0)
	GameManager.complete_delivery(true)


# Note: The extra empty _on_ready() function has been removed.
