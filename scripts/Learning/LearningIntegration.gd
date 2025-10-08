# SimpleIntegration.gd - Simple integration that actually works
extends Node

# Just create the learning system - that's it!
var learning_system = null

func _ready():
	print("🚀 Simple Integration Starting...")
	
	# Create the learning system
	var learning_script = preload("res://scripts/Learning/LearningSystem.gd")
	learning_system = learning_script.new()
	learning_system.name = "CompleteLearningSystem"
	
	# Add to scene
	get_tree().current_scene.add_child(learning_system)
	
	print("✅ Learning system added to scene!")
	print("📝 Controls:")
	print("  - A/D: Push/Pull trolley (triggers learning)")
	print("  - 1/2/3: Change force levels")
	print("  - F1-F5: Debug/Test functions")

# That's it! The learning system handles everything else automatically.
