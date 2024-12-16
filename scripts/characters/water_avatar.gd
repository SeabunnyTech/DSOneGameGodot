extends CharacterBody2D

signal merged_with_player(node: Node2D)
signal separated_from_player(node: Node2D)
signal desired_position_changed(node: Node2D, new_desired_position: Vector2)

@export var player_id: int = 0
@export var follow_distance: float = 10.0
@export var merge_distance: float = 50.0
@export var separation_distance: float = 200.0

@onready var metaball = $Metaball
@onready var inertia_follower = $Metaball/InertiaFollower

var is_merged: bool = false
var target_player: Node2D = null
# var init_position: Vector2

var last_position: Vector2
var current_velocity: Vector2

var waiting_tween: Tween

var base_color = Color.from_hsv(0.45, 0.6, 1, 1)

func _ready():
	# 開始閃爍動畫
	set_color(Color.from_hsv(0.45, 0.6, 1, 1))
	start_waiting_animation()

func _process(_delta):
	# 2 顆 metaball
	var ball_positions: Array[Vector2] = [Vector2(0, 0), inertia_follower.position]

	metaball.update_ball_positions(ball_positions)

func _physics_process(_delta):
	if !is_merged:
		if target_player and position.distance_to(target_player.position) < merge_distance:
			merge_with_player()
		return
		
	if target_player:
		var distance = position.distance_to(target_player.position)
		if distance > separation_distance:
			separate_from_player()
			return
			
		# 跟隨玩家，但保持在河道內
		var direction = (target_player.position - position).normalized()
		var desired_position = target_player.position - direction * follow_distance
		
		desired_position_changed.emit(self, desired_position)

	if last_position:
		current_velocity = (position - last_position) / _delta
	last_position = position

func init(player: Node2D, init_pos: Vector2):
	player_id = player.index
	target_player = player
	position = init_pos

func merge_with_player():
	is_merged = true
	merged_with_player.emit(self)
	stop_waiting_animation()

func separate_from_player():
	is_merged = false
	separated_from_player.emit(self)
	start_waiting_animation()

func start_waiting_animation():
	set_color(base_color)
	# 停止之前的動畫（如果有的話）
	if waiting_tween:
		waiting_tween.kill()
	
	waiting_tween = create_tween()
	waiting_tween.set_loops() # 設置無限循環

	waiting_tween.tween_method(
		func(alpha: float): 
			set_color(Color(base_color, alpha)),
		1.0, 0.3, 0.5
	)
	# 再淡入
	waiting_tween.tween_method(
		func(alpha: float): 
			set_color(Color(base_color, alpha)),
		0.3, 1.0, 0.5
	)

func stop_waiting_animation():
	if waiting_tween:
		waiting_tween.kill()

	waiting_tween = create_tween()
	waiting_tween.tween_method(
		func(alpha: float): 
			set_color(Color(base_color, alpha)),
		0.3, 1.0, 0.5
	)

func set_color(target_color: Color):
	var col = Color(target_color)
	modulate = col
	var vec4_col = Vector4(col.r, col.g, col.b, col.a)
	var vec4_colors: Array[Vector4] = [vec4_col, vec4_col, vec4_col]
	metaball.update_ball_colors(vec4_colors)
