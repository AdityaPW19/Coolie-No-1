class_name EventDisplayUI
extends Control

# Node references
@onready var message_text: Label = $MessageText
@onready var feedback_text: Label = $FeedBackText
@onready var hint_button: Button = $HintSystem/HintButton
@onready var event_manager: Node = $"../../EventManager"

# Animation tweens
var message_tween: Tween
var feedback_tween: Tween

func _ready():
	# Start with labels invisible
	message_text.modulate.a = 0.0
	feedback_text.modulate.a = 0.0
	message_text.show()
	feedback_text.show()
	
	# Connect to EventManager
	event_manager.show_feedback.connect(_on_show_feedback)
	hint_button.pressed.connect(_on_hint_button_pressed)

func _on_show_feedback(text: String, duration: float, is_objective: bool):
	"""Handle both objective and feedback messages"""
	if is_objective:
		_show_objective_message(text, duration)
	else:
		_show_feedback_message(text, duration)

func _show_objective_message(text: String, duration: float):
	"""Show objective message in main message label"""
	# Stop existing animation
	if message_tween and message_tween.is_running():
		message_tween.kill()
	
	# Set text and reset state
	message_text.text = text
	message_text.modulate.a = 0.0
	
	# Create animation
	message_tween = create_tween()
	var tween_chain = message_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Fade in quickly
	tween_chain.tween_property(message_text, "modulate:a", 1.0, 0.2)
	# Stay visible for duration
	tween_chain.tween_interval(duration)
	# Fade out
	tween_chain.tween_property(message_text, "modulate:a", 0.0, 0.5)

func _show_feedback_message(text: String, duration: float):
	"""Show feedback message in feedback label without interrupting objectives"""
	# Stop existing feedback animation
	if feedback_tween and feedback_tween.is_running():
		feedback_tween.kill()
	
	# Set text and reset state
	feedback_text.text = text
	feedback_text.modulate.a = 0.0
	
	# Create animation
	feedback_tween = create_tween()
	var tween_chain = feedback_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Quick fade in
	tween_chain.tween_property(feedback_text, "modulate:a", 1.0, 0.2)
	# Stay visible for duration
	tween_chain.tween_interval(duration)
	# Fade out
	tween_chain.tween_property(feedback_text, "modulate:a", 0.0, 0.3)

func _on_hint_button_pressed():
	"""Request hint from EventManager"""
	event_manager.request_hint()
