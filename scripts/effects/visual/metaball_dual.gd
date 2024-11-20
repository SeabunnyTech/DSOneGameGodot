extends Node2D

@export var canvas_size = 600

# Called when the node enters the scene tree for the first time.
@export var ball1_position: Vector2 = Vector2(0.5, 0.5)
@export var ball1_radius: float = 0.1
@export var ball2_position: Vector2 = Vector2(0.3, 0.3)
@export var ball2_radius: float = 0.1
@export var smoothness: float = 0.01
@export var hint_color: Color


func setup_draw_region():
	var cs = canvas_size
	$ColorRect.size = Vector2(cs, cs)
	$ColorRect.position = Vector2(-cs/2, -cs/2)


func _ready():	

	$ColorRect.material = $ColorRect.material.duplicate()
	
	# 確保 ColorRect 使用 ShaderMaterial
	if $ColorRect.material is ShaderMaterial:
		update_shader_params()
	else:
		print("No ShaderMaterial attached!")


func set_color(color: Color):
	hint_color = color
	var shader_material = $ColorRect.material as ShaderMaterial
	shader_material.set_shader_parameter("hint_color", hint_color)


func set_ball_parameters(pos1: Vector2, radius1: float, pos2: Vector2, radius2: float):

	ball1_position = pos1 / canvas_size + Vector2(0.5, 0.5)
	ball2_position = pos2 / canvas_size + Vector2(0.5, 0.5)
	ball1_radius = radius1 / canvas_size
	ball2_radius = radius2 / canvas_size

	update_shader_params()	 # This is lazy


func update_shader_params():
	var shader_material = $ColorRect.material as ShaderMaterial
	shader_material.set_shader_parameter("hint_color", hint_color)
	shader_material.set_shader_parameter("ball1_position", ball1_position)
	shader_material.set_shader_parameter("ball1_radius", ball1_radius)
	shader_material.set_shader_parameter("ball2_position", ball2_position)
	shader_material.set_shader_parameter("ball2_radius", ball2_radius)
	shader_material.set_shader_parameter("smoothness", smoothness)
