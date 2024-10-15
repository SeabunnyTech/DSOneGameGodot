extends Node

var messages: Dictionary

@onready var popup_one_player_panel: Panel = %PopupMessageOnePlayer
@onready var popup_one_player_label: Label = %PopupMessageOnePlayerLabel
@onready var popup_two_players_panel: Panel = %PopupMessageTwoPlayers
@onready var popup_two_players_label: Label = %PopupMessageTwoPlayersLabel
@onready var dialog_box_panel: PanelContainer = %DialogBox
@onready var dialog_box_label: Label = %DialogBoxLabel

func _ready():
	load_messages()
	set_default_messages()
	hide_all()

func load_messages():
	var file = FileAccess.open("res://assets/text/ui_messages.json", FileAccess.READ)
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	if parse_result == OK:
		messages = json.get_data()
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", file.get_path(), " at line ", json.get_error_line())

func set_default_messages():
	set_popup_message("two_players", "default")
	set_popup_message("one_player", "default")
	set_dialog_message("level_select")

func set_popup_message(player_type: String, key: String):
	var label = popup_two_players_label if player_type == "two_players" else popup_one_player_label
	if messages.popup.has(player_type) and messages.popup[player_type].has(key):
		label.text = messages.popup[player_type][key]
	else:
		print("Popup message not found for ", player_type, " and key ", key)

func set_dialog_message(key: String):
	if messages.dialog.has(key):
		dialog_box_label.text = messages.dialog[key]
	else:
		print("Dialog message not found for key ", key)

func show_popup(player_type: String):
	if player_type == "two_players":
		popup_two_players_panel.show()
		popup_one_player_panel.hide()
	else:
		popup_one_player_panel.show()
		popup_two_players_panel.hide()

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
