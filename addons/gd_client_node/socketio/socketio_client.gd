class_name SocketIOClient extends Node

enum EngineIOPacketType {
	open = 0,
	close = 1,
	ping = 2,
	pong = 3,
	message = 4,
	upgrade = 5,
	noop = 6,
}

enum SocketIOPacketType {
	CONNECT = 0,
	DISCONNECT = 1,
	EVENT = 2,
	ACK = 3,
	CONNECT_ERROR = 4,
	BINARY_EVENT = 5,
	BINARY_ACK = 6,
}

enum ConnectionState {
	DISCONNECTED,
	CONNECTED,
	RECONNECTING,
}

var _url: String
var _client: WebSocketPeer = WebSocketPeer.new()
var _sid: String
var _pingTimeout: int = 0
var _pingInterval: int = 0
var _auth: Variant = null
var _connection_state: ConnectionState = ConnectionState.DISCONNECTED
var _reconnect_timer: Timer = null
var _ack_counter: int = 0
var _ack_callbacks: Dictionary = {}
var _binary_event_data = null
var _binary_attachments = []
var _expected_binary_count = 0
var _packet_buffer = []
var _received_binary_count = 0


# triggered when engine.io connection is established
signal on_engine_connected(sid: String)
# triggered when engine.io connection is closed
signal on_engine_disconnected(code: int, reason: String)
# triggered when engine.io message is received
signal on_engine_message(payload: String)

# triggered when socket.io connection is established
signal on_connect(payload: Variant, name_space: String, error: bool)
# triggered when socket.io connection is closed
signal on_disconnect(name_space: String)
# triggered when socket.io event is received
signal on_event(event_name: String, payload: Variant, name_space: String)

# triggered when lost connection in not-clean way (i.e. service shut down)
# and now trying to reconnect. When re-connects successfully,
# the on_reconnected signal is emitted, instead of on_connect
signal on_connection_lost

# triggered when connects again after losing connection
# it's alternative to on_connect signal, but only emitted
# after automatically re-connecting with socket.io server
signal on_reconnected(payload: Variant, name_space: String, error: bool)

func _init(url: String, auth: Variant=null):
	_auth = auth 
	url = _preprocess_url(url)
	_url = "%s?EIO=4&transport=websocket" % url

func _preprocess_url(url: String) -> String:
	if not url.ends_with("/"):
		url = url + "/"
	if url.begins_with("https"):
		url = "wss" + url.erase(0, len("https"))
	elif url.begins_with("http"):
		url = "ws" + url.erase(0, len("http"))
	return url

func _ready():
	_client.connect_to_url(_url)
	# Instead of connecting directly, perform HTTP handshake first

func _connect_websocket():
	var full_url = _url + "&sid=" + _sid
	print("Connecting to WebSocket: ", full_url)
	_client.connect_to_url(full_url)

func _process(_delta):
	_client.poll()

	var state = _client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while _client.get_available_packet_count():
			var packet = _client.get_packet()
			var is_string = _client.was_string_packet()
			_packet_buffer.append({"is_string": is_string, "data": packet})
		
		_process_packet_buffer()

	elif state == WebSocketPeer.STATE_CLOSED:
		set_process(false)

		var code = _client.get_close_code()
		var reason = _client.get_close_reason()

		if code == -1:
			# -1 is not-clean disconnect (i.e. Service shut down)
			# we should try to reconnect

			_connection_state = ConnectionState.RECONNECTING

			_reconnect_timer = Timer.new()
			_reconnect_timer.wait_time = 1.0
			_reconnect_timer.timeout.connect(_on_reconnect_timer_timeout)
			_reconnect_timer.autostart = true
			add_child(_reconnect_timer)

			on_connection_lost.emit()
		else:
			_connection_state = ConnectionState.DISCONNECTED
			on_engine_disconnected.emit(code, reason)

func _on_reconnect_timer_timeout():
	_client.poll()
	var state = _client.get_ready_state()
	if state == WebSocketPeer.STATE_CLOSED:
		_client.connect_to_url(_url)
	else:
		set_process(true)
		_reconnect_timer.queue_free()

func _exit_tree():
	if _connection_state == ConnectionState.CONNECTED:
		_engineio_send_packet(EngineIOPacketType.close)

	_client.close()

func _engineio_decode_packet(packet: String):
	var packetType = int(packet.substr(0, 1))
	var packetPayload = packet.substr(1)

	match packetType:
		EngineIOPacketType.open:
			var json = JSON.new()
			json.parse(packetPayload)
			_sid = json.data["sid"]
			_pingTimeout = int(json.data["pingTimeout"])
			_pingInterval = int(json.data["pingInterval"])
			on_engine_connected.emit(_sid)

		EngineIOPacketType.ping:
			_engineio_send_packet(EngineIOPacketType.pong)

		EngineIOPacketType.message:
			_socketio_parse_packet(packetPayload)
			on_engine_message.emit(packetPayload)

func _engineio_send_packet(type: EngineIOPacketType, payload: String=""):
	if len(payload) == 0:
		_client.send_text("%d" % type)
	else:
		_client.send_text("%d%s" % [type, payload])


func _socketio_parse_packet(payload: String):
	var packetType = int(payload.substr(0, 1))
	payload = payload.substr(1)

	var regex = RegEx.new()
	regex.compile("(\\d+)-")
	var regexMatch = regex.search(payload)
	if regexMatch and regexMatch.get_start() == 0:
		_expected_binary_count = int(regexMatch.get_string(1))
		_received_binary_count = 0
		payload = payload.substr(regexMatch.get_end())
		# print("Binary data payload detected. Binary attachments count: ", _expected_binary_count)
	
	var name_space = "/"
	regex.compile("(\\w),")
	regexMatch = regex.search(payload)
	if regexMatch and regexMatch.get_start() == 0:
		payload = payload.substr(regexMatch.get_end())
		name_space = regexMatch.get_string(1)

	var ack_id = null
	regex.compile("(\\d+)")
	regexMatch = regex.search(payload)
	if regexMatch and regexMatch.get_start() == 0:
		payload = payload.substr(regexMatch.get_end())
		ack_id = int(regexMatch.get_string(1))

	var data = null
	if len(payload) > 0:
		var json = JSON.new()
		if json.parse(payload) == OK:
			data = json.get_data()

	match packetType:
		SocketIOPacketType.CONNECT:
			if _connection_state == ConnectionState.RECONNECTING:
				_connection_state = ConnectionState.CONNECTED
				on_reconnected.emit(data, name_space, false)
			else:
				_connection_state = ConnectionState.CONNECTED
				on_connect.emit(data, name_space, false)

		SocketIOPacketType.CONNECT_ERROR:
			if _connection_state == ConnectionState.RECONNECTING:
				_connection_state = ConnectionState.CONNECTED
				on_reconnected.emit(data, name_space, true)
			else:
				_connection_state = ConnectionState.CONNECTED
				on_connect.emit(data, name_space, true)

		SocketIOPacketType.EVENT, SocketIOPacketType.BINARY_EVENT, SocketIOPacketType.BINARY_ACK:
			if typeof(data) != TYPE_ARRAY:
				push_error("Invalid socketio event format!")
			else:
				var eventName = "update"  # Assuming the event name is "update"
				var eventData = data[0] if len(data) > 0 else null
				if _expected_binary_count > 0:
					_binary_event_data = eventData
				else:
					on_event.emit(eventName, eventData, "/")  # Assuming default namespace

		SocketIOPacketType.ACK:
			if ack_id != null and _ack_callbacks.has(ack_id):
				var callback = _ack_callbacks[ack_id]
				callback.call(data)
				_ack_callbacks.erase(ack_id)

func _socketio_send_packet(type: SocketIOPacketType, name_space: String, data: Variant=null, binaryData: Array[PackedByteArray]=[], ack_id: Variant=null):
	var payload = "%d" % type
	if binaryData.size() > 0:
		payload += "%d-" % binaryData.size()
	if name_space != "/":
		payload += "%s," % name_space
	if ack_id != null:
		payload += "%d" % ack_id
	if data != null:
		payload += "%s" % JSON.stringify(data)

	_engineio_send_packet(EngineIOPacketType.message, payload)

	for binary in binaryData:
		_client.put_packet(binary)


func _process_packet_buffer():
	while not _packet_buffer.is_empty():
		var packet = _packet_buffer[0]
		if packet.is_string:
			var packetString = packet.data.get_string_from_utf8()
			if len(packetString) > 0:
				_engineio_decode_packet(packetString)
			_packet_buffer.pop_front()
		else:
			if _expected_binary_count > 0:
				_handle_binary_packet(packet.data)
				_packet_buffer.pop_front()
			else:
				# We've received a binary packet but we're not expecting one yet
				# This means we haven't processed the string packet that sets up the binary data
				# So we'll break and wait for the next _process call
				break

func _handle_binary_packet(packet):
	if _binary_event_data != null:
		_binary_attachments.append(packet)
		_received_binary_count += 1
		if _received_binary_count == _expected_binary_count:
			_process_complete_binary_event()
	else:
		push_error("Received unexpected binary packet")

func _process_complete_binary_event():
	var event_data = _binary_event_data
	_binary_event_data = null
	var attachments = _binary_attachments
	_binary_attachments = []
	_expected_binary_count = 0
	_received_binary_count = 0

	_replace_placeholders(event_data, attachments)

	# Emit the event with the complete data
	on_event.emit("update", event_data, "/")  # Assuming default namespace and "update" event name

func _replace_placeholders(data, attachments):
	if typeof(data) == TYPE_DICTIONARY:
		for key in data.keys():
			if data[key] is Dictionary and data[key].has("_placeholder"):
				var index = data[key]["num"]
				if index < len(attachments):
					data[key] = attachments[index]
			else:
				_replace_placeholders(data[key], attachments)
	elif typeof(data) == TYPE_ARRAY:
		for i in range(len(data)):
			if data[i] is Dictionary and data[i].has("_placeholder"):
				var index = data[i]["num"]
				if index < len(attachments):
					data[i] = attachments[index]
			else:
				_replace_placeholders(data[i], attachments)

func get_connection_state() -> ConnectionState:
	return _connection_state

# connect to socket.io server by namespace
func socketio_connect(name_space: String="/"):
	_socketio_send_packet(SocketIOPacketType.CONNECT, name_space, _auth)

# disconnect from socket.io server by namespace
func socketio_disconnect(name_space: String="/"):
	if _connection_state == ConnectionState.CONNECTED:
		# We should ONLY send disconnect packet when we're connected
		_socketio_send_packet(SocketIOPacketType.DISCONNECT, name_space)

	on_disconnect.emit(name_space)

# send event to socket.io server by namespace
func socketio_send(event_name: String, payload: Variant=null, name_space: String="/"):
	if payload == null:
		_socketio_send_packet(SocketIOPacketType.EVENT, name_space, [event_name])
	else:
		_socketio_send_packet(SocketIOPacketType.EVENT, name_space, [event_name, payload])

# Add this new method to the SocketIOClient class
func socketio_emit(event_name: String, data: Variant = null, callback: Callable = Callable(), name_space: String="/"):
	var payload = [event_name]
	if data != null:
		payload.append(data)
	
	var ack_id = null
	if callback.is_valid():
		ack_id = _generate_ack_id()
		_store_ack_callback(ack_id, callback)
	
	_socketio_send_packet(SocketIOPacketType.EVENT, name_space, payload, [], ack_id)

# Helper method to generate a unique acknowledgement ID
func _generate_ack_id() -> int:
	# Implement a way to generate unique IDs, e.g., incrementing counter
	_ack_counter += 1
	return _ack_counter

# Helper method to store callback for later use
func _store_ack_callback(ack_id: int, callback: Callable):
	# Implement a way to store callbacks, e.g., in a dictionary
	_ack_callbacks[ack_id] = callback
