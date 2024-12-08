@tool
extends Node2D

# 這個 level 的一些行為:
# 1. 剛進入時會有一些教學, 基本上就是 文字 ui 和運鏡的 tween 一個接一個
# 2. 可以考慮給一個跳過按鈕
# 3. 教學結束就來到倒數及開始 ui
# 4. 遊戲開始後, 音樂可以切換成遊戲音樂

# 宣告成 Export 再用面板設定音源可以避免檔案路徑一被整理這邊就要重寫路徑的問題
@export var game_music: AudioStream
@export var tutorial_music: AudioStream


@export var camera_center = Vector2(1920, 1080):
	set(new_center):
		camera_center = new_center

@onready var guide_message = $Title
@onready var wheelgame_env = $WheelGameEnviromnent
@onready var circular_mask = $CircularMask


# reset 非常重要, 定義了動畫能夠順利執行的起始條件
# 在編輯器預覽的設定和 reset 後的設定可以不一樣
func reset():
	modulate.a = 0
	guide_message.modulate.a = 0
	$HUD.reset()
	circular_mask.alpha = 1.0
	circular_mask.tween_center_radius(Vector2(1920, 1080), 0.0, 0.0)
	wheelgame_env.reset()
	$SkipButton.fade_away(true)


func enter_scene():
	_begin_tutorial()


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
	tween.tween_callback($SkipButton.showup)

	# 開場說明消失往下接續
	tween.tween_interval(1)
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

	# 5. 看到了嗎! 這是 ooo 型的發電渦輪!
	_show_text('inner')

	# 6. 它雖然重達 x 噸, 相當於 N 台轎車, 
	_show_text('heavy')

	# 7. 但是在你手上的水滴推動下, 它會成為我們的發電喔!
	_show_text('power')

	# 8. 現在舉起你的水滴試著畫圓推進它吧!
	tween.tween_callback(func():_undate_guide_text('pushit'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	# 這邊比較特別, 文字出來以後不用急著藏

	tween.tween_callback(func():
		wheelgame_env.rotation_enabled = true
	)

	tween.play()

	# 等待產電的信號	
	tween.tween_interval(2)
	await wheelgame_env.electron_generated
	_continue_tutorial()



func _continue_tutorial():
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)
	tween.tween_interval(0.5)
	tween.tween_callback(func():_procees_to_game_start())


func _skip_tutorial(_player):
	tween.kill()
	#tween.tween_interval(1)
	tween = create_tween()
	wheelgame_env.camera_to(Vector2(1920, 1080))
	circular_mask.tween_center_radius(Vector2(2420, 1080), 800.0, 1)
	wheelgame_env.set_building_transparent()
	tween.tween_callback(func():_procees_to_game_start())


func _procees_to_game_start():
	if $SkipButton.sensetive:
		$SkipButton.fade_away()
	if tween:
		tween.kill()

	tween = create_tween()

	# 9. 非常好! 看來你已經掌握了發電之道呢!
	_show_text('ready')

	# 10. 將發電機停止並隱藏
	tween.tween_callback(func():
		wheelgame_env.camera_to(Vector2(2200, 1080), 1.2)
		wheelgame_env.rotation_enabled = false
		circular_mask.tween_center_radius(Vector2(2420, 1080), 0.0, 1)
		GlobalAudioPlayer.fade_out()
	)
	tween.tween_interval(1)
	tween.tween_callback(wheelgame_env.destroy_electrons)

	# 11. 接下來就進入挑戰吧! 看看你能在一分鐘內發出多少電力呢!
	_show_text('final')

	# 12. 準備開始!!
	_show_text('start')

	# 瞬間關閉圓形遮罩, 慢慢關閉白幕
	tween.tween_property(circular_mask, 'alpha', 0, 1)

	tween.tween_callback(func():
		wheelgame_env.rotation_enabled = true
		$HUD.show()
		GlobalAudioPlayer.play_music(game_music)
	)
	


func on_leave():
	pass




@onready var player = PlayerManager.player1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# 測試的時候才會成為 main scene
	
	reset()
	# 連接信號:
	# 1. player1 控制旋轉
	# 2. 計分板

	if not Engine.is_editor_hint():

		# 電仔生成
		player.full_rotation_completed.connect(func(_player, clockwise):
			wheelgame_env.react_to_wheel_rotation(clockwise)
		)

		# 水輪旋轉
		player.rotation_detected.connect(func(_player, clockwise, speed):
			wheelgame_env.rotate_wheel(clockwise, speed)
		)

	# 跳過教學的按鈕
	$SkipButton.triggered.connect(_skip_tutorial)

	if get_tree().current_scene == self:
		enter_scene()



func _undate_guide_text(new_text_state):
	var titles = {
		'begin' : '歡迎來到蓄電大挑戰!',
		'case' : '這是一座水力發電廠',
		'show' : '但它其實一點都不普通喔!',
		'inner': '看到了嗎!',
		'heavy': '它重達 x 噸',
		'power': '但在水滴的作用下',
		'pushit': '現在就來推它吧!!',
		'ready': '非常好!',
		'final': '接下來我們就進入挑戰吧!',
		'start': '準備開始!!',
	}

	var guides = {
		'begin' : '今天我們將化身一顆水滴\n來驅動渦輪發電啦!',
		'case' : '它看起來就像是一棟普通的房子對吧!',
		'show' : '在它平淡的外表下\n內部有著很酷的構造喔!',
		'inner': '這是 ooo 型的發電渦輪!',
		'heavy': '相當於 N 台轎車!',
		'power': '它會成為我們的發電夥伴喔!',
		'pushit' : '舉起你手上的水滴\n畫圓推動它!',
		'ready': '看來你已經掌握發電之道了呢!',
		'final': '看看你能在一分鐘內發出多少電力!',
		'start': '',
	}

	var guide_text_positions = {
		'begin' : Vector2(960, 920),
		'case' : Vector2(1800, 920),
		'show' : Vector2(1800, 920),
		'inner': Vector2(80, 920),
		'heavy': Vector2(80, 920),
		'power': Vector2(0, 920),
		'pushit': Vector2(0, 920),
		'ready': Vector2(0, 920),
		'final': Vector2(960, 920),
		'start': Vector2(960, 920),
	}

	$Title.position = guide_text_positions[new_text_state]
	$Title.text = titles[new_text_state]
	$Title/Label.text = guides[new_text_state]



func _show_text(text_key, duration=0.1):
	tween.tween_callback(func():_undate_guide_text(text_key))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	tween.tween_interval(duration)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)
	return tween
