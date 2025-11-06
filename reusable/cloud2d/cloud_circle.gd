extends Node2D
class_name CloudCircle

@export_flags_2d_physics var collision_channels = 14:
	set(value):
		collision_channels = value
		$InertiaFollower/RigidBody2D/CollisionShape2D.collision_layer = collision_channels
		$InertiaFollower/RigidBody2D/CollisionShape2D.collision_mask = collision_channels


@export var radius: float = 180:
	set(value):
		radius = value
		var render_rect_size = Vector2(radius, radius) * 2 / 1.8
		$InertiaFollower/ColorRect.size = render_rect_size
		$InertiaFollower/ColorRect.position = -render_rect_size / 2
		$InertiaFollower/Area2D/CollisionShape2D.shape.radius = radius * 0.3

@export var light_position: Vector2 = Vector2(0.7, 0.3):
	set(value):
		light_position = value
		_update_shader()

@export var use_shadow: bool = true:
	set(value):
		use_shadow = value
		_update_shader()

@export var shadow_color: Color = Color(0.7, 0.7, 0.7, 1.0):
	set(value):
		shadow_color = value
		_update_shader()

@export var shadow_smoothness: float = 0.0:
	set(value):
		shadow_smoothness = value
		_update_shader()

@export var shadow_intensity: float = 0.15:
	set(value):
		shadow_intensity = value
		_update_shader()

@onready var color_rect: ColorRect = $InertiaFollower/ColorRect


var float_phase = randf()
var float_peroid = randi_range(4000, 4500)		#ms

func _ready():
	color_rect.material = color_rect.material.duplicate()
	$InertiaFollower/Area2D.body_entered.connect(on_hit_by_sunlight)
	_update_shader()
	


func _process(delta: float) -> void:
	$InertiaFollower.position.y = radius* 0.02 * sin(2*PI*(float_phase + Time.get_ticks_msec() / 4000.0))



func on_hit_by_sunlight(sunlight_particle: RigidBody2D):
	# 瞬間變黃
	sunlight_particle.queue_free()


func _update_shader():
	# 確保節點已經準備好
	if not is_inside_tree():
		return

	# 如果是在編輯器中且節點還沒準備好，手動獲取
	if not color_rect:
		color_rect = get_node_or_null("InertiaFollower/ColorRect")

	if not color_rect or not color_rect.material:
		return

	var material = color_rect.material as ShaderMaterial
	if material:
		material.set_shader_parameter("light_position", light_position)
		#material.set_shader_parameter("shadow_color", shadow_color)
		material.set_shader_parameter("shadow_smoothness", shadow_smoothness)
		material.set_shader_parameter("shadow_intensity", shadow_intensity)
		
		# 如果不使用陰影，將 shadow_intensity 設為 0
		if not use_shadow:
			material.set_shader_parameter("shadow_intensity", 0.0)
		else:
			material.set_shader_parameter("shadow_intensity", shadow_intensity)
