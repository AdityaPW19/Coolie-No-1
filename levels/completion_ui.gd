class_name CompletionUI
extends Control

# Make these textures export variables so you can drag-and-drop them in the Inspector!
@export var flying_star_texture: Texture2D
@export var filled_star_texture: Texture2D

# --- Node References (Adjusted to match your screenshot) ---
@onready var completion_container: Control = $CompletionContainer
@onready var title_banner: TextureRect = $CompletionContainer/Levelbanner
@onready var title_label: Label = $CompletionContainer/Levelbanner/TitleLabel
@onready var score_label: Label = $CompletionContainer/ScoreBg/ScoreLabel
@onready var buttons_container: Control = $CompletionContainer/ButtonsContainer 
@onready var replay_button: TextureButton = $CompletionContainer/ButtonsContainer/Retry
@onready var next_level_button: TextureButton = $CompletionContainer/ButtonsContainer/Next
@onready var exit_button: TextureButton = $CompletionContainer/ButtonsContainer/Exit
@onready var gameUI: Control = $"../GameUI"

# Coolie expressions
@onready var coolieExpressionsContainer: Control = $CompletionContainer/CoolieExpressions
@onready var coolieHappy: TextureRect = $CompletionContainer/CoolieExpressions/Cooliehappy
@onready var coolieHappy2: TextureRect = $CompletionContainer/CoolieExpressions/Cooliehappy2
@onready var coolieSad: TextureRect = $CompletionContainer/CoolieExpressions/CoolieSad

# Direct references to the final star destination rects
@onready var star_1_rect: TextureRect = $CompletionContainer/StarsContainer/EmptyStar1/TextureRect # Center
@onready var star_2_rect: TextureRect = $CompletionContainer/StarsContainer/EmptyStar2/TextureRect # Left
@onready var star_3_rect: TextureRect = $CompletionContainer/StarsContainer/EmptyStar3/TextureRect # Right

var is_animating: bool = false
var banner_final_scale: Vector2 = Vector2.ONE
var coolie_final_scale: Vector2 = Vector2.ONE

# --- FIX STEP 1: Add a variable to store the scales ---
var _initial_star_scales: Dictionary = {}
var _initial_score_label_size
var _initial_coolie_scales: Dictionary = {}

@export var debug_mode: bool = false  # Toggle this in the Inspector to test animations
@export var debug_test_data: Dictionary = {
	"level_num": 1,
	"score": 30,
	"successes": 3,
	"total_deliveries": 3
}


func _ready():
	# Hide by default and prepare for animation.
	banner_final_scale = title_banner.scale # <-- Save the original
	
	# --- FIX STEP 2: Store the initial scales of each star ---
	_initial_star_scales[star_1_rect] = star_1_rect.scale
	_initial_star_scales[star_2_rect] = star_2_rect.scale
	_initial_star_scales[star_3_rect] = star_3_rect.scale
	_initial_score_label_size = score_label.scale
	
	# Store initial coolie scales
	if coolieHappy:
		_initial_coolie_scales[coolieHappy] = coolieHappy.scale
		coolie_final_scale = coolieHappy.scale
	if coolieHappy2:
		_initial_coolie_scales[coolieHappy2] = coolieHappy2.scale
	if coolieSad:
		_initial_coolie_scales[coolieSad] = coolieSad.scale
	
	hide()
	_reset_ui_to_start_state()
	
	# Connect to the GameManager's signal
	GameManager.level_results_ready.connect(_on_level_results_ready)
	
	# Auto-trigger debug mode if enabled
	if debug_mode:
		await get_tree().create_timer(0.5).timeout  # Small delay so scene is ready
		_debug_trigger_animation()
	
	# Connect our local button signals
	replay_button.pressed.connect(_on_replay_pressed)
	next_level_button.pressed.connect(_on_next_level_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _debug_trigger_animation():
	if debug_mode:
		print("🔧 Debug Mode: Triggering UI Animation...")
		_on_level_results_ready(
			debug_test_data["level_num"],
			debug_test_data["score"],
			debug_test_data["successes"],
			debug_test_data["total_deliveries"]
		)


func _reset_ui_to_start_state():
	"""Sets all elements to their initial, pre-animation state (invisible and small)."""
	completion_container.modulate.a = 0.0 # Make whole container transparent
	
	title_banner.scale = Vector2.ZERO
	
	score_label.pivot_offset = score_label.size / 2
	score_label.scale = Vector2.ZERO
	
	buttons_container.modulate.a = 0.0
	
	# Reset and hide all coolie expressions
	if coolieHappy:
		coolieHappy.scale = Vector2.ZERO
		coolieHappy.hide()
	if coolieHappy2:
		coolieHappy2.scale = Vector2.ZERO
		coolieHappy2.hide()
	if coolieSad:
		coolieSad.scale = Vector2.ZERO
		coolieSad.hide()
	
	# Ensure all buttons are disabled until animations finish
	replay_button.disabled = true
	next_level_button.disabled = true
	exit_button.disabled = true

func _reset_for_new_level():
	"""Reset the completion UI for a new level"""
	print("CompletionUI: Resetting for new level")
	
	# Reset all star textures to empty
	star_1_rect.texture = null
	star_2_rect.texture = null  
	star_3_rect.texture = null
	
	# Reset scales to original values
	star_1_rect.scale = _initial_star_scales.get(star_1_rect, Vector2.ONE)
	star_2_rect.scale = _initial_star_scales.get(star_2_rect, Vector2.ONE)
	star_3_rect.scale = _initial_star_scales.get(star_3_rect, Vector2.ONE)
	
	# Reset coolie expressions
	if coolieHappy:
		coolieHappy.scale = _initial_coolie_scales.get(coolieHappy, Vector2.ONE)
		coolieHappy.hide()
	if coolieHappy2:
		coolieHappy2.scale = _initial_coolie_scales.get(coolieHappy2, Vector2.ONE)
		coolieHappy2.hide()
	if coolieSad:
		coolieSad.scale = _initial_coolie_scales.get(coolieSad, Vector2.ONE)
		coolieSad.hide()
	
	# Hide the UI and reset state
	hide()
	_reset_ui_to_start_state()
	is_animating = false
	
	# Re-enable buttons for next time
	replay_button.disabled = false
	next_level_button.disabled = false
	exit_button.disabled = false

func _on_level_results_ready(level_num: int, score: int, successes: int, total_deliveries: int):
	if is_animating: return # Prevent the animation from running twice
	is_animating = true
	
	_reset_ui_to_start_state()
	show()
	
	# --- Calculate Stars ---
	var stars_to_award = 0
	if successes == total_deliveries and total_deliveries > 0:
		stars_to_award = 3
	elif successes >= total_deliveries * 0.5:
		stars_to_award = 2
	elif successes > 0:
		stars_to_award = 1
	
	# --- Determine which coolie to show based on stars ---
	var coolie_to_show: TextureRect = null
	if stars_to_award == 3:
		coolie_to_show = coolieHappy
	elif stars_to_award == 2:
		coolie_to_show = coolieHappy2
	else: # 0 or 1 stars
		coolie_to_show = coolieSad
	
	# --- Update Static UI Text ---
	if stars_to_award > 0:
		title_label.text = "LEVEL COMPLETE!"
	else:
		title_label.text = "LEVEL FAILED"
	score_label.text = str(score)

	# --- THE ANIMATION SEQUENCE ---
	# 1. Fade in the main panel background
	var tween = create_tween()
	tween.tween_property(completion_container, "modulate:a", 1.0, 0.3)
	await tween.finished

	# 2. Pop in the title banner
	tween = create_tween()
	tween.tween_property(title_banner, "scale", banner_final_scale, 0.4).set_trans(Tween.TRANS_BACK)
	await tween.finished
	
	# 3. Animate the coolie expression popping in
	await _animate_coolie_expression(coolie_to_show)
	
	# 4. Animate the stars flying in, one by one
	await _animate_stars(stars_to_award)
	
	# 5. Pop in the score label
	tween = create_tween()
	tween.tween_property(score_label, "scale", _initial_score_label_size, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

	# 6. Fade in the buttons
	tween = create_tween()
	tween.tween_property(buttons_container, "modulate:a", 1.0, 0.3)
	await tween.finished
	
	# --- Final Step: Enable Buttons ---
	replay_button.disabled = false
	next_level_button.disabled = false
	exit_button.disabled = false
	
	# Hide the "Next Level" button if it's the last level
	if level_num >= 2: # Or whatever your max level is
		next_level_button.hide()
	else:
		next_level_button.show()
		
	is_animating = false

func _animate_coolie_expression(coolie_to_show: TextureRect):
	"""Animates the selected coolie expression with a pop-in effect"""
	if not coolie_to_show:
		return
	
	# Make sure all coolies are hidden first
	if coolieHappy:
		coolieHappy.hide()
	if coolieHappy2:
		coolieHappy2.hide()
	if coolieSad:
		coolieSad.hide()
	
	# Show and animate the selected coolie
	coolie_to_show.show()
	coolie_to_show.pivot_offset = coolie_to_show.size / 2
	
	# Get the original scale for this coolie
	var original_scale = _initial_coolie_scales.get(coolie_to_show, Vector2.ONE)
	
	# Create the pop-in animation (similar to title banner)
	var tween = create_tween()
	tween.tween_property(coolie_to_show, "scale", original_scale, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished

func _animate_stars(star_count: int):
	if star_count == 0:
		await get_tree().create_timer(0.5).timeout
		return
		
	var star_targets = [star_1_rect, star_2_rect, star_3_rect]
	
	for i in star_count:
		var target_rect = star_targets[i]
		
		var flying_star = TextureRect.new()
		flying_star.texture = flying_star_texture
		flying_star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flying_star.pivot_offset = flying_star.get_minimum_size() / 2
		add_child(flying_star)
		
		var viewport_size = get_viewport().get_visible_rect().size
		var start_pos = Vector2(randf_range(-50, viewport_size.x + 50), -100)
		flying_star.global_position = start_pos

		var flight_tween = create_tween()
		flight_tween.parallel().tween_property(flying_star, "global_position", target_rect.global_position, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		flight_tween.parallel().tween_property(flying_star, "rotation_degrees", randf_range(-360, 360), 0.6)
		
		await flight_tween.finished
		flying_star.queue_free()
		
		# --- MODIFIED SECTION ---
		target_rect.texture = filled_star_texture
		target_rect.pivot_offset = target_rect.size / 2
		
		# Get the original scale we saved in _ready()
		var original_scale = _initial_star_scales.get(target_rect, Vector2.ONE)

		var pop_tween = create_tween()
		# For the "pop" effect, scale it to 1.5x its *original* size
		pop_tween.tween_property(target_rect, "scale", original_scale * 1.5, 0.15).set_trans(Tween.TRANS_SINE)
		# For the final state, tween it back to its actual original size
		pop_tween.tween_property(target_rect, "scale", original_scale, 0.25).set_trans(Tween.TRANS_BOUNCE)
		
		await pop_tween.finished

func _hide_animated():
	"""Plays the hiding animation in reverse."""
	if is_animating: return
	is_animating = true
	
	# Disable buttons immediately to prevent multiple clicks
	replay_button.disabled = true
	next_level_button.disabled = true
	exit_button.disabled = true
	
	# Create a tween that plays animations in reverse order
	var tween = create_tween().set_parallel(false)
	tween.set_ease(Tween.EASE_IN) # Use ease-in for disappearing effects
	
	# 1. Fade out buttons
	tween.tween_property(buttons_container, "modulate:a", 0.0, 0.2)
	
	# 2. Shrink score, banner, and coolie
	tween.parallel().tween_property(score_label, "scale", Vector2.ZERO, 0.2)
	tween.parallel().tween_property(title_banner, "scale", Vector2.ZERO, 0.2)
	
	# Shrink whichever coolie is visible
	if coolieHappy and coolieHappy.visible:
		tween.parallel().tween_property(coolieHappy, "scale", Vector2.ZERO, 0.2)
	if coolieHappy2 and coolieHappy2.visible:
		tween.parallel().tween_property(coolieHappy2, "scale", Vector2.ZERO, 0.2)
	if coolieSad and coolieSad.visible:
		tween.parallel().tween_property(coolieSad, "scale", Vector2.ZERO, 0.2)
	
	# 3. Fade out the whole container
	tween.tween_property(completion_container, "modulate:a", 0.0, 0.3)
	
	# Wait for the entire sequence to finish before proceeding
	await tween.finished
	
	hide() # Fully hide the UI after animation
	is_animating = false

# --- Button Handlers (Same clean logic as before) ---
func _on_replay_pressed():
	if is_animating: return
	# The scene will be reloaded, destroying this UI, so we just call the manager.
	GameManager.restart_level()

func _on_next_level_pressed():
	if is_animating: return
	
	print("CompletionUI: Player clicked Next Level button")
	
	# Play hide animation first
	await _hide_animated()
	
	# Reset this UI completely
	_reset_for_new_level()
	
	# Unpause the game
	get_tree().paused = false
	
	# Make sure GameUI is visible
	if gameUI:
		gameUI.visible = true
	
	# Reset HowToPlay tracking so it shows for the new level
	var how_to_play = get_node_or_null("/root/Level1/UI/HowToPlay")
	if how_to_play and how_to_play.has_method("reset_for_new_level"):
		how_to_play.reset_for_new_level()
	
	# Start the next level
	var next_level_num = GameManager.get_current_level() + 1
	print("CompletionUI: Starting level ", next_level_num)
	GameManager.start_level(next_level_num)
	
func _on_exit_pressed():
	# We do the same for the exit button.
	await _hide_animated()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/cutscenes/StartingCutscene.tscn")
