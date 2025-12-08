@tool
extends Control

@onready var crown = $PanelContainer/HBoxContainer/crown


@export var texture_override : Texture2D = null

var score = 0:
	set(value):
		score = value
		%Score.text = str(score)


func reset():
	score = 0
	crown.modulate.a = 0
	crown.scale = Vector2(1,1)


func _ready() -> void:
	if texture_override:
		$PanelContainer/HBoxContainer/TextureRect.texture = texture_override



var crown_tween
func add_crown():
	if crown_tween:
		crown_tween.kill()

	crown_tween = create_tween()
	crown_tween.tween_property(crown, 'modulate:a', 1, 1)
	crown_tween.parallel().tween_property(crown, 'scale', Vector2(1.5, 1.5), 1)


var transition_tween
func fade(out=true):
	if transition_tween:
		transition_tween.kill()
	var target_alpha = 0 if out else 1
	transition_tween = create_tween()
	transition_tween.tween_property(self, 'modulate:a', target_alpha, 1)


func add_score():
	score += 1


var score_board_tween
func show_score_board():
	if score_board_tween:
		score_board_tween.kill()

	score_board_tween = create_tween()
	score_board_tween.tween_property(self, 'modulate:a', 1, 1)
