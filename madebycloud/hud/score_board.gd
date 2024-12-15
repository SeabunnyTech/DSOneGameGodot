extends Control


var score = 0:
	set(value):
		score = value
		%Score.text = str(score)


func reset():
	score = 0


var transition_tween
func fade(out=true):
	if transition_tween:
		transition_tween.kill()
	var target_alpha = 0 if out else 1
	transition_tween = create_tween()
	transition_tween.tween_property(self, 'modulate:a', target_alpha, 1)


func add_score():
	score += 1
