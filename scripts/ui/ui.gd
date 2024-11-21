extends Node

var messages: Dictionary
var messages_path: String = "res://assets/text/ui_messages.json"

@onready var popup_one_player_panel: Panel = %PopupMessageOnePlayer
@onready var popup_one_player_label: Label = %PopupMessageOnePlayerLabel
@onready var popup_two_players_panel: Panel = %PopupMessageTwoPlayers
@onready var popup_two_players_label: Label = %PopupMessageTwoPlayersLabel
@onready var dialog_box_panel: PanelContainer = %DialogBox
@onready var dialog_box_label: Label = %DialogBoxLabel
@onready var skip_button: Panel = %SkipButton

# TODO: 尚未完成，需要串接到 game_state 裡面

signal return_area_entered(body: Node2D)
signal return_area_exited(body: Node2D)
signal skip_area_entered(body: Node2D)
signal skip_area_exited(body: Node2D)

enum GameScene {
	LOGIN,
	LEVEL1,
	LEVEL2
}

enum LoginState {
	START,
	SIGNUP,
	WAIT_FOR_SECOND_PLAYER,
	TUTORIAL,
	SELECT_LEVEL
}

enum GameState {
	TUTORIAL_1,   # 關卡教學階段
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
	GAME_OVER     # 結算階段
}

const LOGIN_SIGNALS = {
	# Login signals
	"login_signup": LoginState.SIGNUP,
	"login_start": LoginState.START,
	"login_wait_for_players": LoginState.WAIT_FOR_SECOND_PLAYER,
	"login_tutorial": LoginState.TUTORIAL,
	"login_select_level": LoginState.SELECT_LEVEL
}

const LEVEL1_SIGNALS = {
	# Level1 signals
	"level1_tutorial_1": GameState.TUTORIAL_1,
	"level1_tutorial_2": GameState.TUTORIAL_2,
	"level1_tutorial_3": GameState.TUTORIAL_3,
	"level1_tutorial_4": GameState.TUTORIAL_4,
	"level1_tutorial_5": GameState.TUTORIAL_5,
	"level1_tutorial_6": GameState.TUTORIAL_6,
	"level1_tutorial_end": GameState.TUTORIAL_END,
	"level1_countdown_3": GameState.COUNTDOWN_3,
	"level1_countdown_2": GameState.COUNTDOWN_2,
	"level1_countdown_1": GameState.COUNTDOWN_1,
	"level1_game_over": GameState.GAME_OVER
}

# 動畫用變數
var tween: Tween

func _ready():
	load_messages()
	set_default_messages()
	# Get the root parent node (scene)
	var root_parent = get_parent()
	connect_signals(root_parent)
	
	var scene_name = root_parent.name
	DebugMessage.info("UI loaded under scene: " + str(scene_name))

func connect_signals(root_parent: Node) -> void:
	var scene_name = root_parent.name
	var signals_to_connect = {}

	match scene_name:
		"Login":
			signals_to_connect = LOGIN_SIGNALS
		"Level1_1p", "Level1_2p":
			signals_to_connect = LEVEL1_SIGNALS
	
	for signal_name in signals_to_connect:
		if root_parent.has_signal(signal_name):
			root_parent.connect(signal_name, 
				func(num_visible_players): _handle_state_signal(signal_name, num_visible_players))
		else:
			push_warning("Signal not found in %s: %s" % [scene_name, signal_name])

func _handle_state_signal(signal_name: String, num_visible_players: int = 0) -> void:
	# 根據訊號名稱前綴決定使用哪個映射和處理函數
	if signal_name.begins_with("login_"):
		if not LOGIN_SIGNALS.has(signal_name):
			push_error("Unknown login signal: " + signal_name)
			return
		handle_login_state(LOGIN_SIGNALS[signal_name], num_visible_players)
	elif signal_name.begins_with("level1_"):
		if not LEVEL1_SIGNALS.has(signal_name):
			push_error("Unknown level1 signal: " + signal_name)
			return
		handle_level1_state(LEVEL1_SIGNALS[signal_name], num_visible_players)

func handle_login_state(state: LoginState, num_visible_players: int = 0):
	match state:
		LoginState.START:
			set_dialog_message("login", "start")
			hide_popups()
		LoginState.SIGNUP:
			set_dialog_message("login", "signup")
			hide_popups()
		LoginState.WAIT_FOR_SECOND_PLAYER:
			set_dialog_message("login", "wait_for_second_player")
			hide_popups()
		LoginState.TUTORIAL:
			set_dialog_message("login", "tutorial")
			set_popup_message(num_visible_players, "login", "tutorial")
		LoginState.SELECT_LEVEL:
			set_dialog_message("login", "select_level")
			hide_popups()

# Level1 相關處理方法
func handle_level1_state(state: GameState, num_visible_players: int = 0):
	match state:
		GameState.TUTORIAL_1:
			show_skip_button()
			set_dialog_message("level1", "tutorial")
			set_popup_message(num_visible_players, "level1", "tutorial_1")
		GameState.TUTORIAL_2:
			set_dialog_message("level1", "tutorial")
			set_popup_message(num_visible_players, "level1", "tutorial_2")
		GameState.TUTORIAL_3:
			set_dialog_message("level1", "tutorial")
			set_popup_message(num_visible_players, "level1", "tutorial_3")
		GameState.TUTORIAL_4:
			hide_skip_button()
			set_dialog_message("level1", "tutorial")
			set_popup_message(num_visible_players, "level1", "tutorial_4")
		GameState.TUTORIAL_5:
			set_dialog_message("level1", "tutorial_ready")
			hide_popups()
		GameState.TUTORIAL_6:
			set_dialog_message("level1", "tutorial_ready")
			set_popup_message(num_visible_players, "level1", "tutorial_6")
		GameState.TUTORIAL_END:
			hide_dialog()
			set_popup_message(num_visible_players, "level1", "tutorial_end")
		GameState.COUNTDOWN_3:
			hide_dialog()
			set_popup_message(num_visible_players, "level1", "countdown_3")
		GameState.COUNTDOWN_2:
			hide_dialog()
			set_popup_message(num_visible_players, "level1", "countdown_2")
		GameState.COUNTDOWN_1:
			hide_dialog()
			set_popup_message(num_visible_players, "level1", "countdown_1")
		GameState.GAME_OVER:
			set_dialog_message("level1", "game_over")
			set_popup_message(num_visible_players, "level1", "game_over")

func load_messages():
	var file = FileAccess.open(messages_path, FileAccess.READ)
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	if parse_result == OK:
		messages = json.get_data()
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", file.get_path(), " at line ", json.get_error_line())

func set_default_messages():
	set_popup_message(1, "login", "tutorial")
	set_dialog_message("login", "start")
	hide_popups()
	hide_skip_button()

func set_popup_message(num_visible_players: int, level_type: String, key: String):
	var label = popup_one_player_label if num_visible_players == 1 else popup_two_players_label
	if messages.popup.has(level_type) and messages.popup[level_type].has(key):
		label.text = messages.popup[level_type][key]
	else:
		print("Popup message not found for ", num_visible_players, " players and key ", key)

	show_popup(num_visible_players)

func set_dialog_message(level_type: String, key: String):
	if messages.dialog.has(level_type) and messages.dialog[level_type].has(key):
		dialog_box_label.text = messages.dialog[level_type][key]
		if level_type == "login" and key == "start":
			apply_breath_effect()
		else:
			remove_breath_effect()
	else:
		print("Dialog message not found for key ", key)

	show_dialog()

func apply_breath_effect():
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_loops()
	tween.tween_property(dialog_box_label, "modulate:a", 0.1, 1.0)
	tween.tween_property(dialog_box_label, "modulate:a", 1.0, 0.8)

func remove_breath_effect():
	if tween:
		tween.kill()
	dialog_box_label.modulate.a = 1.0

func show_popup(num_visible_players: int):
	if num_visible_players == 1:
		popup_one_player_panel.show()
		popup_two_players_panel.hide()
	else:
		popup_one_player_panel.hide()
		popup_two_players_panel.show()

func hide_popups():
	popup_two_players_panel.hide()
	popup_one_player_panel.hide()

func show_dialog():
	dialog_box_panel.modulate.a = 1.0

func hide_dialog():
	dialog_box_panel.modulate.a = 0

func hide_all():
	hide_popups()
	hide_dialog()

func show_skip_button():
	skip_button.show()

func hide_skip_button():
	skip_button.hide()

func _on_return_area_body_entered(body: Node2D) -> void:
	return_area_entered.emit(body)

func _on_return_area_body_exited(body: Node2D) -> void:
	return_area_exited.emit(body)

func _on_skip_area_body_entered(body: Node2D) -> void:
	skip_area_entered.emit(body)

func _on_skip_area_body_exited(body: Node2D) -> void:
	skip_area_exited.emit(body)
