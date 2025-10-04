@tool
extends ColorRect

signal electron_generated
signal lower_lake_level_changed(new_level)


# 將電仔的函數及信號往上暴露
@onready var emitter = $Player1UI/ElectronEmitter
@onready var destroy_electrons = emitter.destroy_electrons
@onready var collect_electrons = emitter.collect_electrons

@onready var electron_collected = emitter.electron_collected
@onready var all_electron_collected = emitter.all_electron_collected


enum Orientation{
	CLOCKWISE,
	COUNTER_CLOCKWISE,
	BOTH
}

@export var allowed_orientation = Orientation.CLOCKWISE

func _is_orientation_allowed(clockwise: bool):
	if allowed_orientation == Orientation.BOTH:
		return true

	if clockwise:
		return allowed_orientation == Orientation.CLOCKWISE
	else:
		return allowed_orientation == Orientation.COUNTER_CLOCKWISE


var num_visible_players = 0
var turbine_front_speed = 0
var turbine_back_speed = 0


# 設定下方水位, 同時會影響上方水位
var lake_tween
@export var lake_level_per_rotation = 0.01  # 每次旋轉時，湖面的高度變化
@export var lower_lake_level: float:		# 從 0~1
	set(value):
		lower_lake_level = clamp(value, 0.0, 1.0)

		var height_range = 280.0
		var delta_lake_pos = Vector2(0, lower_lake_level * height_range)

		if lake_tween:
			lake_tween.kill()
		lake_tween = create_tween()

		var upper_lake_pos = Vector2(607, 700)
		var lower_lake_pos = Vector2(3126, 2350)

		lake_tween.tween_property(upper_lake, "position", upper_lake_pos + delta_lake_pos, 0.3)
		lake_tween.parallel().tween_property(lower_lake, "position", lower_lake_pos - delta_lake_pos, 0.3)
		lower_lake_level_changed.emit(value)


var rotation_enabled: bool = true
var pipe_pumping_enabled: bool = false

const DAMPING_FACTOR = 0.95  # 調整這個值來改變渦輪減速速度 (0.9 更快, 0.99 更慢)
const SPEED_THRESHOLD = 0.01  # 當速度小於這個值時直接設為 0

# TODO: 在一切都測試完後，以下部分 onready 未來可以移到所屬的 subnode 中


@onready var entire_env = $Player1UI 
@onready var building_case = $Player1UI/BuildingFront
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



@export var view_center:Vector2 = Vector2(1920.0, 1080.0):
	set(vc):
		view_center = vc
		var env = $Player1UI 
		env.position = size / 2.0 - view_center * env.scale



var camera_tween
func camera_to(target_center, target_scale=1.0, duration=1, callback=null):
	if camera_tween:
		camera_tween.kill()

	var screen_center = size / 2.0
	var new_position = screen_center - target_center * target_scale
	camera_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	camera_tween.tween_property(entire_env, 'scale', Vector2(target_scale, target_scale), duration)
	camera_tween.parallel().tween_property(entire_env, 'position', new_position, duration)

	if callback:
		camera_tween.finished.connect(callback)


var building_case_tween
func set_building_transparent(transparent=true, duration=1):
	if building_case_tween:
		building_case_tween.kill()

	var final_opacity = 0.0 if transparent else 1.0

	building_case_tween = create_tween()
	building_case_tween.tween_property(building_case, 'modulate:a', final_opacity, duration)


func set_collision_enabled(enabled: bool):
	$Player1UI/UpperLake/CharacterBody2D/CollisionShape2D.disabled = not enabled
	$Player1UI/ElectronEmitter.set_collision_enabled(enabled)

@onready var score_board = $ScoreBoard
var score:
	get:
		return score_board.score

var score_board_tween
func show_score_board():
	if score_board_tween:
		score_board_tween.kill()

	score_board_tween = create_tween()
	score_board_tween.tween_property(score_board, 'modulate:a', 1, 1)



func reset():
	rotation_enabled = false
	lower_lake_level = 1
	score_board.reset()
	score_board.modulate.a = 0
	score_board.position = Vector2(0, 0)
	#emitter.reset()


func _ready():
	# 連接玩家旋轉的訊號
	# SignalBus.player_full_rotation_completed.connect(_on_player_full_rotation_completed)
	# SignalBus.player_rotation_detected.connect(_on_player_rotation_detected)

	# 連接電仔正在收集的訊號
	# SignalBus.electrons_scoring.connect(_on_electrons_scoring)
	# SignalBus.electrons_all_scored.connect(_on_electrons_scored)
	emitter.electron_collected.connect(_on_electrons_scoring)
	emitter.electron_collected.connect($Player1UI/Path2D._pass_electron)
	emitter.electron_collected.connect(func(_e): score_board.add_score())
	$Player1UI/Path2D.eletron_hit_end.connect(func(electron): electron.queue_free())

	# 初始化湖和氣泡
	for num in range(num_pipe_bubbles):
		create_bubble(pipe_bubble_path)

	# 啟動渦輪的轉動?
	front_turbines.play("rotate")
	back_turbines.play("rotate")



var celebrate_tween
func celebrate():
	# 播放音效 / 讓分數變大 / 發光 / 戴個皇冠
	if celebrate_tween:
		celebrate_tween.kill()

	celebrate_tween = create_tween()
	#celebrate_tween.tween_property(entire_env, 'scale', Vector2(1.03, 1.03), 1)
	celebrate_tween.tween_property(self, 'view_center:y', 400, 3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	#camera_to()
	celebrate_tween.tween_property(score_board, 'position:y', -200, 1)
	score_board.add_crown()



func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	front_turbines.speed_scale *= DAMPING_FACTOR
	back_turbines.speed_scale *= DAMPING_FACTOR

	# 當速度很小時直接設為 0
	if max(abs(front_turbines.speed_scale), abs(back_turbines.speed_scale)) < SPEED_THRESHOLD:
		front_turbines.speed_scale = 0
		back_turbines.speed_scale = 0
		if pipe_pumping_enabled:
			stop_pipe_pumping()




func react_to_wheel_rotation(clockwise: bool):
	# 順時針會放水發電
	if not rotation_enabled:
		return

	if not _is_orientation_allowed(clockwise):
		return

	emitter.spawn_electrons(1)
	electron_generated.emit()

	var is_storing_energy = clockwise
	if is_storing_energy:
		lower_lake_level -= lake_level_per_rotation



func rotate_wheel(clockwise: bool, speed: float):

	if not rotation_enabled:
		return

	if not _is_orientation_allowed(clockwise):
		return

	var turbine_speed_scale = (1 if clockwise else -1) * speed
	front_turbines.speed_scale = turbine_speed_scale * 5
	back_turbines.speed_scale = turbine_speed_scale * 5
	var sgn = -1 if clockwise else 1
	for bubble in bubbles:
		bubble.progress_ratio = fmod(bubble.progress_ratio + sgn * speed * 0.002, 1.0)

	# 根據速度計算 duration
	# 假設 speed 範圍是 0.0 到 1.0
	var base_duration = 0.8  # 基礎持續時間
	var min_duration = 0.2   # 最短持續時間
	var duration = max(min_duration, base_duration * (1.0 - speed * 0.8))
	
	start_pipe_pumping(duration)



func _on_electrons_scoring(electron):
	front_turbines.speed_scale = -2
	back_turbines.speed_scale = -2

	move_pipe_bubbles_backward(-0.008)
	lower_lake_level += lake_level_per_rotation
	
	start_pipe_pumping(0.45)



func _on_electrons_scored(player_id: int):
	stop_pipe_pumping()



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
