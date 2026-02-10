extends Node

enum Mode { OFF, CAMERA, CONTOUR }

var current_mode: Mode = Mode.OFF

var _canvas_layer: CanvasLayer
var _texture_rect: TextureRect
var _contour_draw: Control
var _label: Label
var _status_label: Label
var _requesting: bool = false
var _bgr_shader: Shader
var _debug_timer: float = 0.0
var _frame_request_count: int = 0
var _frame_received_count: int = 0
var _contour_draw_count: int = 0


func _ready():
	_bgr_shader = Shader.new()
	_bgr_shader.code = """shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(c.b, c.g, c.r, c.a);
}
"""

	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100
	_canvas_layer.visible = false
	add_child(_canvas_layer)

	# Black background
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas_layer.add_child(bg)

	# TextureRect for camera image
	_texture_rect = TextureRect.new()
	_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_texture_rect.visible = false
	var mat = ShaderMaterial.new()
	mat.shader = _bgr_shader
	_texture_rect.material = mat
	_canvas_layer.add_child(_texture_rect)

	# Custom draw control for contour
	_contour_draw = Control.new()
	_contour_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_contour_draw.visible = false
	_contour_draw.draw.connect(_on_contour_draw)
	_canvas_layer.add_child(_contour_draw)

	# Mode label
	_label = Label.new()
	_label.position = Vector2(20, 20)
	_label.add_theme_font_size_override("font_size", 48)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_canvas_layer.add_child(_label)

	# Status label (debug info)
	_status_label = Label.new()
	_status_label.position = Vector2(20, 80)
	_status_label.add_theme_font_size_override("font_size", 32)
	_status_label.add_theme_color_override("font_color", Color.YELLOW)
	_canvas_layer.add_child(_status_label)


func _input(event: InputEvent):
	if event.is_action_pressed("toggle_camera_debug"):
		_cycle_mode()


func _cycle_mode():
	match current_mode:
		Mode.OFF:
			current_mode = Mode.CONTOUR
		_:
			current_mode = Mode.OFF
	print("[CameraDebug] Mode switched to: ", Mode.keys()[current_mode])
	_apply_mode()


func _apply_mode():
	_requesting = false
	_debug_timer = 0.0
	_frame_request_count = 0
	_frame_received_count = 0
	match current_mode:
		Mode.OFF:
			_canvas_layer.visible = false
			_texture_rect.visible = false
			_contour_draw.visible = false
		Mode.CAMERA:
			_canvas_layer.visible = true
			_texture_rect.visible = true
			_contour_draw.visible = false
			_label.text = "CAMERA DEBUG"
			_request_camera_frame()
		Mode.CONTOUR:
			_canvas_layer.visible = true
			_texture_rect.visible = false
			_contour_draw.visible = true
			_label.text = "CONTOUR DEBUG"


func _process(delta):
	if current_mode == Mode.CAMERA:
		_debug_timer += delta
		# Update on-screen status label every frame
		var sc = PlayerManager.socket_client
		var connected = sc != null and sc.is_socketio_connected
		_status_label.text = "socket=%s  requesting=%s  sent=%d  recv=%d" % [
			"connected" if connected else ("null" if sc == null else "disconnected"),
			_requesting,
			_frame_request_count,
			_frame_received_count
		]
		if _debug_timer >= 3.0:
			_debug_timer = 0.0
			print("[CameraDebug] STATUS: requesting=", _requesting, " connected=", connected,
				" requests_sent=", _frame_request_count, " frames_received=", _frame_received_count)
			# If stuck requesting, retry
			if _requesting:
				print("[CameraDebug] Stuck requesting for 3s, resetting _requesting flag")
				_requesting = false
				call_deferred("_request_camera_frame")
	if current_mode == Mode.CONTOUR:
		_contour_draw.queue_redraw()


# --------------- CAMERA mode ---------------

func _request_camera_frame():
	if _requesting:
		print("[CameraDebug] _request_camera_frame skipped: already requesting")
		return
	if current_mode != Mode.CAMERA:
		print("[CameraDebug] _request_camera_frame skipped: mode is not CAMERA")
		return
	var socket_client = PlayerManager.socket_client
	if socket_client == null:
		print("[CameraDebug] _request_camera_frame FAILED: socket_client is null")
		return
	if not socket_client.is_socketio_connected:
		print("[CameraDebug] _request_camera_frame FAILED: socket not connected (is_socketio_connected=false)")
		return
	_requesting = true
	_frame_request_count += 1
	print("[CameraDebug] Emitting '", ENV.event_datahub_cam, "' event... (request #", _frame_request_count, ")")
	socket_client.emit_event(ENV.event_datahub_cam, "", _on_camera_frame_received)


func _on_camera_frame_received(data: Variant):
	_requesting = false
	_frame_received_count += 1
	print("[CameraDebug] _on_camera_frame_received #", _frame_received_count, " data type: ", typeof(data), " (", type_string(typeof(data)), ")")
	if current_mode != Mode.CAMERA:
		print("[CameraDebug] Ignoring frame: mode is no longer CAMERA")
		return

	# Handle both dict and array wrapper formats
	var payload = data
	if payload is Array and payload.size() > 0:
		print("[CameraDebug] Unwrapping Array payload, size=", payload.size())
		payload = payload[0]

	if not (payload is Dictionary):
		print("[CameraDebug] REJECTED: payload is not Dictionary, type=", type_string(typeof(payload)))
		call_deferred("_request_camera_frame")
		return
	if not payload.has("image"):
		print("[CameraDebug] REJECTED: payload has no 'image' key. Keys=", payload.keys())
		call_deferred("_request_camera_frame")
		return

	var image_dict = payload["image"]
	if not (image_dict is Dictionary):
		print("[CameraDebug] REJECTED: image_dict is not Dictionary, type=", type_string(typeof(image_dict)))
		call_deferred("_request_camera_frame")
		return

	var array = image_dict.get("array", null)
	var shape = image_dict.get("shape", [])
	print("[CameraDebug] image_dict keys=", image_dict.keys(), " shape=", shape, " array type=", type_string(typeof(array)))

	if not (array is PackedByteArray):
		print("[CameraDebug] REJECTED: array is not PackedByteArray, type=", type_string(typeof(array)))
		call_deferred("_request_camera_frame")
		return
	if shape.size() < 2:
		print("[CameraDebug] REJECTED: shape too small, size=", shape.size())
		call_deferred("_request_camera_frame")
		return

	var h: int = int(shape[0])
	var w: int = int(shape[1])
	var channels: int = int(shape[2]) if shape.size() > 2 else 1
	var expected_size = w * h * channels
	print("[CameraDebug] Image: ", w, "x", h, " channels=", channels, " array_size=", array.size(), " expected=", expected_size)

	if array.size() != expected_size:
		print("[CameraDebug] WARNING: array size mismatch! expected=", expected_size, " got=", array.size())

	var image: Image
	if channels == 3:
		image = Image.create_from_data(w, h, false, Image.FORMAT_RGB8, array)
		if _texture_rect.material == null:
			var mat = ShaderMaterial.new()
			mat.shader = _bgr_shader
			_texture_rect.material = mat
	elif channels == 1:
		image = Image.create_from_data(w, h, false, Image.FORMAT_L8, array)
		_texture_rect.material = null
	else:
		print("[CameraDebug] REJECTED: unsupported channels=", channels)
		call_deferred("_request_camera_frame")
		return

	if image == null:
		print("[CameraDebug] FAILED: Image.create_from_data returned null")
		call_deferred("_request_camera_frame")
		return

	print("[CameraDebug] Frame OK: ", w, "x", h, "x", channels, " -> texture updated")
	_texture_rect.texture = ImageTexture.create_from_image(image)

	# request → receive → request loop
	call_deferred("_request_camera_frame")


# --------------- CONTOUR mode ---------------

func _on_contour_draw():
	_contour_draw_count += 1
	var vp_size = _contour_draw.get_viewport_rect().size

	# Black background
	_contour_draw.draw_rect(Rect2(Vector2.ZERO, vp_size), Color.BLACK)

	var data: Dictionary = PlayerManager.latest_contour_data
	var cm_str = str(data.get("center_mass", [])) if not data.is_empty() else "none"
	var c0_size = ""
	if data.has("contours") and data["contours"].size() > 0:
		var c0 = data["contours"][0]
		c0_size = str(c0.get("array", PackedByteArray()).size()) if c0 is Dictionary else "?"
	_status_label.text = "draw=%d  cm=%s  c0_bytes=%s" % [_contour_draw_count, cm_str, c0_size]
	if data.is_empty():
		return

	# Use resolution from payload, fallback to Globals
	var cam_w: float = data["resolution"][0] if data.has("resolution") else Globals.camera_resolution.x
	var cam_h: float = data["resolution"][1] if data.has("resolution") else Globals.camera_resolution.y

	# 1) Draw all raw_contours (gray fill)
	if data.has("raw_contours"):
		for contour_obj in data["raw_contours"]:
			_draw_filled_contour(contour_obj, cam_w, cam_h, vp_size, Color(0.3, 0.3, 0.3))

	# 2) Draw qualified contours (white fill, on top)
	if data.has("contours"):
		for contour_obj in data["contours"]:
			_draw_filled_contour(contour_obj, cam_w, cam_h, vp_size, Color.WHITE)

	# 3) Draw qualified disk ellipses (green outline) + center mass (red dot)
	if data.has("ellipses"):
		for ellipse in data["ellipses"]:
			if ellipse == null or not (ellipse is Array) or ellipse.size() < 3:
				continue
			var center: Vector2
			var radii: Vector2
			var angle: float
			if ellipse[0] is Array and ellipse[0].size() >= 2:
				center = Vector2(float(ellipse[0][0]), float(ellipse[0][1]))
				radii = Vector2(float(ellipse[1][0]), float(ellipse[1][1])) * 0.5
				angle = -deg_to_rad(float(ellipse[2]))
			else:
				continue
			var scaled_center = Vector2(center.x / cam_w * vp_size.x, (cam_h - center.y) / cam_h * vp_size.y)
			var scaled_radii = Vector2(radii.x / cam_w * vp_size.x, radii.y / cam_h * vp_size.y)
			_draw_ellipse(scaled_center, scaled_radii, angle, Color.GREEN, 3.0)

	# 4) Draw center mass points (red dot)
	if data.has("center_mass"):
		for cm in data["center_mass"]:
			if cm == null or not (cm is Array) or cm.size() < 2:
				continue
			var px: float = float(cm[0]) / cam_w * vp_size.x
			var py: float = (cam_h - float(cm[1])) / cam_h * vp_size.y
			_contour_draw.draw_circle(Vector2(px, py), 8.0, Color.RED)


func _draw_filled_contour(contour_obj: Variant, cam_w: float, cam_h: float, vp_size: Vector2, color: Color):
	var points := _parse_contour(contour_obj, cam_w, cam_h, vp_size)
	if points.size() < 3:
		return
	var indices := Geometry2D.triangulate_polygon(points)
	if not indices.is_empty():
		_contour_draw.draw_colored_polygon(points, color)
	else:
		points.append(points[0])
		_contour_draw.draw_polyline(points, color, 2.0)


func _parse_contour(contour_obj: Variant, cam_w: float, cam_h: float, vp_size: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	if not (contour_obj is Dictionary):
		return points
	var arr = contour_obj.get("array", null)
	if not (arr is PackedByteArray):
		return points
	var byte_count: int = arr.size()
	var i: int = 0
	while i + 7 < byte_count:
		var x: int = arr.decode_s32(i)
		var y: int = arr.decode_s32(i + 4)
		points.append(Vector2(
			float(x) / cam_w * vp_size.x,
			(cam_h - float(y)) / cam_h * vp_size.y
		))
		i += 8
	return points


func _draw_ellipse(center: Vector2, radii: Vector2, angle: float, color: Color, width: float = 2.0):
	var points := PackedVector2Array()
	var segments: int = 64
	for i in range(segments + 1):
		var t: float = TAU * i / segments
		var x: float = radii.x * cos(t)
		var y: float = radii.y * sin(t)
		var rx: float = x * cos(angle) - y * sin(angle)
		var ry: float = x * sin(angle) + y * cos(angle)
		points.append(center + Vector2(rx, ry))
	_contour_draw.draw_polyline(points, color, width)
