extends Node

signal full_rotation_completed(player: Node2D, clockwise: bool)
signal rotation_detected(player: Node2D, clockwise: bool, speed: float)

var previous_position: Vector2
var previous_positions: Array[Vector2] = []

@export var min_vector_length: float = 35.0

@export var min_angle_threshold: float = 5.0
@export var min_speed_threshold: float = 0.0  # Minimum speed to trigger rotation
@export var max_speed_threshold: float = 100.0  # Maximum speed to normalize
@export var rotation_threshold: float = TAU  # 2π, one full rotation

var accumulated_rotation: float = 0.0

var node2d_root

func _ready() -> void:
	node2d_root =  get_node2d_root()


func get_node2d_root():
	var node2d_parent = get_parent()
	while node2d_parent and not node2d_parent is Node2D:
		node2d_parent = node2d_parent.get_parent()

	return node2d_parent


func _physics_process(_delta):

	var position = node2d_root.position
	if (previous_position - position).length() > min_vector_length:
		detect_rotation_with_speed()
	
	# Update position history
	if position != Vector2.ZERO:
		previous_positions.push_back(position)
		if previous_positions.size() > 3:
			previous_positions.pop_front()
		
		previous_position = position


func detect_rotation_with_speed():
	# Calculate average movement over recent positions

	var total_movement = Vector2.ZERO
	var rotation_sum = 0.0
	
	# Need at least 3 points to calculate rotation
	if len(previous_positions) < 3:
		return

	var pos1 = previous_positions[0]
	var pos2 = previous_positions[1]
	var pos3 = previous_positions[2]
	
	# Get two consecutive movement vectors
	var vector1 = pos2 - pos1
	var vector2 = pos3 - pos2

	if vector1.length() < min_vector_length or vector2.length() < min_vector_length:
		return

	# Cross product of consecutive movement vectors determines rotation direction
	var cross_product = vector1.cross(vector2)
	var dot_product = vector1.dot(vector2)
	var angle = atan2(cross_product, dot_product)

	if abs(rad_to_deg(angle)) < min_angle_threshold:
		return
		
	rotation_sum += cross_product
	total_movement += vector2
	
	# Accumulate rotation based on cross product
	accumulated_rotation += angle

	# Check if we've completed a full rotation
	if abs(accumulated_rotation) >= rotation_threshold:
		var is_clockwise = accumulated_rotation > 0
		full_rotation_completed.emit(node2d_root, is_clockwise)
		# Reset accumulated rotation but keep the remainder
		accumulated_rotation = fmod(accumulated_rotation, rotation_threshold)

	# Calculate average speed
	var speed = total_movement.length() / 2

	# Normalize speed between 0 and 1
	speed = clamp((speed - min_speed_threshold) / (max_speed_threshold - min_speed_threshold), 0.0, 1.0)
	
	# Only emit if we're moving fast enough
	if speed > 0.05:
		var is_clockwise = rotation_sum > 0
		rotation_detected.emit(node2d_root, is_clockwise, speed)
