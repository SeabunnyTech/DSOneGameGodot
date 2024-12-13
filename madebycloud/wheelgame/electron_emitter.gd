extends StaticBody2D

signal electron_collected(electron)


@export var float_range: float = 50.0
@export var float_speed: float = 0.5
@export var collection_speed: float = 1.5
var collecting: bool = false

@onready var spawn_sfx = $SpawnSFX
@onready var collect_sfx = $CollectSFX
var electron_scene = preload("res://scenes/characters/electron.tscn")
var active_electrons: Array[Node] = []



func collect_electron(electron: Node2D) -> void:
	var tween = create_tween()

	# 吸入效果
	tween.tween_property(electron, "position", 
		Vector2.ZERO, collection_speed
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	# 縮小消失
	#tween.parallel().tween_property(electron, "scale",
	#	Vector2.ONE * 0.3, collection_speed
	#).set_trans(Tween.TRANS_BACK)

	# 完成後處理
	tween.tween_callback(func():
		electron.move_and_colliding = false
		remove_child(electron)
		electron_collected.emit(electron)
		#electron.queue_free()
		collect_sfx.play()
	)


func collect_electrons():
	if collecting:
		return

	collecting = true
	var collect_delay = 1 / (active_electrons.size())
	if collect_delay > 0.1:
		collect_delay = 0.1

	# 依序收集所有電子
	for i in range(active_electrons.size()):
		var electron = active_electrons[i]
		if electron != null:
			# 添加延遲，讓電子一個接一個被收集
			await get_tree().create_timer(collect_delay).timeout
			collect_electron(electron)

	# 等待最後一個動畫完成
	await get_tree().create_timer(collection_speed + 0.2).timeout
	collecting = false


# 讓電仔原地消失好像不存在過一樣
func destroy_electrons():
	for i in range(active_electrons.size()):
		active_electrons[i].vanish()

	active_electrons.clear()


func spawn_electrons(count: int):
	for i in count:
		# 雖然這邊是 for 迴圈，但多數情況電仔還是一個一個送出
		var electron = electron_scene.instantiate()

		# 在區域內隨機位置生成
		electron.position = Vector2.ZERO

		var random_scale = randf_range(0.35, 0.5)
		electron.scale = Vector2(random_scale, random_scale)
		
		# 設置隨機類型
		var random_type = randi() % 3
		electron.set_type(random_type)
		
		add_child(electron)
		active_electrons.append(electron)
		
		spawn_sfx.play()
