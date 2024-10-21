extends CharacterBody2D

signal countdown_complete
signal countdown_cancelled

@onready var radial_progress: Control = $RadialProgress

var target_position: Vector2 = Vector2(0, 3000)

var is_counting_down: bool = false
# var countdown_duration: float = 3.0  # Adjust this value as needed

# You can add a method to update the target position if needed
func set_target_position(new_position: Vector2):
	target_position = new_position

func _ready() -> void:
	radial_progress.hide()

func _process(_delta: float) -> void:
	if radial_progress.progress >= 100:
		is_counting_down = false
		countdown_complete.emit()
		radial_progress.progress = 0

func start_progress_countdown(time: float = 5.0) -> void:
	print("start_countdown")
	radial_progress.show()
	is_counting_down = true
	radial_progress.animate(time) # clockwise
	radial_progress.progress = 0

func stop_progress_countdown() -> void:
	if is_counting_down:
		is_counting_down = false

	radial_progress.progress = 0
	radial_progress.hide()
	countdown_cancelled.emit()
