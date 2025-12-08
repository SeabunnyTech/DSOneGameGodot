extends Node

# 根據傳入的名稱，顯示對應的 avatar 子節點
# 並隱藏所有其他的子節點
func show_avatar(avatar_name: String):
	# 首先，隱藏所有外觀
	hide_all()
	
	# 接著，如果有名為 avatar_name 的子節點，就顯示它
	if has_node(avatar_name):
		var avatar_node = get_node(avatar_name)
		avatar_node.show()
		# 如果 avatar 有自己的 setup 或 reset 函式，也可以在這裡呼叫
		if avatar_node.has_method("enter_view"):
			avatar_node.enter_view()
	else:
		print("VisualsManager: 找不到名為 '", avatar_name, "' 的 avatar。")


# 隱藏所有作為子節點的外觀
func hide_all():
	for child in get_children():
		# 確保我們操作的是 Node2D 或 Control 類型的節點
		if child is CanvasItem:
			if child.has_method("leave_view"):
				child.leave_view()
			child.hide()

