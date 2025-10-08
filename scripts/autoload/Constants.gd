#extends Node
#
## Game Configuration
#const GAME_CONFIG = {
	## Platform
	#"platform_length": 400.0,  # meters
	#"platform_center": 200.0,  # starting position
	#
	## Movement
	#"trolley_speed": 2.0,  # meters per second
	#"coolie_walk_speed": 4.0,  # meters per second (when not pushing)
	#"coolie_reposition_time": 1.0,  # seconds to run around trolley
	#
	## Scoring
	#"max_points_per_delivery": 20,
	#"deliveries_per_level": 5,
	#"time_multiplier": 1.3,  # for allotted time calculation
	#
	## Level 2 specific
	#"effort_depletion_rate": 4.0,  # % per second
	#"max_effort": 100.0,
	#"effort_distance": 50.0,  # meters before effort depletes
	#
	## Physics
	#"push_force": 500.0,
	#"pull_force": 500.0,
	#"trolley_mass": 50.0,
	#"trolley_friction": 0.5
#}
#
## UI Configuration
#const UI_CONFIG = {
	#"button_size": Vector2(120, 120),
	#"hud_margin": 20,
	#"transition_duration": 0.3,
	#"popup_fade_time": 0.5
#}
#
## Input Configuration
#const INPUT_CONFIG = {
	#"tap_force_distance": 2.0,  # meters per tap
	#"hold_threshold": 0.2,  # seconds before continuous movement
	#"touch_dead_zone": 10.0,  # pixels
	#"double_tap_time": 0.3  # seconds
#}
#
## Delivery Time Windows (in seconds after ideal time)
#const SCORING_WINDOWS = {
	#"perfect": 1.0,  # +5 bonus
	#"good": 2.0,     # +2 bonus
	#"normal": 3.0,   # no bonus
	## beyond normal = failed delivery
#}
#
## Colors for debugging and UI
#const COLORS = {
	#"push_indicator": Color.GREEN,
	#"pull_indicator": Color.BLUE,
	#"neutral": Color.WHITE,
	#"warning": Color.YELLOW,
	#"error": Color.RED,
	#"success": Color.GREEN
#}
#
## Audio paths (to be added when assets are ready)
#const AUDIO = {
	#"push_sound": "",
	#"pull_sound": "",
	#"delivery_success": "",
	#"delivery_fail": "",
	#"flip_sound": "",
	#"walk_sound": ""
#}
#
## Calculate ideal time for a delivery
#func calculate_ideal_time(distance: float) -> float:
	#return distance / GAME_CONFIG.trolley_speed
#
## Calculate allotted time for a delivery
#func calculate_allotted_time(distance: float) -> float:
	#return calculate_ideal_time(distance) * GAME_CONFIG.time_multiplier
