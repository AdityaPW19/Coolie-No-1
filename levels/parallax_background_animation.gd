extends ParallaxBackground

@export var cloud_speed: float = -15
@export var train_speed: float = 300
@export var train_loop_limit: float = 11000
@export var bird_speed: float = 160

@onready var clouds: ParallaxLayer = $ParallaxLayer2
@onready var train: ParallaxLayer = $ParallaxLayer3
@onready var birds: ParallaxLayer = $ParallaxLayer6

@onready var animatedBird1: AnimatedSprite2D = $ParallaxLayer6/AnimatedBird
@onready var animatedBird2: AnimatedSprite2D = $ParallaxLayer6/AnimatedBird2
@onready var animatedBird3: AnimatedSprite2D = $ParallaxLayer6/AnimatedBird3

@onready var anouncementSpeaker1: AnimatedSprite2D = $ParallaxLayer4/AnouncementSpeaker1
@onready var anouncementSpeaker2: AnimatedSprite2D = $ParallaxLayer4/AnouncementSpeaker2

@onready var train_sound: AudioStreamPlayer2D = $ParallaxLayer3/Cartoontrain/AudioStreamPlayer2D
@onready var anouncementAudio: AudioStreamPlayer2D = $ParallaxLayer4/AnouncementAudio

# Cooldown control
var can_play_announcement := true
var announcement_cooldown := 10.0 # seconds

func _ready(): 
	animatedBird1.play("flying")
	animatedBird2.play("flying")
	animatedBird3.play("flying")

	anouncementSpeaker1.play("default")
	anouncementSpeaker2.play("default")

	play_announcement()

	train_sound.stream.loop = true
	train_sound.attenuation = 0.0
	train_sound.play()

func _process(delta: float) -> void:
	clouds.motion_offset.x += cloud_speed * delta
	birds.motion_offset.x += bird_speed * delta
	
	train.motion_offset.x += train_speed * delta
	
	if train.motion_offset.x >= train_loop_limit:
		train.motion_offset.x = 0

# Call this function when you want the announcement to play
func play_announcement():
	if can_play_announcement:
		anouncementAudio.play()
		anouncementAudio.stream.loop = true
		can_play_announcement = false
		start_announcement_cooldown()

# Starts the cooldown using a timer
func start_announcement_cooldown():
	var timer = Timer.new()
	timer.wait_time = announcement_cooldown
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_announcement_cooldown_timeout"))
	add_child(timer)
	timer.start()

func _on_announcement_cooldown_timeout():
	can_play_announcement = true
