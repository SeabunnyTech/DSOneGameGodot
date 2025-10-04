extends Path2D

signal eletron_hit_end(electron)

# Called when the node enters the scene tree for the first time.
func _pass_electron(electron):
	var electron_boat = PathFollow2D.new()
	add_child(electron_boat)

	electron_boat.add_child(electron)
	var tween = create_tween()

	# 先跑進電廠
	tween.tween_property(electron_boat, 'progress_ratio', 0.6, 1.5)\
			.set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_CUBIC)

	# 再跑去電塔
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(electron_boat, 'progress_ratio', 1, 1.5)

	tween.parallel().tween_property(electron, 'scale', Vector2(0.4, 0.4), 1.5)
			#.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.chain()
	
	tween.tween_callback(func():
		electron_boat.remove_child(electron)
		eletron_hit_end.emit(electron)
	)
