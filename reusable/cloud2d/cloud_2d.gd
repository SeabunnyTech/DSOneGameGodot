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
	generate_cloud()

func generate_cloud():
	# 清除現有的圓形
	for circle in circles:
		circle.queue_free()
	circles.clear()
	
	# 第一步：產生底部一橫排的圓形數據
	var circle_data_array = generate_base_row()
	
	# 第二步：播放出場動畫
	spawn_circles(circle_data_array)

# 只產生數據，不創建實際節點
func generate_base_row() -> Array[CircleData]:
	var data_array: Array[CircleData] = []
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
		data_array.append(data)
		
		# 多數情況會前進到下一步, 偏離的越多越可能再次生成
		if randf() > 0.3 + 2 * abs(y_ratio):
			var overlap = radius * randf_range(0.3, 0.7)
			current_x += radius - overlap
		else:
			y_bias = -y_ratio
	
	return data_array

# 按順序播放圓圈出場動畫
func spawn_circles(circle_data_array: Array[CircleData]):
	for i in range(circle_data_array.size()):
		var data = circle_data_array[i]
		
		# 創建圓圈節點
		var circle = cloud_circle_scene.instantiate()
		circle.radius = data.radius
		circle.position = data.position
		circle.scale = Vector2.ZERO  # 初始縮放為 0
		
		add_child(circle)
		circles.append(circle)
		
		# 計算延遲時間（有重疊）
		var delay = i * (spawn_duration - spawn_overlap)
		
		# 創建 Tween 動畫
		var tween = create_tween()
		tween.tween_property(circle, "scale", Vector2.ONE, spawn_duration)\
			.set_delay(i * 0.03)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
