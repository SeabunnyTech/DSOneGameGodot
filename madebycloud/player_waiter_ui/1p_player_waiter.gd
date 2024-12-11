extends Node


# 由於遊戲硬體設計 1p 消失時 2p 會自動變成 1p
# 所以只要判定 1p 消失就可以認定所有的玩家都消失了


signal player_lost_for_too_long


@export var wait_lost_player_duration = 10
var _wait_player_time = 0
var _is_waiting_for_player = false
var _timeout: bool = false


func reset():
	_timeout = false
	_wait_player_time = 0


# 設定開始等待
func set_wait_for_player(waiting):
	_is_waiting_for_player = waiting
	if not waiting:
		_wait_player_time = 0


func _process(delta: float) -> void:
	if _timeout:
		return

	# player 有出現的話直接把計時歸零
	var player = PlayerManager.player1
	if not player or player.state != Player.State.LOST:
		_wait_player_time = 0
	
	# 沒出現才來討論現在是不是在等, 在等的話就計時, 沒在等就不管
	if _is_waiting_for_player:
		_wait_player_time += delta
		if _wait_player_time > wait_lost_player_duration:
			_timeout = true
			player_lost_for_too_long.emit()
