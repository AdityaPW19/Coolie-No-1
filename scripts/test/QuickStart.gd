extends Node

func _ready():
	print("Quick Start - Loading Level1_Proto directly")
	get_tree().change_scene_to_file("res://levels/Level1_Proto.tscn")
	await get_tree().tree_changed
	
	if has_node("/root/GameManager"):
		print("Starting game through GameManager")
		get_node("/root/GameManager").start_game()
	else:
		print("GameManager not found! Make sure autoloads are registered.")
