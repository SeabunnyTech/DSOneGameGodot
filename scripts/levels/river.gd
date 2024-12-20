extends Node2D

signal spawn_area_scoring(spawn_id: int, count: int)
signal spawn_area_scored(spawn_id: int)
signal spawn_positions_ready(positions: Array)
signal checkpoint_passed(player_id: int, count: int)
signal finish_line_passed(player_id: int)

var spawn_areas: Array[Node] = []
var spawn_positions: Array[float] = []
var checkpoints: Array[Node] = []  # 存儲所有 checkpoint

var positions_initialized: bool = false
var checkpoint_enabled: bool = false

var current_camera_velocity: float = 0.0

@export var min_camera_speed = 10.0
@export var max_camera_speed = 800.0 	 # 達到此速度會得到最多電仔
@export var min_electrons = 1            # 最少產生電仔數
@export var max_electrons = 20           # 最多產生電仔數

@onready var river_normal_map_sprite = $RiverNormMap
@onready var electron_spawn_areas_node = $ElectronSpawnAreas
@onready var checkpoints_node = $Checkpoints
@onready var finish_line = $FinishLine
@onready var stone_node = $Stone

var river_normal_map: Image

var waiting_tween

func _ready() -> void:
	river_normal_map = river_normal_map_sprite.texture.get_image()

	# 註冊 river_scene 下的 spawn_areas signal
	for child in electron_spawn_areas_node.get_children():
		if child.has_meta("spawn_order"):
			spawn_areas.append(child)
			
			# 連接每個電仔生成區的訊號
			child.electrons_scoring.connect(_on_spawn_scoring)
			child.electrons_scored.connect(_on_spawn_scored)
		
	# 註冊 river_scene 下的 checkpoints signal
	for child in checkpoints_node.get_children():
		checkpoints.append(child)
		# 連接 checkpoint 信號
		child.checkpoint_passed.connect(
			func(player_id, spawn_id): 
				_on_checkpoint_passed(player_id, spawn_id)
		)

	if finish_line:
		finish_line.finish_line_passed.connect(finish_line_passed.emit)
	
	# 確保排序
	spawn_areas.sort_custom(func(a, b): 
		return a.get_meta("spawn_order") < b.get_meta("spawn_order"))

	await get_tree().process_frame
	_update_spawn_positions()

func _update_spawn_positions() -> void:
	spawn_positions.clear()
	for spawn in spawn_areas:
		assert(spawn != null, "Spawn area is null!")
		assert(spawn.position != null, "Spawn position is null!")
		spawn_positions.append(spawn.position.y)
	
	positions_initialized = true

	# 發送座標資訊到上層
	spawn_positions_ready.emit(spawn_positions)

# 檢查 spawn area positions 初始化狀態
func are_positions_ready() -> bool:
	return positions_initialized

func is_camera_in_map(camera_position: Vector2, screen_center: Vector2, camera_zoom_level: float) -> bool:
	var min_camera_y_in_map = camera_position.y - screen_center.y / camera_zoom_level
	var max_camera_y_in_map = camera_position.y + screen_center.y / camera_zoom_level

	var image_size = river_normal_map.get_size()

	# Camera 超出地圖範圍
	if min_camera_y_in_map < 0 or max_camera_y_in_map > image_size.y:
		return false

	return true

func get_normal_at_position(pos: Vector2) -> Color:
	# 確保位置在圖片範圍內
	var image_size = river_normal_map.get_size()
	var x = clamp(pos.x, 0, image_size.x - 1)
	var y = clamp(pos.y, 0, image_size.y - 1)
	
	return river_normal_map.get_pixel(x, y)

# 提供取得座標的方法
func get_spawn_positions() -> Array[float]:
	return spawn_positions.duplicate() # 回傳複製以防止外部修改

# 取得特定 spawn 的座標
func get_spawn_aposition(spawn_id: int) -> float:
	if spawn_id >= 0 and spawn_id < spawn_positions.size():
		return spawn_positions[spawn_id]
	return 0.0

func get_river_scene_size() -> Vector2:
	return river_normal_map_sprite.texture.get_size()

func enable_checkpoint():
	checkpoint_enabled = true
	for checkpoint in checkpoints:
		checkpoint.is_active = true

func disable_checkpoint():
	checkpoint_enabled = false
	for checkpoint in checkpoints:
		checkpoint.is_active = false

func _on_checkpoint_passed(player_id: int, spawn_id: int) -> void:
	# 計算獲得的電仔數量
	var speed_ratio = (current_camera_velocity - min_camera_speed) / (max_camera_speed - min_camera_speed)
	var electron_count = ceil(lerp(min_electrons, max_electrons, speed_ratio))
	
	spawn_areas[spawn_id].spawn_electrons(electron_count)
	checkpoint_passed.emit(player_id, electron_count)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_spawn_scoring(spawn_id: int, count: int) -> void:
	spawn_area_scoring.emit(spawn_id, count)

func _on_spawn_scored(spawn_id: int) -> void:
	spawn_area_scored.emit(spawn_id)

func blink_stones():
	start_waiting_animation(stone_node)

func blink_checkpoint():
	start_waiting_animation(checkpoints_node)

func stop_blink():
	stop_waiting_animation(stone_node)
	stop_waiting_animation(checkpoints_node)

func start_waiting_animation(node):
	# 停止之前的動畫（如果有的話）
	if waiting_tween:
		waiting_tween.kill()
	
	waiting_tween = create_tween()
	waiting_tween.set_loops() # 設置無限循環

	waiting_tween.tween_property(node, "modulate:a", 0, 0.5)
	# 再淡入
	waiting_tween.tween_property(node, "modulate:a", 1, 0.5)

func stop_waiting_animation(node):
	if waiting_tween:
		waiting_tween.kill()

	waiting_tween = create_tween()
	waiting_tween.tween_property(node, "modulate:a", 1, 0.5)





# ================= 以下為電仔回收的功能，目前沒用到，備份保留在此

func trigger_spawn_area_scoring(spawn_id: int) -> void:
	if spawn_id < 0 or spawn_id >= spawn_areas.size():
		return

	spawn_areas[spawn_id].collect_electrons()
