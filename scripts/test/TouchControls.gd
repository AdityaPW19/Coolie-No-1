extends Control

# Handle touch button connections for testing

@onready var push_button: Button = $PushButton
@onready var pull_button: Button = $PullButton

func _ready():
	# Connect buttons to InputManager if available
	if has_node("/root/InputManager"):
		var input_manager = get_node("/root/InputManager")
		
		# Set button areas for InputManager
		push_button.draw.connect(_on_push_button_draw)
		pull_button.draw.connect(_on_pull_button_draw)
		
		# Connect button press/release to input actions
		push_button.button_down.connect(func(): 
			if has_node("/root/InputManager"):
				get_node("/root/InputManager")._start_push()
		)
		push_button.button_up.connect(func(): 
			if has_node("/root/InputManager"):
				get_node("/root/InputManager")._end_push()
		)
		
		pull_button.button_down.connect(func(): 
			if has_node("/root/InputManager"):
				get_node("/root/InputManager")._start_pull()
		)
		pull_button.button_up.connect(func(): 
			if has_node("/root/InputManager"):
				get_node("/root/InputManager")._end_pull()
		)

func _on_push_button_draw():
	if has_node("/root/InputManager") and push_button:
		var rect = Rect2(push_button.global_position, push_button.size)
		get_node("/root/InputManager").set_push_button_area(rect)

func _on_pull_button_draw():
	if has_node("/root/InputManager") and pull_button:
		var rect = Rect2(pull_button.global_position, pull_button.size)
		get_node("/root/InputManager").set_pull_button_area(rect)
