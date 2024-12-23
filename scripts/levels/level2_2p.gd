extends Node2D

signal go_back_to_login

# ========= Old HUD =========
@onready var hud = $HUD
# ===========================

@export var num_players = 2
@export var num_rivers_scenes = 3

@export var game_music: AudioStream
@export var tutorial_music: AudioStream
@export var victory_music: AudioStream

@export var screen_center = Vector2(1920.0/2, 2160.0/2)
@export var camera_positions = [Vector2(1920, 2160), Vector2(1920, 2160)]
@export var camera_velocities = [0.0, 0.0]  # 相機當前速度

@export var camera_zoom_level = 0.65
@export var camera_y_threshold = 0.35  # 螢幕 35% 以下時開始加速
@export var camera_smoothing = 0.1    # 相機平滑度 (0-1)
@export var min_camera_speed = 10.0
@export var max_camera_speed = 800.0
var camera_enabled = [false, false]

@onready var guide_message = $Title
@onready var circular_mask = $CircularMask
@onready var river_game_1 = $GameScene/RiverGamePlayerOne
@onready var river_game_2 = $GameScene/RiverGamePlayerTwo
@onready var river_games = [river_game_1, river_game_2]
var river_scene_size = Vector2.ZERO

var reversed_spawn_positions: Array[float] = []
var scoring_in_progress = false
var current_scoring_index = 0

var game_started = false

var score = {0: 0, 1: 0}

# reset 非常重要, 定義了動畫能夠順利執行的起始條件
# 在編輯器預覽的設定和 reset 後的設定可以不一樣
func reset():

	# 隱藏關卡本身
	visible = false
	modulate.a = 0

	# 介紹用的訊息與遮罩
	guide_message.modulate.a = 0
	circular_mask.alpha = 1.0
	circular_mask.tween_center_radius(Vector2(1920, 1080), 0.0, 0.0)

	# 遊戲本體
	river_game_1.reset()
	river_game_2.reset()
	# time_board.reset()
	# time_board.modulate.a = 0
	# time_board.size = Vector2(3840, 2160)
	game_started = false
	camera_enabled = false
	camera_positions = [Vector2(1920, 2160), Vector2(1920, 2160)]


func enter_scene():
	visible = true
	river_game_1.init(0, num_players, 1) # 初始化 river_2 給 tutorial 用

var tween
func leave_scene_for_restart():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, 'modulate:a', 0, 1)
	tween.tween_interval(1.5)
	tween.tween_callback(func():
		reset()
		go_back_to_login.emit()
	)


func _ready():
	var random_river_index = randi() % num_rivers_scenes
	
	for i in range(num_players):
		hud.update_minimap(random_river_index)

		river_games[i].init(i, num_players, random_river_index)
		river_games[i].camera_to(screen_center, Vector2(1920, 2160), 0.5, 1)
		river_games[i].finish_line_passed.connect(_on_finish_line_passed)
		# river_games[i].spawn_area_scored.connect(_on_spawn_area_scored)
		# river_games[i].spawn_area_scoring.connect(_on_spawn_area_scoring)

		river_scene_size = river_games[i].get_river_scene_size()

		AudioManager.play_level_music()
		
func _process(delta: float) -> void:
	if game_started:	
		_update_cameras(delta)
		_update_minimap()

func _update_minimap() -> void:
	for i in range(num_players):
		var min_camera_y_in_map = camera_positions[i].y - screen_center.y / camera_zoom_level
		var camera_y_size_in_map = screen_center.y * 2 / camera_zoom_level
		var position_ratio = min_camera_y_in_map / (river_scene_size.y - camera_y_size_in_map)

		hud.move_2p_minimap_camera(i, position_ratio, 0.2)

func _update_cameras(delta: float) -> void:
	var screen_height = 2160.0  # 假設這是你的螢幕高度

	for i in range(num_players):
		var river_game = river_games[i]
		var avatar_pos = river_game.get_avatar_position()

		# 計算相機移動速度
		var relative_y = avatar_pos.y / screen_height
		var target_speed = lerp(
			min_camera_speed,
			max_camera_speed,
			max(0, (relative_y - camera_y_threshold) / (1 - camera_y_threshold))
		)

		if river_game.avatar_is_stuck or river_game.avatar_is_separated:
			target_speed = 0.0

		# 平滑過渡到目標速度
		camera_velocities[i] = lerp(camera_velocities[i], target_speed, camera_smoothing)
		
		if not river_game.is_camera_in_map(
			camera_positions[i] + Vector2(0, camera_velocities[i] * delta),
			screen_center,
			camera_zoom_level
		):
			return

		# 更新相機位置
		camera_positions[i].y += camera_velocities[i] * delta
		river_game.update_camera_velocity(camera_velocities[i])

		# 調用 camera_to
		river_game.camera_to(
			screen_center,
			camera_positions[i],
			camera_zoom_level,  # 縮放級別
			0.2  # 速度越快，duration 越短
		)

func _on_finish_line_passed(player_id: int):
	game_started = false

func _on_game_scoring(avatar: Node2D):
	pass

# func _on_avatar_merged(avatar: Node2D):
# 	avatar_is_separated[avatar.player_id] = false
# 	for i in range(num_players):
# 		PlayerManager.current_players[i].reset_attractor()

# func _on_avatar_separated(avatar: Node2D):
# 	avatar_is_separated[avatar.player_id] = true
# 	for i in range(num_players):
# 		PlayerManager.current_players[i].set_attractor(avatars[i].position, 100)	

# func _on_avatar_desired_position_changed(avatar: Node2D, new_desired_position: Vector2):
# 	var avatar_index = 0 if avatar == avatar_1 else 1
# 	var river_game = river_games[avatar_index]
	
# 	var avatar_in_river_position = river_game.avatar_in_river_position(
# 		screen_center,
# 		camera_positions[avatar_index],
# 		camera_zoom_level,
# 		new_desired_position)
# 	var river_normal = river_game.get_color_at_position(avatar_in_river_position)
	
# 	if river_normal.b > 0.001: # 確保在河道內
# 		avatar.position = avatar.position.lerp(new_desired_position, 0.5)
# 		avatar_is_stuck[avatar_index] = false
# 	else:
# 		avatar_is_stuck[avatar_index] = true















# ================= 以下為電仔回收的功能，目前沒用到，備份保留在此


# func start_scoring_sequence(avatar: Node2D):
# 	scoring_in_progress = true
# 	current_scoring_index = 0

# 	move_to_next_scoring_position(avatar.player_id)

# func move_to_next_scoring_position(player_id: int):
# 	if current_scoring_index >= reversed_spawn_positions.size():
# 		scoring_in_progress = false
# 		return
		
# 	var target_position = Vector2(
# 		camera_positions[player_id].x,
# 		reversed_spawn_positions[current_scoring_index]
# 	)
# 	var river_game = river_games[player_id]
	
# 	# 移動相機到指定位置
# 	river_game.camera_to(
# 		screen_center,
# 		target_position,
# 		camera_zoom_level,
# 		1.0,
# 		func(): _on_camera_reached_scoring_position(player_id)
# 	)

# func _on_camera_reached_scoring_position(player_id: int):
# 	if not scoring_in_progress:
# 		return
		
# 	# 觸發當前位置的計分
# 	var spawn_id = reversed_spawn_positions.size() - current_scoring_index - 1
# 	river_games[player_id].trigger_spawn_area_scoring(spawn_id)

# func _on_spawn_area_scored(player_id: int, _spawn_id: int):
# 	current_scoring_index += 1
# 	move_to_next_scoring_position(player_id)

# func _on_spawn_area_scoring(player_id: int, _spawn_id: int, count: int):
# 	pass
