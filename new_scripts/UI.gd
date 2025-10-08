extends CanvasLayer
class_name GameUI

# UI Node References
@onready var score_label = $GameUI/ScorePanel/ScoreLabel
@onready var time_label = $GameUI/Timer/TimerLabel
@onready var delivery_info_label = $GameUI/ObjectivePanel/ObjectiveText
@onready var pause_button: TextureButton = $GameUI/PauseButton
@onready var pause_menu: Control = $PauseMenu

# UI State
var is_tutorial_active = false
var current_delivery_data = {}
var player_reference = null
var update_timer: Timer

func _ready():
	setup_ui_layout()
	_find_player_reference()
	_setup_update_timer()
	
	# Connect to GameManager signals
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.delivery_timer_updated.connect(_on_delivery_time_updated)
	GameManager.delivery_started.connect(_on_delivery_started)
	GameManager.delivery_completed.connect(_on_delivery_completed)
	GameManager.player_picked_up_trolley.connect(_on_player_picked_up_trolley)
	pause_button.pressed.connect(_on_pause_button_pressed)

func _find_player_reference():
	"""Find player reference for real-time calculations"""
	var scene_tree = get_tree()
	if scene_tree and scene_tree.current_scene:
		player_reference = scene_tree.current_scene.find_child("Player", true, false)
		if not player_reference:
			player_reference = scene_tree.current_scene.find_child("CharacterBody2D", true, false)
		
		if player_reference:
			print("GameUI: Found player reference for dynamic updates")

func _setup_update_timer():
	"""Setup timer for real-time UI updates"""
	update_timer = Timer.new()
	update_timer.wait_time = 2.0  # Update every 2 seconds
	update_timer.timeout.connect(_update_dynamic_info)
	add_child(update_timer)
	update_timer.start()

func _update_dynamic_info():
	"""Update delivery info with real-time data"""
	if not current_delivery_data.is_empty() and player_reference:
		_update_delivery_info_dynamic()

func _on_pause_button_pressed():
	AudioManager.play_sfx(GameConstants.AUDIO.buttonCLick)
	GameManager.pause_game()

func _on_score_updated(new_score: int):
	update_score(new_score)

func _on_delivery_time_updated(time_remaining: float):
	update_time(time_remaining)

func _on_delivery_started(delivery_data: Dictionary):
	current_delivery_data = delivery_data
	_update_delivery_info_complete(delivery_data)

func _on_delivery_completed(success: bool, points_earned: int):
	current_delivery_data = {}  # Clear data
	delivery_info_label.text = "Ready to start..."
	if success:
		show_delivery_complete_message(points_earned)
	else:
		show_delivery_complete_message(0)

func _on_player_picked_up_trolley(player, trolley):
	"""Update info when player picks up trolley"""
	if not current_delivery_data.is_empty():
		_update_delivery_info_complete(current_delivery_data)

func setup_ui_layout():
	"""Setup the basic UI layout and positioning"""
	score_label.text = "0"
	time_label.text = "Time: 0.0s"
	time_label.add_theme_font_size_override("font_size", 20)
	delivery_info_label.text = "Ready to start..."

func update_score(score: int):
	"""Update the score display"""
	score_label.text = "%d" % score

func update_time(time: float):
	"""Update time display with visual feedback"""
	if time < 0:
		time = 0
	
	time_label.text = "Time: %.1fs" % time
	
	# Visual feedback for low time
	if time < 10.0:
		time_label.modulate = Color.RED
	elif time < 20.0:
		time_label.modulate = Color.YELLOW
	else:
		time_label.modulate = Color.WHITE

func _update_delivery_info_complete(delivery_data: Dictionary):
	"""Update delivery info with essential data only"""
	var delivery_num = delivery_data.get("delivery_number", 0)
	var total_deliveries = 5  # Default
	if GameConstants.GAME.has("deliveries_per_level"):
		total_deliveries = GameConstants.GAME.deliveries_per_level
	
	var destination = int(delivery_data.get("destination", 0))
	var handle = delivery_data.get("handle", "unknown").capitalize()
	
	var status_text = ""
	
	if player_reference:
		if player_reference.is_with_trolley:
			status_text = "DELIVERING"
		else:
			status_text = "FIND TROLLEY"
	else:
		status_text = "FIND TROLLEY"
	
	# Format with only essential info
	delivery_info_label.text = "Delivery: %d/%d\n%s\nDestination: %dm" % [
		delivery_num,
		total_deliveries,
		status_text,
		destination
	]

func _update_delivery_info_dynamic():
	"""Update only the status text dynamically"""
	if not player_reference or current_delivery_data.is_empty():
		return
	
	var delivery_num = current_delivery_data.get("delivery_number", 0)
	var total_deliveries = 5
	if GameConstants.GAME.has("deliveries_per_level"):
		total_deliveries = GameConstants.GAME.deliveries_per_level
	
	var destination = int(current_delivery_data.get("destination", 0))
	var handle = current_delivery_data.get("handle", "unknown").capitalize()
	
	var status_text = ""
	
	if player_reference.is_with_trolley:
		status_text = "DELIVERING"
	else:
		status_text = "FIND TROLLEY"
	
	# Update with only essential info
	#delivery_info_label.text = "Delivery: %d/%d\n%s\nDestination: %dm\nHandle: %s" % [
		#delivery_num,
		#total_deliveries,
		#status_text,
		#destination,
		#handle
	#]

	delivery_info_label.text = "Delivery: %d/%d\n%s\nDestination: %dm" % [
		delivery_num,
		total_deliveries,
		status_text,
		destination
	]

func show_delivery_complete_message(points: int):
	"""Show message when delivery is completed"""
	var message_text = "Delivery Complete!\n+%d points" % points if points > 0 else "Delivery Failed!"
	
	var message_label = Label.new()
	message_label.text = message_text
	message_label.position = Vector2(
		get_viewport().get_visible_rect().size.x / 2 - 100,
		get_viewport().get_visible_rect().size.y / 2 - 50
	)
	message_label.add_theme_font_size_override("font_size", 24)
	message_label.modulate = Color.GREEN if points > 0 else Color.RED
	add_child(message_label)
	
	# Animate and remove message
	var tween = create_tween()
	tween.tween_property(message_label, "position:y", message_label.position.y - 50, 1.0)
	tween.parallel().tween_property(message_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): message_label.queue_free())

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_pause_button_pressed()
