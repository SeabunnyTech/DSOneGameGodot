extends Line2D
const MAX_POINTS: int = 100
@onready var curve := Curve2D.new()

func _ready() -> void:
	# 讓 Line2D 不跟隨父節點變換，直接使用世界座標
	top_level = true

func _process(delta: float) -> void:
	# 現在可以直接使用全局位置
	curve.add_point(get_parent().global_position)
	
	if curve.get_baked_points().size() > MAX_POINTS:
		curve.remove_point(0)
	points = curve.get_baked_points()

func stop() -> void:
	set_process(false)
	var tw := get_tree().create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 3.0)
	await tw.finished
	queue_free()
