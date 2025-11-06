extends ColorRect

signal spawn_area_scoring(player_id: int, spawn_id: int, count: int)
signal spawn_area_scored(player_id: int, spawn_id: int)
signal checkpoint_passed(player_id: int, count: int)
signal avatar_merged(player_id: int)
signal finish_line_passed(player_id: int)

@onready var avatar = $WaterAvatar
@export var avatar_init_positions = Vector2(2090, 700)
@export var avatar_is_stuck = false
@export var avatar_is_separated = false

@export var screen_center = Vector2(3840.0/2, 2160.0/2)
@export var camera_position = Vector2(1920, 1080)
@export var camera_zoom_level = 1.2
var current_camera_velocity: float = 0.0

var player_id: int = 0

var is_playable = false

# 存此次遊戲所隨機選擇的 river scene
var river_scene: Node2D
var river_scenes = [
	preload("res://levels/level2/river1.tscn"),
	preload("res://levels/level2/river2.tscn"),
	preload("res://levels/level2/river3.tscn")
]

var spawn_area_positions: Array[float] = []

var camera_tween

func _ready() -> void:
	avatar.merged_with_player.connect(_on_avatar_merged)
	avatar.separated_from_player.connect(_on_avatar_separated)
	avatar.desired_position_changed.connect(_on_avatar_desired_position_changed)

func _process(_delta: float) -> void:
	pass

func init(_player_id: int, num_players: int, river_index: int):
	if river_scene:
		river_scene.queue_free()
		river_scene = null

	# 確保 index 在有效範圍內
	river_index = clampi(river_index, 0, river_scenes.size() - 1)
	
	river_scene = river_scenes[river_index].instantiate()

	_connect_river_signals()
	_setup_river_scene(num_players)
	_setup_avatar(_player_id, num_players)
	add_child(river_scene)

func _connect_river_signals():
	river_scene.spawn_area_scored.connect(_on_spawn_area_scored)
	river_scene.spawn_area_scoring.connect(_on_spawn_area_scoring)
	river_scene.spawn_positions_ready.connect(_on_spawn_area_positions)
	river_scene.finish_line_passed.connect(finish_line_passed.emit)
	river_scene.checkpoint_passed.connect(_on_checkpoint_passed)

func _setup_river_scene(num_players: int):
	# 根據 player_index 設定 scale (0 為單人模式，1,2 為雙人模式)
	var scale_value = 0.5 if num_players == 2 else 1.0 
	river_scene.scale = Vector2(scale_value, scale_value)
	river_scene.position = Vector2.ZERO

func _setup_avatar(_player_id: int, num_players: int):
	if num_players == 2:
		avatar_init_positions = Vector2(1045, 250)
	
	avatar.init(PlayerManager.current_players[_player_id], avatar_init_positions)
	PlayerManager.current_players[_player_id].index = _player_id

func get_color_at_position(avatar_pos: Vector2) -> Color:
	return river_scene.get_normal_at_position(avatar_pos)

func get_river_scene_size() -> Vector2:
	return river_scene.get_river_scene_size()

func get_avatar_position() -> Vector2:
	return avatar.position

func is_camera_in_map(_camera_position: Vector2, _screen_center: Vector2, _camera_zoom_level: float) -> bool:
	return river_scene.is_camera_in_map(_camera_position, _screen_center, _camera_zoom_level)

func avatar_in_river_position(_screen_center: Vector2, _camera_position: Vector2, _camera_scale: float, _avatar_target_position: Vector2) -> Vector2:
	var avatar_river_pos = _camera_position + (_avatar_target_position - _screen_center) / _camera_scale
	return avatar_river_pos

func enable_checkpoint():
	river_scene.enable_checkpoint()

func disable_checkpoint():
	river_scene.disable_checkpoint()

func init_player():
	var radii: Array[float] = [18.0, 15.0, 12.0]
	PlayerManager.current_players[0].modulate = Color.from_hsv(0.50, 0.6, 1, 1)
	PlayerManager.current_players[0].set_radii(radii)
	PlayerManager.current_players[1].modulate = Color.from_hsv(0.50, 0.6, 1, 1)
	PlayerManager.current_players[1].set_radii(radii)

func restore_player_size():
	var radii: Array[float] = [40, 35, 30]
	PlayerManager.current_players[0].modulate = Color.from_hsv(0.50, 0.6, 1, 1)
	PlayerManager.current_players[0].set_radii(radii)
	PlayerManager.current_players[1].modulate = Color.from_hsv(0.50, 0.6, 1, 1)
	PlayerManager.current_players[1].set_radii(radii)

func show_avatar():
	is_playable = true
	avatar.show()
	
func timeout_avatar():
	avatar.timeout_hide()
	
func stop_avatar():
	is_playable = false

func end_tutorial():
	river_scene.disable_checkpoint()
	avatar.hide()

func start_game():
	is_playable = true
	enable_checkpoint()
	avatar.show()

func reset():
	is_playable = false

	if river_scene:
		river_scene.queue_free()
		river_scene = null

# func set_screen_center(_screen_center: Vector2):
# 	self.screen_center = _screen_center

# func set_camera_position(_camera_position: Vector2):
# 	self.camera_position = _camera_position

# func set_camera_zoom_level(_camera_zoom_level: float):
# 	self.camera_zoom_level = _camera_zoom_level

func camera_to(_screen_center, _target_center, _target_scale=1.0, _duration=1, _callback=null):
	self.screen_center = _screen_center
	self.camera_position = _target_center
	self.camera_zoom_level = _target_scale
	
	if camera_tween:
		camera_tween.kill()

	var new_position = _screen_center - _target_center * _target_scale

	camera_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# TODO: 這邊把 river_scene 當作參數傳入，應該會更好？
	camera_tween.tween_property(river_scene, 'scale', Vector2(_target_scale, _target_scale), _duration)
	camera_tween.parallel().tween_property(river_scene, 'position', new_position, _duration)

	if _callback:
		camera_tween.finished.connect(_callback)

func update_camera_velocity(velocity: float) -> void:
	current_camera_velocity = velocity
	river_scene.current_camera_velocity = velocity # 傳給下一層的 river scene

func blink_stones():
	river_scene.blink_stones()

func blink_checkpoint():
	river_scene.blink_checkpoint()

func stop_blink():
	river_scene.stop_blink()

func _on_spawn_area_positions(positions: Array):
	spawn_area_positions = positions

func _on_spawn_area_scoring(spawn_id: int, count: int):
	DebugMessage.info("spawn_area_scoring: %s" % count)
	spawn_area_scoring.emit(player_id, spawn_id, count)

func _on_spawn_area_scored(spawn_id: int):
	spawn_area_scored.emit(player_id, spawn_id)

func _on_checkpoint_passed(_player_id: int, count: int):
	checkpoint_passed.emit(_player_id, count)

func _on_game_scoring(avatar: Node2D):
	pass

func _on_avatar_merged(avatar: Node2D):
	avatar_is_separated = false
	if is_playable:
		avatar_merged.emit(player_id)

func _on_avatar_separated(avatar: Node2D):
	avatar_is_separated = true

func _on_avatar_desired_position_changed(avatar: Node2D, new_desired_position: Vector2, delta: float):
	if not is_playable:
		return

	var follow_speed = 50
	var avatar_in_river_position = avatar_in_river_position(
		screen_center,
		camera_position,
		camera_zoom_level,
		new_desired_position)
	var river_normal = get_color_at_position(avatar_in_river_position)

	if river_normal.b > 0.05: # 確保在河道內
		var pos_x = lerp(avatar.position.x, new_desired_position.x, river_normal.b * delta * follow_speed)
		var pos_y = lerp(avatar.position.y, new_desired_position.y, 1 - current_camera_velocity/800.0)
		avatar.position = Vector2(pos_x, pos_y)
		# avatar.position = avatar.position.lerp(new_desired_position, river_normal.b * delta * follow_speed)
		avatar_is_stuck = false
	else:
		avatar_is_stuck = true








# ================= 以下為電仔回收的功能，目前沒用到，備份保留在此

func get_reversed_spawn_positions() -> Array[float]:
	var reversed_spawn_positions = spawn_area_positions.duplicate()
	reversed_spawn_positions.reverse()
	return reversed_spawn_positions

func trigger_spawn_area_scoring(spawn_id: int) -> void:
	river_scene.trigger_spawn_area_scoring(spawn_id)
