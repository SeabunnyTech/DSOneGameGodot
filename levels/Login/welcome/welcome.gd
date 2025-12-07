@tool
extends Control

signal leave_for_level(new_scene_name)

@export var tutorial_music: AudioStream

@onready var collision2d = $StartButtonTexture/Area2D/CollisionShape2D

func enter_scene():
	# 進場的前提是畫面已經是一片白底
	# 這個畫面將從一片 white_curtain 進入
	visible = true

	# 淡出白色前景
	var tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(self, 'modulate:a', 1, 1)
	tween.finished.connect(func():
		collision2d.disabled = false
	)
	$UpperTitle.play_pop_in_animation(.8)
	$LowerTitle.play_pop_in_animation(1.2)
	
	GlobalAudioPlayer.play_music(tutorial_music, 0.5)



var time_since_process = 0
var duration_each_img = 0.3


func _ready():
	# 核心邏輯：判斷自己是不是當前場景的主角
	# get_tree().current_scene 抓到的是目前運行場景樹的根
	if get_tree().current_scene == self:
		print("偵測到 F6 單獨測試模式：自動執行入場流程")
		reset()
		enter_scene()
	
	$StartButtonTexture/Area2D.body_entered.connect(leave_for_next_scene)




var is_leaving = false


func leave_for_next_scene(_body):
	if is_leaving:
		return
	is_leaving = true

	$AudioStreamPlayer.play()
	var tween = create_tween()
	tween.tween_property(self, 'modulate:a', 0, 0.5)
	tween.tween_interval(0.5)
	tween.finished.connect(
		func():
			reset()
			leave_for_level.emit('logos')
	)



func reset():
	$UpperTitle.scale = Vector2.ZERO
	$LowerTitle.scale = Vector2.ZERO
	visible = false
	self.modulate.a = 0
	collision2d.disabled = true
	is_leaving = false
