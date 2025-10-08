extends Control

# References to meter containers
@onready var push_meter: Control = $PushMeter
@onready var pull_meter: Control = $PullMeter
@onready var push_container: VBoxContainer = $PushMeter/Container
@onready var pull_container: VBoxContainer = $PullMeter/Container

# Arrays to hold texture rect references
var push_texture_rects: Array = []
var pull_texture_rects: Array = []

# Current meter values (0.0 to 100.0)
var current_push_effort: float = 100.0
var current_pull_effort: float = 100.0

# Total number of segments in each meter
const MAX_SEGMENTS = 15  # TextureRect to TextureRect14 = 15 segments

func _ready():
	# Initialize texture rect arrays
	_initialize_texture_rects()
	
	# Connect to GameManager signals
	if GameManager.has_signal("effort_updated"):
		GameManager.connect("effort_updated", _on_effort_updated)
	
	if GameManager.has_signal("level_started"):
		GameManager.connect("level_started", _on_level_started)
	
	# Set initial visibility based on current level
	_update_meter_visibility()
	
	# Initialize meter display
	_update_meter_display()

func _initialize_texture_rects():
	"""Initialize arrays with references to all TextureRect nodes"""
	push_texture_rects.clear()
	pull_texture_rects.clear()
	
	# Get push meter texture rects
	for i in range(MAX_SEGMENTS):
		var node_name = "TextureRect" if i == 0 else "TextureRect" + str(i + 1)
		var texture_rect = push_container.get_node_or_null(node_name)
		if texture_rect:
			push_texture_rects.append(texture_rect)
		else:
			print("Warning: Could not find ", node_name, " in PushMeter/Container")
	
	# Get pull meter texture rects
	for i in range(MAX_SEGMENTS):
		var node_name = "TextureRect" if i == 0 else "TextureRect" + str(i + 1)
		var texture_rect = pull_container.get_node_or_null(node_name)
		if texture_rect:
			pull_texture_rects.append(texture_rect)
		else:
			print("Warning: Could not find ", node_name, " in PullMeter/Container")
	
	print("Initialized effort meters: Push segments = ", push_texture_rects.size(), ", Pull segments = ", pull_texture_rects.size())

func _on_level_started(level_number: int):
	"""Called when a new level starts"""
	print("Effort meters: Level ", level_number, " started")
	_update_meter_visibility()
	
	# Reset meters to full when level starts
	if level_number > 1:
		current_push_effort = 100.0
		current_pull_effort = 100.0
		_update_meter_display()

func _on_effort_updated(push_effort: float, pull_effort: float):
	"""Called when GameManager updates effort values"""
	current_push_effort = push_effort
	current_pull_effort = pull_effort
	_update_meter_display()

func _update_meter_visibility():
	"""Show/hide meters based on current level"""
	var current_level = GameManager.get_current_level()
	var should_show = current_level > 1
	
	visible = should_show
	push_meter.visible = should_show
	pull_meter.visible = should_show
	
	print("Effort meters visibility: ", should_show, " (Level: ", current_level, ")")

func _update_meter_display():
	"""Update the visual representation of both meters"""
	if not visible:
		return
		
	_update_single_meter(push_texture_rects, current_push_effort)
	_update_single_meter(pull_texture_rects, current_pull_effort)

func _update_single_meter(texture_rects: Array, effort_value: float):
	"""Update a single meter's visual representation"""
	if texture_rects.is_empty():
		return
	
	# Clamp effort value between 0 and 100
	effort_value = clamp(effort_value, 0.0, 100.0)
	
	# Calculate how many segments should be visible
	var segments_to_show = int((effort_value / 100.0) * MAX_SEGMENTS)
	
	# Update visibility of texture rects
	# Show from bottom to top, hide from top to bottom
	for i in range(texture_rects.size()):
		var segment_index = texture_rects.size() - 1 - i  # Reverse index (bottom to top)
		var should_be_visible = segment_index < segments_to_show
		
		if texture_rects[i] is TextureRect:
			texture_rects[i].visible = should_be_visible

func get_push_effort_percentage() -> float:
	"""Get current push effort as percentage (0.0 to 1.0)"""
	return current_push_effort / 100.0

func get_pull_effort_percentage() -> float:
	"""Get current pull effort as percentage (0.0 to 1.0)"""
	return current_pull_effort / 100.0

func is_meters_enabled() -> bool:
	"""Check if effort meters are currently enabled"""
	return GameManager.get_current_level() > 1

# Optional: Add smooth animations for meter changes
func animate_meter_change(texture_rects: Array, from_value: float, to_value: float, duration: float = 0.3):
	"""Smoothly animate meter changes (optional enhancement)"""
	if texture_rects.is_empty():
		return
		
	var tween = create_tween()
	var temp_value = from_value
	
	tween.tween_method(
		func(value): 
			temp_value = value
			_update_single_meter(texture_rects, temp_value),
		from_value,
		to_value,
		duration
	)

# Debug function to test meters manually
func _input(event):
	if not visible or not OS.is_debug_build():
		return
		
	# Debug controls (only in debug builds)
	#if event.is_action_pressed("ui_up"):
		#current_push_effort = min(current_push_effort + 25, 100)
		#_update_meter_display()
		#print("Debug: Push effort = ", current_push_effort)
	#elif event.is_action_pressed("ui_down"):
		#current_push_effort = max(current_push_effort - 25, 0)
		#_update_meter_display()
		#print("Debug: Push effort = ", current_push_effort)
	#elif event.is_action_pressed("ui_left"):
		#current_pull_effort = max(current_pull_effort - 25, 0)
		#_update_meter_display()
		#print("Debug: Pull effort = ", current_pull_effort)
	#elif event.is_action_pressed("ui_right"):
		#current_pull_effort = min(current_pull_effort + 25, 100)
		#_update_meter_display()
		#print("Debug: Pull effort = ", current_pull_effort)
