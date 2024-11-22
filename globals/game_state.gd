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
	TUTORIAL_1,  # 關卡教學階段
	TUTORIAL_2,
	TUTORIAL_3,
	TUTORIAL_4,
	TUTORIAL_5,
	TUTORIAL_6,
	TUTORIAL_7,
	TUTORIAL_8,
	TUTORIAL_END,
	COUNTDOWN_1, # 倒數計時
	COUNTDOWN_2,
	COUNTDOWN_3,
	GAME_PLAY,	 # 遊戲階段
	GAME_OVER    # 結算階段
}

signal ui_state_updated(state_info: Dictionary)
signal login_state_updated(state_info: Dictionary)

var visible_players = Vector2i(0, 0) # (player1, player2) where 1=visible, 0=invisible
var signup_players = Vector2i(0, 0) # (player1, player2) where 1=signed up, 0=not signed up
var ready_players = Vector2i(0, 0) # (player1, player2) where 1=ready, 0=not ready

var game_data: Dictionary = {
	"score": 0,
	"time": 0,
	"level": 1
}

var current_scene := GameScene.LOGIN:
	set(value):
		current_scene = value
		update_ui_stage()

var current_stage := GameStage.LOGIN_START:
	set(value):
		current_stage = value
		update_ui_stage()

func _ready() -> void:
	# 連接玩家數量
	PlayerManager.player_visibility_changed.connect(_on_player_visibility_changed)
	SignalBus.player_signup_portal_changed.connect(_on_player_signup_portal_changed)
	SignalBus.player_ready_portal_changed.connect(_on_player_ready_portal_changed)

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
		
		# TODO: select_level 的判斷式尚未測試，還沒把 transition level 的邏輯串進來
		GameStage.LOGIN_SELECT_LEVEL:
			# 如果有人退出準備狀態，回到教學
			if ready_players[0] != visible_players[0] or \
			   ready_players[1] != visible_players[1]:
				return GameStage.LOGIN_TUTORIAL
			return GameStage.LOGIN_SELECT_LEVEL
	return GameStage.LOGIN_SIGNUP

func update_state() -> void:
	update_ui_stage()
	update_login_stage()

func update_ui_stage() -> void:
	var num_visible_players = visible_players.length_squared()
	
	var state_info = {
		"scene": current_scene,
		"stage": current_stage,
		"num_visible_players": num_visible_players
	}

	ui_state_updated.emit(state_info)

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

func update_visible_players(players: Vector2i) -> void:
	visible_players = players
	update_state()

func update_signup_players(players: Vector2i) -> void:
	signup_players = players
	update_state()

func update_ready_players(players: Vector2i) -> void:
	ready_players = players
	update_state()

func change_scene(new_scene: GameScene) -> void:
	current_scene = new_scene

func change_stage(new_stage: GameStage) -> void:
	current_stage = new_stage

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
	
func _on_player_signup_portal_changed(player: Node, is_entered: bool) -> void:
	var player_index = 0 if player == PlayerManager.player1 else 1
	signup_players[player_index] = 1 if is_entered else 0
	update_signup_players(signup_players)

func _on_player_ready_portal_changed(player: Node, is_entered: bool) -> void:
	var player_index = 0 if player == PlayerManager.player1 else 1
	ready_players[player_index] = 1 if is_entered else 0
	update_ready_players(ready_players)
