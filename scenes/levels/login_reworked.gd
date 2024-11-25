extends Node2D

# 這是一個遊戲場景
# 每一個遊戲場景都應該管理以下事務
#
# 1. 玩家的游標外觀
# 2. 場內的物件被觸發以後要執行什麼動作
#


var player_num = 1

@onready var logo = $DSOneLogo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 連接信號
	# 1. 玩家的進入與離開
	# 2. Logo 被觸發與被遠離

	# 讓第一個 Logo 進場
	logo.heads_to_state(logo.State.IDLE)



func _on_first_player_state(enter: bool):

	if enter:
		# 第一 Logo => INVITING
		# INVITING 動畫結束才 Triggerable
		pass
	else:
		# 第一 Logo => FADED
		# FADED 動畫隨時可以被中斷
		pass




func _on_second_player_state(enter: bool):
	if enter:
		# 第一 Logo 移左, 第二 Logo => INVITING
		pass
	else:
		# 第一 Logo 回中, 第二 Logo => HIDDEN 
		pass



func _on_first_logo_trigger_state(triggered: bool):
	# 玩家碰到 Logo 時 Logo 會自己進入 Triggering 動畫
	# Triggering 動畫完成時抵達此處

	# 此時有兩種情況
	# 1. 第二玩家在場 => 等待第二玩家就位
	# 2. 第二玩家不在場 => 轉場去下一個畫面
	pass



func _on_second_logo_trigger_state(triggered: bool):
	pass
