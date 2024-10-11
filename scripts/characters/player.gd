extends Node2D

var target_position: Vector2 = Vector2(0, 3000)

# You can add a method to update the target position if needed
func set_target_position(new_position: Vector2):
	target_position = new_position
