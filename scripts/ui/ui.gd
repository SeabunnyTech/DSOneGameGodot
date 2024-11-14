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

var tween: Tween

func _ready():
	load_messages()
	set_default_messages()
	# Get the root parent node (scene)
	var root_parent = get_parent()
	
	var scene_name = root_parent.name
	print("UI loaded under scene: ", scene_name)
	
	# Connect signals based on scene
	match scene_name:
		"Login":
			connect_login_signals(root_parent)
		"Level1_1p", "Level1_2p":
			connect_level1_signals(root_parent)
		"Level2_1p", "Level2_2p":
			connect_level2_signals(root_parent)

func connect_login_signals(root_parent: Node):
	root_parent.connect("login_signup", _on_login_signup)
	root_parent.connect("login_start", _on_login_start)
	root_parent.connect("login_wait_for_players", _on_login_wait_for_players)
	root_parent.connect("login_tutorial", _on_login_tutorial)
	root_parent.connect("login_select_level", _on_login_select_level)

func connect_level1_signals(root_parent: Node):
	hide_all()
	# root_parent.connect("level1_tutorial_1", _on_level1_tutorial_1)
	pass

func connect_level2_signals(root_parent: Node):
	# root_parent.connect("level2_tutorial_1", _on_level2_tutorial_1)
	hide_all()
	pass

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

func set_dialog_message(level_type: String, key: String):
	if messages.dialog.has(level_type) and messages.dialog[level_type].has(key):
		dialog_box_label.text = messages.dialog[level_type][key]
		if level_type == "login" and key == "start":
			apply_breath_effect()
		else:
			remove_breath_effect()
	else:
		print("Dialog message not found for key ", key)

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
	dialog_box_panel.show()

func hide_dialog():
	dialog_box_panel.hide()

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

func _on_login_signup(_num_visible_players: int):
	set_dialog_message("login", "signup")
	hide_popups()

func _on_login_start():
	set_dialog_message("login", "start")
	hide_popups()

func _on_login_wait_for_players():
	set_dialog_message("login", "wait_for_second_player")
	hide_popups()

func _on_login_tutorial(num_visible_players: int):
	set_dialog_message("login", "tutorial")
	show_popup(num_visible_players)
	set_popup_message(num_visible_players, "login", "tutorial")

func _on_login_select_level():
	set_dialog_message("login", "select_level")
	hide_popups()

func _on_login_transition():
	set_dialog_message("login", "transition")
	hide_popups()
