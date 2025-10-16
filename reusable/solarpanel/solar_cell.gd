@tool
extends Polygon2D

class_name SolarCell


@export var original_color: Color


func _ready():
	$Area2D.body_entered.connect(on_hit_by_sunlight)


var half_life: float = 1

func _physics_process(_delta: float):
	$Area2D/CollisionPolygon2D.polygon = polygon

func _process(_delta : float):
	#if Time.get_ticks_msec() > blink_time:
		##on_hit_by_sunlight()
		#blink_time = Time.get_ticks_msec() + 2000

	

	var remain_ratio = 0.5 ** (_delta / half_life)
	color = color * remain_ratio + original_color * (1.0 - remain_ratio)




func on_hit_by_sunlight(sunlight_particle: RigidBody2D):
	# 瞬間變黃
	color = Color.YELLOW
	
	# 創建 Tween 來漸變回原色
	var tween = create_tween()
	tween.tween_property(self, "color", original_color, 0.1)
