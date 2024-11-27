extends Node2D

# 這是一個遊戲場景
# 每一個遊戲場景都應該管理以下事務
#
# 1. 玩家的游標外觀
# 2. 場內的物件被觸發以後要執行什麼動作

enum State {
	WAIT_ONE_PLAYER,
	WAIT_TWO_PLAYER,
	GO_NEXT_SCENE
}


var LState = DSOneLogo.State
@onready var logo1 = $DSOneLogo1
@onready var logo2 = $DSOneLogo2
@onready var logos = [logo1, logo2]

var PState = Player.State
var player1 = PlayerManager.player1
var player2 = PlayerManager.player2
var players = [player1, player2]

@onready var window_size = DisplayServer.window_get_size()
@onready var logo2_offset = Vector2i(0.2 * window_size[0], 0)



func _ready() -> void:
	# 設定 logo 的色相與 player 相符
	logo1.hue = PlayerManager.player_hue[0]
	logo2.hue = PlayerManager.player_hue[1]

	# 設定 logo 位置
	logo1.position = window_size/2
	logo2.position = window_size/2 + logo2_offset


var heading_state
func _heads_to_state(new_state: State):
	if heading_state == heading_state:
		return
	heading_state = new_state



func _process(_delta: float) -> void:
	# 觀察場上的玩家與 logo 狀態, 決定下一步要往哪走

	# 先處理個別 logo 的反應
	for index in range(len(logos)):
		_decide_logo_state_and_heads_there(index)

	# 接著要處理兩個 logo 的位置, 一個玩家以下和兩個玩家在場會讓 logo 調整位置
	var should_show_two_logo = player2.state == PState.LOST
	_heads_to_logo_layout(should_show_two_logo)

	# 再來是更新 player 的觸發反應
	for player in players:
		var logo_triggered = logos[player.index].overlaps_trigger_area(player)
		PlayerManager.update_player_trigger_state(player, logo_triggered)

	# 最後判定是否要進入下一關
	if logo1.state == LState.TRIGGERED:
		if player2.state == PState.LOST:
			# Go next scene with 1P
			pass
		elif logo2.state == LState.TRIGGERED:
			# Go next scene with 2p
			pass



func _decide_logo_state_and_heads_there(index):
	var logo = logos[index]
	var player = players[index]
	var heading_state
	var triggered = false
	if player.state in [PState.FADED, PState.LOST]:
		# 只有第一個 logo 在 player 消失時還會待著進入 IDLE
		heading_state = LState.IDLE if index == 0 else LState.HIDDEN
	else:
		# 看有沒有接觸決定要觸發或不觸發
		triggered = logo.overlaps_trigger_area(player)
		heading_state = LState.TRIGGERED if triggered else LState.INVITING
	logo.heads_to_state(heading_state)



# 調整 logo layout 的兩個小函數
var heading_to_two_logo_layout = false		# 1 代表一個 logo, 2 代表兩個 logo
var logo_position_tween

func _heads_to_logo_layout(should_show_two_logo: bool):
	if heading_to_two_logo_layout == should_show_two_logo:
		return
	heading_to_two_logo_layout = should_show_two_logo

	if heading_to_two_logo_layout:
		_move_logo1(window_size/2)
	else:
		_move_logo1(window_size/2 - logo2_offset)


func _move_logo1(pos):
	if logo_position_tween:
		logo_position_tween.kill()
	logo_position_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	logo_position_tween.tween_property(logo1, 'position', Vector2(pos[0], pos[1]), 1)
