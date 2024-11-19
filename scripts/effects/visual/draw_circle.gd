extends Node2D

@export var circle_color = Color(1, 0, 0)  # 預設為紅色
@export var radius = 90.0  # 圓形半徑

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _draw():
	draw_circle(Vector2(0, 0), radius, circle_color)

func _ready():
	queue_redraw()  # 確保畫布更新，觸發 _draw()

# 如果需要變更顏色，調用這個方法
func change_color(new_color: Color):
	circle_color = new_color
	queue_redraw()  # 重新繪製
