extends Control

# Game UI Controller - Manages all in-game UI elements

@onready var timer_label: Label = $TimerLabel
@onready var objective_panel: Panel = $ObjectivePanel
@onready var player_stats_panel: Panel = $PlayerStatsPanel
@onready var trolley_info_panel: Panel = $TrolleyInfoPanel
@onready var force_indicator: Panel = $ForceIndicator
@onready var progress_bar: Panel = $ProgressBar
@onready var direction_arrow: Sprite2D = $DirectionArrow
@onready var push_button: Button = $PushButton
@onready var pull_button: Button = $PullButton
@onready var interact_button: Button = $InteractButton  # New interact button

# UI element references
var score_label: Label
var delivery_label: Label
var distance_label: Label
var objective_label: Label
var force_label: Label
var progress_fill: ColorRect

# Game state
var delivery_start_time: float = 0.0
var current_delivery_data: Dictionary = {}
var is_delivery_active: bool = false
var player_has_trolley: bool = false

func _ready():
	# Setup UI element references
	_setup_ui_elements()
	
	# Connect to GameManager signals
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		gm.level_started.connect(_on_level_started)
		gm.delivery_started.connect(_on_delivery_started)
		gm.delivery_completed.connect(_on_delivery_completed)
		gm.game_paused.connect(_on_game_paused)
		gm.game_resumed.connect(_on_game_resumed)
	
	# Connect to InputManager for button controls
	if has_node("/root/InputManager"):
		var im = get_node("/root/InputManager")
		# Setup button areas
		_setup_touch_controls()
		
		# Connect button signals
		if push_button:
			push_button.button_down.connect(func(): im._start_push())
			push_button.button_up.connect(func(): im._end_push())
		
		if pull_button:
			pull_button.button_down.connect(func(): im._start_pull())
			pull_button.button_up.connect(func(): im._end_pull())
		
		if interact_button:
			interact_button.pressed.connect(func(): im.emit_signal("interact_requested"))

func _setup_ui_elements():
	# Find or create labels in panels
	if player_stats_panel:
		score_label = _find_or_create_label(player_stats_panel, "ScoreLabel", "Score: 0")
		delivery_label = _find_or_create_label(player_stats_panel, "DeliveryLabel", "Delivery: 0/%d" % GameConstants.GAME.deliveries_per_level)
	
	if trolley_info_panel:
		distance_label = _find_or_create_label(trolley_info_panel, "DistanceLabel", "Distance: 0m")
	
	if objective_panel:
		objective_label = _find_or_create_label(objective_panel, "ObjectiveLabel", "Get Ready!")
	
	if force_indicator:
		force_label = _find_or_create_label(force_indicator, "ForceLabel", "IDLE")
	
	if progress_bar:
		# Create progress fill if it doesn't exist
		progress_fill = progress_bar.get_node_or_null("ProgressFill")
		if not progress_fill:
			progress_fill = ColorRect.new()
			progress_fill.name = "ProgressFill"
			progress_fill.color = GameConstants.COLORS.success if has_node("/root/GameConstants") else Color.GREEN
			progress_fill.size = Vector2(0, progress_bar.size.y - 4)
			progress_fill.position = Vector2(2, 2)
			progress_bar.add_child(progress_fill)
	
	# Create interact button if it doesn't exist
	if not interact_button:
		interact_button = Button.new()
		interact_button.name = "InteractButton"
		interact_button.text = "F - Interact"
		interact_button.size = Vector2(120, 60)
		interact_button.position = Vector2(850, 600)  # Adjust position as needed
		add_child(interact_button)
		interact_button.visible = false  # Hide initially

func _find_or_create_label(parent: Control, name: String, default_text: String) -> Label:
	var label = parent.get_node_or_null(name)
	if not label:
		label = Label.new()
		label.name = name
		label.text = default_text
		label.position = Vector2(10, 10)
		parent.add_child(label)
	return label

func _setup_touch_controls():
	if has_node("/root/InputManager"):
		var im = get_node("/root/InputManager")
		
		# Set button areas for InputManager
		if push_button:
			var push_rect = Rect2(push_button.global_position, push_button.size)
			im.set_push_button_area(push_rect)
		
		if pull_button:
			var pull_rect = Rect2(pull_button.global_position, pull_button.size)
			im.set_pull_button_area(pull_rect)
		
		if interact_button:
			var interact_rect = Rect2(interact_button.global_position, interact_button.size)
			im.set_interact_button_area(interact_rect)

func _process(delta):
	if is_delivery_active and timer_label:
		# Update timer
		var elapsed = Time.get_ticks_msec() / 1000.0 - delivery_start_time
		var remaining = _calculate_remaining_time(elapsed)
		timer_label.text = "Time: %.1f s" % remaining
		
		# Update timer color based on remaining time
		if remaining < 5.0:
			timer_label.modulate = Color.RED
		elif remaining < 10.0:
			timer_label.modulate = Color.YELLOW
		else:
			timer_label.modulate = Color.WHITE
	
	# Update force indicator based on input
	if has_node("/root/InputManager") and force_label:
		var im = get_node("/root/InputManager")
		if im.is_pushing:
			force_label.text = "PUSHING →"
			if has_node("/root/GameConstants"):
				force_indicator.modulate = GameConstants.COLORS.push_indicator
			else:
				force_indicator.modulate = Color.ORANGE
		elif im.is_pulling:
			force_label.text = "← PULLING"
			if has_node("/root/GameConstants"):
				force_indicator.modulate = GameConstants.COLORS.pull_indicator
			else:
				force_indicator.modulate = Color.BLUE
		else:
			force_label.text = "IDLE"
			force_indicator.modulate = Color.WHITE

func _calculate_remaining_time(elapsed: float) -> float:
	if not current_delivery_data.has("distance"):
		return 30.0  # Default
	
	if has_node("/root/GameConstants"):
		var allotted_time = GameConstants.calculate_allotted_time(current_delivery_data.distance)
		return max(0.0, allotted_time - elapsed)
	else:
		# Fallback calculation
		var ideal_time = current_delivery_data.distance / 2.0  # 2 m/s
		var allotted_time = ideal_time * 1.3
		return max(0.0, allotted_time - elapsed)

func _on_level_started(level_number: int):
	# Reset UI for new level
	if score_label:
		score_label.text = "Score: 0"
	if delivery_label:
		var deliveries = 5  # Default
		if has_node("/root/GameConstants"):
			deliveries = GameConstants.GAME.deliveries_per_level
		delivery_label.text = "Delivery: 0/%d" % deliveries
	if objective_label:
		objective_label.text = "Level %d - Get Ready!" % level_number
	
	visible = true

func _on_delivery_started(delivery_data: Dictionary):
	current_delivery_data = delivery_data
	delivery_start_time = Time.get_ticks_msec() / 1000.0
	is_delivery_active = true
	
	# Update UI elements
	if delivery_label:
		var total_deliveries = 5
		if has_node("/root/GameConstants"):
			total_deliveries = GameConstants.GAME.deliveries_per_level
		delivery_label.text = "Delivery: %d/%d" % [delivery_data.get("delivery_number", 1), total_deliveries]
	
	if distance_label:
		distance_label.text = "Distance: %dm" % delivery_data.get("distance", 0)
	
	if objective_label:
		var direction = delivery_data.get("direction", "")
		objective_label.text = "Deliver %dm to the %s!" % [delivery_data.get("distance", 0), direction]
	
	# Update direction arrow
	if direction_arrow and delivery_data.has("direction"):
		direction_arrow.visible = true
		if delivery_data.get("direction", "") == "right":
			direction_arrow.rotation_degrees = 0  # Point right
		else:
			direction_arrow.rotation_degrees = 180  # Point left
	
	# Show interact button
	if interact_button:
		interact_button.visible = true
		interact_button.text = "F - Pick Up"

func _on_delivery_completed(success: bool, points: int):
	is_delivery_active = false
	
	# Update score
	if has_node("/root/GameManager") and score_label:
		var gm = get_node("/root/GameManager")
		score_label.text = "Score: %d" % gm.get_total_score()
	
	# Show delivery result
	if objective_label:
		if success:
			objective_label.text = "Delivery Complete! +%d points" % points
			objective_label.modulate = Color.GREEN
		else:
			objective_label.text = "Delivery Failed!"
			objective_label.modulate = Color.RED
		
		# Reset color after delay
		var timer = get_tree().create_timer(2.0)
		await timer.timeout
		objective_label.modulate = Color.WHITE
	
	# Hide direction arrow
	if direction_arrow:
		direction_arrow.visible = false
	
	# Reset interact button
	player_has_trolley = false

func _on_game_paused():
	# Dim the UI when paused
	modulate = Color(0.5, 0.5, 0.5, 1.0)

func _on_game_resumed():
	# Restore UI brightness
	modulate = Color.WHITE

# Public methods for other systems to update UI
func update_progress(current: float, total: float):
	if progress_bar and progress_fill:
		var percentage = current / total
		progress_fill.size.x = (progress_bar.size.x - 4) * percentage

func show_message(text: String, duration: float = 2.0):
	if objective_label:
		var original_text = objective_label.text
		objective_label.text = text
		await get_tree().create_timer(duration).timeout
		objective_label.text = original_text

# Called by player when they pick up or release trolley
func on_player_trolley_state_changed(has_trolley: bool):
	player_has_trolley = has_trolley
	if interact_button:
		if has_trolley:
			interact_button.text = "F - Flip Handle"
		else:
			interact_button.text = "F - Pick Up"
