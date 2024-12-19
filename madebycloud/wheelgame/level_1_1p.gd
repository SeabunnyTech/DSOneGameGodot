@tool
extends Node2D


signal go_back_to_login



# 這個 level 的一些行為:
# 1. 剛進入時會有一些教學, 基本上就是 文字 ui 和運鏡的 tween 一個接一個
# 2. 可以考慮給一個跳過按鈕
# 3. 教學結束就來到倒數及開始 ui
# 4. 遊戲開始後, 音樂可以切換成遊戲音樂

# 宣告成 Export 再用面板設定音源可以避免檔案路徑一被整理這邊就要重寫路徑的問題
@export var game_music: AudioStream

@onready var guide_message = $Title
@onready var wheelgame_env = $WheelGameEnviromnent
@onready var circular_mask = $CircularMask
@onready var player_waiter = $"1p_player_waiter"

@onready var time_board = $TimeBoard

# reset 非常重要, 定義了動畫能夠順利執行的起始條件
# 在編輯器預覽的設定和 reset 後的設定可以不一樣
func reset():

	# 隱藏關卡本身
	visible = false
	wheelgame_env.set_collision_enabled(false)

	# 介紹用的訊息與遮罩
	guide_message.modulate.a = 0
	circular_mask.alpha = 1.0
	circular_mask.tween_center_radius(Vector2(1920, 1080), 0.0, 0.0)

	# 遊戲本體及記分板
	wheelgame_env.reset()
	time_board.reset()

	# 備用的邏輯
	player_waiter.reset()



var tween
func enter_scene():

	visible = true
	wheelgame_env.set_collision_enabled(true)

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(circular_mask, 'alpha', 0, 1)
	tween.tween_callback(_game_start)



func leave_scene_for_restart():
	circular_mask.tween_radius(0.0, 1.0, func():
		reset()
		go_back_to_login.emit()
	)


func _game_start():
	wheelgame_env.rotation_enabled = true
	#$HUD.update_time($Timer.wait_time)
	time_board.start()
	$short_whistle.play()
	GlobalAudioPlayer.play_music(game_music)
	


@onready var player = PlayerManager.player1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	if not Engine.is_editor_hint():
		reset()

		# 電仔生成
		player.full_rotation_completed.connect(func(_player, clockwise):
			wheelgame_env.react_to_wheel_rotation(clockwise)
			#if game_started:
				#$HUD.add_score(1)
		)

		# 水輪旋轉
		player.rotation_detected.connect(func(_player, clockwise, speed):
			wheelgame_env.rotate_wheel(clockwise, speed)
		)

		# 連接UI 及遊戲環境
		time_board.timeout.connect(_game_timeout)
		#wheelgame_env.electron_collected.connect($HUD.add_score)

		# 連接 player lost 計時器
		player_waiter.player_lost_for_too_long.connect(leave_scene_for_restart)


	# 測試的時候才會成為 main scene
	if get_tree().current_scene == self:
		reset()
		enter_scene()


var game_stop_tween
func _game_timeout():
	wheelgame_env.rotation_enabled = false
	$long_whistle.play()

	# 延遲後退相機畫面
	if game_stop_tween:
		game_stop_tween.kill()
	game_stop_tween = create_tween()

	game_stop_tween.tween_callback(func():
		wheelgame_env.camera_to(Vector2(1920,1080), 1.0, 2)
	)

	game_stop_tween.tween_property(time_board, 'modulate:a', 0, 0.5)	
	game_stop_tween.tween_interval(0.5)

	wheelgame_env.show_score_board()
	game_stop_tween.tween_callback(wheelgame_env.collect_electrons)

	# 挑戰完成! 10 秒後

	GlobalAudioPlayer.stop()
	await wheelgame_env.all_electron_collected
	_congrats_and_return()



func _congrats_and_return():

	var end_duration = 2
	var thanks_duration = 4
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



func _undate_guide_text(new_text_state):
	var titles = {
		'begin' : '歡迎來到抽蓄發電大作戰!',
		'case' : '這是一座水力發電廠',
		'show' : '但它其實一點都不普通喔!',
		'inner': '當水輪機發力把水抽到山上時!',
		'metaphor': '換句話說!',
		'pushit': '現在就來試試吧!!',
		'stored': '非常好!',
		'ready': '既然你已經掌握了蓄電之道!',
		'final': '接下來我們就進入挑戰吧!',
		'start': '準備開始!!',
		'congrats' : '挑戰完成!',
		'thanks' : '感謝你的參與',
	}

	var guides = {
		'begin' : '今天我們將化身一顆水滴\n來進行蓄電工作啦!',
		'case' : '它看起來就像是一棟普通的房子對吧!',
		'show' : '在它平淡的外表下\n內部裝著一台巨大的水輪機呢!',
		'inner': '小小的水滴也可以成為儲能的媒介!',
		'metaphor': '電廠後方山上的水池\n其實也可以被想成是一個電池喔!',
		'pushit' : '舉起你手上的控盤\n順時鐘畫圓來抽水到上池蓄積能量吧!',
		'stored': '被抽到了高處的水\n乘載了滿滿的重力位能\n再次被放下時就可以轉換成電力喔!',
		'ready': '',
		'final': '看看你能在 ' + str($TimeBoard.total_time) + ' 秒內發出多少電力!',
		'start': '',
		'congrats' : '你在 ' + str($TimeBoard.total_time) + ' 秒內轉了 ' +\
					 str(wheelgame_env.score) + ' 圈呢!',
		'thanks':'電幻 1 號所祝您身體健康, 手腕舒適!',
	}

	var guide_text_positions = {
		'begin' : Vector2(960, 920),
		'case' : Vector2(1800, 920),
		'show' : Vector2(1800, 920),
		'inner': Vector2(-120, 920),
		'metaphor' : Vector2(2100, 800),
		'pushit': Vector2(2100, 450),
		'stored': Vector2(2150, 800),
		'ready': Vector2(960, 920),
		'final': Vector2(960, 920),
		'start': Vector2(960, 920),
		'congrats' : Vector2(960, 920),
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
