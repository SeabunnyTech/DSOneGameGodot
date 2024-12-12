@tool
extends Node2D

signal go_next_scene

@export var disabled = true

@onready var guide_ui = $CenterContainer/VBoxContainer


func enter_scene():
	# 進場的前提是畫面已經是一片白底
	# 這個畫面將從一片 white_curtain 進入
	visible = true

	# 淡出白色前景
	var tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(guide_ui, 'modulate:a', 1, 1)
	tween.finished.connect(func():
		disabled = false
	)



var time_since_process = 0
var duration_each_img = 0.3


func _ready():
	reset()
	enter_scene()


func _process(delta: float) -> void:
	if disabled:
		return

	if Engine.is_editor_hint():
		return

	if PlayerManager.num_active_players() > 0:
		leave_for_next_scene()



func leave_for_next_scene():
	var tween = create_tween()
	tween.tween_property(guide_ui, 'modulate:a', 0, 0.5)
	tween.tween_interval(0.5)
	tween.finished.connect(
		func():
			reset()
			go_next_scene.emit()
	)



func reset():
	visible = false
	guide_ui.modulate.a = 0
	disabled = true
