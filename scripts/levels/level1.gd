extends Node2D

var num_visible_players = 0
var turbine_front_speed = 0
var turbine_back_speed = 0

var delta_lake_height = 0
var init_upper_lake_positions: Array[Vector2] = []
var init_lower_lake_positions: Array[Vector2] = []

var rotation_enabled: bool = false

const DAMPING_FACTOR = 0.95  # 調整這個值來改變減速速度 (0.9 更快, 0.99 更慢)
const SPEED_THRESHOLD = 0.01  # 當速度小於這個值時直接設為 0
const LAKE_HEIGHT_ADJUSTMENT_PER_ROTATION = 2.0  # 每次旋轉時，湖面的高度變化
const LAKE_HEIGHT_ANIMATION_DURATION = 0.3  # 湖面高度變化動畫持續時間
const MAX_LAKE_DELTA_HEIGHT = 280  # 最高湖面升降高度

@onready var front_turbines: Array[AnimatedSprite2D] = [
	$Player1UI/TurbineFrontRotate,
	get_node_or_null("Player2UI/TurbineFrontRotate")
]
@onready var back_turbines: Array[AnimatedSprite2D] = [
	$Player1UI/TurbineBackRotate,
	get_node_or_null("Player2UI/TurbineBackRotate")
]
@onready var upper_lake: Array[Node2D] = [
	$Player1UI/UpperLake,
	get_node_or_null("Player2UI/UpperLake")
]
@onready var lower_lake: Array[Node2D] = [
	$Player1UI/LowerLake,
	get_node_or_null("Player2UI/LowerLake")
]

@onready var tutorial_player: Node = $TutorialMimicPlayer

func _ready():
	GameState.level1_state_updated.connect(_on_level1_state_updated)

	# 連接玩家旋轉的訊號
	SignalBus.player_full_rotation_completed.connect(_on_player_full_rotation_completed)
	SignalBus.player_rotation_detected.connect(_on_player_rotation_detected)

	# 連接電仔正在收集的訊號
	SignalBus.electrons_scoring.connect(_on_electrons_scoring)

	for i in range(2):
		if upper_lake[i]:
			init_upper_lake_positions.append(upper_lake[i].position)
		if lower_lake[i]:
			init_lower_lake_positions.append(lower_lake[i].position)

func _process(delta):
	pass

func _physics_process(delta: float) -> void:
	for i in range(num_visible_players):  # 遍歷兩個玩家的渦輪
		# 漸進式減少速度
		front_turbines[i].speed_scale *= DAMPING_FACTOR
		back_turbines[i].speed_scale *= DAMPING_FACTOR
		
		# 當速度很小時直接設為 0
		if abs(front_turbines[i].speed_scale) < SPEED_THRESHOLD:
			front_turbines[i].speed_scale = 0
		if abs(back_turbines[i].speed_scale) < SPEED_THRESHOLD:
			back_turbines[i].speed_scale = 0

func set_tutorial_player_visible(toggle_visible: bool) -> void:
	tutorial_player.visible = toggle_visible

func adjust_lake_heights(player_id: int, forward: bool) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move upper lake down
	var upper_target = init_upper_lake_positions[player_id] + Vector2(0, delta_lake_height)
	tween.tween_property(upper_lake[player_id], "position", upper_target, LAKE_HEIGHT_ANIMATION_DURATION)
	
	# Move lower lake up
	var lower_target = init_lower_lake_positions[player_id] - Vector2(0, delta_lake_height)
	tween.tween_property(lower_lake[player_id], "position", lower_target, LAKE_HEIGHT_ANIMATION_DURATION)

func _on_level1_state_updated(state_info: Dictionary):
	num_visible_players = state_info.num_visible_players

	match state_info.stage:
		GameState.GameStage.LEVEL_START:
			rotation_enabled = false
			set_tutorial_player_visible(true)
		GameState.GameStage.TUTORIAL_1:
			set_tutorial_player_visible(true)
		GameState.GameStage.TUTORIAL_2:
			rotation_enabled = true
			set_tutorial_player_visible(false)
		GameState.GameStage.TUTORIAL_4:
			rotation_enabled = false
		GameState.GameStage.GAME_PLAY:
			rotation_enabled = true
		GameState.GameStage.SCORE:
			rotation_enabled = false
		
	for i in range(num_visible_players):
		front_turbines[i].play("rotate")
		back_turbines[i].play("rotate")

func _on_player_full_rotation_completed(player: Node, clockwise: bool):
	if not rotation_enabled:
		return
	if clockwise:
		return

	var player_id = 0 if player == PlayerManager.player1 else 1
	SignalBus.electrons_to_spawn.emit(1, player_id, 0)
	
	if delta_lake_height < MAX_LAKE_DELTA_HEIGHT:
		delta_lake_height += LAKE_HEIGHT_ADJUSTMENT_PER_ROTATION
		adjust_lake_heights(player_id, true)

func _on_player_rotation_detected(player: Node, clockwise: bool, speed: float):
	if not rotation_enabled:
		return
	if clockwise:
		return

	var player_id = 0 if player == PlayerManager.player1 else 1
	front_turbines[player_id].speed_scale = (1 if clockwise else -1) * speed * 5
	back_turbines[player_id].speed_scale = (1 if clockwise else -1) * speed * 5

func _on_electrons_scoring(count: int, player_id: int):
	front_turbines[player_id].speed_scale = 2
	back_turbines[player_id].speed_scale = 2

	if delta_lake_height > 0:
		delta_lake_height -= LAKE_HEIGHT_ADJUSTMENT_PER_ROTATION
		adjust_lake_heights(player_id, false)

func _on_game_over(_state_info: Dictionary):
	pass
