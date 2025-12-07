@tool
extends Node2D

@export var show_debug_background : bool = false:
	set(value):
		show_debug_background = value
		$"Node2D/太陽能板".visible = value
@export var sun_angle = 90.0: set = set_sun_angle


func set_sun_angle(new_angle):
	if not is_node_ready():
		return

	# sunlight_angle， 以一般的直角座標系為參考: 0 在最右邊, 90 在正上方 180, 在左邊
	sun_angle = clamp(fposmod(new_angle, 360), 10, 170)
	var sun_angle_rad = deg_to_rad(sun_angle)

	# 面板_陰影
	var ref_height = 100.0
	var panel_shadow_x = -ref_height * cos(sun_angle_rad)/sin(sun_angle_rad)
	#$panel_shadow.position.x = panel_shadow_x
	#$panel_shadow.color.a = 2*(0.1 * sin(sun_angle_rad) - 0.05)
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

func _ready() -> void:
	if Engine.is_editor_hint():
		pass
		#create_solar_panel(1,1)


	if not Engine.is_editor_hint():
		# Code to execute in game.
		pass

func _process(_delta):
	if Engine.is_editor_hint():
		pass

	if not Engine.is_editor_hint():
		# Code to execute in game.
		pass

func set_collision_enabled(enabled: bool):
	# Find all BoxQuad children and delegate the call
	# We need a recursive function to find all descendants
	_set_collision_for_descendants(self, enabled)

func _set_collision_for_descendants(node, enabled: bool):
	for child in node.get_children():
		if child is BoxQuad:
			if child.has_method("set_collision_enabled"):
				child.set_collision_enabled(enabled)
		
		# Recurse into children
		if child.get_child_count() > 0:
			_set_collision_for_descendants(child, enabled)
