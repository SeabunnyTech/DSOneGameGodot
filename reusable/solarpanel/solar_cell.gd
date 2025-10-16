@tool
extends Polygon2D

class_name SolarCell


@export var original_color: Color


func _ready():
	$Area2D.body_entered.connect(on_hit_by_sunlight)
	#$AudioStreamPlayer.pitch_scale = 2.


func _physics_process(_delta: float):
	$Area2D/CollisionPolygon2D.polygon = polygon


var half_life: float = 1
func _process(_delta : float):
	var remain_ratio = 0.5 ** (_delta / half_life)
	color = color * remain_ratio + original_color * (1.0 - remain_ratio)



func on_hit_by_sunlight(sunlight_particle: RigidBody2D):
	# 瞬間變黃
	sunlight_particle.queue_free()
	color = Color.YELLOW
	$AudioStreamPlayer.play()
	# 創建 Tween 來漸變回原色
	var tween = create_tween()
	tween.tween_property(self, "color", original_color, 0.1)
	emit_a_bolt()


var boltscene = preload("res://reusable/bolt.tscn")
func emit_a_bolt():
	var bolt = boltscene.instantiate()
	get_parent().add_child(bolt)
	var angle = randf_range(PI*1.3, PI*1.7)
	var speed = 1000.0
	bolt.linear_velocity = Vector2(cos(angle), sin(angle)) * speed



func set_collision_mask(collision_mask):
	$Area2D.collision_mask = collision_mask
