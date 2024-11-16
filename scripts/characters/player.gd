extends CharacterBody2D

signal countdown_complete(player: Node2D)
signal countdown_cancelled(player: Node2D)

signal full_rotation_completed(player: Node2D, clockwise: bool)
signal rotation_detected(player: Node2D, clockwise: bool, speed: float)


enum PlayerState {
	ACTIVE,			# 球被手持, 等待動作中
	FADING_OUT,		# 系統注意到球消失或放地上, 正在通往 FADED 狀態
	FADED,			# 球放太低但是有感應到 (在地上)
	LOST,			# 沒有感應到所以消失了
	FADING_IN,		# 球被拿起來正在恢復 ACTIVE 的路上
	TRIGGERING,		# 球正在觸發某種開關, 通往 TRIGGERED 的路上
	UNTRIGGERING,	# 球剛離開某種觸發到一半的開關正在回到 ACTIVE 狀態的路上
	TRIGGERED,		# 剛剛成功觸發了某件事
	RECOVERING		# 正在從 TRIGGERED 慶祝狀態回到 ACTIVE 的路上
}

var state: PlayerState = PlayerState.LOST

@onready var radial_progress: Control = $RadialProgress

var is_counting_down: bool = false
# var countdown_duration: float = 3.0  # Adjust this value as needed

var selected_level: String = ""
var target_position: Vector2 = Vector2(0, 3000)


# You can add a method to update the target position if needed
func set_target_position(new_position: Vector2):
	target_position = new_position


@export var smoothing_speed: float = 30.0

func _physics_process(delta: float):
	position = position.lerp(target_position, smoothing_speed * delta)


func _ready() -> void:
	$Motion/Angular.connect("full_rotation_completed", full_rotation_completed.emit)
	$Motion/Angular.connect("rotation_detected", rotation_detected.emit)	
	radial_progress.hide()


func _process(_delta: float) -> void:
	if radial_progress.progress >= 100:
		radial_progress.progress = 0
		if is_counting_down:
			is_counting_down = false
			countdown_complete.emit(self)


func set_color(new_color):
	$HintCircle2D.circle_color = new_color


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
