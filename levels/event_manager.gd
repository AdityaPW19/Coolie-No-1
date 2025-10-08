class_name EventManager
extends Node

# Main signal for all UI feedback
signal show_feedback(text: String, duration: float, is_objective: bool)

# State tracking
var current_objective_state: String = ""
var last_objective_message: String = ""
var feedback_cooldown_timer: Timer
var objective_timer: Timer
var player_reference: CharacterBody2D = null
var level_controller_reference: Node2D = null

# Feedback cooldown to prevent spam (BUT NOT for priority messages)
var can_show_regular_feedback: bool = true

# Real-time update tracking
var last_update_time: float = 0.0
var update_interval: float = 2.0  # Update every 2 seconds

func _ready():
	# Setup timers
	feedback_cooldown_timer = Timer.new()
	feedback_cooldown_timer.one_shot = true
	add_child(feedback_cooldown_timer)
	
	objective_timer = Timer.new()
	objective_timer.one_shot = true
	objective_timer.timeout.connect(_on_objective_timer_timeout)
	add_child(objective_timer)
	
	# Connect to all relevant GameManager signals
	_connect_game_signals()
	
	# Find references with a small delay to ensure scene is loaded
	call_deferred("_find_references")

func _connect_game_signals():
	# Game flow signals
	GameManager.game_started.connect(_on_game_started)
	GameManager.delivery_started.connect(_on_delivery_started)
	GameManager.player_picked_up_trolley.connect(_on_player_picked_up_trolley)
	GameManager.delivery_completed.connect(_on_delivery_completed)
	GameManager.delivery_failed.connect(_on_delivery_failed)
	GameManager.level_started.connect(_on_level_started)
	GameManager.level_completed.connect(_on_level_completed)
	
	# Player action signals for accurate feedback
	GameManager.player_moved_with_trolley.connect(_on_player_moved_with_trolley)

func _find_references():
	var scene_tree = get_tree()
	if scene_tree and scene_tree.current_scene:
		# Find player reference
		player_reference = scene_tree.current_scene.find_child("Player", true, false)
		if not player_reference:
			player_reference = scene_tree.current_scene.find_child("CharacterBody2D", true, false)
		
		# Find level controller reference for accurate position calculations
		level_controller_reference = scene_tree.current_scene
		if level_controller_reference.has_method("_calculate_position_from_meters"):
			print("EventManager: Found LevelController with position calculation methods")
		
		if player_reference:
			print("EventManager: Found player reference: ", player_reference.name)

func _process(_delta):
	# Real-time objective updates for find trolley state
	if current_objective_state == "find_trolley" and player_reference:
		var current_time = Time.get_time_dict_from_system().get("second", 0)
		if abs(current_time - last_update_time) >= update_interval:
			_update_find_trolley_objective_realtime()
			last_update_time = current_time

# === MAIN MESSAGE FUNCTIONS ===

func show_objective(text: String, duration: float = 5.0):
	"""Shows an objective message that lasts for specified duration"""
	last_objective_message = text
	current_objective_state = "showing_objective"
	emit_signal("show_feedback", text, duration, true)
	objective_timer.start(duration)

func show_priority_feedback(text: String, duration: float = 2.0):
	"""Shows priority feedback that IGNORES cooldown (delivery success/failure)"""
	emit_signal("show_feedback", text, duration, false)

func show_regular_feedback(text: String, duration: float = 1.5):
	"""Shows regular feedback WITH cooldown protection (push/pull messages)"""
	if not can_show_regular_feedback:
		return
		
	emit_signal("show_feedback", text, duration, false)
	
	# Start cooldown to prevent spam
	can_show_regular_feedback = false
	feedback_cooldown_timer.start(2.0)
	feedback_cooldown_timer.timeout.connect(_reset_feedback_cooldown, CONNECT_ONE_SHOT)

func request_hint() -> String:
	"""Called by hint button - shows last objective again"""
	if last_objective_message.is_empty():
		return "Find a trolley to start your delivery!"
	
	emit_signal("show_feedback", last_objective_message, 3.0, true)
	return last_objective_message

# === GAME EVENT HANDLERS ===

func _on_game_started():
	current_objective_state = "find_trolley"
	call_deferred("_show_find_trolley_objective")

func _on_level_started(level_number: int):
	var message = "Level %d Started! Find your first trolley." % level_number
	show_objective(message, 3.0)
	current_objective_state = "find_trolley"

func _on_delivery_started(delivery_data: Dictionary):
	current_objective_state = "find_trolley"
	call_deferred("_show_find_trolley_objective")

func _on_player_picked_up_trolley(player: CharacterBody2D, trolley: RigidBody2D):
	current_objective_state = "deliver_trolley"
	GameManager.start_delivery_timer()
	
	var delivery_data = GameManager.get_current_delivery_info()
	if not delivery_data.is_empty():
		var destination = int(delivery_data.destination)
		var direction = _get_accurate_delivery_direction()
		var distance = _get_accurate_delivery_distance()
		
		#var message = "Deliver trolley to %dm platform (Go %s, ~%dm away)" % [destination, direction, distance]
		var message = "Deliver trolley to the %s %dm away" % [direction, distance]
		show_objective(message, 5.0)

func _on_delivery_completed(success: bool, points: int):
	# PRIORITY FEEDBACK - No cooldown interference
	if success:
		show_priority_feedback("Delivery Successful! +%d points" % points, 2.0)
	else:
		show_priority_feedback("Delivery Failed! Try again.", 2.0)
	
	# Brief pause before next objective
	await get_tree().create_timer(1.5).timeout
	_show_next_delivery_objective()

func _on_delivery_failed(delivery_data: Dictionary):
	# PRIORITY FEEDBACK - No cooldown interference
	show_priority_feedback("Delivery Failed! Try again.", 2.0)
	
	await get_tree().create_timer(1.5).timeout
	_show_next_delivery_objective()

func _on_level_completed(level_number: int, score: int):
	show_objective("Level %d Complete! Score: %d" % [level_number, score], 4.0)

# === ACCURATE FEEDBACK FOR PLAYER ACTIONS ===

func _on_player_moved_with_trolley(player: CharacterBody2D):
	if not player:
		return
	
	# Get accurate force type and direction info
	var is_correct_direction = _is_player_moving_correctly_accurate(player)
	var current_force_type = _get_current_force_type(player)
	
	if is_correct_direction:
		# Player is moving in the RIGHT direction
		var feedback_message = _get_positive_feedback_message(current_force_type)
		show_regular_feedback(feedback_message, 1.5)
	else:
		# Player is moving in the WRONG direction
		show_regular_feedback("Wrong Direction!", 2.0)

# === ACCURATE HELPER FUNCTIONS ===

func _show_find_trolley_objective():
	if not player_reference:
		_find_references()
	
	var delivery_data = GameManager.get_current_delivery_info()
	if delivery_data.is_empty():
		show_objective("Find the trolley to start delivery!", 5.0)
		return
	
	var trolley_direction = _get_accurate_trolley_direction()
	var distance = _get_accurate_trolley_distance()
	
	var message = "Find trolley to the %s, %dm away" % [trolley_direction, distance]
	show_objective(message, 5.0)

func _update_find_trolley_objective_realtime():
	"""Updates find trolley objective with real-time distance calculations"""
	if current_objective_state != "find_trolley":
		return
	
	var delivery_data = GameManager.get_current_delivery_info()
	if delivery_data.is_empty():
		return
	
	var trolley_direction = _get_accurate_trolley_direction()
	var distance = _get_accurate_trolley_distance()
	
	#last_objective_message = "Find trolley to the %s (~%dm away)" % [trolley_direction, distance]
	last_objective_message = "Find trolley to the %s, %dm away" % [trolley_direction, distance]

func _show_next_delivery_objective():
	# Use GameManager's constant for total deliveries
	var total_deliveries = GameConstants.GAME.deliveries_per_level
	
	if GameManager.current_delivery >= total_deliveries:
		return  # Level will end
	
	current_objective_state = "find_trolley"
	_show_find_trolley_objective()

func _get_accurate_trolley_direction() -> String:
	"""Get accurate direction to trolley using delivery data and player position"""
	if not player_reference:
		return GameManager.get_trolley_direction_from_delivery()
	
	var delivery_data = GameManager.get_current_delivery_info()
	if delivery_data.is_empty():
		return GameManager.get_trolley_direction_from_delivery()
	
	# Use the updated player calculation method
	return player_reference.get_direction_to_trolley()

func _get_accurate_trolley_distance() -> int:
	"""Get accurate distance to trolley using GameManager's distance calculation"""
	if not player_reference:
		return 50  # Default fallback
	
	var delivery_data = GameManager.get_current_delivery_info()
	if delivery_data.is_empty():
		return 50
	
	# Use the distance from GameManager's delivery data (trolley to player distance)
	var player_pos_meters = player_reference.get_current_position_meters()
	var trolley_pos_meters = delivery_data.get("trolley_pos", 0.0)
	
	return int(abs(trolley_pos_meters - player_pos_meters))

func _get_accurate_delivery_direction() -> String:
	"""Get accurate direction to delivery destination"""
	if not player_reference:
		return "right"
	
	# Use player's accurate direction calculation
	return player_reference.get_direction_to_delivery()

func _get_accurate_delivery_distance() -> int:
	"""Get accurate distance to delivery destination using GameManager's calculation"""
	if not player_reference:
		return 50
	
	var delivery_data = GameManager.get_current_delivery_info()
	if delivery_data.is_empty():
		return 50
	
	var destination = delivery_data.get("destination", 0.0)
	var current_pos_meters: float
	
	if player_reference.is_with_trolley and player_reference.current_trolley:
		# Use trolley position when carrying trolley (20 pixels per meter from player script)
		current_pos_meters = player_reference.current_trolley.global_position.x / 20.0
	else:
		# Use player position (20 pixels per meter from player script)  
		current_pos_meters = player_reference.get_current_position_meters()
	
	return int(abs(destination - current_pos_meters))

func _is_player_moving_correctly_accurate(player: CharacterBody2D) -> bool:
	"""Check if player is moving toward the delivery destination using accurate calculations"""
	if not player:
		return false
	
	var delivery_data = GameManager.get_current_delivery_info()
	if delivery_data.is_empty():
		return true
	
	var destination = delivery_data.get("destination", 0.0)
	var current_pos_meters: float
	
	if player.is_with_trolley and player.current_trolley:
		# Use trolley position for accurate calculation (20 pixels per meter)
		current_pos_meters = player.current_trolley.global_position.x / 20.0
	else:
		current_pos_meters = player.get_current_position_meters()
	
	# Determine required direction
	var required_direction_right = destination > current_pos_meters
	
	# Determine actual player direction
	var player_moving_right = player.is_facing_right
	
	# Check if directions match
	return required_direction_right == player_moving_right

func _get_current_force_type(player: CharacterBody2D) -> String:
	"""Determine if player is currently pushing or pulling based on animation"""
	if not player:
		return "move"
	
	if player.is_pushing():
		return "push"
	elif player.is_pulling():
		return "pull"
	else:
		return "move"

func _get_positive_feedback_message(force_type: String) -> String:
	"""Get appropriate positive feedback based on force type"""
	match force_type:
		"push":
			var push_messages = ["Great Push!", "Nice Push!", "Good Push!", "Perfect Push!"]
			return push_messages[randi() % push_messages.size()]
		"pull":
			var pull_messages = ["Great Pull!", "Nice Pull!", "Good Pull!", "Perfect Pull!"]
			return pull_messages[randi() % pull_messages.size()]
		_:
			var general_messages = ["Good Move!", "Nice Work!", "Keep Going!", "Well Done!"]
			return general_messages[randi() % general_messages.size()]

func _reset_feedback_cooldown():
	can_show_regular_feedback = true

func _on_objective_timer_timeout():
	if current_objective_state == "showing_objective":
		current_objective_state = ""
