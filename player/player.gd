class_name Player extends CharacterBody2D

signal on_state_changed(new_state: State)


signal full_rotation_completed(player: Node2D, clockwise: bool)
signal rotation_detected(player: Node2D, clockwise: bool, speed: float)

signal linear_movement_detected(player: Node2D, x_speed: float)
signal linear_burst_triggered(player: Node2D, distance: float, average_speed)

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
	State.TRIGGERED	:	[1, 1, 1],
}

var hue
@export var index = 0:
	set(value):
		index = value
		hue = {0: 0.50, 1:0.45}[index]	# 預設的一些 hue



# 狀態轉換相關的變數與函數

@export var init_state: State = State.LOST
var state: State = State.LOST
var heading_state
var tween

func heads_to_state(new_state, immediate=false, force=false):
	if heading_state == new_state and not force:
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



func _start_color_transition(_new_state, immediate):
	# 調整顏色
	var sva = sva_table[heading_state]
	var target_color = Color.from_hsv(hue, sva[0], sva[1], sva[2])
	if _new_state == State.ACTIVE and in_anticyclone_mode:
		target_color = anticyclone_color
	if immediate:
		modulate = target_color
		state = heading_state
		on_state_changed.emit(state)
		return

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, 'modulate', target_color, 0.3)
	tween.finished.connect(
		func():
			state=heading_state
			visible = not (state==State.LOST)
			on_state_changed.emit(state)
	)




############
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
var target_position: Vector2 = Vector2(0, -1000)

func set_smoothing_speed(new_speed: float):
	smoothing_speed = new_speed

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
	$Motion/Angular.connect("full_rotation_completed", full_rotation_completed.emit)
	$Motion/Angular.connect("rotation_detected", rotation_detected.emit)	

	$Motion/LinearMotion.connect("linear_movement_detected", linear_movement_detected.emit)
	$Motion/LinearMotion.connect("linear_burst_triggered", linear_burst_triggered.emit)
	

	heads_to_state(init_state, true)
	anticyclone_h_label.modulate.a = 0.0


func _process(_delta: float) -> void:
	# 3 顆 metaball
	var ball_positions: Array[Vector2] = [
		Vector2(0, 0),
		inertia_follower1.position,
		inertia_follower2.position]

	metaball_node.update_ball_positions(ball_positions)

@onready var anticyclone_h_label = $AnticycloneH

var in_anticyclone_mode = false
var anticyclone_color = Color.BLACK

func set_player_appearance(is_anticyclone: bool, params={}):

	var duration: float = 0.5
	if 'duration' in params:
		duration = params['duration']

	metaball_node.switch_visual(is_anticyclone, duration)
	in_anticyclone_mode = is_anticyclone

	var label_tween = get_tree().create_tween()
	var target_alpha = 1.0 if is_anticyclone else 0.0
	label_tween.tween_property(anticyclone_h_label, "modulate:a", target_alpha, duration)

	# Kill any ongoing color transition before starting a new one
	if tween:
		tween.kill()

	if 'color' in params:
		anticyclone_color = params['color']

	if is_anticyclone:
		# When switching to anticyclone, tween modulate to the label's theme color
		tween = create_tween()

		# 等高線的顏色
		tween.parallel().tween_property(self, 'modulate', anticyclone_color, duration)

		# H 的顏色
		tween.tween_method(func(val):
			anticyclone_h_label.add_theme_color_override("font_color", val),
			anticyclone_h_label.get_theme_color("font_color"),
			anticyclone_color,
			duration)

	else:
		# When switching back, restore the color based on the current state
		heads_to_state(state, false, true)


func set_radii(new_radius: Array[float]):
	metaball_node.update_ball_radii(new_radius)
