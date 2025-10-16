@tool
extends Polygon2D

class_name BoxQuad

@export var thickness_direction = Vector2(20, 20):
	set(new_vec):
		thickness_direction = new_vec
		generate_sides()

@export var xside_color: Color = Color8(0x93, 0xc9, 0xd2, 0xff)
@export var bottom_color: Color = Color8(0xd4, 0xec, 0xf0, 0xff)



func set_polygon_from_global(polygon2d, global_polygon):
	var local_polygon = PackedVector2Array()
	for vertex in global_polygon:
		local_polygon.append(polygon2d.to_local(vertex))
	polygon2d.polygon = local_polygon


func get_global_polygon(polygon2d):
	var global_polygon = PackedVector2Array()
	for vertex in polygon2d.polygon:
		global_polygon.append(polygon2d.to_global(vertex))
	return global_polygon


func generate_sides():

	var panel_lt = $".".polygon[0]
	var panel_rt = $".".polygon[1]
	var panel_rb = $".".polygon[2]
	var panel_lb = $".".polygon[3]

	# 靠左邊或右邊產生橫側面
	# 有可能兩側都有
	var pxside_polygon : Polygon2D= get_node_or_null("pxside")
	var nxside_polygon : Polygon2D= get_node_or_null("nxside")
	if nxside_polygon:
		nxside_polygon.color = xside_color

		if panel_rt[0] > panel_rb[0]:
			var lt = panel_rt
			var lb = panel_rb
			var rt = lt + thickness_direction
			var rb = lb + thickness_direction
			nxside_polygon.polygon = [lt, rt, rb, lb]
		else:
			nxside_polygon.polygon = []

	if pxside_polygon:
		pxside_polygon.color = xside_color

		if panel_lt[0] < panel_lb[0]:
			var rt = panel_lt
			var rb = panel_lb
			var lt = rt + thickness_direction
			var lb = rb + thickness_direction
			pxside_polygon.polygon = [lt, rt, rb, lb]
		else:
			pxside_polygon.polygon = []

	# 產生底側面
	var bottom_side_polygon: Polygon2D = get_node_or_null("bottom_side")
	if bottom_side_polygon:
		bottom_side_polygon.color = bottom_color
		bottom_side_polygon.polygon = [
			panel_lb,
			panel_rb,
			panel_rb + thickness_direction,
			panel_lb + thickness_direction
		]


func add_side_polygons():
	for pname in ["pxside", "nxside", "bottom_side"]:
		var p = Polygon2D.new()
		p.name = pname
		p.light_mask = light_mask
		add_child(p)


func _ready() -> void:
	add_side_polygons()
	generate_sides()
	if Engine.is_editor_hint():
		pass

	if not Engine.is_editor_hint():
		# Code to execute in game.
		pass


var __last_hash = null
var __update_countdown : float = 0.0
var __update_period = 0.1

func _process(delta):
	if Engine.is_editor_hint():
		if __update_countdown < 0:
			__update_countdown -= delta
			return
		__update_countdown = __update_period
		# Code to execute in game.
		var p = $"."
		var h = _polygon_hash(p)
		if __last_hash != h:
			__last_hash = h
			_on_quad_changed()


func _on_quad_changed():
	generate_sides()	

func _polygon_hash(p) -> int:
	# 以點列作為變更依據（需要的是 p.polygon）
	return hash(p.polygon)
