extends Node

signal score_updated(new_score: int, player_id: int)
signal electron_scored(count: int, spawn_id: int, player_id: int)

var scores: Dictionary = {
    0: 0,  # Player 1 score
    1: 0   # Player 2 score
}

func _ready() -> void:
    SignalBus.electrons_to_score.connect(_on_electrons_scored)

func _on_electrons_scored(count: int, player_id: int, spawn_id: int) -> void:
    scores[player_id] += count
    score_updated.emit(scores[player_id], player_id)
    electron_scored.emit(count, spawn_id, player_id)

func reset_scores() -> void:
    scores = {0: 0, 1: 0}
    for player_id in scores.keys():
        score_updated.emit(scores[player_id], player_id)