extends Node
# Temporary autoload loader for testing

func _ready():
	print("=== Setting up temporary autoloads ===")
	
	# Load and add autoload scripts manually
	var autoloads = [
		{"name": "GameConstants", "script": "res://scripts/autoload/GameConstants.gd"},
		{"name": "GameManager", "script": "res://scripts/autoload/GameManager.gd"},
		{"name": "InputManager", "script": "res://scripts/autoload/InputManager.gd"}
	]
	
	for autoload in autoloads:
		if not has_node("/root/" + autoload.name):
			var node = Node.new()
			node.name = autoload.name
			node.set_script(load(autoload.script))
			get_node("/root").add_child(node)
			print("✓ Added temporary autoload: ", autoload.name)
		else:
			print("✓ Autoload already exists: ", autoload.name)
	
	print("\n✓ Temporary autoloads ready!")
	print("Starting game in 1 second...")
	
	await get_tree().create_timer(1.0).timeout
	
	# Load the starting cutscene
	get_tree().change_scene_to_file("res://scene/cutscenes/StartingCutscene.tscn")
