extends Node2D
class_name CloudCircle

var mean_y: float = 0.0

@export var radius: float = 180:
	set(value):
		radius = value
		var render_rect_size =  2.0 * Vector2(radius, radius) * 2.0/1.8
		$ColorRect.size = render_rect_size
		$ColorRect.position.x = -radius
		mean_y = - radius

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


var float_phase = randf()
var float_peroid = randi_range(4000, 4500)		#ms

func _ready():
	$ColorRect.material = $ColorRect.material.duplicate()
	_update_shader()
	


func _process(delta: float) -> void:
	$ColorRect.position.y = mean_y + radius* 0.02 * sin(2*PI*(float_phase + Time.get_ticks_msec() / 4000.0))



func _update_shader():
	# 確保節點已經準備好
	if not is_inside_tree():
		return

	var material = $ColorRect.material as ShaderMaterial
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
