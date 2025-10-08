extends Node2D

var step := 0
var cap_animation_resumed := false
@onready var anim_player = $AnimationPlayer
@onready var color_rect = $FadeOverlay
@onready var next_button = $NextButton
@onready var skip_button = $SkipButton
@onready var lets_go_Button = $Shot4/LetsGoButton

func _ready() -> void:
	# Add a tiny delay for audio
	color_rect.visible = true
	next_button.disabled = false
	skip_button.visible = true
	lets_go_Button.visible = false
	await get_tree().create_timer(0.01).timeout
	AudioManager.play_music(GameConstants.AUDIO.cutscenebgm, 0.2, true, -5.0)
	anim_player.play("cutscene1")
	anim_player.animation_finished.connect(_on_animation_finished)
	skip_button.pressed.connect(_on_skip_button_pressed)
	lets_go_Button.pressed.connect(_on_lets_go_button_pressed)

func _on_next_button_pressed() -> void:
	next_button.disabled = true  # Disable until animation is done
	match step:
		0:
			AudioManager.play_dialogue(GameConstants.DIALOGUES.VendorDialogue, 0.0)
			anim_player.play("Vendor1")
		1:
			AudioManager.play_dialogue(GameConstants.DIALOGUES.CoolieDialogue1, 3.0)
			anim_player.play("coolie1")
		2:
			# Hide next button for this animation
			next_button.visible = false
			skip_button.visible = false
			AudioManager.play_dialogue(GameConstants.DIALOGUES.CoolieDialogue2, 1)
			anim_player.play("Coolie_Wearing_Cap")
			# Pause at 0.9377 seconds
			await get_tree().create_timer(0.9377).timeout
			if not cap_animation_resumed:
				anim_player.pause()
				lets_go_Button.visible = true
		3:
			_start_game()
	
	if step != 2:  # Don't increment for step 2 since we handle it differently
		step += 1

func _on_lets_go_button_pressed() -> void:
	cap_animation_resumed = true
	lets_go_Button.visible = false
	anim_player.play()  # Resume the paused animation

func _on_skip_button_pressed() -> void:
	# Stop any current animation
	anim_player.stop()
	# Hide UI elements
	skip_button.visible = false
	next_button.visible = false
	lets_go_Button.visible = false
	# Jump directly to starting the game
	_start_game()

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Coolie_Wearing_Cap":
		# Automatically go to step 3 after cap animation completes
		next_button.visible = true
		step = 3
		_start_game()
	else:
		next_button.disabled = false

func _start_game() -> void:
	# Hide skip button when starting game
	#AudioManager.stop_music()
	skip_button.visible = false
	# Start the game first, then load the level
	if has_node("/root/GameManager"):
		# Tell GameManager to start the game
		# It will handle the scene loading
		get_node("/root/GameManager").start_game()
	else:
		# Fallback: directly load the scene
		print("GameManager not found, loading scene directly")
		get_tree().change_scene_to_file("res://levels/Level1_Proto.tscn")
