extends TextureRect

# 這裡不需要 default_scale 了，因為目標就是 Vector2.ONE (1,1)

func _ready():
	# --- 之前的設定保持不變 ---
	# 1. 確保初始軸心是正確的，這樣才會從中間放大
	update_pivot_center()
	# 監聽尺寸變化訊號，確保響應式變化時軸心依然在中間
	resized.connect(update_pivot_center)
	
	# --- 在遊戲開始時自動播放一次看看效果 ---
	# 你也可以在需要的時候從其他腳本呼叫這個函數
	# play_pop_in_animation()

# 更新軸心到圖片正中央的輔助函數 (重要!)
func update_pivot_center():
	pivot_offset = size / 2.0

# ==========================================
# 重點：新的彈出動畫函數
# ==========================================
# 加入 delay 參數，預設值為 0.0 (如果不填寫就是立即播放)
func play_pop_in_animation(delay: float = 0.0):
	# 1. 一樣先將尺寸歸零隱藏
	scale = Vector2.ZERO
	
	# 2. 建立 Tween
	var tween = create_tween()
	
	# 3. 設定同樣的彈性曲線
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# 4. 執行動畫，並加上延遲設定
	# 注意：.set_delay(delay) 是接在 tween_property 後面的
	# 這句話的意思是："設定 scale 變回 1 的動畫，但開始前先等 'delay' 秒"
	tween.tween_property(self, "scale", Vector2.ONE, 0.8).set_delay(delay)

# 測試用：點擊滑鼠時再次觸發
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		play_pop_in_animation()
