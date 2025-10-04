extends Label



var tween = null

func show_message(message, immediate=false):
	if immediate:
		text = message
		modulate.a = 1
		return

	if tween:
		tween.kill()

	# 將 label 淡出再抽換文字再淡入
	tween = create_tween()
	tween.tween_property(self, 'modulate:a', 0, 0.5)
	tween.finished.connect(func():
		text = message
		tween.kill()
		tween = create_tween()
		tween.tween_property(self, 'modulate:a', 1, 0.5)
	)
