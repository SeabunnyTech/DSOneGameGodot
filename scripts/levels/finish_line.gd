class_name FinishLine
extends Area2D

signal finish_line_passed(player_id: int)

# @onready var sfx_player = $CheckpointSFX

var is_active = true

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	pass

func _physics_process(delta):
	if not is_active:
		return
		
	# 獲取所有 water_avatar
	var avatars = get_tree().get_nodes_in_group("water_avatar")
	
	for avatar in avatars:
		# 計算 avatar 在 river_scene 座標系中的實際位置
		var avatar_in_river_pos = get_parent().to_local(avatar.global_position)
		
		# 檢查是否與 checkpoint 區域重疊
		if _is_point_in_finish_line(avatar_in_river_pos):
			_handle_avatar_entered(avatar)

func _is_point_in_finish_line(point: Vector2) -> bool:
	# 使用簡單的矩形碰撞檢測
	var rect = $CollisionShape2D.shape.get_rect()
	var checkpoint_pos = position

	return point.x >= checkpoint_pos.x - rect.size.x/2 \
		and point.x <= checkpoint_pos.x + rect.size.x/2 \
		and point.y >= checkpoint_pos.y - rect.size.y/2 \
		and point.y <= checkpoint_pos.y + rect.size.y/2

func _handle_avatar_entered(avatar: Node2D):
	if not is_active:
		return

	is_active = false
	finish_line_passed.emit(avatar.player_id)

func _on_body_entered(body: Node2D):
	if not is_active or not body.is_in_group("water_avatar"):
		return

	# 進入冷卻
	is_active = false
	# cooldown_timer = COOLDOWN_TIME

	finish_line_passed.emit(body.player_id)
