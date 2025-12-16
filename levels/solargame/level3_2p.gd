extends Control


signal leave_for_level(new_level_name)



# 這個 level 的一些行為:
# 1. 剛進入時會有一些教學, 基本上就是 文字 ui 和運鏡的 tween 一個接一個
# 2. 可以考慮給一個跳過按鈕
# 3. 教學結束就來到倒數及開始 ui
# 4. 遊戲開始後, 音樂可以切換成遊戲音樂

# 宣告成 Export 再用面板設定音源可以避免檔案路徑一被整理這邊就要重寫路徑的問題
@export var game_music: AudioStream

@onready var guide_message = $Title
@onready var solarfarm_env_2p = $SolarfarmEnv_2p
@onready var solarfarm_env_2p2 = $SolarfarmEnv_2p2
@onready var circular_mask = $CircularMask
@onready var player_waiter = $"1p_player_waiter"

@onready var time_board = $TimeBoard

# reset 非常重要, 定義了動畫能夠順利執行的起始條件
# 在編輯器預覽的設定和 reset 後的設定可以不一樣
func reset():

	# 隱藏關卡本身
	visible = false
	solarfarm_env_2p.set_collision_enabled(false)
	solarfarm_env_2p2.set_collision_enabled(false)

	# 介紹用的訊息與遮罩
	guide_message.modulate.a = 0
	circular_mask.alpha = 1.0
	circular_mask.tween_center_radius(Vector2(1920, 1080), 0.0, 0.0)

	# 遊戲本體及記分板
	solarfarm_env_2p.reset()
	solarfarm_env_2p2.reset()
	time_board.reset()
	time_board.modulate.a = 1

	# 備用的邏輯
	player_waiter.reset()



var tween
func enter_scene():

	# 把玩家的游標設成水滴
	for p in PlayerManager.current_players:
		p.set_player_appearance(true, {'color':Color.WHITE})

	visible = true
	solarfarm_env_2p.set_collision_enabled(true)
	solarfarm_env_2p2.set_collision_enabled(true)

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(circular_mask, 'alpha', 0, 1)
	tween.tween_callback(_game_start)



func leave_scene_for_restart():
	circular_mask.tween_radius(0.0, 1.0, func():
		reset()
		leave_for_level.emit('welcome')
	)


func _game_start():
	solarfarm_env_2p.start_game_play()
	solarfarm_env_2p2.start_game_play()

	time_board.start()
	$short_whistle.play()
	GlobalAudioPlayer.play_music(game_music)
	


@onready var player = PlayerManager.player1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	if not Engine.is_editor_hint():
		reset()

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
	solarfarm_env_2p.stop_game_play()
	solarfarm_env_2p2.stop_game_play()
	$long_whistle.play()

	# 延遲後退相機畫面
	if game_stop_tween:
		game_stop_tween.kill()
	game_stop_tween = create_tween()

	#game_stop_tween.tween_callback(func():
		#solarfarm_env.camera_to(Vector2(1920,1080), 1.0, 2)
	#)

	game_stop_tween.tween_property(time_board, 'modulate:a', 0, 0.5)	
	game_stop_tween.tween_interval(0.5)

	game_stop_tween.tween_callback(solarfarm_env_2p.collect_electrons)
	game_stop_tween.tween_callback(solarfarm_env_2p2.collect_electrons)

	# 挑戰完成! 10 秒後

	GlobalAudioPlayer.stop()
	await solarfarm_env_2p.all_electron_collected
	await solarfarm_env_2p2.all_electron_collected
	_congrats_and_return()



func _congrats_and_return():

	var end_duration = 2
	var thanks_duration = 4
	var wait_duration = 2

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_interval(wait_duration)
	tween.tween_callback(func():
		$"victory sfx".play()
		for p in PlayerManager.current_players:
			p.set_player_appearance(true, {'color':Color.BLACK})
	)
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



func _update_guide_text(new_text_state):
	var titles = {
		'congrats' : '挑戰完成!',
		'thanks' : '感謝你的參與',
	}

	var guides = {
		'congrats' : '你們一起讓太陽能板接到了 ' + str(solarfarm_env_2p.score) + " + " + str(solarfarm_env_2p2.score) + ' 個光子呢!',
		'thanks':'電幻 1 號所祝您有美好的一天!',
	}

	var guide_text_positions = {
		'congrats' : Vector2(960, 920),
		'thanks':Vector2(960, 920),
	}

	$Title.position = guide_text_positions[new_text_state]
	$Title.text = titles[new_text_state]
	$Title/Label.text = guides[new_text_state]



func _show_text(text_key, duration=2, trans_duration=1):
	tween.tween_callback(func():_update_guide_text(text_key))
	tween.tween_property(guide_message, 'modulate:a', 1, trans_duration)
	tween.tween_interval(duration)
	tween.tween_property(guide_message, 'modulate:a', 0, trans_duration)
	return tween
