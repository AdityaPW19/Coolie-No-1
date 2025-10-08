extends Node2D
# Test scene for new trolley implementation

@onready var trolley_instance: CharacterBody2D = null
@onready var info_label: Label = $UI/InfoLabel

var test_direction := 1

func _ready():
	# Create UI
	_setup_ui()
	
	# Spawn trolley
	_spawn_trolley()
	
	print("Trolley Test Scene Ready!")
	print("Controls:")
	print("- 1/2: Push left/right")
	print("- 3/4: Pull left/right")
	print("- F: Flip handle")
	print("- S: Stop movement")
	print("- D: Toggle debug")

func _setup_ui():
	var ui = CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	
	# Info label
	var label = Label.new()
	label.name = "InfoLabel"
	label.position = Vector2(20, 20)
	label.size = Vector2(400, 200)
	label.add_theme_font_size_override("font_size", 14)
	ui.add_child(label)
	
	info_label = label

func _spawn_trolley():
	# Load and instantiate trolley
	var trolley_scene = load("res://scene/objects/trolley_new.tscn")
	if not trolley_scene:
		push_error("Could not load trolley_new.tscn!")
		return
	
	trolley_instance = trolley_scene.instantiate()
	trolley_instance.position = Vector2(960, 540)  # Center of screen
	trolley_instance.debug_mode = true
	add_child(trolley_instance)
	
	# Attach to simulate player interaction
	trolley_instance.attach_to_player(self)

func _process(_delta):
	if not trolley_instance:
		return
	
	# Update info
	var info = "=== TROLLEY TEST ===\n"
	info += "State: %s\n" % ["Idle", "Pushed", "Pulled"][trolley_instance.current_state]
	info += "Handle: %s\n" % trolley_instance.get_handle_direction_string()
	info += "Velocity: %.1f px/s\n" % trolley_instance.velocity.x
	info += "Position: %.1f, %.1f\n" % [trolley_instance.position.x, trolley_instance.position.y]
	info += "\nControls:\n"
	info += "1/2: Push L/R | 3/4: Pull L/R\n"
	info += "F: Flip | S: Stop | D: Debug"
	
	info_label.text = info

func _input(event):
	if not trolley_instance:
		return
	
	if event.is_action_pressed("ui_select"):  # Space
		trolley_instance.stop_movement()
	
	# Number keys for testing
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:  # Push left
				if trolley_instance.apply_push_force(-1):
					print("Pushing left")
				else:
					print("Cannot push left with handle on %s" % trolley_instance.get_handle_direction_string())
			KEY_2:  # Push right
				if trolley_instance.apply_push_force(1):
					print("Pushing right")
				else:
					print("Cannot push right with handle on %s" % trolley_instance.get_handle_direction_string())
			KEY_3:  # Pull left
				if trolley_instance.apply_pull_force(-1):
					print("Pulling left")
				else:
					print("Cannot pull left with handle on %s" % trolley_instance.get_handle_direction_string())
			KEY_4:  # Pull right
				if trolley_instance.apply_pull_force(1):
					print("Pulling right")
				else:
					print("Cannot pull right with handle on %s" % trolley_instance.get_handle_direction_string())
			KEY_F:  # Flip handle
				trolley_instance.flip_handle()
			KEY_S:  # Stop
				trolley_instance.stop_movement()
			KEY_D:  # Debug toggle
				trolley_instance.debug_mode = not trolley_instance.debug_mode
				if trolley_instance.debug_label:
					trolley_instance.debug_label.visible = trolley_instance.debug_mode

# Create a simple platform for testing
func _draw():
	# Draw ground
	draw_rect(Rect2(0, 600, 1920, 480), Color.BROWN)
	# Draw platform line
	draw_line(Vector2(0, 600), Vector2(1920, 600), Color.BLACK, 3)
