extends Node
# Quick integration test script

func _ready():
	print("\n=== TROLLEY INTEGRATION TEST ===")
	
	# Check if all systems are loaded
	var systems_ok = true
	
	# Check GameManager
	if has_node("/root/GameManager"):
		print("✓ GameManager loaded")
	else:
		print("✗ GameManager missing!")
		systems_ok = false
	
	# Check GameConstants
	if has_node("/root/GameConstants"):
		print("✓ GameConstants loaded")
	else:
		print("✗ GameConstants missing!")
		systems_ok = false
	
	# Check InputManager
	if has_node("/root/InputManager"):
		print("✓ InputManager loaded")
	else:
		print("✗ InputManager missing!")
		systems_ok = false
	
	# Check Level1_Proto scene elements
	if get_tree().current_scene.name == "Level1":
		print("✓ Level1_Proto scene loaded")
		
		# Check for required nodes
		var level = get_tree().current_scene
		
		if level.has_node("GameElements/Player"):
			print("✓ Player found")
		else:
			print("✗ Player missing!")
			systems_ok = false
		
		if level.has_node("GameElements/DeliveryZones"):
			print("✓ DeliveryZones container found")
		else:
			print("✗ DeliveryZones missing!")
			systems_ok = false
		
		if level.has_node("UI/GameUI"):
			print("✓ GameUI found")
		else:
			print("✗ GameUI missing!")
			systems_ok = false
		
		if level.has_node("UI/PauseMenu"):
			print("✓ PauseMenu found")
		else:
			print("✗ PauseMenu missing!")
			systems_ok = false
	
	print("\n=== INTEGRATION STATUS ===")
	if systems_ok:
		print("✓ All systems ready!")
		print("\nStarting test delivery in 2 seconds...")
		await get_tree().create_timer(2.0).timeout
		
		# Start a test delivery
		if has_node("/root/GameManager"):
			var gm = get_node("/root/GameManager")
			gm.start_level(1)
	else:
		print("✗ Some systems are missing. Please check autoloads.")
	
	print("=========================\n")
