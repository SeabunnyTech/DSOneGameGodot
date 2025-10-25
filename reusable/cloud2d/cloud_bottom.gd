@tool
extends Node2D
class_name CloudBottom

enum CirclePosition { LEFT, RIGHT }

@export var rect_width: float = 150.0
@export var rect_height: float = 30.0
@export var circle_radius: float = 50.0

var _bottom_rect_x = 0
@export var circle_position: CirclePosition = CirclePosition.LEFT:
	set(value):
		circle_position = value
		_bottom_rect_x = -rect_width if CirclePosition.RIGHT else 0

var rect: ColorRect
var circle_node: Node2D
var circle_visual: Polygon2D

func _ready():
	pass
	#build()


func _draw():
	#var col = Color.RED
	var col = Color.WHITE
	draw_circle(Vector2(0, -circle_radius), circle_radius, col)
	draw_rect(Rect2(Vector2(_bottom_rect_x, -rect_height), Vector2(rect_width, rect_height)),col)
	update_collsion()


func update_collsion():
	$Area2D/CollisionSideCircle.position = Vector2(0, -circle_radius)
	var circle_scale = circle_radius / 10
	$Area2D/CollisionSideCircle.scale = Vector2(circle_scale, circle_scale)

	$Area2D/CollisionRectBottom.position = Vector2(_bottom_rect_x + rect_width/2, -rect_height / 2)
	$Area2D/CollisionRectBottom.scale = Vector2(rect_width/20, rect_height/20)

func build():
	# 清除舊的子節點(如果有)
	for child in get_children():
		child.queue_free()
	
	# 創建長方形
	rect = ColorRect.new()
	rect.size = Vector2(rect_width, rect_height)
	rect.position = Vector2.ZERO
	rect.color = Color.WHITE
	add_child(rect)
	
	# 創建圓形節點
	circle_node = Node2D.new()
	
	# 根據位置設定圓心座標
	if circle_position == CirclePosition.LEFT:
		# 圓在左頂點,圓心在 (0, 0),圓底對齊長方形底部
		circle_node.position = Vector2(0, rect_height - circle_radius)
	else:  # RIGHT
		# 圓在右頂點,圓心在 (rect_width, 0),圓底對齊長方形底部
		circle_node.position = Vector2(rect_width, rect_height - circle_radius)
	
	add_child(circle_node)
	
	# 創建圓形視覺
	circle_visual = create_circle_visual(circle_radius)
	circle_node.add_child(circle_visual)

func create_circle_visual(radius: float) -> Polygon2D:
	var polygon = Polygon2D.new()
	var points = PackedVector2Array()
	var segments = 32
	
	for i in range(segments):
		var angle = i * TAU / segments
		points.append(Vector2(
			cos(angle) * radius,
			sin(angle) * radius
		))
	
	polygon.polygon = points
	polygon.color = Color.WHITE
	return polygon

# 設定函數(可以在程式碼中動態調整)
func set_rect_width(width: float):
	rect_width = width
	if rect:
		build()

func set_rect_height(height: float):
	rect_height = height
	if rect:
		build()

func set_circle_radius(radius: float):
	circle_radius = radius
	if circle_node:
		build()

func set_circle_position(pos: CirclePosition):
	circle_position = pos
	if circle_node:
		build()

# 獲取圓形節點(用於掛載其他子物件或腳本)
func get_circle_node() -> Node2D:
	return circle_node

# 獲取長方形節點(用於掛載頂部圓形)
func get_rect_node() -> ColorRect:
	return rect
