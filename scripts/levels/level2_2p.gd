extends Node2D

@export var num_players = 2
@export var num_rivers_scenes = 3

@export var camera_zoom_level = 0.65
@export var camera_y_threshold = 0.4  # 螢幕 40% 以下時開始加速
@export var camera_smoothing = 0.1    # 相機平滑度 (0-1)
@export var min_camera_speed = 10.0
@export var max_camera_speed = 800.0

@export var screen_center = Vector2(1920.0/2, 2160.0/2)
@export var camera_positions = [Vector2(1920, 2160), Vector2(1920, 2160)]
@export var camera_velocities = [0.0, 0.0]  # 相機當前速度

@onready var river_game_1 = $GameScene/RiverGamePlayerOne
@onready var river_game_2 = $GameScene/RiverGamePlayerTwo
@onready var river_games = [river_game_1, river_game_2]

@onready var avatar_1 = $WaterAvatar
@onready var avatar_2 = $WaterAvatar2
@onready var avatars = [avatar_1, avatar_2]
@export var avatar_init_positions = [Vector2(1045, 460.0/2), Vector2(2965, 460.0/2)]
var avatar_is_stuck = [false, false]

# TODO: level2_1p 和 level2_2p gdscript 可以合併
func _ready():
	var random_river_index = randi() % num_rivers_scenes
	
	for i in range(num_players):
		river_games[i].init(i, num_players, random_river_index)
		river_games[i].camera_to(screen_center, Vector2(1920, 2160), 0.5, 1)

		avatars[i].init(PlayerManager.current_players[i], avatar_init_positions[i])
		avatars[i].merged_with_player.connect(_on_avatar_merged)
		avatars[i].separated_from_player.connect(_on_avatar_separated)
		avatars[i].desired_position_changed.connect(_on_avatar_desired_position_changed)

func _process(delta: float) -> void:
	_update_cameras(delta)

func _update_cameras(delta: float) -> void:
	var screen_height = 2160.0  # 假設這是你的螢幕高度

	for i in range(num_players):
		var river_game = river_games[i]
		var avatar_pos = avatars[i].position

		# 計算相機移動速度
		var relative_y = avatar_pos.y / screen_height
		var target_speed = lerp(
			min_camera_speed,
			max_camera_speed,
			max(0, (relative_y - camera_y_threshold) / (1 - camera_y_threshold))
		)

		if avatar_is_stuck[i]:
			target_speed = 0.0

		# 平滑過渡到目標速度
		camera_velocities[i] = lerp(camera_velocities[i], target_speed, camera_smoothing)
		
		if not river_game.is_camera_in_map(camera_positions[i] + Vector2(0, camera_velocities[i] * delta), screen_center, camera_zoom_level):
			return

		# 更新相機位置
		camera_positions[i].y += camera_velocities[i] * delta

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
