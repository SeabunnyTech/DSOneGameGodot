@tool
extends Node2D
class_name Cloud2D

# 雲朵的基本屬性
@export var base_cloud_width: float = 350.0  # 雲朵底部寬度
@export var base_circle_radius: float = 160.0  # 基礎圓形半徑
@export var radius_variation: float = 0.3  # 半徑隨機變化比例 (0.0-1.0)

# 出場動畫參數
@export var spawn_duration: float = 0.3  # 每個圓圈放大的時間
@export var spawn_overlap: float = 0.28  # 圓圈之間動畫重疊的時間（秒）

# CloudCircle 的引用（假設你已經有這個場景）
var cloud_circle_scene = preload("res://reusable/cloud2d/cloud_circle.tscn")
var circles: Array[Node2D] = []

# 儲存圓圈數據的結構
class CircleData:
	var radius: float
	var position: Vector2

func _ready():
	generate_cloud_data()


var sun_position: Vector2:
	set(new_sun_pos):
		sun_position = new_sun_pos
		for circle in circles:
			var relative_sun_pos: Vector2 = sun_position - circle.global_position
			var sun_dir = relative_sun_pos.normalized()
			var toon_distance = clamp(relative_sun_pos.length() / 3000, 0.1, 0.3)
			circle.light_position = Vector2(0.5, 0.5) + toon_distance * sun_dir


# 只產生數據，不創建實際節點
var cloud_data_array: Array[CircleData] = []
func generate_cloud_data():
	var current_x = 0.0
	var y_bias = 0.0

	while true:
		# 寬度超越基礎值後就停止
		if current_x > base_cloud_width:
			break
		
		# 隨機化半徑
		var middle_inflation = current_x * (base_cloud_width - current_x) / (base_cloud_width ** 2) * 1.2
		var radius = base_circle_radius * randf_range(1.0 - radius_variation + middle_inflation, 1.0 + radius_variation + middle_inflation)
		
		# Y 位置稍微隨機，但大致在同一水平線
		var y_ratio = randf_range(-0.2, 0.2)
		var pos = Vector2(current_x, y_ratio * radius + y_bias)
		if y_bias != 0:
			y_bias = 0
		
		# 創建數據對象
		var data = CircleData.new()
		data.radius = radius
		data.position = pos
		cloud_data_array.append(data)
		
		# 多數情況會前進到下一步, 偏離的越多越可能再次生成
		if randf() > 0.3 + 2 * abs(y_ratio):
			var overlap = radius * randf_range(0.3, 0.7)
			current_x += radius - overlap
		else:
			y_bias = -y_ratio * 1.5

	cloud_data_array.shuffle()


# 按順序播放圓圈出場動畫
func play_spawn_animation():

	$AudioStreamPlayer2D.play()
	for i in range(cloud_data_array.size()):
		var data = cloud_data_array[i]
		
		# 創建圓圈節點
		var circle = cloud_circle_scene.instantiate()
		circle.radius = data.radius
		circle.position = data.position
		circle.scale = Vector2.ZERO  # 初始縮放為 0
		
		add_child(circle)
		circles.append(circle)
		
		# 計算延遲時間（有重疊）
		var delay = i * 0.03
		
		# 創建 Tween 動畫
		var tween = create_tween()

		tween.tween_property(circle, "scale", Vector2.ONE, spawn_duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)


func poof():
	var tween = create_tween().set_parallel(true)
	for circle in get_children():
		if not circle is Node2D:
			continue

		var direction = circle.position.normalized()
		if direction == Vector2.ZERO:
			direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		
		var move_to_pos = circle.position + direction * 50 # 向外移動 50 像素

		tween.tween_property(circle, "position", move_to_pos, 0.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		tween.tween_property(circle, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	await tween.finished
	queue_free()
