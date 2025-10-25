extends RigidBody2D

func _ready():
	# 創建計時器
	gravity_scale = 0.1
	var timer = Timer.new()
	timer.wait_time = 3.0  # 設置為 10 秒
	timer.one_shot = true   # 只觸發一次
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()

	# 隨機分配要打到哪一層
	collision_layer = 1 << randi_range(1, 3)
	collision_mask = collision_layer

func _on_timer_timeout():
	queue_free()
