# LearningSystem.gd - Clean Event-Based Physics Learning System
extends Control

# === PHYSICS LEARNING SIGNALS ===
signal physics_concept_learned(concept_name: String)
signal learning_milestone_reached(milestone: String)
signal tutorial_completed(tutorial_name: String)
signal physics_demonstration_shown(demo_type: String)

# === UI ELEMENT REFERENCES ===
# Main UI elements - now referenced instead of created
@onready var learning_popup = $LearningPopup
@onready var physics_demo_panel = $PhysicsDemo
@onready var concept_tracker = $ConceptTracker
@onready var achievement_notification = $AchievementNotification
@onready var tutorial_overlay = $TutorialOverlay
@onready var hint_system = $HintSystem
@onready var celebration_effects = $CelebrationEffects

# UI sub-element references for easy access
@onready var popup_title = $LearningPopup/ContentContainer/HeaderSection/Title
@onready var popup_explanation = $LearningPopup/ContentContainer/ExplanationSection/Explanation
@onready var popup_real_world = $LearningPopup/ContentContainer/RealWorldSection/RealWorld
@onready var popup_objective = $LearningPopup/ContentContainer/ObjectiveSection/Objective
@onready var popup_demo_btn = $LearningPopup/ContentContainer/ButtonSection/DemoButton
@onready var popup_close_btn = $LearningPopup/ContentContainer/ButtonSection/CloseButton

@onready var demo_title = $PhysicsDemo/DemoContainer/HeaderSection/DemoTitle
@onready var demo_content = $PhysicsDemo/DemoContainer/ContentSection/DemoContent
@onready var demo_close_btn = $PhysicsDemo/DemoContainer/ButtonSection/CloseDemo

@onready var tracker_title = $ConceptTracker/TrackerContainer/HeaderSection/TrackerTitle
@onready var tracker_progress = $ConceptTracker/TrackerContainer/ProgressSection/ProgressText

@onready var achievement_icon = $AchievementNotification/AchievementContainer/IconSection/AchievementIcon
@onready var achievement_text = $AchievementNotification/AchievementContainer/TextSection/AchievementText

@onready var hint_title = $HintSystem/HintPanel/HintContainer/HintTitle
@onready var hint_text = $HintSystem/HintPanel/HintContainer/HintText

@onready var celebration_text = $CelebrationEffects/CelebrationText

# === GAME REFERENCES ===
var player = null
var trolley = null
var level_manager = null

# === LEARNING STATE ===
var learning_progress = {
	"concepts_learned": [],
	"demonstrations_seen": [],
	"current_focus": "",
	"learning_streak": 0,
	"total_achievements": 0
}

# === PLAYER ACTIONS TRACKING ===
var player_actions = {
	"push_count": 0,
	"pull_count": 0,
	"force_changes": 0,
	"surface_changes": 0,
	"total_actions": 0
}

# === LEARNING FLOW STATE ===
var learning_flow = {
	"welcome_shown": false,
	"first_push_shown": false,
	"push_mastery_shown": false,
	"first_pull_shown": false,
	"pull_mastery_shown": false,
	"force_control_shown": false,
	"physics_mastery_shown": false
}

# === ROBUST TIMING CONTROL ===
var ui_state = {
	"popup_active": false,
	"demo_active": false,
	"achievement_active": false,
	"last_interaction_time": 0.0,
	"min_interaction_delay": 2.0,
	"scenario_queue": [],
	"processing_scenario": false
}

# === PHYSICS CONCEPTS DATABASE ===
var physics_concepts = {
	"welcome": {
		"title": "🚂 Welcome to Physics Lab!",
		"explanation": "You're about to learn real physics! Every action you take demonstrates scientific principles that govern our world.",
		"real_world": "From pushing shopping carts to pulling doors - physics is everywhere around us!",
		"demonstration": "Let's start with your first physics experiment!"
	},
	"push_force": {
		"title": "🚀 Push Force Physics",
		"explanation": "When you PUSH something, you apply force AWAY from yourself. The object accelerates in the direction of your push!",
		"real_world": "Like pushing a shopping cart, opening a heavy door, or moving furniture - you're applying force to move things away from you.",
		"demonstration": "Watch how the trolley moves away when you push it! The stronger you push, the faster it accelerates!"
	},
	"pull_force": {
		"title": "🪢 Pull Force Physics", 
		"explanation": "When you PULL something, you apply force TOWARD yourself. The object moves in your direction - same physics, opposite direction!",
		"real_world": "Like pulling a rope, opening a drawer, or dragging a heavy box - you're bringing things closer to you.",
		"demonstration": "Notice how the trolley comes toward you when you pull it! You're applying the same force principles!"
	},
	"friction": {
		"title": "🌪️ Friction Forces",
		"explanation": "Friction is the force that opposes motion between surfaces. Different surfaces create different amounts of friction!",
		"real_world": "Walking on ice (low friction) vs. walking on rough pavement (high friction). Your shoes grip differently on each surface!",
		"demonstration": "See how the trolley moves differently on smooth vs. rough surfaces! Feel the difference in resistance!"
	},
	"force_control": {
		"title": "⚡ Force Control Mastery",
		"explanation": "You can control how much force you apply! Different force levels create different accelerations and speeds.",
		"real_world": "Like a car accelerator - light pressure for gentle movement, more pressure for faster acceleration!",
		"demonstration": "Try different force levels and feel how the trolley responds differently to each!"
	},
	"gravity": {
		"title": "🌍 Gravity & Motion",
		"explanation": "Gravity constantly pulls objects downward! On slopes, gravity helps objects roll downhill but resists uphill motion.",
		"real_world": "Rolling a ball down a hill is easy, but pushing it uphill requires more force to overcome gravity!",
		"demonstration": "Notice how gravity affects the trolley's movement on different surfaces!"
	},
	"physics_mastery": {
		"title": "🏆 Physics Master!",
		"explanation": "Congratulations! You've mastered the fundamental forces: push, pull, friction, gravity, and force control!",
		"real_world": "You now understand the same physics principles that engineers use to design cars, planes, and rockets!",
		"demonstration": "You're ready to apply these physics principles to solve real-world problems!"
	}
}

# === LEARNING SCENARIOS ===
var learning_scenarios = [
	{
		"id": "welcome",
		"concept": "welcome",
		"title": "🚂 Welcome to Physics Lab!",
		"message": "You're about to become a physics expert! Every action teaches you real science.",
		"objective": "Press A to PUSH the trolley and start your physics journey!"
	},
	{
		"id": "first_push",
		"concept": "push_force",
		"title": "🚀 Amazing! You Applied Push Force!",
		"message": "You just demonstrated Newton's Second Law! The trolley accelerated because you applied force to it.",
		"objective": "Try pushing a few more times to master this concept!"
	},
	{
		"id": "push_mastery",
		"concept": "push_force",
		"title": "🎯 Push Force Mastered!",
		"message": "Excellent! You understand push forces. Now let's learn the opposite - PULL forces!",
		"objective": "Press D to PULL the trolley toward you!"
	},
	{
		"id": "first_pull",
		"concept": "pull_force",
		"title": "🪢 Fantastic! You Applied Pull Force!",
		"message": "Perfect! Pull forces work just like push forces, but in the opposite direction. Same physics, different direction!",
		"objective": "Try pulling a few more times to master this concept!"
	},
	{
		"id": "pull_mastery",
		"concept": "pull_force",
		"title": "🏆 Pull Force Mastered!",
		"message": "Incredible! You now understand both push AND pull forces. Let's learn about force control!",
		"objective": "Press 1, 2, or 3 to change your force strength!"
	},
	{
		"id": "force_control",
		"concept": "force_control",
		"title": "⚡ Force Control Expert!",
		"message": "Amazing! You've learned to control force levels. This is advanced physics in action!",
		"objective": "Try moving on different surfaces to learn about friction!"
	},
	{
		"id": "friction_intro",
		"concept": "friction",
		"title": "🌪️ Friction Discovery!",
		"message": "You're experiencing friction! Different surfaces resist motion in different ways.",
		"objective": "Complete your delivery to become a physics master!"
	},
	{
		"id": "physics_mastery",
		"concept": "physics_mastery",
		"title": "🏆 Physics Master Achieved!",
		"message": "Congratulations! You've mastered push forces, pull forces, friction, and force control. You're now a physics expert!",
		"objective": "Use your physics knowledge to tackle more challenges!"
	}
]

# === INITIALIZATION ===
func _ready():
	print("🔬 Clean Physics Learning System Starting...")
	print("📋 Using pre-created UI elements")
	_initialize_system()

func _initialize_system():
	_connect_ui_signals()
	_find_game_objects()
	_connect_learning_signals()
	_start_learning_journey()

func _connect_ui_signals():
	"""Connect UI button signals"""
	if popup_demo_btn:
		popup_demo_btn.pressed.connect(_show_physics_demo)
	if popup_close_btn:
		popup_close_btn.pressed.connect(_close_learning_popup)
	if demo_close_btn:
		demo_close_btn.pressed.connect(_close_physics_demo)
	print("✅ UI signals connected")

func _find_game_objects():
	"""Find game objects with retry mechanism"""
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		player = players[0]
		print("📚 Connected to player: ", player.name)
	else:
		print("❌ Player not found! Retrying...")
		await get_tree().create_timer(1.0).timeout
		_find_game_objects()
		return
	
	var trolleys = get_tree().get_nodes_in_group("trolleys")
	if trolleys.size() > 0:
		trolley = trolleys[0]
		print("📚 Connected to trolley: ", trolley.name)
	
	level_manager = get_tree().current_scene

func _connect_learning_signals():
	"""Connect to player signals with error handling"""
	if not player:
		print("❌ Cannot connect signals - no player")
		return
	
	if player.has_signal("state_changed"):
		if not player.state_changed.is_connected(_on_player_physics_action):
			player.state_changed.connect(_on_player_physics_action)
			print("✅ Connected to player state_changed")
	
	if player.has_signal("force_level_changed"):
		if not player.force_level_changed.is_connected(_on_force_experimentation):
			player.force_level_changed.connect(_on_force_experimentation)
			print("✅ Connected to player force_level_changed")
	
	if player.has_signal("surface_changed"):
		if not player.surface_changed.is_connected(_on_surface_experience):
			player.surface_changed.connect(_on_surface_experience)
			print("✅ Connected to player surface_changed")

func _start_learning_journey():
	"""Start the learning journey with proper timing"""
	print("🎓 Starting physics learning journey...")
	await get_tree().create_timer(2.0).timeout
	_trigger_learning_scenario("welcome")

# === ROBUST SCENARIO MANAGEMENT ===
func _trigger_learning_scenario(scenario_id: String):
	"""Trigger learning scenario with proper timing control"""
	print("🎓 Trigger request: ", scenario_id)
	
	# Check if already shown
	if learning_flow.get(scenario_id + "_shown", false):
		print("⚠️ Scenario already shown: ", scenario_id)
		return
	
	# Check timing constraints
	var current_time = Time.get_time_dict_from_system()
	var time_seconds = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
	
	if time_seconds - ui_state.last_interaction_time < ui_state.min_interaction_delay:
		print("⚠️ Too soon, queueing scenario: ", scenario_id)
		ui_state.scenario_queue.append(scenario_id)
		return
	
	# Check if UI is busy
	if ui_state.popup_active or ui_state.processing_scenario:
		print("⚠️ UI busy, queueing scenario: ", scenario_id)
		ui_state.scenario_queue.append(scenario_id)
		return
	
	# Find scenario
	var scenario = null
	for s in learning_scenarios:
		if s.id == scenario_id:
			scenario = s
			break
	
	if not scenario:
		print("❌ Scenario not found: ", scenario_id)
		return
	
	# Show scenario
	print("✅ Showing scenario: ", scenario_id)
	ui_state.processing_scenario = true
	ui_state.last_interaction_time = time_seconds
	learning_flow[scenario_id + "_shown"] = true
	_show_learning_content(scenario)

func _show_learning_content(scenario: Dictionary):
	"""Show learning content with safe UI updates"""
	if not learning_popup:
		print("❌ Learning popup not found!")
		ui_state.processing_scenario = false
		return
	
	ui_state.popup_active = true
	learning_progress.current_focus = scenario.concept
	
	# Update popup content safely
	if popup_title:
		popup_title.text = scenario.title
	if popup_explanation:
		popup_explanation.text = scenario.message
	if popup_objective:
		popup_objective.text = "🎯 " + scenario.objective
	
	# Add concept details
	if scenario.concept in physics_concepts:
		var concept = physics_concepts[scenario.concept]
		if popup_real_world:
			popup_real_world.text = "🌍 Real World: " + concept.real_world
	
	# Show popup with animation
	learning_popup.visible = true
	learning_popup.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(learning_popup, "modulate:a", 1.0, 0.5)
	tween.tween_callback(func(): ui_state.processing_scenario = false)
	
	_update_concept_tracker()
	print("✅ Learning content shown: ", scenario.title)

func _show_physics_demo():
	"""Show physics demo with proper state management"""
	if ui_state.demo_active or not learning_progress.current_focus:
		return
	
	var concept = physics_concepts.get(learning_progress.current_focus, {})
	if concept.is_empty():
		return
	
	ui_state.demo_active = true
	
	# Update demo content
	if demo_title:
		demo_title.text = "🔬 " + concept.get("title", "Physics Demo")
	if demo_content:
		demo_content.text = concept.get("demonstration", "Physics in action!")
	
	# Show demo
	physics_demo_panel.visible = true
	physics_demo_panel.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(physics_demo_panel, "modulate:a", 1.0, 0.3)
	
	# Track demo as seen
	if learning_progress.current_focus not in learning_progress.demonstrations_seen:
		learning_progress.demonstrations_seen.append(learning_progress.current_focus)
		physics_demonstration_shown.emit(learning_progress.current_focus)
		_update_concept_tracker()
	
	print("✅ Physics demo shown")

func _close_learning_popup():
	"""Close learning popup with proper state management"""
	if not learning_popup or not ui_state.popup_active:
		return
	
	print("🔄 Closing learning popup...")
	
	# Animate out
	var tween = create_tween()
	tween.tween_property(learning_popup, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): 
		learning_popup.visible = false
		ui_state.popup_active = false
		_handle_popup_closed()
	)

func _handle_popup_closed():
	"""Handle popup closed with concept learning and queue processing"""
	# Mark concept as learned
	if learning_progress.current_focus and learning_progress.current_focus not in learning_progress.concepts_learned:
		learning_progress.concepts_learned.append(learning_progress.current_focus)
		learning_progress.total_achievements += 1
		physics_concept_learned.emit(learning_progress.current_focus)
		
		# Show achievement with proper timing
		var achievement_text = "Physics Concept Mastered: " + learning_progress.current_focus.replace("_", " ").capitalize()
		_show_achievement_safe(achievement_text)
	
	_update_concept_tracker()
	
	# Process queue after delay
	if ui_state.scenario_queue.size() > 0:
		await get_tree().create_timer(1.0).timeout
		var next_scenario = ui_state.scenario_queue.pop_front()
		_trigger_learning_scenario(next_scenario)

func _close_physics_demo():
	"""Close physics demo with proper state management"""
	if not physics_demo_panel or not ui_state.demo_active:
		return
	
	var tween = create_tween()
	tween.tween_property(physics_demo_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): 
		physics_demo_panel.visible = false
		ui_state.demo_active = false
	)

func _show_achievement_safe(achievement_text_content: String):
	"""Show achievement with proper timing and state management"""
	if not achievement_notification or ui_state.achievement_active:
		return
	
	ui_state.achievement_active = true
	
	# Update achievement text
	if achievement_text:
		achievement_text.text = "🏆 " + achievement_text_content
	
	# Show achievement
	achievement_notification.visible = true
	achievement_notification.modulate.a = 0.0
	achievement_notification.position.y = 10
	
	# Create separate tweens for better control
	var fade_in_tween = create_tween()
	fade_in_tween.parallel().tween_property(achievement_notification, "modulate:a", 1.0, 0.5)
	fade_in_tween.parallel().tween_property(achievement_notification, "position:y", 50, 0.5)
	
	# Wait for fade in to complete, then wait additional time, then fade out
	await fade_in_tween.finished
	await get_tree().create_timer(1.0).timeout  # Stay visible for 1 seconds
	
	# Fade out
	var fade_out_tween = create_tween()
	fade_out_tween.parallel().tween_property(achievement_notification, "modulate:a", 0.0, 0.5)
	fade_out_tween.parallel().tween_property(achievement_notification, "position:y", 10, 0.5)
	
	# Wait for fade out to complete, then cleanup
	await fade_out_tween.finished
	achievement_notification.visible = false
	ui_state.achievement_active = false
	
	print("✅ Achievement shown for 4+ seconds: ", achievement_text_content)

func _update_concept_tracker():
	"""Update concept tracker with current progress"""
	if not tracker_progress:
		return
	
	var concepts_count = learning_progress.concepts_learned.size()
	var demos_count = learning_progress.demonstrations_seen.size()
	var current_focus = learning_progress.current_focus.replace("_", " ").capitalize()
	
	tracker_progress.text = "🎯 Current: %s\n⚡ Concepts: %d/7\n🔬 Demos seen: %d\n🏆 Achievements: %d\n📊 Actions: %d" % [
		current_focus,
		concepts_count,
		demos_count,
		learning_progress.total_achievements,
		player_actions.total_actions
	]

# === EVENT HANDLERS ===
func _on_player_physics_action(action: String):
	"""Handle player physics actions with proper flow"""
	print("🎮 Player action: ", action)
	player_actions.total_actions += 1
	
	match action:
		"pushing":
			player_actions.push_count += 1
			if player_actions.push_count == 1:
				_trigger_learning_scenario("first_push")
			elif player_actions.push_count >= 3:
				_trigger_learning_scenario("push_mastery")
		
		"pulling":
			player_actions.pull_count += 1
			if player_actions.pull_count == 1:
				_trigger_learning_scenario("first_pull")
			elif player_actions.pull_count >= 3:
				_trigger_learning_scenario("pull_mastery")
	
	_update_concept_tracker()

func _on_force_experimentation(force_level: String):
	"""Handle force level changes"""
	print("⚡ Force changed: ", force_level)
	player_actions.force_changes += 1
	player_actions.total_actions += 1
	
	if player_actions.force_changes >= 3:
		_trigger_learning_scenario("force_control")
	
	_update_concept_tracker()

func _on_surface_experience(surface_type: String):
	"""Handle surface changes"""
	print("🌍 Surface changed: ", surface_type)
	player_actions.surface_changes += 1
	player_actions.total_actions += 1
	
	if player_actions.surface_changes >= 2:
		_trigger_learning_scenario("friction_intro")
	
	_update_concept_tracker()

# === PUBLIC API ===
func get_learning_progress() -> Dictionary:
	return learning_progress.duplicate()

func is_concept_learned(concept_name: String) -> bool:
	return concept_name in learning_progress.concepts_learned

func force_trigger_scenario(scenario_id: String):
	"""Force trigger a scenario for testing"""
	learning_flow[scenario_id + "_shown"] = false
	_trigger_learning_scenario(scenario_id)

func reset_learning_system():
	"""Reset the entire learning system"""
	learning_progress.concepts_learned.clear()
	learning_progress.demonstrations_seen.clear()
	learning_progress.current_focus = ""
	learning_progress.total_achievements = 0
	
	player_actions = {"push_count": 0, "pull_count": 0, "force_changes": 0, "surface_changes": 0, "total_actions": 0}
	
	for key in learning_flow:
		learning_flow[key] = false
	
	ui_state.scenario_queue.clear()
	ui_state.popup_active = false
	ui_state.demo_active = false
	ui_state.achievement_active = false
	ui_state.processing_scenario = false
	
	# Hide all UI elements
	if learning_popup:
		learning_popup.visible = false
	if physics_demo_panel:
		physics_demo_panel.visible = false
	if achievement_notification:
		achievement_notification.visible = false
	
	_update_concept_tracker()
	print("🔄 Learning system reset")

# === DEBUG CONTROLS ===
func _input(event):
	if not OS.is_debug_build():
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F7:
				force_trigger_scenario("welcome")
			KEY_F8:
				force_trigger_scenario("first_push")
			KEY_F9:
				force_trigger_scenario("first_pull")
			KEY_F10:
				_show_achievement_safe("Debug Achievement Test!")
			KEY_F11:
				print("🎓 Learning State:")
				print("  - Concepts: ", learning_progress.concepts_learned)
				print("  - Demos: ", learning_progress.demonstrations_seen)
				print("  - Actions: ", player_actions)
				print("  - Flow: ", learning_flow)
				print("  - UI State: ", ui_state)
			KEY_F12:
				reset_learning_system()

func _notification(what):
	if what == NOTIFICATION_READY:
		print("📚 Clean Physics Learning System Ready!")
		print("📚 All UI elements pre-created - no code generation!")
		print("📚 Features: Robust timing, crash prevention, proper coordination")
		print("📚 Debug: F7-F12 for testing")
