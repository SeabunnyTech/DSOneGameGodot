@tool
extends Polygon2D

class_name SolarCell
signal hit_by_sunlight

@export var original_color: Color
@export var player_index:int = 0

func _ready():
	$Area2D.body_entered.connect(on_hit_by_sunlight)
	#$AudioStreamPlayer.pitch_scale = 2.


func _physics_process(_delta: float):
	$Area2D/CollisionPolygon2D.polygon = polygon


var half_life: float = 1
func _process(_delta : float):
	var remain_ratio = 0.5 ** (_delta / half_life)
	color = color * remain_ratio + original_color * (1.0 - remain_ratio)



func on_hit_by_sunlight(sunlight_particle):
	# 不是光子的話不要收
	if not sunlight_particle.has_method("on_cloud_hit"):
		return

	# 不同 player_index 不要收
	if sunlight_particle.player_index != player_index:
		return

	# 瞬間變黃
	sunlight_particle.queue_free()
	color = Color.YELLOW
	$AudioStreamPlayer.play()
	# 創建 Tween 來漸變回原色
	var tween = create_tween()
	tween.tween_property(self, "color", original_color, 0.3)
	hit_by_sunlight.emit()
	emit_a_bolt()


var boltscene = preload("res://reusable/bolt.tscn")
func emit_a_bolt():
	var bolt = boltscene.instantiate()
	get_parent().add_child(bolt)
	var angle = randf_range(PI*1.3, PI*1.7)
	var speed = 1500.0
	bolt.linear_velocity = Vector2(cos(angle), sin(angle)) * speed



func set_collision_mask(collision_mask):
	$Area2D.collision_mask = collision_mask

func set_collision_enabled(enabled: bool):
	$Area2D/CollisionPolygon2D.disabled = not enabled
