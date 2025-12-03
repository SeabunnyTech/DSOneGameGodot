extends Label

# 設定文字高度要佔 Label 總高度的多少百分比 (0.8 代表 80%)
@export var height_ratio: float = 0.95

func _ready():
	# 確保有 LabelSettings 資源，否則報錯
	if label_settings == null:
		label_settings = LabelSettings.new()
	
	# 初始化大小
	_update_font_size()
	
	# 當 Label 尺寸改變時 (例如視窗被拉大)，重新計算字體
	resized.connect(_update_font_size)

func _update_font_size():
	# 避免高度為 0 出錯
	if size.y <= 0: return
	
	# 計算目標字體大小：當前高度 * 比例
	var new_size = int(size.y * height_ratio)
	
	# 設定最小字體限制 (避免縮太小看不見)
	if new_size < 8:
		new_size = 8
		
	# 套用新設定
	label_settings.font_size = new_size
