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

var PState = Player.State
var player1 = PlayerManager.player1
var player2 = PlayerManager.player2


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
	## logo1 在沒玩家時往 fade, 有玩家時看 trigger 狀態前往 invite 或 triggered 
	var logo1_heading_state
	var logo1_triggered = false
	if player1.state in [PState.FADED, PState.LOST]:
		logo1_heading_state = LState.IDLE
	else:
		logo1_triggered = logo1.overlaps_trigger_area(player1)
		logo1_heading_state = LState.TRIGGERED if logo1_triggered else LState.INVITING
	logo1.heads_to_state(logo1_heading_state)

	## logo2 在玩家二不在時藏起, 在場時則同樣會選擇要去 invite 或 triggered
	var logo2_heading_state
	var logo2_triggered = false
	if player2.state in [PState.FADED, PState.LOST]:
		logo2_heading_state = LState.HIDDEN
	else:
		logo2_triggered = logo2.overlaps_trigger_area(player2)
		logo2_heading_state = LState.TRIGGERED if logo2_triggered else LState.INVITING
	logo2.heads_to_state(logo2_heading_state)

	# 接著要處理兩個 logo 的位置, 一個玩家以下和兩個玩家在場會讓 logo 調整位置
	if player2.state == PState.LOST:
		_heads_to_one_logo()
	else:
		_heads_to_two_logo()

	# 再來是更新 player 的觸發反應
	PlayerManager.update_player_trigger_state(player1, logo1_triggered)
	PlayerManager.update_player_trigger_state(player2, logo2_triggered)

	# 最後判定是否要進入下一關
	if logo1.state == LState.TRIGGERED:
		if player2.state == PState.LOST:
			# Go next scene with 1P
			pass
		elif logo2 == LState.TRIGGERED:
			# Go next scene with 2p
			pass


# 調整 logo 位置的函數

var heading_logo_layout = 1		# 1 代表一個 logo, 2 代表兩個 logo
var logo_position_tween

func _move_logo1(pos):
	if logo_position_tween:
		logo_position_tween.kill()
	logo_position_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	logo_position_tween.tween_property(logo1, 'position', Vector2(pos[0], pos[1]), 1)
	#logo_position_tween.parallel()


func _heads_to_one_logo():
	if heading_logo_layout == 1:
		return
	heading_logo_layout = 1
	_move_logo1(window_size/2)


func _heads_to_two_logo():
	if heading_logo_layout == 2:
		return
	heading_logo_layout = 2
	_move_logo1(window_size/2-logo2_offset)
