extends Node2D

signal go_back_to_login

# ========= Old HUD =========
@onready var hud = $HUD
# ===========================

@export var game_music: AudioStream
@export var tutorial_music: AudioStream

@export var screen_center = Vector2(3840.0/2, 2160.0/2)
@export var camera_position = Vector2(1920, 1080):
	set(new_position):
		camera_position = new_position
@export var camera_velocity = 0.0  # 相機當前速度

@export var camera_zoom_level = 1.2
@export var camera_y_threshold = 0.3  # 螢幕 50% 以下時開始加速
@export var camera_smoothing = 0.1    # 相機平滑度 (0-1)
@export var min_camera_speed = 10.0
@export var max_camera_speed = 800.0

@onready var guide_message = $Title
@onready var river_game_1 = $RiverGamePlayerOne
@onready var circular_mask = $CircularMask
@onready var player_waiter = $"1p_player_waiter"
@onready var skip_button = $SkipButton

@export var num_players = 1
@export var num_rivers_scenes = 3

var river_scene_size = Vector2.ZERO

var reversed_spawn_positions: Array[float] = []
var scoring_in_progress = false
var current_scoring_index = 0
var game_mode = true # 遊戲模式，true 為遊戲中，false 為遊戲結束準備計分

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
	skip_button.fade_away(true)

	# 遊戲本體及記分板
	# river_game_1.reset()

	# time_board.reset()
	# time_board.modulate.a = 0
	# time_board.size = Vector2(3840, 2160)
	game_started = false

	# 備用的邏輯
	player_waiter.reset()



func enter_scene():
	visible = true
	_begin_tutorial()

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

var tween

func _begin_tutorial():
	if tween:
		tween.kill()
	tween = create_tween()

	# 在一開始停止執行
	tween.pause()
	GlobalAudioPlayer.play_music(tutorial_music)
	tween.tween_property(self, 'modulate:a', 1, 1)

	# 1. (白底) 歡迎來到蓄電大挑戰! 在這關我們將化身一顆水滴來驅動渦輪發電喔! (3 sec)
	tween.tween_interval(0.5)
	tween.tween_callback(func():_undate_guide_text('begin'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)

	# 接著冒出跳過按鈕
	tween.tween_interval(1)
	tween.tween_callback(skip_button.showup)

	# 開場說明消失往下接續
	tween.tween_interval(1)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)

	# 2. 這一座水力發電廠! 它看起來只是一棟普通的房子對吧!
	tween.tween_callback(func():
		river_game_1.camera_to(screen_center, Vector2(3000, 1080))
		circular_mask.tween_center_radius(Vector2(1200, 1080), 800.0, 1)
	)

	tween.tween_interval(1)
	_show_text('control')

	# 3. 但它其實一點都不普通喔! 在它平淡的外表下\n內部有著很酷的構造喔!
	_show_text('speed')

	# 4. (一語不發移鏡, 然後外殼轉透明)
	tween.tween_callback(func():
		#_undate_guide_text('case')
		river_game_1.camera_to(screen_center, Vector2(1920, 1080))
		circular_mask.tween_center_radius(Vector2(2420, 1080), 800.0, 1)
	)

	tween.tween_interval(1)

	# 5. 在水輪機的強力加持之下, 小小的水滴也可以成為儲能的媒介!
	_show_text('obstacle')

	tween.tween_callback(func():
		river_game_1.camera_to(screen_center, Vector2(2100, 1000), 0.8)
		circular_mask.tween_center_radius(Vector2(1450, 1080), 1000.0, 1.5)
	)

	tween.tween_interval(1.5)

	# 6. 換句話說! 電廠後方山上的水池, 其實也可以被想成是一個電池喔! 
	_show_text('downstream')

	# 8. 現在舉起你的水滴試著畫圓推進它吧!
	tween.tween_callback(func():_undate_guide_text('electron'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	# 這邊比較特別, 文字出來以後不用急著藏

	tween.tween_callback(func():
		player_waiter.set_wait_for_player(true)
	)

	tween.play()

	# 等待產電的信號	
	tween.tween_interval(2)
	await river_game_1.checkpoint_passed
	_continue_tutorial()


var game_started
func _continue_tutorial():
	player_waiter.set_wait_for_player(false)
	if game_started:
		return

	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_interval(0.5)
	
	tween.tween_interval(0.2)
	tween.tween_property(guide_message, 'modulate:a', 0, 0.5)

	tween.tween_interval(0.5)
	_show_text('start', 3)
	tween.tween_interval(0.5)

	tween.tween_callback(func():_proceed_to_game_start())


func _skip_tutorial(_player):
	tween.kill()
	tween = create_tween()

	tween.tween_interval(0.5)
	circular_mask.tween_radius(0.0, 1)
	river_game_1.camera_to(screen_center, Vector2(1920, 1080))

	tween.tween_property(guide_message, 'modulate:a', 0, 1)
	tween.tween_callback(func():_proceed_to_game_start())


func _proceed_to_game_start():
	player_waiter.set_wait_for_player(false)
	if skip_button.sensetive:
		skip_button.fade_away()
	if tween:
		tween.kill()

	tween = create_tween()

	# 9. 既然你已經掌握蓄電之道
	_show_text('ready')

	# 12. 準備開始!!
	_show_text('start')

	# 瞬間關閉圓形遮罩, 慢慢關閉白幕
	# tween.tween_property(time_board, 'modulate:a', 1, 0.5)

	# tween.tween_property(time_board, 'size', Vector2(3840, 400), 1)\
	# 	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# tween.tween_property(circular_mask, 'alpha', 0, 1)


	#tween.tween_interval(0.5)

	tween.tween_callback(func():
		game_started = true
		GlobalAudioPlayer.play_music(game_music)
	)

	



# ================== Tutorial ==================

func _undate_guide_text(new_text_state):
	var titles = {
		'begin': '歡迎來到水流急急棒!',
		'control': '你現在是一顆靈活的水滴!',
		'speed': '水滴的速度很重要喔!',
		'obstacle': '小心前方的障礙物!',
		'downstream': '順著水流而下!',
		'electron': '收集電仔囉!',
		'ready': '準備好了嗎?',
		'start': '開始挑戰!!',
		'congrats': '挑戰完成!',
		'thanks': '感謝你的參與'
	}

	var guides = {
		'begin': '在這關卡中\n我們要順著水流完成發電任務!',
		'control': '擺動你手上的控制器\n就能控制水滴的移動方向!',
		'speed': '水滴移動越快\n經過電廠時就能產生越多電仔喔!',
		'obstacle': '遇到障礙物要小心閃避\n不然會減慢水滴的速度!',
		'downstream': '越往下游水流越快\n但也要更小心控制方向!',
		'electron': '讓電仔獸進入高壓機組\n就能獲得分數了!',
		'ready': '接下來就讓我們開始挑戰吧!',
		'start': '',
		# 'congrats': '你在 ' + str($TimeBoard.total_time) + ' 秒內\n收集了 ' + str(score) + ' 個電仔獸!',
		'thanks': '電幻一號所祝您身體健康, 手腕舒適!'
	}


	var guide_text_positions = {
		'begin' : Vector2(960, 920),
		'control' : Vector2(1800, 920),
		'speed' : Vector2(1800, 920),
		'obstacle': Vector2(-80, 920),
		'downstream' : Vector2(2150, 800),
		'electron': Vector2(2150, 800),
		'stored': Vector2(2150, 800),
		'ready': Vector2(960, 920),
		'start': Vector2(960, 920),
		'thanks':Vector2(960, 920),
	}

	$Title.position = guide_text_positions[new_text_state]
	$Title.text = titles[new_text_state]
	$Title/Label.text = guides[new_text_state]



func _show_text(text_key, duration=2, trans_duration=1):
	tween.tween_callback(func():_undate_guide_text(text_key))
	tween.tween_property(guide_message, 'modulate:a', 1, trans_duration)
	tween.tween_interval(duration)
	tween.tween_property(guide_message, 'modulate:a', 0, trans_duration)
	return tween


# ==============================================

# TODO: level2_1p 和 level2_2p gdscript 可以合併
func _ready():
	var random_river_index = randi() % num_rivers_scenes

	hud.update_minimap(random_river_index)
	
	river_game_1.init(0, num_players, random_river_index) # player_id, num_players, river_index
	river_game_1.camera_to(screen_center, Vector2(1920, 1080), 1, 1)
	river_game_1.finish_line_passed.connect(_on_finish_line_passed)
	river_game_1.spawn_area_scored.connect(_on_spawn_area_scored)
	river_game_1.spawn_area_scoring.connect(_on_spawn_area_scoring)
	river_game_1.checkpoint_passed.connect(_on_checkpoint_passed)
	river_scene_size = river_game_1.get_river_scene_size()

	player_waiter.player_lost_for_too_long.connect(leave_scene_for_restart)

	skip_button.triggered.connect(_skip_tutorial)

	# 測試的時候才會成為 main scene
	if get_tree().current_scene == self:
		enter_scene()

	# AudioManager.play_level_music()

func _process(delta: float) -> void:
	if game_started:
		_update_cameras(delta)
		_update_minimap()

func _update_minimap() -> void:
	var min_camera_y_in_map = camera_position.y - screen_center.y / camera_zoom_level
	var camera_y_size_in_map = screen_center.y * 2 / camera_zoom_level
	var position_ratio = min_camera_y_in_map / (river_scene_size.y - camera_y_size_in_map)
	
	hud.move_1p_minimap_camera(position_ratio, 0.2)

func _update_cameras(delta: float) -> void:
	var screen_height = 2160.0  # 假設這是你的螢幕高度
	var river_game = river_game_1
	var avatar_pos = river_game_1.get_avatar_position()

	# 計算相機移動速度
	var relative_y = avatar_pos.y / screen_height
	var target_speed = lerp(
		min_camera_speed,
		max_camera_speed,
		max(0, (relative_y - camera_y_threshold) / (1 - camera_y_threshold))
	)

	if river_game_1.avatar_is_stuck or river_game_1.avatar_is_separated:
		target_speed = 0.0

	# 平滑過渡到目標速度
	camera_velocity = lerp(camera_velocity, target_speed, camera_smoothing)
	
	if not river_game.is_camera_in_map(camera_position + Vector2(0, camera_velocity * delta), screen_center, camera_zoom_level):
		return

	# 更新相機位置
	camera_position.y += camera_velocity * delta
	river_game.update_camera_velocity(camera_velocity)
	# 調用 camera_to
	river_game.camera_to(
		screen_center,
		camera_position,
		camera_zoom_level,  # 縮放級別
		0.2  # 速度越快，duration 越短
	)

func _on_finish_line_passed(_player_id: int):
	game_mode = false
	TimerManager.stop_timer(TimerManager.TimerType.GAME)
	AudioManager.play_victor_music()

func _on_checkpoint_passed(player_id: int, count: int):
	score[player_id] += count
	hud.update_score_display(score)



# ================= 以下為電仔回收的功能，目前沒用到，備份保留在此

func move_to_next_scoring_position(player_id: int):
	if current_scoring_index >= reversed_spawn_positions.size():
		scoring_in_progress = false
		return
		
	var target_position = Vector2(
		camera_position.x,
		reversed_spawn_positions[current_scoring_index]
	)
	var river_game = river_game_1
	
	# 移動相機到指定位置
	river_game.camera_to(
		screen_center,
		target_position,
		camera_zoom_level,
		1.0,
		func(): _on_camera_reached_scoring_position(player_id)
	)

func _on_camera_reached_scoring_position(_player_id: int):
	if not scoring_in_progress:
		return
		
	# 觸發當前位置的計分
	var spawn_id = reversed_spawn_positions.size() - current_scoring_index - 1
	river_game_1.trigger_spawn_area_scoring(spawn_id)

func _on_spawn_area_scoring(_player_id: int, _spawn_id: int, count: int):
	pass

func _on_spawn_area_scored(_player_id: int, _spawn_id: int):
	current_scoring_index += 1
	move_to_next_scoring_position(_player_id)

func start_scoring_sequence(avatar: Node2D):
	scoring_in_progress = true
	current_scoring_index = 0

	move_to_next_scoring_position(avatar.player_id)
