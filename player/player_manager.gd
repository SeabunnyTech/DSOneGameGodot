class_name PlayerManagerNode extends Node

var socket_client: SocketIOClientNode

var viewport_size: Vector2 = Globals.get_viewport_size()

var PState = Player.State
var player_scene: PackedScene = preload("res://player/player.tscn")
var player1: Node = player_scene.instantiate()
var player2: Node = player_scene.instantiate()

var current_players: Array[Node] = [player1, player2]

signal player_visibility_changed(player: Node, _is_visible: bool)
signal player_countdown_completed(player: Node)

@export var freeze_player_detection: bool = false
@export var disappearance_buffer_frames: int = 180  # Frames to wait before hiding a player


# 用 hsv 中的色相 hue 區分玩家, 用飽和度 saturation 及透明度 alpha 來表達不同狀態
var player_hue = {
	0:0.50,
	1:0.45
}


var player_visibility: Array[bool] = [false, false]

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

# Contour debug data (full payload for CameraDebug to read)
var latest_contour_data: Dictionary = {}

# Dev mode variables
var active_dev_player: Node = null
var dev_mode_active: bool = false


func num_active_players():
	var num = 0
	for player in current_players:
		if player.state != PState.LOST:
			num += 1
	return num


func convert_to_positions(center_mass_array) -> Array[Vector2]:
	var center_positions : Array[Vector2] = []
	for center_mass in center_mass_array:
		var xres = Globals.camera_resolution[0]
		var yres = Globals.camera_resolution[1]
		var move_scale = Globals.player_move_scale
		var relative_position = Vector2(
			((center_mass[0] / xres) - 0.5) * move_scale + 0.5,
			((center_mass[1] / yres) - 0.5) * move_scale + 0.5,
		)

		if Globals.flip_camera_x:
			relative_position[0] = 1.0 - relative_position[0]

		if Globals.flip_camera_y:
			relative_position[1] = 1.0 - relative_position[1]

		var scaled_position = relative_position * viewport_size
		center_positions.append(scaled_position)

	return center_positions


# TODO: 同時考量偵測 camera 視角變化時，需要對應到 viewport 和 player 位置
func handle_center_mass(payload: Variant):
	if payload is Dictionary:
		latest_contour_data = payload
	elif payload is Array and payload.size() > 0 and payload[0] is Dictionary:
		latest_contour_data = payload[0]
	var center_positions = []
	if payload.size() > 1 and payload["center_mass"].size() > 0:
		# 取得 center mass
		var center_masses = payload["center_mass"]

		# 只留下前兩個座標
		center_masses = center_masses.slice(0, 2)

		# 轉換成 player 座標
		center_positions = convert_to_positions(center_masses)

		# 用 x 座標排序: 左邊是 player1 右邊是 player2
		center_positions.sort_custom(func(a, b): return a[0] < b[0])

		# 更新屎山代碼中的變數 player_position 來幫助狀態轉換
		# 先前的程式碼會看這個變數裡有幾項來決定要不要把 player fade 或者 activate
		player_position = center_positions.duplicate()

		# 設定有在 center_positions 清單內的 player 位置 (玩家數量可能是 0~2)
		var multiplayer_x_offset = [0, 0]
		if player2.visible:
			var dx = Globals.dual_player_x_offset
			multiplayer_x_offset = [dx, -dx]

		for i in range(center_positions.size()):
			var player = current_players[i]
			var new_target_position = center_positions[i]
			new_target_position[0] +=  multiplayer_x_offset[i] * viewport_size[0]
			if player.state in [PState.FADED, PState.LOST]:
				player.position = new_target_position
			player.set_target_position(new_target_position)

		# 根據 center_positions 更新 player_buffer_counters (間接更新狀態) 
		for i in range(center_positions.size()):
			player_buffer_counters[i] = 0
	else:
		player_position = []

	# player 不在的話增加 player_buffer_counters
	for i in range(current_players.size()):
		if i >= center_positions.size():
			player_buffer_counters[i] += 1


func update_player_states():
	var num_players = player_position.size()

	for i in range(current_players.size()):
		var player = current_players[i]

		if i < num_players:
			# If the player has just reappeared, update its position immediately
			# Show the player
			player.heads_to_state(PState.ACTIVE)
			player_buffer_counters[i] = 0
		else:
			if freeze_player_detection:
				return
			# Check if the player should be hidden due to buffer or timeout
			if player_buffer_counters[i] >= disappearance_buffer_frames:
				player.heads_to_state(PState.LOST)

func toggle_player(player_index: int) -> void:
	var player = current_players[player_index]
	
	# Player 1 specific logic
	if player_index == 0:
		if active_dev_player != player:
			active_dev_player = player
			player.heads_to_state(PState.ACTIVE)
		elif current_players[1].state == PState.LOST:
			active_dev_player = null
			player.heads_to_state(PState.LOST)
	
	# Player 2 specific logic
	else:  # player_index == 1
		if active_dev_player != player and current_players[0].state > PState.LOST:
			active_dev_player = player
			player.heads_to_state(PState.ACTIVE)
		elif active_dev_player == player:
			active_dev_player = null
			player.heads_to_state(PState.LOST)

func _on_player_visibility_changed(player: Node) -> void:
	player_visibility_changed.emit(player, player.visible)

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

	for idx in range(len(current_players)):
		var player = current_players[idx]
		player.index = idx
		#player.heads_to_state(PState.LOST)
		player.visible = false
		player.z_index = 5
		player_layer.add_child(player, true)
		player.add_to_group("player" + str(idx))
		player.visibility_changed.connect(_on_player_visibility_changed.bind(player))

func _setup_dev_mode():
	if Globals.mouse_mode:
		dev_mode_active = true
		active_dev_player = current_players[0]


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


func update_player_trigger_state(player: Player, triggering: bool):
	if player.heading_state not in [PState.FADED, PState.LOST]:
		player.heads_to_state(PState.TRIGGERED if triggering else PState.ACTIVE)


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
			if active_dev_player.state in [PState.FADED, PState.LOST]:
				active_dev_player.position = mouse_pos
			else:
				active_dev_player.set_target_position(mouse_pos)
	
	else:
		# Normal mode: Use SocketIO
		if socket_client.is_socketio_connected:
			socket_client.emit_event(ENV.event_datahub_contours, "", handle_center_mass)
		update_player_states()
