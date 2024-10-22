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
	
	if get_parent().get_parent().has_node("Login"):
		get_parent().get_parent().get_node("Login").connect("ready_to_start", _on_ready_to_start)
		get_parent().get_parent().get_node("Login").connect("wait_for_players", _on_wait_for_players)
	# hide_all()

func load_messages():
	var file = FileAccess.open(messages_path, FileAccess.READ)
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	if parse_result == OK:
		messages = json.get_data()
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", file.get_path(), " at line ", json.get_error_line())

func set_default_messages():
	set_popup_message("one_player", "login", "ready")
	set_popup_message("two_players", "login", "ready")
	set_dialog_message("login", "start")
	hide_popups()
	hide_skip_button()

func set_popup_message(player_type: String, level_type: String, key: String):
	var label = popup_two_players_label if player_type == "two_players" else popup_one_player_label
	if messages.popup.has(level_type) and messages.popup[level_type].has(key):
		label.text = messages.popup[level_type][key]
	else:
		print("Popup message not found for ", player_type, " and key ", key)

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

func _on_ready_to_start(_players: int):
	set_dialog_message("login", "signup")

func _on_wait_for_players():
	set_dialog_message("login", "start")
