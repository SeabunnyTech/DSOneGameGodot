extends Node

@onready var player_one_container: VBoxContainer = $HBoxContainer/PlayerOneContainer
@onready var player_two_container: VBoxContainer = $HBoxContainer/PlayerTwoContainer

@onready var player_one_score: Label = %PlayerOneScore
@onready var player_one_timer: Label = %PlayerOneTimer
@onready var player_two_score: Label = %PlayerTwoScore
@onready var player_two_timer: Label = %PlayerTwoTimer

@onready var player_one_minimap: MarginContainer = $HBoxContainer/PlayerOneMiniMap
@onready var player_two_minimap: MarginContainer = $HBoxContainer/PlayerTwoMiniMap

@onready var separator: VSeparator = $HBoxContainer/VSeparator

func _ready() -> void:
	# Connect to timer updates
	TimerManager.game_time_updated.connect(_on_game_time_updated)
	
	# Connect to score updates
	ScoreManager.score_updated.connect(_on_score_updated)

	# Connect to game state updates, to turn on/off hud 1p/2p score and timer, or even minimap display
	GameState.hud_state_updated.connect(_on_hud_state_updated)

	# Initialize displays
	_update_score_display({0: 0, 1: 0})
	_update_timer_display(0)

	SignalBus.hud_ready.emit()

func _update_timer_display(time: float) -> void:
	# Format time to show one decimal place
	player_one_timer.text = "%02d:%02d" % [int(time / 60), int(time) % 60]
	player_two_timer.text = "%02d:%02d" % [int(time / 60), int(time) % 60]

func _update_score_display(scores: Dictionary) -> void:
	player_one_score.text = str(scores[0])
	player_two_score.text = str(scores[1])

func _on_game_time_updated(time: float) -> void:
	_update_timer_display(time)
	
func _on_score_updated(scores: Dictionary) -> void:
	_update_score_display(scores)

func _on_hud_state_updated(state_info: Dictionary) -> void:
	var scene = state_info.scene
	var stage = state_info.stage
	var num_visible_players = state_info.num_visible_players

	match scene:
		GameState.GameScene.LEVEL1:
			_handle_level1_state(stage, num_visible_players)
		GameState.GameScene.LEVEL2:
			_handle_level2_state(stage, num_visible_players)

func _handle_level1_state(stage: GameState.GameStage, num_visible_players: int = 0) -> void:
	if num_visible_players == 2:
		player_two_container.show()
		separator.show()
	else:
		player_two_container.hide()
		separator.hide()

	match stage:
		GameState.GameStage.LEVEL_START:
			pass
		GameState.GameStage.TUTORIAL_1:
			pass

func _handle_level2_state(stage: GameState.GameStage, num_visible_players: int = 0) -> void:
	if num_visible_players == 2:
		player_two_container.show()
		player_one_minimap.show()
		player_two_minimap.show()
		separator.show()
	else:
		player_two_container.hide()
		player_one_minimap.show()
		player_two_minimap.hide()
		separator.hide()

	match stage:
		GameState.GameStage.LEVEL_START:
			pass
		GameState.GameStage.TUTORIAL_1:
			pass
