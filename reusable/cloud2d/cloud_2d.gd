extends Node2D
class_name Cloud2D

# 雲朵的基本屬性
@export var base_cloud_width: float = 450.0
@export var base_width_variation: float = 0.15
@export var base_circle_radius: float = 80.0
@export var radius_variation: float = 0.3

# 出場動畫參數
@export var spawn_duration: float = 0.3
@export var spawn_overlap: float = 0.28

# 玩家互動參數
@export var push_speed: float = 2000.0
@export var repulsion_radius: float = 10.0
@export var drag: float = 1.0 # How quickly the cloud slows down

var is_poofing: bool = false
var should_poof = false
var velocity: Vector2 = Vector2.ZERO # For repulsion movement
var _cloud_generated_width: float = 0.0

var collision_channels:
	set(value):
		collision_channels = value
		$CloudCircleContainer.collision_mask = collision_channels

# CloudCircle 的引用
var cloud_circle_scene = preload("res://reusable/cloud2d/cloud_circle.tscn")

# 儲存圓圈數據的結構
class CircleData:
	var radius: float
	var position: Vector2

var cloud_data_array: Array[CircleData] = []


@onready var repulsion_area = $RepulsionArea2

func set_responsive_to_anticyclone(responsive:bool):
	repulsion_area.monitoring = responsive


func _ready():
	generate_cloud_data()
	_update_collision_shape()
	$CloudCircleContainer.position.x = -_cloud_generated_width / 2
	$CloudCircleContainer.body_entered.connect(on_hit_by_sunlight)


@export var distance_threshold = 200

func _process(delta: float):
	if is_poofing or should_poof:
		return

	# --- Player Interaction ---
	var player_indexes = [player_index]
	if player_index == -1:
		player_indexes = [0, 1]

	for idx in player_indexes:
		var player = PlayerManager.current_players[idx]
		if not player.visible:
			continue

		var distance_to_player = player.global_position - (global_position + Vector2(cloud_width/2., 0.))
		if distance_to_player.length() < distance_threshold:
			should_poof = true
			return

		var dx_to_player = player.global_position.x - (global_position.x + cloud_width/2.)

		# Calculate a force multiplier that increases sharply as the player gets closer
		var normalized_distance = clamp(dx_to_player / repulsion_radius, 0.0, 1.0)
		var force_multiplier = pow(2, 1.0 - normalized_distance)

		# Apply repulsion acceleration, scaled by the multiplier
		var direction = sign(-dx_to_player) # Direction is away from the player
		var acceleration = direction * push_speed * force_multiplier
		velocity.x += acceleration * delta
	
	# --- Physics Update ---
	# Apply drag
	velocity = velocity.lerp(Vector2.ZERO, drag * delta)

	# Update position based on velocity
	global_position += velocity * delta




func _update_collision_shape():
	if cloud_data_array.is_empty():
		return

	# Sort circles by their x position to find boundaries
	var sorted_circles = cloud_data_array.duplicate()
	sorted_circles.sort_custom(func(a, b): return a.position.x < b.position.x)

	var vertices = PackedVector2Array()
	if sorted_circles.size() == 0: return
	
	var leftmost_circle = sorted_circles[0]
	var rightmost_circle = sorted_circles[-1]

	# Start polygon from bottom-left, going clockwise
	vertices.append(Vector2(leftmost_circle.position.x - leftmost_circle.radius, 0))
	vertices.append(Vector2(leftmost_circle.position.x - leftmost_circle.radius, leftmost_circle.position.y))

	# Find 3 highest points in the middle
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

	for p in top_points:
		vertices.append(p)

	vertices.append(Vector2(rightmost_circle.position.x + rightmost_circle.radius, rightmost_circle.position.y))
	vertices.append(Vector2(rightmost_circle.position.x + rightmost_circle.radius, 0))

	var old_shape = $CloudCircleContainer.get_node_or_null("CollisionShape2D")
	if old_shape:
		old_shape.queue_free()

	var polygon = CollisionPolygon2D.new()
	polygon.polygon = vertices
	$CloudCircleContainer.add_child(polygon)

@export var player_index : int = 0
func on_hit_by_sunlight(sunlight_particle):
	if not sunlight_particle.has_method("on_cloud_hit"):
		return

	# 不同 player_index 不要收
	if sunlight_particle.player_index != player_index:
		return

	sunlight_particle.on_cloud_hit()


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

var cloud_width
func generate_cloud_data():
	var current_x = 0.0
	var y_bias = 0.0
	cloud_width = base_cloud_width * randf_range(1.0-base_width_variation, 1.0+base_width_variation)
	while true:
		if current_x > cloud_width:
			break

		var middle_inflation = current_x * (cloud_width - current_x) / (cloud_width ** 2) * 1.2
		var radius = base_circle_radius * randf_range(1.0 - radius_variation + middle_inflation, 1.0 + radius_variation + middle_inflation)
		var y_ratio = randf_range(-0.2, 0.2)
		var pos = Vector2(current_x, -radius + y_ratio * radius + y_bias)
		if y_bias != 0:
			y_bias = 0

		var data = CircleData.new()
		data.radius = radius
		data.position = pos
		cloud_data_array.append(data)
		
		if randf() > 0.3 + 2 * abs(y_ratio):
			var overlap = radius * randf_range(0.3, 0.7)
			current_x += radius - overlap
		else:
			y_bias = -y_ratio * 1.5
	
	_cloud_generated_width = current_x
	cloud_data_array.shuffle()


func play_spawn_animation():
	var brightness = randf_range(0.9, 1.0)
	$AudioStreamPlayer2D.play()
	for i in range(cloud_data_array.size()):
		var data = cloud_data_array[i]
		var circle = cloud_circle_scene.instantiate()
		circle.radius = data.radius
		circle.position = data.position
		circle.scale = Vector2.ZERO
		circle.modulate.v = brightness
		$CloudCircleContainer.add_child(circle)

		var delay = i * 0.03
		var tween = create_tween()
		tween.tween_property(circle, "scale", Vector2.ONE, spawn_duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)


func poof():
	if is_poofing: return
	is_poofing = true
	
	var tween = create_tween().set_parallel(true)
	for child in $CloudCircleContainer.get_children():
		if not child is Node2D or child is CollisionPolygon2D:
			continue

		var circle = child
		var direction = circle.position.normalized()
		if direction == Vector2.ZERO:
			direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

		var move_to_pos = circle.position + direction * 50
		tween.tween_property(circle, "position", move_to_pos, 0.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		tween.tween_property(circle, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	await tween.finished
	queue_free()

func set_collision_enabled(enabled: bool):
	if has_node("RepulsionArea"):
		# Disable the Area2D from detecting bodies
		$RepulsionArea.monitoring = enabled
	
	# The collision shape for sunlight is on another Area2D
	if has_node("CloudCircleContainer"):
		# Disable the Area2D from being detected
		$CloudCircleContainer.monitorable = enabled
