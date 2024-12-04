@tool
extends ColorRect



@export var center = Vector2(800, 800):
	set(new_center):
		center = new_center
		material.set_shader_parameter("mask_center", Array([center[0], center[1]]))



@export var radius = 600.0:
	set(new_radius):
		radius = new_radius
		material.set_shader_parameter("mask_radius", radius)



var center_tween
var call_back_tween
var radius_tween


func tween_center_radius(new_center=null, new_radius=null, duration=1, callback=null):
	if new_center:
		if center_tween != null:
			center_tween.kill()
		center_tween = create_tween()\
						.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		center_tween.tween_method(func(value): center = value, center, new_center, duration)

	if new_radius != null:
		if radius_tween:
			radius_tween.kill()
		radius_tween = create_tween()\
						.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		radius_tween.tween_method(func(value): radius = value, radius, new_radius, duration)


	if callback:
		if call_back_tween:
			call_back_tween.kill()
		call_back_tween = create_tween()
		call_back_tween.tween_interval(duration)
		call_back_tween.finished.connect(callback)
