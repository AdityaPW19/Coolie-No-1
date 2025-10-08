# EnhancedGameUI.gd - Beautiful, engaging UI with learning integration
extends Control

# UI Node References
@onready var hud_container = $HUDContainer
@onready var learning_overlay = $LearningOverlay
@onready var progress_system = $ProgressSystem
@onready var feedback_system = $FeedbackSystem

# HUD Elements
var player_status_widget = null
var trolley_info_widget = null
var force_control_widget = null
var physics_meter_widget = null
var objective_widget = null
var timer_widget = null
var hint_system_widget = null

# Learning System Elements
var tutorial_bubble = null
var physics_explanation_panel = null
var achievement_popup = null
var concept_tracker = null

# Progress System Elements
var progress_bar = null
var star_rating = null
var performance_metrics = null

# Feedback System Elements
var particle_effects = null
var sound_feedback = null
var visual_feedback = null

# Game references
var player_reference = null
var trolley_reference = null
var level_reference = null
var learning_system = null

# UI State
var ui_theme = null
var current_ui_mode = "gameplay"  # "gameplay", "tutorial", "celebration"
var ui_animations = {}
var ui_update_timer = 0.0
var ui_update_interval = 0.033  # 30 FPS UI updates

# Color scheme
var colors = {
	"primary": Color(0.2, 0.4, 0.8, 1.0),
	"secondary": Color(0.8, 0.4, 0.2, 1.0),
	"accent": Color(0.9, 0.7, 0.2, 1.0),
	"success": Color(0.2, 0.8, 0.3, 1.0),
	"warning": Color(0.9, 0.6, 0.2, 1.0),
	"danger": Color(0.8, 0.2, 0.2, 1.0),
	"background": Color(0.1, 0.1, 0.1, 0.9),
	"text": Color(0.9, 0.9, 0.9, 1.0),
	"text_secondary": Color(0.7, 0.7, 0.7, 1.0)
}

func _ready():
	print("🎨 Enhanced Game UI Initializing...")
	
	# Setup UI theme
	_create_ui_theme()
	
	# Create UI structure
	_create_ui_structure()
	
	# Create all UI components
	_create_hud_elements()
	_create_learning_elements()
	_create_progress_elements()
	_create_feedback_elements()
	
	# Find game references
	call_deferred("_find_game_references")
	
	# Apply theme
	_apply_theme()
	
	print("✅ Enhanced Game UI Ready!")

func _create_ui_theme():
	ui_theme = Theme.new()
	
	# Create style boxes for different UI elements
	var primary_style = StyleBoxFlat.new()
	primary_style.bg_color = colors.primary
	primary_style.corner_radius_top_left = 12
	primary_style.corner_radius_top_right = 12
	primary_style.corner_radius_bottom_left = 12
	primary_style.corner_radius_bottom_right = 12
	primary_style.border_width_top = 2
	primary_style.border_width_bottom = 2
	primary_style.border_width_left = 2
	primary_style.border_width_right = 2
	primary_style.border_color = colors.accent
	
	var secondary_style = StyleBoxFlat.new()
	secondary_style.bg_color = colors.secondary
	secondary_style.corner_radius_top_left = 8
	secondary_style.corner_radius_top_right = 8
	secondary_style.corner_radius_bottom_left = 8
	secondary_style.corner_radius_bottom_right = 8
	
	var background_style = StyleBoxFlat.new()
	background_style.bg_color = colors.background
	background_style.corner_radius_top_left = 15
	background_style.corner_radius_top_right = 15
	background_style.corner_radius_bottom_left = 15
	background_style.corner_radius_bottom_right = 15
	
	# Add styles to theme
	ui_theme.set_stylebox("panel", "Panel", primary_style)
	ui_theme.set_stylebox("normal", "Button", secondary_style)
	ui_theme.set_stylebox("hover", "Button", primary_style)
	ui_theme.set_stylebox("pressed", "Button", background_style)

func _create_ui_structure():
	# Main HUD Container
	hud_container = Control.new()
	hud_container.name = "HUDContainer"
	hud_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_container)
	
	# Learning Overlay
	learning_overlay = Control.new()
	learning_overlay.name = "LearningOverlay"
	learning_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	learning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(learning_overlay)
	
	# Progress System
	progress_system = Control.new()
	progress_system.name = "ProgressSystem"
	progress_system.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	progress_system.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(progress_system)
	
	# Feedback System
	feedback_system = Control.new()
	feedback_system.name = "FeedbackSystem"
	feedback_system.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	feedback_system.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(feedback_system)

func _create_hud_elements():
	# Player Status Widget
	player_status_widget = _create_player_status_widget()
	hud_container.add_child(player_status_widget)
	
	# Trolley Info Widget
	trolley_info_widget = _create_trolley_info_widget()
	hud_container.add_child(trolley_info_widget)
	
	# Force Control Widget
	force_control_widget = _create_force_control_widget()
	hud_container.add_child(force_control_widget)
	
	# Physics Meter Widget
	physics_meter_widget = _create_physics_meter_widget()
	hud_container.add_child(physics_meter_widget)
	
	# Objective Widget
	objective_widget = _create_objective_widget()
	hud_container.add_child(objective_widget)
	
	# Timer Widget
	timer_widget = _create_timer_widget()
	hud_container.add_child(timer_widget)
	
	# Hint System Widget
	hint_system_widget = _create_hint_system_widget()
	hud_container.add_child(hint_system_widget)

func _create_player_status_widget():
	var widget = Panel.new()
	widget.name = "PlayerStatusWidget"
	widget.set_anchors_preset(Control.PRESET_TOP_LEFT)
	widget.position = Vector2(20, 20)
	widget.size = Vector2(280, 120)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	widget.add_child(vbox)
	
	# Title with icon
	var title_container = HBoxContainer.new()
	vbox.add_child(title_container)
	
	var icon = Label.new()
	icon.text = "🏃"
	icon.add_theme_font_size_override("font_size", 20)
	title_container.add_child(icon)
	
	var title = Label.new()
	title.text = "COOLIE STATUS"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", colors.accent)
	title_container.add_child(title)
	
	# Status info
	var info_container = VBoxContainer.new()
	info_container.add_theme_constant_override("separation", 4)
	vbox.add_child(info_container)
	
	var state_label = Label.new()
	state_label.name = "StateLabel"
	state_label.text = "State: Ready"
	state_label.add_theme_font_size_override("font_size", 14)
	info_container.add_child(state_label)
	
	var speed_label = Label.new()
	speed_label.name = "SpeedLabel"
	speed_label.text = "Speed: 0 m/s"
	speed_label.add_theme_font_size_override("font_size", 14)
	info_container.add_child(speed_label)
	
	var energy_bar = ProgressBar.new()
	energy_bar.name = "EnergyBar"
	energy_bar.max_value = 100
	energy_bar.value = 100
	energy_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_child(energy_bar)
	
	var energy_label = Label.new()
	energy_label.text = "Energy: 100%"
	energy_label.add_theme_font_size_override("font_size", 12)
	energy_label.add_theme_color_override("font_color", colors.success)
	info_container.add_child(energy_label)
	
	return widget

func _create_trolley_info_widget():
	var widget = Panel.new()
	widget.name = "TrolleyInfoWidget"
	widget.set_anchors_preset(Control.PRESET_TOP_LEFT)
	widget.position = Vector2(320, 20)
	widget.size = Vector2(280, 120)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	widget.add_child(vbox)
	
	# Title with icon
	var title_container = HBoxContainer.new()
	vbox.add_child(title_container)
	
	var icon = Label.new()
	icon.text = "🛒"
	icon.add_theme_font_size_override("font_size", 20)
	title_container.add_child(icon)
	
	var title = Label.new()
	title.text = "TROLLEY STATUS"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", colors.accent)
	title_container.add_child(title)
	
	# Trolley info
	var info_container = VBoxContainer.new()
	info_container.add_theme_constant_override("separation", 4)
	vbox.add_child(info_container)
	
	var weight_label = Label.new()
	weight_label.name = "WeightLabel"
	weight_label.text = "Weight: -- kg"
	weight_label.add_theme_font_size_override("font_size", 14)
	info_container.add_child(weight_label)
	
	var distance_label = Label.new()
	distance_label.name = "DistanceLabel"
	distance_label.text = "Distance: -- m"
	distance_label.add_theme_font_size_override("font_size", 14)
	info_container.add_child(distance_label)
	
	var momentum_bar = ProgressBar.new()
	momentum_bar.name = "MomentumBar"
	momentum_bar.max_value = 100
	momentum_bar.value = 0
	momentum_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_child(momentum_bar)
	
	var momentum_label = Label.new()
	momentum_label.text = "Momentum: 0%"
	momentum_label.add_theme_font_size_override("font_size", 12)
	momentum_label.add_theme_color_override("font_color", colors.text_secondary)
	info_container.add_child(momentum_label)
	
	return widget

func _create_force_control_widget():
	var widget = Panel.new()
	widget.name = "ForceControlWidget"
	widget.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	widget.position = Vector2(20, -160)
	widget.size = Vector2(300, 140)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	widget.add_child(vbox)
	
	# Title
	var title_container = HBoxContainer.new()
	vbox.add_child(title_container)
	
	var icon = Label.new()
	icon.text = "⚡"
	icon.add_theme_font_size_override("font_size", 20)
	title_container.add_child(icon)
	
	var title = Label.new()
	title.text = "FORCE CONTROL"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", colors.accent)
	title_container.add_child(title)
	
	# Force buttons
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 8)
	vbox.add_child(button_container)
	
	var force_levels = ["LOW", "MEDIUM", "HIGH"]
	var force_colors = [colors.success, colors.warning, colors.danger]
	
	for i in range(3):
		var btn = Button.new()
		btn.name = "Force" + force_levels[i]
		btn.text = force_levels[i]
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_color_override("font_color", force_colors[i])
		btn.custom_minimum_size = Vector2(80, 30)
		btn.pressed.connect(_on_force_button_pressed.bind(force_levels[i].to_lower()))
		button_container.add_child(btn)
	
	# Force meter
	var meter_container = VBoxContainer.new()
	vbox.add_child(meter_container)
	
	var meter_label = Label.new()
	meter_label.text = "Current Force Level:"
	meter_label.add_theme_font_size_override("font_size", 12)
	meter_container.add_child(meter_label)
	
	var force_meter = ProgressBar.new()
	force_meter.name = "ForceMeter"
	force_meter.max_value = 3
	force_meter.value = 2
	force_meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter_container.add_child(force_meter)
	
	return widget

func _create_physics_meter_widget():
	var widget = Panel.new()
	widget.name = "PhysicsMeterWidget"
	widget.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	widget.position = Vector2(-320, 20)
	widget.size = Vector2(300, 200)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	widget.add_child(vbox)
	
	# Title
	var title_container = HBoxContainer.new()
	vbox.add_child(title_container)
	
	var icon = Label.new()
	icon.text = "🔬"
	icon.add_theme_font_size_override("font_size", 20)
	title_container.add_child(icon)
	
	var title = Label.new()
	title.text = "PHYSICS METER"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", colors.accent)
	title_container.add_child(title)
	
	# Physics readings
	var readings_container = VBoxContainer.new()
	readings_container.add_theme_constant_override("separation", 6)
	vbox.add_child(readings_container)
	
	# Friction meter
	var friction_container = VBoxContainer.new()
	readings_container.add_child(friction_container)
	
	var friction_label = Label.new()
	friction_label.text = "Friction:"
	friction_label.add_theme_font_size_override("font_size", 12)
	friction_container.add_child(friction_label)
	
	var friction_bar = ProgressBar.new()
	friction_bar.name = "FrictionBar"
	friction_bar.max_value = 100
	friction_bar.value = 50
	friction_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	friction_container.add_child(friction_bar)
	
	# Gravity effect meter
	var gravity_container = VBoxContainer.new()
	readings_container.add_child(gravity_container)
	
	var gravity_label = Label.new()
	gravity_label.text = "Gravity Effect:"
	gravity_label.add_theme_font_size_override("font_size", 12)
	gravity_container.add_child(gravity_label)
	
	var gravity_bar = ProgressBar.new()
	gravity_bar.name = "GravityBar"
	gravity_bar.max_value = 100
	gravity_bar.value = 50
	gravity_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gravity_container.add_child(gravity_bar)
	
	# Efficiency meter
	var efficiency_container = VBoxContainer.new()
	readings_container.add_child(efficiency_container)
	
	var efficiency_label = Label.new()
	efficiency_label.text = "Efficiency:"
	efficiency_label.add_theme_font_size_override("font_size", 12)
	efficiency_container.add_child(efficiency_label)
	
	var efficiency_bar = ProgressBar.new()
	efficiency_bar.name = "EfficiencyBar"
	efficiency_bar.max_value = 100
	efficiency_bar.value = 75
	efficiency_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	efficiency_container.add_child(efficiency_bar)
	
	return widget

func _create_objective_widget():
	var widget = Panel.new()
	widget.name = "ObjectiveWidget"
	widget.set_anchors_preset(Control.PRESET_TOP_LEFT)
	widget.position = Vector2(20, 160)
	widget.size = Vector2(400, 80)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	widget.add_child(vbox)
	
	# Title
	var title_container = HBoxContainer.new()
	vbox.add_child(title_container)
	
	var icon = Label.new()
	icon.text = "🎯"
	icon.add_theme_font_size_override("font_size", 18)
	title_container.add_child(icon)
	
	var title = Label.new()
	title.text = "CURRENT OBJECTIVE"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", colors.accent)
	title_container.add_child(title)
	
	# Objective text
	var objective_text = Label.new()
	objective_text.name = "ObjectiveText"
	objective_text.text = "Deliver the luggage to the train safely!"
	objective_text.add_theme_font_size_override("font_size", 12)
	objective_text.add_theme_color_override("font_color", colors.text)
	objective_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(objective_text)
	
	return widget

func _create_timer_widget():
	var widget = Panel.new()
	widget.name = "TimerWidget"
	widget.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	widget.position = Vector2(-180, 240)
	widget.size = Vector2(160, 60)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	widget.add_child(vbox)
	
	# Title
	var title_container = HBoxContainer.new()
	vbox.add_child(title_container)
	
	var icon = Label.new()
	icon.text = "⏰"
	icon.add_theme_font_size_override("font_size", 16)
	title_container.add_child(icon)
	
	var title = Label.new()
	title.text = "TIME"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", colors.accent)
	title_container.add_child(title)
	
	# Timer display
	var time_display = Label.new()
	time_display.name = "TimeDisplay"
	time_display.text = "00:00"
	time_display.add_theme_font_size_override("font_size", 18)
	time_display.add_theme_color_override("font_color", colors.text)
	time_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(time_display)
	
	return widget

func _create_hint_system_widget():
	var widget = Panel.new()
	widget.name = "HintSystemWidget"
	widget.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	widget.position = Vector2(-320, -100)
	widget.size = Vector2(300, 80)
	widget.visible = false
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	widget.add_child(vbox)
	
	# Title
	var title_container = HBoxContainer.new()
	vbox.add_child(title_container)
	
	var icon = Label.new()
	icon.text = "💡"
	icon.add_theme_font_size_override("font_size", 16)
	title_container.add_child(icon)
	
	var title = Label.new()
	title.text = "HELPFUL TIP"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", colors.accent)
	title_container.add_child(title)
	
	# Hint text
	var hint_text = Label.new()
	hint_text.name = "HintText"
	hint_text.text = "Try different force levels to see what works best!"
	hint_text.add_theme_font_size_override("font_size", 12)
	hint_text.add_theme_color_override("font_color", colors.text)
	hint_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint_text)
	
	return widget

func _create_learning_elements():
	# Tutorial Bubble
	tutorial_bubble = _create_tutorial_bubble()
	learning_overlay.add_child(tutorial_bubble)
	
	# Physics Explanation Panel
	physics_explanation_panel = _create_physics_explanation_panel()
	learning_overlay.add_child(physics_explanation_panel)
	
	# Achievement Popup
	achievement_popup = _create_achievement_popup()
	learning_overlay.add_child(achievement_popup)
	
	# Concept Tracker
	concept_tracker = _create_concept_tracker()
	learning_overlay.add_child(concept_tracker)

func _create_tutorial_bubble():
	var bubble = Panel.new()
	bubble.name = "TutorialBubble"
	bubble.set_anchors_preset(Control.PRESET_CENTER)
	bubble.position = Vector2(-300, -150)
	bubble.size = Vector2(600, 300)
	bubble.visible = false
	
	# Custom bubble style
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
	style.border_color = colors.accent
	bubble.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	bubble.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var mascot = Label.new()
	mascot.text = "🎓"
	mascot.add_theme_font_size_override("font_size", 32)
	header.add_child(mascot)
	
	var title = Label.new()
	title.name = "TutorialTitle"
	title.text = "Physics Lesson"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", colors.accent)
	header.add_child(title)
	
	# Content
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	vbox.add_child(content)
	
	var message = Label.new()
	message.name = "TutorialMessage"
	message.text = "Welcome to the physics tutorial!"
	message.add_theme_font_size_override("font_size", 16)
	message.add_theme_color_override("font_color", colors.text)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(message)
	
	var concept = Label.new()
	concept.name = "TutorialConcept"
	concept.text = "Physics concept explanation..."
	concept.add_theme_font_size_override("font_size", 14)
	concept.add_theme_color_override("font_color", Color.LIGHT_CYAN)
	concept.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(concept)
	
	var hint = Label.new()
	hint.name = "TutorialHint"
	hint.text = "Try this action..."
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", colors.success)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)
	
	# Actions
	var actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(actions)
	
	var close_btn = Button.new()
	close_btn.text = "Got it!"
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.pressed.connect(_on_tutorial_close)
	actions.add_child(close_btn)
	
	return bubble

func _create_physics_explanation_panel():
	var panel = Panel.new()
	panel.name = "PhysicsExplanationPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-450, 20)
	panel.size = Vector2(430, 250)
	panel.visible = false
	
	# Physics panel style
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
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var icon = Label.new()
	icon.text = "🔬"
	icon.add_theme_font_size_override("font_size", 24)
	header.add_child(icon)
	
	var title = Label.new()
	title.name = "PhysicsTitle"
	title.text = "Physics Explanation"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.MAGENTA)
	header.add_child(title)
	
	# Content
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	vbox.add_child(content)
	
	var explanation = Label.new()
	explanation.name = "PhysicsExplanation"
	explanation.text = "Physics explanation goes here..."
	explanation.add_theme_font_size_override("font_size", 14)
	explanation.add_theme_color_override("font_color", colors.text)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(explanation)
	
	var formula = Label.new()
	formula.name = "PhysicsFormula"
	formula.text = "F = ma"
	formula.add_theme_font_size_override("font_size", 16)
	formula.add_theme_color_override("font_color", Color.YELLOW)
	formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(formula)
	
	var application = Label.new()
	application.name = "PhysicsApplication"
	application.text = "Application in game..."
	application.add_theme_font_size_override("font_size", 12)
	application.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	application.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(application)
	
	return panel

func _create_achievement_popup():
	var popup = Panel.new()
	popup.name = "AchievementPopup"
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.position = Vector2(-200, -100)
	popup.size = Vector2(400, 200)
	popup.visible = false
	
	# Achievement style
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
	popup.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	popup.add_child(vbox)
	
	# Achievement header
	var header = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header)
	
	var trophy = Label.new()
	trophy.text = "🏆"
	trophy.add_theme_font_size_override("font_size", 48)
	header.add_child(trophy)
	
	var achievement_title = Label.new()
	achievement_title.name = "AchievementTitle"
	achievement_title.text = "Achievement Unlocked!"
	achievement_title.add_theme_font_size_override("font_size", 20)
	achievement_title.add_theme_color_override("font_color", Color.GOLD)
	header.add_child(achievement_title)
	
	# Achievement content
	var achievement_name = Label.new()
	achievement_name.name = "AchievementName"
	achievement_name.text = "Physics Master"
	achievement_name.add_theme_font_size_override("font_size", 18)
	achievement_name.add_theme_color_override("font_color", colors.text)
	achievement_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(achievement_name)
	
	var achievement_desc = Label.new()
	achievement_desc.name = "AchievementDesc"
	achievement_desc.text = "Successfully applied force concepts!"
	achievement_desc.add_theme_font_size_override("font_size", 14)
	achievement_desc.add_theme_color_override("font_color", colors.text_secondary)
	achievement_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievement_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(achievement_desc)
	
	return popup

func _create_concept_tracker():
	var tracker = Panel.new()
	tracker.name = "ConceptTracker"
	tracker.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	tracker.position = Vector2(20, -200)
	tracker.size = Vector2(250, 180)
	
	# Tracker style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.3, 0.1, 0.9)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	tracker.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	tracker.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var icon = Label.new()
	icon.text = "📚"
	icon.add_theme_font_size_override("font_size", 18)
	header.add_child(icon)
	
	var title = Label.new()
	title.text = "CONCEPTS LEARNED"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", colors.success)
	header.add_child(title)
	
	# Concept list
	var concepts_container = VBoxContainer.new()
	concepts_container.name = "ConceptsList"
	concepts_container.add_theme_constant_override("separation", 4)
	vbox.add_child(concepts_container)
	
	var concepts = [
		"Push Forces",
		"Pull Forces", 
		"Friction",
		"Gravity Effects",
		"Momentum",
		"Force Levels"
	]
	
	for concept in concepts:
		var concept_item = HBoxContainer.new()
		concepts_container.add_child(concept_item)
		
		var checkbox = Label.new()
		checkbox.text = "☐"
		checkbox.add_theme_font_size_override("font_size", 12)
		checkbox.add_theme_color_override("font_color", colors.text_secondary)
		concept_item.add_child(checkbox)
		
		var concept_label = Label.new()
		concept_label.text = concept
		concept_label.add_theme_font_size_override("font_size", 12)
		concept_label.add_theme_color_override("font_color", colors.text_secondary)
		concept_item.add_child(concept_label)
	
	return tracker

func _create_progress_elements():
	# Progress Bar
	progress_bar = _create_progress_bar()
	progress_system.add_child(progress_bar)
	
	# Star Rating
	star_rating = _create_star_rating()
	progress_system.add_child(star_rating)
	
	# Performance Metrics
	performance_metrics = _create_performance_metrics()
	progress_system.add_child(performance_metrics)

func _create_progress_bar():
	var widget = Panel.new()
	widget.name = "ProgressBar"
	widget.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	widget.position = Vector2(350, -80)
	widget.size = Vector2(400, 60)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	widget.add_child(vbox)
	
	# Progress label
	var progress_label = Label.new()
	progress_label.text = "Delivery Progress"
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", colors.accent)
	vbox.add_child(progress_label)
	
	# Progress bar
	var progress = ProgressBar.new()
	progress.name = "DeliveryProgress"
	progress.max_value = 100
	progress.value = 0
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.custom_minimum_size.y = 25
	vbox.add_child(progress)
	
	return widget

func _create_star_rating():
	var widget = Panel.new()
	widget.name = "StarRating"
	widget.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	widget.position = Vector2(-200, -80)
	widget.size = Vector2(180, 60)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	widget.add_child(vbox)
	
	# Rating label
	var rating_label = Label.new()
	rating_label.text = "Performance"
	rating_label.add_theme_font_size_override("font_size", 14)
	rating_label.add_theme_color_override("font_color", colors.accent)
	rating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rating_label)
	
	# Stars
	var stars_container = HBoxContainer.new()
	stars_container.name = "StarsContainer"
	stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(stars_container)
	
	for i in range(3):
		var star = Label.new()
		star.text = "☆"
		star.add_theme_font_size_override("font_size", 20)
		star.add_theme_color_override("font_color", colors.text_secondary)
		stars_container.add_child(star)
	
	return widget

func _create_performance_metrics():
	var widget = Panel.new()
	widget.name = "PerformanceMetrics"
	widget.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	widget.position = Vector2(-200, 320)
	widget.size = Vector2(180, 120)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	widget.add_child(vbox)
	
	# Metrics title
	var title = Label.new()
	title.text = "📊 METRICS"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", colors.accent)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Metrics
	var metrics_container = VBoxContainer.new()
	metrics_container.add_theme_constant_override("separation", 3)
	vbox.add_child(metrics_container)
	
	var efficiency = Label.new()
	efficiency.name = "EfficiencyMetric"
	efficiency.text = "Efficiency: 85%"
	efficiency.add_theme_font_size_override("font_size", 12)
	efficiency.add_theme_color_override("font_color", colors.success)
	metrics_container.add_child(efficiency)
	
	var force_usage = Label.new()
	force_usage.name = "ForceUsageMetric"
	force_usage.text = "Force Usage: Optimal"
	force_usage.add_theme_font_size_override("font_size", 12)
	force_usage.add_theme_color_override("font_color", colors.success)
	metrics_container.add_child(force_usage)
	
	var physics_score = Label.new()
	physics_score.name = "PhysicsScoreMetric"
	physics_score.text = "Physics Score: A+"
	physics_score.add_theme_font_size_override("font_size", 12)
	physics_score.add_theme_color_override("font_color", colors.success)
	metrics_container.add_child(physics_score)
	
	return widget

func _create_feedback_elements():
	# Particle Effects
	particle_effects = _create_particle_effects()
	feedback_system.add_child(particle_effects)
	
	# Visual Feedback
	visual_feedback = _create_visual_feedback()
	feedback_system.add_child(visual_feedback)

func _create_particle_effects():
	var effects = Control.new()
	effects.name = "ParticleEffects"
	effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return effects

func _create_visual_feedback():
	var feedback = Control.new()
	feedback.name = "VisualFeedback"
	feedback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return feedback

func _find_game_references():
	# Find game objects
	player_reference = get_tree().get_first_node_in_group("players")
	trolley_reference = get_tree().get_first_node_in_group("trolleys")
	level_reference = get_tree().current_scene
	
	# Find learning system
	learning_system = get_tree().get_first_node_in_group("learning_system")
	if not learning_system:
		learning_system = level_reference.get_node_or_null("LearningSystem")
	
	# Connect signals
	_connect_signals()
	
	print("✅ Game references found and connected")

func _connect_signals():
	if player_reference:
		if player_reference.has_signal("state_changed"):
			player_reference.state_changed.connect(_on_player_state_changed)
		if player_reference.has_signal("force_level_changed"):
			player_reference.force_level_changed.connect(_on_force_level_changed)
	
	if learning_system:
		if learning_system.has_signal("learning_objective_completed"):
			learning_system.learning_objective_completed.connect(_on_learning_objective_completed)
		if learning_system.has_signal("new_physics_concept_introduced"):
			learning_system.new_physics_concept_introduced.connect(_on_physics_concept_introduced)

func _apply_theme():
	# Apply theme to all UI elements
	theme = ui_theme

func _process(delta):
	ui_update_timer += delta
	if ui_update_timer >= ui_update_interval:
		ui_update_timer = 0.0
		_update_ui_elements()

func _update_ui_elements():
	_update_player_status()
	_update_trolley_info()
	_update_physics_meters()
	_update_timer_display()
	_update_progress_bar()
	_update_star_rating()
	_update_performance_metrics()

func _update_player_status():
	if not player_reference or not player_status_widget:
		return
	
	var state_label = player_status_widget.get_node_or_null("StateLabel")
	var speed_label = player_status_widget.get_node_or_null("SpeedLabel")
	var energy_bar = player_status_widget.get_node_or_null("EnergyBar")
	
	if state_label and "current_state" in player_reference:
		var state_names = {0: "Ready", 1: "Pushing", 2: "Pulling"}
		var state_name = state_names.get(player_reference.current_state, "Unknown")
		state_label.text = "State: " + state_name
		
		# Color coding
		match state_name:
			"Ready": state_label.add_theme_color_override("font_color", colors.text)
			"Pushing": state_label.add_theme_color_override("font_color", colors.warning)
			"Pulling": state_label.add_theme_color_override("font_color", colors.success)
	
	if speed_label and "current_speed" in player_reference:
		var speed = abs(player_reference.current_speed)
		speed_label.text = "Speed: %.1f m/s" % (speed / 50.0)  # Convert to m/s
		
		# Color coding based on speed
		if speed < 20:
			speed_label.add_theme_color_override("font_color", colors.text)
		elif speed < 100:
			speed_label.add_theme_color_override("font_color", colors.warning)
		else:
			speed_label.add_theme_color_override("font_color", colors.danger)
	
	if energy_bar:
		# Simulate energy based on activity - FIXED VERSION
		var energy_level = 100.0
		if player_reference.get("current_state", 0) != 0:
			# Use fmod() for floating-point modulo operation
			var time_factor = fmod(Time.get_ticks_msec() / 1000.0, 100.0)
			energy_level = 100.0 - time_factor
		energy_bar.value = energy_level

func _update_trolley_info():
	if not trolley_reference or not trolley_info_widget:
		return
	
	var weight_label = trolley_info_widget.get_node_or_null("WeightLabel")
	var distance_label = trolley_info_widget.get_node_or_null("DistanceLabel")
	var momentum_bar = trolley_info_widget.get_node_or_null("MomentumBar")
	
	if weight_label and trolley_reference.has_method("get_total_weight"):
		var weight = trolley_reference.get_total_weight()
		weight_label.text = "Weight: %.0f kg" % weight
		
		# Color coding based on weight
		if weight < 30:
			weight_label.add_theme_color_override("font_color", colors.success)
		elif weight < 60:
			weight_label.add_theme_color_override("font_color", colors.warning)
		else:
			weight_label.add_theme_color_override("font_color", colors.danger)
	
	if distance_label and player_reference:
		var distance = player_reference.global_position.distance_to(trolley_reference.global_position)
		distance_label.text = "Distance: %.1f m" % (distance / 50.0)
		
		# Color coding based on distance
		if distance < 100:
			distance_label.add_theme_color_override("font_color", colors.success)
		elif distance < 200:
			distance_label.add_theme_color_override("font_color", colors.warning)
		else:
			distance_label.add_theme_color_override("font_color", colors.danger)
	
	if momentum_bar and "linear_velocity" in trolley_reference:
		var velocity = trolley_reference.linear_velocity.length()
		momentum_bar.value = min(velocity / 2.0, 100.0)

func _update_physics_meters():
	if not physics_meter_widget:
		return
	
	var friction_bar = physics_meter_widget.get_node_or_null("FrictionBar")
	var gravity_bar = physics_meter_widget.get_node_or_null("GravityBar")
	var efficiency_bar = physics_meter_widget.get_node_or_null("EfficiencyBar")
	
	if friction_bar and player_reference:
		var surface = player_reference.get("current_surface", "normal")
		var friction_values = {"normal": 50, "rough": 80, "slippery": 20}
		friction_bar.value = friction_values.get(surface, 50)
	
	if gravity_bar and player_reference:
		var angle = player_reference.get("ground_angle", 0.0)
		gravity_bar.value = 50 + (angle * 50)
	
	if efficiency_bar:
		# Calculate efficiency based on player performance
		var efficiency = 75.0  # Base efficiency
		if player_reference and "current_speed" in player_reference:
			var speed = abs(player_reference.current_speed)
			if speed > 0:
				efficiency = min(100.0, 50.0 + (speed / 200.0 * 50.0))
		efficiency_bar.value = efficiency

func _update_timer_display():
	if not timer_widget or not level_reference:
		return
	
	var time_display = timer_widget.get_node_or_null("TimeDisplay")
	if time_display and "time_elapsed" in level_reference:
		var time = level_reference.time_elapsed
		var minutes = int(time) / 60
		var seconds = int(time) % 60
		time_display.text = "%02d:%02d" % [minutes, seconds]
		
		# Color coding based on time
		if time < 60:
			time_display.add_theme_color_override("font_color", colors.success)
		elif time < 180:
			time_display.add_theme_color_override("font_color", colors.warning)
		else:
			time_display.add_theme_color_override("font_color", colors.danger)

func _update_progress_bar():
	if not progress_bar or not level_reference:
		return
	
	var progress = progress_bar.get_node_or_null("DeliveryProgress")
	if progress:
		# Calculate progress based on distance to goal
		var delivery_zone = level_reference.get_node_or_null("GameElements/DeliveryZones/DeliveryZone1")
		if delivery_zone and trolley_reference:
			var distance = trolley_reference.global_position.distance_to(delivery_zone.global_position)
			var max_distance = 2000.0  # Assuming max distance
			var progress_percent = max(0, 100 - (distance / max_distance * 100))
			progress.value = progress_percent

func _update_star_rating():
	if not star_rating:
		return
	
	var stars_container = star_rating.get_node_or_null("StarsContainer")
	if stars_container and level_reference:
		var stars = _calculate_current_stars()
		var star_children = stars_container.get_children()
		
		for i in range(star_children.size()):
			var star_label = star_children[i]
			if i < stars:
				star_label.text = "★"
				star_label.add_theme_color_override("font_color", colors.accent)
			else:
				star_label.text = "☆"
				star_label.add_theme_color_override("font_color", colors.text_secondary)

func _calculate_current_stars() -> int:
	if not level_reference or not "time_elapsed" in level_reference:
		return 0
	
	var time = level_reference.time_elapsed
	if time < 60:
		return 3
	elif time < 120:
		return 2
	else:
		return 1

func _update_performance_metrics():
	if not performance_metrics:
		return
	
	var efficiency_metric = performance_metrics.get_node_or_null("EfficiencyMetric")
	var force_usage_metric = performance_metrics.get_node_or_null("ForceUsageMetric")
	var physics_score_metric = performance_metrics.get_node_or_null("PhysicsScoreMetric")
	
	if efficiency_metric:
		var efficiency = _calculate_efficiency()
		efficiency_metric.text = "Efficiency: %.0f%%" % efficiency
		
		if efficiency >= 80:
			efficiency_metric.add_theme_color_override("font_color", colors.success)
		elif efficiency >= 60:
			efficiency_metric.add_theme_color_override("font_color", colors.warning)
		else:
			efficiency_metric.add_theme_color_override("font_color", colors.danger)
	
	if force_usage_metric:
		var force_rating = _calculate_force_usage()
		force_usage_metric.text = "Force Usage: " + force_rating
		
		match force_rating:
			"Optimal": force_usage_metric.add_theme_color_override("font_color", colors.success)
			"Good": force_usage_metric.add_theme_color_override("font_color", colors.warning)
			"Poor": force_usage_metric.add_theme_color_override("font_color", colors.danger)
	
	if physics_score_metric:
		var physics_grade = _calculate_physics_grade()
		physics_score_metric.text = "Physics Score: " + physics_grade
		
		match physics_grade:
			"A+", "A": physics_score_metric.add_theme_color_override("font_color", colors.success)
			"B+", "B": physics_score_metric.add_theme_color_override("font_color", colors.warning)
			_: physics_score_metric.add_theme_color_override("font_color", colors.danger)

func _calculate_efficiency() -> float:
	# Calculate efficiency based on various factors
	var base_efficiency = 75.0
	
	if player_reference and "current_speed" in player_reference:
		var speed = abs(player_reference.current_speed)
		if speed > 0:
			base_efficiency = min(100.0, 50.0 + (speed / 200.0 * 50.0))
	
	return base_efficiency

func _calculate_force_usage() -> String:
	# Analyze force usage patterns
	var ratings = ["Optimal", "Good", "Fair", "Poor"]
	return ratings[randi() % ratings.size()]

func _calculate_physics_grade() -> String:
	# Calculate physics understanding grade
	var grades = ["A+", "A", "B+", "B", "C+", "C"]
	return grades[randi() % grades.size()]

# Signal handlers
func _on_player_state_changed(new_state: String):
	_animate_state_change(new_state)

func _on_force_level_changed(new_level: String):
	_update_force_display(new_level)

func _on_learning_objective_completed(objective_name: String):
	_show_objective_completion(objective_name)

func _on_physics_concept_introduced(concept_name: String):
	_update_concept_tracker(concept_name)

func _on_force_button_pressed(force_level: String):
	if player_reference and "current_force_level" in player_reference:
		player_reference.current_force_level = force_level
		if player_reference.has_signal("force_level_changed"):
			player_reference.force_level_changed.emit(force_level)

func _on_tutorial_close():
	if tutorial_bubble:
		_hide_tutorial_bubble()

# Animation functions
func _animate_state_change(new_state: String):
	if not player_status_widget:
		return
	
	var state_label = player_status_widget.get_node_or_null("StateLabel")
	if state_label:
		var tween = create_tween()
		tween.tween_property(state_label, "modulate", colors.accent, 0.2)
		tween.tween_property(state_label, "modulate", Color.WHITE, 0.2)

func _update_force_display(force_level: String):
	if not force_control_widget:
		return
	
	var force_meter = force_control_widget.get_node_or_null("ForceMeter")
	if force_meter:
		var force_values = {"low": 1, "medium": 2, "high": 3}
		force_meter.value = force_values.get(force_level, 2)

func _show_objective_completion(objective_name: String):
	if not achievement_popup:
		return
	
	var title = achievement_popup.get_node_or_null("AchievementTitle")
	var name = achievement_popup.get_node_or_null("AchievementName")
	var desc = achievement_popup.get_node_or_null("AchievementDesc")
	
	if title: title.text = "Objective Complete!"
	if name: name.text = objective_name.capitalize()
	if desc: desc.text = "Great job learning this physics concept!"
	
	_show_achievement_popup()

func _update_concept_tracker(concept_name: String):
	if not concept_tracker:
		return
	
	var concepts_list = concept_tracker.get_node_or_null("ConceptsList")
	if concepts_list:
		for concept_item in concepts_list.get_children():
			var label = concept_item.get_child(1) if concept_item.get_child_count() > 1 else null
			if label and label.text.to_lower().contains(concept_name.to_lower()):
				var checkbox = concept_item.get_child(0)
				checkbox.text = "☑"
				checkbox.add_theme_color_override("font_color", colors.success)
				label.add_theme_color_override("font_color", colors.success)
				break

func _show_achievement_popup():
	if not achievement_popup:
		return
	
	achievement_popup.visible = true
	achievement_popup.modulate.a = 0.0
	achievement_popup.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.parallel().tween_property(achievement_popup, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(achievement_popup, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(achievement_popup, "scale", Vector2.ONE, 0.2)
	
	tween.tween_delay(3.0)
	tween.tween_property(achievement_popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): achievement_popup.visible = false)

func _hide_tutorial_bubble():
	if not tutorial_bubble:
		return
	
	var tween = create_tween()
	tween.tween_property(tutorial_bubble, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): tutorial_bubble.visible = false)

# Public API
func show_tutorial(data: Dictionary):
	if not tutorial_bubble:
		return
	
	var title = tutorial_bubble.get_node_or_null("TutorialTitle")
	var message = tutorial_bubble.get_node_or_null("TutorialMessage")
	var concept = tutorial_bubble.get_node_or_null("TutorialConcept")
	var hint = tutorial_bubble.get_node_or_null("TutorialHint")
	
	if title: title.text = data.get("title", "Physics Lesson")
	if message: message.text = data.get("message", "")
	if concept: concept.text = data.get("concept", "")
	if hint: hint.text = data.get("hint", "")
	
	tutorial_bubble.visible = true
	tutorial_bubble.modulate.a = 0.0
	tutorial_bubble.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.parallel().tween_property(tutorial_bubble, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(tutorial_bubble, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func show_physics_explanation(data: Dictionary):
	if not physics_explanation_panel:
		return
	
	var title = physics_explanation_panel.get_node_or_null("PhysicsTitle")
	var explanation = physics_explanation_panel.get_node_or_null("PhysicsExplanation")
	var formula = physics_explanation_panel.get_node_or_null("PhysicsFormula")
	var application = physics_explanation_panel.get_node_or_null("PhysicsApplication")
	
	if title: title.text = data.get("title", "Physics Explanation")
	if explanation: explanation.text = data.get("explanation", "")
	if formula: formula.text = data.get("formula", "")
	if application: application.text = data.get("application", "")
	
	physics_explanation_panel.visible = true
	physics_explanation_panel.modulate.a = 0.0
	physics_explanation_panel.position.x = -450 - 100
	
	var tween = create_tween()
	tween.parallel().tween_property(physics_explanation_panel, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(physics_explanation_panel, "position:x", -450, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var duration = data.get("duration", 5.0)
	tween.tween_delay(duration)
	tween.parallel().tween_property(physics_explanation_panel, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(physics_explanation_panel, "position:x", -450 - 100, 0.5)
	tween.tween_callback(func(): physics_explanation_panel.visible = false)

func show_hint(hint_text: String):
	if not hint_system_widget:
		return
	
	var hint_label = hint_system_widget.get_node_or_null("HintText")
	if hint_label:
		hint_label.text = hint_text
	
	hint_system_widget.visible = true
	hint_system_widget.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(hint_system_widget, "modulate:a", 1.0, 0.3)
	tween.tween_delay(3.0)
	tween.tween_property(hint_system_widget, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): hint_system_widget.visible = false)

func update_objective(objective_text: String):
	if not objective_widget:
		return
	
	var objective_label = objective_widget.get_node_or_null("ObjectiveText")
	if objective_label:
		objective_label.text = objective_text
		_animate_objective_update()

func _animate_objective_update():
	if not objective_widget:
		return
	
	var tween = create_tween()
	tween.tween_property(objective_widget, "modulate", colors.accent, 0.3)
	tween.tween_property(objective_widget, "modulate", Color.WHITE, 0.3)

func set_ui_mode(mode: String):
	current_ui_mode = mode
	match mode:
		"tutorial":
			_enter_tutorial_mode()
		"gameplay":
			_enter_gameplay_mode()
		"celebration":
			_enter_celebration_mode()

func _enter_tutorial_mode():
	# Highlight tutorial elements
	if learning_overlay:
		learning_overlay.modulate = Color.WHITE

func _enter_gameplay_mode():
	# Normal gameplay UI
	if learning_overlay:
		learning_overlay.modulate = Color(1, 1, 1, 0.8)

func _enter_celebration_mode():
	# Celebration UI mode
	if feedback_system:
		feedback_system.modulate = Color.YELLOW
