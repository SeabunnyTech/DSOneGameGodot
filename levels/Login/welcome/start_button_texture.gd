extends TextureRect

@onready var area_2d = $Area2D

# --- 設定參數 ---
var hover_scale: Vector2 = Vector2(1.1, 1.1)    # 被踩到時的大小
var normal_scale: Vector2 = Vector2.ONE         # 正常大小
var idle_pulse_scale: Vector2 = Vector2(1.03, 1.03) # 閒置時微微變大的大小 (不用太大)

var active_tween: Tween
var is_hovered: bool = false #用來記錄現在是否有人踩在上面

func _ready():
	# 1. 確保軸心在正中間
	pivot_offset = size / 2.0
	
	# 2. 連接訊號
	area_2d.body_entered.connect(_on_object_entered)
	area_2d.body_exited.connect(_on_object_exited)
	
	# 3. 遊戲一開始沒人踩，直接開始呼吸動畫
	# start_idle_pulse()

# 當物件碰到 Area2D
func _on_object_entered(_body):
	is_hovered = true # 標記為被踩踏狀態
	animate_scale(hover_scale) # 這裡會自動 kill 掉閒置動畫，轉為變大

# 當物件離開 Area2D
func _on_object_exited(_body):
	is_hovered = false # 解除標記
	
	# 這裡我們做一個特殊處理：
	# 呼叫 animate_scale 變回原狀，並告訴它「動畫做完後，請重新開始呼吸」
	animate_scale(normal_scale, true)

# 修改後的縮放動畫函數，多了一個參數 check_idle
func animate_scale(target_scale: Vector2, restart_idle_after: bool = false):
	# 如果有舊的動畫 (包含閒置動畫) 在跑，先殺掉它
	if active_tween:
		active_tween.kill()
	
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_ELASTIC)
	active_tween.set_ease(Tween.EASE_OUT)
	
	# 執行縮放
	active_tween.tween_property(self, "scale", target_scale, 0.6)
	
	# 如果指定要在結束後重啟呼吸 (通常是用在 Exited 時)
	if restart_idle_after:
		# 使用 tween_callback 在動畫結束後執行函數
		active_tween.tween_callback(start_idle_pulse)

# 新增：閒置時的呼吸動畫
func start_idle_pulse():
	# 安全檢查：如果現在有人踩著，就不應該播放呼吸動畫
	if is_hovered: return
	
	# 殺掉之前的 tween 確保乾淨
	if active_tween: active_tween.kill()
	
	active_tween = create_tween()
	# 設定為無限循環
	active_tween.set_loops()
	
	# --- 定義呼吸循環 ---
	# 1. 等待 2 秒 (發呆時間)
	active_tween.tween_interval(2.0)
	
	# 2. 微微變大 (用 SINE 曲線比較柔和，不像 ELASTIC 那麼彈)
	active_tween.tween_property(self, "scale", idle_pulse_scale, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 3. 變回原狀
	active_tween.tween_property(self, "scale", normal_scale, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
