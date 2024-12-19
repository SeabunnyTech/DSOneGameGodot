extends Node2D

# 轉場的信號
signal go_welcome_scene
signal go_select_scene(player_num: int)


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


@export var disabled = true


func enter_scene():
	visible = true
	modulate.a = 1

	# 關閉 disabled 的一瞬間會開啟 _process
	# 讓 logo1 彈出來, 完成進入轉場
	disabled = false


func leave_scene_after_delay(callback: Callable, delay=2):
	disabled = true
	var tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, 'modulate:a', 0, 1)
	tween.finished.connect(
		func():
			reset()
			callback.call()
	)


func reset():
	# 讓這整個物件消失不見先
	visible = false

	# Logo 藏起來
	for logo in logos:
		logo.heads_to_state(LState.HIDDEN, 1)

	# 清除吸子!
	for player in players:
		player.reset_attractor()

	# 重置狀態變數
	just_entered = true


func _ready() -> void:
	# 設定 logo 的色相與 player 相符
	logo1.hue = PlayerManager.player_hue[0]
	logo2.hue = PlayerManager.player_hue[1]

	# 設定 logo 位置
	logo1.position = window_size/2
	logo2.position = window_size/2 + logo2_offset

	# 連接信號
	for logo in logos:
		logo.heading_new_state.connect(func(new_state): _update_guide_text(logo, new_state))



func _process(delta: float) -> void:
	if disabled:
		return
	_interact(delta)



var lost_duration = 0
@export var lost_time_limit = 5		## 兩個玩家都消失多久以後會回到歡迎頁


var logo_heading_states = [null, null]	# 這個變數幾乎記錄了頁面當前狀態

func _interact(delta):
	# 觀察場上的玩家與 logo 狀態, 決定下一步要往哪走

	# 先處理個別 logo 的反應
	var num_logos = len(logos)
	for index in range(num_logos):
		logo_heading_states[index] =_decide_logo_state(index)

	# 調整 logo 狀態
	for index in num_logos:
		logos[index].heads_to_state(logo_heading_states[index])

	# 接著要處理兩個 logo 的位置, 一個玩家以下和兩個玩家在場會讓 logo 調整位置
	var should_show_two_logo = player2.state == PState.LOST
	_heads_to_logo_layout(should_show_two_logo)

	# 更新 player 的吸子位置
	for index in range(len(players)):
		var logo = logos[index]
		players[index].set_attractor(logo.circle_center, logo.circle_radius)

	# 再來是更新 player 的觸發反應
	for player in players:
		var logo_triggered = logos[player.index].overlaps_trigger_area(player)
		PlayerManager.update_player_trigger_state(player, logo_triggered)

	# 判定是否要轉場回到最開始的歡迎頁
	if PlayerManager.num_active_players() == 0:
		lost_duration += delta
		if lost_duration > lost_time_limit:
			leave_scene_after_delay(func(): go_welcome_scene.emit(), 0)
	else:
		lost_duration = 0

	# 判定是否要進行轉場到下一頁
	# 首先玩家一如果沒就位當然不用轉場
	if logo1.state == LState.TRIGGERED:
		# 如果任一個玩家還沒真正定下來的話也不要轉場
		if logo1.is_in_transition() or logo2.is_in_transition():
			return

		if player2.state == PState.LOST:
			# Go next scene with 1P
			leave_scene_after_delay(func(): go_select_scene.emit(1))
		elif logo2.state == LState.TRIGGERED:
			# Go next scene with 2p
			leave_scene_after_delay(func(): go_select_scene.emit(2))



func _decide_logo_state(index):
	var logo = logos[index]
	var player = players[index]
	var logo_heading_state
	var triggered = false
	if player.state in [PState.FADED, PState.LOST]:
		# 只有第一個 logo 在 player 消失時還會待著進入 IDLE
		logo_heading_state = LState.IDLE if index == 0 else LState.HIDDEN
	else:
		# 看有沒有接觸決定要觸發或不觸發
		triggered = logo.overlaps_trigger_area(player)
		logo_heading_state = LState.TRIGGERED if triggered else LState.INVITING
	return logo_heading_state



# 引導文字的邏輯是比較 sequential 的而非像外觀純 combinational
var just_entered = true

func _update_guide_text(logo:DSOneLogo, new_state: DSOneLogo.State):
	# 判斷現在該向玩家說什麼, 基本上只有兩種選項
	# 1. 鼓勵玩家就位
	# 2. 提示玩家把圓餅拿好
	# 主要判斷參考是觸發這個更新的動作, 也就是 new_state
	# 可以用 PlayerManager.num_active_players 輔助


	var msg = {
		'JUST_ENTERED':'太好了! 現在你有沒有注意到電幻一號所的標誌缺少了什麼部分呢?\n現在用你手上的控盤移動水滴, 彌補它的空缺吧!',
		'ALL_PLAYER_GONE':'歐噢! 所有的水滴都不見啦!\n面對電視舉起操控盤, 把水滴召喚回來!',
		'A_PLAYER_GONE':'歐噢! 有一位玩家的水滴消失了!\n面對電視舉起操控盤, 就可以把水滴召喚回來喔!',
		'INVITING':'注意到電幻一號所的標誌缺少了什麼部分嗎?\n 現在用你手上的控盤操控水滴去補完它吧!',
		'THANK_ONE':'謝謝你幫我們補完了標誌! 你的參與讓電幻的運作變完整啦!',
		'THANK_TWO':'謝謝你們補完了電幻一號所的標誌! 你們的參與讓電幻的運作變完整啦!',
		'INVITE_P1':'恭喜! 右邊的玩家已經補完了他的標誌, 現在輪到左邊的玩家了!\n現在就拿著水滴去補完最後一個缺口吧!',
		'INVITE_P2':'恭喜! 左邊的玩家已經補完了他的標誌, 現在輪到右邊的玩家了!\n現在就拿著水滴去補完最後一個缺口吧!',
	}

	# 初次進入
	if just_entered:
		show_message(msg['JUST_ENTERED'])
		just_entered = false
		return

	# 無玩家在場
	var num_active_players = PlayerManager.num_active_players()
	if num_active_players == 0:
		show_message(msg['ALL_PLAYER_GONE'])
		return
	
	# 其餘的多種可能包含玩家進入 / 離開 / Trigger / Untriggered
	match new_state:
		LState.HIDDEN:
			# 只有第二個玩家離開會觸發這個, 可以問
			show_message(msg['A_PLAYER_GONE'])
		LState.INVITING:
			# 這邊可以細分是從 TRIGGERED 倒退, 或是從 HIDDEN 進入的
			# 不過現在決定先簡單的邀請就好
			show_message(msg['INVITING'])
		LState.TRIGGERED:
			# 可以看兩個 logo 的現狀決定是都完成了要轉場
			# 或是要請另外一個玩家就位
			if num_active_players == 1:
				show_message(msg['THANK_ONE'])
			elif logo1.heading_state == LState.TRIGGERED and logo2.heading_state == LState.TRIGGERED:
				show_message(msg['THANK_TWO'])
			else:
				# 要請另外一個玩家就位
				var invite_msg = 'INVITE_P1' if logo == logo2 else 'INVITE_P2'
				show_message(msg[invite_msg])


func show_message(message):
	$Label.show_message(message)



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
