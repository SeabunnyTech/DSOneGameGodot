extends Node2D

var num_visible_players = 0
var turbine_front_speed = 0
var turbine_back_speed = 0

var delta_lake_height: float
var init_upper_lake_position : Vector2
var init_lower_lake_position : Vector2

var rotation_enabled: bool = true
var pipe_pumping_enabled: bool = false

const DAMPING_FACTOR = 0.95  # 調整這個值來改變渦輪減速速度 (0.9 更快, 0.99 更慢)
const SPEED_THRESHOLD = 0.01  # 當速度小於這個值時直接設為 0
const LAKE_HEIGHT_ADJUSTMENT_PER_ROTATION = 2.0  # 每次旋轉時，湖面的高度變化
const LAKE_HEIGHT_ANIMATION_DURATION = 0.3  # 湖面高度變化動畫持續時間
const MAX_LAKE_DELTA_HEIGHT = 280  # 最高湖面升降高度

# TODO: 在一切都測試完後，以下部分 onready 未來可以移到所屬的 subnode 中

@onready var front_turbines = $Player1UI/TurbineFrontRotate
@onready var back_turbines = $Player1UI/TurbineBackRotate
@onready var upper_lake = $Player1UI/UpperLake
@onready var lower_lake = $Player1UI/LowerLake
@onready var pipe_bubble_path = $Player1UI/Pipe/PipeBubblePath
@onready var pipe = $Player1UI/Pipe

@onready var bubbles = []
@onready var bubble_texture: Texture2D = preload("res://assets/images/backgrounds/animated/level1/pipe_bubble.png")
@export var num_pipe_bubbles: int = 20
var pipe_tweens = null


func _ready():
	# GameState.level1_state_updated.connect(_on_level1_state_updated)

	# 連接玩家旋轉的訊號
	# SignalBus.player_full_rotation_completed.connect(_on_player_full_rotation_completed)
	# SignalBus.player_rotation_detected.connect(_on_player_rotation_detected)

	# 連接電仔正在收集的訊號
	# SignalBus.electrons_scoring.connect(_on_electrons_scoring)
	# SignalBus.electrons_all_scored.connect(_on_electrons_scored)

	# 初始化湖和氣泡
	init_upper_lake_position = upper_lake.position
	init_lower_lake_position = lower_lake.position
	for num in range(num_pipe_bubbles):
		create_bubble(pipe_bubble_path)

	# 啟動渦輪的轉動?
	front_turbines.play("rotate")
	back_turbines.play("rotate")


func _process(_delta):
	pass

func _physics_process(_delta: float) -> void:
	front_turbines.speed_scale *= DAMPING_FACTOR
	back_turbines.speed_scale *= DAMPING_FACTOR
	
	# 當速度很小時直接設為 0
	if max(abs(front_turbines.speed_scale), abs(back_turbines.speed_scale)) < SPEED_THRESHOLD:
		front_turbines.speed_scale = 0
		back_turbines.speed_scale = 0
		if pipe_pumping_enabled:
			stop_pipe_pumping()



func generate_electron_and_adjust_lake_level(clockwise: bool):

	if not rotation_enabled:
		return

	if clockwise:
		return

	$ElectronSpawn.spawn_electrons(1)
	
	if delta_lake_height < MAX_LAKE_DELTA_HEIGHT:
		delta_lake_height += LAKE_HEIGHT_ADJUSTMENT_PER_ROTATION
		adjust_lake_heights()



func rotate_wheel(clockwise: bool, speed: float):

	if not rotation_enabled:
		return
	if clockwise:
		return

	var turbine_speed_scale = (1 if clockwise else -1) * speed
	front_turbines.speed_scale = turbine_speed_scale * 5
	back_turbines.speed_scale = turbine_speed_scale * 5
	
	for bubble in bubbles:
		bubble.progress_ratio = fmod(bubble.progress_ratio + speed * 0.002, 1.0)

	# 根據速度計算 duration
	# 假設 speed 範圍是 0.0 到 1.0
	var base_duration = 0.8  # 基礎持續時間
	var min_duration = 0.2   # 最短持續時間
	var duration = max(min_duration, base_duration * (1.0 - speed * 0.8))
	
	start_pipe_pumping(duration)



func _on_electrons_scoring(_count: int):
	front_turbines.speed_scale = 2
	back_turbines.speed_scale = 2

	move_pipe_bubbles_backward(0.008)
	if delta_lake_height > 0:
		delta_lake_height -= LAKE_HEIGHT_ADJUSTMENT_PER_ROTATION
		adjust_lake_heights()
	
	start_pipe_pumping(0.45)

func _on_electrons_scored(player_id: int):
	stop_pipe_pumping()

func _on_game_over(_state_info: Dictionary):
	pass


# TODO: 在一切都測試完後，以下 func 未來可以移到所屬的 subnode 中
# ===========================================
func adjust_lake_heights() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move upper lake down
	var upper_target = init_upper_lake_position + Vector2(0, delta_lake_height)
	tween.tween_property(upper_lake, "position", upper_target, LAKE_HEIGHT_ANIMATION_DURATION)
	
	# Move lower lake up
	var lower_target = init_lower_lake_position - Vector2(0, delta_lake_height)
	tween.tween_property(lower_lake, "position", lower_target, LAKE_HEIGHT_ANIMATION_DURATION)

func create_bubble(path: Path2D):
	var follow = PathFollow2D.new()
	path.add_child(follow)
	
	# Add a sprite to the follower
	var sprite = Sprite2D.new()
	sprite.texture = bubble_texture
	var random_scale = randf_range(0.5, 1.2)
	sprite.scale = Vector2(random_scale, random_scale)  # Adjust size as needed
	follow.add_child(sprite)
	
	# Start from random position along the path
	follow.progress_ratio = randf()
	bubbles.append(follow)

func move_pipe_bubbles_backward(offset: float) -> void:
	 # Create a tween for smooth bubble movement
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple properties to tween simultaneously
	
	for bubble in bubbles:
		var current_ratio = bubble.progress_ratio
		var target_ratio = current_ratio - offset
		# Ensure we stay within 0-1 range
		if target_ratio < 0:
			target_ratio += 1.0
		
		# 如果移動距離太大（跨越邊界），就選擇較短的路徑
		if abs(target_ratio - current_ratio) > 0.5:
			if target_ratio > current_ratio:
				target_ratio -= 1.0
			else:
				target_ratio += 1.0
	
		tween.tween_property(bubble, "progress_ratio", target_ratio, 0.3)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)

func start_pipe_pumping(duration: float = 0.4) -> void:
	pipe_pumping_enabled = true
	# 如果已經有執行中的 tween，就不要重新創建
	if pipe_tweens and pipe_tweens.is_valid():
		return

	var pipe_material = pipe.material
	pipe_tweens = create_tween().set_loops()
	var tween = pipe_tweens

	tween.tween_method(
		func(value: float): pipe_material.set_shader_parameter("transition", value),
		0.0,  # 起始值
		1.0,  # 結束值
		duration   # 持續時間
	).set_trans(Tween.TRANS_SPRING)

	tween.tween_method(
		func(value: float): pipe_material.set_shader_parameter("transition", value),
		1.0,  # 起始值
		0.0,  # 結束值
		duration   # 持續時間
	).set_trans(Tween.TRANS_SPRING)

func stop_pipe_pumping() -> void:
	pipe_pumping_enabled = false
	# 如果有正在執行的 tween，先停止它
	if pipe_tweens and pipe_tweens.is_valid():
		pipe_tweens.kill()

	var pipe_material = pipe.material
	var tween = create_tween()
	pipe_tweens = tween

	tween.tween_method(
		func(value: float): pipe_material.set_shader_parameter("transition", value),
		pipe_material.get_shader_parameter("transition"),  # 從當前值開始
		0.0,  # 結束值
		0.8   # 持續時間
	).set_trans(Tween.TRANS_SPRING)
