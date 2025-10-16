@tool
extends Node2D
class_name SolarfarmEnv

# 設計給上層遊戲場景 (solargame.tscn) 呼叫的 API

## 當陽光打到太陽能板上時發出
signal on_light_hit_solar_panel



#region 節點參考


# 天空背景，可能是 ColorRect 或一個著色器
@onready var sky_background = $sky_background

# 雲的容器，所有動態產生的雲實例都會放在這個節點下
@onready var clouds_container: Node2D = $clouds_container

# 山上樹木的容器，方便統一處理風吹動畫
@onready var trees_container: Node2D = $trees_container

#endregion




#region 內部狀態變數

# 當前的風力向量，會影響雲的移動和樹的搖擺
var _current_wind_vector: Vector2 = Vector2.ZERO

#endregion

func _on_hit(node: RigidBody2D):
	$Area2D.modulate = Color(randf(), 1, 1, 1)

func _ready() -> void:
	# 初始化場景，例如預載入雲的場景等
	$Area2D.body_entered.connect(_on_hit)

func _process(delta: float) -> void:
	# 每幀更新的邏輯
	# 1. 根據 _current_wind_vector 移動雲
	#    - 遍歷 clouds_container 中的所有雲
	#    - 更新它們的位置：cloud.global_position += _current_wind_vector * delta
	#    - 如果雲飄出畫面，可以將其移除或重新放置
	# 2. 根據 _current_wind_vector 更新樹的動畫
	#    - 遍歷 trees_container 中的所有樹
	#    - 可以透過設定 shader 的 uniform 參數或播放 AnimationPlayer 來實現搖擺效果
	sunlight_progress = (Time.get_ticks_msec() % 30000) / 30000.0
	if not Engine.is_editor_hint():
		emit_light_from_sun()


#region 公開 API - 供外部呼叫

# --- 太陽與天空控制 ---
@export_group("Sky Colors")
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
		$sun_orbit_center.rotation_degrees = lerp(30, -30, value)

		# 調整天空顏色
		var sky_light_progress = 1.0 - 2.0 * abs(sunlight_progress - 0.5)
		$sky_background.color = sky_color_over_time.sample(sky_light_progress)
		# 微調太陽顏色
		$sun_orbit_center/sun/Sunball2d.tint_color = sun_color_over_time.sample(sky_light_progress)


var LightParticleScene = preload("res://levels/solargame/light_particle/light_particle.tscn")

# 發射單個粒子
func emit_light_from_sun():
	var particle = LightParticleScene.instantiate()
	particle.global_position = $sun_orbit_center/sun.global_position
	
	var angle = randf_range(0, 2*PI)
	var speed = 1200#randf_range(200, 400)
	var initial_velocity = Vector2(cos(angle), sin(angle)) * speed
	
	get_parent().add_child(particle)
	particle.linear_velocity = initial_velocity

# 發射多個粒子
#func emit_light_burst(count: int = 10):
	#for i in range(count):
		#emit_light_from_sun()
		#await get_tree().create_timer(0.05).timeout  # 每個粒子間隔 0.05 秒


# --- 雲朵控制 ---

## 在場景中產生指定數量的雲
## @param count: int - 要產生的雲數量
## @param type: String - (可選) 雲的類型，用於產生不同外觀或行為的雲
func spawn_clouds(count: int, type: String = "default") -> void:
	# 在這裡填寫實作：
	# 1. 預載入雲的場景 (e.g., preload("res://path/to/cloud.tscn"))
	# 2. 迴圈 count 次，實例化雲場景
	# 3. 為每朵雲設定隨機的初始位置、大小、透明度和速度
	# 4. 將實例化的雲節點加到 clouds_container 中
	#    clouds_container.add_child(new_cloud)
	pass



# --- 風力控制 ---

## 設定當前的風力
## @param wind_vector: Vector2 - 風的方向和強度。
## 例如 Vector2(100, 0) 表示向右的強風；Vector2(0, 0) 表示無風。
func set_wind(wind_vector: Vector2) -> void:
	# 在這裡填寫實作：
	# 1. 更新內部的風力變數，_process 函數會使用它來移動雲和樹
	_current_wind_vector = wind_vector
	# 2. (可選) 你也可以在這裡直接觸發一次性的效果，例如一陣強風的音效
	pass

#endregion
