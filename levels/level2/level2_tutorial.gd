extends Node2D

signal leave_for_level(new_scene_name)

# ========= Old HUD =========
@onready var hud = $HUD
# ===========================

@export var game_music: AudioStream
@export var tutorial_music: AudioStream
@export var victory_music: AudioStream

@onready var guide_message = $Title
@onready var river_game_tutorial = $RiverGameTutorial
@onready var circular_mask = $CircularMask
@onready var player_waiter = $"1p_player_waiter"
@onready var skip_button = $SkipButton

@export var screen_center = Vector2(3840.0/2, 2160.0/2)
@export var camera_position = Vector2(1920, 1080):
	set(new_position):
		camera_position = new_position
@export var camera_velocity = 0.0  # 相機當前速度

@export var camera_zoom_level = 1.2
@export var camera_y_threshold = 0.35  # 螢幕 35% 以下時開始加速
@export var camera_smoothing = 0.8    # 相機平滑度 (0-1)
@export var min_camera_speed = 10.0
@export var max_camera_speed = 800.0
var camera_enabled = false

@export var num_players = 1
@export var num_rivers_scenes = 3

# var game_started = false
var tutorial_skipped = false

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
	river_game_tutorial.reset()

	# time_board.reset()
	# time_board.modulate.a = 0
	# time_board.size = Vector2(3840, 2160)
	# game_started = false
	tutorial_skipped = false
	camera_enabled = false
	camera_position = Vector2(1920, 1080)

	# 備用的邏輯
	player_waiter.reset()

func enter_scene():
	river_game_tutorial.init(0, 1, 1) # _player_id: int, num_players: int, river_index: int
	river_game_tutorial.camera_to(screen_center, Vector2(1920, 1080), 1, 1)
	river_scene_size = river_game_tutorial.get_river_scene_size()

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
		leave_for_level.emit('welcome')
	)

var tween

func _begin_tutorial():
	river_game_tutorial.init_player()

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
		river_game_tutorial.show_avatar()
		river_game_tutorial.camera_to(screen_center, Vector2(1920, 1080), 1.1)
		circular_mask.tween_center_radius(Vector2(1920, 800), 700.0, 1)
	)

	tween.tween_callback(func():
		var guide_text = 'control_1p' if Globals.intended_player_num == 1 else 'control_2p'
		_undate_guide_text(guide_text)
	)

	tween.tween_property(guide_message, 'modulate:a', 1, 1)

	tween.play()

	# 等待產電的信號	
	tween.tween_interval(2)

	await river_game_tutorial.avatar_merged
	_continue_tutorial_1()

func _continue_tutorial_1():
	if tutorial_skipped:
		return

	if tween:
		tween.kill()

	tween = create_tween()

	tween.tween_interval(0.5)
	
	tween.tween_callback(func():
		river_game_tutorial.blink_stones()
		river_game_tutorial.camera_to(screen_center, Vector2(1920, 1080), 1.15)
		circular_mask.tween_center_radius(Vector2(2160, 800), 500.0, 1.5)
	)

	# 3. 遇到障礙物要小心閃避\n不然會減慢水滴的速度!
	_show_text('obstacle')

	tween.tween_callback(func():
		river_game_tutorial.stop_blink()
		river_game_tutorial.camera_to(screen_center, Vector2(1920, 1080), 1)
		circular_mask.tween_center_radius(Vector2(1450, 1080), 1000.0, 1)
	)

	tween.tween_interval(0.5)
	
	tween.tween_callback(func():
		river_game_tutorial.blink_checkpoint()
	)

	# 4. 水滴移動越快，經過電廠時就能產生越多電仔喔!
	tween.tween_callback(func():
		_undate_guide_text('speed')
	)
	
	tween.tween_property(guide_message, 'modulate:a', 1, 0.5)

	tween.tween_interval(0.5)
	tween.tween_callback(func():
		river_game_tutorial.enable_checkpoint()
	)
	
	tween.play()

	# 等待玩家通過 checkpoint
	tween.tween_interval(3)

	await river_game_tutorial.checkpoint_passed
	_continue_tutorial_2()

func _continue_tutorial_2():
	river_game_tutorial.stop_blink()

	if tutorial_skipped:
		return
	if tween:
		tween.kill()

	tween = create_tween()

	# 5. 越往下游水流越快，但也要更小心控制方向!
	camera_enabled = true

	tween.tween_callback(func():
		river_game_tutorial.camera_to(screen_center, Vector2(1920, 1080), 1)
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
	tutorial_skipped = true

	if tween:
		tween.kill()

	tween = create_tween()

	tween.tween_interval(0.5)
	circular_mask.tween_radius(0.0, 1)
	river_game_tutorial.camera_to(screen_center, Vector2(1920, 1080))

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
		camera_enabled = false
		river_game_tutorial.end_tutorial()
		circular_mask.tween_radius(0.0, 1)
	)

	# 9. 準備好了嗎?
	_show_text('ready')

	# 12. 準備開始!!
	_show_text('start')

	tween.tween_interval(0.5)

	tween.tween_callback(func():
		reset()
		var new_level_name = 'level2_1p' if Globals.intended_player_num == 1 else 'level2_2p'
		leave_for_level.emit(new_level_name)
	)


# ================== Tutorial ==================

func _undate_guide_text(new_text_state):
	var titles = {
		'begin': '歡迎來到水流急急棒!',
		'control_1p': '你現在是一顆靈活的水滴!',
		'control_2p': '你們現在是一顆靈活的水滴!',
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
		'control_1p': '玩家請擺動你手上的控制器\n吸附到上方閃爍的水滴就能控制方向!',
		'control_2p': '左邊的玩家請擺動你手上的控制器\n吸附到上方閃爍的水滴就能控制方向!',
		'obstacle': '遇到障礙物要小心閃避\n不然會減慢水滴的速度!',
		'speed': '水滴移動越快\n經過電廠時就能產生越多電仔喔!',
		'downstream': '越往下游水流越快\n但也要更小心控制方向!',
		'electron': '水滴就完成了偉大的發電任務!',
		'ready': '接下來就讓我們開始挑戰吧!',
		'start': '',
		'congrats': '小水滴在美麗的大甲溪流域產生 ' + str(score[0]) + ' 個電仔!',
		'thanks': '電幻 1 號所祝您身體健康!'
	}

	var guide_text_positions = {
		'begin' : Vector2(960, 920),
		'control_1p' : Vector2(960, 1600),
		'control_2p' : Vector2(960, 1600),
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

	player_waiter.player_lost_for_too_long.connect(leave_scene_for_restart)

	skip_button.triggered.connect(_skip_tutorial)

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
	var river_game = river_game_tutorial
	var avatar_pos = river_game_tutorial.get_avatar_position()

	# 計算相機移動速度
	var relative_y = avatar_pos.y / screen_height
	var target_speed = lerp(
		min_camera_speed,
		max_camera_speed,
		max(0, (relative_y - camera_y_threshold) / (1 - camera_y_threshold))
	)

	if river_game_tutorial.avatar_is_stuck or river_game_tutorial.avatar_is_separated:
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
