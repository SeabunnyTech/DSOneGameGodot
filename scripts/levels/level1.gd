extends Node2D

var num_visible_players = 0
var turbine_front_speed = 0
var turbine_back_speed = 0

@onready var front_turbine: Node = $Player1UI/TurbineFrontRotate
@onready var back_turbine: Node = $Player1UI/TurbineBackRotate
@onready var tutorial_player: Node = $TutorialMimicPlayer

const Electron = preload("res://scenes/characters/electron.tscn")

# @onready var electron_spawn_area = $ElectronSpawnArea
var electrons = []
var electron_container: Node2D

func set_tutorial_player_visible(toggle_visible: bool) -> void:
	tutorial_player.visible = toggle_visible

func _ready():
	GameState.level1_state_updated.connect(_on_level1_state_updated)

	# electron_container = Node2D.new()
	# electron_container.name = "Electrons"
	# $".".add_child(electron_container)  # Add to Player1UI instead of root
	
	# $Player1UI/TurbineBackRotate.play("rotate")
	# $Player1UI/TurbineFrontRotate.play("rotate")

func _process(delta):
	pass

func _on_level1_state_updated(state_info: Dictionary):
	num_visible_players = state_info.num_visible_players

	match state_info.stage:
		GameState.GameStage.LEVEL_START:
			set_tutorial_player_visible(true)
		GameState.GameStage.TUTORIAL_1:
			set_tutorial_player_visible(true)
		GameState.GameStage.TUTORIAL_2:
			set_tutorial_player_visible(false)

func _on_game_over(_state_info: Dictionary):
	pass
