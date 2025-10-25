@tool
extends Node2D
class_name Cloud2D

# 雲朵的基本屬性
@export var base_cloud_width: float = 350.0  # 雲朵底部寬度
@export var base_circle_radius: float = 160.0  # 基礎圓形半徑
@export var radius_variation: float = 0.3  # 半徑隨機變化比例 (0.0-1.0)

# CloudCircle 的引用（假設你已經有這個場景）
var cloud_circle_scene = preload("res://reusable/cloud2d/cloud_circle.tscn")

var circles: Array[Node2D] = []

func _ready():
	generate_cloud()

func generate_cloud():
	# 清除現有的圓形
	for circle in circles:
		circle.queue_free()
	circles.clear()
	
	# 第一步：產生底部一橫排的圓形
	generate_base_row()


func generate_base_row():

	var current_x = 0.0
	while true:
		# 寬度超越基礎值後就停止
		if current_x > base_cloud_width:
			break

		var circle = cloud_circle_scene.instantiate()
		
		# 隨機化半徑
		var middle_inflation = current_x * (base_cloud_width - current_x) / (base_cloud_width ** 2) * 1.2
		var radius = base_circle_radius * randf_range(1.0 - radius_variation + middle_inflation, 1.0 + radius_variation + middle_inflation)
		circle.radius = radius
		
		# 位置：稍微重疊以確保相連
		circle.position.x = current_x
		#circle.use_shadow = randf() > 0.2
		
		# Y 位置稍微隨機，但大致在同一水平線
		var y_ratio = randf_range(-0.2, 0.2)
		circle.position.y = y_ratio * radius

		add_child(circle)
		circles.append(circle)
		
		# 多數情況會前進到下一步, 偏離的越多越可能再次生成
		if randf() > 0.3 + 2 * abs(y_ratio):
			var overlap = radius * randf_range(0.3, 0.7)
			current_x += radius - overlap
