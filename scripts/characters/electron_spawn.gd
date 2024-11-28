extends StaticBody2D

@export var float_range: float = 50.0
@export var float_speed: float = 0.5
@export var collection_speed: float = 1.5
var collecting: bool = false

var electron_scene = preload("res://scenes/characters/electron.tscn")
var active_electrons: Array[Node] = []

func _ready():
	var spawn_id = get_meta("spawn_order") if has_meta("spawn_order") else 0
	var player_id = get_meta("player_id") if has_meta("player_id") else 0

	SignalBus.electrons_to_spawn.connect(_on_spawn_electrons)
	SignalBus.electrons_to_collect.connect(_on_collect_electrons)

	ScoreManager.register_spawn_area(player_id, spawn_id)

func collect_electron(electron: Node2D) -> void:
	var tween = create_tween()
	
	# 吸入效果
	tween.tween_property(electron, "position", 
		Vector2.ZERO, collection_speed
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# 縮小消失
	tween.parallel().tween_property(electron, "scale",
		Vector2.ONE * 0.3, collection_speed
	).set_trans(Tween.TRANS_BACK)
	
	# 完成後處理
	tween.tween_callback(func():
		electron.queue_free()
	)

func _on_collect_electrons(player_id: int, spawn_id: int):
	# 尚未判斷這樣是不是好的寫法，若不好管理可修正
	# 目前寫法是接收廣播訊號 electrons_to_collect，發現不是自己的 spawn_id 或 player_id 就跳過
	var self_spawn_id = get_meta("spawn_order") if has_meta("spawn_order") else 0
	var self_player_id = get_meta("player_id") if has_meta("player_id") else 0

	if self_spawn_id != spawn_id or self_player_id != player_id:
		return
	
	if collecting:
		return

	collecting = true
	
	# 依序收集所有電子
	for i in range(active_electrons.size()):
		var electron = active_electrons[i]
		if electron != null:
			# 添加延遲，讓電子一個接一個被收集
			await get_tree().create_timer(0.2).timeout
			collect_electron(electron)
			SignalBus.electrons_scoring.emit(1, self_player_id)
			
			# 播放收集音效
			# AudioManager.play_sfx("electron_collect")
	
	# 等待最後一個動畫完成
	await get_tree().create_timer(collection_speed + 0.2).timeout
	collecting = false

func _on_spawn_electrons(count: int, player_id: int, spawn_id: int):
	var self_spawn_id = get_meta("spawn_order") if has_meta("spawn_order") else 0
	var self_player_id = get_meta("player_id") if has_meta("player_id") else 0

	if self_spawn_id != spawn_id or self_player_id != player_id:
		return
	
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

func _exit_tree():
	var spawn_id = get_meta("spawn_order") if has_meta("spawn_order") else 0
	var player_id = get_meta("player_id") if has_meta("player_id") else 0
	
	# Unregister when scene changes/exits
	ScoreManager.unregister_spawn_area(player_id, spawn_id)
