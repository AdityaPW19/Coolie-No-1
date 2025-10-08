extends Control

# Simple Main Menu for Coolie No 1

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var test_button: Button = $VBoxContainer/TestButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready():
	# Connect buttons
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if test_button:
		test_button.pressed.connect(_on_test_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Check autoload status
	_check_systems()

func _check_systems():
	var status = "System Status:\n"
	
	if has_node("/root/Constants"):
		status += "✓ Constants loaded\n"
	else:
		status += "✗ Constants NOT loaded\n"
	
	if has_node("/root/GameManager"):
		status += "✓ GameManager loaded\n"
	else:
		status += "✗ GameManager NOT loaded\n"
	
	if has_node("/root/InputManager"):
		status += "✓ InputManager loaded"
	else:
		status += "✗ InputManager NOT loaded"
	
	print(status)

func _on_play_pressed():
	# Start the game through GameManager
	if has_node("/root/GameManager"):
		# First load the level scene
		get_tree().change_scene_to_file("res://levels/Level1_Proto.tscn")
		
		# Wait a frame for scene to load, then start game
		await get_tree().process_frame
		get_node("/root/GameManager").start_game()
	else:
		# Fallback - just load the level
		get_tree().change_scene_to_file("res://levels/Level1_Proto.tscn")

func _on_test_pressed():
	# Load test scene
	get_tree().change_scene_to_file("res://scene/test/TestScene.tscn")

func _on_quit_pressed():
	get_tree().quit()
