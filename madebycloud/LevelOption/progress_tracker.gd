extends Node

signal triggered
signal heading_altered(target_state)

@export var duration: float = 0.5

var progress: float = 0.0
var target_progress: float = 0.0
var tween


func reset():
	progress = 0.0
	target_progress = 0.0


func react(triggering: bool):
	var new_target_progress = 1 if triggering else 0
	if new_target_progress != target_progress:
		target_progress = new_target_progress
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(self, 'progress', target_progress, duration * (1-progress))

		heading_altered.emit(triggering)

		# 走在觸發的路上
		if triggering:
			tween.tween_callback(triggered.emit)
