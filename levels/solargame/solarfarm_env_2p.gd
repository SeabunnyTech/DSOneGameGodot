@tool
extends Control
class_name SolarfarmEnv_2p

# 設計給上層遊戲場景 (solargame.tscn) 呼叫的 API

## 當陽光打到太陽能板上時發出
signal all_electron_collected

@onready var cloud_manager : CloudManager = $CloudManager

# 天空背景，可能是 ColorRect 或一個著色器
@onready var sky_background = $sky_background

# 雲的容器，所有動態產生的雲實例都會放在這個節點下
@onready var clouds_container: Node2D = $clouds_container

# 山上樹木的容器，方便統一處理風吹動畫
@onready var trees_container: Node2D = $trees_container



func _ready():
	$SolarPanel2d.hit_by_sunlight.connect(func():
		$ScoreBoard.add_score()
	)
	#$sun_orbit_center.position.x = -position.x / 2# + 960

	$CloudManager.player_index = player_index
	$SolarPanel2d.player_index = player_index


func set_responsive_to_anticyclone(responsive:bool):
	$CloudManager.set_responsive_to_anticyclone(responsive)


# 當前的風力向量，會影響雲的移動和樹的搖擺
var _wind_speed: float = 0
var wind_decay_factor = 50.0

func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		_wind_speed = _wind_speed * (wind_decay_factor ** -delta)
		$CloudManager.update_wind_speed(_wind_speed)

@export var sun_progress_speed: float = 1/30.0
var sun_should_go: bool = false
var sun_should_emit_light: bool = false

func _process(_delta: float) -> void:

	if sun_should_go:
		sunlight_progress += _delta * sun_progress_speed
	
	if sun_should_emit_light:
		emit_light_from_sun()


#region 公開 API - 供外部呼叫

# --- 太陽與天空控制 ---

@export var sun_color_over_time : Gradient
@export var sky_color_over_time : Gradient
## 設定太陽月亮的進度
## @param progress: float - 從 0 到 1 的進度, 0 是日出前, 1 是日落後, 0.5 是正中午


# 太陽節點，可能是 Sprite2D 或 Light2D
@export_range(0.0, 1.0) var sunlight_progress: float = 0.0:
	set(value):
		# 調整太陽位置
		sunlight_progress = value
		if not is_inside_tree(): return
		$sun_orbit_center.rotation_degrees = lerp(12, -12, value)

		# 調整天空顏色
		var sky_light_progress = 1.0 - 2.0 * abs(sunlight_progress - 0.5)
		$sky_background.color = sky_color_over_time.sample(sky_light_progress)
		# 微調太陽顏色
		#$sun_orbit_center/sun/Sunball2d.tint_color = sun_color_over_time.sample(sky_light_progress)
		#$sun_orbit_center/sun/EnvLight2D.color = sun_color_over_time.sample(sky_light_progress)


var LightParticleScene = preload("res://levels/solargame/light_particle/light_particle.tscn")

# 發射單個粒子
@export var player_index: int = 0

func emit_light_from_sun():
	var particle = LightParticleScene.instantiate()
	add_child(particle)
	particle.global_position = $sun_orbit_center/sun.global_position
	
	var angle = randf_range(0, 2*PI)
	var speed = 1200#randf_range(200, 400)
	var initial_velocity = Vector2(cos(angle), sin(angle)) * speed
	


	particle.player_index = player_index
	particle.linear_velocity = initial_velocity




## 啟用或禁用環境中的所有碰撞
func set_collision_enabled(enabled: bool) -> void:
	$CloudManager.set_collision_enabled(enabled)
	$SolarPanel2d.set_collision_enabled(enabled)


func reset():
	# Reset wind
	_wind_speed = 0.0

	# Reset sun and orbit position
	sun_should_go = false
	sun_should_emit_light = false
	self.sunlight_progress = 0.0

	# Reset the CloudManager
	$CloudManager.reset()

	# 計分板
	score_board.reset()
	score_board.modulate.a = 0
	score_board.position = Vector2(1450, 1680)


func spawn_clouds():
	$CloudManager.start()
	get_tree().create_timer(3).timeout.connect($CloudManager.stop_generate)



func start_game_play():
	# 太陽開始移動
	sun_should_go = true
	sun_should_emit_light = true

	show_score_board()

	# 雲開生成
	$CloudManager.start()


func stop_game_play():
	# 太陽停止
	sun_should_go = false
	sun_should_emit_light = false

	# move score_board_to_center
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($ScoreBoard, 'position', Vector2(795, 986), 1.0)

	# 雲集體原地消失
	$CloudManager.stop_generate()
	$CloudManager.clear_all_clouds()


############ (Almost) Copied from wheelgame_env



@onready var entire_env = $"."
var camera_tween

func camera_to(target_center, target_scale=1.0, duration=1, callback=null):
	if camera_tween:
		camera_tween.kill()

	var screen_center = size / 2.0
	var new_position = screen_center - target_center * target_scale
	camera_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	camera_tween.tween_property(entire_env, 'scale', Vector2(target_scale, target_scale), duration)
	camera_tween.parallel().tween_property(entire_env, 'position', new_position, duration)

	if callback:
		camera_tween.finished.connect(callback)




@onready var score_board = $ScoreBoard
var score:
	get:
		return score_board.score

func show_score_board(): return score_board.show_score_board()




func collect_electrons():
	#score_board.score = electron_collected
	all_electron_collected.emit()
