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

signal return_area_entered(body: Node2D)
signal return_area_exited(body: Node2D)
signal skip_area_entered(body: Node2D)
signal skip_area_exited(body: Node2D)

# 動畫用變數
var tween: Tween

func _ready():
	load_messages()
	set_default_messages()
	
	GameState.ui_state_updated.connect(_on_ui_state_updated)
	# 通知 GameState UI 已準備完成
	SignalBus.ui_ready.emit()

func _on_ui_state_updated(state_info: Dictionary):
	var scene = state_info.scene
	var stage = state_info.stage
	var num_visible_players = state_info.num_visible_players

	match scene:
		GameState.GameScene.LOGIN:
			_handle_login_state(stage, num_visible_players)
		GameState.GameScene.LEVEL1:
			_handle_level1_state(stage, num_visible_players)

# Login 相關處理
func _handle_login_state(stage: GameState.GameStage, num_visible_players: int = 0):
	match stage:
		GameState.GameStage.LOGIN_START:
			set_dialog_message("login", "start")
			hide_popups()
		GameState.GameStage.LOGIN_SIGNUP:
			set_dialog_message("login", "signup")
			hide_popups()
		GameState.GameStage.LOGIN_WAIT_FOR_SECOND_PLAYER:
			set_dialog_message("login", "wait_for_second_player")
			hide_popups()
		GameState.GameStage.LOGIN_TUTORIAL:
			set_dialog_message("login", "tutorial")
			set_popup_message(num_visible_players, "login", "tutorial")
		GameState.GameStage.LOGIN_SELECT_LEVEL:
			set_dialog_message("login", "select_level")
			hide_popups()

# Level1 相關處理
func _handle_level1_state(stage: GameState.GameStage, num_visible_players: int = 0):
	match stage:
		GameState.GameStage.LEVEL_START:
			set_dialog_message("level1", "tutorial")
		GameState.GameStage.TUTORIAL_1:
			show_skip_button()
			set_dialog_message("level1", "tutorial")
			set_popup_message(num_visible_players, "level1", "tutorial_1")
		GameState.GameStage.TUTORIAL_2:
			set_dialog_message("level1", "tutorial")
			set_popup_message(num_visible_players, "level1", "tutorial_2")
		GameState.GameStage.TUTORIAL_3:
			set_dialog_message("level1", "tutorial")
			set_popup_message(num_visible_players, "level1", "tutorial_3")
		GameState.GameStage.TUTORIAL_4:
			hide_skip_button()
			set_dialog_message("level1", "tutorial")
			set_popup_message(num_visible_players, "level1", "tutorial_4")
		GameState.GameStage.TUTORIAL_5:
			set_dialog_message("level1", "tutorial_ready")
			hide_popups()
		GameState.GameStage.TUTORIAL_6:
			set_dialog_message("level1", "tutorial_ready")
			set_popup_message(num_visible_players, "level1", "tutorial_6")
		GameState.GameStage.TUTORIAL_END:
			hide_dialog()
			set_popup_message(num_visible_players, "level1", "tutorial_end")
		GameState.GameStage.COUNTDOWN_3:
			hide_dialog()
			set_popup_message(num_visible_players, "level1", "countdown_3")
		GameState.GameStage.COUNTDOWN_2:
			hide_dialog()
			set_popup_message(num_visible_players, "level1", "countdown_2")
		GameState.GameStage.COUNTDOWN_1:
			hide_dialog()
			set_popup_message(num_visible_players, "level1", "countdown_1")
		GameState.GameStage.GAME_PLAY:
			hide_dialog()
			hide_popups()
		GameState.GameStage.GAME_OVER:
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
