extends Node2D

@export var num_players = 2
@export var num_rivers_scenes = 3

@export var camera_zoom_level = 0.65
@export var min_camera_speed = 10.0
@export var max_camera_speed = 800.0
@export var camera_y_threshold = 0.2  # 螢幕 50% 以下時開始加速
@export var camera_smoothing = 0.1    # 相機平滑度 (0-1)

@onready var river_game_1 = $GameScene/RiverGamePlayerOne
@onready var river_game_2 = $GameScene/RiverGamePlayerTwo
@onready var river_games = [river_game_1, river_game_2]

@onready var avatar_1 = $WaterAvatar
@onready var avatar_2 = $WaterAvatar2
@onready var avatars = [avatar_1, avatar_2]
var avatar_is_stuck = [false, false]
var avatar_init_positions = [Vector2(1045, 460/2), Vector2(2965, 460/2)]

var screen_center = Vector2(1920/2, 2160/2)
var camera_positions = [Vector2(1920, 2160), Vector2(1920, 2160)]
var camera_velocities = [0.0, 0.0]  # 相機當前速度
# TODO: 設定相機邊界範圍

var player_in_river_positions = [Vector2(0, 0), Vector2(0, 0)]

func _ready():
	var random_river_index = randi() % num_rivers_scenes
	
	for i in range(num_players):
		river_games[i].init(i, num_players, random_river_index)
		avatars[i].init(PlayerManager.current_players[i], avatar_init_positions[i])
		avatars[i].merged_with_player.connect(_on_avatar_merged)
		avatars[i].separated_from_player.connect(_on_avatar_separated)
		avatars[i].desired_position_changed.connect(_on_avatar_desired_position_changed)

		river_games[i].camera_to(screen_center, Vector2(1920, 2160), 0.5, 1)

func _process(delta: float) -> void:
	# _update_player_in_river_positions()
	_update_cameras(delta)

# func _update_player_in_river_positions() -> void:
# 	for i in range(num_players):
# 		player_in_river_positions[i] = river_games[i].player_in_river_position(
# 			screen_center,
# 			camera_positions[i],
# 			camera_zoom_level,
# 			avatars[i].position)

func _update_cameras(delta: float) -> void:
	var screen_height = 2160.0  # 假設這是你的螢幕高度

	for i in range(num_players):
		var river_game = river_game_1 if i == 0 else river_game_2
		var player_pos = avatars[i].position

		# 計算相機移動速度
		var relative_y = player_pos.y / screen_height
		var target_speed = lerp(
			min_camera_speed,
			max_camera_speed,
			max(0, (relative_y - camera_y_threshold) / (1 - camera_y_threshold))
		)

		if avatar_is_stuck[i]:
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

func _on_avatar_merged(avatar: Node2D):
	pass
	# DebugMessage.info("avatar merged")

func _on_avatar_separated(avatar: Node2D):
	pass
	# DebugMessage.info("avatar separated")

func _on_avatar_desired_position_changed(avatar: Node2D, new_desired_position: Vector2):
	var avatar_index = 0 if avatar == avatar_1 else 1
	var river_game = river_games[avatar_index]
	
	var avatar_in_river_position = river_game.avatar_in_river_position(
		screen_center,
		camera_positions[avatar_index],
		camera_zoom_level,
		new_desired_position)
	var river_normal = river_game.get_color_at_position(avatar_in_river_position)
	
	if river_normal.b > 0.001: # 確保在河道內
		avatar.position = avatar.position.lerp(new_desired_position, 0.5)
		avatar_is_stuck[avatar_index] = false
	else:
		avatar_is_stuck[avatar_index] = true



# ==============================
# 以下是玩家固定於畫面中間的作法，目前擱置並考慮不使用
# func _update_cameras(delta: float) -> void:

# 	for i in range(num_players):
# 		var player_pos = screen_center + river_games[i].position
# 		var target_speed = 0.5
# 		var player_controller = PlayerManager.current_players[i].target_position
# 		DebugMessage.info("player_controller: " + str(player_controller))
# 		player_in_river_positions[i] = river_games[i].player_in_river_position(
# 			screen_center,
# 			camera_positions[i],
# 			camera_zoom_level,
# 			player_pos)
# 		if player_is_stuck[i]:
# 			target_speed = 0.1

	
# 		camera_positions[i] += (player_controller - player_pos) * target_speed * delta

# 		river_games[i].camera_to(
# 			screen_center,
# 			camera_positions[i],
# 			camera_zoom_level,  # 縮放級別
# 			0.2  # 速度越快，duration 越短
# 		)
