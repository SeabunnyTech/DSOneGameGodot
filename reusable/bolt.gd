extends RigidBody2D

func _ready():
	# 創建計時器
	var timer = Timer.new()
	timer.wait_time = 0.7  # 設置為 10 秒
	timer.one_shot = true   # 只觸發一次
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

	angular_velocity = randf_range(-8.0, 8.0)
