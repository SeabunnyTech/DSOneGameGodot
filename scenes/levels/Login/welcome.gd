@tool
extends Node2D

signal go_next_scene

@export var disabled = true

@onready var guide_texture_rect = $CenterContainer/VBoxContainer/TextureRect
@onready var white_curtain = $WhiteRectCurtain

var guide_images = [
	load("res://assets/images/drawings/解說圖1-1.PNG"),
	load("res://assets/images/drawings/解說圖1-2.PNG"),
	load("res://assets/images/drawings/解說圖1-3.PNG")
]


func enter_scene():
	# 進場的前提是畫面已經是一片白底
	# 這個畫面將從一片 white_curtain 進入
	modulate.a = 1

	# 淡出白色前景
	var tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(white_curtain, 'modulate:a', 0, 1)
	tween.finished.connect(func():
		disabled = false
	)



var time_since_process = 0
var duration_each_img = 0.3
@export var loop_img =false

func _process(delta: float) -> void:
	if disabled:
		return

	if PlayerManager.num_active_players() > 0:
		leave_for_next_scene()

	if loop_img:
		time_since_process += delta
		var image_index = int(floor(time_since_process / duration_each_img)) % 3
		guide_texture_rect.texture = guide_images[image_index]



func leave_for_next_scene():
	var tween = create_tween()
	tween.tween_property(white_curtain, 'modulate:a', 1, 0.5)
	tween.tween_interval(0.5)
	tween.finished.connect(
		func():
			reset()
			go_next_scene.emit()
	)



func reset():
	modulate.a = 0
	disabled = true
