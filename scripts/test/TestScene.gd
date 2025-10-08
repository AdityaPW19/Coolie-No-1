extends Node2D

# Test scene to verify core systems are working

@onready var status_label: Label = $CanvasLayer/VBoxContainer/StatusLabel
@onready var game_state_label: Label = $CanvasLayer/VBoxContainer/GameStateLabel
@onready var input_state_label: Label = $CanvasLayer/VBoxContainer/InputStateLabel
@onready var delivery_info_label: Label = $CanvasLayer/VBoxContainer/DeliveryInfoLabel
@onready var log_output: RichTextLabel = $CanvasLayer/VBoxContainer/LogOutput

var log_messages: Array[String] = []

func _ready():
	_log("Test Scene Started")
	
	# Check if autoloads are available
	_check_autoloads()
	
	# Connect to GameManager signals
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		gm.game_started.connect(_on_game_started)
		gm.level_started.connect(_on_level_started)
		gm.delivery_started.connect(_on_delivery_started)
		gm.delivery_completed.connect(_on_delivery_completed)
		gm.game_paused.connect(_on_game_paused)
		gm.game_resumed.connect(_on_game_resumed)
		_log("Connected to GameManager signals")
	
	# Connect to InputManager signals
	if has_node("/root/InputManager"):
		var im = get_node("/root/InputManager")
		im.push_action_started.connect(_on_push_started)
		im.push_action_ended.connect(_on_push_ended)
		im.pull_action_started.connect(_on_pull_started)
		im.pull_action_ended.connect(_on_pull_ended)
		im.walk_left.connect(_on_walk_left)
		im.walk_right.connect(_on_walk_right)
		im.pause_requested.connect(_on_pause_requested)
		_log("Connected to InputManager signals")
	
	# Create test player
	_create_test_player()
	
	# Display controls
	_log("\n=== CONTROLS ===")
	_log("SPACE/Click Push Button - Push")
	_log("SHIFT/Click Pull Button - Pull")
	_log("A/LEFT - Walk Left")
	_log("D/RIGHT - Walk Right")
	_log("F - Flip Trolley (Level 2)")
	_log("ESC - Pause")
	_log("1 - Start Game")
	_log("2 - Complete Current Delivery")
	_log("================\n")

func _check_autoloads():
	var autoloads = ["GameConstants", "GameManager", "InputManager"]
	var all_loaded = true
	
	_log("=== CHECKING AUTOLOADS ===")
	for autoload in autoloads:
		var path = "/root/" + autoload
		if has_node(path):
			_log("✓ " + autoload + " loaded successfully")
		else:
			_log("✗ " + autoload + " NOT FOUND!")
			all_loaded = false
	
	if all_loaded:
		_log("All autoloads loaded successfully!")
		status_label.text = "Status: All Systems Ready"
		status_label.modulate = GameConstants.COLORS.success
	else:
		status_label.text = "Status: Missing Autoloads"
		status_label.modulate = GameConstants.COLORS.error
	_log("========================\n")

func _create_test_player():
	# Create a simple player instance
	var player_scene = load("res://scene/player/Player.tscn")
	if player_scene:
		var player = player_scene.instantiate()
		player.position = Vector2(400, 300)
		add_child(player)
		_log("Player instance created")
		
		# Connect player signals
		if player.has_signal("started_pushing"):
			player.started_pushing.connect(func(): _log("Player: Started pushing"))
			player.started_pulling.connect(func(): _log("Player: Started pulling"))
			player.stopped_action.connect(func(): _log("Player: Stopped action"))
			player.reposition_started.connect(func(): _log("Player: Repositioning started"))
			player.reposition_completed.connect(func(): _log("Player: Repositioning completed"))
	else:
		_log("ERROR: Could not load Player scene")

func _process(_delta):
	# Update state displays
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		game_state_label.text = "Game State: " + _get_state_name(gm.current_state)
		
		var delivery = gm.get_current_delivery_info()
		if delivery and delivery.size() > 0:
			delivery_info_label.text = "Delivery #%d: %s %dm" % [
				delivery.get("delivery_number", 0),
				delivery.get("direction", ""),
				delivery.get("distance", 0)
			]
		else:
			delivery_info_label.text = "No active delivery"
	
	if has_node("/root/InputManager"):
		var im = get_node("/root/InputManager")
		var states = []
		if im.is_pushing:
			states.append("PUSHING")
		if im.is_pulling:
			states.append("PULLING")
		if states.is_empty():
			states.append("IDLE")
		input_state_label.text = "Input: " + ", ".join(states)

func _input(event):
	if event.is_action_pressed("ui_select") or (event is InputEventKey and event.pressed):
		if event is InputEventKey:
			match event.keycode:
				KEY_1:
					_start_test_game()
				KEY_2:
					_complete_test_delivery()

func _get_state_name(state: int) -> String:
	match state:
		0: return "MENU"
		1: return "PLAYING"
		2: return "PAUSED"
		3: return "DELIVERY_COMPLETE"
		4: return "LEVEL_COMPLETE"
		5: return "GAME_OVER"
		_: return "UNKNOWN"

# Test functions
func _start_test_game():
	if has_node("/root/GameManager"):
		_log("Starting test game...")
		get_node("/root/GameManager").start_game()

func _complete_test_delivery():
	if has_node("/root/GameManager"):
		_log("Completing test delivery...")
		get_node("/root/GameManager").complete_delivery(true)

# Signal callbacks
func _on_game_started():
	_log("SIGNAL: Game Started!")

func _on_level_started(level: int):
	_log("SIGNAL: Level %d Started!" % level)

func _on_delivery_started(data: Dictionary):
	_log("SIGNAL: Delivery Started - #%d, %s, %dm" % [
		data.get("delivery_number", 0),
		data.get("direction", ""),
		data.get("distance", 0)
	])

func _on_delivery_completed(success: bool, points: int):
	_log("SIGNAL: Delivery Completed - Success: %s, Points: %d" % [str(success), points])

func _on_game_paused():
	_log("SIGNAL: Game Paused")

func _on_game_resumed():
	_log("SIGNAL: Game Resumed")

func _on_push_started():
	_log("INPUT: Push Started")

func _on_push_ended():
	_log("INPUT: Push Ended")

func _on_pull_started():
	_log("INPUT: Pull Started")

func _on_pull_ended():
	_log("INPUT: Pull Ended")

func _on_walk_left():
	_log("INPUT: Walk Left")

func _on_walk_right():
	_log("INPUT: Walk Right")

func _on_pause_requested():
	_log("INPUT: Pause Requested")
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.is_playing():
			gm.pause_game()
		elif gm.is_paused():
			gm.resume_game()

func _log(message: String):
	print(message)  # Also print to console
	log_messages.append(message)
	if log_messages.size() > 20:  # Keep only last 20 messages
		log_messages.pop_front()
	
	if log_output:
		log_output.text = "\n".join(log_messages)
