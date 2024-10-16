class_name PlayerManagerNode extends Node

var socket_client: SocketIOClientNode

var player1_scene: PackedScene = preload("res://scenes/characters/player1.tscn")
var player2_scene: PackedScene = preload("res://scenes/characters/player2.tscn")
var player1: Node = player1_scene.instantiate()
var player2: Node = player2_scene.instantiate()

var current_players: Array[Node] = [player1, player2]

var viewport_size: Vector2 = Globals.viewport_size
var player_position: Array[Vector2] = []
var player_last_spawn_position: Array[Vector2] = [Vector2(0, 5000), Vector2(0, 5000)]

# signal players_updated(players: Array[Node])

@export var smoothing_speed: float = 30.0

func handle_center_mass(payload: Variant):
	if payload.size() > 1 and payload["center_mass"].size() > 0:
		var center_masses = payload["center_mass"]

		# Sort center masses by x-coordinate
		center_masses.sort_custom(func(a, b): return a[0] < b[0])

		# Save sorted center masses into player_position array
		player_position = []
		for cm in center_masses:
			player_position.append(Vector2(cm[0], cm[1]))
	else:
		player_position = []

func update_player_positions():
	var num_players = player_position.size()

	if num_players > 0:
		# TODO: Handle single player case
		if num_players == 1:
			player2.visible = false

		# Update player positions
		for i in range(min(num_players, current_players.size())):
			var player = current_players[i]
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

	else:
		# Hide all players when payload is empty
		for player in current_players:
			player.visible = false

# Add this new method to your class
func _physics_process(delta: float):
	for player in current_players:
		player.position = player.position.lerp(player.target_position, smoothing_speed * delta)

func _on_connection_established():
	print("Connected to SocketIO server")

func _on_connection_error():
	print("Failed to connect to SocketIO server")

func _on_payload_received(event_name: String, payload: Variant):
	match event_name:
		"update":
			handle_center_mass(payload)

func _ready():
	socket_client = SocketIOClientNode.new()
	socket_client.name = "SocketIOClientNode" # Just for runtime debugging
	add_child(socket_client)
	socket_client.init(ENV.socketio_url)
	socket_client.connection_established.connect(_on_connection_established)
	socket_client.connection_error.connect(_on_connection_error)
	socket_client.payload_received.connect(_on_payload_received)

	viewport_size = get_viewport().size

	player1.visible = false
	player2.visible = false

	add_child(player1, true)
	add_child(player2, true)

func _process(_delta):
	if Globals.dev_mode:
		# Dev mode: Control player1 with mouse
		var mouse_pos = get_viewport().get_mouse_position()
		var dev_player = current_players[0]
		dev_player.position = mouse_pos
		player1.visible = true
		player2.visible = false
	else:
		# Normal mode: Use SocketIO
		socket_client.emit_event(ENV.event_datahub_contours, "", handle_center_mass)
		update_player_positions()
