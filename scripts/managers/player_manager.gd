class_name PlayerManagerNode extends Node

var socket_client: SocketIOClientNode

var player_scene: PackedScene = preload("res://scenes/characters/player.tscn")
var current_players: Array[Node] = []
var spawn_position: Vector2 = Vector2(0, 5000)

# signal players_updated(players: Array[Node])

@export var max_players: int = 2
@export var player_sprites: Array[Texture2D] = [
	preload("res://assets/images/sprites/player1.svg"),
	preload("res://assets/images/sprites/player2.svg")
]

func spawn_players(num_players: int):
	var players_to_spawn = min(num_players, max_players)
	# Remove existing players
	while current_players.size() > players_to_spawn:
		var player = current_players.pop_back()
		player.queue_free()	
	
	# Spawn new players
	for i in range(players_to_spawn):
		var player: Node
		if i < current_players.size():
			player = current_players[i]
		else:
			player = player_scene.instantiate()
			player.position = spawn_position
			get_parent().add_child(player, true)
			current_players.append(player)

		if player.has_method("set_sprite") and i < player_sprites.size():
			player.set_sprite(player_sprites[i])
		else:
			push_warning("Player scene does not have a set_sprite method or sprite not available.")

# This function should be called when the number of detected balls changes
func update_players(num_players: int):
	if current_players.size() != num_players:
		spawn_players(num_players)

func get_player_node():
	if not current_players.is_empty():
		return current_players
	else:
		push_warning("No players spawned yet.")
		return null

func _on_connection_established():
	print("Connected to SocketIO server")

func _on_connection_error():
	print("Failed to connect to SocketIO server")

func _on_payload_received(event_name: String, payload: Variant):
	match event_name:
		"update":
			handle_center_mass(payload)

func handle_center_mass(payload: Variant):
	if payload.size() > 1 and payload["center_mass"].size() > 0:
		var center_masses = payload["center_mass"]
		var num_players = center_masses.size()

		update_players(num_players)
		
		if num_players > 0:
			# Sort center masses by x-coordinate
			center_masses.sort_custom(func(a, b): return a[0] < b[0])
			
			# Update player positions
			for i in range(min(num_players, current_players.size())):
				var player = current_players[i]
				var center_mass = Vector2(center_masses[i][0], center_masses[i][1])

				player.position = center_mass
	else:
		# Empty center_masses when payload is empty
		update_players(0)

func _ready():
	socket_client = SocketIOClientNode.new()
	add_child(socket_client)
	socket_client.init(ENV.socketio_url)
	socket_client.connection_established.connect(_on_connection_established)
	socket_client.connection_error.connect(_on_connection_error)
	socket_client.payload_received.connect(_on_payload_received)

func _process(_delta):
	socket_client.emit_event(ENV.event_datahub_contours, "", handle_center_mass)
