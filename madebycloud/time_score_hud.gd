extends Node

@onready var player_one_score: Label = %PlayerOneScore
@onready var player_one_timer: Label = %PlayerOneTimer


func _ready() -> void:
	update_score(0)
	update_time(0)


func show(immediate=false):
	_set_visible(true, immediate)



func hide(immediate=false):
	_set_visible(false, immediate)


func reset():
	hide(true)
	player_one_timer.text = '0'
	player_one_score.text = '0'


var transition_tween
func _set_visible(visibility, immediate):
	if transition_tween:
		transition_tween.kill()
	transition_tween = create_tween()

	var target_alpha = 1.0 if visibility else 0.0

	if immediate:
		$HBoxContainer.modulate.a = target_alpha
	else:
		transition_tween.tween_property($HBoxContainer, 'modulate:a', target_alpha, 1)
	


func update_time(time: float) -> void:
	player_one_timer.text = "%02d:%02d" % [int(time / 60), int(time) % 60]



func update_score(scores: float) -> void:
	player_one_score.text = str(scores)
