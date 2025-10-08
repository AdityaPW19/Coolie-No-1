extends Node

func _ready():
	print("GameConstants ready!")

# Physics Constants
const PHYSICS = {
	"gravity": 980.0,
	"player_mass": 10.0,
	"trolley_mass": 50.0,  # From GDD
	"max_push_force": 500.0,  # From GDD
	"max_pull_force": 500.0,  # From GDD (same as push in GDD)
	"trolley_friction": 0.5,  # From GDD
	"friction_smooth": 0.1,
	"friction_rough": 0.4,
	"friction_slippery": 0.05,
	"ramp_angle_gentle": 15.0,
	"ramp_angle_steep": 30.0
}

# Game Configuration (From GDD)
const GAME = {
	# Platform
	"platform_length": 400.0,  # meters
	"platform_center": 200.0,  # starting position in meters
	# We set it to 10.0 to match your desired 200 px/s speed.
	"trolley_speed_meters_per_sec": 10.0,
	
	# We will now define the ACTUAL pixel speeds here as well.
	# This makes it easy to change game feel.
	"PLAYER_WALK_SPEED_PIXELS": 200.0,
	"TROLLEY_MOVE_SPEED_PIXELS": 200.0, # Your desired speed
	
	# Movement
	"trolley_speed": 2.0,  # meters per second
	"coolie_walk_speed": 4.0,  # meters per second (when not pushing)
	"coolie_reposition_time": 1.0,  # seconds to run around trolley
	
	# Levels
	"starting_level": 1,
	"deliveries_per_level": 5,
	"max_points_per_delivery": 20,
	
	# Timing
	"time_multiplier": 2.8,  # for allotted time calculation
	"time_limit_level_1": 240.0,  # 4 minutes total
	"time_limit_level_2": 360.0,  # 6 minutes total
	
	# Scoring
	"delivery_points": 100,
	"time_bonus_multiplier": 3.0
}

# Level-specific Configuration (From GDD)
const LEVEL_CONFIG = {
	1: {  # Level 1 - Rookie's Route
		"effort_enabled": false,
		"flip_enabled": false,
		"effort_meters": false,
		"effort_meters_enabled": false
	},
	2: {  # Level 2 - Express Pro
		"flip_enabled": true,
		"effort_meters_enabled": true,
		"max_effort": 100.0,
		"effort_cost_per_tap": 20.0,
		"effort_recharge_rate": 15 # This is 6.25 points per second
	}
}

# Input Configuration (From GDD)
const INPUT = {
	"tap_force_distance": 2.0,  # meters per tap
	"hold_threshold": 0.2,  # seconds before continuous movement
	"touch_dead_zone": 10.0,  # pixels
	"double_tap_time": 0.3  # seconds
}

# Scoring Windows (From GDD)
const SCORING = {
	"perfect_window": 4.0,  # +5 bonus (within 1 sec of ideal)
	"good_window": 8.0,     # +2 bonus (within 2 sec of ideal)
	"normal_window": 12.0,   # no bonus (within 3 sec of ideal)
	# beyond normal = failed delivery
	"perfect_points": 20,
	"good_points": 17,
	"normal_points": 15,
	"failed_points": 0
}

# Visual Settings
const VISUAL = {
	"camera_smooth_speed": 5.0,
	"camera_offset": Vector2(200, 0),
	"force_indicator_scale": 0.5,
	"debug_draw": false,
	"platform_pixels_per_meter": 20.0  # Conversion factor
}

# Touch Controls
const TOUCH = {
	"button_size": Vector2(120, 120),
	"joystick_size": 150.0,
	"force_slider_size": Vector2(60, 300),
	"dead_zone": 0.2
}

# UI Configuration
const UI = {
	"hud_margin": 20,
	"transition_duration": 0.3,
	"popup_fade_time": 0.5,
	"message_display_time": 2.0
}

# Colors for UI and debugging
const COLORS = {
	"push_indicator": Color.GREEN,
	"pull_indicator": Color.BLUE,
	"neutral": Color.WHITE,
	"warning": Color.YELLOW,
	"error": Color.RED,
	"success": Color.GREEN,
	"delivery_zone": Color(0, 1, 0, 0.3)
}

# Audio paths (to be added when assets are ready)
const AUDIO = {
	"cutscenebgm": "res://assets/audio/a-desi-inspired-dj-mix-blending.mp3",
	"gameMusic1": "res://assets/audio/game-music-player-console-8bit-background-intro-theme-297305 compressed.mp3",
	"StationAmbience": "res://assets/audio/indian-railway-station-ambience-crowd-chatter-and-train-arrival-331012.mp3", 
	"PlatformAnouncement": "res://assets/audio/indian-railway-train-arriving-announcement-333043.mp3",
	"Level1DeliveryMusic": "res://assets/audio/gaming-music-8-bit-console-play-background-intro-theme-342069.mp3",
	"LevelBgm": "res://assets/audio/8-bit-video-game-background-musi.mp3",
	#"LevelBgm": "res://assets/audio/Jiya-Tu-Gangs-Of-Wasseypur-128-K.mp3",
	"delivery_success": "res://assets/audio/video-game-bonus-323603.mp3",
	"delivery_fail": "res://assets/audio/game-over-arcade-6435.mp3",
	"trolley_sfx": "res://assets/audio/luggage-rolling3-73475.mp3",
	"flip_sound": "res://assets/audio/woosh-260275.mp3",
	"walk_sound": "res://assets/audio/footsteps-on-hard-floor-356919.mp3",
	"level_complete": "res://assets/audio/brass-fanfare-with-timpani-and-winchimes-reverberated-146260.mp3",
	"buttonCLick": "res://assets/audio/menu-button-88360.mp3"
}

const DIALOGUES = {
	"VendorDialogue": "res://assets/audio/dialogues/ChaiWallah1.mp3",
	"CoolieDialogue1": "res://assets/audio/dialogues/CoolieDialogue1.mp3",
	"CoolieDialogue2": "res://assets/audio/dialogues/CoolieDialogue2.mp3"
}

# Helper Functions

# This helper function becomes more important now
func is_feature_enabled(level: int, feature: String) -> bool:
	if level in LEVEL_CONFIG:
		# e.g., LEVEL_CONFIG[1].get("flip_enabled", false)
		return LEVEL_CONFIG[level].get(feature + "_enabled", false)
	return false
	
# Calculate ideal time for a delivery
func calculate_ideal_time(distance: float) -> float:
	return distance / GAME.trolley_speed_meters_per_sec

# Calculate allotted time for a delivery (with 1.3x multiplier)
func calculate_allotted_time(distance: float) -> float:
	return calculate_ideal_time(distance) * GAME.time_multiplier

# Convert meters to pixels based on platform scale
func meters_to_pixels(meters: float) -> float:
	return meters * VISUAL.platform_pixels_per_meter

# Convert pixels to meters
func pixels_to_meters(pixels: float) -> float:
	return pixels / VISUAL.platform_pixels_per_meter

# Get scoring points based on delivery time
#func get_delivery_points(distance: float, time_taken: float) -> int:
	#var ideal_time = calculate_ideal_time(distance)
	#var time_difference = time_taken - ideal_time
	#
	#if time_difference <= SCORING.perfect_window:
		#return SCORING.perfect_points
	#elif time_difference <= SCORING.good_window:
		#return SCORING.good_points
	#elif time_difference <= SCORING.normal_window:
		#return SCORING.normal_points
	#else:
		#return SCORING.failed_points
		
func get_delivery_points(distance: float, time_taken: float) -> int:
	var ideal_time = calculate_ideal_time(distance)
	var allotted_time = calculate_allotted_time(distance)
	
	print("=== GDD SCORING ===")
	print("  Distance: ", distance, "m, Time: ", time_taken, "s")
	print("  Ideal: ", ideal_time, "s, Allotted: ", allotted_time, "s")
	
	# Failed if over allotted time
	if time_taken > allotted_time:
		print("  CANCELLED: 0 points (over ", allotted_time, "s)")
		return 0
	
	# GDD scoring windows from ideal time
	var time_over_ideal = time_taken - ideal_time
	
	if time_over_ideal <= SCORING.perfect_window:           # Ideal to +4 sec
		print("  PERFECT: 20 points (15 + 5 bonus)")
		return 20  # 15 (on-time) + 5 (bonus)
	elif time_over_ideal <= SCORING.good_window:        # +1 to +2 X 4sec  
		print("  GOOD: 17 points (15 + 2 bonus)")
		return 17  # 15 (on-time) + 2 (bonus)
	elif time_over_ideal <= SCORING.normal_window:        # +2 to +3 x  4 sec
		print("  AVERAGE: 15 points (15 only)")
		return 15  # 15 (on-time only)
	else:
		# Within allotted time but over +3s from ideal
		print("  SLOW: 5 points (within time but slow)")
		return 5   # Some points for completing
