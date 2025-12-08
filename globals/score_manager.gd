extends Node

signal score_updated(scores: Dictionary)

var scores: Dictionary = {
	0: 0,  # Player 1 score
	1: 0   # Player 2 score
}

var spawn_areas: Dictionary = {
	0: {}, # {player1: {spawn_id: count}}
	1: {}  # {player2: {spawn_id: count}}
}

func _ready() -> void:
	get_tree().root.connect("ready", _on_scene_changed)
	#SignalBus.electrons_scoring.connect(_on_electrons_scoring)
	#SignalBus.electrons_area_scored.connect(_on_electrons_area_scored)

func register_spawn_area(player_id: int, spawn_id: int) -> void:
	if not spawn_areas.has(player_id):
		spawn_areas[player_id] = {}
	spawn_areas[player_id][spawn_id] = 0

func unregister_spawn_area(player_id: int, spawn_id: int) -> void:
	if spawn_areas.has(player_id):
		spawn_areas[player_id].erase(spawn_id)

func start_score(player_id: int) -> void:
	if not spawn_areas.has(player_id):
		return
	# Emit collect signal for each spawn area of this player
	# TODO: 改成間隔時間觸發（為了應付 level2 的 camera 移動速度，好讓電仔收集速度跟上 camera）
	for spawn_id in spawn_areas[player_id].keys():
		await get_tree().create_timer(0.2).timeout
		# 根據目前場景中 ElectronSpawnArea 的 metadata (player_id, spawn_id) 
		# 送訊號給 ElectronSpawn，讓它們開始收集電仔
		SignalBus.electrons_to_collect.emit(player_id, spawn_id)

func reset_scores() -> void:
	scores = {0: 0, 1: 0}
	score_updated.emit(scores)

func _on_electrons_scoring(count: int, player_id: int) -> void:
	scores[player_id] += count
	score_updated.emit(scores) # 訊號會被 HUD 接收

func _on_electrons_area_scored(player_id: int, spawn_id: int) -> void:
	spawn_areas[player_id][spawn_id] = 0
	if spawn_areas[player_id].values().all(func(value: int): return value == 0):
		SignalBus.electrons_all_scored.emit(player_id)

func _on_scene_changed() -> void:
	reset_scores()
