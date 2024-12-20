@tool
extends Node2D


signal go_back_to_login



# 宣告成 Export 再用面板設定音源可以避免檔案路徑一被整理這邊就要重寫路徑的問題
@export var game_music: AudioStream

@onready var guide_message = $Title
@onready var wheelgame_env = $WheelGameEnviromnent
@onready var wheelgame_env2 = $WheelGameEnviromnent2
@onready var circular_mask = $CircularMask
@onready var player_waiter = $"1p_player_waiter"

@onready var time_board = $TimeBoard

# reset 非常重要, 定義了動畫能夠順利執行的起始條件
# 在編輯器預覽的設定和 reset 後的設定可以不一樣
func reset():

	# 隱藏關卡本身
	visible = false
	wheelgame_env.set_collision_enabled(false)
	wheelgame_env2.set_collision_enabled(false)
	wheelgame_env2.view_center = Vector2(1800, 1080)

	# 介紹用的訊息與遮罩
	guide_message.modulate.a = 0
	circular_mask.alpha = 1.0
	circular_mask.tween_center_radius(Vector2(1920, 1080), 0.0, 0.0)

	# 遊戲本體及記分板
	wheelgame_env.reset()
	wheelgame_env2.reset()
	time_board.reset()

	# 備用的邏輯
	player_waiter.reset()



var tween
func enter_scene():

	visible = true
	wheelgame_env.set_collision_enabled(true)
	wheelgame_env2.set_collision_enabled(true)
	
	wheelgame_env.set_building_transparent(true)
	wheelgame_env2.set_building_transparent(true)

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
	wheelgame_env2.rotation_enabled = true
	#$HUD.update_time($Timer.wait_time)
	time_board.start()
	$short_whistle.play()
	GlobalAudioPlayer.play_music(game_music)
	


@onready var player1 = PlayerManager.player1
@onready var player2 = PlayerManager.player2

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
			wheelgame_env2.react_to_wheel_rotation(clockwise)
		)

		# 水輪旋轉
		player2.rotation_detected.connect(func(_player, clockwise, speed):
			wheelgame_env2.rotate_wheel(clockwise, speed)
		)

		# 連接UI 及遊戲環境
		time_board.timeout.connect(_game_timeout)

		# 連接 player lost 計時器
		player_waiter.player_lost_for_too_long.connect(leave_scene_for_restart)

		# 連接結尾
		wheelgame_env.all_electron_collected.connect(func():_done_collecting())
		wheelgame_env2.all_electron_collected.connect(func():_done_collecting())


	# 測試的時候才會成為 main scene
	if get_tree().current_scene == self:
		reset()
		enter_scene()



var game_stop_tween
func _game_timeout():
	wheelgame_env.rotation_enabled = false
	wheelgame_env2.rotation_enabled = false
	$long_whistle.play()

	# 延遲後退相機畫面
	if game_stop_tween:
		game_stop_tween.kill()
	game_stop_tween = create_tween()

	game_stop_tween.tween_callback(func():
		wheelgame_env.camera_to(Vector2(1800,1000), 1, 2)
	)

	game_stop_tween.tween_interval(0.15)

	game_stop_tween.tween_callback(func():	
		wheelgame_env2.camera_to(Vector2(1800,1000), 1, 2)
	)

	game_stop_tween.tween_property(time_board, 'modulate:a', 0, 0.5)	
	game_stop_tween.tween_interval(0.5)

	wheelgame_env.show_score_board()
	wheelgame_env2.show_score_board()
	game_stop_tween.tween_callback(func():
		wheelgame_env.collect_electrons.call()
		wheelgame_env2.collect_electrons.call()
	)

	# 挑戰完成! 10 秒後

	GlobalAudioPlayer.stop()



var some_one_already_done_collection = false
func _done_collecting():
	# 第二個數完的對象才是第一名
	if not some_one_already_done_collection:
		some_one_already_done_collection = true
		return

	_congrats_and_return()



func _congrats_and_return():

	var end_duration = 2
	var thanks_duration = 4
	var wait_duration = 2

	
	var winner_env = null
	if wheelgame_env.score > wheelgame_env2.score:
		winner_env = wheelgame_env
	elif wheelgame_env.score < wheelgame_env2.score:
		winner_env = wheelgame_env2

	if tween:
		tween.kill()

	tween = create_tween()
	tween.pause()
	tween.tween_interval(3)
	tween.tween_callback(func():
		$"victory sfx".play()
	)	
	
	if winner_env:
		tween.tween_callback(func():winner_env.celebrate())
	else:
		tween.tween_callback(func():wheelgame_env.celebrate())
		tween.tween_interval(0.2)
		tween.tween_callback(func():wheelgame_env2.celebrate())

	tween.tween_interval(5)

	tween.tween_interval(wait_duration)
	tween.tween_property(circular_mask, 'alpha', 1, 1)
	_show_text('congrats', 3, 1)

	#tween.tween_interval(thanks_duration)
	_show_text('thanks', 2, 1)
	tween.tween_callback(leave_scene_for_restart)
	tween.play()



func _undate_guide_text(new_text_state):
	var titles = {
		'congrats' : '挑戰完成!',
		'thanks' : '感謝你的參與',
	}

	var guides = {
		'congrats' : '你們在 ' + str($TimeBoard.total_time) + ' 秒內一共轉了 ' +\
					 str(wheelgame_env.score) + ' + ' + str(str(wheelgame_env2.score)) + ' 圈呢!',
		'thanks':'電幻 1 號所祝您身體健康, 度過美好的一天!',
	}

	var guide_text_positions = {
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
