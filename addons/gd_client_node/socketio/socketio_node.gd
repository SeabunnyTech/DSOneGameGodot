class_name SocketIOClientNode extends Node

signal connection_established
signal connection_error
signal payload_received(event_name: String, payload: Variant)

var client = SocketIOClient
var is_socketio_connected: bool = false  # Add this line to track connection state

func init(url: String):
	# initialize client
	client = SocketIOClient.new(url)
	
	client.name = "SocketIOClient" # Just for runtime debugging

	# this signal is emitted when the socket is ready to connect
	client.on_engine_connected.connect(on_socket_ready)

	# this signal is emitted when socketio server is connected
	client.on_connect.connect(on_socket_connect)

	# this signal is emitted when socketio server sends a message
	client.on_event.connect(on_socket_event)

	# add client to tree to start websocket
	add_child(client)

func on_socket_ready(_sid: String):
	# connect to socketio server when engine.io connection is ready
	client.socketio_connect()

func on_socket_connect(_payload: Variant, _name_space, error: bool):
	if error:
		push_error("Failed to connect to backend!")
		connection_error.emit()
	else:
		print("Socket connected")
		is_socketio_connected = true  # Set the connection state to true
		connection_established.emit()

func on_socket_event(event_name: String, payload: Variant, _name_space):
	payload_received.emit(event_name, payload)

func emit_event(event_name: String, data: Variant, handle_payload: Callable):
	if is_socketio_connected:
		client.socketio_emit(event_name, data, handle_payload)
	else:
		push_warning("Cannot emit event. Socket is not connected.")

func _exit_tree():
	# optional: disconnect from socketio server
	client.socketio_disconnect()
