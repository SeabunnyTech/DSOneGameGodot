@tool
extends Node2D

signal triggered(node: Node2D)


# 將觸發事件暴露到第一層方便外部連接
@onready var body_entered = $button/Area2D.body_entered


var sensetive = true

# Button 被觸動時會往 -y 方向跳高, 影子也會跑離原位
@export var jump_distance = 20
var jump_progress: float:
	set(value):
		jump_progress = clamp(value, 0 , 1)
		$button.position = Vector2(0, -jump_progress * jump_distance)
		_update_shade_position()

@export var shade_distance = 40:
	set(value):
		shade_distance = value
		_update_shade_position()

@export var shade_angle = 45:
	set(value):
		shade_angle = value
		_update_shade_position()


func _update_shade_position():
	var ang_rad = deg_to_rad(shade_angle)
	$shade.position = (shade_distance + jump_progress * jump_distance)\
						* Vector2(cos(ang_rad), sin(ang_rad))


var jump_tween
func _on_triggered_anim(body: Node2D):
	if not sensetive:
		return
	$"triggered sfx".play()
	sensetive = false
	jump_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	jump_tween.tween_property(self, 'jump_progress', 1, 0.2)
	jump_tween.tween_property(self, 'jump_progress', 0, 0.2)
	jump_tween.tween_callback(fade_away)
	triggered.emit(body)


func reset():
	if alpah_tween:
		alpah_tween.kill()
	if jump_tween:
		jump_tween.kill()
	sensetive = false


var alpah_tween

func fade_away(immediate=false):
	sensetive = false
	if immediate:
		modulate.a = 0
		return

	if alpah_tween:
		alpah_tween.kill()
	alpah_tween = create_tween()
	alpah_tween.tween_property(self, 'modulate:a', 0, 1)


func showup():
	if alpah_tween:
		alpah_tween.kill()
	alpah_tween = create_tween()
	alpah_tween.tween_property(self, 'modulate:a', 1, 1)
	alpah_tween.tween_callback(func():sensetive = true)


func _ready() -> void:
	reset()
	$button/Area2D.body_entered.connect(_on_triggered_anim)
	_update_shade_position()
	
	if get_tree().current_scene == self:
		position = Vector2(300, 300)
		showup()
