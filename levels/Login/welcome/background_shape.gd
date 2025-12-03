@tool
extends Control

@export_group("Colors")
@export var blue_color: Color = Color("0085ff"):
	set(value):
		blue_color = value
		queue_redraw()

@export var yellow_color: Color = Color("fff200"):
	set(value):
		yellow_color = value
		queue_redraw()

@export_group("Blue Shape Ratios (0.0 - 1.0)")
# 藍色區塊：頂部佔螢幕寬度的比例
@export var blue_top_width: float = 0.25:
	set(value):
		blue_top_width = value
		queue_redraw()

# 藍色區塊：底部佔螢幕寬度的比例
# 提示：如果你希望藍色底邊"剛好卡在角落" (也就是底部寬度為 0)，請將此設為 0.0
# 如果是參考圖那樣，底部其實還有一段寬度，可以設為 0.15 左右
@export var blue_bottom_width: float = 0.15:
	set(value):
		blue_bottom_width = value
		queue_redraw()

@export_group("Yellow Stripe Widths (0.0 - 0.2)")
# 黃色條紋：頂部的寬度 (上窄)
@export var yellow_top_width: float = 0.02:
	set(value):
		yellow_top_width = value
		queue_redraw()

# 黃色條紋：底部的寬度 (下寬)
@export var yellow_bottom_width: float = 0.06:
	set(value):
		yellow_bottom_width = value
		queue_redraw()


func _ready():
	resized.connect(queue_redraw)

func _draw():
	var w = size.x
	var h = size.y
	
	# --- 計算左側座標 ---
	
	# 1. 藍色區塊的右邊界 X 座標
	var l_blue_top_x = w * blue_top_width
	var l_blue_bottom_x = w * blue_bottom_width
	
	# 2. 黃色條紋的右邊界 X 座標 (藍色邊界 + 黃色寬度)
	var l_yellow_top_x = l_blue_top_x + (w * yellow_top_width)
	var l_yellow_bottom_x = l_blue_bottom_x + (w * yellow_bottom_width)
	
	# --- 開始繪製 (注意層級：先畫黃色墊底，再畫藍色蓋上去，或者分開畫) ---
	# 這裡我們採用「拼接法」：黃色畫在藍色旁邊，這樣半透明時才不會重疊顏色
	# 但為了簡單與避免縫隙，我們還是用「黃色畫大一點，藍色蓋上去」的方法最穩
	
	# 繪製左側黃色 (底層，包含藍色區域+黃色區域)
	var left_yellow_poly = PackedVector2Array([
		Vector2(0, 0), 
		Vector2(l_yellow_top_x, 0),
		Vector2(l_yellow_bottom_x, h), 
		Vector2(0, h)
	])
	draw_colored_polygon(left_yellow_poly, yellow_color)
	
	# 繪製左側藍色 (上層，蓋住黃色左半邊)
	var left_blue_poly = PackedVector2Array([
		Vector2(0, 0), 
		Vector2(l_blue_top_x, 0),
		Vector2(l_blue_bottom_x, h), 
		Vector2(0, h)
	])
	draw_colored_polygon(left_blue_poly, blue_color)
	
	# --- 計算右側座標 (鏡像) ---
	# 右側的計算原理是用 (總寬度 w) 減去 (左側的寬度)
	
	# 繪製右側黃色
	var right_yellow_poly = PackedVector2Array([
		Vector2(w - l_yellow_top_x, 0),
		Vector2(w, 0),
		Vector2(w, h),
		Vector2(w - l_yellow_bottom_x, h)
	])
	draw_colored_polygon(right_yellow_poly, yellow_color)
	
	# 繪製右側藍色
	var right_blue_poly = PackedVector2Array([
		Vector2(w - l_blue_top_x, 0),
		Vector2(w, 0),
		Vector2(w, h),
		Vector2(w - l_blue_bottom_x, h)
	])
	draw_colored_polygon(right_blue_poly, blue_color)
