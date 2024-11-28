extends Node2D

var num_visible_players = 0
var turbine_front_speed = 0
var turbine_back_speed = 0

const DAMPING_FACTOR = 0.95  # 調整這個值來改變減速速度 (0.9 更快, 0.99 更慢)
const SPEED_THRESHOLD = 0.01  # 當速度小於這個值時直接設為 0

@onready var front_turbines: Array[AnimatedSprite2D] = [
	$Player1UI/TurbineFrontRotate,
	$Player2UI/TurbineFrontRotate
]
@onready var back_turbines: Array[AnimatedSprite2D] = [
	$Player1UI/TurbineBackRotate,
	$Player2UI/TurbineBackRotate
]
@onready var tutorial_player: Node = $TutorialMimicPlayer

func set_tutorial_player_visible(toggle_visible: bool) -> void:
	tutorial_player.visible = toggle_visible

func _ready():
	GameState.level1_state_updated.connect(_on_level1_state_updated)

	# 連接玩家旋轉訊號
	SignalBus.player_full_rotation_completed.connect(_on_player_full_rotation_completed)
	SignalBus.player_rotation_detected.connect(_on_player_rotation_detected)

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

func _on_level1_state_updated(state_info: Dictionary):
	num_visible_players = state_info.num_visible_players

	match state_info.stage:
		GameState.GameStage.LEVEL_START:
			set_tutorial_player_visible(true)
		GameState.GameStage.TUTORIAL_1:
			set_tutorial_player_visible(true)
		GameState.GameStage.TUTORIAL_2:
			set_tutorial_player_visible(false)
	
	for i in range(num_visible_players):
		front_turbines[i].play("rotate")
		back_turbines[i].play("rotate")

func _on_player_full_rotation_completed(player: Node, clockwise: bool):
	var player_index = 0 if player == PlayerManager.player1 else 1
	SignalBus.electrons_to_spawn.emit(1, player_index, 0)

func _on_player_rotation_detected(player: Node, clockwise: bool, speed: float):
	var player_index = 0 if player == PlayerManager.player1 else 1
	front_turbines[player_index].speed_scale = (1 if clockwise else -1) * speed * 5
	back_turbines[player_index].speed_scale = (1 if clockwise else -1) * speed * 5

func _on_game_over(_state_info: Dictionary):
	pass
