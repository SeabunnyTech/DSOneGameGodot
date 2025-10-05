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



var p1_tween
var p2_tween
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
	
	p2_progress.heading_altered.connect(func(target_state):
		if p2_tween:
			p2_tween.kill()
		p2_tween = create_tween()
		if target_state:
			$OnTriggerSFX.play()
			p2_tween.tween_property(self, 'scale', Vector2(1.05, 1.05), 0.3)
		else:
			p2_tween.tween_property(self, 'scale', Vector2(1, 1), 0.3)
	)

	p1_progress.triggered.connect(_on_option_triggered)
	p2_progress.triggered.connect(_on_option_triggered)


func _on_option_triggered():
	if Globals.intended_player_num == 1:
		all_player_ready.emit()
		reset()
	elif Globals.intended_player_num == 2:
		if p1_progress.progress == 1.0 and p2_progress.progress == 1.0:
			all_player_ready.emit()
			reset()


func _process(_delta: float) -> void:

	queue_redraw()
	# 判斷兩個 player 是否在內, 是的話就 tween 增加 progress
	# progress 到底就判斷要不要放事件出來
	if disabled:
		return

	if not Engine.is_editor_hint():
		var p1_triggering = portal_area.overlaps_body(player1)
		p1_progress.react(p1_triggering)

		if Globals.intended_player_num == 2:
			var p2_triggering = portal_area.overlaps_body(player2)
			p2_progress.react(p2_triggering)




func _draw_progress(progress, player_idx):

	var hue = player1.hue if player_idx == 1 else player2.hue
	var y0 = 800 if player_idx == 1 else 860
	#var rect = Rect2(Vector2(-600, -600), Vector2(1200, 1400))  # 位置和大小
	var player_color = Color.from_hsv(hue, 1, 1, 1)
	var light_gray = Color(0.95, 0.95, 0.95)
	var width = 30.0  # 邊框寬度
	#draw_rect(rect, color, false, width)

	# p1: 有 p1 與 p2 的進度條
	# 進度條尾端是灰色
	draw_line(Vector2(-600, y0), Vector2(progress * 1200 - 600, y0), player_color, width)
	draw_line(Vector2(progress * 1200 - 600, y0), Vector2(600, y0), light_gray, width)
	


func _draw():
	if not Engine.is_editor_hint():
		_draw_progress(p1_progress.progress, 1)

		if Globals.intended_player_num == 2:
			_draw_progress(p2_progress.progress, 2)
