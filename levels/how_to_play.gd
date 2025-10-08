extends Control

# --- Node References ---
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var hbox_container: HBoxContainer = $ScrollContainer/HBoxContainer
@onready var title_container: Control = $TitleContainer
@onready var title_label: Label = $TitleContainer/Text
@onready var left_button: TextureButton = $LeftButton
@onready var right_button: TextureButton = $RightButton
@onready var close_button: TextureButton = $CloseButton

# Get all slide TextureRects
@onready var slide_1: TextureRect = $ScrollContainer/HBoxContainer/Slide1
@onready var slide_2: TextureRect = $ScrollContainer/HBoxContainer/Slide2
@onready var slide_3: TextureRect = $ScrollContainer/HBoxContainer/Slide3
@onready var slide_4: TextureRect = $ScrollContainer/HBoxContainer/Slide4
@onready var slide_5: TextureRect = $ScrollContainer/HBoxContainer/Slide5

# --- Variables ---
var current_slide_index: int = 0
var total_slides: int = 0
var visible_slides: Array = []
var slide_width: float = 0.0
var is_animating: bool = false
var was_opened_from_pause: bool = false
var has_shown_for_current_level: bool = false
var current_level_shown: int = 0

# Title animation variables
var title_tween: Tween = null
var title_text: String = "How To Play"
var title_animation_speed: float = 60.0  # Pixels per second
var title_reset_position: float = 0.0
var title_end_position: float = 0.0

# --- NEW: Reference to the pause menu that opened this screen ---
var pause_menu_instance = null

# --- Lifecycle ---
func _ready():
	# Get slide width from first slide
	if slide_1:
		slide_width = slide_1.custom_minimum_size.x
		if slide_width == 0:
			slide_width = slide_1.size.x
	
	# Connect button signals
	left_button.pressed.connect(_on_left_button_pressed)
	right_button.pressed.connect(_on_right_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Setup initial state
	hide()
	
	# Setup title animation
	_setup_title_animation()
	
	# Connect to GameManager's level_started signal
	if not GameManager.level_started.is_connected(_on_level_started):
		GameManager.level_started.connect(_on_level_started)
		print("HowToPlay: Connected to GameManager.level_started signal")
	
	# Also connect to game_started signal for when game begins
	if not GameManager.game_started.is_connected(_on_game_started):
		GameManager.game_started.connect(_on_game_started)
		print("HowToPlay: Connected to GameManager.game_started signal")

func _setup_title_animation():
	"""Setup the railway station style scrolling text animation."""
	title_label.text = title_text
	
	# Wait for the label to calculate its size
	await get_tree().process_frame
	
	# Calculate positions for the scrolling effect
	var container_width = title_container.size.x
	var label_width = title_label.size.x
	
	# Start position: just outside the right edge of container
	title_reset_position = container_width
	# End position: completely scrolled off the left side
	title_end_position = -label_width - 50  # Extra padding
	
	# Position label at start
	title_label.position.x = title_reset_position
	
	# Start the animation
	_start_title_animation()

func _start_title_animation():
	"""Starts the continuous scrolling animation for the title."""
	if not visible:
		return
	
	# Kill any existing tween
	if title_tween and title_tween.is_valid():
		title_tween.kill()
	
	# Reset position
	title_label.position.x = title_reset_position
	
	# Calculate animation duration based on distance and speed
	var distance = abs(title_reset_position - title_end_position)
	var duration = distance / title_animation_speed
	
	# Create new tween for smooth scrolling
	title_tween = create_tween()
	title_tween.set_loops()  # Infinite loop
	title_tween.tween_property(title_label, "position:x", title_end_position, duration)
	title_tween.tween_callback(_reset_title_position)

func _reset_title_position():
	"""Resets the title position for continuous scrolling."""
	title_label.position.x = title_reset_position

func _stop_title_animation():
	"""Stops the title animation."""
	if title_tween and title_tween.is_valid():
		title_tween.kill()
		title_tween = null

func _on_game_started():
	"""Called when the game starts initially."""
	print("HowToPlay: Game started signal received")
	# Reset tracking variables
	has_shown_for_current_level = false
	current_level_shown = 0

func _on_level_started(level_number: int):
	"""Called whenever a new level starts."""
	print("HowToPlay: Level ", level_number, " started")
	
	# Check if we've already shown the tutorial for this level
	if has_shown_for_current_level and current_level_shown == level_number:
		print("HowToPlay: Already shown for level ", level_number, ", skipping")
		return
	
	# Mark that we're showing for this level
	has_shown_for_current_level = true
	current_level_shown = level_number
	
	# Small delay to ensure level is fully loaded
	await get_tree().create_timer(0.5).timeout
	
	# Show the appropriate tutorial
	show_for_level(level_number, false)

# --- Public Methods ---
func show_for_level(level: int, from_pause_menu: bool = false):
	"""Shows the HowToPlay screen with content for the specified level."""
	if is_animating:
		return
	
	print("HowToPlay: Showing tutorial for level ", level)
	was_opened_from_pause = from_pause_menu
	
	# Setup slides based on level
	_setup_slides_for_level(level)
	
	# Initialize to first slide
	current_slide_index = 0
	_update_display()
	
	# Show with animation
	_show_animated()

func _setup_slides_for_level(level: int):
	"""Shows/hides appropriate slides based on level."""
	visible_slides.clear()
	
	# Hide all slides first
	if slide_1: slide_1.visible = false
	if slide_2: slide_2.visible = false
	if slide_3: slide_3.visible = false
	if slide_4: slide_4.visible = false
	if slide_5: slide_5.visible = false
	
	if level == 1:
		# Show slides 1-3 for level 1
		if slide_1: 
			slide_1.visible = true
			visible_slides.append(slide_1)
		if slide_2: 
			slide_2.visible = true
			visible_slides.append(slide_2)
		if slide_3: 
			slide_3.visible = true
			visible_slides.append(slide_3)
	elif level == 2:
		# Show slides 4-5 for level 2
		if slide_4: 
			slide_4.visible = true
			visible_slides.append(slide_4)
		if slide_5: 
			slide_5.visible = true
			visible_slides.append(slide_5)
	
	total_slides = visible_slides.size()
	print("HowToPlay: Setup ", total_slides, " slides for level ", level)

func open_from_pause_menu(pause_menu_ref):
	"""Called from PauseMenu when HowToButton is pressed."""
	# Store the reference to the pause menu
	pause_menu_instance = pause_menu_ref
	
	var current_level = GameManager.get_current_level()
	if current_level == 0:
		current_level = 1
	
	show_for_level(current_level, true)

# --- UI Management ---
func _show_animated():
	"""Shows the HowToPlay screen with animation."""
	is_animating = true
	
	# Pause the game if it's not from pause menu (which is already paused)
	if not was_opened_from_pause and GameManager.is_playing():
		get_tree().paused = true
	
	# Hide other UIs
	_hide_game_uis()
	
	# If opened from pause menu, hide it
	if was_opened_from_pause:
		if GameManager.pause_menu_instance:
			GameManager.pause_menu_instance.visible = false
		if GameManager.event_display_instance:
			GameManager.event_display_instance.visible = true
	
	# Show this screen
	show()
	modulate.a = 0.0
	
	# Start title animation
	_start_title_animation()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	await tween.finished
	
	is_animating = false

func _hide_animated():
	"""Hides the HowToPlay screen with animation."""
	if is_animating:
		return
	
	is_animating = true
	
	# Stop title animation
	_stop_title_animation()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	hide()
	
	# Unpause the game if it wasn't opened from pause menu
	if not was_opened_from_pause:
		get_tree().paused = false
	
	# Restore appropriate UIs
	if was_opened_from_pause:
		# Show pause menu again
		if GameManager.pause_menu_instance:
			GameManager.pause_menu_instance.visible = true
			GameManager.pause_menu_instance.is_paused = true
	else:
		# Show game UIs
		_show_game_uis()
	
	is_animating = false

func _hide_game_uis():
	"""Hides game UIs when HowToPlay is shown."""
	if GameManager.game_ui_instance:
		GameManager.game_ui_instance.hide()
	
	if GameManager.mobile_controls_instance:
		GameManager.mobile_controls_instance.hide()
	
	if GameManager.event_display_instance:
		GameManager.event_display_instance.hide()

func _show_game_uis():
	"""Shows game UIs when HowToPlay is closed."""
	if GameManager.is_playing() or GameManager.current_state == GameManager.GameState.PLAYING:
		if GameManager.game_ui_instance:
			GameManager.game_ui_instance.show()
		
		if GameManager.mobile_controls_instance:
			GameManager.mobile_controls_instance.show()
		
		if GameManager.event_display_instance:
			GameManager.event_display_instance.show()

# --- Slide Navigation ---
func _on_left_button_pressed():
	"""Navigate to previous slide (cyclic)."""
	if is_animating or total_slides == 0:
		return
	
	current_slide_index = (current_slide_index - 1 + total_slides) % total_slides
	_update_display()

func _on_right_button_pressed():
	"""Navigate to next slide (cyclic)."""
	if is_animating or total_slides == 0:
		return
	
	current_slide_index = (current_slide_index + 1) % total_slides
	_update_display()

func _update_display():
	"""Updates the visible slide position."""
	if current_slide_index >= visible_slides.size():
		return
	
	# Calculate scroll position based on current slide
	var separation = hbox_container.get_theme_constant("separation") if hbox_container.has_theme_constant("separation") else 0
	
	# Get the position of the current visible slide
	var target_slide = visible_slides[current_slide_index]
	var target_scroll = target_slide.position.x
	
	# Animate scroll to current slide
	var tween = create_tween()
	tween.tween_property(scroll_container, "scroll_horizontal", target_scroll, 0.3).set_ease(Tween.EASE_IN_OUT)

# --- Close Handling ---
func _on_close_button_pressed():
	"""Closes the HowToPlay screen."""
	if is_animating:
		return
	
	_hide_animated()

# --- Input Handling ---
func _input(event):
	"""Handle keyboard shortcuts for navigation."""
	if not visible or is_animating:
		return
	
	if event.is_action_pressed("ui_left"):
		_on_left_button_pressed()
	elif event.is_action_pressed("ui_right"):
		_on_right_button_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()

# --- Reset Method for Level Transitions ---
func reset_for_new_level():
	"""Called to reset the state when transitioning between levels."""
	has_shown_for_current_level = false
	print("HowToPlay: Reset for new level")

func _exit_tree():
	"""Clean up when node is removed."""
	_stop_title_animation()
