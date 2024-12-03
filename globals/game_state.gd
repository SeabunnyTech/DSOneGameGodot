extends Node

enum GameScene {
	LOGIN,
	LEVEL1,
	LEVEL2
}

enum GameStage {
	# 登入階段
	LOGIN_START,
	LOGIN_SIGNUP,
	LOGIN_WAIT_FOR_SECOND_PLAYER,
	LOGIN_TUTORIAL,
	LOGIN_SELECT_LEVEL,

	# 關卡階段
	LEVEL_START,
	TUTORIAL_1,  # 關卡教學階段
	TUTORIAL_2,
	TUTORIAL_3,
	TUTORIAL_4,
	TUTORIAL_5,
	TUTORIAL_6,
	TUTORIAL_7,
	TUTORIAL_8,
	TUTORIAL_END,
	COUNTDOWN_3, # 倒數計時
	COUNTDOWN_2,
	COUNTDOWN_1,
	GAME_PLAY,	 # 遊戲階段
	SCORE,		 # 結算階段
	GAME_OVER    # 正式結束頁面
}

var scene_handlers = {
	GameScene.LOGIN: _handle_login_scene,
	GameScene.LEVEL1: _handle_level1_scene,
	GameScene.LEVEL2: _handle_level2_scene,
	# 之後可以輕鬆添加更多場景
}

signal ui_state_updated(state_info: Dictionary)
signal hud_state_updated(state_info: Dictionary)
signal login_state_updated(state_info: Dictionary)
signal level1_state_updated(state_info: Dictionary)
signal level2_state_updated(state_info: Dictionary)

var ui_ready := false
var hud_ready := false
var visible_players = Vector2i(0, 0) # (player1, player2) where 1=visible, 0=invisible
var signup_players = Vector2i(0, 0) # (player1, player2) where 1=signed up, 0=not signed up
var ready_players = Vector2i(0, 0) # (player1, player2) where 1=ready, 0=not ready
var scored_players = Vector2i(0, 0) # (player1, player2) where 1=scored, 0=not scored
var entered_level = [Vector2i(0, 0), Vector2i(0, 0)] # [level1(player1, player2), level2(player1, player2)]
var tutorial_rotation_count = Vector2i(0, 0) # (player1, player2) 

var game_data: Dictionary = {
	"score": 0, # 還沒用到
	"time": 0,  # 還沒用到，沒把總分和時間串到 game_state
	"level": ""
}

var current_scene := GameScene.LOGIN:
	set(value):
		current_scene = value
		update_scene(current_scene)
		update_ui_stage()

var current_stage := GameStage.LOGIN_START:
	set(value):
		current_stage = value
		update_ui_stage()

var current_tutorial_completed: bool = false
var current_game_time_expired: bool = false
var current_countdown_time: float = 0.0

func _ready() -> void:
	_connect_signals()

	# 在編輯器除錯專用
	if OS.has_feature("editor") and get_tree().current_scene:
		var temp_scene = detect_current_scene()
		_on_debug_scene(temp_scene)

func _connect_signals() -> void:
	# 連接玩家註冊與否訊號
	PlayerManager.player_visibility_changed.connect(_on_player_visibility_changed)
	PlayerManager.player_countdown_completed.connect(_on_player_countdown_complete)
	# 連接 UI 載入完成訊號
	SignalBus.ui_ready.connect(_on_ui_ready)
	SignalBus.hud_ready.connect(_on_hud_ready)
	# 連接玩家登入、準備完成訊號
	SignalBus.player_signup_portal_changed.connect(_on_player_signup_portal_changed)
	SignalBus.player_ready_portal_changed.connect(_on_player_ready_portal_changed)
	# 連接選擇關卡訊號
	SignalBus.level_portal_entered.connect(_on_level_portal_entered)
	SignalBus.level_portal_exited.connect(_on_level_portal_exited)
	# 連接電仔出現訊號
	SignalBus.electrons_to_spawn.connect(_on_spawn_electrons)
	SignalBus.electrons_all_scored.connect(_on_electrons_scored)
	# 連接計時器訊號
	TimerManager.tutorial_time_expired.connect(_on_tutorial_time_expired)
	TimerManager.countdown_time_updated.connect(_on_countdown_time_updated)
	TimerManager.countdown_time_expired.connect(_on_countdown_time_expired)
	TimerManager.game_time_updated.connect(_on_game_time_updated)
	TimerManager.game_time_expired.connect(_on_game_time_expired)

# 新增這個函數來檢測當前場景
func detect_current_scene() -> GameScene:
	var current_scene_path = get_tree().current_scene.scene_file_path.to_lower()
	
	if "level1" in current_scene_path:
		return GameScene.LEVEL1
	elif "level2" in current_scene_path:
		return GameScene.LEVEL2
	
	# 如果都不符合，返回預設場景
	return GameScene.LOGIN

# 取得場景路徑
func determine_scene_path(new_scene: GameScene) -> String:
	var num_visible_players = visible_players.length_squared()

	match new_scene:
		GameScene.LOGIN:
			return "res://scenes/levels/login.tscn"
		GameScene.LEVEL1:
			game_data["level"] = "level1"
		GameScene.LEVEL2:
			game_data["level"] = "level2"

	var scene_path = "res://scenes/levels/%s/%s_%dp.tscn" % [game_data["level"], game_data["level"], num_visible_players] 
	return scene_path

# 登入狀態邏輯
func determine_login_stage() -> GameStage:
	var num_visible_players = visible_players.length_squared()
	var num_signup_players = signup_players.length_squared()

	if num_visible_players == 0:
		return GameStage.LOGIN_SIGNUP
	
	match current_stage:
		GameStage.LOGIN_START:
			return GameStage.LOGIN_SIGNUP
		GameStage.LOGIN_SIGNUP:
			# 檢查是否所有可見玩家都已註冊
			if signup_players[0] == visible_players[0] and \
			   signup_players[1] == visible_players[1]:
				return GameStage.LOGIN_TUTORIAL
			# 如果有人註冊但未完全註冊，進入等待狀態
			elif num_signup_players > 0:
				return GameStage.LOGIN_WAIT_FOR_SECOND_PLAYER
			return GameStage.LOGIN_SIGNUP
		GameStage.LOGIN_WAIT_FOR_SECOND_PLAYER:
			# 如果所有可見玩家都註冊了，進入教學
			if signup_players[0] == visible_players[0] and \
			   signup_players[1] == visible_players[1]:
				return GameStage.LOGIN_TUTORIAL
			elif num_signup_players == 0:
				return GameStage.LOGIN_SIGNUP
			return GameStage.LOGIN_WAIT_FOR_SECOND_PLAYER
		GameStage.LOGIN_TUTORIAL:
			# 如果所有可見玩家都準備好了，進入選關
			if ready_players[0] == visible_players[0] and \
			   ready_players[1] == visible_players[1]:
				return GameStage.LOGIN_SELECT_LEVEL
			return GameStage.LOGIN_TUTORIAL
		GameStage.LOGIN_SELECT_LEVEL:
			# 如果有人退出準備狀態，回到教學
			if num_visible_players == 0:
				return GameStage.LOGIN_SIGNUP
			return GameStage.LOGIN_SELECT_LEVEL
	return GameStage.LOGIN_SIGNUP

# 第一關場景狀態邏輯
func determine_level1_stage() -> GameStage:
	var num_visible_players = visible_players.length_squared()

	match current_stage:
		# TODO: game over 模式要顯示對話框
		# TODO: 對話框的 UI 要重新設計調色、新增淡入淡出醒目動畫、提醒要順時鐘旋轉
		GameStage.LEVEL_START:
			TimerManager.start_tutorial_timer(5.0)
			return GameStage.TUTORIAL_1
		GameStage.TUTORIAL_1:
			if current_tutorial_completed:
				current_tutorial_completed = false
				return GameStage.TUTORIAL_2
			return GameStage.TUTORIAL_1
		GameStage.TUTORIAL_2:
			if (bool(visible_players[0]) == (tutorial_rotation_count[0] >= 1)) and \
			   (bool(visible_players[1]) == (tutorial_rotation_count[1] >= 1)):
				TimerManager.start_tutorial_timer(20.0)
				return GameStage.TUTORIAL_3
			return GameStage.TUTORIAL_2
		GameStage.TUTORIAL_3:
			if current_tutorial_completed or \
			   (bool(visible_players[0]) == (tutorial_rotation_count[0] >= 10)) and \
			   (bool(visible_players[1]) == (tutorial_rotation_count[1] >= 10)):
				current_tutorial_completed = false
				TimerManager.start_tutorial_timer(5.0)
				return GameStage.TUTORIAL_4
			return GameStage.TUTORIAL_3
		GameStage.TUTORIAL_4:
			if current_tutorial_completed:
				current_tutorial_completed = false
				for player_id in range(num_visible_players):
					ScoreManager.start_score(player_id)
				TimerManager.start_tutorial_timer(5.0)
				return GameStage.TUTORIAL_5
			return GameStage.TUTORIAL_4
		GameStage.TUTORIAL_5:
			if current_tutorial_completed:
				current_tutorial_completed = false
				TimerManager.start_tutorial_timer(5.0)
				return GameStage.TUTORIAL_6
			return GameStage.TUTORIAL_5
		GameStage.TUTORIAL_6:
			if current_tutorial_completed:
				current_tutorial_completed = false
				TimerManager.start_tutorial_timer(5.0)
				return GameStage.TUTORIAL_END
			return GameStage.TUTORIAL_6
		GameStage.TUTORIAL_END:
			if current_tutorial_completed:
				current_tutorial_completed = false
				ScoreManager.reset_scores()
				TimerManager.start_countdown_timer(3.0)
				return GameStage.COUNTDOWN_3
			return GameStage.TUTORIAL_END
		GameStage.COUNTDOWN_3:
			if current_countdown_time <= 2.0:
				return GameStage.COUNTDOWN_2
			return GameStage.COUNTDOWN_3
		GameStage.COUNTDOWN_2:
			if current_countdown_time <= 1.0:
				return GameStage.COUNTDOWN_1
			return GameStage.COUNTDOWN_2
		GameStage.COUNTDOWN_1:
			if current_countdown_time <= 0.0:
				TimerManager.start_game_timer(80.0) # 遊戲先設定 80 秒
				return GameStage.GAME_PLAY
			return GameStage.COUNTDOWN_1
		GameStage.GAME_PLAY:
			if current_game_time_expired:
				current_game_time_expired = false
				for player_id in range(num_visible_players):
					ScoreManager.start_score(player_id)
				return GameStage.SCORE
			return GameStage.GAME_PLAY
		GameStage.SCORE:
			if scored_players[0] == visible_players[0] and \
			   scored_players[1] == visible_players[1]:
				return GameStage.GAME_OVER
			return GameStage.SCORE
		GameStage.GAME_OVER:
			ScoreManager.reset_scores()
			return GameStage.GAME_OVER
	return GameStage.LEVEL_START

# 測試用 Demo 用的模式
func jump_to_scene_and_play(new_scene: GameScene) -> void:
	var scene_path = determine_scene_path(new_scene)
	# Use call_deferred to ensure the scene change happens at a safe time
	get_tree().call_deferred("change_scene_to_file", scene_path)
	get_tree().tree_changed.connect(_on_debug_scene.bind(new_scene), CONNECT_ONE_SHOT)

func _on_debug_scene(new_scene: GameScene) -> void:
	await get_tree().process_frame # 等待新場景的 _ready 完成
	ui_ready = false
	hud_ready = false

	if new_scene == GameScene.LOGIN:
		return
	
	var num_visible_players = 1
	current_scene = new_scene
	current_stage = GameStage.GAME_PLAY
	var state_info = {
		"scene": current_scene,
		"stage": current_stage,
		"num_visible_players": num_visible_players
	}
	
	match new_scene:
		GameScene.LEVEL1:
			TimerManager.start_game_timer(20.0) # 測試用倒數遊戲時間
			level1_state_updated.emit(state_info)
			# 模擬一個玩家在場
		GameScene.LEVEL2:
			TimerManager.start_game_timer(80.0)
			# level2_state_updated.emit(state_info)
			# update_level2_stage()
			# 模擬一個玩家在場
	
	ui_state_updated.emit(state_info)
	hud_state_updated.emit(state_info)


func update_scene(new_scene: GameScene) -> void:
	var scene_path = determine_scene_path(new_scene)

	# Use call_deferred to ensure the scene change happens at a safe time
	get_tree().call_deferred("change_scene_to_file", scene_path)
	
	# Connect to the tree_changed signal to detect when the new scene is ready
	get_tree().tree_changed.connect(_on_scene_changed, CONNECT_ONE_SHOT)

func update_stage() -> void:
	update_ui_stage()
	update_hud_stage()
	if current_scene in scene_handlers:
		scene_handlers[current_scene].call()
	else:
		push_warning("No handler found for scene: %s" % current_scene)

func update_ui_stage() -> void:
	if not ui_ready:
		await SignalBus.ui_ready

	var num_visible_players = visible_players.length_squared()
	
	var state_info = {
		"scene": current_scene,
		"stage": current_stage,
		"num_visible_players": num_visible_players
	}

	ui_state_updated.emit(state_info)

func update_hud_stage() -> void:
	if not hud_ready:
		await SignalBus.hud_ready

	var num_visible_players = visible_players.length_squared()
	
	var state_info = {
		"scene": current_scene,
		"stage": current_stage,
		"num_visible_players": num_visible_players
	}

	hud_state_updated.emit(state_info)

func update_login_stage() -> void:
	var new_stage = determine_login_stage()
	if new_stage != current_stage:
		change_stage(new_stage)

	# 整合所有登入相關的狀態資訊
	var state_info = {
		"stage": current_stage,
		"player1_visible": visible_players[0] == 1,
		"player2_visible": visible_players[1] == 1,
		"player1_signup": signup_players[0] == 1,
		"player2_signup": signup_players[1] == 1,
		"player1_ready": ready_players[0] == visible_players[0],
		"player2_ready": ready_players[1] == visible_players[1]
	}

	login_state_updated.emit(state_info)

func update_level1_stage() -> void:
	var new_stage = determine_level1_stage()
	if new_stage != current_stage:
		change_stage(new_stage)

	var num_visible_players = visible_players.length_squared()

	# 整合所有登入相關的狀態資訊
	var state_info = {
		"scene": current_scene,
		"stage": current_stage,
		"num_visible_players": num_visible_players
	}

	level1_state_updated.emit(state_info)

func update_visible_players(players: Vector2i) -> void:
	visible_players = players
	update_stage()

func update_signup_players(players: Vector2i) -> void:
	signup_players = players
	update_stage()

func update_ready_players(players: Vector2i) -> void:
	ready_players = players
	update_stage()

func change_scene(new_scene: GameScene) -> void:
	current_scene = new_scene

func change_stage(new_stage: GameStage) -> void:
	current_stage = new_stage

func reset_game_state() -> void:
	TimerManager.pause_timer(TimerManager.TimerType.TUTORIAL)
	TimerManager.pause_timer(TimerManager.TimerType.GAME)
	TimerManager.pause_timer(TimerManager.TimerType.COUNTDOWN)

	# 重置其他狀態
	change_scene(GameScene.LOGIN)
	change_stage(GameStage.LOGIN_START)
	visible_players = Vector2i(0, 0)
	signup_players = Vector2i(0, 0)
	ready_players = Vector2i(0, 0)
	tutorial_rotation_count = Vector2i(0, 0)

func _on_ui_ready() -> void:
	ui_ready = true
	# UI 準備好後，發送當前狀態
	update_ui_stage()

func _on_hud_ready() -> void:
	hud_ready = true
	update_hud_stage()

func _on_scene_changed() -> void:
	ui_ready = false
	hud_ready = false
	var num_visible_players = visible_players.length_squared()
	var state_info = {
		"scene": current_scene,
		"stage": current_stage,
		"num_visible_players": num_visible_players
	}

	ui_state_updated.emit(state_info)
	hud_state_updated.emit(state_info)

	update_stage()

func _on_player_visibility_changed(player: Node, _is_visible: bool) -> void:
	var is_player1 = player == PlayerManager.player1
	var player_index = 0 if is_player1 else 1
	
	# 更新可見性玩家
	visible_players[player_index] = 1 if _is_visible else 0

	# 處理已經登入的玩家退出
	if not _is_visible and signup_players[1 if not is_player1 else 0] == 1:
		signup_players[player_index] = 0
	
	# 更新遊戲狀態
	update_visible_players(visible_players)

# TODO 以下所有 portal 都要增加轉場時的緩沖判斷時間
func _on_player_signup_portal_changed(player: Node, is_entered: bool) -> void:
	var player_index = 0 if player == PlayerManager.player1 else 1
	signup_players[player_index] = 1 if is_entered else 0
	update_signup_players(signup_players)

func _on_player_ready_portal_changed(player: Node, is_entered: bool) -> void:
	var player_index = 0 if player == PlayerManager.player1 else 1
	ready_players[player_index] = 1 if is_entered else 0
	update_ready_players(ready_players)

func _on_spawn_electrons(count: int, player_id: int, spawn_id: int):
	if current_scene != GameScene.LEVEL1:
		return

	tutorial_rotation_count[player_id] += 1
	update_stage()

func _on_electrons_scored(player_id: int):
	scored_players[player_id] = 1
	update_stage()

func _on_level_portal_entered(player: Node, level: String):
	var level_index = 0 if level == "level1" else 1
	var player_index = 0 if player == PlayerManager.player1 else 1
	entered_level[level_index][player_index] = 1
	player.start_progress_countdown()

func _on_level_portal_exited(player: Node, level: String):
	var level_index = 0 if level == "level1" else 1
	var player_index = 0 if player == PlayerManager.player1 else 1
	entered_level[level_index][player_index] = 0
	player.stop_progress_countdown()

func _on_player_countdown_complete(player: Node):
	var player_index = 0 if player == PlayerManager.player1 else 1
	if entered_level[0][player_index] == 1:
		change_scene(GameScene.LEVEL1)
		change_stage(GameStage.LEVEL_START)
	elif entered_level[1][player_index] == 1:
		change_scene(GameScene.LEVEL2)
		change_stage(GameStage.LEVEL_START)

func _on_tutorial_time_updated(time: float) -> void:
	update_stage()

func _on_tutorial_time_expired() -> void:
	current_tutorial_completed = true
	update_stage()

func _on_countdown_time_updated(time: float) -> void:
	current_countdown_time = time
	update_stage()

func _on_countdown_time_expired() -> void:
	current_countdown_time = 0.0
	update_stage()

func _on_game_time_updated(time: float) -> void:
	pass

func _on_game_time_expired() -> void:
	current_game_time_expired = true
	update_stage()

# 個別場景的處理函數
func _handle_login_scene() -> void:
	update_login_stage()

func _handle_level1_scene() -> void:
	update_level1_stage()

func _handle_level2_scene() -> void:
	# TODO: 實作 Level2 的邏輯
	pass
