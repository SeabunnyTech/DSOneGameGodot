extends Node2D

signal leave_for_level(new_level_name)

# ========= Old HUD =========
@onready var hud = $HUD
# ===========================

@export var num_players = 2
@export var num_rivers_scenes = 3

@export var game_music: AudioStream
@export var tutorial_music: AudioStream
@export var victory_music: AudioStream

@export var screen_center = Vector2(1920.0/2, 2160.0/2)
@export var camera_positions = [Vector2(1920, 1080), Vector2(1920, 1080)]
@export var camera_velocities = [0.0, 0.0]  # 相機當前速度

@export var camera_zoom_level = 0.65
@export var camera_y_threshold = 0.35  # 螢幕 35% 以下時開始加速
@export var camera_smoothing = 0.8    # 相機平滑度 (0-1)
@export var min_camera_speed = 10.0
@export var max_camera_speed = 800.0
var camera_enabled = false

@onready var guide_message = $Title
@onready var circular_mask = $CircularMask
@onready var river_game_1 = $GameScene/RiverGamePlayerOne
@onready var river_game_2 = $GameScene/RiverGamePlayerTwo
@onready var river_games = [river_game_1, river_game_2]
var river_scene_size = Vector2.ZERO

var reversed_spawn_positions: Array[float] = []
var scoring_in_progress = false
var current_scoring_index = 0
var random_river_index = 0

var game_started = false

var score = {0: 0, 1: 0}

# reset 非常重要, 定義了動畫能夠順利執行的起始條件
# 在編輯器預覽的設定和 reset 後的設定可以不一樣
func reset():

	# 隱藏關卡本身
	visible = false

	# 介紹用的訊息與遮罩
	guide_message.modulate.a = 0
	circular_mask.alpha = 0.0
	circular_mask.tween_center_radius(Vector2(1920, 1080), 0.0, 0.0)

	# 遊戲本體
	river_game_1.reset()
	river_game_2.reset()
	
	# time_board.reset()
	# time_board.modulate.a = 0
	# time_board.size = Vector2(3840, 2160)
	score = {0: 0, 1: 0}

	game_started = false
	camera_enabled = false
	camera_positions = [Vector2(1920, 2160), Vector2(1920, 2160)]

func enter_scene():
	visible = true
	game_started = true	
	camera_enabled = true

	num_players = Globals.intended_player_num

	for i in len(river_games):
		river_games[i].init(i, num_players, random_river_index)
		river_games[i].camera_to(screen_center, Vector2(1920, 2160), 0.5, 1)
		river_games[i].start_game()
		river_scene_size = river_games[i].get_river_scene_size()

	TimerManager.start_game_timer(30)
	GlobalAudioPlayer.play_music(game_music)	

var tween
func leave_scene_for_restart():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, 'modulate:a', 0, 1)
	tween.tween_interval(1.5)
	tween.tween_callback(func():
		reset()
		leave_for_level.emit('welcome')
	)

var game_stop_tween
func _game_timeout():
	
	game_started = false
	camera_enabled = false
	
	$long_whistle.play()


	
	
	TimerManager.stop_timer(TimerManager.TimerType.GAME)
	GlobalAudioPlayer.stop()

	GlobalAudioPlayer.play_music(victory_music)
	
	river_game_1.stop_avatar()
	river_game_2.stop_avatar()
	river_game_1.timeout_avatar()
	river_game_2.timeout_avatar()

	var winner_id = 0 if score[0] > score[1] else 1

	# 延遲後退相機畫面
	if game_stop_tween:
		game_stop_tween.kill()
	game_stop_tween = create_tween()

	game_stop_tween.tween_callback(func():
		river_game_1.camera_to(screen_center, Vector2(1920, 1080), 1.0, 4)
		river_game_2.camera_to(screen_center, Vector2(1920, 1080), 1.0, 4)
		if score[0] != score[1]:  # Only show crown if there's a clear winner
			hud.show_crown(winner_id)
	)

	game_stop_tween.tween_interval(7.5)
	game_stop_tween.tween_callback(func():
		hud.hide()
		GlobalAudioPlayer.stop()
		river_game_1.restore_player_size()
		river_game_2.restore_player_size()
		river_game_1.reset()
		river_game_2.reset()
		_congrats_and_return()
	)

func _congrats_and_return():

	var end_duration = 3
	var thanks_duration = 3
	var wait_duration = 2

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_interval(wait_duration)
	_show_text('congrats', end_duration, 1)
	_show_text('thanks')

	if game_stop_tween:
		game_stop_tween.kill()
	game_stop_tween = create_tween()
	game_stop_tween.tween_interval(wait_duration)
	game_stop_tween.tween_property(circular_mask, 'alpha', 1, 1)
	game_stop_tween.tween_interval(end_duration)
	game_stop_tween.tween_interval(thanks_duration)
	game_stop_tween.tween_callback(leave_scene_for_restart)

func _show_text(text_key, duration=2, trans_duration=1):
	tween.tween_callback(func():_undate_guide_text(text_key))
	tween.tween_property(guide_message, 'modulate:a', 1, trans_duration)
	tween.tween_interval(duration)
	tween.tween_property(guide_message, 'modulate:a', 0, trans_duration)
	return tween

func _undate_guide_text(new_text_state):
	var titles = {
		'congrats': '挑戰完成!',
		'thanks': '感謝你們的參與'
	}

	var guides = {
		'congrats': '小水滴在美麗的大甲溪流域產生 ' + str(score[0]) + ' + ' + str(score[1]) + ' 個電仔!',
		'thanks': '電幻 1 號所祝您身體健康!'
	}

	var guide_text_positions = {
		'congrats': Vector2(960, 920),
		'thanks': Vector2(960, 920),
	}

	$Title.position = guide_text_positions[new_text_state]
	$Title.text = titles[new_text_state]
	$Title/Label.text = guides[new_text_state]


func _ready():

	reset()

	random_river_index = randi() % num_rivers_scenes
	
	num_players = Globals.intended_player_num

	for i in len(river_games):
		river_games[i].finish_line_passed.connect(_on_finish_line_passed)
		river_games[i].checkpoint_passed.connect(_on_checkpoint_passed)

	camera_positions = [Vector2(1920, 2160), Vector2(1920, 2160)]
	score = {0: 0, 1: 0}

	hud.update_score_display(score)
	hud.update_minimap(random_river_index)
	hud.display_hud(num_players)
	hud.display_minimap(num_players)
	hud.show()

	TimerManager.game_time_expired.connect(_game_timeout)

	# 測試的時候才會成為 main scene
	if get_tree().current_scene == self:
		enter_scene()

func _process(delta: float) -> void:
	if camera_enabled:	
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

	for i in len(river_games):
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
			0.15  # 速度越快，duration 越短
		)

func _on_finish_line_passed(_player_id: int):
	_game_timeout()

func _on_checkpoint_passed(player_id: int, count: int):
	DebugMessage.info('player_id: %d, count: %d' % [player_id, count])
	if game_started:
		score[player_id] += count
		hud.update_score_display(score)

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
