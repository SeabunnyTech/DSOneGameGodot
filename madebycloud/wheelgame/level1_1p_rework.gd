extends Node2D

# 這個 level 的一些行為:
# 1. 剛進入時會有一些教學, 基本上就是 文字 ui 和運鏡的 tween 一個接一個
# 2. 可以考慮給一個跳過按鈕
# 3. 教學結束就來到倒數及開始 ui
# 4. 遊戲開始後, 音樂可以切換成遊戲音樂


func on_enter():
	# 轉場進入
	# 
	pass


func on_leave():
	pass


@onready var wheelgame_env = $WheelGameEnviromnent
@onready var player = PlayerManager.player1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 連接信號:
	# 1. player1 控制旋轉
	# 2. 計分板

	# 電仔生成
	player.full_rotation_completed.connect(func(player, clockwise):
		wheelgame_env.generate_electron_and_adjust_lake_level(clockwise)
	)

	# 水輪旋轉
	player.rotation_detected.connect(func(player, clockwise, speed):
		wheelgame_env.rotate_wheel(clockwise, speed)
	)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
