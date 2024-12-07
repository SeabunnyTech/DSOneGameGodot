extends Node2D

signal spawn_area_scoring(spawn_id: int, count: int)
signal spawn_area_scored(spawn_id: int)
signal spawn_positions_ready(positions: Array)

var spawn_areas: Array[Node] = []
var spawn_positions: Array[float] = []
var positions_initialized: bool = false

var normal_image: Image

func _ready() -> void:
	for child in get_children():
		if child.has_meta("spawn_order"):
			spawn_areas.append(child)
			
			# 連接每個電仔生成區的訊號
			child.electrons_scoring.connect(_on_spawn_scoring)
			child.electrons_scored.connect(_on_spawn_scored)
	
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


func get_normal_at_position(pos: Vector2) -> Color:
	# 確保位置在圖片範圍內
	var image_size = normal_image.get_size()
	var x = clamp(pos.x, 0, image_size.x - 1)
	var y = clamp(pos.y, 0, image_size.y - 1)
	
	return normal_image.get_pixel(x, y)

# 提供取得座標的方法
func get_spawn_positions() -> Array[float]:
	return spawn_positions.duplicate() # 回傳複製以防止外部修改

# 取得特定 spawn 的座標
func get_spawn_aposition(spawn_id: int) -> float:
	if spawn_id >= 0 and spawn_id < spawn_positions.size():
		return spawn_positions[spawn_id]
	return 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_spawn_scoring(spawn_id: int, count: int) -> void:
	spawn_area_scoring.emit(spawn_id, count)

func _on_spawn_scored(spawn_id: int) -> void:
	spawn_area_scored.emit(spawn_id)
