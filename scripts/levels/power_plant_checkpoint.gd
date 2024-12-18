class_name PowerPlantCheckpoint
extends Area2D

signal checkpoint_passed(player_id: int, spawn_id: int)

@export var min_speed_threshold = 10.0  # 最低需要的速度
@export var spawn_id: int = 0            # 對應的 electron spawn id

var is_active = true
var cooldown_timer: float = 0.0
var COOLDOWN_TIME = 5.0  # 冷卻時間，避免重複觸發

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	pass
	# if cooldown_timer > 0:
	# 	cooldown_timer -= delta
	# 	if cooldown_timer <= 0:
	# 		is_active = true

# 在 power_plant_checkpoint.gd 中
func _physics_process(delta):
	if not is_active:
		return
		
	# 獲取所有 water_avatar
	var avatars = get_tree().get_nodes_in_group("water_avatar")
	
	for avatar in avatars:
		# 計算 avatar 在 river_scene 座標系中的實際位置
		var avatar_in_river_pos = get_parent().to_local(avatar.global_position)
		
		# 檢查是否與 checkpoint 區域重疊
		if _is_point_in_checkpoint(avatar_in_river_pos):
			_handle_avatar_entered(avatar)

func _is_point_in_checkpoint(point: Vector2) -> bool:
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
	cooldown_timer = COOLDOWN_TIME
	checkpoint_passed.emit(avatar.player_id, spawn_id)

func _on_body_entered(body: Node2D):
	if not is_active or not body.is_in_group("water_avatar"):
		return

	# 進入冷卻
	is_active = false
	cooldown_timer = COOLDOWN_TIME

	checkpoint_passed.emit(body.player_id, spawn_id)
