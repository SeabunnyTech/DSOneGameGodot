extends CanvasLayer

signal timeout

@onready var player_one_score: Label = %PlayerOneScore
@onready var player_one_timer: Label = %PlayerOneTimer


@onready var start_timer = $Timer.start
@onready var container = $HBoxContainer

@export var total_time = 30

var seconds_left:
	set(value):
		seconds_left = value
		player_one_timer.text = "%02d:%02d" % [int(seconds_left / 60), int(seconds_left) % 60]

var score = 0:
	set(value):
		score = value
		player_one_score.text = str(score)



func _ready() -> void:
	reset()
	$Timer.timeout.connect(_tick)


func _tick():
	seconds_left -= 1
	if seconds_left == 0:
		timeout.emit()
		$Timer.stop()


func fade_in(immediate=false):
	_set_visible(true, immediate)



func fade_out(immediate=false):
	_set_visible(false, immediate)


func reset():
	fade_out(true)
	seconds_left = total_time
	score = 0


var transition_tween
func _set_visible(visibility, immediate):
	var target_alpha = 1.0 if visibility else 0.0

	if immediate:
		container.modulate.a = target_alpha
	else:
		if transition_tween:
			transition_tween.kill()
		transition_tween = create_tween()
		transition_tween.tween_property(container, 'modulate:a', target_alpha, 1)


func add_score(value):
	score += value
