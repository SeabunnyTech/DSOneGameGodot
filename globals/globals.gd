extends Node

# To control players with mouse
@export var mouse_mode: bool = false
@export var debug_message: bool = false

# 特設的變數, 用來記錄 logos 這個畫面登入的玩家數, 方便其它頁面參考這個數字做出反應
var intended_player_num: int = 1

var _viewport_size: Vector2 = Vector2(3840, 2160)

# 目前用不到，因為 stretch 模式設定為 viewport，所以會鎖定在 3840x2160
# 但難保之後會變成 canvas_item，所以先保留
signal viewport_size_changed(new_size: Vector2)

func get_viewport_size() -> Vector2:
	return _viewport_size

func set_viewport_size(new_size: Vector2) -> void:
	_viewport_size = new_size
	viewport_size_changed.emit(new_size)
