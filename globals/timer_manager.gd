extends Node

signal tutorial_time_expired
signal game_time_updated(time: float)
signal game_time_expired
signal countdown_time_updated(time: float)
signal countdown_time_expired

enum TimerType {
	TUTORIAL,
	GAME,
	COUNTDOWN
}

# 用來監控其他 timer 的 timer，每 0.1 秒更新一次
var update_timer: Timer 

# 其他 timer 的集合
var timers: Dictionary = {}

func _ready() -> void:
	update_timer = Timer.new()
	update_timer.wait_time = 0.1
	update_timer.one_shot = false
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)

	# Initialize different timer types
	for timer_type in TimerType.values():
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = 1.0
		add_child(timer)
		timers[timer_type] = timer
		
		# Connect signals based on timer type
		match timer_type:
			TimerType.TUTORIAL:
				timer.timeout.connect(_on_tutorial_timer_timeout)
			TimerType.GAME:
				timer.timeout.connect(_on_game_timer_timeout)
			TimerType.COUNTDOWN:
				timer.timeout.connect(_on_countdown_timer_timeout)

func start_tutorial_timer(duration: float) -> void:
	var timer = timers[TimerType.TUTORIAL]
	timer.wait_time = duration
	timer.start()

func start_game_timer(duration: float) -> void:
	var timer = timers[TimerType.GAME]
	timer.wait_time = duration
	timer.start()

func start_countdown_timer(duration: float) -> void:
	var timer = timers[TimerType.COUNTDOWN]
	timer.wait_time = duration
	timer.start()
	update_timer.start()

func get_countdown_timer_time_left() -> float:
	if timers.has(TimerType.COUNTDOWN):
		return timers[TimerType.COUNTDOWN].time_left
	return 0.0

func _on_tutorial_timer_timeout() -> void:
	tutorial_time_expired.emit()

func _on_game_timer_timeout() -> void:
	game_time_expired.emit()

func _on_countdown_timer_timeout() -> void:
	update_timer.stop()
	countdown_time_expired.emit()

func _on_update_timer_timeout() -> void:
	var countdown_timer = timers[TimerType.COUNTDOWN]
	if countdown_timer.time_left > 0:
		countdown_time_updated.emit(countdown_timer.time_left)

func pause_timer(timer_type: TimerType) -> void:
	if timers.has(timer_type):
		timers[timer_type].paused = true

func resume_timer(timer_type: TimerType) -> void:
	if timers.has(timer_type):
		timers[timer_type].paused = false

func stop_timer(timer_type: TimerType) -> void:
	if timers.has(timer_type):
		timers[timer_type].stop()
