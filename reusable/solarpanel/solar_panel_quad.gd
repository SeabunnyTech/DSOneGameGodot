@tool
extends BoxQuad

@onready var main_panel: Polygon2D = $"."

@export var grid_size = Vector2(4, 3)
@export var gap_ratio = 0.02
@export var border_ratio = 0.02

@export var panel_color : Color = Color(0.192, 0.365, 0.533)
@export_flags_2d_render var solar_cell_light_mask = 1
@export var sun_angle = 90.0: set = set_sun_angle

const SolarCellScene = preload("res://reusable/solarpanel/solar_cell.tscn")


func set_intersect_polygons(polygon_a, polygon_b, target_polygon):
	var polygon_a_global = PackedVector2Array()
	for vertex in polygon_a.polygon:
		polygon_a_global.append(polygon_a.to_global(vertex))

	var polygon_b_global = PackedVector2Array()
	for vertex in polygon_b.polygon:
		polygon_b_global.append(polygon_b.to_global(vertex))

	var verts = Geometry2D.intersect_polygons(polygon_a_global, polygon_b_global)

	var output_polygon = PackedVector2Array()
	for vertex in verts[0]:
		output_polygon.append(target_polygon.to_local(vertex))

	target_polygon.polygon = output_polygon




func set_sun_angle(new_angle):
	if not is_node_ready():
		return

	# sunlight_angle， 以一般的直角座標系為參考: 0 在最右邊, 90 在正上方 180, 在左邊
	sun_angle = clamp(fposmod(new_angle, 360), 10, 170)
	var sun_angle_rad = deg_to_rad(sun_angle)

	# 面板_陰影
	var ref_height = 100.0
	var panel_shadow_x = -ref_height * cos(sun_angle_rad)/sin(sun_angle_rad)
	$panel_shadow.position.x = panel_shadow_x
	$panel_shadow.color.a = 2*(0.1 * sin(sun_angle_rad) - 0.05)
	#var xbound = PackedVector2Array()
	#for vertex in get_global_polygon($panel_shadow_xbound):
	#	xbound.append(Vector2(vertex[0] + panel_shadow_x, vertex[1]))

	#var verts = Geometry2D.intersect_polygons(xbound, get_global_polygon($panel_shadow_envelope))
	#set_polygon_from_global($panel_shadow, verts[0])

	# 支架陰影
	#var rod_shadow = $"支架/rod_shadow"
	#var rod_shadow_xbound = $"支架/rod_shadow_xbound"
	#var rod_shadow_envelope = $"支架/rod_shadow_envelope"
	
	#for idx in [1, 2]:
	#	rod_shadow_xbound.polygon[idx] = xbound[idx]

	#verts = Geometry2D.intersect_polygons(rod_shadow_envelope.polygon, rod_shadow_xbound.polygon)
	#print(verts)
	#rod_shadow.polygon = verts[0]
	

	# 底座頂面/底座頂面_陰影
	#var basetop_shadow_x = 
	#var ref_polygon = $"底座頂面/底座頂面_陰影_ref".polygon
	#var polygon = $"底座頂面/底座頂面_陰影".polygon
	#polygon[2].x = clamp(, ref_polygon[2])

func create_solar_panel(quad : Polygon2D):
	
	# 獲取大板面的四個頂點
	if quad.polygon.size() != 4:
		print("quad 必須是四邊形（4個頂點）")
		return
	
	# 清除之前生成的小板塊
	#for child in quad.get_children():
		#if child.name.begins_with("solar_cell_"):
			#child.queue_free()

	var total_cols = grid_size.x
	var total_rows = grid_size.y

	# 生成小板塊
	for r in range(total_rows):
		for c in range(total_cols):
			create_solar_cell_in_quad(quad, grid_size, r, c)



func create_solar_cell_in_quad(
		quad: Polygon2D,
		grid_size: Vector2i,
		row: int, col: int):

	var total_cols = grid_size.x
	var total_rows = grid_size.y

	# 計算邊框和間隙在標準化空間中的大小
	var border_u = border_ratio
	var border_v = border_ratio
	var gap_u = gap_ratio / total_cols
	var gap_v = gap_ratio / total_rows
	
	# 計算可用空間
	var available_u = 1.0 - 2 * border_u - (total_cols - 1) * gap_u
	var available_v = 1.0 - 2 * border_v - (total_rows - 1) * gap_v
	
	# 計算單個小板塊在標準化空間中的尺寸
	var cell_u_size = available_u / total_cols
	var cell_v_size = available_v / total_rows
	
	# 計算小板塊在標準化空間中的位置 (0,0) 到 (1,1)
	var u_start = border_u + col * (cell_u_size + gap_u)
	var v_start = border_v + row * (cell_v_size + gap_v)
	var u_end = u_start + cell_u_size
	var v_end = v_start + cell_v_size
	
	# 使用雙線性插值將標準化座標轉換為實際座標
	var uv_arr = [
		Vector2(u_start, v_start),
		Vector2(u_end, v_start),
		Vector2(u_end, v_end),
		Vector2(u_start, v_end)
	]

	var corners = []
	var quad_points = get_global_polygon(quad)
	for uv in uv_arr:
		corners.append(bilinear_interpolate(quad_points, uv))

	# 創建小板塊
	var cell_name = "solar_cell_%d_%d" % [row, col]
	var solar_cell = quad.get_node_or_null(cell_name)
	if not solar_cell:
		solar_cell = SolarCellScene.instantiate()
		solar_cell.name = cell_name
		quad.add_child(solar_cell)

	set_polygon_from_global(solar_cell, corners)
	#var local_polygon = PackedVector2Array()
	#for vertex in corners:
		#local_polygon.append(solar_cell.to_local(vertex))
	#solar_cell.polygon = local_polygon



	# 設定顏色為藍色
	solar_cell.original_color = panel_color
	solar_cell.light_mask = solar_cell_light_mask


# 雙線性插值函數
# 在四邊形內根據標準化座標 (u, v) 計算實際座標
# u, v 的範圍都是 0.0 到 1.0
func bilinear_interpolate(quad: PackedVector2Array, uv: Vector2) -> Vector2:
	# 先在底邊和頂邊進行線性插值
	var u = uv[0]
	var v = uv[1]

	var tl = quad[0]
	var tr = quad[1]
	var br = quad[2]
	var bl = quad[3]

	var bottom = bl.lerp(br, u)  # 底邊插值
	var top = tl.lerp(tr, u)     # 頂邊插值
	
	# 然後在垂直方向進行線性插值
	return bottom.lerp(top, v)


func _ready() -> void:
	create_solar_panel(main_panel)
	super._ready()
	if Engine.is_editor_hint():
		pass
		#create_solar_panel(1,1)


	if not Engine.is_editor_hint():
		# Code to execute in game.
		pass

var editor_angle: float = 0.0
func _process(delta):
	super._process(delta)
	if Engine.is_editor_hint():
		#return
		editor_angle += 0.01
		var sim_sun_angle = 90.0 + 60*cos(editor_angle)
		#set_sun_angle(sim_sun_angle)

	if not Engine.is_editor_hint():
		# Code to execute in game.
		pass


func _on_quad_changed():
	generate_sides()	
	create_solar_panel(main_panel)
