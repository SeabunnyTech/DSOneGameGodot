class_name PowerPlantCheckpoint
extends Area2D

signal checkpoint_passed(speed: float, player_id: int, spawn_id: int)

@export var min_speed_threshold = 10.0  # 最低需要的速度
@export var spawn_id: int = 0            # 對應的 electron spawn id

@onready var sfx_player = $CheckpointSFX

var is_active = true
var cooldown_timer: float = 0.0
var COOLDOWN_TIME = 5.0  # 冷卻時間，避免重複觸發

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	if cooldown_timer > 0:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_active = true

func _on_body_entered(body: Node2D):
	if not is_active or not body.is_in_group("water_avatar"):
		return
		
	var speed = body.current_velocity.length()
	if speed < min_speed_threshold:
		return

	# 進入冷卻
	is_active = false
	cooldown_timer = COOLDOWN_TIME

	checkpoint_passed.emit(speed, body.player_id, spawn_id)
