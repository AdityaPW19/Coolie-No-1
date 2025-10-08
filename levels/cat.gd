class_name Cat
extends Node2D

# --- EXPORT VARIABLES ---
@export var player: CharacterBody2D
@export var follow_lerp_weight: float = 7.5
@export var guide_jump_height: float = -30.0

# --- NODE REFERENCES ---
@onready var animated_sprite: AnimatedSprite2D = $CatSprite
@onready var cat_pos_1: Marker2D = player.get_node("CatPosition1")
@onready var cat_pos_2: Marker2D = player.get_node("CatPosition2")
@onready var dialogue_bubble: Sprite2D = $DialogueBubble
@onready var rich_text_label: RichTextLabel = $DialogueBubble/RichTextLabel
@onready var cat_sound_1: AudioStreamPlayer2D = $CatSound1 # Idle/Walk/Success sound
@onready var cat_sound_2: AudioStreamPlayer2D = $CatSound2 # Guide/Fail sound

# --- STATE MANAGEMENT ---
var is_guiding: bool = false
var guide_timer: Timer
var idle_sound_timer: Timer
var current_guide_direction_str: String = "" # This will switch between trolley and delivery direction
var should_guide: bool = false # Controls when cat should guide

# --- ANIMATION & DIRECTION ---
var current_anim: String = ""

func _ready():
	global_position = _get_target_marker().global_position
	dialogue_bubble.hide()
	
	# --- Setup Timers ---
	guide_timer = Timer.new()
	guide_timer.wait_time = 3.0
	guide_timer.one_shot = false
	guide_timer.timeout.connect(_on_guide_timer_timeout)
	add_child(guide_timer)
	
	idle_sound_timer = Timer.new()
	idle_sound_timer.one_shot = true
	#idle_sound_timer.timeout.connect(_on_idle_sound_timer_timeout)
	add_child(idle_sound_timer)
	
	# Connect to GameManager signals
	GameManager.delivery_started.connect(_on_delivery_started)
	GameManager.delivery_succeeded.connect(_on_delivery_succeeded)
	GameManager.delivery_failed.connect(_on_delivery_failed)
	
	# Connect to player signals for trolley pickup
	GameManager.player_picked_up_trolley.connect(_on_player_picked_up_trolley)

func _process(delta: float):
	if not is_instance_valid(player):
		set_animation("idle")
		return

	var target_pos = _get_target_marker().global_position
	global_position = global_position.lerp(target_pos, delta * follow_lerp_weight)

	if player.is_idle():
		# Start timers if they are stopped
		if guide_timer.is_stopped(): guide_timer.start()
		_start_idle_sound_timer_if_stopped()
		
		if not is_guiding:
			set_animation("idle")
			set_cat_facing_direction(player.is_facing_right)
	else:
		# Player is moving, so stop guide timer but keep idle/walk sound timer running
		if not guide_timer.is_stopped(): guide_timer.stop()
		_start_idle_sound_timer_if_stopped()
		
		if dialogue_bubble.visible: dialogue_bubble.hide()
		is_guiding = false
		set_animation("run")
		set_cat_facing_direction(player.is_facing_right)

# --- SIGNAL HANDLERS ---
func _on_delivery_started(delivery_data: Dictionary):
	# Show trolley direction initially (player doesn't have trolley yet)
	current_guide_direction_str = GameManager.get_trolley_direction_from_delivery()
	should_guide = true
	print("Cat: Guiding towards trolley direction: ", current_guide_direction_str)

func _on_player_picked_up_trolley(player_node: CharacterBody2D, trolley: RigidBody2D):
	# Switch to delivery direction when player picks up trolley
	if player_node == player:
		current_guide_direction_str = player.fixed_delivery_direction
		should_guide = true
		print("Cat: Switching to delivery direction: ", current_guide_direction_str)

func _on_delivery_succeeded(_delivery_data, _points):
	# Play success sound and show happy dialogue
	idle_sound_timer.stop()
	cat_sound_1.play()
	show_dialogue("Meow! Meow! 😺", 2.0)
	
	# Stop guiding
	current_guide_direction_str = ""
	should_guide = false

func _on_delivery_failed(_delivery_data):
	# Play fail sound and show sad dialogue
	idle_sound_timer.stop()
	cat_sound_2.play()
	show_dialogue("Meow... 😿", 2.0)
	
	# Stop guiding
	current_guide_direction_str = ""
	should_guide = false

# --- CORE LOGIC & TIMERS ---
func _on_guide_timer_timeout():
	# Only guide if we should guide, player is idle, not currently guiding, and we have a direction
	if should_guide and player.is_idle() and not is_guiding and current_guide_direction_str != "":
		# Hide cat guidance when player is near trolley (same logic as arrow)
		if player.nearby_trolley != null:
			return
			
		if randf() < 0.4:
			var direction_int = 1 if current_guide_direction_str == "right" else -1
			call_deferred("_perform_guide_animation", direction_int)

func _on_idle_sound_timer_timeout():
	"""Plays the idle sound and sets a new random wait time for the next one."""
	cat_sound_1.play()

func _start_idle_sound_timer_if_stopped():
	"""Checks if the interval sound timer is stopped, and if so, starts it with a new random time."""
	if idle_sound_timer.is_stopped():
		idle_sound_timer.wait_time = randf_range(4.0, 8.0)
		idle_sound_timer.start()

func _perform_guide_animation(direction: int):
	if is_guiding: return
	is_guiding = true
	
	# Stop interval sound and play guide sound
	idle_sound_timer.stop()
	cat_sound_2.play()

	# Show appropriate text based on what we're guiding towards
	var guide_text = ""
	if player.is_with_trolley:
		guide_text = "DELIVERY %s!" % current_guide_direction_str.to_upper()
	else:
		guide_text = "TROLLEY %s!" % current_guide_direction_str.to_upper()
	
	rich_text_label.text = "Meow! %s" % guide_text
	dialogue_bubble.show()

	set_cat_facing_direction(direction == 1)
	set_animation("jump")
	
	var motion_tween = create_tween()
	var lean_angle = deg_to_rad(15) if direction == 1 else deg_to_rad(-15)
	
	var start_y = animated_sprite.position.y
	motion_tween.tween_property(animated_sprite, "position:y", start_y + guide_jump_height, 0.2).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(animated_sprite, "position:y", start_y, 0.3).set_ease(Tween.EASE_IN).set_delay(0.2)
	motion_tween.parallel().tween_property(animated_sprite, "rotation", lean_angle, 0.2).set_delay(0.1).set_ease(Tween.EASE_OUT)
	motion_tween.parallel().tween_property(animated_sprite, "rotation", 0, 0.3).set_delay(0.5).set_ease(Tween.EASE_IN)
	
	await motion_tween.finished
	dialogue_bubble.hide()
	is_guiding = false

# --- HELPER FUNCTIONS ---
func show_dialogue(text: String, duration: float):
	rich_text_label.text = text
	dialogue_bubble.show()
	var dialogue_hide_timer = get_tree().create_timer(duration)
	dialogue_hide_timer.timeout.connect(dialogue_bubble.hide)

func _get_target_marker() -> Marker2D:
	if player.is_facing_right: return cat_pos_1
	else: return cat_pos_2

func set_cat_facing_direction(is_facing_right: bool):
	animated_sprite.flip_h = not is_facing_right

func set_animation(new_anim: String):
	if current_anim != new_anim:
		current_anim = new_anim
		animated_sprite.play(current_anim)
