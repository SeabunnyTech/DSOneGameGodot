@tool
extends Node2D


signal leave_for_level(new_scene_name)


# 這個 level 的一些行為:
# 1. 剛進入時會有一些教學, 基本上就是 文字 ui 和運鏡的 tween 一個接一個
# 2. 可以考慮給一個跳過按鈕
# 3. 教學結束就來到倒數及開始 ui
# 4. 遊戲開始後, 音樂可以切換成遊戲音樂

# 宣告成 Export 再用面板設定音源可以避免檔案路徑一被整理這邊就要重寫路徑的問題
@export var game_music: AudioStream
@export var tutorial_music: AudioStream

@onready var guide_message = $Title
@onready var wheelgame_env = $WheelGameEnviromnent
@onready var circular_mask = $CircularMask
@onready var player_waiter = $"1p_player_waiter"

@onready var action_guide_img = $action_guide_img

@onready var time_board = $TimeBoard

# reset 非常重要, 定義了動畫能夠順利執行的起始條件
# 在編輯器預覽的設定和 reset 後的設定可以不一樣
func reset():

	# 隱藏關卡本身
	visible = false
	modulate.a = 0
	wheelgame_env.set_collision_enabled(false)

	# 介紹用的訊息與遮罩
	guide_message.modulate.a = 0
	circular_mask.alpha = 1.0
	circular_mask.tween_center_radius(Vector2(1920, 1080), 0.0, 0.0)
	$SkipButton.fade_away(true)
	action_guide_img.visible = 0
	action_guide_img.modulate.a = 0

	# 遊戲本體及記分板
	wheelgame_env.reset()
	time_board.reset()
	time_board.modulate.a = 0
	time_board.size = Vector2(3840, 2160)
	game_started = false

	# 備用的邏輯
	player_waiter.reset()


func enter_scene():
	visible = true
	wheelgame_env.set_collision_enabled(true)
	_begin_tutorial()



func leave_scene_for_restart():
	circular_mask.tween_radius(0.0, 1.0, func():
		reset()
		leave_for_level.emit('welcome')
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
	tween.tween_interval(0.8)
	tween.tween_callback($SkipButton.showup)

	# 開場說明消失往下接續
	tween.tween_interval(0.8)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)


	# 2. 這一座水力發電廠! 它看起來只是一棟普通的房子對吧!
	tween.tween_callback(func():
		wheelgame_env.camera_to(Vector2(3000, 1080))
		circular_mask.tween_center_radius(Vector2(1200, 1080), 800.0, 1)
	)

	tween.tween_interval(1)
	_show_text('case')

	# 3. 但它其實一點都不普通喔! 在它平淡的外表下\n內部有著很酷的構造喔!
	_show_text('show')

	# 4. (一語不發移鏡, 然後外殼轉透明)
	tween.tween_callback(func():
		#_undate_guide_text('case')
		wheelgame_env.camera_to(Vector2(1920, 1080))
		circular_mask.tween_center_radius(Vector2(2420, 1080), 800.0, 1)
	)
	tween.tween_interval(1)
	tween.tween_callback(func():
		wheelgame_env.set_building_transparent()
	)

	tween.tween_interval(1)

	# 5. 在水輪機的強力加持之下, 小小的水滴也可以成為儲能的媒介!
	_show_text('inner', 3)

	tween.tween_callback(func():
		wheelgame_env.camera_to(Vector2(2200, 1000), 0.8)
		circular_mask.tween_center_radius(Vector2(1350, 1080), 1000.0, 1.5)
	)

	tween.tween_interval(1.5)

	# 6. 換句話說! 電廠後方山上的水池, 其實也可以被想成是一個電池喔! 
	_show_text('metaphor')

	# 8. 現在舉起你的水滴試著畫圓推進它吧!
	tween.tween_callback(func():
		_undate_guide_text('pushit')
		action_guide_img.visible = true
	)
	
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	tween.tween_property(action_guide_img, 'modulate:a', 1, 1)
	# 這邊比較特別, 文字出來以後不用急著藏

	tween.tween_callback(func():
		wheelgame_env.rotation_enabled = true
		player_waiter.set_wait_for_player(true)
	)

	tween.play()

	# 等待產電的信號	
	tween.tween_interval(2)
	await wheelgame_env.electron_generated
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
	tween.tween_property(action_guide_img, 'modulate:a', 0, 1)
	tween.tween_property(guide_message, 'modulate:a', 0, 0.5)

	tween.tween_interval(0.5)
	_show_text('stored', 3)
	tween.tween_interval(0.5)

	tween.tween_callback(func():_proceed_to_game_start())


func _skip_tutorial(_player):
	tween.kill()
	tween = create_tween()

	tween.tween_interval(0.5)
	action_guide_img.visible = false
	circular_mask.tween_radius(0.0, 1)
	wheelgame_env.camera_to(Vector2(1920, 1080))

	tween.tween_property(guide_message, 'modulate:a', 0, 1)
	wheelgame_env.set_building_transparent()
	tween.tween_callback(func():_proceed_to_game_start())


func _proceed_to_game_start():
	player_waiter.set_wait_for_player(false)
	if $SkipButton.sensetive:
		$SkipButton.fade_away()
	if tween:
		tween.kill()

	tween = create_tween()

	# 10. 將發電機停止並隱藏
	tween.tween_callback(func():
		wheelgame_env.camera_to(Vector2(2200, 1080), 1.2)
		wheelgame_env.rotation_enabled = false
		circular_mask.tween_radius(0.0, 1)
		GlobalAudioPlayer.fade_out()
	)

	tween.tween_callback(wheelgame_env.destroy_electrons)
	tween.tween_interval(1)

	# 9. 既然你已經掌握蓄電之道
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
		# 在保持畫面上只有一個 timeboard 的狀態下
		# 瞬間隱藏並切換到起始畫面同樣是只有一個 timeboard 的下一關
		# 讓觀眾產生兩關連續的錯覺
		reset()
		var new_level_name = 'level1_1p' if Globals.intended_player_num == 1 else 'level1_2p'
		leave_for_level.emit(new_level_name)
	)

	



@onready var player1 = PlayerManager.player1
@onready var player2 =  PlayerManager.player2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	if not Engine.is_editor_hint():
		reset()

		# 電仔生成
		player1.full_rotation_completed.connect(func(_player, clockwise):
			wheelgame_env.react_to_wheel_rotation(clockwise)
		)

		# 水輪旋轉
		player1.rotation_detected.connect(func(_player, clockwise, speed):
			wheelgame_env.rotate_wheel(clockwise, speed)
		)

		player2.full_rotation_completed.connect(func(_player, clockwise):
			if Globals.intended_player_num == 2:
				wheelgame_env.react_to_wheel_rotation(clockwise)
		)

		# 水輪旋轉
		player2.rotation_detected.connect(func(_player, clockwise, speed):
			if Globals.intended_player_num == 2:
				wheelgame_env.rotate_wheel(clockwise, speed)
		)

		# 連接 player lost 計時器
		player_waiter.player_lost_for_too_long.connect(leave_scene_for_restart)


	# 跳過教學的按鈕
	$SkipButton.triggered.connect(_skip_tutorial)

	# 測試的時候才會成為 main scene
	if get_tree().current_scene == self:
		enter_scene()



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
