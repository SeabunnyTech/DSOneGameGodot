extends Node2D

signal go_back_to_login

# ========= Old HUD =========
@onready var hud = $HUD
# ===========================

@export var game_music: AudioStream
@export var tutorial_music: AudioStream
@export var victory_music: AudioStream

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
var camera_enabled = false

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

	# 遊戲本體
	river_game_1.reset()

	# time_board.reset()
	# time_board.modulate.a = 0
	# time_board.size = Vector2(3840, 2160)
	game_started = false
	camera_enabled = false

	# 備用的邏輯
	player_waiter.reset()


func enter_scene():
	visible = true
	river_game_1.init(0, num_players, 1) # 初始化 river_2 給 tutorial 用
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
	river_game_1.init_player()

	if tween:
		tween.kill()
	tween = create_tween()

	# 在一開始停止執行
	tween.pause()
	hud.hide()

	GlobalAudioPlayer.play_music(tutorial_music)
	tween.tween_property(self, 'modulate:a', 1, 1)

	# 1. (白底) 歡迎來到水流急急棒! 在這關我們要順著水流完成發電任務! (3 sec)
	tween.tween_interval(0.5)
	tween.tween_callback(func():_undate_guide_text('begin'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)

	# 接著冒出跳過按鈕
	tween.tween_callback(func():
		skip_button.showup()
	)

	# 開場說明消失往下接續
	
	tween.tween_interval(1)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)

	# 2. 擺動你手上的控制器，吸附到上方閃爍的水滴就能控制方向!
	tween.tween_callback(func():
		river_game_1.show_avatar()
		river_game_1.camera_to(screen_center, Vector2(1920, 1080), 1.1)
		circular_mask.tween_center_radius(Vector2(1920, 800), 700.0, 1)
	)

	tween.tween_callback(func():
		_undate_guide_text('control')
	)
	
	tween.tween_property(guide_message, 'modulate:a', 1, 1)

	tween.play()

	# 等待產電的信號	
	tween.tween_interval(2)

	await river_game_1.avatar_merged
	_continue_tutorial_1()

func _continue_tutorial_1():
	if game_started:
		return

	if tween:
		tween.kill()

	tween = create_tween()

	tween.tween_interval(0.5)
	
	tween.tween_callback(func():
		river_game_1.show_avatar()
		river_game_1.camera_to(screen_center, Vector2(1920, 1080), 1.15)
		circular_mask.tween_center_radius(Vector2(2160, 800), 500.0, 1.5)
	)

	# 3. 遇到障礙物要小心閃避\n不然會減慢水滴的速度!
	_show_text('obstacle')

	tween.tween_callback(func():
		river_game_1.camera_to(screen_center, Vector2(1920, 1080), 1)
		circular_mask.tween_center_radius(Vector2(1450, 1080), 1000.0, 1)
	)


	tween.tween_interval(0.5)

	# 4. 水滴移動越快，經過電廠時就能產生越多電仔喔!
	tween.tween_callback(func():
		river_game_1.enable_checkpoint()
		_undate_guide_text('speed')
	)
	
	tween.tween_property(guide_message, 'modulate:a', 1, 1)

	tween.tween_interval(1)
	tween.play()
	
	await river_game_1.checkpoint_passed
	_continue_tutorial_2()


var game_started
func _continue_tutorial_2():
	if game_started:
		return
	if tween:
		tween.kill()

	tween = create_tween()

	# 5. 越往下游水流越快，但也要更小心控制方向!
	camera_enabled = true

	tween.tween_callback(func():
		river_game_1.camera_to(screen_center, Vector2(1920, 1080), 1)
		circular_mask.tween_center_radius(Vector2(1920, 2160), 1800.0, 0.5)
	)

	_show_text('downstream')

	tween.tween_interval(0.5)
	tween.tween_callback(func():
		circular_mask.tween_center_radius(Vector2(1920, 2160), 1800.0, 0.5)
	)

	# 6.經過了這麼多電廠，發現原來一滴水可以發很多次電!
	tween.tween_callback(func():_undate_guide_text('electron'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)

	# 這邊比較特別, 文字出來以後不用急著藏
	tween.tween_callback(func():
		player_waiter.set_wait_for_player(true)
	)

	tween.tween_interval(5)
	
	tween.tween_property(guide_message, 'modulate:a', 0, 0.5)

	tween.tween_callback(func():_proceed_to_game_start())


func _skip_tutorial(_player):
	if tween:
		tween.kill()

	tween = create_tween()

	tween.tween_interval(0.5)
	circular_mask.tween_radius(0.0, 1)
	river_game_1.camera_to(screen_center, Vector2(1920, 1080))

	tween.tween_property(guide_message, 'modulate:a', 0, 1)
	tween.tween_callback(func():_proceed_to_game_start())


func _proceed_to_game_start():
	if tween:
		tween.kill()

	tween = create_tween()
	
	player_waiter.set_wait_for_player(false)

	if skip_button.sensetive:
		skip_button.fade_away()
	if tween:
		tween.kill()

	tween = create_tween()

	tween.tween_callback(func():
		game_started = true	
		camera_enabled = false
		river_game_1.end_tutorial()
		circular_mask.tween_radius(0.0, 1)
	)

	# 9. 準備好了嗎?
	_show_text('ready')

	# 12. 準備開始!!
	_show_text('start')

	tween.tween_interval(0.5)

	tween.tween_callback(func():
		var random_river_index = randi() % num_rivers_scenes

		camera_position = Vector2(1920, 1080)
		score = {0: 0, 1: 0}
		hud.update_score_display(score)
		hud.update_minimap(random_river_index)
		hud.show()

		river_game_1.init(0, num_players, random_river_index)
		river_game_1.camera_to(screen_center, camera_position, 1)
		river_game_1.start_game()

		camera_enabled = true

		TimerManager.start_game_timer(30)
		GlobalAudioPlayer.play_music(game_music)
	)

	# 瞬間關閉圓形遮罩, 慢慢關閉白幕
	tween.tween_property(circular_mask, 'alpha', 0, 1)

var game_stop_tween
func _game_timeout():
	TimerManager.stop_timer(TimerManager.TimerType.GAME)
	GlobalAudioPlayer.stop()

	GlobalAudioPlayer.play_music(victory_music)

	game_started = false

	$long_whistle.play()

	# 延遲後退相機畫面
	if game_stop_tween:
		game_stop_tween.kill()
	game_stop_tween = create_tween()

	game_stop_tween.tween_callback(func():
		river_game_1.camera_to(screen_center, Vector2(1920, 1080), 1.0, 2)
	)

	game_stop_tween.tween_property(hud, 'modulate:a', 0, 0.5)	
	game_stop_tween.tween_interval(10)
	game_stop_tween.tween_callback(func():
		hud.hide()
		GlobalAudioPlayer.stop()
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



# ================== Tutorial ==================

func _undate_guide_text(new_text_state):
	var titles = {
		'begin': '歡迎來到水流急急棒!',
		'control': '你現在是一顆靈活的水滴!',
		'obstacle': '小心前方的障礙物!',
		'speed': '水滴的速度很重要喔!',
		'downstream': '順著水流而下!',
		'electron': '收集電仔囉!',
		'ready': '準備好了嗎?',
		'start': '開始挑戰!!',
		'congrats': '挑戰完成!',
		'thanks': '感謝你的參與'
	}

	var guides = {
		'begin': '在大甲溪流域中\n一滴水可以發很多次電!',
		'control': '擺動你手上的控制器\n吸附到上方閃爍的水滴就能控制方向!',
		'obstacle': '遇到障礙物要小心閃避\n不然會減慢水滴的速度!',
		'speed': '水滴移動越快\n經過電廠時就能產生越多電仔喔!',
		'downstream': '越往下游水流越快\n但也要更小心控制方向!',
		'electron': '水滴就完成了偉大的發電任務!',
		'ready': '接下來就讓我們開始挑戰吧!',
		'start': '',
		'congrats': '小水滴在美麗的大甲溪流域產生 ' + str(score[0]) + ' 個電仔!',
		'thanks': '電幻一號所祝您身體健康!'
	}

	var guide_text_positions = {
		'begin' : Vector2(960, 920),
		'control' : Vector2(960, 1600),
		'obstacle': Vector2(-80, 920),
		'speed' : Vector2(2080, 960),
		'downstream' : Vector2(2160, 180),
		'electron': Vector2(2160, 180),
		'ready': Vector2(960, 920),
		'start': Vector2(960, 920),
		'congrats': Vector2(960, 920),
		'thanks': Vector2(960, 920),
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
	
	reset()

	river_game_1.init(0, num_players, 1) # 初始化 river_2 給 tutorial 用

	river_game_1.camera_to(screen_center, Vector2(1920, 1080), 1, 1)
	river_game_1.finish_line_passed.connect(_on_finish_line_passed)
	river_game_1.spawn_area_scored.connect(_on_spawn_area_scored)
	river_game_1.spawn_area_scoring.connect(_on_spawn_area_scoring)
	river_game_1.checkpoint_passed.connect(_on_checkpoint_passed)
	river_scene_size = river_game_1.get_river_scene_size()

	player_waiter.player_lost_for_too_long.connect(leave_scene_for_restart)

	skip_button.triggered.connect(_skip_tutorial)

	TimerManager.game_time_expired.connect(_game_timeout)

	# 測試的時候才會成為 main scene
	if get_tree().current_scene == self:
		enter_scene()

func _process(delta: float) -> void:
	if camera_enabled:
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
	_game_timeout()

func _on_checkpoint_passed(player_id: int, count: int):
	if game_started:
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
