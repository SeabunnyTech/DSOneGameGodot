extends Node2D

@export var canvas_size = 1600
@export var ball_count: int = 3
@export var ball_radii: Array[float] = [40, 35, 30]

@onready var color_rect = $ColorRect
@onready var color_rect2 = $ColorRect2 # Anticyclone visual

func _ready():
	var cs = canvas_size
	# Initialize ColorRect (Metaball)
	color_rect.size = Vector2(cs, cs)
	color_rect.position = Vector2(-cs/2.0, -cs/2.0)
	color_rect.material = color_rect.material.duplicate()
	
	# Initialize ColorRect2 (Anticyclone)
	color_rect2.size = Vector2(cs, cs)
	color_rect2.position = Vector2(-cs/2.0, -cs/2.0)
	color_rect2.material = color_rect2.material.duplicate()
	color_rect2.modulate.a = 0.0 # Start invisible
	
	update_ball_count(ball_count)
	update_ball_radii(ball_radii)


func switch_visual(is_anticyclone: bool, duration: float = 0.5):
	var tween = create_tween()
	if is_anticyclone:
		tween.tween_property(color_rect, "modulate:a", 0.0, duration)
		tween.tween_property(color_rect2, "modulate:a", 1.0, duration)
	else:
		tween.tween_property(color_rect, "modulate:a", 1.0, duration)
		tween.tween_property(color_rect2, "modulate:a", 0.0, duration)


func update_ball_colors(	ball_colors: Array[Vector4]):
	color_rect.material.set_shader_parameter("ball_colors", ball_colors)
	# Anticyclone shader does not use ball_colors, so no need to set it for color_rect2

func update_ball_count(new_ball_count: int):
	ball_count = new_ball_count
	color_rect.material.set_shader_parameter("ball_count", ball_count)
	color_rect2.material.set_shader_parameter("ball_count", ball_count)


func update_ball_radii(new_ball_radii: Array[float]):
	ball_radii = new_ball_radii
	var shader_ball_radii = []
	for radius in ball_radii:
		shader_ball_radii.append(radius / canvas_size)

	color_rect.material.set_shader_parameter("ball_radii", shader_ball_radii)
	color_rect2.material.set_shader_parameter("ball_radii", shader_ball_radii)


func update_ball_positions(ball_positions: Array[Vector2]):
	var shader_ball_positions = []
	for pos in ball_positions:
		shader_ball_positions.append(pos / canvas_size + Vector2(0.5, 0.5))

	color_rect.material.set_shader_parameter("ball_positions", shader_ball_positions)
	color_rect2.material.set_shader_parameter("ball_positions", shader_ball_positions)
