@tool
class_name DSOneLogo extends Node2D

# 提供外部使用的信號
signal state_changed(new_state)
signal heading_new_state(new_state)


@export var hue = 0.57:	# 青綠 0.45 水藍 0.57
	set(value):
		hue = value
		if Engine.is_editor_hint():
			$ScalarNode/Capsules.modulate = Color.from_hsv(hue, 0.7, 1)
			$ScalarNode/Circle.modulate = Color.from_hsv(hue, 0.4, 1)

enum State {
	HIDDEN,
	IDLE,
	INVITING,
	TRIGGERED
}

# 記錄了各狀態顏色的 sva 值 (hsv 的 sv 以及 a for alpha)
var	capsule_sva = {
	State.HIDDEN		:	[0, 0.56, 0],
	State.IDLE		:	[0, 0.56, 1],
	State.INVITING	:	[0.4, 1, 1],
	State.TRIGGERED	:	[0.7, 1, 1],
}

var	circle_sva = {
	State.HIDDEN		:	[0, 0.78, 0],
	State.IDLE		:	[0, 0.78, .1],
	State.INVITING	:	[0.2, .78, .1],
	State.TRIGGERED	:	[1, 1, 1],
}

# 用來查找調用顏色的函數
func lookup_color(logo_state: State, sva_dict):
	var sva = sva_dict[logo_state]
	return Color.from_hsv(hue, sva[0], sva[1], sva[2])

func capsule_color(logo_state):
	return lookup_color(logo_state, capsule_sva)

func circle_color(logo_state):
	return lookup_color(logo_state, circle_sva)


# 各種尺寸
var scales = {
	State.HIDDEN		:	Vector2(0, 0),
	State.IDLE		:	Vector2(.9, .9),
	State.INVITING	:	Vector2(1, 1),
	State.TRIGGERED	:	Vector2(1.2, 1.2),
}

var transition_times = {
	State.HIDDEN		:	1,
	State.IDLE		:	2,
	State.INVITING	:	1,
	State.TRIGGERED	:	1,
}


# 可以調整的一些參數
@export var transition_time_multiplier = 0.8
@export var preview_state = State.INVITING:
	set(value):
		preview_state = value
		if Engine.is_editor_hint():
			heads_to_state(value, true)
@export var init_state = State.HIDDEN

# 主 tween 掌管全體的狀態
# 小 tween 控制個別物件的反應
@onready var main_tween
@onready var capsule_tween
@onready var circle_tween


var state = null
var heading_state = null
var prev_heading_state = null		# 提供切換狀態的路途中要再次變換方向時作判斷

# 方便呼叫避免打錯字
@onready var scalar_node = $ScalarNode
@onready var capsule_node = $ScalarNode/Capsules
@onready var circle_node = $ScalarNode/Circle
@onready var area_2d = $ScalarNode/Area2D


var circle_center: 
	get:
		return circle_node.global_position

var circle_radius:
	get:
		return 400 * $ScalarNode/Circle/BigWhiteCircle.global_scale[0]


func _ready() -> void:
	heads_to_state(init_state, true)


func _process(delta: float) -> void:
	$ScalarNode/Label.visible = is_triggered()


# 觸發與離開的反應
func overlaps_trigger_area(trigger: Node):
	return area_2d.overlaps_body(trigger)


# 狀態的轉換
func heads_to_state(new_state: State, immediate=false):
	# 這個判斷讓這個函數可以同時被觸發多次也不會出錯
	if heading_state == new_state:
		return

	# 記下狀態變換過程
	prev_heading_state = heading_state
	heading_state = new_state

	# 釋放狀態變換信號
	heading_new_state.emit(heading_state)

	# 不適立即要跳到新狀態的情況
	if not immediate:
		_play_transition_tweens(new_state)
		_play_transition_sfx(new_state)
		return

	# 立即切到新狀態並啟動對應的到站 tween
	scalar_node.scale = scales[new_state]
	capsule_node.scale = Vector2(1, 1)
	circle_node.scale = Vector2(1, 1)
	capsule_node.modulate = capsule_color(new_state)
	circle_node.modulate = circle_color(new_state)
	_on_transotion_tween_finished()



func _is_leaving_state(the_state: State, include_preheading=true):
	# 如果剛才準備要進入 the_state 但還沒到就切走了也算 is_leaving_state
	var was_there = (state == the_state)
	var was_heading_there = (prev_heading_state == the_state)
	var is_heading_somewhere_else = (heading_state != the_state)

	if not include_preheading:
		return was_there and is_heading_somewhere_else
	else:
		return (was_there or was_heading_there) and is_heading_somewhere_else 



func _play_transition_tweens(new_state: State):
	# 動作較大的狀態轉換用 TRANS_ELASTIC
	var trans_type = Tween.TRANS_CUBIC
	if _is_leaving_state(State.HIDDEN) or new_state == State.TRIGGERED:
		trans_type = Tween.TRANS_ELASTIC

	_reset_all_tweens(trans_type)

	var t = transition_times[new_state] * transition_time_multiplier

	# Logo 的主尺寸
	main_tween.tween_property(scalar_node, 'scale', scales[new_state], t)

	# 配件的尺寸在 transition 過程中先復原到 1
	capsule_tween.tween_property(capsule_node, 'scale', Vector2(1, 1), t)
	circle_tween.tween_property(circle_node, 'scale', Vector2(1, 1), t)

	# 配件的顏色各自走到新狀態
	capsule_tween.parallel().tween_property(capsule_node, 'modulate', capsule_color(new_state), t)
	circle_tween.parallel().tween_property(circle_node, 'modulate', circle_color(new_state), t)

	# 暫態動畫結束後連接穩態的動畫
	main_tween.finished.connect(_on_transotion_tween_finished)

	# 三段都要播放
	_play_tweens([main_tween, capsule_tween, circle_tween])



func _play_transition_sfx(new_state: State):
	# 只要是離開 hidden 的狀態都會播放 on_showing_sfx
	if _is_leaving_state(State.HIDDEN):
		$on_showing_sfx.play()

	# 要成功了播放 triggered 音效
	if heading_state == State.TRIGGERED:
		$on_triggered_sfx.play()
	
	if _is_leaving_state(State.TRIGGERED):
		$on_showing_sfx.play()



# 到達狀態後的反應與呼叫
func _on_transotion_tween_finished():	
	# 完成狀態的切換
	state = heading_state
	state_changed.emit(state)

	_reset_all_tweens(Tween.TRANS_SINE)

	# 播放接續的動畫, 事實上只有 inviting 比較動感有這個環節
	match state:
		State.INVITING:
			_play_inviting_loop_tween()


const DURATIONS = {
	ELASTIC = 2.5,
	FADE = 1.0,
	RIPPLE = 2.0,
	MERGE = 0.4,
	POSITION = 1.0,
	SQUASH = 0.2,
	STRETCH = 0.15
}


const SCALES = {
	NORMAL = Vector2(1.0, 1.0),
	SMALL = Vector2(0.1, 0.1),
	RIPPLE = Vector2(1.1, 1.1),
	SQUASH = Vector2(1.07, 0.93),
	STRETCH = Vector2(0.93, 1.01),
	BOUNCE = Vector2(0.97, 1.03)
}



func _play_inviting_loop_tween():
	# TODO 這個函數會引發 started with no Tweener 錯誤但是目前沒找到原因

	# 讓圓盤一閃即逝
	circle_tween.tween_interval(0.6)
	circle_tween.tween_property(circle_node, "modulate:a", 0.4, 0.1)
	circle_tween.tween_property(circle_node, "modulate:a", 0, 1.1)
	#circle_tween.tween_interval(0.2)

	# 讓圓圈反覆縮放
	## 縮小 / 變半透明
	#circle_tween.tween_property(circle_node, "scale", SCALES.RIPPLE, DURATIONS.RIPPLE)
	#circle_tween.parallel().tween_property(circle_node, "modulate:a", 0.8, DURATIONS.FADE)

	## 放大 / 變實心
	#circle_tween.tween_property(circle_node, "scale", SCALES.NORMAL, DURATIONS.SQUASH)
	#circle_tween.parallel().tween_property(circle_node, "modulate:a", 1.0, 0.0)

	# 讓上下膠囊反覆壓縮
	capsule_tween.tween_property(capsule_node, "scale", SCALES.SQUASH, DURATIONS.MERGE)
	capsule_tween.tween_property(capsule_node, "scale", SCALES.STRETCH, DURATIONS.SQUASH)\
		.set_trans(Tween.TRANS_CUBIC)
	capsule_tween.tween_property(capsule_node, "scale", SCALES.SQUASH, DURATIONS.SQUASH)\
		.set_trans(Tween.TRANS_BOUNCE)
	capsule_tween.tween_property(capsule_node, "scale", SCALES.BOUNCE, DURATIONS.STRETCH)
	capsule_tween.tween_property(capsule_node, "scale", SCALES.NORMAL, 0.25)
	capsule_tween.tween_interval(0.6)

	# 循環播放
	circle_tween.set_loops()
	capsule_tween.set_loops()

	# 只有這兩段需要 play
	_play_tweens([circle_tween, capsule_tween])



# 中斷所有動畫並重創所有 tween 讓系統可以執行任何新動畫
func _reset_all_tweens(trans_type=Tween.TRANS_CUBIC, ease_mode=Tween.EASE_OUT):
	# 立即中斷任何運行中的動畫
	for tween in [main_tween, capsule_tween, circle_tween]:
		if tween:
			tween.kill()

	var _create_tween = func():
		var tween = create_tween()\
			.set_ease(ease_mode)\
			.set_trans(trans_type)
		tween.pause()
		return tween

	main_tween = _create_tween.call()
	capsule_tween = _create_tween.call()
	circle_tween = _create_tween.call()


func _play_tweens(tweens):
	for tween in tweens:
		tween.play()


func is_in_transition():
	return heading_state != state


func is_triggered():
	return state==State.TRIGGERED and not is_in_transition()
# 測試用的區塊暫時功成身退
#func _input(event: InputEvent) -> void:

#	var key_state_map = {
#		KEY_H : State.HIDDEN,
#		KEY_I : State.IDLE,
#		KEY_V : State.INVITING,
#		KEY_R : State.TRIGGERED
#	}

#	if event is InputEventKey and event.pressed:
#		if event.keycode in key_state_map:
#			heads_to_state(key_state_map[event.keycode])
