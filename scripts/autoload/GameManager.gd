extends Node

signal game_started
signal game_paused
signal game_resumed
signal level_started(level_number: int)
signal level_completed(level_number: int, score: int)
signal delivery_started(delivery_data: Dictionary)
signal delivery_completed(success: bool, points: int)
signal game_ended(final_score: int, completed: bool)
# --- ADD NEW SIGNALS ---
signal delivery_timer_started(allotted_time: float)
signal delivery_timer_updated(time_remaining: float)
signal score_updated(new_total_score: int)
signal effort_updated(push_effort: float, pull_effort: float)

# Announce when the player performs a key action. We pass the nodes involved.
signal player_picked_up_trolley(player: CharacterBody2D, trolley: RigidBody2D)
signal player_moved_with_trolley(player: CharacterBody2D)
signal player_completed_first_move(player: CharacterBody2D)
signal delivery_succeeded(delivery_data: Dictionary, points_earned: int)
signal delivery_failed(delivery_data: Dictionary)
signal level_results_ready(level_number: int, level_score: int, successful_deliveries: int, total_deliveries: int)

var pause_menu_instance: Control = null
var game_ui_instance: Control = null
var completion_ui_instance: Control = null
var mobile_controls_instance: Control = null
var event_display_instance: Control = null

@onready var analytics = get_node("/root/AnalyticsManager")

# Add these new variables to GameManager (around line 30-40)
var current_delivery_destination_meters: float = 0.0

# Add these new signals
signal delivery_direction_changed(new_direction: String)


enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	DELIVERY_COMPLETE,
	LEVEL_COMPLETE,
	GAME_OVER
}

enum ForceType {
	NONE,
	PUSH,
	PULL
}

# Game state variables
var current_state := GameState.MENU
var current_level := 0
var current_delivery := 0
var total_score := 0
var level_score := 0
var is_transitioning := false
var successful_deliveries_this_level := 0

# Delivery tracking
var active_delivery = null
var delivery_start_time := 0.0
var delivery_time_remaining := 0.0 # REPLACES delivery_start_time
var trolley_at_destination := false


# --- ADD NEW VARIABLES ---
var delivery_is_timed := false
var allotted_time := 0.0
var push_effort: float = 100.0
var pull_effort: float = 100.0

# Level data storage
var level_scenarios = {}

# Scene management
var pending_level_start := 0

func _ready():
	# This line enables the _process function for this node.
	# It's set to ALWAYS so the timer can run even if the game is paused (optional).
	# You can change it to PROCESS_MODE_INHERIT if the timer should pause with the pause menu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_load_level_data()
	
		# Initialize analytics with user info
	# These values should come from your React Native app ideally
	analytics.set_user_info(
		"66f5fa2a9a1d4b2e34a17c01",  # userId - get from your auth system
		"grocery_delivery_game_id",   # gameId - unique for this game
		"Player Name"                 # player name - get from profile
	)
	
	# Add game-specific raw data
	analytics.add_raw_data("gameVersion", "1.0.0")
	analytics.add_raw_data("totalDeliveries", "0")
	
	# Connect to scene tree for handling scene changes (your existing code)
	if get_tree():
		get_tree().node_added.connect(_on_node_added)
		
		
func some_critical_function():
	analytics.track_executed_line("some_critical_function entered")
	
	# Wrap risky code in error check (simulate as Godot has limited try/catch)
	var error_occurred = false
	
	# Your logic
	# If error detected, call:
	if error_occurred:
		analytics.report_crash()
		return	
		
func _process(delta: float):
	"""
	This process loop runs every frame and is used to manage the delivery timer.
	"""
	# Check if a timed delivery is currently active
	if delivery_is_timed and current_state == GameState.PLAYING:
		# The old time calculation is replaced with a simple countdown
		delivery_time_remaining -= delta

		# Send a signal with the remaining time for the UI to display
		emit_signal("delivery_timer_updated", delivery_time_remaining)

		# Check if the player has run out of time
		if delivery_time_remaining <= 0:
			print("GameManager: Delivery timed out!")
			delivery_is_timed = false # Stop the timer logic
			# Call the complete_delivery function with 'success = false'
			emit_signal("delivery_failed", active_delivery)
			complete_delivery(false)
			
	# --- Block 2: Effort Meter Recharging Logic (Corrected) ---
	# It will only run if we are in PLAYING state AND the feature is enabled.
	if (current_state == GameState.PLAYING or current_state == GameState.DELIVERY_COMPLETE) and GameConstants.is_feature_enabled(current_level, "effort_meters"):
		var config = GameConstants.LEVEL_CONFIG[current_level]
		var recharge_rate = config.effort_recharge_rate
		var max_effort = config.max_effort
		var recharge_amount = recharge_rate * delta
		var needs_ui_update = false
		
		if push_effort < max_effort:
			push_effort = min(push_effort + recharge_amount, max_effort)
			needs_ui_update = true
		if pull_effort < max_effort:
			pull_effort = min(pull_effort + recharge_amount, max_effort)
			needs_ui_update = true
		
		if needs_ui_update:
			emit_signal("effort_updated", push_effort, pull_effort)

func can_use_effort(force_type: String) -> bool:
	if not GameConstants.is_feature_enabled(current_level, "effort_meters"): # FIX: Added GameConstants prefix
		return true

	var cost = GameConstants.LEVEL_CONFIG[current_level].effort_cost_per_tap # FIX: Added GameConstants prefix
	if force_type == "push" and push_effort >= cost:
		return true
	if force_type == "pull" and pull_effort >= cost:
		return true
	
	return false
	

func spend_effort(force_type: String):
	if not GameConstants.is_feature_enabled(current_level, "effort_meters"): # FIX: Added GameConstants prefix
		return

	var cost = GameConstants.LEVEL_CONFIG[current_level].effort_cost_per_tap # FIX: Added GameConstants prefix
	if force_type == "push":
		push_effort -= cost
	elif force_type == "pull":
		pull_effort -= cost
	
	emit_signal("effort_updated", push_effort, pull_effort)

func _on_node_added(node: Node):
	# Check if Level1_Proto scene was loaded and we're waiting to start
	if pending_level_start > 0 and node.name == "Level1" and node.scene_file_path == "res://levels/Level1_Proto.tscn":
		_handle_level_loaded()

func _handle_level_loaded():
	var level = pending_level_start
	pending_level_start = 0
	
	# Give the scene a moment to initialize
	call_deferred("_finish_level_start", level)

func _finish_level_start(level_number: int):
	emit_signal("level_started", level_number)
	# Small delay to ensure everything is ready
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(func(): 
		_start_next_delivery()
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func _load_level_data():
	# Load delivery scenarios from GDD
	#level_scenarios = {
		#1: {  # Level 1 scenarios
			#"sets": {
				#"A": [
					#{"distance": 30.0, "direction": "left", "start": 200.0, "trolley_pos": 200.0, "handle": "left", "destination": 230.0},
					#{"distance": 40.0, "direction": "right", "start": 230.0, "trolley_pos": 170.0, "handle": "right", "destination": 130.0},
					#{"distance": 20.0, "direction": "right", "start": 130.0, "trolley_pos": 210.0, "handle": "left", "destination": 230.0},
					#{"distance": 50.0, "direction": "left", "start": 230.0, "trolley_pos": 160.0, "handle": "left", "destination": 110.0},
					#{"distance": 60.0, "direction": "right", "start": 110.0, "trolley_pos": 190.0, "handle": "right", "destination": 250.0}
				#],
				#"B": [
					#{"distance": 20.0, "direction": "left", "start": 200.0, "trolley_pos": 180.0, "handle": "left", "destination": 160.0},
					#{"distance": 30.0, "direction": "right", "start": 160.0, "trolley_pos": 220.0, "handle": "right", "destination": 250.0},
					#{"distance": 40.0, "direction": "left", "start": 250.0, "trolley_pos": 160.0, "handle": "left", "destination": 120.0},
					#{"distance": 10.0, "direction": "right", "start": 120.0, "trolley_pos": 200.0, "handle": "left", "destination": 210.0},
					#{"distance": 60.0, "direction": "left", "start": 210.0, "trolley_pos": 140.0, "handle": "right", "destination": 80.0}
				#],
				#"C": [
					#{"distance": 50.0, "direction": "right", "start": 200.0, "trolley_pos": 250.0, "handle": "left", "destination": 300.0},
					#{"distance": 40.0, "direction": "left", "start": 300.0, "trolley_pos": 190.0, "handle": "right", "destination": 150.0},
					#{"distance": 60.0, "direction": "right", "start": 150.0, "trolley_pos": 260.0, "handle": "right", "destination": 320.0},
					#{"distance": 30.0, "direction": "left", "start": 320.0, "trolley_pos": 200.0, "handle": "left", "destination": 170.0},
					#{"distance": 20.0, "direction": "right", "start": 170.0, "trolley_pos": 210.0, "handle": "right", "destination": 230.0}
				#]
			#},
			#"current_set": ""
		#},
		#2: {  # Level 2 scenarios
			#"sets": {
				#"A": [
					#{"distance": 80.0, "direction": "left", "start": 200.0, "trolley_pos": 250.0, "handle": "right", "destination": 120.0},
					#{"distance": 60.0, "direction": "right", "start": 120.0, "trolley_pos": 260.0, "handle": "left", "destination": 320.0},
					#{"distance": 100.0, "direction": "left", "start": 320.0, "trolley_pos": 100.0, "handle": "right", "destination": 0.0},
					#{"distance": 90.0, "direction": "right", "start": 0.0, "trolley_pos": 280.0, "handle": "right", "destination": 370.0},
					#{"distance": 70.0, "direction": "left", "start": 370.0, "trolley_pos": 190.0, "handle": "left", "destination": 120.0}
				#],
				#"B": [
					#{"distance": 60.0, "direction": "right", "start": 200.0, "trolley_pos": 200.0, "handle": "right", "destination": 260.0},
					#{"distance": 90.0, "direction": "left", "start": 260.0, "trolley_pos": 150.0, "handle": "left", "destination": 60.0},
					#{"distance": 100.0, "direction": "right", "start": 60.0, "trolley_pos": 200.0, "handle": "right", "destination": 300.0},
					#{"distance": 70.0, "direction": "left", "start": 300.0, "trolley_pos": 120.0, "handle": "right", "destination": 50.0},
					#{"distance": 80.0, "direction": "right", "start": 50.0, "trolley_pos": 240.0, "handle": "left", "destination": 320.0}
				#],
				#"C": [
					#{"distance": 50.0, "direction": "left", "start": 200.0, "trolley_pos": 200.0, "handle": "right", "destination": 150.0},
					#{"distance": 100.0, "direction": "right", "start": 150.0, "trolley_pos": 200.0, "handle": "left", "destination": 300.0},
					#{"distance": 90.0, "direction": "left", "start": 300.0, "trolley_pos": 180.0, "handle": "right", "destination": 90.0},
					#{"distance": 70.0, "direction": "right", "start": 90.0, "trolley_pos": 260.0, "handle": "right", "destination": 330.0},
					#{"distance": 80.0, "direction": "left", "start": 330.0, "trolley_pos": 210.0, "handle": "left", "destination": 130.0}
				#]
			#},
			#"current_set": ""
		#}
	#}
			level_scenarios = {
	1: {  # Level 1 - Corrected with ALL rules
"sets": {
			"A": [
				# Player at 200, Trolley at 150 (Left). Move Right to 210.
				{"distance": 50.0, "direction": "left", "start": 200.0, "trolley_pos": 150.0, "handle": "right", "destination": 210.0},
				# Player at 210, Trolley at 280 (Right). Move Left to 210.
				{"distance": 40.0, "direction": "right", "start": 210.0, "trolley_pos": 280.0, "handle": "left", "destination": 240.0},
				# Player at 210, Trolley at 130 (Left). Move Right to 210.
				{"distance": 80.0, "direction": "left", "start": 240.0, "trolley_pos": 130.0, "handle": "right", "destination": 160.0},
				# Player at 210, Trolley at 300 (Right). Move Left to 240.
				{"distance": 90.0, "direction": "right", "start": 160.0, "trolley_pos": 250.0, "handle": "left", "destination": 340.0},
				# Player at 240, Trolley at 150 (Left). Move Right to 240.
				{"distance": 60.0, "direction": "left", "start": 340.0, "trolley_pos": 280.0, "handle": "right", "destination": 200.0}
			],
			"B": [
				{"distance": 50.0, "direction": "right", "start": 200.0, "trolley_pos": 250.0, "handle": "left", "destination": 180.0},
				{"distance": 100.0, "direction": "left", "start": 180.0, "trolley_pos": 100.0, "handle": "right", "destination": 200.0},
				{"distance": 90.0, "direction": "right", "start": 200.0, "trolley_pos": 290.0, "handle": "left", "destination": 130.0},
				{"distance": 70.0, "direction": "right", "start": 130.0, "trolley_pos": 200.0, "handle": "left", "destination": 350.0},
				{"distance": 100.0, "direction": "left", "start": 350.0, "trolley_pos": 250.0, "handle": "right", "destination":200.0}
			],
			"C": [
			
				{"distance": 80.0, "direction": "left", "start": 200.0, "trolley_pos": 120.0, "handle": "right", "destination": 250.0},
			
				{"distance": 60.0, "direction": "right", "start": 250.0, "trolley_pos": 310.0, "handle": "left", "destination": 240.0},
			 
				{"distance": 80.0, "direction": "left", "start": 240.0, "trolley_pos": 160.0, "handle": "right", "destination": 210.0},
			
				{"distance": 140.0, "direction": "right", "start": 210.0, "trolley_pos": 350.0, "handle": "left", "destination": 280.0},
			  
				{"distance": 80.0, "direction": "left", "start": 280.0, "trolley_pos": 100.0, "handle": "right", "destination": 200.0}
			]
		}
	},
	2: {  # Level 2 - Corrected with ALL rules
		"sets": {
			"A": [
				{"distance": 70.0, "direction": "left", "start": 200.0, "trolley_pos": 130.0, "handle": "right", "destination": 220.0},
				{"distance": 40.0, "direction": "right", "start": 220.0, "trolley_pos": 260.0, "handle": "left", "destination": 320.0},
				{"distance": 30.0, "direction": "left", "start": 320.0, "trolley_pos": 290.0, "handle": "right", "destination": 10.0},
				{"distance": 60.0, "direction": "right", "start": 10.0, "trolley_pos": 70.0, "handle": "right", "destination": 370.0},
				{"distance": 40.0, "direction": "left", "start": 370.0, "trolley_pos": 330.0, "handle": "left", "destination": 200.0}
			],
			"B": [
			
				
				{"distance": 50.0, "direction": "right", "start": 200.0, "trolley_pos": 250.0, "handle": "right", "destination": 300.0},
				
				{"distance": 50.0, "direction": "left", "start": 300.0, "trolley_pos": 250.0, "handle": "left", "destination": 60.0},
				
			
				{"distance": 30.0, "direction": "right", "start": 60.0, "trolley_pos": 90.0, "handle": "right", "destination": 300.0},
			
				{"distance": 90.0, "direction": "left", "start": 300.0, "trolley_pos": 210.0, "handle": "right", "destination": 50.0},
				{"distance": 30.0, "direction": "right", "start": 50.0, "trolley_pos": 80.0, "handle": "left", "destination": 200.0}
			],
			"C": [
			
				
				{"distance": 40.0, "direction": "left", "start": 200.0, "trolley_pos": 160.0, "handle": "right", "destination": 130.0},
				
				
				{"distance": 80.0, "direction": "right", "start": 130.0, "trolley_pos": 210.0, "handle": "left", "destination": 300.0},
				
				{"distance": 40.0, "direction": "left", "start": 300.0, "trolley_pos": 260.0, "handle": "right", "destination": 90.0},
				{"distance": 60.0, "direction": "left", "start": 90.0, "trolley_pos": 170.0, "handle": "right", "destination": 250.0},
				{"distance": 20.0, "direction": "right", "start": 250.0, "trolley_pos": 270.0, "handle": "left", "destination":100.0}
			]
}
	}
}


func start_game():
	current_state = GameState.PLAYING
	total_score = 0
	emit_signal("game_started")
	start_level(1)

func start_level(level_number: int):
	print("GameManager: Starting level ", level_number)
	
	# Set level state
	current_level = level_number
	level_score = 0
	current_delivery = 0
	successful_deliveries_this_level = 0
	current_state = GameState.PLAYING
	
		# Analytics: Start tracking this level
	analytics.start_level("L" + str(level_number), true)  # true = faster time is better
	
	# Reset effort meters for new level
	if GameConstants.is_feature_enabled(current_level, "effort_meters"):
		var max_effort = GameConstants.LEVEL_CONFIG[current_level].max_effort
		push_effort = max_effort
		pull_effort = max_effort
	else:
		push_effort = 9999
		pull_effort = 9999
	
	# Always update effort UI at level start
	emit_signal("effort_updated", push_effort, pull_effort)
	
	# Select random set for this level
	if level_number in level_scenarios:
		var sets = level_scenarios[level_number].sets.keys()
		level_scenarios[level_number].current_set = sets[randi() % sets.size()]
	
	# Make sure we're in the right scene
	var current_scene = get_tree().current_scene if get_tree() else null
	if current_scene and current_scene.scene_file_path == "res://levels/Level1_Proto.tscn":
		# Already in correct scene
		emit_signal("level_started", level_number)
		
		# Wait a moment then start first delivery
		var timer = Timer.new()
		timer.wait_time = 1.0  # Longer delay to ensure everything is ready
		timer.one_shot = true
		timer.timeout.connect(func(): 
			print("GameManager: Starting first delivery for level ", level_number)
			_start_next_delivery()
			timer.queue_free()
		)
		add_child(timer)
		timer.start()
	else:
		# Need to load level scene
		var level_scene_path = "res://levels/Level%d_Proto.tscn" % level_number
		if not ResourceLoader.exists(level_scene_path):
			level_scene_path = "res://levels/Level1_Proto.tscn"
		
		pending_level_start = level_number
		
		if get_tree():
			get_tree().change_scene_to_file(level_scene_path)
		else:
			push_error("Cannot start level - no scene tree available")

func get_delivery_direction_from_position(player_position_meters: float) -> String:
	"""
	Returns the direction the player needs to go to reach the delivery destination.
	Returns "right" if destination is to the right, "left" if to the left.
	"""
	if current_delivery_destination_meters == 0.0:
		return "right"  # Default fallback
	
	if current_delivery_destination_meters > player_position_meters:
		return "right"
	else:
		return "left"
		
# Add this function to get current delivery direction for any game object
func get_current_delivery_direction(player_position_meters: float) -> String:
	"""
	Public API for getting delivery direction. Other game objects can call this.
	"""
	return get_delivery_direction_from_position(player_position_meters)

# Add this function to update delivery direction and notify listeners
func update_delivery_direction(player_position_meters: float):
	"""
	Updates and broadcasts delivery direction changes.
	Call this when player position changes significantly.
	"""
	var new_direction = get_delivery_direction_from_position(player_position_meters)
	emit_signal("delivery_direction_changed", new_direction)
	print_debug("delivery direction changed")

func _start_next_delivery():
	if current_delivery >= GameConstants.GAME.deliveries_per_level:
		complete_level()
		return
	
	current_delivery += 1
	var delivery_data = _get_delivery_data(current_level, current_delivery)
	active_delivery = delivery_data
	
		# Store delivery start time for analytics
	active_delivery["analytics_start_time"] = Time.get_ticks_msec() / 1000.0
	
	# Store the delivery destination for direction calculations
	current_delivery_destination_meters = delivery_data.get("destination", 0.0)
	
	# Reset timer logic
	delivery_is_timed = false
	delivery_start_time = 0.0
	var distance_delivery = abs(active_delivery.destination-active_delivery.trolley_pos)
	print_debug("this distance in meter for time is calculated : ",distance_delivery)
	allotted_time = GameConstants.calculate_allotted_time(distance_delivery)
	
	emit_signal("delivery_started", delivery_data)
	
func get_trolley_direction_from_delivery() -> String:
	"""
	Returns the direction where the trolley is located from the delivery data.
	This is the existing logic you want to keep.
	"""
	if not active_delivery:
		return "right"
	return active_delivery.get("direction", "right")
	
func start_delivery_timer():
	if not active_delivery or delivery_is_timed:
		return # Do nothing if there's no active delivery or timer is already running
	
	print("GameManager: Player equipped trolley. Starting the clock!")
	delivery_is_timed = true
	delivery_time_remaining = allotted_time # This line is changed
	emit_signal("delivery_timer_started", allotted_time)

func _get_delivery_data(level: int, delivery_num: int) -> Dictionary:
	if level in level_scenarios:
		var current_set = level_scenarios[level].current_set
		if current_set != "" and current_set in level_scenarios[level].sets:
			var deliveries = level_scenarios[level].sets[current_set]
			if delivery_num - 1 < deliveries.size():
				var data = deliveries[delivery_num - 1].duplicate()
				data["delivery_number"] = delivery_num
				data["level"] = level
				return data
	
	# Fallback data
	return {
		"delivery_number": delivery_num,
		"level": level,
		"distance": 50.0,
		"direction": "right" if delivery_num % 2 == 0 else "left",
		"trolley_pos": 200.0,
		"handle": "left",
		"destination": 250.0 if delivery_num % 2 == 0 else 150.0
	}

func complete_delivery(success: bool):
	if not active_delivery:
		return
	
	var points = 0
	if success:
		# Increment our new counter if the delivery was a success.
		successful_deliveries_this_level += 1
		
		# Calculate delivery time based on the countdown
		var delivery_time = allotted_time - delivery_time_remaining
		var destination_distance = abs(active_delivery.destination-active_delivery.trolley_pos)
		points = GameConstants.get_delivery_points(destination_distance, delivery_time)
		level_score += points
		total_score += points
		
				# Analytics: Add this delivery as a task
		var task_id = "D" + str(current_delivery)
		var task_time = delivery_time if success else allotted_time
		
		# Build question and choices for analytics
		var question = "Deliver trolley from %.0fm to %.0fm (%.0fm distance)" % [
			active_delivery.get("trolley_pos", 0),
			active_delivery.get("destination", 0),
			abs(active_delivery.get("destination", 0) - active_delivery.get("trolley_pos", 0))
		]
		
		var options = "Direction: %s, Handle: %s, Time: %.1fs" % [
			active_delivery.get("direction", ""),
			active_delivery.get("handle", ""),
			allotted_time
		]
		
		var correct_choice = "Complete within %.1fs" % allotted_time
		var choice_made = "Completed in %.1fs" % task_time if success else "Failed/Timeout"
		
		analytics.add_task(
			task_id,
			success,
			task_time,
			points,
			question,
			options,
			correct_choice,
			choice_made
		)
			
	# Clear delivery destination
	current_delivery_destination_meters = 0.0
	
	active_delivery = null
	current_state = GameState.DELIVERY_COMPLETE
	emit_signal("delivery_completed", success, points)
	
	# --- THIS IS THE KEY LINE ---
	# We must emit the signal with the new total score.
	emit_signal("score_updated", total_score)
	# -----------------------------
	
	# Use a timer for the delay
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func():
		current_state = GameState.PLAYING
		_start_next_delivery()
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func complete_level():
	
		# Calculate level success (e.g., 60% deliveries successful)
	var level_successful = successful_deliveries_this_level >= (GameConstants.GAME.deliveries_per_level * 0.6)
	
	# Analytics: Complete the level
	analytics.complete_level(level_successful, level_score)
	
	# Update total deliveries in raw data
	var total_deliveries = (current_level * GameConstants.GAME.deliveries_per_level)
	for item in analytics.raw_data:
		if item["key"] == "totalDeliveries":
			item["value"] = str(total_deliveries)
			break
	
	# Send analytics after each level (optional - you can also send only at game end)
	analytics.send_analytics()
	
	current_state = GameState.LEVEL_COMPLETE
	
	# Announce the results to the UI
	emit_signal(
		"level_results_ready",
		current_level,
		level_score,
		successful_deliveries_this_level,
		GameConstants.GAME.deliveries_per_level
	)
	
	# Hide the game UI
	if game_ui_instance:
		game_ui_instance.hide()
		
	
	# PAUSE THE GAME - Don't auto-transition!
	#get_tree().paused = true
	print("GameManager: Level ", current_level, " completed - game paused, waiting for player input")
	
	# Remove the automatic level transition
	# The CompletionUI will handle starting the next level when player clicks "Next"

func end_game(completed: bool = false):
	current_state = GameState.GAME_OVER
		# Send final analytics payload
	analytics.send_analytics()
	
	emit_signal("game_ended", total_score, completed)

func pause_game():
	if current_state == GameState.PLAYING and get_tree():
		current_state = GameState.PAUSED
		get_tree().paused = true
		
		# --- ADD THIS LINE ---
		# If we have a reference to the pause menu, show it.
		#if pause_menu_instance:
			#pause_menu_instance.show()
			
		if game_ui_instance:
			game_ui_instance.hide()
			
		if mobile_controls_instance:
			mobile_controls_instance.hide()
			
		emit_signal("game_paused")

func resume_game():
	if current_state == GameState.PAUSED and get_tree():
		current_state = GameState.PLAYING
		get_tree().paused = false
		
		# --- ADD THIS LINE ---
		# If we have a reference to the pause menu, hide it.
		#if pause_menu_instance:
			#pause_menu_instance.hide()
			
		if game_ui_instance:
			game_ui_instance.show()
		
		if mobile_controls_instance:
			mobile_controls_instance.show()
			
		emit_signal("game_resumed")
		
func restart_level():
	"""
	Restarts the current level by reloading the scene.
	"""
	# First, ensure the game is unpaused so scene transitions can happen correctly.
	if is_paused():
		resume_game()
		# We wait for one frame to ensure the tree is fully unpaused before reloading.
		await get_tree().process_frame

	# Now, we can safely reload the current scene.
	# This is the simplest and most effective way to restart.
	# Godot will discard the old scene and load a fresh copy from the file.
	get_tree().reload_current_scene()

func get_current_delivery_info() -> Dictionary:
	if active_delivery:
		return active_delivery
	return {}

func is_level_feature_enabled(feature: String) -> bool:
	return GameConstants.is_feature_enabled(current_level, feature)

func get_current_level() -> int:
	return current_level

func get_total_score() -> int:
	return total_score

func get_level_score() -> int:
	return level_score

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_paused() -> bool:
	return current_state == GameState.PAUSED
