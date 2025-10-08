# CompleteLearningSystem.gd - A COMPLETE working learning system
extends CanvasLayer

# Game object references
var player = null
var trolley = null
var level = null

# Learning state
var learning_phase = 0
var messages_shown = []
var player_actions = []
var last_player_state = ""
var last_force_level = ""

# UI Elements
var objective_panel = null
var tutorial_panel = null
var physics_panel = null
var hint_panel = null
var celebration_panel = null
var status_panel = null

# Status tracking
var push_attempts = 0
var pull_attempts = 0
var force_changes = 0
var has_moved_trolley = false

# Learning messages queue
var message_queue = []
var current_message_index = 0

func _ready():
	print("🎓 Complete Learning System Starting...")
	
	# Set layer to stay on top
	layer = 100
	
	# Create all UI elements
	_create_all_ui()
	
	# Find game objects
	call_deferred("_find_and_connect_objects")
	
	# Start learning sequence
	call_deferred("_start_learning_sequence")

func _create_all_ui():
	# Main container
	var main_container = Control.new()
	main_container.name = "LearningUI"
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_container)
	
	# Create all panels
	_create_objective_panel(main_container)
	_create_tutorial_panel(main_container)
	_create_physics_panel(main_container)
	_create_hint_panel(main_container)
	_create_celebration_panel(main_container)
	_create_status_panel(main_container)
	
	print("✅ All UI panels created")

func _create_objective_panel(parent):
	objective_panel = Panel.new()
	objective_panel.name = "ObjectivePanel"
	objective_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	objective_panel.position = Vector2(20, 20)
	objective_panel.size = Vector2(400, 100)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.3, 0.8, 0.9)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color.YELLOW
	objective_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	objective_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🎯 CURRENT OBJECTIVE"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.YELLOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var objective_text = Label.new()
	objective_text.name = "ObjectiveText"
	objective_text.text = "Press A or D to start learning about forces!"
	objective_text.add_theme_font_size_override("font_size", 12)
	objective_text.add_theme_color_override("font_color", Color.WHITE)
	objective_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(objective_text)
	
	parent.add_child(objective_panel)

func _create_tutorial_panel(parent):
	tutorial_panel = Panel.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.set_anchors_preset(Control.PRESET_CENTER)
	tutorial_panel.position = Vector2(-300, -150)
	tutorial_panel.size = Vector2(600, 300)
	tutorial_panel.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.2, 0.5, 0.95)
	style.corner_radius_top_left = 25
	style.corner_radius_top_right = 25
	style.corner_radius_bottom_left = 25
	style.corner_radius_bottom_right = 25
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_color = Color.GOLD
	tutorial_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	tutorial_panel.add_child(vbox)
	
	var header = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header)
	
	var mascot = Label.new()
	mascot.text = "🎓"
	mascot.add_theme_font_size_override("font_size", 24)
	header.add_child(mascot)
	
	var title = Label.new()
	title.name = "TutorialTitle"
	title.text = "Physics Lesson"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(title)
	
	var message = Label.new()
	message.name = "TutorialMessage"
	message.text = "Tutorial message here"
	message.add_theme_font_size_override("font_size", 14)
	message.add_theme_color_override("font_color", Color.WHITE)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(message)
	
	var concept = Label.new()
	concept.name = "TutorialConcept"
	concept.text = "Physics concept here"
	concept.add_theme_font_size_override("font_size", 12)
	concept.add_theme_color_override("font_color", Color.LIGHT_CYAN)
	concept.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	concept.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(concept)
	
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_container)
	
	var close_button = Button.new()
	close_button.text = "Got it!"
	close_button.add_theme_font_size_override("font_size", 14)
	close_button.custom_minimum_size = Vector2(100, 30)
	close_button.pressed.connect(_on_tutorial_close)
	button_container.add_child(close_button)
	
	var next_button = Button.new()
	next_button.name = "NextButton"
	next_button.text = "Next"
	next_button.add_theme_font_size_override("font_size", 14)
	next_button.custom_minimum_size = Vector2(100, 30)
	next_button.pressed.connect(_on_tutorial_next)
	button_container.add_child(next_button)
	
	parent.add_child(tutorial_panel)

func _create_physics_panel(parent):
	physics_panel = Panel.new()
	physics_panel.name = "PhysicsPanel"
	physics_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	physics_panel.position = Vector2(-350, 20)
	physics_panel.size = Vector2(330, 200)
	physics_panel.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.1, 0.4, 0.95)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color.MAGENTA
	physics_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	physics_panel.add_child(vbox)
	
	var header = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header)
	
	var icon = Label.new()
	icon.text = "🔬"
	icon.add_theme_font_size_override("font_size", 20)
	header.add_child(icon)
	
	var title = Label.new()
	title.name = "PhysicsTitle"
	title.text = "Physics Explanation"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.MAGENTA)
	header.add_child(title)
	
	var explanation = Label.new()
	explanation.name = "PhysicsExplanation"
	explanation.text = "Physics explanation goes here..."
	explanation.add_theme_font_size_override("font_size", 12)
	explanation.add_theme_color_override("font_color", Color.WHITE)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(explanation)
	
	var formula = Label.new()
	formula.name = "PhysicsFormula"
	formula.text = "F = ma"
	formula.add_theme_font_size_override("font_size", 14)
	formula.add_theme_color_override("font_color", Color.YELLOW)
	formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(formula)
	
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.add_theme_font_size_override("font_size", 12)
	close_button.custom_minimum_size = Vector2(80, 25)
	close_button.pressed.connect(_on_physics_close)
	vbox.add_child(close_button)
	
	parent.add_child(physics_panel)

func _create_hint_panel(parent):
	hint_panel = Panel.new()
	hint_panel.name = "HintPanel"
	hint_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_panel.position = Vector2(-300, -100)
	hint_panel.size = Vector2(280, 80)
	hint_panel.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.7, 0.2, 0.9)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	hint_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	hint_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "💡 Tip"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var hint_text = Label.new()
	hint_text.name = "HintText"
	hint_text.text = "Hint appears here"
	hint_text.add_theme_font_size_override("font_size", 11)
	hint_text.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	hint_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint_text)
	
	parent.add_child(hint_panel)

func _create_celebration_panel(parent):
	celebration_panel = Panel.new()
	celebration_panel.name = "CelebrationPanel"
	celebration_panel.set_anchors_preset(Control.PRESET_CENTER)
	celebration_panel.position = Vector2(-200, -100)
	celebration_panel.size = Vector2(400, 200)
	celebration_panel.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.6, 0.2, 0.95)
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_color = Color.GOLD
	celebration_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	celebration_panel.add_child(vbox)
	
	var header = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header)
	
	var trophy = Label.new()
	trophy.text = "🏆"
	trophy.add_theme_font_size_override("font_size", 40)
	header.add_child(trophy)
	
	var title = Label.new()
	title.name = "CelebrationTitle"
	title.text = "Achievement!"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.GOLD)
	header.add_child(title)
	
	var achievement_text = Label.new()
	achievement_text.name = "AchievementText"
	achievement_text.text = "You learned something!"
	achievement_text.add_theme_font_size_override("font_size", 14)
	achievement_text.add_theme_color_override("font_color", Color.WHITE)
	achievement_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(achievement_text)
	
	var close_button = Button.new()
	close_button.text = "Awesome!"
	close_button.add_theme_font_size_override("font_size", 14)
	close_button.custom_minimum_size = Vector2(120, 30)
	close_button.pressed.connect(_on_celebration_close)
	vbox.add_child(close_button)
	
	parent.add_child(celebration_panel)

func _create_status_panel(parent):
	status_panel = Panel.new()
	status_panel.name = "StatusPanel"
	status_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	status_panel.position = Vector2(20, 140)
	status_panel.size = Vector2(300, 120)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	status_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	status_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "📊 LEARNING PROGRESS"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color.CYAN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var push_label = Label.new()
	push_label.name = "PushLabel"
	push_label.text = "Push attempts: 0"
	push_label.add_theme_font_size_override("font_size", 10)
	push_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(push_label)
	
	var pull_label = Label.new()
	pull_label.name = "PullLabel"
	pull_label.text = "Pull attempts: 0"
	pull_label.add_theme_font_size_override("font_size", 10)
	pull_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(pull_label)
	
	var force_label = Label.new()
	force_label.name = "ForceLabel"
	force_label.text = "Force changes: 0"
	force_label.add_theme_font_size_override("font_size", 10)
	force_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(force_label)
	
	var phase_label = Label.new()
	phase_label.name = "PhaseLabel"
	phase_label.text = "Phase: Introduction"
	phase_label.add_theme_font_size_override("font_size", 10)
	phase_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(phase_label)
	
	parent.add_child(status_panel)

func _find_and_connect_objects():
	# Find game objects
	player = get_tree().get_first_node_in_group("players")
	trolley = get_tree().get_first_node_in_group("trolleys")
	level = get_tree().current_scene
	
	print("Player found: ", player != null)
	print("Trolley found: ", trolley != null)
	print("Level found: ", level != null)
	
	# Connect signals
	if player:
		if player.has_signal("state_changed"):
			player.state_changed.connect(_on_player_state_changed)
		if player.has_signal("force_level_changed"):
			player.force_level_changed.connect(_on_force_level_changed)
		print("✅ Player signals connected")

func _start_learning_sequence():
	# Initialize learning messages
	message_queue = [
		{
			"type": "welcome",
			"title": "🚂 Welcome to Coolie No.1!",
			"message": "You're a railway coolie! Your job is to move luggage using physics.",
			"concept": "Forces are pushes and pulls that make objects move.",
			"objective": "Press A to PUSH or D to PULL the trolley!"
		},
		{
			"type": "push_tutorial",
			"title": "💪 Push Force",
			"message": "Great! You're pushing the trolley forward.",
			"concept": "Push forces move objects away from you. F = ma (Force = mass × acceleration)",
			"objective": "Now try PULLING! Press D to pull the trolley."
		},
		{
			"type": "pull_tutorial", 
			"title": "🏃 Pull Force",
			"message": "Excellent! You're pulling the trolley.",
			"concept": "Pull forces bring objects toward you. Pulling gives better control.",
			"objective": "Try changing force levels! Press 1, 2, or 3."
		},
		{
			"type": "force_levels",
			"title": "⚡ Force Levels",
			"message": "You discovered force control!",
			"concept": "Different forces: 1=Low, 2=Medium, 3=High. More force = more acceleration.",
			"objective": "Experiment with different combinations!"
		},
		{
			"type": "mastery",
			"title": "🎓 Physics Master!",
			"message": "You've learned the basics of forces and motion!",
			"concept": "You can now push, pull, and control force levels effectively.",
			"objective": "Complete the level by delivering the luggage!"
		}
	]
	
	# Show first message
	_show_next_message()

func _show_next_message():
	if current_message_index >= message_queue.size():
		return
	
	var message_data = message_queue[current_message_index]
	_show_tutorial_message(message_data)
	_update_objective(message_data.objective)

func _show_tutorial_message(data: Dictionary):
	if not tutorial_panel:
		return
	
	# Prevent duplicate messages
	var message_id = data.get("type", "unknown")
	if message_id in messages_shown:
		return
	
	messages_shown.append(message_id)
	
	# Update content
	var title = tutorial_panel.get_node("TutorialTitle")
	var message = tutorial_panel.get_node("TutorialMessage")
	var concept = tutorial_panel.get_node("TutorialConcept")
	
	title.text = data.get("title", "")
	message.text = data.get("message", "")
	concept.text = data.get("concept", "")
	
	# Show/hide next button
	var next_button = tutorial_panel.get_node("NextButton")
	next_button.visible = current_message_index < message_queue.size() - 1
	
	# Show panel
	tutorial_panel.visible = true
	tutorial_panel.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(tutorial_panel, "modulate:a", 1.0, 0.5)
	
	print("📚 Showing tutorial: ", data.get("title", ""))

func _update_objective(text: String):
	if objective_panel:
		var objective_text = objective_panel.get_node("ObjectiveText")
		objective_text.text = text
		
		# Animate objective update
		var tween = create_tween()
		tween.tween_property(objective_panel, "modulate", Color.YELLOW, 0.2)
		tween.tween_property(objective_panel, "modulate", Color.WHITE, 0.2)

func _update_status_panel():
	if not status_panel:
		return
	
	var push_label = status_panel.get_node("PushLabel")
	var pull_label = status_panel.get_node("PullLabel")
	var force_label = status_panel.get_node("ForceLabel")
	var phase_label = status_panel.get_node("PhaseLabel")
	
	push_label.text = "Push attempts: " + str(push_attempts)
	pull_label.text = "Pull attempts: " + str(pull_attempts)
	force_label.text = "Force changes: " + str(force_changes)
	
	var phase_names = ["Introduction", "Push Learning", "Pull Learning", "Force Control", "Mastery"]
	phase_label.text = "Phase: " + phase_names[min(learning_phase, phase_names.size() - 1)]

# Signal handlers
func _on_player_state_changed(new_state: String):
	print("🎮 Player state changed to: ", new_state)
	
	if new_state == last_player_state:
		return
	
	last_player_state = new_state
	
	match new_state:
		"pushing":
			push_attempts += 1
			_handle_push_action()
		"pulling":
			pull_attempts += 1
			_handle_pull_action()
	
	_update_status_panel()

func _on_force_level_changed(new_level: String):
	print("⚡ Force level changed to: ", new_level)
	
	if new_level == last_force_level:
		return
	
	last_force_level = new_level
	force_changes += 1
	_handle_force_change()
	_update_status_panel()

func _handle_push_action():
	if learning_phase == 0:
		learning_phase = 1
		current_message_index = 1
		_show_next_message()
		_show_celebration("First Push!", "You've learned how to push the trolley!")

func _handle_pull_action():
	if learning_phase == 1:
		learning_phase = 2
		current_message_index = 2
		_show_next_message()
		_show_celebration("First Pull!", "You've learned how to pull the trolley!")

func _handle_force_change():
	if learning_phase == 2 and force_changes >= 2:
		learning_phase = 3
		current_message_index = 3
		_show_next_message()
		_show_celebration("Force Master!", "You've mastered force control!")

func _show_celebration(title: String, text: String):
	if not celebration_panel:
		return
	
	var celebration_title = celebration_panel.get_node("CelebrationTitle")
	var achievement_text = celebration_panel.get_node("AchievementText")
	
	celebration_title.text = title
	achievement_text.text = text
	
	celebration_panel.visible = true
	celebration_panel.modulate.a = 0.0
	celebration_panel.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.parallel().tween_property(celebration_panel, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(celebration_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
	
	print("🎉 Celebration: ", title)

func _show_physics_explanation(title: String, explanation: String, formula: String):
	if not physics_panel:
		return
	
	var physics_title = physics_panel.get_node("PhysicsTitle")
	var physics_explanation = physics_panel.get_node("PhysicsExplanation")
	var physics_formula = physics_panel.get_node("PhysicsFormula")
	
	physics_title.text = title
	physics_explanation.text = explanation
	physics_formula.text = formula
	
	physics_panel.visible = true
	physics_panel.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(physics_panel, "modulate:a", 1.0, 0.5)
	
	print("🔬 Physics: ", title)

func _show_hint(hint_text: String):
	if not hint_panel:
		return
	
	var hint_label = hint_panel.get_node("HintText")
	hint_label.text = hint_text
	
	hint_panel.visible = true
	hint_panel.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(hint_panel, "modulate:a", 1.0, 0.3)
	
	# Auto-hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	
	var hide_tween = create_tween()
	hide_tween.tween_property(hint_panel, "modulate:a", 0.0, 0.3)
	hide_tween.tween_callback(func(): hint_panel.visible = false)

# Button handlers
func _on_tutorial_close():
	if tutorial_panel:
		tutorial_panel.visible = false

func _on_tutorial_next():
	current_message_index += 1
	_show_next_message()

func _on_physics_close():
	if physics_panel:
		physics_panel.visible = false

func _on_celebration_close():
	if celebration_panel:
		celebration_panel.visible = false

# Process function for continuous updates
func _process(_delta):
	# Show contextual hints
	if randf() < 0.005:  # 0.5% chance per frame
		_show_contextual_hints()

func _show_contextual_hints():
	var hints = [
		"Try both pushing (A) and pulling (D) to see the difference!",
		"Use 1, 2, 3 keys to change force levels!",
		"Higher force levels make the trolley move faster!",
		"Physics is all about forces and motion!",
		"Push moves away, pull brings closer - that's physics!"
	]
	
	_show_hint(hints[randi() % hints.size()])

# Input handling for manual testing
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				_show_tutorial_message({
					"type": "test",
					"title": "🧪 Test Tutorial",
					"message": "This is a test tutorial message.",
					"concept": "Testing ensures everything works correctly.",
					"objective": "Test completed!"
				})
			KEY_F2:
				_show_physics_explanation("🔬 Test Physics", "This is a test physics explanation.", "Test = Success")
			KEY_F3:
				_show_celebration("Test Achievement!", "The learning system is working!")
			KEY_F4:
				_show_hint("This is a test hint!")
			KEY_F5:
				print("📊 Learning Status:")
				print("  Phase: ", learning_phase)
				print("  Push attempts: ", push_attempts)
				print("  Pull attempts: ", pull_attempts)
				print("  Force changes: ", force_changes)
				print("  Messages shown: ", messages_shown)
