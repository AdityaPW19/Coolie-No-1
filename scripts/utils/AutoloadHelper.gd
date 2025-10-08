extends Node
# Temporary autoload checker and error handler

static func check_autoload(name: String) -> bool:
	return Engine.has_singleton(name) or has_node("/root/" + name)

static func get_autoload_safe(name: String) -> Node:
	if Engine.has_singleton(name):
		return Engine.get_singleton(name)
	elif has_node("/root/" + name):
		return get_node("/root/" + name)
	else:
		push_warning("Autoload not found: " + name)
		return null

static func safe_connect(source_node: Node, signal_name: String, target: Callable) -> void:
	if source_node and source_node.has_signal(signal_name):
		if not source_node.is_connected(signal_name, target):
			source_node.connect(signal_name, target)

static func has_autoloads() -> bool:
	var required = ["GameConstants", "GameManager", "InputManager"]
	for autoload in required:
		if not check_autoload(autoload):
			return false
	return true
