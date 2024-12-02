extends Node2D

@export var mute: bool = false
var background_music_playing: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func stop_level_music():
	$GameMusic.stop()
	background_music_playing = false

func play_level_music():
	if not background_music_playing:
		$GameMusic.play()
	background_music_playing = true

func play_victor_music():
	if $GameMusic.playing:
		$GameMusic.stop()
		background_music_playing = false
	
	if not background_music_playing:
		$GameVictory.play()
	background_music_playing = true
