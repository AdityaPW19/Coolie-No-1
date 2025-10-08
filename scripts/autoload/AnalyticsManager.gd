# AnalyticsManager.gd
# Add this as an Autoload/Singleton in Project Settings -> Autoload
extends Node

# Session configuration (set these from your React Native app or game initialization)
var user_id: String = ""
var game_id: String = ""
var player_name: String = ""

# Session tracking
var session_start_time: float = 0.0
var total_xp_earned: int = 0

# Raw data storage
var raw_data: Array = []

# Level tracking
var levels_data: Array = []
var current_level_data: Dictionary = {}
var current_level_start_time: float = 0.0

# Task tracking within a level
var current_tasks: Array = []

var crash_detected: bool = false
var last_executed_line: String = ""

func _ready():
	session_start_time = Time.get_unix_time_from_system()
	_initialize_raw_data()

func _initialize_raw_data():
	"""Initialize common raw data fields"""
	raw_data = [
		{"key": "device", "value": OS.get_name()},
		{"key": "sessionLength", "value": "0"}
	]
	
func track_executed_line(line_info: String):
	"""Call this from key lines in game code to store last executed step before potential crash"""
	last_executed_line = line_info
	
	
func report_crash():
	"""Call this on crash or exception detection to send crash data"""
	crash_detected = true
	
	var crash_payload = {
		"userId": user_id,
		"gameId": game_id,
		"name": player_name,
		"xpEarned": total_xp_earned,
		"rawData": raw_data.duplicate(),
		"diagnostics": {
			"levels": levels_data.duplicate()
		},
		"crashReport": {
			"timestamp": Time.get_unix_time_from_system(),
			"lastExecutedLine": last_executed_line
		}
	}
	
	_send_to_react_native(crash_payload)
	print("Analytics: Crash report sent")


func on_uncaught_exception(message: String):
	# Custom signal handler you can call on catching errors
	report_crash()
# ============================================
# PUBLIC API - Call these from your game
# ============================================

func set_user_info(p_user_id: String, p_game_id: String, p_name: String):
	"""Set user and game identification - call this at game start"""
	user_id = p_user_id
	game_id = p_game_id
	player_name = p_name
	print("Analytics: User set - ", p_name)

func add_raw_data(key: String, value: String):
	"""Add custom raw data field"""
	raw_data.append({"key": key, "value": value})

func start_level(level_id: String, time_direction: bool = true):
	"""Start tracking a new level
	Args:
		level_id: Level identifier (e.g., "L1", "L2")
		time_direction: true if faster time is better, false if longer is better
	"""
	current_level_start_time = Time.get_ticks_msec() / 1000.0
	current_tasks = []
	
	current_level_data = {
		"levelId": level_id,
		"successful": false,
		"timeTaken": 0,
		"timeDirection": time_direction,
		"xpEarned": 0,
		"tasks": []
	}
	
	print("Analytics: Level started - ", level_id)

func add_task(
	task_id: String,
	successful: bool,
	time_taken: float,
	xp_earned: int,
	question: String = "",
	options: String = "",
	correct_choice: String = "",
	choice_made: String = ""
):
	"""Add a task/delivery/challenge to the current level
	Args:
		task_id: Unique task identifier (MANDATORY)
		successful: Whether task was completed successfully (MANDATORY)
		time_taken: Time taken for task in seconds (MANDATORY)
		xp_earned: XP earned from this task (MANDATORY)
		question: Optional - the question/challenge text
		options: Optional - available options (comma-separated)
		correct_choice: Optional - the correct answer/choice
		choice_made: Optional - the player's actual choice
	"""
	var task_data = {
		"taskId": task_id,
		"successful": successful,
		"timeTaken": int(time_taken),
		"xpEarned": xp_earned
	}
	
	# Add optional fields only if provided
	if question != "":
		task_data["question"] = question
	if options != "":
		task_data["options"] = options
	if correct_choice != "":
		task_data["correctChoice"] = correct_choice
	if choice_made != "":
		task_data["choiceMade"] = choice_made
	
	current_tasks.append(task_data)
	print("Analytics: Task added - ", task_id, " Success: ", successful)

func complete_level(successful: bool, level_xp: int):
	"""Complete the current level and finalize its data
	Args:
		successful: Whether the level was completed successfully
		level_xp: Total XP earned in this level
	"""
	if current_level_data.is_empty():
		push_error("Analytics: No active level to complete!")
		return
	
	var level_end_time = Time.get_ticks_msec() / 1000.0
	var time_taken = int(level_end_time - current_level_start_time)
	
	current_level_data["successful"] = successful
	current_level_data["timeTaken"] = time_taken
	current_level_data["xpEarned"] = level_xp
	current_level_data["tasks"] = current_tasks.duplicate()
	
	levels_data.append(current_level_data.duplicate())
	total_xp_earned += level_xp
	
	print("Analytics: Level completed - ", current_level_data["levelId"], 
		  " Success: ", successful, " XP: ", level_xp)
	
	# Clear current level data
	current_level_data.clear()
	current_tasks.clear()

func send_analytics():
	"""Build and send the complete analytics payload to React Native"""
	_update_session_length()
	
	var payload = {
		"userId": user_id,
		"gameId": game_id,
		"name": player_name,
		"xpEarned": total_xp_earned,
		"rawData": raw_data.duplicate(),
		"diagnostics": {
			"levels": levels_data.duplicate()
		}
	}
	
	_send_to_react_native(payload)
	print("Analytics: Payload sent to React Native")
	return payload

func _update_session_length():
	"""Update the session length in raw data"""
	var session_length = int(Time.get_unix_time_from_system() - session_start_time)
	for item in raw_data:
		if item["key"] == "sessionLength":
			item["value"] = str(session_length)
			return
	# If not found, add it
	raw_data.append({"key": "sessionLength", "value": str(session_length)})

func _send_to_react_native(payload: Dictionary):
	"""Send the payload to React Native WebView"""
	if OS.has_feature('web'):
		var json_string = JSON.stringify(payload)
		
		# Escape quotes for JavaScript string
		var escaped_json = json_string.replace("'", "\\'")
		
		var js_code = """
		(function() {
			try {
				var data = '%s';
				if (window.ReactNativeWebView) {
					window.ReactNativeWebView.postMessage(data);
					console.log('Sent to ReactNativeWebView:', data);
				} else if (window.parent) {
					window.parent.postMessage(data, '*');
					console.log('Sent to parent window:', data);
				} else {
					console.error('No WebView interface found');
				}
			} catch(e) {
				console.error('Error sending message:', e);
			}
		})();
		""" % escaped_json
		
		JavaScriptBridge.eval(js_code)
	else:
		# For testing in editor or desktop builds
		print("Analytics Payload (Desktop Mode):")
		print(JSON.stringify(payload, "\t"))

# Optional: Auto-send on game end
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		send_analytics()
