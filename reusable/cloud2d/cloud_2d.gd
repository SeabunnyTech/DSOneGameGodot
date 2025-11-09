@tool
extends Node2D
class_name Cloud2D

# 雲朵的基本屬性
@export var base_cloud_width: float = 450.0  # 雲朵底部寬度
@export var base_width_variation: float = 0.15

@export var base_circle_radius: float = 80.0  # 基礎圓形半徑
@export var radius_variation: float = 0.3  # 半徑隨機變化比例 (0.0-1.0)

# 出場動畫參數
@export var spawn_duration: float = 0.3  # 每個圓圈放大的時間
@export var spawn_overlap: float = 0.28  # 圓圈之間動畫重疊的時間（秒）

# CloudCircle 的引用（假設你已經有這個場景）
var cloud_circle_scene = preload("res://reusable/cloud2d/cloud_circle.tscn")


# 儲存圓圈數據的結構
class CircleData:
	var radius: float
	var position: Vector2

func _ready():
	generate_cloud_data()
	$CloudCircleContainer.body_entered.connect(on_hit_by_sunlight)


func _update_collision_shape():
	if cloud_data_array.is_empty():
		return

	# Sort circles by their x position to find boundaries
	var sorted_circles = cloud_data_array.duplicate()
	sorted_circles.sort_custom(func(a, b): return a.position.x < b.position.x)

	var vertices = PackedVector2Array()
	var leftmost_circle = sorted_circles[0]
	var rightmost_circle = sorted_circles[-1]

	# Start polygon from bottom-left, going clockwise
	vertices.append(Vector2(leftmost_circle.position.x - leftmost_circle.radius, 0))
	
	# Left side point of the leftmost circle
	vertices.append(Vector2(leftmost_circle.position.x, -leftmost_circle.position.y))

	# Find 2-3 highest points in the middle
	var top_points_count = 3
	var cloud_span = rightmost_circle.position.x - leftmost_circle.position.x
	
	var top_points: Array[Vector2] = []

	if cloud_span > 0:
		var section_width = cloud_span / top_points_count
		for i in range(top_points_count):
			var section_start = leftmost_circle.position.x + i * section_width
			var section_end = section_start + section_width
			
			var circles_in_section = sorted_circles.filter(func(c): return c.position.x >= section_start and c.position.x < section_end)
			if circles_in_section.is_empty():
				# if section is empty, try to get the closest one
				var closest_circle = sorted_circles[0]
				var min_dist = INF
				for c in sorted_circles:
					var dist = abs(c.position.x - (section_start + section_width/2))
					if dist < min_dist:
						min_dist = dist
						closest_circle = c
				circles_in_section.append(closest_circle)

			var highest_circle = circles_in_section[0]
			for circle in circles_in_section:
				if (circle.position.y - circle.radius) < (highest_circle.position.y - highest_circle.radius):
					highest_circle = circle
			
			top_points.append(Vector2(highest_circle.position.x, highest_circle.position.y - highest_circle.radius))

	# Add the top points in order
	for p in top_points:
		vertices.append(p)

	# Right side point of the rightmost circle
	vertices.append(Vector2(rightmost_circle.position.x + rightmost_circle.radius, rightmost_circle.position.y))
	
	# End polygon at bottom-right
	vertices.append(Vector2(rightmost_circle.position.x + rightmost_circle.radius, 0))

	# Remove old shape and add new one
	var old_shape = $CloudCircleContainer.get_node_or_null("CollisionShape2D")
	if old_shape:
		old_shape.queue_free()

	var polygon = CollisionPolygon2D.new()
	polygon.polygon = vertices
	$CloudCircleContainer.add_child(polygon)


func on_hit_by_sunlight(sunlight_particle: RigidBody2D):
	if sunlight_particle.has_method("on_cloud_hit"):
		sunlight_particle.on_cloud_hit()
	else:
		sunlight_particle.queue_free()


var sun_position: Vector2:
	set(new_sun_pos):
		sun_position = new_sun_pos
		for circle in $CloudCircleContainer.get_children():
			if circle is not CloudCircle:
				continue
			var relative_sun_pos: Vector2 = sun_position - circle.global_position
			var sun_dir = relative_sun_pos.normalized()
			var toon_distance = clamp(relative_sun_pos.length() / 3000, 0.1, 0.3)
			circle.light_position = Vector2(0.5, 0.5) + toon_distance * sun_dir


# 只產生數據，不創建實際節點
var cloud_data_array: Array[CircleData] = []
func generate_cloud_data():
	var current_x = 0.0
	var y_bias = 0.0

	var cloud_width = base_cloud_width * randf_range(1.0-base_width_variation, 1.0+base_width_variation)
	while true:
		# 寬度超越基礎值後就停止
		if current_x > cloud_width:
			_update_collision_shape()
			break

		# 隨機化半徑
		var middle_inflation = current_x * (cloud_width - current_x) / (cloud_width ** 2) * 1.2
		var radius = base_circle_radius * randf_range(1.0 - radius_variation + middle_inflation, 1.0 + radius_variation + middle_inflation)
		
		# Y 位置稍微隨機，但大致在同一水平線
		var y_ratio = randf_range(-0.2, 0.2)
		var pos = Vector2(current_x, -radius + y_ratio * radius + y_bias)
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

	var brightness = randf_range(0.9, 1.0)
	$AudioStreamPlayer2D.play()
	for i in range(cloud_data_array.size()):
		var data = cloud_data_array[i]

		# 創建圓圈節點
		var circle = cloud_circle_scene.instantiate()
		circle.radius = data.radius
		circle.position = data.position
		circle.scale = Vector2.ZERO  # 初始縮放為 0
		circle.modulate.v = brightness

		$CloudCircleContainer.add_child(circle)

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
	for circle in $CloudCircleContainer.get_children():
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
