class_name PlayerManagerNode extends Node

var socket_client: SocketIOClientNode
var viewport_size: Vector2 = Globals.get_viewport_size()

var player_scene: PackedScene = preload("res://scenes/characters/player.tscn")

var player1: Node = player_scene.instantiate()
var player2: Node = player_scene.instantiate()

var current_players: Array[Node] = [player1, player2]

@export var freeze_player_detection: bool = false
@export var disappearance_buffer_frames: int = 180  # Frames to wait before hiding a player

var player_position: Array[Vector2] = []
var player_buffer_counters: Array[int] = [0, 0]
var player_colors = {
	"player1": {
		"active": Color.hex(0x00B6EEFF),
		"inactive": Color.hex(0x8F8F8FFF)
	},
	"player2": {
		"active": Color.hex(0x006888FF),
		"inactive": Color.hex(0x8F8F8FFF)
	}
}

# Dev mode variables
var active_dev_player: Node = null
var dev_mode_active: bool = false

# TODO: 同時考量偵測 camera 視角變化時，需要對應到 viewport 和 player 位置
func handle_center_mass(payload: Variant):
	if payload.size() > 1 and payload["center_mass"].size() > 0:
		var center_masses = payload["center_mass"]

		# Sort center masses by x-coordinate
		center_masses.sort_custom(func(a, b): return a[0] < b[0])

		# Save sorted center masses into player_position array
		player_position = []
		for cm in center_masses:
			player_position.append(Vector2(cm[0], cm[1]))
			# Limit the number of players to 2
			if player_position.size() == 2:
				break

		# Reset buffer counters and update last seen time for visible players
		for i in range(player_position.size()):
			player_buffer_counters[i] = 0
	else:
		player_position = []

	# Increment buffer counters for missing players
	for i in range(current_players.size()):
		if i >= player_position.size():
			player_buffer_counters[i] += 1

func update_player_positions():
	var num_players = player_position.size()

	for i in range(current_players.size()):
		var player = current_players[i]

		if i < num_players:
			var center_mass = Vector2(player_position[i][0], player_position[i][1])

			var scaled_position = Vector2(
				(center_mass.x / 512.0) * viewport_size.x,
				(center_mass.y / 424.0) * viewport_size.y
			)

			var reversed_position_y = viewport_size.y - scaled_position.y

			var new_target_position = Vector2(scaled_position.x, reversed_position_y)

			player.set_target_position(new_target_position)

			# If the player has just reappeared, update its position immediately
			if player.visible == false:
				player.position = new_target_position

			# Show the player
			player.visible = true
			player_buffer_counters[i] = 0
		else:
			if freeze_player_detection:
				return
			# Check if the player should be hidden due to buffer or timeout
			if player_buffer_counters[i] >= disappearance_buffer_frames:
				player.visible = false

func toggle_player(player_index: int) -> void:
	var player = current_players[player_index]
	
	# Player 1 specific logic
	if player_index == 0:
		if active_dev_player != player:
			active_dev_player = player
			player.visible = true
		elif current_players[1].visible == false:
			active_dev_player = null
			player.visible = false
	
	# Player 2 specific logic
	else:  # player_index == 1
		if active_dev_player != player and current_players[0].visible:
			active_dev_player = player
			player.visible = true
		elif active_dev_player == player:
			active_dev_player = null
			player.visible = false

func _on_player_countdown_complete(player: Node2D):
	print("Player countdown complete: ", player.name)

func _on_player_countdown_cancelled(player: Node2D):
	print("Player countdown cancelled: ", player.name)

func _on_connection_established():
	print("Connected to SocketIO server")

func _on_connection_error():
	print("Failed to connect to SocketIO server")

func _on_payload_received(event_name: String, payload: Variant):
	match event_name:
		"update":
			handle_center_mass(payload)

func _init_socket_client():
	# Initialize SocketIO client
	socket_client = SocketIOClientNode.new()
	socket_client.name = "SocketIOClientNode" # Just for runtime debugging
	add_child(socket_client)

	socket_client.init(ENV.socketio_url)
	socket_client.connection_established.connect(_on_connection_established)
	socket_client.connection_error.connect(_on_connection_error)
	socket_client.payload_received.connect(_on_payload_received)

func _init_player_layer():
	var player_layer = CanvasLayer.new()
	player_layer.name = "PlayerLayer"
	player_layer.layer = 1
	add_child(player_layer)

	for player in current_players:
		player.visible = false
		player.z_index = 5
		player_layer.add_child(player, true)
		player.add_to_group("Players")
		player.countdown_complete.connect(_on_player_countdown_complete)
		player.countdown_cancelled.connect(_on_player_countdown_cancelled)


func _setup_dev_mode():
	if Globals.mouse_mode:
		dev_mode_active = true
		active_dev_player = current_players[0]

func _init_player_color():
	player1.set_color(0x00b6eecc)
	player2.set_color(0x006888cc)

func _on_viewport_size_changed():
	viewport_size = get_viewport().size
	Globals.set_viewport_size(viewport_size)

func _ready():
	# 初始化 viewport size
	viewport_size = get_viewport().size
	Globals.set_viewport_size(viewport_size)

	get_tree().root.connect("size_changed", _on_viewport_size_changed)

	_init_socket_client()
	_init_player_layer()
	_setup_dev_mode()
	_init_player_color()

func _process(_delta):
	if dev_mode_active:
		# Handle player switching
		if Input.is_action_just_pressed("toggle_player1"):
			toggle_player(0)
		if Input.is_action_just_pressed("toggle_player2"):
			toggle_player(1)

		# Move active player with mouse
		if active_dev_player:
			var mouse_pos = get_viewport().get_mouse_position()
			active_dev_player.set_target_position(mouse_pos)
	
	else:
		# Normal mode: Use SocketIO
		socket_client.emit_event(ENV.event_datahub_contours, "", handle_center_mass)
		update_player_positions()
