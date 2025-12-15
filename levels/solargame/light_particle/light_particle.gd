extends RigidBody2D

var is_dying = false

@export var trail_color: Color = Color.YELLOW
@export var trail_width: float = 5.0
const MAX_TRAIL_LENGTH = 15
var trail_points := []


func _ready():
	# 創建計時器
	gravity_scale = 0.1
	var timer = Timer.new()
	timer.name = "DeathTimer"
	timer.wait_time = 6.0  # 設置為 6 秒
	timer.one_shot = true   # 只觸發一次
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()

	# 隨機分配要打到哪一層
	collision_layer = 128 << randi_range(0, 2)
	#collision_mask = collision_layer


func _physics_process(delta: float) -> void:
	$Sprite2D.rotate(5. * delta)

	trail_points.push_front(global_position)
	if trail_points.size() > MAX_TRAIL_LENGTH:
		trail_points.pop_back()

	queue_redraw()


func _draw():
	if trail_points.size() > 1:
		var colors = PackedColorArray()
		var num_points = trail_points.size()
		for i in range(num_points):
			var alpha = 1.0 - (float(i) / num_points)
			colors.append(Color(trail_color, alpha))
		
		var local_points = PackedVector2Array()
		for p in trail_points:
			local_points.push_back(to_local(p))

		draw_polyline_colors(local_points, colors, trail_width)
		

func _on_timer_timeout():
	queue_free()


func on_cloud_hit():
	if is_dying:
		return
	is_dying = true
	$AudioStreamPlayer2D.play()
	# Stop the particle from moving and reacting to physics
	linear_velocity = Vector2.ZERO

	# Stop the timeout timer
	var timer = get_node_or_null("DeathTimer")
	if timer:
		timer.stop()

	# Get the Sprite2D child node
	var sprite = get_node_or_null("Sprite2D")
	if not sprite:
		# Fallback in case there's no sprite, just remove the particle
		queue_free()
		return

	# Create a tween on the particle itself
	var tween = create_tween()
	
	# Tween the scale to 2x its current size
	tween.tween_property(sprite, "scale", sprite.scale * 3.0, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	# After scaling, make it disappear
	tween.tween_callback(queue_free)
