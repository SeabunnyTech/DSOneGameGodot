extends ColorRect
class_name CloudManager

signal clouds_cleared

@export var sun_node: Node2D


# 雲朵生成設定
@export var spawn_interval: float = 0.3  # 每幾秒生成一朵雲
@export var spawn_area_size: Vector2 = Vector2(1000, 600)  # 生成區域大小
@export var spawn_offset: Vector2 = Vector2(-200, 0)  # 生成區域偏移

# 雲朵移動設定
@export var move_speed: float = 20.0  # 移動速度（像素/秒）


# 雲朵預設設定
@export var cloud_scene: PackedScene = preload("res://reusable/cloud2d/cloud2d.tscn")



@export_flags_2d_physics var collision_channels = 14

# 風力設定
@export var wind_decay_rate: float = 1.0 # 風力衰減速度
var wind_speed: float = 0.0


var clouds: Array[Cloud2D] = []
var spawn_timer: float = 0.0

# State variables
var is_processing: bool = false
var is_spawning: bool = false


func _ready():
	# 如果沒有指定場景，嘗試動態創建
	if not cloud_scene:
		push_warning("CloudManager: 沒有指定 cloud_scene，將動態創建雲朵")
	reset()


func _process(_delta: float) -> void:
	if not is_processing:
		return
		
	# 更新每一朵雲的太陽位置
	for cloud in clouds:
		cloud.sun_position = sun_node.global_position


func _physics_process(delta: float) -> void:
	if not is_processing:
		return

	# Spawning logic
	if is_spawning:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			spawn_cloud()
			if len(clouds) > 20:
				# Use clear_all_clouds for animated removal if needed,
				# but for now, just remove the oldest one.
				clouds[0].poof()
				clouds.remove_at(0)

	# Movement logic
	_move_clouds_to_sun(delta)

	# Wind logic
	_apply_wind(delta)


func spawn_cloud(pos=null):
	var cloud: Cloud2D

	cloud = cloud_scene.instantiate()
	
	var x_inset = 300
	if not pos:
		pos = Vector2(
			randf_range(x_inset, size.x-x_inset),
			randf_range(0, size.y)
		)

	cloud.position = pos
	cloud.sun_position = sun_node.position
	cloud.collision_channels = collision_channels
	add_child(cloud)
	clouds.append(cloud)
	
	cloud.play_spawn_animation()


func _move_clouds_to_sun(delta: float) -> void:
	for cloud in clouds:
		if not is_instance_valid(cloud):
			continue
		
		var direction = (sun_node.global_position - cloud.global_position).normalized().x
		cloud.global_position.x += 10.0 * direction * move_speed * delta


var cloud_responsive: bool = true
func set_responsive_to_anticyclone(responsive:bool):
	cloud_responsive = responsive

func _apply_wind(_delta: float) -> void:
	var screen_width = get_viewport_rect().size.x
	
	# Create a copy of the array to iterate over, as we may modify the original
	var saved_clouds: Array[Cloud2D] = []
	for cloud in clouds:
		cloud.set_responsive_to_anticyclone(cloud_responsive)
		var poof_distance = randf_range(300, 600)
		if cloud.position.x + cloud.cloud_width < poof_distance\
			or cloud.position.x > screen_width - poof_distance:
			cloud.poof()
			
		else:
			saved_clouds.append(cloud)

	# 檢查是否要觸發 clouds clear
	if saved_clouds.is_empty() and not clouds.is_empty():
		print("clouds_cleared")
		clouds_cleared.emit()

	clouds = saved_clouds
# --- Public API ---

func start():
	is_processing = true
	is_spawning = true

func stop():
	is_processing = false
	is_spawning = false

func stop_generate():
	is_spawning = false

func clear_all_clouds():
	for cloud in clouds:
		if is_instance_valid(cloud):
			cloud.poof()
	clouds.clear()

func reset():
	stop()
	for cloud in clouds:
		if is_instance_valid(cloud):
			cloud.queue_free()
	clouds.clear()
	spawn_timer = 0.0
	wind_speed = 0.0

# 從外部施加一陣風力
func update_wind_speed(xspeed):
	wind_speed = xspeed

func set_collision_enabled(enabled: bool):
	for cloud in clouds:
		if is_instance_valid(cloud) and cloud.has_method("set_collision_enabled"):
			cloud.set_collision_enabled(enabled)
