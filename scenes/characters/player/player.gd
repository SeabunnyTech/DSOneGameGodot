class_name Player extends CharacterBody2D

signal on_state_changed(new_state: State)

signal countdown_complete(player: Node2D)
signal countdown_cancelled(player: Node2D)


signal full_rotation_completed(player: Node2D, clockwise: bool)
signal rotation_detected(player: Node2D, clockwise: bool, speed: float)


enum State {
	LOST,			# 沒有感應到所以消失了
	FADED,			# 球放太低但是有感應到 (在地上)
	ACTIVE,			# 球正常被偵測到, 隨時可以有動作
	TRIGGERED,		# 剛剛成功觸發了某件事
}

# 用來呈現外觀的 [h]sva 表
var sva_table = {
	State.LOST		:	[0, 1, 0],
	State.FADED		:	[0, 1, 0.2],
	State.ACTIVE		:	[0.6, 1, 1],
	State.TRIGGERED	:	[1, 1, 1]
}

var hue
@export var index = 0:
	set(value):
		index = value
		hue = {0: 0.57, 1:0.45}[index]	# 預設的一些 hue


# 狀態轉換相關的變數與函數

@export var init_state: State = State.LOST
var state: State = State.LOST
var heading_state
var tween

func heads_to_state(new_state, immediate=false):
	if heading_state == new_state:
		return
	heading_state = new_state

	# 為了向前相容 visible 的使用
	if heading_state != State.LOST:
		visible = true

	# 在消失或出現時播放音效
	var is_heading_lost = (new_state == State.LOST) and (state != State.LOST)
	var is_showing = (state == State.LOST) and (new_state != State.LOST)
	if is_heading_lost:
		$on_lost_sfx.play()
	elif is_showing:
		$on_showing_sfx.play()

	# 調整顏色狀態
	_start_color_transition(new_state, immediate)



func _start_color_transition(new_state, immediate):
	# 調整顏色
	var sva = sva_table[heading_state]
	var target_color = Color.from_hsv(hue, sva[0], sva[1], sva[2])
	if immediate:
		set_color(target_color)
		state = heading_state
		on_state_changed.emit(state)
		return

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_method(set_color, modulate, target_color, 0.3)
	tween.finished.connect(
		func():
			state=heading_state
			visible = not (state==State.LOST)
			on_state_changed.emit(state)
	)




############
@onready var radial_progress: Control = $RadialProgress
@onready var metaball_node: Node = $Metaball
@onready var inertia_follower1: Node = $Metaball/InertiaFollower
@onready var inertia_follower2: Node = $Metaball/InertiaFollower/InertiaFollower

var is_counting_down: bool = false
# var countdown_duration: float = 3.0  # Adjust this value as needed

var selected_level: String = ""
############



# 附加在 set_target_position 上的功能:用 attractor 吸住游標
var attractor_position
var attractor_radius: float
func set_attractor(pos: Vector2, radius: float):
	attractor_position = pos
	attractor_radius = radius

func reset_attractor():
	attractor_position = null


# 為了處理輸入位置跳躍而寫的邏輯, 導致 player 要用 set_target_position 設定位置
@export var smoothing_speed: float = 30.0
var target_position: Vector2 = Vector2(0, 3000)

func set_target_position(new_position: Vector2):
	if attractor_position:
		# 簡易的 attractor: 靠近就會吸住
		if (new_position - attractor_position).length() < attractor_radius:
			target_position = attractor_position
			return
	target_position = new_position

func _physics_process(delta: float):
	position = position.lerp(target_position, smoothing_speed * delta)



func _ready() -> void:
	$Motion/Angular.connect("full_rotation_completed", SignalBus.player_full_rotation_completed.emit)
	$Motion/Angular.connect("rotation_detected", SignalBus.player_rotation_detected.emit)	
	
	$Motion/Angular.connect("full_rotation_completed", full_rotation_completed.emit)
	$Motion/Angular.connect("rotation_detected", rotation_detected.emit)	
	
	radial_progress.hide()
	heads_to_state(init_state, true)


func _process(_delta: float) -> void:
	if radial_progress.progress >= 100:
		radial_progress.progress = 0
		if is_counting_down:
			is_counting_down = false
			countdown_complete.emit(self)

	# 3 顆 metaball
	var ball_positions: Array[Vector2] = [
		Vector2(0, 0),
		inertia_follower1.position,
		inertia_follower2.position]

	metaball_node.update_ball_positions(ball_positions)


func set_color(new_color):
	var col = Color(new_color)
	modulate = col
	var vec4_col = Vector4(col.r, col.g, col.b, col.a)
	var vec4_colors: Array[Vector4] = [vec4_col, vec4_col, vec4_col]
	$Metaball.update_ball_colors(vec4_colors)

func start_progress_countdown(time: float = 5.0) -> void:
	radial_progress.show()
	is_counting_down = true
	radial_progress.animate(time) # clockwise
	radial_progress.progress = 0

func stop_progress_countdown() -> void:
	if is_counting_down:
		is_counting_down = false

	radial_progress.progress = 0
	radial_progress.hide()
	countdown_cancelled.emit(self)
