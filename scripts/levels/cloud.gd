extends Sprite2D

# 動畫參數
@export var float_range: Vector2 = Vector2(30, 32)  # 上下浮動範圍
@export var float_duration: Vector2 = Vector2(10, 20)  # 浮動週期範圍
@export var scale_range: Vector2 = Vector2(1, 1.05)  # 縮放範圍
@export var scale_duration: Vector2 = Vector2(10, 15)  # 縮放週期範圍
@export var move_range: Vector2 = Vector2(100, 200)  # 水平移動範圍
@export var move_duration: Vector2 = Vector2(10, 25)  # 完成一次左右移動的時間範圍

var original_position: Vector2
var viewport_width: float
var tween: Tween

func _ready():
	original_position = position
	viewport_width = get_viewport_rect().size.x
	_start_animation()

func _start_animation():
	if tween:
		tween.kill()
	
	tween = create_tween().set_loops()
	
	# 上下浮動動畫
	var float_time = randf_range(float_duration.x, float_duration.y)
	var float_offset = randf_range(float_range.x, float_range.y)
	
	tween.tween_property(self, "position:y",
		original_position.y - float_offset, float_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", 
		original_position.y + float_offset, float_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	# 同時進行縮放動畫
	var parallel_tween = create_tween().set_loops()
	var scale_time = randf_range(scale_duration.x, scale_duration.y)
	
	parallel_tween.tween_property(self, "scale", 
		Vector2.ONE * scale_range.y, scale_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	parallel_tween.tween_property(self, "scale", 
		Vector2.ONE * scale_range.x, scale_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	# 水平移動動畫
	var move_tween = create_tween().set_loops()
	var move_offset = randf_range(move_range.x, move_range.y)
	var move_time = randf_range(move_duration.x, move_duration.y)
	
	move_tween.tween_property(self, "position:x",
		original_position.x + move_offset, move_time * 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	move_tween.tween_property(self, "position:x",
		original_position.x - move_offset, move_time * 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
