extends TextureRect # 或是 Control，看你的節點類型

# --- 設定參數 ---
@export var jump_height: float = 30.0   # 跳躍高度 (像素)
@export var jump_duration: float = 0.25 # 單次往上跳的時間 (秒)
@export var pause_duration: float = 1.0 # 跳完三下後的休息時間 (秒)

# 用來記錄地板位置
var original_y: float

func _ready():
	# 1. 記錄初始的 Y 座標 (地板位置)
	original_y = position.y
	
	# 2. 開始播放動畫
	start_jumping_routine()

func start_jumping_routine():
	# 建立 Tween
	var tween = create_tween()
	
	# 設定這個 Tween 無限循環
	tween.set_loops()
	
	# --- 製作 "跳跳跳" 的動作序列 ---
	# 利用迴圈連續加入 3 次跳躍指令
	for i in range(3):
		# 動作 A: 往上跳 (變慢，模擬重力)
		# 使用 EASE_OUT (出場時快，到頂點變慢)
		tween.tween_property(self, "position:y", original_y - jump_height, jump_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# 動作 B: 掉下來 (變快，模擬重力)
		# 使用 EASE_IN (剛開始慢，落地時快)
		tween.tween_property(self, "position:y", original_y, jump_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# --- 動作 C: 休息一下 ---
	# 在 3 次跳躍動作都執行完後，加入一段空白時間
	tween.tween_interval(pause_duration)
