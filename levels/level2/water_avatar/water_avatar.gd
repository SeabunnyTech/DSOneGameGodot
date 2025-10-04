extends CharacterBody2D

signal merged_with_player(node: Node2D)
signal separated_from_player(node: Node2D)
signal desired_position_changed(node: Node2D, new_desired_position: Vector2, delta: float)

@export var player_id: int = 0
@export var follow_distance: float = 20.0
@export var merge_distance: float = 50.0
@export var separation_distance: float = 300.0

@onready var metaball = $Metaball
@onready var inertia_follower = $Metaball/InertiaFollower

var is_timeout: bool = false
var is_merged: bool = false
var target_player: Node2D = null

var waiting_tween: Tween
var arrow_tween: Tween

var base_color = Color.from_hsv(0.50, 0.6, 1, 1)
var waiting_color = Color.from_hsv(0.48, 0.6, 0.3, 1)

func _ready():
	# 開始閃爍動畫
	start_waiting_animation()
	start_arrow_animation()

func _process(_delta):
	# 2 顆 metaball
	var ball_positions: Array[Vector2] = [Vector2(0, 0), inertia_follower.position]

	metaball.update_ball_positions(ball_positions)

func _physics_process(_delta):
	var scene_node_pos = get_parent().position
	var player_position = target_player.position - scene_node_pos
	if !is_merged:
		if target_player and position.distance_to(player_position) < merge_distance:
			is_merged = true
			merge_with_player()
		return
		
	if target_player:
		var distance = position.distance_to(player_position)
		if distance > separation_distance:
			is_merged = false
			separate_from_player()
			return
			
		# 跟隨玩家，但保持在河道內
		var direction = (player_position - position).normalized()
		var desired_position = lerp(position, player_position, 0.75) - direction * follow_distance
		
		desired_position_changed.emit(self, desired_position, _delta)

func init(player: Node2D, init_pos: Vector2):
	player_id = player.index
	target_player = player
	position = init_pos
	is_timeout = false

func reset():
	is_timeout = false

func timeout_hide():
	self.hide()
	is_timeout = true

func merge_with_player():
	$Arrow.hide()
	self.hide()
	set_color(base_color)
	
	merged_with_player.emit(self)
	stop_waiting_animation()

func separate_from_player():
	if is_timeout:
		return

	$Arrow.show()
	self.show()
	set_color(waiting_color)

	separated_from_player.emit(self)
	start_waiting_animation()
	start_arrow_animation()

func start_waiting_animation():
	set_color(waiting_color)
	# 停止之前的動畫（如果有的話）
	if waiting_tween:
		waiting_tween.kill()
	
	waiting_tween = create_tween()
	waiting_tween.set_loops() # 設置無限循環

	# 只對 metaball 進行動畫
	waiting_tween.tween_method(
		func(alpha: float): 
			var vec4_col = Vector4(base_color.r, base_color.g, base_color.b, alpha)
			var vec4_colors: Array[Vector4] = [vec4_col, vec4_col, vec4_col]
			metaball.update_ball_colors(vec4_colors),
		1.0, 0.3, 0.5
	)
	# 再淡入
	waiting_tween.tween_method(
		func(alpha: float): 
			var vec4_col = Vector4(base_color.r, base_color.g, base_color.b, alpha)
			var vec4_colors: Array[Vector4] = [vec4_col, vec4_col, vec4_col]
			metaball.update_ball_colors(vec4_colors),
		0.3, 1.0, 0.5
	)

func stop_waiting_animation():
	if waiting_tween:
		waiting_tween.kill()

	waiting_tween = create_tween()
	waiting_tween.tween_method(
		func(alpha: float): 
			var vec4_col = Vector4(base_color.r, base_color.g, base_color.b, alpha)
			var vec4_colors: Array[Vector4] = [vec4_col, vec4_col, vec4_col]
			metaball.update_ball_colors(vec4_colors),
		0.3, 1.0, 0.5
	)

func start_arrow_animation():
	if arrow_tween:
		arrow_tween.kill()
	
	arrow_tween = create_tween().set_loops()
	
	# Initial position and scale
	var base_pos = Vector2(125, 0)
	var base_scale = Vector2(0.641129, 0.641129)
	
	# Bounce up
	arrow_tween.tween_property($Arrow, "position", 
		base_pos + Vector2(0, -10), 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	arrow_tween.parallel().tween_property($Arrow, "scale",
		base_scale * 1.2, 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Bounce down
	arrow_tween.tween_property($Arrow, "position",
		base_pos, 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	arrow_tween.parallel().tween_property($Arrow, "scale",
		base_scale, 0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func set_color(target_color: Color):
	var vec4_col = Vector4(target_color.r, target_color.g, target_color.b, target_color.a)
	var vec4_colors: Array[Vector4] = [vec4_col, vec4_col, vec4_col]
	metaball.update_ball_colors(vec4_colors)
