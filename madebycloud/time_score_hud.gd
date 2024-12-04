extends Node

@onready var player_one_score: Label = %PlayerOneScore
@onready var player_one_timer: Label = %PlayerOneTimer


func _ready() -> void:
	# Connect to timer updates

	update_score(0)
	update_time(0)



func update_time(time: float) -> void:
	player_one_timer.text = "%02d:%02d" % [int(time / 60), int(time) % 60]


func update_score(scores: float) -> void:
	player_one_score.text = str(scores)
