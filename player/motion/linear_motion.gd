class_name LinearMotion
extends Node

# Emitted every frame there is significant horizontal movement.
# direction is -1.0 for left, 1.0 for right.
signal linear_movement_detected(player:Node2D, speed: float)

# Emitted after a quick, continuous movement in one direction exceeds a distance threshold.
signal linear_burst_triggered(player:Node2D, distance: float, average_speed)

# Emitted once when horizontal movement stops.
signal linear_movement_stopped()

@export var enabled: bool = true:
	set(value):
		enabled = value
		if not enabled:
			_reset_state()

# The minimum horizontal speed (pixels/sec) to be considered movement.
@export var speed_threshold: float = 50.0

# The horizontal distance (pixels) that must be traveled to trigger a burst.
@export var burst_distance_threshold: float = 200.0

# If movement stops for more than this time (seconds), the burst accumulation resets.
@export var burst_time_limit: float = 0.3

var previous_x_position: float = 0.0
var is_initialized: bool = false
var was_moving: bool = false

# --- Burst tracking variables ---
var burst_distance_accumulator: float = 0.0
var burst_speed_accumulator: float = 0.0
var burst_sample_count: int = 0
var time_since_last_move: float = 0.0
var last_move_direction: float = 0.0


var node2d_root

func _ready() -> void:
	node2d_root =  get_node2d_root()


func get_node2d_root():
	var node2d_parent = get_parent()
	while node2d_parent and not node2d_parent is Node2D:
		node2d_parent = node2d_parent.get_parent()

	return node2d_parent



func _physics_process(delta: float):
	if not enabled:
		return

	var current_x_position: float = node2d_root.global_position.x
	var delta_x: float = current_x_position - previous_x_position
	var current_speed: float = delta_x / delta

	var is_moving_now: bool = abs(current_speed) > speed_threshold

	if is_moving_now:
		time_since_last_move = 0.0
		var current_direction: float = sign(delta_x)
		linear_movement_detected.emit(node2d_root, current_speed)
		
		# --- Burst Logic ---
		# If direction changes, reset burst accumulation.
		if current_direction != last_move_direction and last_move_direction != 0.0:
			_reset_burst_state()
		
		last_move_direction = current_direction
		burst_distance_accumulator += abs(delta_x)
		burst_speed_accumulator += current_speed
		burst_sample_count += 1
		
		if burst_distance_accumulator >= burst_distance_threshold:
			var average_speed = burst_speed_accumulator / float(burst_sample_count)
			linear_burst_triggered.emit(node2d_root, burst_distance_accumulator, average_speed)
			_reset_burst_state()

	else:
		time_since_last_move += delta
		if time_since_last_move > burst_time_limit:
			_reset_burst_state()
			
		if was_moving:
			emit_signal("linear_movement_stopped")

	was_moving = is_moving_now
	previous_x_position = current_x_position




func _reset_state():
	was_moving = false
	_reset_burst_state()


func _reset_burst_state():
	burst_distance_accumulator = 0.0
	burst_speed_accumulator = 0.0
	burst_sample_count = 0
	last_move_direction = 0.0
