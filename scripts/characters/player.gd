extends CharacterBody2D

signal countdown_complete(player: Node2D)
signal countdown_cancelled(player: Node2D)

signal rotation_detected(player: Node2D, clockwise: bool, speed: float)
signal full_rotation_completed(player: Node2D, clockwise: bool)

@onready var radial_progress: Control = $RadialProgress

var is_counting_down: bool = false
# var countdown_duration: float = 3.0  # Adjust this value as needed

var selected_level: String = ""
var target_position: Vector2 = Vector2(0, 3000)

var previous_position: Vector2
var previous_positions: Array[Vector2] = []

var position_buffer_size: int = 10  # Adjust for speed sensitivity
var min_speed_threshold: float = 0.0  # Minimum speed to trigger rotation
var max_speed_threshold: float = 100.0  # Maximum speed to normalize
var accumulated_rotation: float = 0.0
var rotation_threshold: float = TAU  # 2π, one full rotation
var min_vector_length: float = 35.0
var min_angle_threshold: float = 5.0

# You can add a method to update the target position if needed
func set_target_position(new_position: Vector2):
	target_position = new_position

func _ready() -> void:
	radial_progress.hide()

func _process(_delta: float) -> void:
	if radial_progress.progress >= 100:
		radial_progress.progress = 0
		if is_counting_down:
			is_counting_down = false
			countdown_complete.emit(self)

func set_color(new_color):
	$HintCircle2D.circle_color = new_color

func _physics_process(_delta):
	if previous_position.length() - position.length() > min_vector_length:
		detect_rotation_with_speed()
	
	# Update position history
	if position != Vector2.ZERO:
		previous_positions.push_back(position)
		if previous_positions.size() > position_buffer_size:
			previous_positions.pop_front()
		
		previous_position = position

func detect_rotation_with_speed():
	# Calculate average movement over recent positions
	var total_movement = Vector2.ZERO
	var rotation_sum = 0.0
	
	# Need at least 3 points to calculate rotation
	if previous_positions.size() > 3:
		# Calculate rotation by comparing consecutive movement vectors
		for i in range(previous_positions.size() - 2):
			var pos1 = previous_positions[i]
			var pos2 = previous_positions[i + 1]
			var pos3 = previous_positions[i + 2]
			
			# Get two consecutive movement vectors
			var vector1 = pos2 - pos1
			var vector2 = pos3 - pos2

			if vector1.length() < min_vector_length or vector2.length() < min_vector_length:
				continue

			# Cross product of consecutive movement vectors determines rotation direction
			var cross_product = vector1.cross(vector2)
			var dot_product = vector1.dot(vector2)
			var angle = atan2(cross_product, dot_product)

			if abs(rad_to_deg(angle)) < min_angle_threshold:
				continue
				
			rotation_sum += cross_product
			total_movement += vector2
			
			# Accumulate rotation based on cross product
			accumulated_rotation += angle

			# Check if we've completed a full rotation
			if abs(accumulated_rotation) >= rotation_threshold:
				var is_clockwise = accumulated_rotation > 0
				full_rotation_completed.emit(self, is_clockwise)
				# Reset accumulated rotation but keep the remainder
				accumulated_rotation = fmod(accumulated_rotation, rotation_threshold)
	
	# Calculate average speed
	var speed = total_movement.length() / position_buffer_size

	# Normalize speed between 0 and 1
	speed = clamp((speed - min_speed_threshold) / (max_speed_threshold - min_speed_threshold), 0.0, 1.0)
	
	# Only emit if we're moving fast enough
	if speed > 0.05:
		var is_clockwise = rotation_sum > 0
		rotation_detected.emit(self, is_clockwise, speed)

func start_progress_countdown(time: float = 5.0) -> void:
	radial_progress.show()
	is_counting_down = true
	radial_progress.animate(time) # clockwise
	radial_progress.progress = 0

func stop_progress_countdown() -> void:
	if is_counting_down:
		is_counting_down = false

	radial_progress.progress = 0
	radial_progress.hide()
	countdown_cancelled.emit(self)
