extends Node2D

signal leave_for_level(new_scene_name)

@export var wind_strength_factor: float = 0.5

var linear_motion_node: Node


@onready var solarfarm_env = $SolarfarmEnv
@onready var player = PlayerManager.player1
func _ready() -> void:

	reset()
	# 測試的時候才會成為 main scene
	if get_tree().current_scene == self:
		enter_scene()

func enter_scene():
	# 設定玩家外觀
	var players = PlayerManager.current_players
	for p in players:
		p.set_visual_mode(true)
	
	# 連接玩家移動信號以產生風
	PlayerManager.player1.linear_movement_detected.connect(_on_player_linear_movement)


func reset():
	# 重設玩家外觀
	var players = PlayerManager.current_players
	for p in players:
		p.set_visual_mode(false, 0.0) # Immediately switch back


func _on_player_linear_movement(_player, speed: float):
	solarfarm_env.add_wind_speed(speed)
