extends Control

# Pause Menu Controller

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

func _ready():
	# Hide by default
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Create UI if it doesn't exist
	_create_pause_ui()
	
	# Connect to GameManager
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		gm.game_paused.connect(_on_game_paused)
		gm.game_resumed.connect(_on_game_resumed)
	
	# Connect to InputManager for pause
	if has_node("/root/InputManager"):
		var im = get_node("/root/InputManager")
		im.pause_requested.connect(_on_pause_requested)

func _create_pause_ui():
	# Create panel if it doesn't exist
	var panel = get_node_or_null("Panel")
	if not panel:
		panel = Panel.new()
		panel.name = "Panel"
		panel.custom_minimum_size = Vector2(400, 300)
		panel.anchor_left = 0.5
		panel.anchor_top = 0.5
		panel.anchor_right = 0.5
		panel.anchor_bottom = 0.5
		panel.offset_left = -200
		panel.offset_top = -150
		panel.offset_right = 200
		panel.offset_bottom = 150
		add_child(panel)
	
	# Create VBoxContainer
	var vbox = panel.get_node_or_null("VBoxContainer")
	if not vbox:
		vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.anchor_left = 0.5
		vbox.anchor_top = 0.5
		vbox.anchor_right = 0.5
		vbox.anchor_bottom = 0.5
		vbox.offset_left = -100
		vbox.offset_top = -100
		vbox.offset_right = 100
		vbox.offset_bottom = 100
		panel.add_child(vbox)
		
		# Title
		var title = Label.new()
		title.text = "PAUSED"
		title.add_theme_font_size_override("font_size", 32)
		vbox.add_child(title)
		
		# Spacer
		vbox.add_child(Control.new())
		
		# Resume Button
		resume_button = Button.new()
		resume_button.name = "ResumeButton"
		resume_button.text = "Resume"
		resume_button.custom_minimum_size = Vector2(200, 50)
		resume_button.pressed.connect(_on_resume_pressed)
		vbox.add_child(resume_button)
		
		# Restart Button
		restart_button = Button.new()
		restart_button.name = "RestartButton"
		restart_button.text = "Restart Level"
		restart_button.custom_minimum_size = Vector2(200, 50)
		restart_button.pressed.connect(_on_restart_pressed)
		vbox.add_child(restart_button)
		
		# Quit Button
		quit_button = Button.new()
		quit_button.name = "QuitButton"
		quit_button.text = "Quit to Menu"
		quit_button.custom_minimum_size = Vector2(200, 50)
		quit_button.pressed.connect(_on_quit_pressed)
		vbox.add_child(quit_button)

func _on_pause_requested():
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.is_playing():
			gm.pause_game()

func _on_game_paused():
	visible = true

func _on_game_resumed():
	visible = false

func _on_resume_pressed():
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").resume_game()

func _on_restart_pressed():
	# Resume first
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		gm.resume_game()
		# Restart current level
		var current_level = gm.get_current_level()
		gm.start_level(current_level)

func _on_quit_pressed():
	# Resume and go to main menu
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").resume_game()
	
	# Go back to starting cutscene
	get_tree().change_scene_to_file("res://scene/cutscenes/StartingCutscene.tscn")
