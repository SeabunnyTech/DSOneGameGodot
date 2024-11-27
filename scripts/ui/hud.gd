extends Node

@onready var player_one_score: Label = %PlayerOneScore
@onready var player_one_timer: Label = %PlayerOneTimer
@onready var player_two_score: Label = %PlayerTwoScore
@onready var player_two_timer: Label = %PlayerTwoTimer

func _ready() -> void:
	# Connect to timer updates
	TimerManager.game_time_updated.connect(_on_game_time_updated)
	
	# Connect to score updates
	ScoreManager.score_updated.connect(_on_score_updated)

	# Initialize displays
	_update_score_display({0: 0, 1: 0})
	_update_timer_display(0)

func _update_timer_display(time: float) -> void:
	# Format time to show one decimal place
	player_one_timer.text = "%02d:%02d" % [int(time / 60), int(time) % 60]

func _update_score_display(scores: Dictionary) -> void:
	player_one_score.text = str(scores[0])
	player_two_score.text = str(scores[1])

func _on_game_time_updated(time: float) -> void:
	_update_timer_display(time)
	
func _on_score_updated(scores: Dictionary) -> void:
	_update_score_display(scores)
