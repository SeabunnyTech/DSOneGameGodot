extends Node2D

@export var canvas_size = 1600
@export var ball_count: int = 3
@export var ball_radii: Array[float] = [40, 35, 30]

func _ready():	
	var cs = canvas_size
	$ColorRect.size = Vector2(cs, cs)
	$ColorRect.position = Vector2(-cs/2, -cs/2)
	$ColorRect.material = $ColorRect.material.duplicate()
	update_ball_count(ball_count)
	update_ball_radii(ball_radii)


func update_ball_colors(	ball_colors: Array[Vector3]):
	$ColorRect.material.set_shader_parameter("ball_colors", ball_colors)


func update_ball_count(new_ball_count: int):
	ball_count = new_ball_count
	$ColorRect.material.set_shader_parameter("ball_count", ball_count)


func update_ball_radii(new_ball_radii: Array[float]):
	ball_radii = new_ball_radii
	var shader_ball_radii = []
	for radius in ball_radii:
		shader_ball_radii.append(radius / canvas_size)

	$ColorRect.material.set_shader_parameter("ball_radii", shader_ball_radii)


func update_ball_positions(ball_positions: Array[Vector2]):
	var shader_ball_positions = []
	for pos in ball_positions:
		shader_ball_positions.append(pos / canvas_size + Vector2(0.5, 0.5))

	$ColorRect.material.set_shader_parameter("ball_positions", shader_ball_positions)
