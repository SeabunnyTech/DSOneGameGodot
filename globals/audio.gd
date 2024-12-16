extends AudioStreamPlayer

# 加入這個 AudioStreamPlayer 作為 Global 的 AudioPlayer 目的包含
#
# 1. 絕不同時播放兩首音樂 ( 只用一個 player 的話就不可能犯錯導致兩個物件同時播音樂 )
# 2. 提供播放功能 ( 不同場景可能會試圖播放同一首 AudioStream, 這種時候忽略就好 )
# 3. 播放與停止功能都要提供 fadein fadeout 選項

var current_track: AudioStream = null
var fade_tween: Tween


func _ready():
	fade_tween = create_tween()
	stream_paused = false


func play_music(new_track: AudioStream, fade_duration: float = 1.0):
	if current_track:
		if current_track.resource_path == new_track.resource_path:
			return

	if stream:
		fade_out(fade_duration)
	
	current_track = new_track
	stream = new_track
	play()
	fade_in(fade_duration)


func fade_in(duration: float = 1.0):
	volume_db = -80  # Start silent
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "volume_db", 0.0, duration)



func fade_out(duration: float = 1.0):
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "volume_db", -80.0, duration)
	fade_tween.tween_callback(stop)


func pause_music():
	stream_paused = true

func resume_music():
	stream_paused = false

func set_volume(value: float):
	volume_db = linear_to_db(value)
