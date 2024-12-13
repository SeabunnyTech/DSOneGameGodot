extends ColorRect

signal spawn_area_scoring(player_id: int, spawn_id: int, count: int)
signal spawn_area_scored(player_id: int, spawn_id: int)
signal checkpoint_passed(player_id: int, count: int)
signal finish_line_passed(player_id: int)
var player_id: int = 0

# 存此次遊戲所隨機選擇的 river scene
var river_scene: Node2D
var river_scenes = [
	preload("res://scenes/levels/level2/river1.tscn"),
	preload("res://scenes/levels/level2/river2.tscn"),
	preload("res://scenes/levels/level2/river3.tscn")
]

var spawn_area_positions: Array[float] = []

var camera_tween

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func init(player_id: int, num_players: int, river_index: int):
	# 確保 index 在有效範圍內
	river_index = clampi(river_index, 0, river_scenes.size() - 1)
	
	river_scene = river_scenes[river_index].instantiate()
	river_scene.spawn_area_scored.connect(_on_spawn_area_scored)
	river_scene.spawn_area_scoring.connect(_on_spawn_area_scoring)
	river_scene.spawn_positions_ready.connect(_on_spawn_area_positions)
	river_scene.finish_line_passed.connect(finish_line_passed.emit)
	river_scene.checkpoint_passed.connect(checkpoint_passed.emit)
	# 根據 player_index 設定 scale (0 為單人模式，1,2 為雙人模式)
	var scale_value = 0.5 if num_players == 2 else 1.0 
	river_scene.scale = Vector2(scale_value, scale_value)
	river_scene.position = Vector2.ZERO

	add_child(river_scene)

func get_color_at_position(avatar_pos: Vector2) -> Color:
	return river_scene.get_normal_at_position(avatar_pos)

func get_river_scene_size() -> Vector2:
	return river_scene.get_river_scene_size()

func is_camera_in_map(camera_position: Vector2, screen_center: Vector2, camera_zoom_level: float) -> bool:
	return river_scene.is_camera_in_map(camera_position, screen_center, camera_zoom_level)

func avatar_in_river_position(screen_center: Vector2, camera_position: Vector2, camera_scale: float, avatar_target_position: Vector2) -> Vector2:
	var avatar_river_pos = camera_position + (avatar_target_position - screen_center - self.position) / camera_scale
	return avatar_river_pos

func camera_to(screen_center, target_center, target_scale=1.0, duration=1, callback=null):
	if camera_tween:
		camera_tween.kill()

	var new_position = screen_center - target_center * target_scale

	camera_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# TODO: 這邊把 river_scene 當作參數傳入，應該會更好？
	camera_tween.tween_property(river_scene, 'scale', Vector2(target_scale, target_scale), duration)
	camera_tween.parallel().tween_property(river_scene, 'position', new_position, duration)

	if callback:
		camera_tween.finished.connect(callback)

func update_camera_velocity(velocity: float) -> void:
	river_scene.current_camera_velocity = velocity

func _on_spawn_area_positions(positions: Array):
	spawn_area_positions = positions

func _on_spawn_area_scoring(spawn_id: int, count: int):
	DebugMessage.info("spawn_area_scoring: %s" % count)
	spawn_area_scoring.emit(player_id, spawn_id, count)

func _on_spawn_area_scored(spawn_id: int):
	spawn_area_scored.emit(player_id, spawn_id)










# ================= 以下為電仔回收的功能，目前沒用到，備份保留在此

func get_reversed_spawn_positions() -> Array[float]:
	var reversed_spawn_positions = spawn_area_positions.duplicate()
	reversed_spawn_positions.reverse()
	return reversed_spawn_positions

func trigger_spawn_area_scoring(spawn_id: int) -> void:
	river_scene.trigger_spawn_area_scoring(spawn_id)
