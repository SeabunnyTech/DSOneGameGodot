extends Node2D

@export var num_players = 2
@export var num_rivers_scenes = 3

@export var camera_zoom_level = 0.75
@export var min_camera_speed = 10.0
@export var max_camera_speed = 800.0
@export var camera_y_threshold = 0.2  # 螢幕 50% 以下時開始加速
@export var camera_smoothing = 0.1    # 相機平滑度 (0-1)

@onready var river_game_1 = $GameScene/RiverGamePlayerOne
@onready var river_game_2 = $GameScene/RiverGamePlayerTwo
@onready var river_games = [river_game_1, river_game_2]

var screen_center = Vector2(1920/2, 2160/2)
var camera_positions = [Vector2(1920, 2160), Vector2(1920, 2160)]
var camera_velocities = [0.0, 0.0]  # 相機當前速度

var player_in_river_positions = [Vector2(0, 0), Vector2(0, 0)]
var player_is_stuck = [false, false]

func _ready():
	var random_river_index = randi() % num_rivers_scenes
	
	for i in range(num_players):
		river_games[i].init(i, num_players, random_river_index)
		river_games[i].camera_to(screen_center, Vector2(1920, 2160), 0.5, 1)

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void: 
	for i in range(num_players):
		var normal = river_games[i].get_color_at_position(player_in_river_positions[i])

		player_is_stuck[i] = true if normal.b < 0.01 else false

		PlayerManager.current_players[i].set_smoothing_speed(10.0 * normal.b)
		DebugMessage.info(str(PlayerManager.current_players[i].name) + " : current_speed: " + str(30.0 * normal.b) + ", stuck: " + str(player_is_stuck[i]))
	
	_update_player_in_river_positions()
	_update_cameras(delta)

func _update_player_in_river_positions() -> void:
	for i in range(num_players):
		player_in_river_positions[i] = river_games[i].player_in_river_position(
			screen_center,
			camera_positions[i],
			camera_zoom_level,
			PlayerManager.current_players[i].target_position)

func _update_cameras(delta: float) -> void:
	var screen_height = 2160.0  # 假設這是你的螢幕高度

	for i in range(num_players):
		var river_game = river_game_1 if i == 0 else river_game_2
		var player_pos = PlayerManager.current_players[i].target_position

		# 計算相機移動速度
		var relative_y = player_pos.y / screen_height
		var target_speed = lerp(
			min_camera_speed,
			max_camera_speed,
			max(0, (relative_y - camera_y_threshold) / (1 - camera_y_threshold))
		)

		if player_is_stuck[i]:
			target_speed = 0.0

		# 平滑過渡到目標速度
		camera_velocities[i] = lerp(camera_velocities[i], target_speed, camera_smoothing)
		
		# 更新相機位置
		camera_positions[i].y += camera_velocities[i] * delta

		# 確保相機不會落後於玩家太多
		var min_camera_y = player_pos.y - screen_height * 0.7
		camera_positions[i].y = max(camera_positions[i].y, min_camera_y)

		# 調用 camera_to
		river_game.camera_to(
			screen_center,
			camera_positions[i],
			camera_zoom_level,  # 縮放級別
			0.2  # 速度越快，duration 越短
		)
