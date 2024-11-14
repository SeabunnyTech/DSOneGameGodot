extends Node2D

var turbine_front_speed = 0
var turbine_back_speed = 0

func _ready():
	for player in [PlayerManager.player1, PlayerManager.player2]:
		if player:
			player.connect("rotation_detected", _on_player_rotation_detected)

	# Start the turbine animations
	$Player1UI/TurbineBackRotate.play("rotate")
	$Player1UI/TurbineFrontRotate.play("rotate")

	# Hide all sprites initially
	# for sprite in get_children():
	# 	sprite.hide()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				toggle_sprite(0)
			KEY_2:
				toggle_sprite(1)
			KEY_3:
				toggle_sprite(2)
			KEY_4:
				toggle_sprite(3)
			KEY_T:
				transition_to_level_2()

func transition_to_level_2():
	# Add a short delay before transitioning
	await get_tree().create_timer(1.0).timeout
	# Change scene to level 2
	# get_tree().change_scene_to_file("res://scenes/levels/level2.tscn")

func toggle_sprite(index):
	if index < get_child_count():
		var sprite = get_child(index)
		sprite.visible = !sprite.visible

func _on_player_rotation_detected(_player: Node2D, clockwise: bool, speed: float):
	$Player1UI/TurbineBackRotate.speed_scale = speed * (1 if clockwise else -1) * 3
	$Player1UI/TurbineFrontRotate.speed_scale = speed * (1 if clockwise else -1) * 3
