extends Node

# To control players with mouse
@export var mouse_mode: bool = false
@export var debug_message: bool = false

var _viewport_size: Vector2 = Vector2(3840, 2160)

# 目前用不到，因為 stretch 模式設定為 viewport，所以會鎖定在 3840x2160
# 但難保之後會變成 canvas_item，所以先保留
signal viewport_size_changed(new_size: Vector2)

func get_viewport_size() -> Vector2:
	return _viewport_size

func set_viewport_size(new_size: Vector2) -> void:
	_viewport_size = new_size
	viewport_size_changed.emit(new_size)
