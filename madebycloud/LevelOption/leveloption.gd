@tool
extends Node2D

signal all_player_ready

@export var image: Texture2D:
	set(value):
		image = value
		$image.texture = image

@export var title: String:
	set(value):
		title = value
		$image/Label.text = title

# player_num 是 1 的情況下不會對第二個 player 有任何反應
@export var player_num: int = 1
var disabled = true

@onready var player1 = PlayerManager.player1
@onready var player2 = PlayerManager.player2
@onready var portal_area = $PortalArea


enum State {
	DISABLED,
	ONE_PLAYER_IN,
	TWO_PLAYER_IN,
	TRIGGERED
}


@onready var p1_progress = $P1ProgressTracker
@onready var p2_progress = $P2ProgressTracker


func reset():
	disabled = true
	p1_progress.reset()
	p2_progress.reset()



func _draw_selection_boarder():
	player1.player_hue

var p1_tween
func _ready():
	#position = Vector2(1200, 1200)
	disabled = false

	p1_progress.heading_altered.connect(func(target_state):
		if p1_tween:
			p1_tween.kill()
		p1_tween = create_tween()
		if target_state:
			$OnTriggerSFX.play()
			p1_tween.tween_property(self, 'scale', Vector2(1.05, 1.05), 0.3)
		else:
			p1_tween.tween_property(self, 'scale', Vector2(1, 1), 0.3)
	)
	
	# 這是為了 1 暫時做的, 現在不會對 2p 有任何反映	
	p1_progress.triggered.connect(_on_option_triggered)


func _on_option_triggered():
	if player_num == 1:
		all_player_ready.emit()


func _process(delta: float) -> void:

	queue_redraw()
	# 判斷兩個 player 是否在內, 是的話就 tween 增加 progress
	# progress 到底就判斷要不要放事件出來
	if disabled:
		return

	var p1_triggering = portal_area.overlaps_body(player1)
	p1_progress.react(p1_triggering)

	if player_num == 2:
		var p2_triggering = portal_area.overlaps_body(player2)
		p2_progress.react(p2_triggering)




func _draw_boarder(progress):

	#var rect = Rect2(Vector2(-600, -600), Vector2(1200, 1400))  # 位置和大小
	var color = Color.from_hsv(player1.hue, 1, 1, progress)
	var width = 30.0  # 邊框寬度
	#draw_rect(rect, color, false, width)
	draw_line(Vector2(-600, 800), Vector2(progress * 1200 - 600, 800), color, width)

func _draw():
	_draw_boarder(p1_progress.progress)
