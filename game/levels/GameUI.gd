# GameUI.gd - Fixed UI Controller with proper references
extends Control

# UI Node References - Fixed paths based on your structure
@onready var player_stats_panel = $PlayerStatsPanel
@onready var player_title = $PlayerStatsPanel/_VBoxContainer_5/Title
@onready var state_label = $PlayerStatsPanel/_VBoxContainer_5/StateLabel
@onready var speed_label = $PlayerStatsPanel/_VBoxContainer_5/SpeedLabel
@onready var surface_label = $PlayerStatsPanel/_VBoxContainer_5/SurfaceLabel

@onready var trolley_info_panel = $TrolleyInfoPanel
@onready var trolley_title = $TrolleyInfoPanel/_VBoxContainer_6/Title
@onready var weight_label = $TrolleyInfoPanel/_VBoxContainer_6/WeightLabel
@onready var distance_label = $TrolleyInfoPanel/_VBoxContainer_6/DistanceLabel

@onready var force_indicator = $ForceIndicator
@onready var force_title = $ForceIndicator/_VBoxContainer_7/Title
@onready var force_low_btn = $ForceIndicator/_VBoxContainer_7/_HBoxContainer_8/ForceLOW
@onready var force_medium_btn = $ForceIndicator/_VBoxContainer_7/_HBoxContainer_8/ForceMEDIUM
@onready var force_high_btn = $ForceIndicator/_VBoxContainer_7/_HBoxContainer_8/ForceHIGH

@onready var progress_bar = $ProgressBar
@onready var progress_title = $ProgressBar/_VBoxContainer_9/Title
@onready var actual_progress = $ProgressBar/_VBoxContainer_9/ActualProgress
@onready var distance_to_goal = $ProgressBar/_VBoxContainer_9/DistanceToGoal

@onready var timer_label = $TimerLabel

@onready var objective_panel = $ObjectivePanel
@onready var objective_title = $ObjectivePanel/_VBoxContainer_10/Title
@onready var objective_text = $ObjectivePanel/_VBoxContainer_10/ObjectiveText

@onready var controls_hint = $ControlsHint
@onready var controls_title = $ControlsHint/_VBoxContainer_11/Title
@onready var controls_text = $ControlsHint/_VBoxContainer_11/ControlsText

# Player and game references
var player_reference = null
var trolley_reference = null
var level_reference = null

# UI Update frequency - Make it faster for better responsiveness
var ui_update_timer = 0.0
var ui_update_interval = 0.05  # Update UI every 0.05 seconds (20 FPS)

func _ready():
	print("GameUI initialized with manual UI references")
	
	# Set initial UI content first
	_set_initial_ui_content()
	
	# Verify all UI elements are found
	_verify_ui_elements()
	
	# Find game objects immediately
	_find_game_references()
	
	# Connect to player signals
	_connect_signals()
	
	# Connect force buttons
	_connect_force_buttons()
	
	print("GameUI setup complete")

func _verify_ui_elements():
	var missing_elements = []
	
	# Check critical UI elements with corrected paths
	if not player_stats_panel: missing_elements.append("PlayerStatsPanel")
	if not state_label: missing_elements.append("StateLabel")
	if not speed_label: missing_elements.append("SpeedLabel")
	if not surface_label: missing_elements.append("SurfaceLabel")
	
	if not trolley_info_panel: missing_elements.append("TrolleyInfoPanel")
	if not weight_label: missing_elements.append("WeightLabel")
	if not distance_label: missing_elements.append("DistanceLabel")
	
	if not force_indicator: missing_elements.append("ForceIndicator")
	if not force_low_btn: missing_elements.append("ForceLOW")
	if not force_medium_btn: missing_elements.append("ForceMEDIUM")
	if not force_high_btn: missing_elements.append("ForceHIGH")
	
	if not progress_bar: missing_elements.append("ProgressBar")
	if not actual_progress: missing_elements.append("ActualProgress")
	if not distance_to_goal: missing_elements.append("DistanceToGoal")
	
	if not timer_label: missing_elements.append("TimerLabel")
	
	if not objective_panel: missing_elements.append("ObjectivePanel")
	if not objective_text: missing_elements.append("ObjectiveText")
	
	if not controls_hint: missing_elements.append("ControlsHint")
	if not controls_text: missing_elements.append("ControlsText")
	
	if missing_elements.size() > 0:
		print("⚠️ Missing UI elements: ", missing_elements)
	else:
		print("✅ All UI elements found successfully!")

func _set_initial_ui_content():
	# Set initial text content - check if elements exist first
	if player_title:
		player_title.text = "PLAYER STATUS"
	if state_label:
		state_label.text = "State: IDLE"
	if speed_label:
		speed_label.text = "Speed: 0 px/s"
	if surface_label:
		surface_label.text = "Surface: Normal"
	
	if trolley_title:
		trolley_title.text = "TROLLEY INFO"
	if weight_label:
		weight_label.text = "Weight: -- kg"
	if distance_label:
		distance_label.text = "Distance: -- px"
	
	if force_title:
		force_title.text = "FORCE LEVEL"
	if force_low_btn:
		force_low_btn.text = "LOW"
	if force_medium_btn:
		force_medium_btn.text = "MEDIUM"
	if force_high_btn:
		force_high_btn.text = "HIGH"
	
	if progress_title:
		progress_title.text = "DELIVERY PROGRESS"
	if actual_progress:
		actual_progress.max_value = 100
		actual_progress.value = 0
	if distance_to_goal:
		distance_to_goal.text = "Distance: --m"
	
	if timer_label:
		timer_label.text = "Time: 00:00"
	
	if objective_title:
		objective_title.text = "🎯 OBJECTIVE"
	if objective_text:
		objective_text.text = "Push or pull the trolley to the delivery zone!"
	
	if controls_title:
		controls_title.text = "⌨️ CONTROLS"
	if controls_text:
		controls_text.text = "A/D - Push/Pull trolley\n1/2/3 - Force levels\nR - Restart level"

func _connect_force_buttons():
	# Connect force level buttons with error checking
	if force_low_btn:
		if not force_low_btn.pressed.is_connected(_on_force_button_pressed):
			force_low_btn.pressed.connect(_on_force_button_pressed.bind("low"))
			print("Connected LOW force button")
	if force_medium_btn:
		if not force_medium_btn.pressed.is_connected(_on_force_button_pressed):
			force_medium_btn.pressed.connect(_on_force_button_pressed.bind("medium"))
			print("Connected MEDIUM force button")
	if force_high_btn:
		if not force_high_btn.pressed.is_connected(_on_force_button_pressed):
			force_high_btn.pressed.connect(_on_force_button_pressed.bind("high"))
			print("Connected HIGH force button")

func _find_game_references():
	# Find player - try multiple methods
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		player_reference = players[0]
		print("UI found player: ", player_reference.name)
	else:
		# Try scene path
		player_reference = get_tree().current_scene.get_node_or_null("GameElements/Player")
		if player_reference:
			print("UI found player via scene path: ", player_reference.name)
		else:
			print("❌ Player not found! Make sure player is in 'players' group")
	
	# Find trolley
	var trolleys = get_tree().get_nodes_in_group("trolleys")
	if trolleys.size() > 0:
		trolley_reference = trolleys[0]
		print("UI found trolley: ", trolley_reference.name)
	else:
		print("❌ Trolley not found!")
	
	# Find level
	level_reference = get_tree().current_scene
	print("UI connected to level: ", level_reference.name)

func _connect_signals():
	if not player_reference:
		print("❌ Cannot connect signals - player_reference is null")
		return
	
	# Connect player signals with error checking
	if player_reference.has_signal("state_changed"):
		if not player_reference.state_changed.is_connected(_on_player_state_changed):
			player_reference.state_changed.connect(_on_player_state_changed)
			print("✅ Connected to player state_changed signal")
	else:
		print("⚠️ Player doesn't have state_changed signal")
		
	if player_reference.has_signal("force_level_changed"):
		if not player_reference.force_level_changed.is_connected(_on_force_level_changed):
			player_reference.force_level_changed.connect(_on_force_level_changed)
			print("✅ Connected to player force_level_changed signal")
	else:
		print("⚠️ Player doesn't have force_level_changed signal")
		
	if player_reference.has_signal("movement_failed"):
		if not player_reference.movement_failed.is_connected(_on_movement_failed):
			player_reference.movement_failed.connect(_on_movement_failed)
			print("✅ Connected to player movement_failed signal")
	else:
		print("⚠️ Player doesn't have movement_failed signal")

# Process function to update UI
func _process(delta):
	ui_update_timer += delta
	if ui_update_timer >= ui_update_interval:
		ui_update_timer = 0.0
		_update_ui_elements()

func _update_ui_elements():
	_update_player_stats()
	_update_trolley_info()
	_update_progress()
	_update_timer()

func _update_player_stats():
	if not player_reference:
		return
	
	# Update state with better error checking
	if state_label:
		if "current_state" in player_reference:
			var state_names = {0: "IDLE", 1: "PUSHING", 2: "PULLING"}
			var state_name = state_names.get(player_reference.current_state, "UNKNOWN")
			state_label.text = "State: " + state_name
			
			# Color code the state
			match state_name:
				"IDLE":
					state_label.add_theme_color_override("font_color", Color.WHITE)
				"PUSHING":
					state_label.add_theme_color_override("font_color", Color.CYAN)
				"PULLING":
					state_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			state_label.text = "State: NO DATA"
	
	# Update speed
	if speed_label:
		if "current_speed" in player_reference:
			speed_label.text = "Speed: %.0f px/s" % abs(player_reference.current_speed)
			
			# Color code speed
			var speed = abs(player_reference.current_speed)
			if speed < 10:
				speed_label.add_theme_color_override("font_color", Color.WHITE)
			elif speed < 100:
				speed_label.add_theme_color_override("font_color", Color.GREEN)
			else:
				speed_label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			speed_label.text = "Speed: NO DATA"
	
	# Update surface
	if surface_label:
		if "current_surface" in player_reference:
			var surface = player_reference.current_surface.capitalize()
			surface_label.text = "Surface: " + surface
			
			# Color code surface
			match player_reference.current_surface:
				"normal":
					surface_label.add_theme_color_override("font_color", Color.WHITE)
				"rough":
					surface_label.add_theme_color_override("font_color", Color.ORANGE)
				"slippery":
					surface_label.add_theme_color_override("font_color", Color.CYAN)
		else:
			surface_label.text = "Surface: NO DATA"
	
	# Update force level display
	if player_reference and "current_force_level" in player_reference:
		_update_force_indicator_highlight(player_reference.current_force_level)

func _update_trolley_info():
	if not trolley_reference:
		if weight_label:
			weight_label.text = "Weight: NO TROLLEY"
		if distance_label:
			distance_label.text = "Distance: NO TROLLEY"
		return
	
	# Update weight
	if weight_label:
		if trolley_reference.has_method("get_total_weight"):
			var weight = trolley_reference.get_total_weight()
			weight_label.text = "Weight: %.0f kg" % weight
			
			# Color code weight
			if weight < 30:
				weight_label.add_theme_color_override("font_color", Color.GREEN)
			elif weight < 60:
				weight_label.add_theme_color_override("font_color", Color.YELLOW)
			else:
				weight_label.add_theme_color_override("font_color", Color.RED)
		else:
			weight_label.text = "Weight: NO METHOD"
	
	# Update distance from player
	if distance_label and player_reference:
		var distance = player_reference.global_position.distance_to(trolley_reference.global_position)
		distance_label.text = "Distance: %.0f px" % distance
		
		# Color code distance (good when close to grab distance)
		if distance < 80:  # Close to ideal grab distance
			distance_label.add_theme_color_override("font_color", Color.GREEN)
		elif distance < 150:
			distance_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			distance_label.add_theme_color_override("font_color", Color.RED)

func _update_progress():
	if not level_reference:
		return
	
	# Calculate progress based on distance to delivery zone
	var delivery_zone = level_reference.get_node_or_null("GameElements/DeliveryZones/DeliveryZone1")
	if delivery_zone and trolley_reference:
		var distance_to_goal_value = trolley_reference.global_position.distance_to(delivery_zone.global_position)
		
		# Update progress bar
		if actual_progress:
			# Assuming max distance is around 2000 pixels
			var max_distance = 2000.0
			var progress_percent = max(0, 100 - (distance_to_goal_value / max_distance * 100))
			actual_progress.value = progress_percent
		
		# Update distance label
		if distance_to_goal:
			distance_to_goal.text = "Distance: %.0fm" % (distance_to_goal_value / 10)  # Convert to "meters"

func _update_timer():
	if not timer_label or not level_reference:
		return
	
	if "time_elapsed" in level_reference:
		var time = level_reference.time_elapsed
		var minutes = int(time) / 60
		var seconds = int(time) % 60
		timer_label.text = "Time: %02d:%02d" % [minutes, seconds]
		
		# Color code time (warning colors for long times)
		if time < 60:  # Under 1 minute
			timer_label.add_theme_color_override("font_color", Color.GREEN)
		elif time < 180:  # Under 3 minutes
			timer_label.add_theme_color_override("font_color", Color.YELLOW)
		else:  # Over 3 minutes
			timer_label.add_theme_color_override("font_color", Color.ORANGE)

# Signal handlers
func _on_player_state_changed(new_state):
	print("UI: Player state changed to ", new_state)

func _on_force_level_changed(level):
	print("UI: Force level changed to ", level)
	_update_force_indicator_highlight(level)

func _on_movement_failed(reason):
	print("UI: Movement failed - ", reason)
	_show_failure_notification(reason)

func _on_force_button_pressed(force_level):
	print("UI: Force button pressed - ", force_level)
	if player_reference:
		# Update player's force level directly
		if "current_force_level" in player_reference:
			player_reference.current_force_level = force_level
			print("Set player force level to: ", force_level)
			
			# Emit signal if available
			if player_reference.has_signal("force_level_changed"):
				player_reference.force_level_changed.emit(force_level)
				print("Emitted force_level_changed signal")
			
			# Update UI immediately
			_update_force_indicator_highlight(force_level)

func _update_force_indicator_highlight(level):
	# Reset all button styles to default
	if force_low_btn:
		force_low_btn.add_theme_color_override("font_color", Color.WHITE)
		force_low_btn.modulate = Color(1, 1, 1, 0.7)
	if force_medium_btn:
		force_medium_btn.add_theme_color_override("font_color", Color.WHITE)
		force_medium_btn.modulate = Color(1, 1, 1, 0.7)
	if force_high_btn:
		force_high_btn.add_theme_color_override("font_color", Color.WHITE)
		force_high_btn.modulate = Color(1, 1, 1, 0.7)
	
	# Highlight current force level
	match level:
		"low":
			if force_low_btn:
				force_low_btn.add_theme_color_override("font_color", Color.CYAN)
				force_low_btn.modulate = Color(1, 1, 1, 1)
		"medium":
			if force_medium_btn:
				force_medium_btn.add_theme_color_override("font_color", Color.GREEN)
				force_medium_btn.modulate = Color(1, 1, 1, 1)
		"high":
			if force_high_btn:
				force_high_btn.add_theme_color_override("font_color", Color.RED)
				force_high_btn.modulate = Color(1, 1, 1, 1)

func _show_failure_notification(reason):
	# Create temporary failure notification
	var notification = Label.new()
	notification.text = "⚠️ " + reason
	notification.add_theme_font_size_override("font_size", 24)
	notification.add_theme_color_override("font_color", Color.RED)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Position in center of screen
	var screen_size = get_viewport().get_visible_rect().size
	notification.position = Vector2(screen_size.x * 0.5 - 200, screen_size.y * 0.3)
	notification.size = Vector2(400, 50)
	
	# Add background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(1, 0, 0, 0.7)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	notification.add_theme_stylebox_override("normal", style_box)
	
	add_child(notification)
	
	# Animate and remove
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, 3.0)
	tween.tween_callback(notification.queue_free)

# Utility functions
func toggle_ui_visibility():
	visible = !visible

func hide_ui():
	visible = false

func show_ui():
	visible = true

func update_objective(new_objective: String):
	if objective_text:
		objective_text.text = new_objective

func update_controls_hint(new_controls: String):
	if controls_text:
		controls_text.text = new_controls

## Debug function to test UI updates
#func _input(event):
	## Press F4 to test UI manually
	#if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_F4:
		#print("=== UI DEBUG TEST ===")
		#print("Player reference: ", player_reference)
		#print("Trolley reference: ", trolley_reference)
		#print("Level reference: ", level_reference)
		#if player_reference:
			#print("Player state: ", player_reference.get("current_state", "NOT FOUND"))
			#print("Player speed: ", player_reference.get("current_speed", "NOT FOUND"))
			#print("Player surface: ", player_reference.get("current_surface", "NOT FOUND"))
			#print("Player force: ", player_reference.get("current_force_level", "NOT FOUND"))
