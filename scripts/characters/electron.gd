extends CharacterBody2D

var current_velocity: Vector2
var min_speed: float = 50.0
var max_speed: float = 250.0

enum ElectronType {
	TYPE1,
	TYPE2,
	TYPE3
}

const TEXTURE_PATHS = {
	"base": {
		ElectronType.TYPE1: preload("res://assets/images/sprites/electrons1.svg"),
		ElectronType.TYPE2: preload("res://assets/images/sprites/electrons2.svg"),
		ElectronType.TYPE3: preload("res://assets/images/sprites/electrons3.svg")
	},
	"halo1": {
		ElectronType.TYPE1: preload("res://assets/images/sprites/electrons1_halo1.svg"),
		ElectronType.TYPE2: preload("res://assets/images/sprites/electrons2_halo1.svg"),
		ElectronType.TYPE3: preload("res://assets/images/sprites/electrons3_halo1.svg")
	},
	"halo2": {
		ElectronType.TYPE1: preload("res://assets/images/sprites/electrons1_halo2.svg"),
		ElectronType.TYPE2: preload("res://assets/images/sprites/electrons2_halo2.svg"),
		ElectronType.TYPE3: preload("res://assets/images/sprites/electrons3_halo2.svg")
	}
}

var current_type: ElectronType = ElectronType.TYPE1

func _ready():
	modulate = Color(1, 1, 1, 0.8)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	var angle = randf_range(0, TAU)
	var initial_speed = randf_range(min_speed, max_speed)
	current_velocity = Vector2(cos(angle), sin(angle)) * initial_speed
	
func _physics_process(delta):
	# TODO: 可以在遠近景時有不同大小，讓遠景的電仔比較小，看起來有立體感
	# 更新位置
	velocity = current_velocity
	var collision = move_and_collide(velocity * delta)
	
	# 處理碰撞反彈
	if collision:
		current_velocity = current_velocity.bounce(collision.get_normal())
	
	# 添加旋轉效果
	rotation += current_velocity.length() * 0.0001 

func set_type(type: int):
	var electron_type = ElectronType.values()[type]
	current_type = electron_type

	$Base.texture = TEXTURE_PATHS.base[electron_type]
	$Halo1.texture = TEXTURE_PATHS.halo1[electron_type]
	$Halo2.texture = TEXTURE_PATHS.halo2[electron_type]

	# Start halo animation after type is set
	animate_halos()

func animate_halos():
	# Animate halos
	var halo1 = $Halo1
	var halo2 = $Halo2

	var tween = create_tween()
	tween.set_loops()
	
	# Halo1 animation (inner halo)
	tween.tween_property(halo1, "modulate:a", 0.8, 0.6).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(halo1, "scale", Vector2(1.1, 1.1), 0.6).set_trans(Tween.TRANS_CIRC)
	
	# Halo2 animation (outer halo)
	tween.parallel().tween_property(halo2, "modulate:a", 0.8, 0.6).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(halo2, "scale", Vector2(1.25, 1.25), 0.6).set_trans(Tween.TRANS_CIRC)

	# Contract both halos
	tween.chain().tween_property(halo1, "modulate:a", 0.05, 0.9).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(halo1, "scale", Vector2(1, 1), 0.9).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(halo2, "modulate:a", 0.05, 0.9).set_trans(Tween.TRANS_CIRC)
	tween.parallel().tween_property(halo2, "scale", Vector2(1, 1), 0.9).set_trans(Tween.TRANS_CIRC)


func vanish():
	var duration = randf_range(0.7, 1.3)
	var tween = create_tween()
	tween.tween_property(self, 'modulate:a', 0, duration)
	tween.tween_callback(self.queue_free)
