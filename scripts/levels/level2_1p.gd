extends Node2D

@export var num_players = 1
@export var num_rivers_scenes = 3

@export var camera_zoom_level = 1.2
@export var camera_y_threshold = 0.3  # 螢幕 50% 以下時開始加速
@export var camera_smoothing = 0.1    # 相機平滑度 (0-1)
@export var min_camera_speed = 10.0
@export var max_camera_speed = 800.0

@onready var river_game_1 = $RiverGamePlayerOne

@onready var avatar_1 = $WaterAvatar
var avatar_is_stuck = false
var avatar_init_positions = Vector2(2090, 460)

var screen_center = Vector2(3840/2, 2160/2)
var camera_position = Vector2(1920, 1080)
var camera_velocitie = 0.0  # 相機當前速度

# TODO: level2_1p 和 level2_2p gdscript 可以合併
func _ready():
	var random_river_index = randi() % num_rivers_scenes
	
	river_game_1.init(0, num_players, random_river_index)
	river_game_1.camera_to(screen_center, Vector2(1920, 1080), 1, 1)

	avatar_1.init(PlayerManager.current_players[0], avatar_init_positions)
	avatar_1.merged_with_player.connect(_on_avatar_merged)
	avatar_1.separated_from_player.connect(_on_avatar_separated)
	avatar_1.desired_position_changed.connect(_on_avatar_desired_position_changed)


func _process(delta: float) -> void:
	_update_cameras(delta)

func _update_cameras(delta: float) -> void:
	var screen_height = 2160.0  # 假設這是你的螢幕高度
	var river_game = river_game_1
	var player_pos = avatar_1.position

	# 計算相機移動速度
	var relative_y = player_pos.y / screen_height
	var target_speed = lerp(
		min_camera_speed,
		max_camera_speed,
		max(0, (relative_y - camera_y_threshold) / (1 - camera_y_threshold))
	)

	if avatar_is_stuck:
		target_speed = 0.0

	# 平滑過渡到目標速度
	camera_velocitie = lerp(camera_velocitie, target_speed, camera_smoothing)
	
	# 更新相機位置
	camera_position.y += camera_velocitie * delta

	# 確保相機不會落後於玩家太多
	var min_camera_y = player_pos.y - screen_height * 0.7
	camera_position.y = max(camera_position.y, min_camera_y)

	# 調用 camera_to
	river_game.camera_to(
		screen_center,
		camera_position,
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
	var river_game = river_game_1
	
	var avatar_in_river_position = river_game.avatar_in_river_position(
		screen_center,
		camera_position,
		camera_zoom_level,
		new_desired_position)
	var river_normal = river_game.get_color_at_position(avatar_in_river_position)
	
	if river_normal.b > 0.001: # 確保在河道內
		avatar.position = avatar.position.lerp(new_desired_position, 0.5)
		avatar_is_stuck = false
	else:
		avatar_is_stuck = true
