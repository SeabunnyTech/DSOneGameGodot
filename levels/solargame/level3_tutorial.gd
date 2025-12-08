extends Node2D

signal leave_for_level(new_scene_name)


@export var wind_strength_factor: float = 0.5
@export var game_music: AudioStream
@export var tutorial_music: AudioStream


var linear_motion_node: Node


@onready var guide_message = $Title
@onready var solarfarm_env = $SolarfarmEnv
@onready var player = PlayerManager.player1
@onready var circular_mask = $CircularMask
@onready var skip_button = $SkipButton
@onready var action_guide_img = $action_guide_img
@onready var time_board = $TimeBoard
@onready var player_waiter = $"1p_player_waiter"



func reset():
	# 隱藏關卡本身
	visible = false
	modulate.a = 0
	solarfarm_env.set_collision_enabled(false) # Assuming solarfarm_env has this method

	# 介紹用的訊息與遮罩
	guide_message.modulate.a = 0
	circular_mask.alpha = 1.0
	circular_mask.tween_center_radius(Vector2(1920, 1080), 0.0, 0.0)
	skip_button.fade_away(true)
	action_guide_img.visible = 0
	action_guide_img.modulate.a = 0

	# 遊戲本體及記分板
	solarfarm_env.reset() # Assuming solarfarm_env has a reset method
	time_board.reset()
	time_board.modulate.a = 0
	game_started = false

	# 備用的邏輯
	player_waiter.reset()



func enter_scene():
	var players = PlayerManager.current_players
	for p in players:
		p.set_player_appearance(true, {'color':Color.BLACK}) # Now uses the renamed function

	visible = true
	solarfarm_env.set_collision_enabled(true) # Assuming solarfarm_env has this method
	_begin_tutorial()



func leave_scene_for_restart():
	circular_mask.tween_radius(0.0, 1.0, func():
		reset()
		leave_for_level.emit('welcome') # Or a specific level for restarting
	)


var game_started

var tween

func _begin_tutorial():
	if tween:
		tween.kill()
	tween = create_tween()

	tween.pause()
	GlobalAudioPlayer.play_music(tutorial_music)
	tween.tween_property(self, 'modulate:a', 1, 1)

	# 1. (白底) 歡迎來到太陽能發電大作戰! 今天我們將為太陽能板進行除塵!
	tween.tween_interval(0.5)
	tween.tween_callback(func():_update_guide_text('begin'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)

	# 接著冒出跳過按鈕
	tween.tween_interval(0.8)
	tween.tween_callback(skip_button.showup)

	# 開場說明消失往下接續
	tween.tween_interval(0.8)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)


	tween.play()

	return

	_show_text('case', 3)

	tween.tween_callback(func():
		#solarfarm_env.camera_to(Vector2(2200, 1000), 0.8)
		circular_mask.tween_center_radius(Vector2(1350, 1080), 1000.0, 1.5)
	)






func _continue_tutorial():
	player_waiter.set_wait_for_player(false)
	if game_started:
		return

	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_interval(0.5)
	
	tween.tween_interval(0.2)
	tween.tween_property(action_guide_img, 'modulate:a', 0, 1)
	tween.tween_property(guide_message, 'modulate:a', 0, 0.5)

	tween.tween_interval(0.5)
	_show_text('cleaned', 3)
	tween.tween_interval(0.5)

	tween.tween_callback(func():_proceed_to_game_start())


func _skip_tutorial(_player = null): # Add default null for _player argument
	tween.kill()
	tween = create_tween()

	tween.tween_interval(0.5)
	action_guide_img.visible = false
	circular_mask.tween_radius(0.0, 1)
	solarfarm_env.camera_to(Vector2(1920, 1080)) # Assuming solarfarm_env has this method

	tween.tween_property(guide_message, 'modulate:a', 0, 1)
	# Assuming a method like set_solar_panels_clean or similar
	# solarfarm_env.set_solar_panels_clean() 
	tween.tween_callback(func():_proceed_to_game_start())


func _proceed_to_game_start():
	player_waiter.set_wait_for_player(false)
	if skip_button.sensetive:
		skip_button.fade_away()
	if tween:
		tween.kill()

	tween = create_tween()

	# 10. 將遊戲環境重置並隱藏相關UI
	tween.tween_callback(func():
		solarfarm_env.camera_to(Vector2(2200, 1080), 1.2)
		# solarfarm_env.rotation_enabled = false # If applicable
		circular_mask.tween_radius(0.0, 1)
		GlobalAudioPlayer.fade_out()
	)

	# Assuming a method to clear any visual effects or active elements
	# tween.tween_callback(solarfarm_env.destroy_active_elements) 
	tween.tween_interval(1)

	# 9. 既然你已經掌握清掃之道
	_show_text('ready', 1)

	# 11. 接下來就進入挑戰吧! 看看你能在一分鐘內發出多少電力呢!
	_show_text('final', 1.5)

	# 12. 準備開始!!
	_show_text('start', 1)

	# 瞬間關閉圓形遮罩, 慢慢關閉白幕
	tween.tween_property(time_board, 'modulate:a', 1, 0.5)

	tween.tween_property(time_board, 'size', Vector2(3840, 400), 1)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


	tween.tween_callback(func():
		reset()
		# Assuming a naming convention for the actual game levels
		var new_level_name = 'level3_1p' if Globals.intended_player_num == 1 else 'level3_2p'
		leave_for_level.emit(new_level_name)
	)


func _ready() -> void:
	# Connect player movement for wind generation
	# PlayerManager.player1.linear_movement_detected.connect(_on_player_linear_movement)
	
	# Connect signals for Level 3 specific interactions (e.g., dust cleaned)
	# solarfarm_env.dust_cleaned.connect(_continue_tutorial) # Placeholder

	# 連接 player lost 計時器
	player_waiter.player_lost_for_too_long.connect(leave_scene_for_restart)

	# 跳過教學的按鈕
	skip_button.triggered.connect(_skip_tutorial)

	# 測試的時候才會成為 main scene
	if get_tree().current_scene == self:
		enter_scene()

func _update_guide_text(new_text_state):
	var titles = {
		'begin' : '歡迎來到陽光保衛戰!',
		'case' : '這是一座太陽能電廠!',
		'show' : '但它其實很不一樣喔!',
		'clean': '灰塵會降低發電效率!',
		'wind': '利用風力清除灰塵!',
		'pushit': '現在就來試試吧!!',
		'cleaned': '非常好!',
		'ready': '既然你已經學會趕走烏雲!',
		'final': '接下來我們就進入實戰',
		'start': '準備開始!!',
		'congrats' : '挑戰完成!',
		'thanks' : '感謝你的參與',
	}

	var guides = {
		'begin' : '今天我們將化身為一團高氣壓\n守護太陽能案場的天空',
		'case' : '它看起來就像是一座普通的太陽能電廠對吧!',
		'show' : '在這裡，你需要維護太陽能板的清潔!',
		'clean': '每當太陽能板變髒，發電效率就會降低喔!',
		'wind': '舉起你手上的控盤，畫圓來產生風力\n將太陽能板上的灰塵清除吧!',
		'pushit' : '舉起你手上的控盤\n畫圓來清除太陽能板上的灰塵吧!',
		'cleaned': '太陽能板已恢復潔淨\n發電效率提升了!',
		'ready': '',
		'final': '看看你能讓太陽能板接到多少光子吧!', # Assuming solarfarm_env has a time_limit
		'start': '',
		'congrats' : '你讓太陽能板接到了' + str(solarfarm_env.score) + '個光子呢!', # Assuming dust_cleaned_count
		'thanks':'電幻 1 號所祝您有美好的一天!',
	}

	var guide_text_positions = {
		'begin' : Vector2(960, 920),
		'case' : Vector2(1800, 920),
		'show' : Vector2(1800, 920),
		'clean': Vector2(1800, 920),
		'wind': Vector2(2100, 450),
		'pushit': Vector2(2100, 450),
		'cleaned': Vector2(2150, 800),
		'ready': Vector2(960, 920),
		'final': Vector2(960, 920),
		'start': Vector2(960, 920),
		'congrats' : Vector2(960, 920),
		'thanks':Vector2(960, 920),
	}

	$Title.position = guide_text_positions[new_text_state]
	$Title.text = titles[new_text_state]
	$Title/Label.text = guides[new_text_state]



func _show_text(text_key, duration=2.0, trans_duration=1.0):
	tween.tween_callback(func():_update_guide_text(text_key))
	tween.tween_property(guide_message, 'modulate:a', 1, trans_duration)
	tween.tween_interval(duration)
	tween.tween_property(guide_message, 'modulate:a', 0, trans_duration)
	return tween
