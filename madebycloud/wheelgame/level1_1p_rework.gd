@tool
extends Node2D

# 這個 level 的一些行為:
# 1. 剛進入時會有一些教學, 基本上就是 文字 ui 和運鏡的 tween 一個接一個
# 2. 可以考慮給一個跳過按鈕
# 3. 教學結束就來到倒數及開始 ui
# 4. 遊戲開始後, 音樂可以切換成遊戲音樂

@export var camera_center = Vector2(1920, 1080):
	set(new_center):
		camera_center = new_center
		
@onready var guide_message = $Title
@onready var wheelgame_env = $WheelGameEnviromnent
@onready var circular_mask = $CircularMask


# reset 非常重要, 定義了動畫能夠順利執行的起始條件
# 在編輯器預覽的設定和 reset 後的設定可以不一樣
func reset():
	$WhiteCurtain.modulate.a = 0
	guide_message.modulate.a = 0
	$HUD.reset()
	circular_mask.tween_center_radius(Vector2(1920, 1080), 0.0, 0.0)
	wheelgame_env.rotation_enabled = false


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



func _fade_audio_stream(audio_player, fade_in=false, duration = 2):
	var audio_tween = create_tween()
	var start_volume_db = -80.0 if fade_in else -10.0
	var target_volume_db = -10.0 if fade_in else -80.0

	audio_player.volume_db = start_volume_db
	audio_tween.tween_property(audio_player, "volume_db", target_volume_db, duration)
	if fade_in:
		audio_player.play()
	else:
		audio_tween.tween_callback(audio_player.stop)




func on_enter():
	var tween = create_tween()
	_fade_audio_stream($TutorialMusic, true)
	#curtain
	# 2. 裡面有一台巨大的渦輪機, 當水流推著它轉動時, 就會產生電力喔
	# 3. 現在就用你手上的水滴畫一個大圓來推動它吧!
	# 4. (噴出電仔, 立即運鏡到空中) 哇! 你成功發出了十顆電仔呢! 看來你已經了解這個遊戲怎麼玩了喔!
	# 5. 接下來給你 30 秒的時間, 看看你能發出多少電吧!
	# 6. 3, 2, 1, go! (配樂變化)



	# 轉場進入

	
	#tween.tween_method(circular_mask, 'center', )
	#circular_mask.center = Vector2(2000, 1000)
	#tween.tween_method(func(center): circular_mask.center = center, Vector2(1920, 1080), Vector2(0 ,0), 1)

	# 1. (白底) 歡迎來到蓄電大挑戰! 在這關我們將化身一顆水滴來驅動渦輪發電喔! (3 sec)
	tween.tween_interval(1)
	_undate_guide_text('begin')
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	#tween.tween_interval(3)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)

	# 2. 這一座水力發電廠! 它看起來只是一棟普通的房子對吧!
	tween.tween_callback(func():
		_undate_guide_text('case')
		wheelgame_env.camera_to(Vector2(3000, 1080))
		circular_mask.tween_center_radius(Vector2(1200, 1080), 800.0, 1)
	)

	tween.tween_interval(1)
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	#tween.tween_interval(2)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)

	# 3. 但它其實一點都不普通喔! 在它平淡的外表下\n內部有著很酷的構造喔!
	tween.tween_callback(func():_undate_guide_text('show'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	#tween.tween_interval(2)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)

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
	tween.tween_callback(func():_undate_guide_text('inner'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	#tween.tween_interval(2)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)

	# 6. 它雖然重達 x 噸, 相當於 N 台轎車, 
	tween.tween_callback(func():_undate_guide_text('heavy'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	#tween.tween_interval(2)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)

	# 7. 但是在你手上的水滴推動下, 它會成為我們的發電喔!
	tween.tween_callback(func():_undate_guide_text('power'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	#tween.tween_interval(2)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)

	# 8. 現在舉起你的水滴試著畫圓推進它吧!
	tween.tween_callback(func():_undate_guide_text('pushit'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	# 這邊比較特別, 文字出來以後不用急著藏

	tween.tween_callback(func():
		wheelgame_env.rotation_enabled = true
	)

	# 等待產電的信號	
	tween.tween_interval(2)
	await wheelgame_env.electron_generated
	continue_tutorial()


func continue_tutorial():
	var tween = create_tween()
	tween.tween_interval(1)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)
	tween.tween_interval(1)

	# 9. 非常好! 看來你已經掌握了發電之道呢!
	tween.tween_callback(func():_undate_guide_text('ready'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	#tween.tween_interval(2)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)

	# 10. 將發電機停止並隱藏
	tween.tween_callback(func():
		wheelgame_env.camera_to(Vector2(2200, 1080), 1.2)
		wheelgame_env.rotation_enabled = false
		circular_mask.tween_center_radius(Vector2(2420, 1080), 0.0, 1)
		_fade_audio_stream($TutorialMusic)
	)
	tween.tween_interval(1)
	tween.tween_callback(func(): $WhiteCurtain.modulate.a = 1)

	# 11. 接下來就進入挑戰吧! 看看你能在一分鐘內發出多少電力呢!
	tween.tween_callback(func():_undate_guide_text('final'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	tween.tween_interval(2)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)

	# 12. 準備開始!!
	tween.tween_callback(func():_undate_guide_text('start'))
	tween.tween_property(guide_message, 'modulate:a', 1, 1)
	tween.tween_interval(2)
	tween.tween_property(guide_message, 'modulate:a', 0, 1)

	# 瞬間關閉圓形遮罩, 慢慢關閉白幕
	tween.tween_property(circular_mask, 'modulate:a', 0, 0)
	tween.tween_property($WhiteCurtain, 'modulate:a', 0, 1)

	tween.tween_callback(func():
		wheelgame_env.rotation_enabled = true
		$HUD.show()
		_fade_audio_stream($GameMusic, true, 1)
	)
	


func on_leave():
	pass




@onready var player = PlayerManager.player1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset()
	# 連接信號:
	# 1. player1 控制旋轉
	# 2. 計分板

	# 電仔生成
	player.full_rotation_completed.connect(func(player, clockwise):
		wheelgame_env.generate_electron_and_adjust_lake_level(clockwise)
	)

	# 水輪旋轉
	player.rotation_detected.connect(func(player, clockwise, speed):
		wheelgame_env.rotate_wheel(clockwise, speed)
	)

	
	on_enter()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
