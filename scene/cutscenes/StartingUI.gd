extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var menu_music: AudioStreamPlayer = $MainMenuMusic
@onready var click_sound: AudioStreamPlayer = $ClickSound

func _ready() -> void:
	menu_music.play()  # Play main menu music on loop
	animation_player.play("Starting")
	fade_overlay.visible = true

func _on_play_button_pressed() -> void:
	animation_player.play("playPressed")
	click_sound.play()  # Play the click sound
	_start_fade_out_music()  # Begin fading out menu music
	animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "playPressed":
		#get_tree().change_scene_to_file("res://game/levels/Level1.tscn")
		get_tree().change_scene_to_file("res://scene/cutscenes/cut_scene_1.tscn")

func _start_fade_out_music():
	var fade_timer = Timer.new()
	fade_timer.wait_time = 0.05
	fade_timer.one_shot = false
	add_child(fade_timer)
	fade_timer.start()

	fade_timer.timeout.connect(func():
		if menu_music.volume_db > -40:
			menu_music.volume_db -= 2  # Reduce volume in steps
		else:
			menu_music.stop()
			fade_timer.queue_free()
	)

#func _input(event):
	#if event is InputEventScreenTouch and event.pressed:
		#var pos = event.position
		#var clicked = get_viewport().gui_get_focus_owner()
		#print("Touched at ", pos, ", UI focus owner: ", clicked)
