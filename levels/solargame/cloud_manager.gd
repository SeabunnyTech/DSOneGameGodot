extends ColorRect
class_name CloudManager

@export var sun_node: Node2D


# 雲朵生成設定
@export var spawn_interval: float = 3.0  # 每幾秒生成一朵雲
@export var spawn_area_size: Vector2 = Vector2(1000, 600)  # 生成區域大小
@export var spawn_offset: Vector2 = Vector2(-200, 0)  # 生成區域偏移

# 雲朵移動設定
@export var move_speed: float = 20.0  # 移動速度（像素/秒）


# 雲朵預設設定
@export var cloud_scene: PackedScene = preload("res://reusable/cloud2d/cloud2d.tscn")


var clouds: Array[Cloud2D] = []
var spawn_timer: float = 0.0

func _ready():
	# 如果沒有指定場景，嘗試動態創建
	if not cloud_scene:
		push_warning("CloudManager: 沒有指定 cloud_scene，將動態創建雲朵")

func _process(delta: float) -> void:
	# 更新每一朵雲的太陽位置
	for cloud in clouds:
		cloud.sun_position = sun_node.global_position
		
	# 生成計時器
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_cloud()
	
	# 移動所有雲朵
	_move_clouds_to_sun(delta)


func spawn_cloud():
	var cloud: Cloud2D
	
	cloud = cloud_scene.instantiate()
	
	# 隨機生成位置（在生成區域內）
	var spawn_pos = Vector2(
		randf_range(0, size.x),
		randf_range(0, size.y)
	)
	cloud.position = spawn_pos
	
	# 設定太陽方向
	cloud.sun_position = sun_node.position
	
	# 加入場景和陣列
	add_child(cloud)
	clouds.append(cloud)
	
	cloud.play_spawn_animation()


func _move_clouds_to_sun(delta: float) -> void:
	for cloud in clouds:
		if not is_instance_valid(cloud):
			continue
		
		# 計算往太陽的方向
		var direction = (sun_node.global_position - cloud.global_position).normalized().x
		
		# 移動雲朵
		cloud.global_position.x += direction * move_speed * delta


# 手動生成多朵雲
func spawn_multiple_clouds(count: int) -> void:
	for i in count:
		spawn_cloud()

# 清除所有雲朵
func clear_all_clouds() -> void:
	for cloud in clouds:
		if is_instance_valid(cloud):
			cloud.queue_free()
	clouds.clear()

# 設定生成間隔
func set_spawn_interval(interval: float) -> void:
	spawn_interval = interval
	spawn_timer = 0.0
