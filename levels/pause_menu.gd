extends Control
# --- Node References ---
@onready var menu_container: TextureRect = $Container
@onready var resume_button: TextureButton = $ButtonsContainer/Resume
@onready var quit_button: TextureButton = $ButtonsContainer/Exit
@onready var restart_button: TextureButton = $ButtonsContainer/Restart
@onready var banner: TextureRect = $Banner
@onready var how_to_button: TextureButton = $HowToButton
var is_animating: bool = false
var banner_final_scale: Vector2 = Vector2.ONE
var is_paused: bool = false

func _ready():
	banner_final_scale = banner.scale
	hide()
	reset_to_start_state()
	
	# Connect to GameManager signals
	GameManager.game_paused.connect(show_animated)
	
	# Connect button signals
	resume_button.pressed.connect(_on_resume_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	if how_to_button:
		how_to_button.pressed.connect(_on_how_to_button_pressed)

func _on_how_to_button_pressed():
	"""Opens the HowToPlay screen from pause menu."""
	if is_animating: 
		return
	
	# Play button click sound
	AudioManager.play_button_click()
	
	# Find the HowToPlay screen
	var how_to_play = get_node_or_null("/root/Level1/UI/HowToPlay")
	if not how_to_play:
		# Try alternative path
		how_to_play = get_tree().get_nodes_in_group("how_to_play")
		if not how_to_play.is_empty():
			how_to_play = how_to_play[0]
		else:
			push_error("HowToPlay screen not found!")
			return
	
	# Call the function to open from pause menu
	if how_to_play.has_method("open_from_pause_menu"):
		# Hide this pause menu UI before showing the other screen
		hide()
		# Pass a reference of this menu to the HowToPlay screen so it can call us back
		how_to_play.open_from_pause_menu(self)

func reset_to_start_state():
	"""Puts all UI elements in their initial, pre-animation state."""
	menu_container.modulate.a = 0.0
	banner.scale = Vector2.ZERO
	
	# Disable buttons until animation is done
	resume_button.disabled = true
	quit_button.disabled = true
	restart_button.disabled = true

func show_animated():
	"""Called by the game_paused signal."""
	if is_animating: return
	is_animating = true
	
	reset_to_start_state()
	show()
	
	var tween = create_tween().set_parallel(false)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(menu_container, "modulate:a", 1.0, 0.2)
	tween.tween_property(banner, "scale", banner_final_scale, 0.4).set_trans(Tween.TRANS_BACK)
	await tween.finished
	
	resume_button.disabled = false
	quit_button.disabled = false
	restart_button.disabled = false
	is_animating = false
	is_paused = true

func re_show_animated():
	"""
	Makes the pause menu reappear with animations after a submenu is closed.
	Assumes the game is already in a paused state.
	"""
	if is_animating: return
	is_animating = true
	
	reset_to_start_state()
	show()
	
	var tween = create_tween().set_parallel(false)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(menu_container, "modulate:a", 1.0, 0.2)
	tween.tween_property(banner, "scale", banner_final_scale, 0.4).set_trans(Tween.TRANS_BACK)
	await tween.finished
	
	resume_button.disabled = false
	quit_button.disabled = false
	restart_button.disabled = false
	is_animating = false
	# NOTE: We do not set is_paused here, as it should already be true.

func hide_animated():
	"""Plays the hiding animation."""
	if is_animating: return
	is_animating = true
	
	resume_button.disabled = true
	quit_button.disabled = true
	restart_button.disabled = true
	
	var tween = create_tween().set_parallel(false)
	tween.set_ease(Tween.EASE_IN)
	
	tween.tween_property(banner, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(menu_container, "modulate:a", 0.0, 0.1)
	
	await tween.finished
	
	hide()
	is_animating = false
	is_paused = false

# --- Button Handlers ---
func _on_restart_button_pressed():
	if is_animating: return
	AudioManager.play_button_click()
	AudioManager.stop_all_audio()
	GameManager.restart_level()

func _on_resume_button_pressed():
	if is_animating: return
	AudioManager.play_button_click()
	await hide_animated()
	GameManager.resume_game()

func _on_quit_button_pressed():
	if is_animating: return
	AudioManager.play_button_click()
	AudioManager.stop_all_audio()
	GameManager.resume_game() 
	get_tree().change_scene_to_file("res://scene/cutscenes/StartingCutscene.tscn")
	
func _input(event):
	# The input logic should only ever run if the game is paused
	# AND this specific pause menu UI is visible on screen.
	if is_paused and is_visible_in_tree():
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				_on_resume_button_pressed()

		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if how_to_button and how_to_button.get_global_rect().has_point(event.global_position):
				return

			if not menu_container.get_global_rect().has_point(event.global_position):
				_on_resume_button_pressed()
